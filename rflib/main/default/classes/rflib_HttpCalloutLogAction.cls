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
 * @group Logger
 * @description Invocable Action that will send out an HTTP request to an external system, such as
 *              AWS CloudWatch via API Gateway. The whole batch of matching Log Events is serialized
 *              as-is and POSTed to the RFLIB_HTTP_CALLOUT_LOG Named Credential.
 *
 *              The shared forwarding algorithm lives in rflib_LogEventHttpForwarderAction; this class
 *              only supplies the endpoint, configuration accessor and payload.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_HttpCalloutLogAction extends rflib_LogEventHttpForwarderAction {

    @InvocableMethod(label='Log Event via HTTP to Remote System' category='RFLIB' description='Log Events in external systems such as AWS Cloudwatch')
    public static void sendToExternalService(List<rflib_Log_Event__e> events) {
        new rflib_HttpCalloutLogAction().process(events);
    }

    protected override String getLoggerName() {
        return 'rflib_HttpCalloutLogAction';
    }

    protected override String getEndpoint() {
        return 'callout:RFLIB_HTTP_CALLOUT_LOG';
    }

    protected override String getConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings) {
        return loggerSettings.HTTP_Callout_Log_Level__c;
    }

    protected override String getAppEventFailureName() {
        return 'rflib-http-callout-log-event-failed';
    }

    protected override String createPayload(List<rflib_Log_Event__e> events) {
        return JSON.serialize(events);
    }
}