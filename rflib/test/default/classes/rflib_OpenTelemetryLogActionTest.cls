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

        sendWith(createTestLogEvents('ERROR'), 200, '{}');

        Assert.areEqual(0, failureEventCount(), 'No failure event expected on success.');
        Assert.isTrue(
            logs().contains('Successfully sent data to remote service'),
            'Expected a success diagnostic log.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToOpenTelemetry_NoContentSuccess() {
        configure('ERROR');

        // Grafana Cloud and other OTLP gateways acknowledge a successful export with 204 No Content.
        sendWith(createTestLogEvents('ERROR'), 204, '');

        Assert.areEqual(
            0,
            failureEventCount(),
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

        sendWith(createTestLogEvents('ERROR'), 200, '{}');

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

        sendWith(
            createTestLogEvents('ERROR'),
            200,
            '{"partialSuccess":{"rejectedLogRecords":1,"errorMessage":"bad record"}}'
        );

        Assert.areEqual(1, failureEventCount(), 'Expected a failure event when records are rejected.');
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

        sendWith(createTestLogEvents('ERROR'), 500, 'Server Error');

        Assert.areEqual(1, failureEventCount(), 'Expected a failure event on HTTP failure.');
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

        Test.setMock(HttpCalloutMock.class, new ForwarderMock(new CalloutException('boom')));
        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(1, failureEventCount(), 'Expected a failure event on callout exception.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testNoMatchingLogLevel() {
        configure('ERROR');

        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(createTestLogEvents('INFO'));
        Test.stopTest();

        Assert.isTrue(
            logs().contains('No events to send found'),
            'Expected the no-events short-circuit when the level does not match.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testPayloadStructure() {
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

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');
        Map<String, Object> record = firstRecord(mock.lastBody);

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

        // Confirm the platform info was flattened into a typed OTLP attribute (int64 encoded as string).
        Assert.areEqual(
            '12',
            intValueOf(record, 'rflib.apex.cpu_time'),
            'Numeric platform info should be encoded as intValue string.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSeverityMapping() {
        // Configure TRACE so every level passes the filter and lands in one payload to inspect.
        configure('TRACE');

        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        for (String level : new List<String>{ 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL' }) {
            events.add(new rflib_Log_Event__e(Log_Level__c = level, Log_Messages__c = 'm'));
        }

        ForwarderMock mock = sendWith(events, 200, '{}');

        Map<String, Integer> bySeverity = new Map<String, Integer>();
        for (Object recObj : records(mock.lastBody)) {
            Map<String, Object> rec = (Map<String, Object>) recObj;
            bySeverity.put((String) rec.get('severityText'), (Integer) rec.get('severityNumber'));
        }

        Assert.areEqual(1, bySeverity.get('TRACE'), 'TRACE -> 1');
        Assert.areEqual(5, bySeverity.get('DEBUG'), 'DEBUG -> 5');
        Assert.areEqual(9, bySeverity.get('INFO'), 'INFO -> 9');
        Assert.areEqual(13, bySeverity.get('WARN'), 'WARN -> 13');
        Assert.areEqual(17, bySeverity.get('ERROR'), 'ERROR -> 17');
        Assert.areEqual(21, bySeverity.get('FATAL'), 'FATAL -> 21');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testAttributeTyping() {
        configure('ERROR');

        // CPU Time + Heap Size mark the Apex shape; the extra keys exercise int/bool typing, and the
        // null Context__c exercises the null -> empty stringValue path.
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'm',
            Context__c = null,
            Platform_Info__c = '{"CPU Time":42,"Heap Size":1,"enabled":true}'
        );

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');
        Map<String, Object> record = firstRecord(mock.lastBody);

        Assert.areEqual('42', intValueOf(record, 'rflib.apex.cpu_time'), 'Integers should be intValue strings.');
        Assert.areEqual(true, valueOf(record, 'rflib.apex.enabled').get('boolValue'), 'Booleans should be boolValue.');
        Assert.areEqual(
            '',
            valueOf(record, 'rflib.context').get('stringValue'),
            'Null should default to an empty stringValue.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testPlatformAttributeCountCap() {
        configure('ERROR');

        // Valid JSON that flattens into far more leaves than the cap. Without the cap, every leaf would
        // become an OTLP attribute, materializing thousands of nested Maps before byte-batching runs.
        Map<String, Object> platformInfo = new Map<String, Object>();
        for (Integer i = 0; i < rflib_OpenTelemetryLogAction.MAX_PLATFORM_ATTRIBUTES + 50; i++) {
            platformInfo.put('field' + i, i);
        }
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'x',
            Platform_Info__c = JSON.serialize(platformInfo)
        );

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');
        Map<String, Object> record = firstRecord(mock.lastBody);

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
    private static void testPlatformAttributeTruncation() {
        configure('ERROR');

        // Malformed JSON makes the parser fall back to the raw Platform_Info__c string.
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'x',
            Platform_Info__c = 'p'.repeat(rflib_OpenTelemetryLogAction.MAX_ATTRIBUTE_LENGTH + 500)
        );

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');
        Map<String, Object> record = firstRecord(mock.lastBody);

        String rawValue = (String) valueOf(record, 'rflib.platform_info').get('stringValue');
        Assert.areEqual(
            rflib_OpenTelemetryLogAction.MAX_ATTRIBUTE_LENGTH,
            rawValue.length(),
            'Oversized platform string attributes must be capped.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testPartialSuccessParsing() {
        // Drives every branch of the OTLP partialSuccess parsing through the public path: only the two
        // responses that actually report rejected records become failures.
        configure('ERROR');

        Test.startTest();
        sendBody('');
        sendBody('not-json');
        sendBody('[]');
        sendBody('{"partialSuccess":5}');
        sendBody('{"partialSuccess":{}}');
        sendBody('{"partialSuccess":{"rejectedLogRecords":2}}');
        sendBody('{"partialSuccess":{"rejectedLogRecords":"5"}}');
        Test.stopTest();

        Assert.areEqual(2, failureEventCount(), 'Only responses reporting rejected records should be failures.');
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

        ForwarderMock mock = sendWith(events, 200, '{}');

        Assert.areEqual(1, mock.callCount, 'Only one callout should be made before the budget is exhausted.');
        Assert.areEqual(
            1,
            failureEventCount(),
            'Undelivered events must be surfaced as a failure application event, not silently dropped.'
        );
        Assert.isTrue(logs().contains('not delivered'), 'Expected a diagnostic naming the undelivered events.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testChunking() {
        configure('ERROR');

        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        for (Integer i = 0; i < rflib_OpenTelemetryLogAction.MAX_EVENTS_PER_CALLOUT + 50; i++) {
            events.add(new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = 'msg ' + i));
        }

        ForwarderMock mock = sendWith(events, 200, '{}');

        Assert.areEqual(2, mock.callCount, 'Expected 150 events to be sent in two callouts of up to 100.');
    }

    // ---- Helpers ---------------------------------------------------------------------------------

    private static ForwarderMock sendWith(List<rflib_Log_Event__e> events, Integer statusCode, String body) {
        ForwarderMock mock = new ForwarderMock(statusCode, body);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(events);
        Test.stopTest();
        return mock;
    }

    // Sends a single ERROR event against a 200 response with the given body (no start/stop; the caller
    // wraps a sequence of these in one Test.startTest/stopTest).
    private static void sendBody(String body) {
        Test.setMock(HttpCalloutMock.class, new ForwarderMock(200, body));
        rflib_OpenTelemetryLogAction.sendToOpenTelemetry(createTestLogEvents('ERROR'));
    }

    private static Integer failureEventCount() {
        return [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT];
    }

    private static List<Object> records(String payload) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> resourceLog = (Map<String, Object>) ((List<Object>) root.get('resourceLogs')).get(0);
        Map<String, Object> scopeLog = (Map<String, Object>) ((List<Object>) resourceLog.get('scopeLogs')).get(0);
        return (List<Object>) scopeLog.get('logRecords');
    }

    private static Map<String, Object> firstRecord(String payload) {
        return (Map<String, Object>) records(payload).get(0);
    }

    private static Map<String, Object> valueOf(Map<String, Object> record, String attributeKey) {
        for (Object attrObj : (List<Object>) record.get('attributes')) {
            Map<String, Object> attr = (Map<String, Object>) attrObj;
            if (attr.get('key') == attributeKey) {
                return (Map<String, Object>) attr.get('value');
            }
        }
        return null;
    }

    private static Object intValueOf(Map<String, Object> record, String attributeKey) {
        return valueOf(record, attributeKey).get('intValue');
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

    private class ForwarderMock implements HttpCalloutMock {
        private final Integer statusCode;
        private final String body;
        private final CalloutException error;
        public Integer callCount = 0;
        public String lastBody;

        public ForwarderMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public ForwarderMock(CalloutException error) {
            this.error = error;
        }

        public HttpResponse respond(HttpRequest req) {
            callCount++;
            lastBody = req.getBody();
            if (error != null) {
                throw error;
            }
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }
}
