@IsTest
@SuppressWarnings('PMD.ClassNamingConventions, PMD.AvoidGlobalModifier')
global class rflib_SimpleHttpRequestMock implements HttpCalloutMock {
    
    private final List<String> headersToValidate;

    private final HttpRequest expectedRequest;
    private final HttpResponse responseToBeReturned;
    private final CalloutException exceptionToBeThrown;

    public rflib_SimpleHttpRequestMock(
        HttpRequest expectedRequest,
        HttpResponse responseToBeReturned
    ) {
        this(expectedRequest, responseToBeReturned, new List<String>(), null);
    }

    public rflib_SimpleHttpRequestMock(
        HttpRequest expectedRequest,
        HttpResponse responseToBeReturned,
        List<String> headersToValidate
    ) {
        this(expectedRequest, responseToBeReturned, headersToValidate, null);
    }

    public rflib_SimpleHttpRequestMock(
        HttpRequest expectedRequest,
        CalloutException exceptionToBeThrown
    ) {
        this(expectedRequest, null, new List<String> (), exceptionToBeThrown);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private rflib_SimpleHttpRequestMock(
        HttpRequest expectedRequest,
        HttpResponse responseToBeReturned,
        List<String> headersToValidate,
        CalloutException exceptionToBeThrown
    ) {
        this.expectedRequest = expectedRequest;
        this.responseToBeReturned = responseToBeReturned;
        this.headersToValidate = headersToValidate;
        this.exceptionToBeThrown = exceptionToBeThrown;
    }

    @SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation, PMD.ApexAssertionsShouldIncludeMessage')
    global HTTPResponse respond(HTTPRequest actualRequest) {

        System.assertEquals(expectedRequest.getEndpoint(), actualRequest.getEndpoint());
        System.assertEquals(expectedRequest.getMethod(), actualRequest.getMethod());
        System.assertEquals(expectedRequest.getCompressed(), actualRequest.getCompressed());
        System.assertEquals(expectedRequest.getBody(), actualRequest.getBody());

        for (String headerName : headersToValidate) {
            String expectedValue = expectedRequest.getHeader(headerName);
            String actualValue = actualRequest.getHeader(headerName);
            System.assertEquals(expectedValue, actualValue, String.format('Values for header with name "{0}" were note matching: expected={1}, actual={2}', new String[] { headerName, expectedValue, actualValue }));
        }

        if (exceptionToBeThrown != null) {
            throw exceptionToBeThrown;
        }

        return responseToBeReturned;
    }
}