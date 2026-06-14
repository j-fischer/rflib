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

    private static final String ENDPOINT = 'callout:RFLIB_APP_INSIGHTS/v2.1/track';
    private static final String METHOD = 'POST';
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
        rflib_AppInsightsLogAction.fallbackTimestamp = Datetime.newInstanceGmt(2026, 6, 11, 17, 30, 12);

        List<rflib_Log_Event__e> events = createTestLogEvents('ERROR');
        HttpRequest req = createExpectedRequest(events);
        HttpResponse resp = createResponse(200, '{}');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(events);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT], 'No failure event expected on success.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToAppInsights_HttpFailure() {
        configure('ERROR');

        HttpRequest req = createExpectedRequest(createTestLogEvents('ERROR'));
        HttpResponse resp = createResponse(401, '[{"errorCode":"INVALID_SESSION_ID"}]');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT], 'Expected a failure event on HTTP failure.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToAppInsights_PartialSuccess() {
        configure('ERROR');

        HttpRequest req = createExpectedRequest(createTestLogEvents('ERROR'));
        HttpResponse resp = createResponse(206, '{"itemsReceived":1,"itemsAccepted":0,"errors":[{"index":0,"statusCode":400}]}');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT], 'Expected a failure event on 206 partial success.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToAppInsights_ThrowsException() {
        configure('ERROR');

        HttpRequest req = createExpectedRequest(createTestLogEvents('ERROR'));
        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, new CalloutException('boom')));

        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = :FAILURE_EVENT], 'Expected a failure event on callout exception.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testNoMatchingLogLevel() {
        configure('ERROR');

        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(createTestLogEvents('INFO'));
        Test.stopTest();

        Assert.isTrue(
            rflib_LoggerUtil.getFactory().createLogger('rflib_AppInsightsLogAction').printLogs().contains('No events to send found'),
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
            rflib_LoggerUtil.getFactory().createLogger('rflib_AppInsightsLogAction').printLogs().contains('is not configured'),
            'Expected the not-configured short-circuit when the instrumentation key is blank.'
        );
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testCreatePayload_Envelope() {
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

        Test.startTest();
        String payload = new rflib_AppInsightsLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Assert.areEqual('Microsoft.ApplicationInsights.Message', envelope.get('name'), 'Envelope name should be the Message type.');
        Assert.areEqual(IKEY, envelope.get('iKey'), 'iKey should be the configured instrumentation key.');
        Assert.areEqual('2026-06-11T17:30:12.000Z', envelope.get('time'), 'time should use the deterministic fallback timestamp.');

        Map<String, Object> data = (Map<String, Object>) envelope.get('data');
        Map<String, Object> baseData = (Map<String, Object>) data.get('baseData');
        Assert.areEqual('Something failed', baseData.get('message'), 'message should carry the log messages.');
        Assert.areEqual(3, baseData.get('severityLevel'), 'ERROR should map to severityLevel 3.');

        Map<String, Object> properties = (Map<String, Object>) baseData.get('properties');
        Assert.areEqual('MyClass.myMethod', properties.get('Context'), 'Context should be a property.');
        Assert.areEqual('12', properties.get('rflib.apex.cpu_time'), 'Platform info should be flattened into string properties.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSeverityMapping() {
        Assert.areEqual(0, rflib_AppInsightsLogAction.toSeverityLevel('TRACE'));
        Assert.areEqual(0, rflib_AppInsightsLogAction.toSeverityLevel('DEBUG'));
        Assert.areEqual(1, rflib_AppInsightsLogAction.toSeverityLevel('INFO'));
        Assert.areEqual(2, rflib_AppInsightsLogAction.toSeverityLevel('WARN'));
        Assert.areEqual(3, rflib_AppInsightsLogAction.toSeverityLevel('ERROR'));
        Assert.areEqual(4, rflib_AppInsightsLogAction.toSeverityLevel('FATAL'));
        Assert.areEqual(1, rflib_AppInsightsLogAction.toSeverityLevel('SOMETHING'));
        Assert.areEqual(1, rflib_AppInsightsLogAction.toSeverityLevel(null));
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testTruncation() {
        configure('ERROR');

        String longMessage = 'x'.repeat(rflib_AppInsightsLogAction.MAX_MESSAGE_LENGTH + 100);
        rflib_Log_Event__e evt = new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = longMessage);

        Test.startTest();
        String payload = new rflib_AppInsightsLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> baseData = (Map<String, Object>) ((Map<String, Object>) envelope.get('data')).get('baseData');
        String message = (String) baseData.get('message');
        Assert.isTrue(message.startsWith('[TRUNCATED]'), 'Oversized messages should be front-truncated.');
        Assert.isTrue(message.endsWith('x'), 'The most recent content (tail) should be kept.');
        Assert.areEqual(rflib_AppInsightsLogAction.MAX_MESSAGE_LENGTH, message.length(), 'Truncated value must not exceed the limit including the marker.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testPlatformPropertyTruncation() {
        configure('ERROR');

        // Malformed JSON makes the parser fall back to the raw Platform_Info__c string.
        String hugePlatformInfo = 'p'.repeat(rflib_AppInsightsLogAction.MAX_PROPERTY_LENGTH + 500);
        rflib_Log_Event__e evt = new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = 'x', Platform_Info__c = hugePlatformInfo);

        Test.startTest();
        String payload = new rflib_AppInsightsLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> baseData = (Map<String, Object>) ((Map<String, Object>) envelope.get('data')).get('baseData');
        Map<String, Object> properties = (Map<String, Object>) baseData.get('properties');
        String rawProp = (String) properties.get('rflib.platform_info');
        Assert.areEqual(rflib_AppInsightsLogAction.MAX_PROPERTY_LENGTH, rawProp.length(), 'Flattened platform properties must be capped at the property limit.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testItemSizeCapWithLargeProperties() {
        configure('ERROR');

        // Six large custom string properties (~48 KB once flattened/capped) plus a huge message.
        Map<String, Object> pinfo = new Map<String, Object>();
        for (Integer i = 0; i < 6; i++) {
            pinfo.put('field' + i, 'p'.repeat(8000));
        }
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'm'.repeat(40000),
            Platform_Info__c = JSON.serialize(pinfo)
        );

        Test.startTest();
        String payload = new rflib_AppInsightsLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Integer itemBytes = Blob.valueOf(payload).size();
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
        Map<String, Object> pinfo = new Map<String, Object>();
        for (Integer i = 0; i < 12; i++) {
            pinfo.put('field' + i, 'p'.repeat(8000));
        }
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'm'.repeat(40000),
            Platform_Info__c = JSON.serialize(pinfo)
        );

        Test.startTest();
        String payload = new rflib_AppInsightsLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Integer itemBytes = Blob.valueOf(payload).size();
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
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Log_Messages__c = '中'.repeat(25000)
        );

        Test.startTest();
        String payload = new rflib_AppInsightsLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Integer itemBytes = Blob.valueOf(payload).size();
        Assert.isTrue(
            itemBytes <= rflib_AppInsightsLogAction.MAX_ITEM_BYTES,
            'Multi-byte messages must be shrunk by serialized bytes, not characters; item was ' + itemBytes + ' bytes.'
        );

        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> baseData = (Map<String, Object>) ((Map<String, Object>) envelope.get('data')).get('baseData');
        String message = (String) baseData.get('message');
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

        Test.startTest();
        String payload = new rflib_AppInsightsLogAction().createPayload(new List<rflib_Log_Event__e>{ evt });
        Test.stopTest();

        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Map<String, Object> baseData = (Map<String, Object>) ((Map<String, Object>) envelope.get('data')).get('baseData');
        Map<String, Object> properties = (Map<String, Object>) baseData.get('properties');

        Boolean sawLongPlatformKey = false;
        for (String name : properties.keySet()) {
            Assert.isTrue(name.length() <= rflib_AppInsightsLogAction.MAX_PROPERTY_NAME_LENGTH, 'Property name exceeds the App Insights 150-char cap: ' + name.length());
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

        SizeCapturingMock mock = new SizeCapturingMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(events);
        Test.stopTest();

        Assert.isTrue(mock.bodySizes.size() > 1, 'Large events should be split across multiple callouts by byte size.');
        for (Integer size : mock.bodySizes) {
            Assert.isTrue(size <= rflib_AppInsightsLogAction.MAX_CALLOUT_BYTES, 'No callout body may exceed the byte budget; was ' + size);
        }
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testChunking() {
        configure('ERROR');

        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        for (Integer i = 0; i < rflib_AppInsightsLogAction.MAX_EVENTS_PER_CALLOUT + 50; i++) {
            events.add(new rflib_Log_Event__e(Log_Level__c = 'ERROR', Log_Messages__c = 'msg ' + i));
        }

        CountingMock mock = new CountingMock(200, '{}');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        rflib_AppInsightsLogAction.sendToAppInsights(events);
        Test.stopTest();

        Assert.areEqual(2, mock.callCount, 'Expected 150 events to be sent in two callouts of up to 100.');
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
        req.setBody(new rflib_AppInsightsLogAction().createPayload(events));
        return req;
    }

    private static HttpResponse createResponse(Integer statusCode, String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(body);
        return response;
    }

    private class SizeCapturingMock implements HttpCalloutMock {
        public List<Integer> bodySizes = new List<Integer>();

        public HttpResponse respond(HttpRequest req) {
            bodySizes.add(Blob.valueOf(req.getBody()).size());
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
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
