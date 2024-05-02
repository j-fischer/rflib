/*
 * Copyright (c) 2021 Johannes Fischer <fischer.jh@gmail.com>
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
 * @description This is a wrapper class for the HttpRequest. It includes logging
                and automatically includes the Trace ID in the request header as 
                defined in rflib_Settings Custom Metadata.
 */ 
 @SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_HttpRequest {

    private final rflib_Logger logger;
    private final HttpRequest delegatee = new HttpRequest();
    
    public rflib_HttpRequest() {
        this(rflib_LoggerUtil.getFactory().createLogger('rflib_HttpRequest'));
    }

    public rflib_HttpRequest(rflib_Logger logger) {
        this.logger = logger;
    }

    public HttpRequest getPlatformRequest() {
        return delegatee;
    }

    public HttpResponse send() {
        return send(null);
    }

    public HttpResponse send(rflib_LogTimer logTimer) {
        try {
            LOGGER.info('Sending request: {0} with body: {1}', new String[] { delegatee.toString(), delegatee.getBody() } );
    
            delegatee.setHeader(rflib_GlobalSettings.traceIdHeaderNameOrDefault, rflib_TraceId.value);

            if (rflib_GlobalSettings.httpRequestMockingEnabled && (
                    rflib_OrgUtil.isSandboxOrg() ||
                    (rflib_OrgUtil.isProductionOrg() && rflib_GlobalSettings.httpRequestMockingAllowInProduction)
            )) {
                HttpResponse mockResponse = rflib_HttpEndpointMocker.getMockResponse(delegatee);

                if (mockResponse != null) {
                    return mockResponse;
                }

                if (rflib_GlobalSettings.httpRequestMockingThrowErrorIfNotMockNotFound) {
                    throw new MockEndpointNotFoundException();
                }
            }
    
            Http http = new Http();
            HttpResponse response = http.send(delegatee);
            
            LOGGER.info('Response received: {0} with body: {1}', new String[] { response.toString(), response.getBody() } );
    
            return response;
        } finally {
            if (logTimer != null) {
                logTimer.done();
            }
        }
    }

    public void setBody(String body) {
        delegatee.setBody(body);
    }

    public void setBodyAsBlob(Blob body) {
        delegatee.setBodyAsBlob(body);
    }

    public void setBodyDocument(Dom.Document body) {
        delegatee.setBodyDocument(body);
    }

    public void setClientCertificate(String clientCert, String password) {
        delegatee.setClientCertificate(clientCert, password);
    }

    public void setClientCertificateName(String certDevName) {
        setClientCertificateName(certDevName);
    }

    public void setCompressed(Boolean compressed) {
        delegatee.setCompressed(compressed);
    }

    public void setEndpoint(String endpoint) {
        delegatee.setEndpoint(endpoint);
    }

    public void setHeader(String key, String value) {
        delegatee.setHeader(key, value);
    }

    public void setMethod(String method) {
        delegatee.setMethod(method);
    }

    public void setTimeout(Integer timeout) {
        delegatee.setTimeout(timeout);
    }

    public override String toString() {
        return delegatee.toString();
    }

    public class MockEndpointNotFoundException extends Exception {} 
}
