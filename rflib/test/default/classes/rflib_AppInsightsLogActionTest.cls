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
private class rflib_AppInsightsLogActionTest {
    private static final String IKEY = '00000000-0000-0000-0000-000000000000';
    private static final String FAILURE_EVENT = 'rflib-app-insights-log-event-failed';

    private static void configure(String logLevel) {
        rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();
        loggerSettings.App_Insights_Log_Level__c = logLevel;
        insert loggerSettings;
        rflib_GlobalSettings.SETTINGS.put('App_Insights_Instrumentation_Key', IKEY);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToAppInsights_Success() {
        configure('ERROR');

        sendWith(createTestLogEvents('ERROR'), 200, '{}');

        Assert.areEqual(0, failureEventCount(), 'No failure event expected on success.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToAppInsights_HttpFailure() {
        configure('ERROR');

        sendWith(createTestLogEvents('ERROR'), 401, '[{"errorCode":"INVALID_SESSION_ID"}]');

        Assert.areEqual(1, failureEventCount(), 'Expected a failure event on HTTP failure.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToAppInsights_PartialSuccess() {
        configure('ERROR');

        sendWith(
            createTestLogEvents('ERROR'),
            206,
            '{"itemsReceived":1,"itemsAccepted":0,"errors":[{"index":0,"statusCode":400}]}'
        );

        Assert.areEqual(1, failureEventCount(), 'Expected a failure event on 206 partial success.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToAppInsights_ThrowsException() {
        configure('ERROR');

        Test.setMock(HttpCalloutMock.class, new ForwarderMock(new CalloutException('boom')));
        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(1, failureEventCount(), 'Expected a failure event on callout exception.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testNoMatchingLogLevel() {
        configure('ERROR');

        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(createTestLogEvents('INFO'));
        Test.stopTest();

        Assert.isTrue(
            logs().contains('No events to send found'),
            'Expected the no-events short-circuit when the level does not match.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testNotConfigured() {
        rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();
        loggerSettings.App_Insights_Log_Level__c = 'ERROR';
        insert loggerSettings;
        // Instrumentation key intentionally left unset.

        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.isTrue(
            logs().contains('is not configured'),
            'Expected the not-configured short-circuit when the instrumentation key is blank.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testEnvelopeStructure() {
        configure('ERROR');
        rflib_AppInsightsLogAction.fallbackTimestamp = Datetime.newInstanceGmt(2026, 6, 11, 17, 30, 12);

        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'Something failed',
            Context__c = 'MyClass.myMethod',
            Request_ID__c = 'req-123',
            Source_System_ID__c = 'org-abc',
            Platform_Info__c = '{"CPU Time":12,"Heap Size":4080}'
        );

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');
        Map<String, Object> envelope = envelopes(mock.lastBody)[0];

        Assert.areEqual(
            'Microsoft.ApplicationInsights.Message',
            envelope.get('name'),
            'Envelope name should be the Message type.'
        );
        Assert.areEqual(IKEY, envelope.get('iKey'), 'iKey should be the configured instrumentation key.');
        Assert.areEqual(
            '2026-06-11T17:30:12.000Z',
            envelope.get('time'),
            'time should use the deterministic fallback timestamp.'
        );

        Map<String, Object> baseData = baseData(envelope);
        Assert.areEqual('Something failed', baseData.get('message'), 'message should carry the log messages.');
        Assert.areEqual(3, baseData.get('severityLevel'), 'ERROR should map to severityLevel 3.');

        Map<String, Object> properties = (Map<String, Object>) baseData.get('properties');
        Assert.areEqual('MyClass.myMethod', properties.get('Context'), 'Context should be a property.');
        Assert.areEqual(
            '12',
            properties.get('rflib.apex.cpu_time'),
            'Platform info should be flattened into string properties.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSeverityMapping() {
        // Configure TRACE so every level passes the filter and lands in one NDJSON body to inspect.
        configure('TRACE');

        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        for (String level : new List<String>{ 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL' }) {
            events.add(new rflib_Log_Event__e(Log_Level__c = level, Log_Messages__c = 'm'));
        }

        ForwarderMock mock = sendWith(events, 200, '{}');

        Map<String, Integer> bySeverity = new Map<String, Integer>();
        for (Map<String, Object> envelope : envelopes(mock.lastBody)) {
            Map<String, Object> properties = (Map<String, Object>) baseData(envelope).get('properties');
            bySeverity.put((String) properties.get('LogLevel'), (Integer) baseData(envelope).get('severityLevel'));
        }

        Assert.areEqual(0, bySeverity.get('TRACE'), 'TRACE -> 0');
        Assert.areEqual(0, bySeverity.get('DEBUG'), 'DEBUG -> 0');
        Assert.areEqual(1, bySeverity.get('INFO'), 'INFO -> 1');
        Assert.areEqual(2, bySeverity.get('WARN'), 'WARN -> 2');
        Assert.areEqual(3, bySeverity.get('ERROR'), 'ERROR -> 3');
        Assert.areEqual(4, bySeverity.get('FATAL'), 'FATAL -> 4');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testTruncation() {
        configure('ERROR');

        String longMessage = 'x'.repeat(rflib_AppInsightsLogAction.MAX_MESSAGE_LENGTH + 100);
        rflib_Log_Event__e evt = new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = longMessage);

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');
        String message = (String) baseData(envelopes(mock.lastBody)[0]).get('message');

        Assert.isTrue(message.startsWith('[TRUNCATED]'), 'Oversized messages should be front-truncated.');
        Assert.isTrue(message.endsWith('x'), 'The most recent content (tail) should be kept.');
        Assert.areEqual(
            rflib_AppInsightsLogAction.MAX_MESSAGE_LENGTH,
            message.length(),
            'Truncated value must not exceed the limit including the marker.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testPlatformPropertyTruncation() {
        configure('ERROR');

        // Malformed JSON makes the parser fall back to the raw Platform_Info__c string.
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'x',
            Platform_Info__c = 'p'.repeat(rflib_AppInsightsLogAction.MAX_PROPERTY_LENGTH + 500)
        );

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');
        Map<String, Object> properties = (Map<String, Object>) baseData(envelopes(mock.lastBody)[0]).get('properties');

        String rawProp = (String) properties.get('rflib.platform_info');
        Assert.areEqual(
            rflib_AppInsightsLogAction.MAX_PROPERTY_LENGTH,
            rawProp.length(),
            'Flattened platform properties must be capped at the property limit.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testPlatformPropertyCountCap() {
        configure('ERROR');

        // Valid JSON that flattens into far more properties than the cap. Without the cap, fitItem would
        // remove these one at a time (re-serializing the envelope each pass) and risk the CPU limit.
        Map<String, Object> platformInfo = new Map<String, Object>();
        for (Integer i = 0; i < rflib_AppInsightsLogAction.MAX_PLATFORM_PROPERTIES + 50; i++) {
            platformInfo.put('field' + i, i);
        }
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'x',
            Platform_Info__c = JSON.serialize(platformInfo)
        );

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');
        Map<String, Object> properties = (Map<String, Object>) baseData(envelopes(mock.lastBody)[0]).get('properties');

        Integer flattenedCount = 0;
        for (String key : properties.keySet()) {
            if (key.startsWith('rflib.platform.')) {
                flattenedCount++;
            }
        }
        Assert.areEqual(
            rflib_AppInsightsLogAction.MAX_PLATFORM_PROPERTIES,
            flattenedCount,
            'Flattened platform properties must be capped to protect against the CPU limit.'
        );
        Assert.isTrue(
            properties.containsKey('rflib.platform_info.truncated'),
            'Expected a marker property noting that platform properties were dropped.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testItemSizeCapWithLargeProperties() {
        configure('ERROR');

        // Six large custom string properties (~48 KB once flattened/capped) plus a huge message.
        Map<String, Object> platformInfo = new Map<String, Object>();
        for (Integer i = 0; i < 6; i++) {
            platformInfo.put('field' + i, 'p'.repeat(8000));
        }
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'm'.repeat(40000),
            Platform_Info__c = JSON.serialize(platformInfo)
        );

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');

        Integer itemBytes = Blob.valueOf(mock.lastBody).size();
        Assert.isTrue(
            itemBytes <= rflib_AppInsightsLogAction.MAX_ITEM_BYTES,
            'The full telemetry item must stay under the App Insights 64 KB cap; was ' + itemBytes + ' bytes.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testItemSizeCapWhenPropertiesExceedCap() {
        configure('ERROR');

        // Platform properties alone (~80 KB) exceed the item cap; the item must still be bounded by
        // dropping flattened platform properties, even with a large message.
        Map<String, Object> platformInfo = new Map<String, Object>();
        for (Integer i = 0; i < 12; i++) {
            platformInfo.put('field' + i, 'p'.repeat(8000));
        }
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'm'.repeat(40000),
            Platform_Info__c = JSON.serialize(platformInfo)
        );

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');

        Integer itemBytes = Blob.valueOf(mock.lastBody).size();
        Assert.isTrue(
            itemBytes <= rflib_AppInsightsLogAction.MAX_ITEM_BYTES,
            'Even when properties alone exceed the cap, the item must be trimmed under it; was ' + itemBytes + ' bytes.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testItemSizeCapWithMultiByteMessage() {
        configure('ERROR');

        // 25,000 CJK characters = ~75 KB in UTF-8 but only 25k by String.length(); a char-based cap
        // would leave the serialized item over the byte limit.
        rflib_Log_Event__e evt = new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = '中'.repeat(25000));

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');

        Integer itemBytes = Blob.valueOf(mock.lastBody).size();
        Assert.isTrue(
            itemBytes <= rflib_AppInsightsLogAction.MAX_ITEM_BYTES,
            'Multi-byte messages must be shrunk by serialized bytes, not characters; item was ' + itemBytes + ' bytes.'
        );

        String message = (String) baseData(envelopes(mock.lastBody)[0]).get('message');
        Assert.isTrue(message.startsWith('[TRUNCATED]'), 'The message should be truncated, not dropped.');
        Assert.isTrue(message.length() > 0, 'A fitting non-empty message should remain.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testPropertyNameCap() {
        configure('ERROR');

        String longKey = 'k'.repeat(200);
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'x',
            Platform_Info__c = JSON.serialize(new Map<String, Object>{ longKey => 'v' })
        );

        ForwarderMock mock = sendWith(new List<rflib_Log_Event__e>{ evt }, 200, '{}');
        Map<String, Object> properties = (Map<String, Object>) baseData(envelopes(mock.lastBody)[0]).get('properties');

        Boolean sawLongPlatformKey = false;
        for (String name : properties.keySet()) {
            Assert.isTrue(
                name.length() <= rflib_AppInsightsLogAction.MAX_PROPERTY_NAME_LENGTH,
                'Property name exceeds the App Insights 150-char cap: ' + name.length()
            );
            if (name.startsWith('rflib.platform.')) {
                sawLongPlatformKey = true;
            }
        }
        Assert.isTrue(sawLongPlatformKey, 'Expected the flattened long platform key to be present (name-capped).');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testByteSizeChunking() {
        configure('ERROR');
        // Lower the byte budget so a few moderate events force multiple callouts without large heap use.
        rflib_AppInsightsLogAction.MAX_CALLOUT_BYTES = 200000;

        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        for (Integer i = 0; i < 10; i++) {
            events.add(new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = 'm'.repeat(50000)));
        }

        ForwarderMock mock = sendWith(events, 200, '{}');

        Assert.isTrue(mock.bodySizes.size() > 1, 'Large events should be split across multiple callouts by byte size.');
        for (Integer size : mock.bodySizes) {
            Assert.isTrue(
                size <= rflib_AppInsightsLogAction.MAX_CALLOUT_BYTES,
                'No callout body may exceed the byte budget; was ' + size
            );
        }
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testMultiBatchFailuresAllAttempted() {
        configure('ERROR');
        // Force multiple batches so a failure on an early batch must not abort the later callouts.
        rflib_AppInsightsLogAction.MAX_CALLOUT_BYTES = 200000;

        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        for (Integer i = 0; i < 10; i++) {
            events.add(new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = 'm'.repeat(50000)));
        }

        ForwarderMock mock = sendWith(events, 401, '[{"errorCode":"INVALID_SESSION_ID"}]');

        Assert.isTrue(mock.callCount > 1, 'The batch should have been split across multiple callouts.');
        // All batches are attempted (none lost to uncommitted-work errors) and their failures are
        // consolidated into a single deferred application event whose detail records the failure count.
        List<rflib_Application_Event__c> failures = [
            SELECT Additional_Details__c
            FROM rflib_Application_Event__c
            WHERE Event_Name__c = :FAILURE_EVENT
        ];
        Assert.areEqual(
            1,
            failures.size(),
            'Failures should be consolidated into a single deferred application event.'
        );
        Assert.isTrue(
            failures[0].Additional_Details__c.contains(mock.callCount + ' failure(s)'),
            'The consolidated detail should record that every attempted batch failed.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testChunking() {
        configure('ERROR');

        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        for (Integer i = 0; i < rflib_AppInsightsLogAction.MAX_EVENTS_PER_CALLOUT + 50; i++) {
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
        rflib_AppInsightsLogAction.sendToAppInsights(events);
        Test.stopTest();
        return mock;
    }

    private static Integer failureEventCount() {
        return [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT];
    }

    // The App Insights wire format is newline-delimited JSON (one Message envelope per line).
    private static List<Map<String, Object>> envelopes(String ndjson) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (String line : ndjson.split('\n')) {
            if (String.isNotBlank(line)) {
                result.add((Map<String, Object>) JSON.deserializeUntyped(line));
            }
        }
        return result;
    }

    private static Map<String, Object> baseData(Map<String, Object> envelope) {
        return (Map<String, Object>) ((Map<String, Object>) envelope.get('data')).get('baseData');
    }

    private static String logs() {
        return rflib_LoggerUtil.getFactory().createLogger('rflib_AppInsightsLogActionTest').printLogs();
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
        public final List<Integer> bodySizes = new List<Integer>();

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
            bodySizes.add(Blob.valueOf(req.getBody()).size());
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
