@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_HttpRequestTest {    

    private static final String ENDPOINT = 'https://www.somedomain.ca';
    private static final String METHOD = 'POST';
    private static final Boolean COMPRESSED = true;
    private static final String BODY = 'Some body 123';

    @IsTest
    private static void testCommonRequestProperties() {
        Test.startTest();
        rflib_HttpRequest req = createRequest();

        HttpRequest actualRequest = req.getPlatformRequest();
        Test.stopTest();

        System.assertEquals(ENDPOINT, actualRequest.getEndpoint());
        System.assertEquals(METHOD, actualRequest.getMethod());
        System.assertEquals(COMPRESSED, actualRequest.getCompressed());
        System.assertEquals(BODY, actualRequest.getBody());
    }

    @IsTest
    private static void testSetBodyAsBlob() {
        Blob bodyAsBlob = Blob.valueOf(BODY);

        Test.startTest();
        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setBodyAsBlob(bodyAsBlob);
        Test.stopTest();

        HttpRequest actualRequest = req.getPlatformRequest();
        System.assertEquals(BODY, actualRequest.getBody());
        System.assertEquals(bodyAsBlob, actualRequest.getBodyAsBlob());
    }

    @IsTest
    private static void testSetBodyAsDocument() {
        Dom.Document bodyAsDoc = new Dom.Document();
        bodyAsDoc.load('<test>' + BODY + '</test>');

        Test.startTest();
        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setBodyDocument(bodyAsDoc);
        Test.stopTest();

        HttpRequest actualRequest = req.getPlatformRequest();
        System.assertEquals(bodyAsDoc.toXmlString(), actualRequest.getBodyDocument().toXmlString());
    }

    @IsTest
    private static void testSend() {
        Test.startTest();
        rflib_HttpRequest req = createRequest();
        HttpResponse resp = createResponse('testCommonRequestProperties');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), resp, new String[] { rflib_GlobalSettings.traceIdHeaderNameOrDefault }));

        HttpResponse actualResponse = req.send();
        Test.stopTest();

        System.assertNotEquals(null, actualResponse);
        System.assertEquals(UserInfo.getUserId() + '|' + Request.getCurrent().getRequestId(), req.getPlatformRequest().getHeader(rflib_GlobalSettings.traceIdHeaderNameOrDefault));
        
        assertResponse(resp, actualResponse);
    }

    @IsTest
    private static void testSend_withLogTimer() {
        rflib_MockLogger logger = new rflib_MockLogger();
        rflib_MockLogTimer logTimer = new rflib_MockLogTimer();
        
        Test.startTest();
        rflib_HttpRequest req = createRequest();
        HttpResponse resp = createResponse('testSend_withLogTimer');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), resp, new String[] { rflib_GlobalSettings.traceIdHeaderNameOrDefault }));

        logTimer.start(logger, rflib_LogLevel.WARN, -1, 'HttpRequest timer');
        HttpResponse actualResponse = req.send(logTimer);
        Test.stopTest();

        System.assert(logTimer.doneInvoked , 'The rflib_HttpRequest should have invoked the logTimer.done() methods');
    }

    @IsTest
    private static void testSend_WithCustomHeader() {
        String headerKey = 'X-UnitTest';
        String headerValue = 'FooBar';

        Test.startTest();
        rflib_HttpRequest req = createRequest();
        HttpResponse resp = createResponse('testSend_WithHeaders');
        
        req.setHeader(headerKey, headerValue);

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), resp, new String[] { headerKey }));

        HttpResponse actualResponse = req.send();
        Test.stopTest();

        System.assertNotEquals(null, actualResponse);
        System.assertEquals(headerValue, req.getPlatformRequest().getHeader(headerKey));
        
        assertResponse(resp, actualResponse);
    }

    @IsTest
    private static void testSend_ThrowsCalloutException() {
        rflib_HttpRequest req = createRequest();
        CalloutException ex = new CalloutException('Foo bar');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), ex));

        Test.startTest();
        try {
            req.send();
            System.assert(false, 'Excepted CalloutException to be thrown');
        } catch (CalloutException actualEx) {
            System.assertEquals(ex, actualEx);
        }
        Test.stopTest();
    }

    @IsTest
    private static void testMockingEnabledInSandbox() {
        setupMockEndpoints();

        rflib_GlobalSettings.SETTINGS.put('Http_Mocking_Enabled', 'true');
        rflib_OrgUtil.isSandbox = true;

        rflib_HttpRequest req = createRequest('http://example.com/test', 'This is a TestPayload');
        Test.startTest();
        HttpResponse actualResponse = req.send();
        Test.stopTest();

        System.assertEquals('Mock response', actualResponse.getBody(), 'The response should be the mocked response');
    }

    @IsTest
    private static void testMockingEnabledInProductionWithAllowance() {
        setupMockEndpoints();

        rflib_GlobalSettings.SETTINGS.put('Http_Mocking_Enabled', 'true');
        rflib_GlobalSettings.SETTINGS.put('Http_Mocking_Allow_In_Production', 'true');
        rflib_OrgUtil.isSandbox = false;

        rflib_HttpRequest req = createRequest('http://example.com/test', 'This is a TestPayload');
        Test.startTest();
        HttpResponse actualResponse = req.send();
        Test.stopTest();

        System.assertEquals('Mock response', actualResponse.getBody(), 'The response should be the mocked response');
    }

    @IsTest
    private static void testNoMockFoundAndThrowError() {
        setupMockEndpoints();

        rflib_GlobalSettings.SETTINGS.put('Http_Mocking_Enabled', 'true');
        rflib_GlobalSettings.SETTINGS.put('Http_Mocking_Throw_Error_If_Mock_Not_Found', 'true');
        rflib_OrgUtil.isSandbox = true;

        rflib_HttpRequest req = createRequest('http://example.com/test', 'Invalid Payload Content');

        try {
            Test.startTest();
            req.send();
            Test.stopTest();
            System.assert(false, 'Expected MockEndpointNotFoundException to be thrown');
        } catch (rflib_HttpRequest.MockEndpointNotFoundException e) {
            System.assert(true, 'MockEndpointNotFoundException was thrown as expected');
        }
    }

    @IsTest
    private static void testToString() {
        Test.startTest();
        rflib_HttpRequest req = createRequest();

        HttpRequest actualRequest = req.getPlatformRequest();
        Test.stopTest();
        
        System.assertEquals(req.toString(), actualRequest.toString());
    }

    private static void assertResponse(HttpResponse expectedResponse, HttpResponse actualResponse) {
        System.assertEquals(expectedResponse.toString(), actualResponse.toString());
        System.assertEquals(expectedResponse.getBody(), actualResponse.getBody());

    }

    private static HttpResponse createResponse(String body) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(body);

        return response;
    }

    private static rflib_HttpRequest createRequest() {
        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod(METHOD);
        req.setCompressed(COMPRESSED);
        req.setBody(BODY);
        req.setTimeout(60);

        return req;
    }

    private static rflib_HttpRequest createRequest(String endpoint, String body) {
        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setBody(body);
        return req;
    }
    
    private static void setupMockEndpoints() {
        List<rflib_HTTP_Mock_Endpoint__mdt> mocks = new List<rflib_HTTP_Mock_Endpoint__mdt>{
            new rflib_HTTP_Mock_Endpoint__mdt(
                HTTP_Method__c = 'POST',
                URL_Pattern__c = 'http://example.com/test',
                Payload_Pattern__c = '.*TestPayload.*',
                Response_Status__c = 200,
                Response_Payload__c = 'Mock response',
                Is_Active__c = true
            ),
            new rflib_HTTP_Mock_Endpoint__mdt(
                HTTP_Method__c = 'GET',
                URL_Pattern__c = 'http://example.com/invalid',
                Payload_Pattern__c = '.*InvalidPayload.*',
                Response_Status__c = 400,
                Response_Payload__c = 'Invalid URL',
                Is_Active__c = true
            ),
            new rflib_HTTP_Mock_Endpoint__mdt(
                HTTP_Method__c = 'POST',
                URL_Pattern__c = 'http://example.com/test',
                Payload_Pattern__c = '.*InactivePayload.*',
                Response_Status__c = 200,
                Response_Payload__c = 'Should not match',
                Is_Active__c = false // Inactive entry
            )
        };

        rflib_HttpEndpointMocker.mockEndpointSettings = mocks;
    }
}