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
private class rflib_HttpCalloutLogActionTest {

    private static final String LOG_EVENT_RESPONSE = '{"status":"success"}';
    private static final String ERROR_RESPONSE = '[{"message":"Session expired or invalid","errorCode":"INVALID_SESSION_ID"}]';
    private static final String ENDPOINT = 'callout:RFLIB_HTTP_CALLOUT_LOG';
    private static final String METHOD = 'POST';

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testLogEventViaHttp_Success() {
        setupLoggerSettings('ERROR');

        HttpRequest req = createRequest();
        HttpResponse resp = createResponse(LOG_EVENT_RESPONSE);

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_HttpCalloutLogAction.sentToCloudWatch(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(200, resp.getStatusCode(), 'Expected a 200 status code from the mock response.');
        Assert.areEqual(LOG_EVENT_RESPONSE, resp.getBody(), 'Expected the response body to match the mock response body.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testLogEventViaHttp_Failure() {
        setupLoggerSettings('ERROR');

        HttpRequest req = createRequest();
        HttpResponse resp = createErrorResponse();

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, resp));

        Test.startTest();
        rflib_HttpCalloutLogAction.sentToCloudWatch(createTestLogEvents('ERROR'));
        Test.stopTest();

        // Expecting failure handling logic, normally assert log output or exception.
        Assert.areEqual(1, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-http-callout-log-event-failed']);
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testNoMatchingLogLevel() {
        setupLoggerSettings('WARN');

        Test.startTest();
        rflib_HttpCalloutLogAction.sentToCloudWatch(createTestLogEvents('INFO'));
        Test.stopTest();

        // Since the log level doesn't match, no HTTP request should be made, so no mock setup.
        Assert.isTrue(rflib_LoggerUtil.getFactory().createLogger('rflib_HttpCalloutLogActionTest').printLogs().contains('No events to send found. Nothing to do here.'));
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testLogEventViaHttp_ThrowsException() {
        setupLoggerSettings('ERROR');

        HttpRequest req = createRequest();
        CalloutException expectedEx = new CalloutException('HTTP callout failed');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req, expectedEx));

        Test.startTest();
        rflib_HttpCalloutLogAction.sentToCloudWatch(createTestLogEvents('ERROR'));
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM rflib_Application_Event__c WHERE Event_Name__c = 'rflib-http-callout-log-event-failed']);
    }

    private static List<rflib_Log_Event__e> createTestLogEvents(String logLevel) {
        List<rflib_Log_Event__e> events = new List<rflib_Log_Event__e>();
        events.add(new rflib_Log_Event__e(
            Log_Level__c = logLevel,
            Log_Messages__c = 'Test log message',
            Platform_Info__c = '{"CPU Time":12,"Heap Size":4080}',
            Source_System_ID__c = 'TestSystemID'
        ));
        return events;
    }

    private static HttpRequest createRequest() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod(METHOD);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(createTestLogEvents('ERROR')));
        return req;
    }

    private static HttpResponse createResponse(String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(body);
        return response;
    }

    private static HttpResponse createErrorResponse() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(401);
        response.setBody(ERROR_RESPONSE);
        return response;
    }

    private static void setupLoggerSettings(String logLevel) {
        rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();
        loggerSettings.HTTP_Callout_Log_Level__c = logLevel;
        insert loggerSettings;
    }
}
