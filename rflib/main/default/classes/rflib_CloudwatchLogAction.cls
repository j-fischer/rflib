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
 * @group Logger
 * @description Invocable Action that will send out an email to the Apex Email Notification list.
 *              Please make sure to set the Org Wide Email Sender Address in the Logger Custom Settings
 *              or the email will note be sent. This is due to the fact that Platform Event based triggers
 *              are executed by the System user. 
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_CloudwatchLogAction {
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_CloudwatchLogAction');

    private static final rflib_ApplicationEventLogger APP_EVENT_LOGGER = rflib_LoggerUtil.getApplicationEventLogger();

    static {
        // NOTE: It is critical to turn reporting off so that a log configuration reporting INFO statements
        //       does not create an infinite loop of log events. 
        LOGGER.setReportingLogLevel(rflib_LogLevel.NONE);
        LOGGER.setSystemDebugLevel(rflib_LogLevel.DEBUG);
    }

    @InvocableMethod(label='Log Event to AWS Cloudwatch' category='RFLIB' description='Log Events in AWS Cloudwatch')
    public static void sentToCloudWatch(List<rflib_Log_Event__e> events) {
        try {
            rflib_HttpRequest req = new rflib_HttpRequest(LOGGER);

            req.setEndpoint('callout:AWS_API_Gateway_Legacy/log-event');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(events));

            HttpResponse res = req.send();
            if (res.getStatusCode() == 200) {
                LOGGER.debug('Successfully sent data to API Gateway');
            } else {
                LOGGER.debug('Failed to send data to API Gateway. Status: ' + res.getStatus());
                APP_EVENT_LOGGER.logApplicationEvent('rflib-cloudwatch-log-event-failed', null, JSON.serialize(res));
            }
        } catch (Exception ex) {
            LOGGER.error('Failed to archive log event', ex);
            APP_EVENT_LOGGER.logApplicationEvent('rflib-cloudwatch-log-event-failed', null, LOGGER.printLogs());
        }
    }
}