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

 /**
 * @group Integration
 * @description This class provides access to the `rflib_HTTP_Mock_Endpoint__mdt`
 *              for mocking production endpoints. 
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public class rflib_HttpEndpointMocker {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('rflib_HttpEndpointMocker');

    @TestVisible
    private static List<rflib_HTTP_Mock_Endpoint__mdt> mockEndpointSettings {
        get {
            if (mockEndpointSettings == null) {
                mockEndpointSettings = getAllActiveMockEndpoints();
            }
            return mockEndpointSettings;
        }
        private set;
    }
    
    public static HttpResponse getMockResponse(HttpRequest req) {
        LOGGER.debug('getMockResponse invoked: ' + req);
        
        for (rflib_HTTP_Mock_Endpoint__mdt endpointInfo : mockEndpointSettings) {

            if (endpointInfo.HTTP_Method__c == req.getMethod() &&
                Pattern.matches(endpointInfo.URL_Pattern__c, req.getEndpoint()) &&
                Pattern.matches(endpointInfo.Payload_Pattern__c, req.getBody()) && 
                endpointInfo.Is_Active__c) {

                LOGGER.debug('Request matched mock endpoint: ' + JSON.serialize(endpointInfo));
                Integer statusCode = Integer.valueOf(endpointInfo.Response_Status__c);
                HttpResponse response = new HttpResponse();
                response.setStatusCode(statusCode);
                response.setStatus(STATUS_CODE_DESCRIPTIONS.get(statusCode));
                response.setBody(endpointInfo.Response_Payload__c);

                LOGGER.info('Returning mock response: {0} with body: {1}', new String[] { response.toString(), response.getBody() } );

                return response;
            }
        }

        LOGGER.debug('No mock response found');
        
        return null;
    }

    private static List<rflib_HTTP_Mock_Endpoint__mdt> getAllActiveMockEndpoints() {
        LOGGER.debug('getAllActiveMockEndpoints invoked');

        List<rflib_HTTP_Mock_Endpoint__mdt> allMockEndpoints = rflib_HTTP_Mock_Endpoint__mdt.getAll().values();

        LOGGER.debug('All mock endpoint values: ' + JSON.serialize(allMockEndpoints));

        List<rflib_HTTP_Mock_Endpoint__mdt> result = new LIst<rflib_HTTP_Mock_Endpoint__mdt>();
        for (rflib_HTTP_Mock_Endpoint__mdt endpoint : allMockEndpoints) {
            if (endpoint.Is_Active__c == true) {
                result.add(endpoint);
            } 
        }

        LOGGER.debug('Filtered mock endpoint values: ' + JSON.serialize(result));

        return result;
    }

    private static Map<Integer, String> STATUS_CODE_DESCRIPTIONS = new Map<Integer, String>{
        // 1xx: Informational
        100 => 'Continue',
        101 => 'Switching Protocols',
        102 => 'Processing',

        // 2xx: Success
        200 => 'OK',
        201 => 'Created',
        202 => 'Accepted',
        203 => 'Non-Authoritative Information',
        204 => 'No Content',
        205 => 'Reset Content',
        206 => 'Partial Content',

        // 3xx: Redirection
        300 => 'Multiple Choices',
        301 => 'Moved Permanently',
        302 => 'Found',
        303 => 'See Other',
        304 => 'Not Modified',
        307 => 'Temporary Redirect',
        308 => 'Permanent Redirect',

        // 4xx: Client Error
        400 => 'Bad Request',
        401 => 'Unauthorized',
        402 => 'Payment Required',
        403 => 'Forbidden',
        404 => 'Not Found',
        405 => 'Method Not Allowed',
        406 => 'Not Acceptable',
        407 => 'Proxy Authentication Required',
        408 => 'Request Timeout',
        409 => 'Conflict',
        410 => 'Gone',
        411 => 'Length Required',
        412 => 'Precondition Failed',
        413 => 'Payload Too Large',
        414 => 'URI Too Long',
        415 => 'Unsupported Media Type',
        416 => 'Range Not Satisfiable',
        417 => 'Expectation Failed',
        418 => 'I\'m a teapot', // Historical code, not in official registry but documented

        // 5xx: Server Error
        500 => 'Internal Server Error',
        501 => 'Not Implemented',
        502 => 'Bad Gateway',
        503 => 'Service Unavailable',
        504 => 'Gateway Timeout',
        505 => 'HTTP Version Not Supported',
        506 => 'Variant Also Negotiates',
        507 => 'Insufficient Storage',
        508 => 'Loop Detected',
        510 => 'Not Extended',
        511 => 'Network Authentication Required'
    };
}