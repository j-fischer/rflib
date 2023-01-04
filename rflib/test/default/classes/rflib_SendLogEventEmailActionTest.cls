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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_SendLogEventEmailActionTest {

    @isTest
    public static void testNoApexEmailConfigurationRecords() {
        rflib_SendLogEventEmailAction.USE_ORG_WIDE_EMAIL_ADDRESS = true;
        rflib_SendLogEventEmailAction.APEX_EMAIL_NOTIFICATION = new List<ApexEmailNotification>();

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations());
        rflib_SendLogEventEmailAction.sendEmailsIfApplicable(createLogEventList());
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @isTest
    public static void testEmailLogLevelDoesNotMatch() {
        createLoggerSettings('FATAL');

        rflib_SendLogEventEmailAction.USE_ORG_WIDE_EMAIL_ADDRESS = false;
        rflib_SendLogEventEmailAction.APEX_EMAIL_NOTIFICATION = createApexEmailNotification();

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations());
        rflib_SendLogEventEmailAction.sendEmailsIfApplicable(createLogEventList());
        System.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @isTest
    public static void testSuccess_WithoutPlatformInfo() {
        createLoggerSettings('ERROR');

        rflib_SendLogEventEmailAction.USE_ORG_WIDE_EMAIL_ADDRESS = false;
        rflib_SendLogEventEmailAction.APEX_EMAIL_NOTIFICATION = createApexEmailNotification();

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations());
        rflib_SendLogEventEmailAction.sendEmailsIfApplicable(createLogEventList());
        System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @isTest
    public static void testSuccess_WithPlatformInfo() {
        createLoggerSettings('ERROR');

        rflib_SendLogEventEmailAction.USE_ORG_WIDE_EMAIL_ADDRESS = false;
        rflib_SendLogEventEmailAction.APEX_EMAIL_NOTIFICATION = createApexEmailNotification();

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations());
        rflib_SendLogEventEmailAction.sendEmailsIfApplicable(createLogEventList('{"someKey":"some value"}'));
        System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
    }

    private static List<ApexEmailNotification> createApexEmailNotification() {
        return new List<ApexEmailNotification> {
            new ApexEmailNotification(
                Email = 'test@someDomain.com'
            ),
            new ApexEmailNotification(
                UserId = UserInfo.getUserId()
            )
        };
    }

    private static List<rflib_Log_Event__e> createLogEventList() {
        return createLogEventList(null);
    }

    private static List<rflib_Log_Event__e> createLogEventList(String platformInfo) {
        rflib_Log_Event__e ev = new rflib_Log_Event__e(
            Request_ID__c = 'Some Request ID',
            Context__c = 'Context Foo',
            Log_Messages__c = 'Some messages',
            Log_Level__c = 'ERROR',
            Platform_Info__c = platformInfo
        );

        return new List<rflib_Log_Event__e> { ev };
    }

    private static rflib_Logger_Settings__c createLoggerSettings() {
        return createLoggerSettings('ERROR');
    }

    private static rflib_Logger_Settings__c createLoggerSettings(String level) {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();
        settings.Email_Log_Level__c = level;
        
        upsert settings;
        return settings;
    }
}
