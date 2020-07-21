@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_HttpRequestTest {    

    private static final String ENDPOINT = 'https://www.somedomain.ca';
    private static final String METHOD = 'POST';
    private static final Boolean COMPRESSED = true;
    private static final String BODY = 'Some body 123';

    @IsTest
    private static void testCommonRequestProperties() {
        rflib_HttpRequest req = createRequest();

        HttpRequest actualRequest = req.getPlatformRequest();
        System.assertEquals(ENDPOINT, actualRequest.getEndpoint());
        System.assertEquals(METHOD, actualRequest.getMethod());
        System.assertEquals(COMPRESSED, actualRequest.getCompressed());
        System.assertEquals(BODY, actualRequest.getBody());
    }

    @IsTest
    private static void testSetBodyAsBlob() {
        Blob bodyAsBlob = Blob.valueOf(BODY);

        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setBodyAsBlob(bodyAsBlob);

        HttpRequest actualRequest = req.getPlatformRequest();
        System.assertEquals(BODY, actualRequest.getBody());
        System.assertEquals(bodyAsBlob, actualRequest.getBodyAsBlob());
    }

    @IsTest
    private static void testSetBodyAsDocument() {
        Dom.Document bodyAsDoc = new Dom.Document();
        bodyAsDoc.load('<test>' + BODY + '</test>');

        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setBodyDocument(bodyAsDoc);

        HttpRequest actualRequest = req.getPlatformRequest();
        System.assertEquals(bodyAsDoc.toXmlString(), actualRequest.getBodyDocument().toXmlString());
    }

    @IsTest
    private static void testSend() {
        rflib_HttpRequest req = createRequest();
        HttpResponse resp = createResponse('testCommonRequestProperties');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), resp, new String[] { rflib_GlobalSettings.traceIdHeaderName }));

        HttpResponse actualResponse = req.send();

        System.assertNotEquals(null, actualResponse);
        System.assertEquals(UserInfo.getUserId(), req.getPlatformRequest().getHeader(rflib_GlobalSettings.traceIdHeaderName));
        
        assertResponse(resp, actualResponse);
    }

    @IsTest
    private static void testSend_WithCustomHeader() {
        String headerKey = 'X-UnitTest';
        String headerValue = 'FooBar';

        rflib_HttpRequest req = createRequest();
        HttpResponse resp = createResponse('testSend_WithHeaders');
        
        req.setHeader(headerKey, headerValue);

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), resp, new String[] { headerKey }));

        HttpResponse actualResponse = req.send();

        System.assertNotEquals(null, actualResponse);
        System.assertEquals(headerValue, req.getPlatformRequest().getHeader(headerKey));
        
        assertResponse(resp, actualResponse);
    }

    @IsTest
    private static void testSend_ThrowsCalloutExcpetion() {
        rflib_HttpRequest req = createRequest();
        CalloutException ex = new CalloutException('Foo bar');

        Test.setMock(HttpCalloutMock.class, new rflib_SimpleHttpRequestMock(req.getPlatformRequest(), ex));

        try {
            req.send();
            System.assert(false, 'Excepted CalloutException to be thrown');
        } catch (CalloutException actualEx) {
            System.assertEquals(ex, actualEx);
        }
    }

    @IsTest
    private static void testToString() {
        rflib_HttpRequest req = createRequest();

        HttpRequest actualRequest = req.getPlatformRequest();
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
}