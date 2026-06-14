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
 * @description Invocable Action that forwards RFLIB Log Events to Azure Application Insights via the
 *              telemetry ingestion endpoint (v2.1/track). Each Log Event becomes a Message telemetry
 *              envelope; the batch is sent as newline-delimited JSON (the Application Insights SDK
 *              wire format).
 *
 *              Requires a Named Credential named RFLIB_APP_INSIGHTS pointing at the resource's
 *              IngestionEndpoint (authenticated with Microsoft Entra ID), the Global Setting
 *              App_Insights_Instrumentation_Key, and App_Insights_Log_Level__c configured in the
 *              Logger Settings. See azure/README.md for the full setup guide.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_AppInsightsLogAction extends rflib_LogEventHttpForwarderAction {

    @TestVisible
    private static final String ENDPOINT = 'callout:RFLIB_APP_INSIGHTS/v2.1/track';

    // Application Insights accepts up to 64KB per telemetry item. Keep the whole envelope under that
    // (with headroom for transport overhead) and cap the message field individually.
    @TestVisible
    private static final Integer MAX_ITEM_BYTES = 62000;

    @TestVisible
    private static final Integer MAX_MESSAGE_LENGTH = 32768;

    @TestVisible
    private static final Integer MAX_PROPERTY_LENGTH = 8192;

    @TestVisible
    private static final Integer MAX_EVENTS_PER_CALLOUT = 100;

    // CreatedDate is null on events constructed directly (e.g. in tests). Use a stable fallback so
    // payloads are deterministic within a transaction.
    @TestVisible
    private static Datetime fallbackTimestamp = Datetime.now();

    @InvocableMethod(label='Send Log Event to Azure Application Insights' category='RFLIB' description='Forwards Log Events to Azure Application Insights via the telemetry ingestion endpoint')
    public static void sendToAppInsights(List<rflib_Log_Event__e> events) {
        new rflib_AppInsightsLogAction().process(events);
    }

    protected override String getLoggerName() {
        return 'rflib_AppInsightsLogAction';
    }

    protected override String getEndpoint() {
        return ENDPOINT;
    }

    protected override String getConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings) {
        return loggerSettings.App_Insights_Log_Level__c;
    }

    protected override String getAppEventFailureName() {
        return 'rflib-app-insights-log-event-failed';
    }

    protected override String getContentType() {
        return 'application/x-json-stream';
    }

    protected override Integer getMaxEventsPerCallout() {
        return MAX_EVENTS_PER_CALLOUT;
    }

    protected override Boolean isConfigured() {
        return String.isNotBlank(rflib_GlobalSettings.appInsightsInstrumentationKeyOrDefault);
    }

    @TestVisible
    protected override String createPayload(List<rflib_Log_Event__e> events) {
        String instrumentationKey = rflib_GlobalSettings.appInsightsInstrumentationKeyOrDefault;
        List<String> lines = new List<String>();
        for (rflib_Log_Event__e evt : events) {
            lines.add(JSON.serialize(createEnvelope(evt, instrumentationKey)));
        }
        return String.join(lines, '\n');
    }

    private Map<String, Object> createEnvelope(rflib_Log_Event__e evt, String instrumentationKey) {
        Datetime timestamp = evt.CreatedDate != null ? evt.CreatedDate : fallbackTimestamp;

        Map<String, Object> tags = new Map<String, Object>{
            'ai.cloud.role' => 'Salesforce',
            'ai.cloud.roleInstance' => String.isNotBlank(evt.Source_System_ID__c) ? evt.Source_System_ID__c : UserInfo.getOrganizationId(),
            'ai.operation.id' => evt.Request_ID__c,
            'ai.user.id' => evt.CreatedById
        };

        Map<String, Object> properties = new Map<String, Object>{
            'LogLevel' => evt.Log_Level__c,
            'Context' => evt.Context__c,
            'RequestId' => evt.Request_ID__c,
            'SourceSystemId' => evt.Source_System_ID__c,
            'LogSource' => evt.Log_Source__c,
            'Stacktrace' => truncate(evt.Stacktrace__c, MAX_PROPERTY_LENGTH),
            'CreatedById' => evt.CreatedById,
            'OrgId' => UserInfo.getOrganizationId()
        };

        Map<String, Object> platformInfo = rflib_PlatformInfoParser.flatten(evt);
        List<String> platformKeys = new List<String>(platformInfo.keySet());
        platformKeys.sort();
        for (String key : platformKeys) {
            properties.put(key, truncate(String.valueOf(platformInfo.get(key)), MAX_PROPERTY_LENGTH));
        }

        Map<String, Object> baseData = new Map<String, Object>{
            'ver' => 2,
            'message' => '',
            'severityLevel' => toSeverityLevel(evt.Log_Level__c),
            'properties' => properties
        };

        Map<String, Object> envelope = new Map<String, Object>{
            'name' => 'Microsoft.ApplicationInsights.Message',
            'time' => timestamp.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''),
            'iKey' => instrumentationKey,
            'tags' => tags,
            'data' => new Map<String, Object>{
                'baseType' => 'MessageData',
                'baseData' => baseData
            }
        };

        fitItem(envelope, baseData, properties, platformKeys, evt.Log_Messages__c);
        return envelope;
    }

    /**
     * @description Guarantees the serialized telemetry item stays under the 64 KB App Insights cap.
     *              First, if the item without any message already exceeds the cap (e.g. a very large
     *              valid Platform_Info__c), flattened platform properties are dropped largest-first
     *              until it fits. Then the message is sized to whatever space remains — which may be
     *              zero, in which case it is left empty rather than forced to a minimum that would
     *              push the item back over the limit.
     */
    private void fitItem(Map<String, Object> envelope, Map<String, Object> baseData, Map<String, Object> properties, List<String> platformKeys, String rawMessage) {
        baseData.put('message', '');

        while (!platformKeys.isEmpty() && Blob.valueOf(JSON.serialize(envelope)).size() > MAX_ITEM_BYTES) {
            properties.remove(removeLargestKey(properties, platformKeys));
        }

        Integer overhead = Blob.valueOf(JSON.serialize(envelope)).size();
        Integer budget = Math.min(MAX_MESSAGE_LENGTH, MAX_ITEM_BYTES - overhead);
        if (budget <= 0) {
            return;
        }
        baseData.put('message', truncate(rawMessage, budget));

        // JSON escaping of the message can inflate the serialized size; shrink once more if needed.
        Integer total = Blob.valueOf(JSON.serialize(envelope)).size();
        if (total > MAX_ITEM_BYTES) {
            Integer newBudget = budget - (total - MAX_ITEM_BYTES);
            baseData.put('message', newBudget <= 0 ? '' : truncate(rawMessage, newBudget));
        }
    }

    /**
     * @description Removes and returns the platform property key whose value serializes longest, so
     *              the largest contributor is dropped first when trimming an oversized item.
     */
    private String removeLargestKey(Map<String, Object> properties, List<String> platformKeys) {
        String largestKey = platformKeys[0];
        Integer largestLength = -1;
        for (String key : platformKeys) {
            Integer length = String.valueOf(properties.get(key)).length();
            if (length > largestLength) {
                largestLength = length;
                largestKey = key;
            }
        }
        platformKeys.remove(platformKeys.indexOf(largestKey));
        return largestKey;
    }

    /**
     * @description Maps an RFLIB log level to the Application Insights SeverityLevel scale
     *              (0 Verbose, 1 Information, 2 Warning, 3 Error, 4 Critical).
     */
    @TestVisible
    private static Integer toSeverityLevel(String logLevel) {
        switch on (logLevel == null ? '' : logLevel.toUpperCase()) {
            when 'TRACE', 'DEBUG' {
                return 0;
            }
            when 'INFO' {
                return 1;
            }
            when 'WARN' {
                return 2;
            }
            when 'ERROR' {
                return 3;
            }
            when 'FATAL' {
                return 4;
            }
            when else {
                return 1;
            }
        }
    }
}
