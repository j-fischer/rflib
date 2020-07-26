/*
 * Copyright (c) 2019 Johannes Fischer <fischer.jh@gmail.com>
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
 * 3. Neither the name of mosquitto nor the names of its
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