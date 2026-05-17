/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
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
private class rflib_SendLogEventSlackActionTest {

    private static final String SUCCESS_RESPONSE = 'ok';
    private static final String ERROR_RESPONSE = 'invalid_payload';
    private static final String METHOD = 'POST';

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToSlack_Success() {
        setupLoggerSettings('ERROR');

        List<rflib_Log_Event__e> events = createTestLogEvents('ERROR');
        HttpRequest req = createMockRequest(events[0]);
        HttpResponse resp = createSuccessResponse();

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_SendLogEventSlackAction.sendToSlack(events);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-slack-log-event-failed']);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToSlack_LogLevelDoesNotMatch() {
        setupLoggerSettings('WARN');

        Test.startTest();
        rflib_SendLogEventSlackAction.sendToSlack(createTestLogEvents('INFO'));
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-slack-log-event-failed']);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToSlack_LogLevelNone() {
        setupLoggerSettings('NONE');

        Test.startTest();
        rflib_SendLogEventSlackAction.sendToSlack(createTestLogEvents('FATAL'));
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-slack-log-event-failed']);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToSlack_FailureResponse() {
        setupLoggerSettings('ERROR');

        List<rflib_Log_Event__e> events = createTestLogEvents('ERROR');
        HttpRequest req = createMockRequest(events[0]);
        HttpResponse resp = createErrorResponse();

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_SendLogEventSlackAction.sendToSlack(events);
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-slack-log-event-failed']);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToSlack_ThrowsException() {
        setupLoggerSettings('ERROR');

        List<rflib_Log_Event__e> events = createTestLogEvents('ERROR');
        HttpRequest req = createMockRequest(events[0]);
        CalloutException ex = new CalloutException('Slack webhook callout failed');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, ex));

        Test.startTest();
        rflib_SendLogEventSlackAction.sendToSlack(events);
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-slack-log-event-failed']);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToSlack_LongMessageTruncated() {
        setupLoggerSettings('ERROR');

        String longMessage = 'X'.repeat(5000);
        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>{
            new rflib_Log_Event__e(
                Log_Level__c = 'ERROR',
                Context__c = 'TestContext',
                Request_ID__c = 'TestRequestId',
                Log_Messages__c = longMessage,
                Platform_Info__c = '{"CPU Time":12,"Heap Size":4080}'
            )
        };

        HttpRequest req = createMockRequest(events[0]);
        HttpResponse resp = createSuccessResponse();

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_SendLogEventSlackAction.sendToSlack(events);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-slack-log-event-failed']);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToSlack_InfoLevelConfigured_InfoEventNotSent() {
        setupLoggerSettings('INFO');

        Test.startTest();
        rflib_SendLogEventSlackAction.sendToSlack(createTestLogEvents('INFO'));
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-slack-log-event-failed']);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testSendToSlack_InfoLevelConfigured_WarnEventSentAtWarnFloor() {
        setupLoggerSettings('INFO');

        List<rflib_Log_Event__e> events = createTestLogEvents('WARN');
        HttpRequest req = createMockRequest(events[0]);
        HttpResponse resp = createSuccessResponse();
        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_SendLogEventSlackAction.sendToSlack(events);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-slack-log-event-failed']);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testCreateSlackPayload_WithPlatformInfo() {
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'ERROR',
            Context__c = 'TestContext',
            Request_ID__c = 'TestRequestId',
            Log_Messages__c = 'Test log message',
            Platform_Info__c = '{"CPU Time":12,"Heap Size":4080}'
        );

        Test.startTest();
        String payload = rflib_SendLogEventSlackAction.createSlackPayload(evt);
        Test.stopTest();

        Assert.isTrue(payload.contains('RFLIB Log Event'), 'Payload should contain the header text');
        Assert.isTrue(payload.contains('ERROR'), 'Payload should contain the log level');
        Assert.isTrue(payload.contains('TestContext'), 'Payload should contain the context');
        Assert.isTrue(payload.contains('TestRequestId'), 'Payload should contain the request ID');
        Assert.isTrue(payload.contains('Test log message'), 'Payload should contain the log messages');
        Assert.isTrue(payload.contains('CPU Time'), 'Payload should contain the platform info');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testCreateSlackPayload_WithoutPlatformInfo() {
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'WARN',
            Context__c = 'TestContext',
            Request_ID__c = 'TestRequestId',
            Log_Messages__c = 'Test log message',
            Platform_Info__c = null
        );

        Test.startTest();
        String payload = rflib_SendLogEventSlackAction.createSlackPayload(evt);
        Test.stopTest();

        Assert.isTrue(payload.contains('N/A'), 'Payload should contain N/A for missing platform info');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testCreateSlackPayload_WithNonJsonPlatformInfo() {
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Log_Level__c = 'WARN',
            Context__c = 'TestContext',
            Request_ID__c = 'TestRequestId',
            Log_Messages__c = 'Test log message',
            Platform_Info__c = 'N/A'
        );

        Test.startTest();
        String payload = rflib_SendLogEventSlackAction.createSlackPayload(evt);
        Test.stopTest();

        Assert.isTrue(payload.contains('N/A'), 'Payload should contain the raw platform info value when it is not JSON');
    }

    private static List<rflib_Log_Event__e> createTestLogEvents(String logLevel) {
        return new List<rflib_Log_Event__e>{
            new rflib_Log_Event__e(
                Log_Level__c = logLevel,
                Context__c = 'TestContext',
                Request_ID__c = 'TestRequestId',
                Log_Messages__c = 'Test log message',
                Platform_Info__c = '{"CPU Time":12,"Heap Size":4080}'
            )
        };
    }

    private static HttpRequest createMockRequest(rflib_Log_Event__e evt) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(rflib_SendLogEventSlackAction.ENDPOINT);
        req.setMethod(METHOD);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(rflib_SendLogEventSlackAction.createSlackPayload(evt));
        return req;
    }

    private static HttpResponse createSuccessResponse() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(SUCCESS_RESPONSE);
        return response;
    }

    private static HttpResponse createErrorResponse() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(400);
        response.setBody(ERROR_RESPONSE);
        return response;
    }

    private static void setupLoggerSettings(String slackLogLevel) {
        rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();
        loggerSettings.Slack_Log_Level__c = slackLogLevel;
        insert loggerSettings;
    }
}
