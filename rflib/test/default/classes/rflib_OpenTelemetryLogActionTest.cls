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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_OpenTelemetryLogActionTest {
    private static final String ENDPOINT = 'callout:RFLIB_OTEL_LOGS';
    private static final String METHOD = 'POST';
    private static final String FAILURE_EVENT = 'rflib-otel-log-event-failed';

    private static void configure(String logLevel) {
        rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();
        loggerSettings.OTel_Log_Level__c = logLevel;
        insert loggerSettings;
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToOpenTelemetry_Success() {
        configure('ERROR');
        rflib_OpenTelemetryLogAction.fallbackTimestamp = Datetime.newInstanceGmt(2026, 6, 11, 17, 30, 12);

        List<rflib_Log_Event__e> events = createTestLogEvents('ERROR');
        HttpRequest req = createExpectedRequest(events);
        HttpResponse resp = createResponse(200, '{}');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(events);
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT],
            'No failure event expected on success.'
        );
        Assert.isTrue(
            logs().contains('Successfully sent data to remote service'),
            'Expected a success diagnostic log.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToOpenTelemetry_NoContentSuccess() {
        configure('ERROR');

        List<rflib_Log_Event__e> events = createTestLogEvents('ERROR');
        HttpRequest req = createExpectedRequest(events);
        // Grafana Cloud and other OTLP gateways acknowledge a successful export with 204 No Content.
        HttpResponse resp = createResponse(204, '');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(events);
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT],
            'A 204 No Content response is a successful OTLP export, not a failure.'
        );
        Assert.isTrue(
            logs().contains('Successfully sent data to remote service'),
            'Expected a success diagnostic log for the 204 response.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testRequestBodyIsNotCached() {
        configure('ERROR');

        List<rflib_Log_Event__e> events = createTestLogEvents('ERROR');
        HttpRequest req = createExpectedRequest(events);
        HttpResponse resp = createResponse(200, '{}');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(events);
        Test.stopTest();

        // The OTLP request body always contains "resourceLogs"; the callout uses a non-caching logger so
        // the (potentially MB-sized) body must never land in the shared in-transaction log buffer.
        Assert.isFalse(
            logs().contains('resourceLogs'),
            'The request body must not be cached in the shared log buffer (heap safety).'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToOpenTelemetry_PartialSuccess() {
        configure('ERROR');

        HttpRequest req = createExpectedRequest(createTestLogEvents('ERROR'));
        HttpResponse resp = createResponse(
            200,
            '{"partialSuccess":{"rejectedLogRecords":1,"errorMessage":"bad record"}}'
        );

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT],
            'Expected a failure event when records are rejected.'
        );
        String logOutput = logs();
        Assert.isTrue(
            logOutput.contains('Failed to send data to remote service'),
            'Expected the partial-success rejection to be recorded as a failure.'
        );
        Assert.isTrue(
            logOutput.contains('rejectedLogRecords'),
            'Expected the rejection detail (response body) to be captured.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToOpenTelemetry_HttpFailure() {
        configure('ERROR');

        HttpRequest req = createExpectedRequest(createTestLogEvents('ERROR'));
        HttpResponse resp = createResponse(500, 'Server Error');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT],
            'Expected a failure event on HTTP failure.'
        );
        String logOutput = logs();
        Assert.isTrue(
            logOutput.contains('Failed to send data to remote service'),
            'Expected a failure diagnostic log.'
        );
        Assert.isTrue(logOutput.contains('Server Error'), 'Expected the response body to be logged for debugging.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToOpenTelemetry_ThrowsException() {
        configure('ERROR');

        HttpRequest req = createExpectedRequest(createTestLogEvents('ERROR'));
        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, new CalloutException('boom')));

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT],
            'Expected a failure event on callout exception.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testNoMatchingLogLevel() {
        configure('ERROR');

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(createTestLogEvents('INFO'));
        Test.stopTest();

        Assert.isTrue(
            rflib_LoggerUtil.getFactory()
                .createLogger('rflib_OpenTelemetryLogAction')
                .printLogs()
                .contains('No events to send found'),
            'Expected the no-events short-circuit when the level does not match.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testCreatePayload_Structure() {
        configure('ERROR');
        rflib_OpenTelemetryLogAction.fallbackTimestamp = Datetime.newInstanceGmt(2026, 6, 11, 17, 30, 12);

        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'Something failed',
            Context__c = 'MyClass.myMethod',
            Request_ID__c = 'req-123',
            Source_System_ID__c = 'org-abc',
            Platform_Info__c = '{"CPU Time":12,"Heap Size":4080}'
        );

        Test.startTest();
        String payload = new rflib_OpenTelemetryLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        List<Object> resourceLogs = (List<Object>) root.get('resourceLogs');
        Assert.areEqual(1, resourceLogs.size(), 'Expected a single resourceLogs entry.');

        Map<String, Object> resourceLog = (Map<String, Object>) resourceLogs.get(0);
        List<Object> scopeLogs = (List<Object>) resourceLog.get('scopeLogs');
        Map<String, Object> scopeLog = (Map<String, Object>) scopeLogs.get(0);
        List<Object> logRecords = (List<Object>) scopeLog.get('logRecords');
        Map<String, Object> record = (Map<String, Object>) logRecords.get(0);

        Assert.areEqual(17, record.get('severityNumber'), 'ERROR should map to severityNumber 17.');
        Assert.areEqual('ERROR', record.get('severityText'), 'severityText should be the log level.');
        String expectedNanos = String.valueOf(Datetime.newInstanceGmt(2026, 6, 11, 17, 30, 12).getTime() * 1000000L);
        Assert.areEqual(expectedNanos, record.get('timeUnixNano'), 'timeUnixNano should be nanoseconds as a string.');
        Assert.areEqual(
            expectedNanos,
            record.get('observedTimeUnixNano'),
            'observedTimeUnixNano should be set per the OTLP data model.'
        );

        Map<String, Object> body = (Map<String, Object>) record.get('body');
        Assert.areEqual('Something failed', body.get('stringValue'), 'body.stringValue should carry the log messages.');

        // Confirm the platform info was flattened into typed OTLP attributes (int64 encoded as string).
        Boolean foundCpuTime = false;
        for (Object attrObj : (List<Object>) record.get('attributes')) {
            Map<String, Object> attr = (Map<String, Object>) attrObj;
            if (attr.get('key') == 'rflib.apex.cpu_time') {
                Map<String, Object> value = (Map<String, Object>) attr.get('value');
                Assert.areEqual(
                    '12',
                    value.get('intValue'),
                    'Numeric platform info should be encoded as intValue string.'
                );
                foundCpuTime = true;
            }
        }
        Assert.isTrue(foundCpuTime, 'Expected rflib.apex.cpu_time attribute in the log record.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testPlatformAttributeCountCap() {
        configure('ERROR');

        // Valid JSON that flattens into far more leaves than the cap. Without the cap, every leaf would
        // become an OTLP attribute, materializing thousands of nested Maps before byte-batching runs.
        Map<String, Object> pinfo = new Map<String, Object>();
        for (Integer i = 0; i < rflib_OpenTelemetryLogAction.MAX_PLATFORM_ATTRIBUTES + 50; i++) {
            pinfo.put('field' + i, i);
        }
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'x',
            Platform_Info__c = JSON.serialize(pinfo)
        );

        Test.startTest();
        String payload = new rflib_OpenTelemetryLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> record = (Map<String, Object>) ((List<Object>) ((Map<String, Object>) ((List<Object>) ((Map<String, Object>) ((List<Object>) root.get(
                                'resourceLogs'
                            ))
                            .get(0))
                        .get('scopeLogs'))
                    .get(0))
                .get('logRecords'))
            .get(0);

        Integer flattenedCount = 0;
        Boolean foundMarker = false;
        for (Object attrObj : (List<Object>) record.get('attributes')) {
            String key = (String) ((Map<String, Object>) attrObj).get('key');
            if (key.startsWith('rflib.platform.')) {
                flattenedCount++;
            } else if (key == 'rflib.platform_info.truncated') {
                foundMarker = true;
            }
        }
        Assert.areEqual(
            rflib_OpenTelemetryLogAction.MAX_PLATFORM_ATTRIBUTES,
            flattenedCount,
            'Flattened platform attributes must be capped to protect against heap/CPU limits.'
        );
        Assert.isTrue(foundMarker, 'Expected a marker attribute noting that platform attributes were dropped.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testCalloutBudgetStopsBeforeLimit() {
        configure('ERROR');
        // Force the per-transaction callout budget to 1 so the second batch cannot be sent.
        rflib_LogEventHttpForwarderAction.calloutLimitOverride = 1;

        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        for (Integer i = 0; i < rflib_OpenTelemetryLogAction.MAX_EVENTS_PER_CALLOUT + 50; i++) {
            events.add(new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = 'msg ' + i));
        }

        CountingMock mock = new CountingMock(200, '{}');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(events);
        Test.stopTest();

        Assert.areEqual(1, mock.callCount, 'Only one callout should be made before the budget is exhausted.');
        Assert.areEqual(
            1,
            [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT],
            'Undelivered events must be surfaced as a failure application event, not silently dropped.'
        );
        Assert.isTrue(logs().contains('not delivered'), 'Expected a diagnostic naming the undelivered events.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testPlatformAttributeTruncation() {
        configure('ERROR');

        // Malformed JSON makes the parser fall back to the raw Platform_Info__c string.
        String hugePlatformInfo = 'p'.repeat(rflib_OpenTelemetryLogAction.MAX_ATTRIBUTE_LENGTH + 500);
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'x',
            Platform_Info__c = hugePlatformInfo
        );

        Test.startTest();
        String payload = new rflib_OpenTelemetryLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> record = (Map<String, Object>) ((List<Object>) ((Map<String, Object>) ((List<Object>) ((Map<String, Object>) ((List<Object>) root.get(
                                'resourceLogs'
                            ))
                            .get(0))
                        .get('scopeLogs'))
                    .get(0))
                .get('logRecords'))
            .get(0);

        Boolean foundRaw = false;
        for (Object attrObj : (List<Object>) record.get('attributes')) {
            Map<String, Object> attr = (Map<String, Object>) attrObj;
            if (attr.get('key') == 'rflib.platform_info') {
                String value = (String) ((Map<String, Object>) attr.get('value')).get('stringValue');
                Assert.areEqual(
                    rflib_OpenTelemetryLogAction.MAX_ATTRIBUTE_LENGTH,
                    value.length(),
                    'Oversized platform string attributes must be capped.'
                );
                foundRaw = true;
            }
        }
        Assert.isTrue(foundRaw, 'Expected the raw platform_info fallback attribute.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSeverityMapping() {
        Assert.areEqual(1, rflib_OpenTelemetryLogAction.toSeverityNumber('TRACE'));
        Assert.areEqual(5, rflib_OpenTelemetryLogAction.toSeverityNumber('DEBUG'));
        Assert.areEqual(9, rflib_OpenTelemetryLogAction.toSeverityNumber('INFO'));
        Assert.areEqual(13, rflib_OpenTelemetryLogAction.toSeverityNumber('WARN'));
        Assert.areEqual(17, rflib_OpenTelemetryLogAction.toSeverityNumber('ERROR'));
        Assert.areEqual(21, rflib_OpenTelemetryLogAction.toSeverityNumber('FATAL'));
        Assert.areEqual(9, rflib_OpenTelemetryLogAction.toSeverityNumber('SOMETHING'));
        Assert.areEqual(9, rflib_OpenTelemetryLogAction.toSeverityNumber(null));
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testAttributeTyping() {
        Map<String, Object> intAttr = rflib_OpenTelemetryLogAction.attribute('k', 42);
        Assert.areEqual(
            '42',
            ((Map<String, Object>) intAttr.get('value')).get('intValue'),
            'Integers should be intValue strings.'
        );

        Map<String, Object> boolAttr = rflib_OpenTelemetryLogAction.attribute('k', true);
        Assert.areEqual(
            true,
            ((Map<String, Object>) boolAttr.get('value')).get('boolValue'),
            'Booleans should be boolValue.'
        );

        Map<String, Object> strAttr = rflib_OpenTelemetryLogAction.attribute('k', null);
        Assert.areEqual(
            '',
            ((Map<String, Object>) strAttr.get('value')).get('stringValue'),
            'Null should default to an empty stringValue.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testGetRejectedLogRecords() {
        Assert.areEqual(
            0L,
            rflib_OpenTelemetryLogAction.getRejectedLogRecords(''),
            'Blank body means nothing rejected.'
        );
        Assert.areEqual(
            0L,
            rflib_OpenTelemetryLogAction.getRejectedLogRecords('{}'),
            'Empty object means nothing rejected.'
        );
        Assert.areEqual(
            0L,
            rflib_OpenTelemetryLogAction.getRejectedLogRecords('not-json'),
            'Unparseable body is treated as success.'
        );
        Assert.areEqual(
            3L,
            rflib_OpenTelemetryLogAction.getRejectedLogRecords('{"partialSuccess":{"rejectedLogRecords":3}}'),
            'rejectedLogRecords should be parsed.'
        );
        Assert.areEqual(
            3L,
            rflib_OpenTelemetryLogAction.getRejectedLogRecords('{"partialSuccess":{"rejectedLogRecords":"3"}}'),
            'rejectedLogRecords as a string should be parsed.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testChunking() {
        configure('ERROR');

        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        for (Integer i = 0; i < rflib_OpenTelemetryLogAction.MAX_EVENTS_PER_CALLOUT + 50; i++) {
            events.add(new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = 'msg ' + i));
        }

        CountingMock mock = new CountingMock(200, '{}');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(events);
        Test.stopTest();

        Assert.areEqual(2, mock.callCount, 'Expected 150 events to be sent in two callouts of up to 100.');
    }

    private static String logs() {
        // printLogs() returns the shared in-transaction log buffer, so any logger instance sees the
        // messages the action wrote through its own (reporting-disabled) logger.
        return rflib_LoggerUtil.getFactory().createLogger('rflib_OpenTelemetryLogActionTest').printLogs();
    }

    private static List<rflib_Log_Event__e> createTestLogEvents(String logLevel) {
        return new List<rflib_Log_Event__e>{
            new rflib_Log_Event__e(
                Log_Level__c = logLevel,
                Log_Messages__c = 'Test log message',
                Platform_Info__c = '{"CPU Time":12,"Heap Size":4080}',
                Source_System_ID__c = 'TestSystemID'
            )
        };
    }

    private static HttpRequest createExpectedRequest(List<rflib_Log_Event__e> events) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod(METHOD);
        req.setBody(new rflib_OpenTelemetryLogAction().createPayload(events));
        return req;
    }

    private static HttpResponse createResponse(Integer statusCode, String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(body);
        return response;
    }

    private class CountingMock implements HttpCalloutMock {
        private final Integer statusCode;
        private final String body;
        public Integer callCount = 0;

        public CountingMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }
}
