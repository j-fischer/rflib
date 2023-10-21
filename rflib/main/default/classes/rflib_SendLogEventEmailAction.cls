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
public with sharing class rflib_SendLogEventEmailAction {
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_EmailLogEventHandler');

    private static final String PLAIN_TEXT_MESSAGE = 'A Log Event was created by {0}.\Request ID: {1}\nContext: {2}\nLog Messages: {3}\nPlatform Info: {4}';
    private static final String HTML_MESSAGE = '<h2>A Log Event was created by {0}.</h2><h3>Request ID: {1}</h3><h3>Context: {2}</h3><p><b>Log Messages:</b> {3}</p></h3><p><b>Platform Info:</b> {4}</p>';

    @TestVisible
    private static Boolean USE_ORG_WIDE_EMAIL_ADDRESS = true;

    @TestVisible
    private static List<ApexEmailNotification> APEX_EMAIL_NOTIFICATION = [SELECT Email, UserId FROM ApexEmailNotification];

    static {
        // NOTE: It is critical to turn reporting off so that a log configuration reporting INFO statements
        //       does not create an infinite loop of log events. 
        LOGGER.setReportingLogLevel(rflib_LogLevel.NONE);
    }

    @InvocableMethod(label='Send Log Event Emails' category='RFLIB' description='Send Log Events to Apex Email Notification recipients')
    public static void sendEmailsIfApplicable(List<rflib_Log_Event__e> events) {
        rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();

        LOGGER.debug('run() invoked');
        if (APEX_EMAIL_NOTIFICATION.size() == 0) {
            LOGGER.debug('No Apex email notifications found');
            return;
        }

        List<String> emailAddresses = new List<String>();
        List<Id> userIds = new List<Id>();

        for (ApexEmailNotification apexEmail : APEX_EMAIL_NOTIFICATION) {
            if (String.isNotEmpty(apexEmail.Email)) {
                emailAddresses.add(apexEmail.Email);
            }

            if (String.isNotEmpty(apexEmail.UserId)) {
                userIds.add(apexEmail.UserId);
            }
        }

        emailAddresses.addAll(getEmailAddressesForUsers(userIds));

        LOGGER.debug('Recipients of log event: ' + String.join(emailAddresses, ','));

        if (emailAddresses.isEmpty()) {
            return;
        }

        Integer numEmailToSend = Math.min(events.size(), 10);

        LOGGER.debug('Emails to be sent = ' + numEmailToSend);
        for (Integer i = 0; i < numEmailToSend; i++) {
            rflib_Log_Event__e evt = events[i];
            if (matchesConfiguredLogLevel(loggerSettings, evt)) {
                sendMessage(emailAddresses, evt);
            }
        }
    }

    private static Boolean matchesConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings, rflib_Log_Event__e evt) {
        return rflib_LogLevel.fromString(loggerSettings.Email_Log_Level__c).
            encompasses(rflib_LogLevel.fromString(evt.Log_Level__c));
    }

    private static List<String> getEmailAddressesForUsers(List<Id> userIds) {
        List<String> result = new List<String>();
        for (User u : [SELECT Email FROM User WHERE Id IN :userIds]) {
            if (String.isNotEmpty(u.Email)) {
                result.add(u.Email);
            }
        }
        
        return result;
    }

    private static Id getOrgWideEmailAddressId() {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        return [SELECT Id FROM OrgWideEmailAddress WHERE Address = :settings.Org_Wide_Email_Sender_Address__c].Id;
    }

    private static void sendMessage(List<String> toAddresses, rflib_Log_Event__e event) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(toAddresses);

        if (USE_ORG_WIDE_EMAIL_ADDRESS) {
            mail.setOrgWideEmailAddressId(getOrgWideEmailAddressId());
        }

        mail.setSubject('A Log Event Occurred');
        mail.setPlainTextBody(String.format(PLAIN_TEXT_MESSAGE, new String[] { event.CreatedById, event.Request_ID__c, event.Context__c, event.Log_Messages__c, getFormattedPlatformInfo(event)  }));
        mail.setHtmlBody(String.format(HTML_MESSAGE, new String[] { event.CreatedById, event.Request_ID__c, event.Context__c, event.Log_Messages__c.replaceAll('(\\r|\\n)+', '<br />'), getFormattedPlatformInfo(event).replaceAll('(\\r|\\n)+', '<br />')  }));

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    private static String getFormattedPlatformInfo(rflib_Log_Event__e event) {
        if (String.isBlank(event.Platform_Info__c)) {
            return 'N/A';
        }

        return JSON.serializePretty(JSON.deserializeUntyped(event.Platform_Info__c));
    }
}
