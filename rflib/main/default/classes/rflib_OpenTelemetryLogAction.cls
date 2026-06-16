/*
 * Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name "RFLIB", the name of the copyright holder, nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @group Logger
 * @description Invocable Action that forwards RFLIB Log Events to any OpenTelemetry Protocol (OTLP)
 *              logs endpoint using OTLP/HTTP JSON encoding. A single resourceLogs payload carries the
 *              batch; each Log Event becomes one logRecord with the Platform_Info__c values flattened
 *              into typed OTLP attributes.
 *
 *              The endpoint is the RFLIB_OTEL_LOGS Named Credential. The full logs URL (e.g.
 *              .../v1/logs) and any backend-specific headers (such as CloudWatch's x-aws-log-group /
 *              x-aws-log-stream, or a vendor API key) are configured on the Named Credential so this
 *              one action serves AWS CloudWatch, OpenTelemetry collectors and other OTLP backends that
 *              accept the JSON encoding. Azure Monitor's native OTLP ingestion requires protobuf, so it
 *              is supported only behind an OpenTelemetry Collector (for direct Azure ingestion use
 *              rflib_AppInsightsLogAction instead). Requires OTel_Log_Level__c configured in the Logger
 *              Settings. See otel/README.md for the full setup guide.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_OpenTelemetryLogAction extends rflib_LogEventHttpForwarderAction {

    @TestVisible
    private static final String ENDPOINT = 'callout:RFLIB_OTEL_LOGS';

    @TestVisible
    private static final String SCOPE_NAME = 'rflib';

    @TestVisible
    private static final String SDK_VERSION = '10.4.0';

    @TestVisible
    private static final Integer MAX_BODY_LENGTH = 32768;

    @TestVisible
    private static final Integer MAX_ATTRIBUTE_LENGTH = 8192;

    @TestVisible
    private static final Integer MAX_EVENTS_PER_CALLOUT = 100;

    // Bound each callout body for HEAP safety, not just the 6 MB callout-body limit:
    // rflib_HttpRequest logs the body at INFO (buffered by the logger), so the transaction briefly
    // holds the payload plus a formatted copy (~2x). 2 MB keeps that peak well under the Apex heap
    // limit while still batching efficiently and staying within the 100-callout-per-transaction cap.
    @TestVisible
    private static Integer MAX_CALLOUT_BYTES = 2000000;

    // CreatedDate is null on events constructed directly (e.g. in tests). Use a stable fallback so
    // payloads are deterministic within a transaction.
    @TestVisible
    private static Datetime fallbackTimestamp = Datetime.now();

    @InvocableMethod(label='Send Log Event to OpenTelemetry' category='RFLIB' description='Forwards Log Events to an OpenTelemetry (OTLP/HTTP JSON) logs endpoint such as AWS CloudWatch or an OpenTelemetry Collector. Azure Monitor is supported only behind a Collector (its native OTLP ingestion requires protobuf).')
    public static void sendToOpenTelemetry(List<rflib_Log_Event__e> events) {
        new rflib_OpenTelemetryLogAction().process(events);
    }

    protected override String getLoggerName() {
        return 'rflib_OpenTelemetryLogAction';
    }

    protected override String getEndpoint() {
        return ENDPOINT;
    }

    protected override String getConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings) {
        return loggerSettings.OTel_Log_Level__c;
    }

    protected override String getAppEventFailureName() {
        return 'rflib-otel-log-event-failed';
    }

    protected override Integer getMaxEventsPerCallout() {
        return MAX_EVENTS_PER_CALLOUT;
    }

    protected override Integer getMaxBytesPerCallout() {
        return MAX_CALLOUT_BYTES;
    }

    protected override Boolean isSuccessResponse(HttpResponse res) {
        if (res.getStatusCode() != 200) {
            return false;
        }
        // OTLP and CloudWatch signal dropped records via partialSuccess.rejectedLogRecords.
        Long rejected = getRejectedLogRecords(res.getBody());
        if (rejected > 0) {
            rflib_LoggerUtil.logInternal(getLogger(),
                'OTLP endpoint returned HTTP 200 but rejected {0} log record(s); response: {1}',
                new Object[] { rejected, res.getBody() });
            return false;
        }
        return true;
    }

    @TestVisible
    private static Long getRejectedLogRecords(String body) {
        if (String.isBlank(body)) {
            return 0;
        }
        try {
            Object parsed = JSON.deserializeUntyped(body);
            if (!(parsed instanceof Map<String, Object>)) {
                return 0;
            }
            Object partialSuccess = ((Map<String, Object>) parsed).get('partialSuccess');
            if (!(partialSuccess instanceof Map<String, Object>)) {
                return 0;
            }
            Object rejected = ((Map<String, Object>) partialSuccess).get('rejectedLogRecords');
            return rejected == null ? 0 : Long.valueOf(String.valueOf(rejected));
        } catch (Exception ex) {
            return 0;
        }
    }

    @TestVisible
    protected override String createPayload(List<rflib_Log_Event__e> events) {
        List<Object> logRecords = new List<Object>();
        for (rflib_Log_Event__e evt : events) {
            logRecords.add(createLogRecord(evt));
        }

        Map<String, Object> resourceLogs = new Map<String, Object>{
            'resource' => new Map<String, Object>{
                'attributes' => new List<Object>{
                    attribute('service.name', rflib_GlobalSettings.otelServiceNameOrDefault),
                    attribute('service.instance.id', UserInfo.getOrganizationId()),
                    attribute('telemetry.sdk.name', 'rflib-apex'),
                    attribute('telemetry.sdk.language', 'apex'),
                    attribute('telemetry.sdk.version', SDK_VERSION)
                }
            },
            'scopeLogs' => new List<Object>{
                new Map<String, Object>{
                    'scope' => new Map<String, Object>{ 'name' => SCOPE_NAME, 'version' => SDK_VERSION },
                    'logRecords' => logRecords
                }
            }
        };

        return JSON.serialize(new Map<String, Object>{
            'resourceLogs' => new List<Object>{ resourceLogs }
        });
    }

    private Map<String, Object> createLogRecord(rflib_Log_Event__e evt) {
        Datetime timestamp = evt.CreatedDate != null ? evt.CreatedDate : fallbackTimestamp;
        String timeUnixNano = String.valueOf(timestamp.getTime() * 1000000L);

        List<Object> attributes = new List<Object>{
            attribute('rflib.context', evt.Context__c),
            attribute('rflib.request_id', evt.Request_ID__c),
            attribute('rflib.source_system_id', evt.Source_System_ID__c),
            attribute('rflib.log_source', evt.Log_Source__c),
            attribute('rflib.stacktrace', truncate(evt.Stacktrace__c, MAX_ATTRIBUTE_LENGTH)),
            attribute('enduser.id', evt.CreatedById)
        };

        Map<String, Object> platformInfo = rflib_PlatformInfoParser.flatten(evt);
        List<String> platformKeys = new List<String>(platformInfo.keySet());
        platformKeys.sort();
        for (String key : platformKeys) {
            Object value = platformInfo.get(key);
            if (value instanceof String) {
                value = truncate((String) value, MAX_ATTRIBUTE_LENGTH);
            }
            attributes.add(attribute(key, value));
        }

        return new Map<String, Object>{
            'timeUnixNano' => timeUnixNano,
            'observedTimeUnixNano' => timeUnixNano,
            'severityNumber' => toSeverityNumber(evt.Log_Level__c),
            'severityText' => evt.Log_Level__c,
            'body' => new Map<String, Object>{ 'stringValue' => truncate(evt.Log_Messages__c, MAX_BODY_LENGTH) },
            'attributes' => attributes
        };
    }

    /**
     * @description Builds an OTLP KeyValue with the value typed per the OTLP/HTTP JSON encoding
     *              (int64 is encoded as a string).
     */
    @TestVisible
    private static Map<String, Object> attribute(String key, Object value) {
        Map<String, Object> anyValue;
        if (value instanceof Integer || value instanceof Long) {
            anyValue = new Map<String, Object>{ 'intValue' => String.valueOf(value) };
        } else if (value instanceof Double || value instanceof Decimal) {
            anyValue = new Map<String, Object>{ 'doubleValue' => value };
        } else if (value instanceof Boolean) {
            anyValue = new Map<String, Object>{ 'boolValue' => value };
        } else {
            anyValue = new Map<String, Object>{ 'stringValue' => value == null ? '' : String.valueOf(value) };
        }
        return new Map<String, Object>{ 'key' => key, 'value' => anyValue };
    }

    /**
     * @description Maps an RFLIB log level to the OpenTelemetry SeverityNumber scale
     *              (TRACE 1, DEBUG 5, INFO 9, WARN 13, ERROR 17, FATAL 21).
     */
    @TestVisible
    private static Integer toSeverityNumber(String logLevel) {
        switch on (logLevel == null ? '' : logLevel.toUpperCase()) {
            when 'TRACE' {
                return 1;
            }
            when 'DEBUG' {
                return 5;
            }
            when 'INFO' {
                return 9;
            }
            when 'WARN' {
                return 13;
            }
            when 'ERROR' {
                return 17;
            }
            when 'FATAL' {
                return 21;
            }
            when else {
                return 9;
            }
        }
    }
}
