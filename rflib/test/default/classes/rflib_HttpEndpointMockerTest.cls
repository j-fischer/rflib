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
private class rflib_HttpEndpointMockerTest {

    @IsTest
    static void testMatchFound() {
        setupMockEndpoints();
        HttpRequest req = createMockRequest('POST', 'http://example.com/test', 'This is a TestPayload');

        HttpResponse response = rflib_HttpEndpointMocker.getMockResponse(req);

        Assert.areNotEqual(null, response, 'Response should not be null');
        Assert.areEqual('Mock response', response.getBody(), 'Response body should match mock data');
        Assert.areEqual(200, response.getStatusCode(), 'Status code should match mock data');
    }

    @IsTest
    static void testMatchNotFoundInvalidURL() {
        setupMockEndpoints();
        HttpRequest req = createMockRequest('POST', 'http://example.com/invalidurl', 'This is a TestPayload');

        HttpResponse response = rflib_HttpEndpointMocker.getMockResponse(req);

        Assert.areEqual(null, response, 'Response should be null due to invalid URL');
    }

    @IsTest
    static void testMatchNotFoundInvalidPayload() {
        setupMockEndpoints();
        HttpRequest req = createMockRequest('POST', 'http://example.com/test', 'This is an InvalidPayload');

        HttpResponse response = rflib_HttpEndpointMocker.getMockResponse(req);

        Assert.areEqual(null, response, 'Response should be null due to invalid payload');
    }

    @IsTest
    static void testMatchNotFoundInactiveEntry() {
        setupMockEndpoints();
        HttpRequest req = createMockRequest('POST', 'http://example.com/test', 'This is an InactivePayload');

        HttpResponse response = rflib_HttpEndpointMocker.getMockResponse(req);

        Assert.areEqual(null, response, 'Response should be null because the matching entry is inactive');
    }

    @IsTest
    static void testMatchNotFoundInvalidHTTPMethod() {
        setupMockEndpoints();
        HttpRequest req = createMockRequest('GET', 'http://example.com/test', 'This is a TestPayload');
        HttpResponse response = rflib_HttpEndpointMocker.getMockResponse(req);

        Assert.areEqual(null, response, 'Response should be null due to HTTP method mismatch');
    }

    private static HttpRequest createMockRequest(String method, String endpoint, String body) {
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(endpoint);
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
                HTTP_Method__c = 'POST',
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
                Is_Active__c = false 
            )
        };

        rflib_HttpEndpointMocker.mockEndpointSettings = mocks;
    }
}
