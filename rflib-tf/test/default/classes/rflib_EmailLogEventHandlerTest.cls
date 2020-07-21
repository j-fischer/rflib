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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_EmailLogEventHandlerTest {
    
    @isTest
    public static void testNoApexEmailConfigurationRecords() {
        System.assertEquals(0, Limits.getEmailInvocations());
        new rflib_EmailLogEventHandler(new List<ApexEmailNotification>(), true, createLoggerSettings()).run(null);
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @isTest
    public static void testEmailLogLevelDoesNotMatch() {
        System.assertEquals(0, Limits.getEmailInvocations());
        new rflib_EmailLogEventHandler(createApexEmailNotification(), false, createLoggerSettings('FATAL')).run(createLogEventArgs());
        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @isTest
    public static void testSuccess() {
        System.assertEquals(0, Limits.getEmailInvocations());
        new rflib_EmailLogEventHandler(createApexEmailNotification(), false, createLoggerSettings()).run(createLogEventArgs());
        System.assertEquals(1, Limits.getEmailInvocations());
    }

    @isTest
    public static void testOnConsecutiveRun() {
        System.assertEquals(0, Limits.getEmailInvocations());
        new rflib_EmailLogEventHandler().onConsecutiveRun(null, 1);
        System.assertEquals(0, Limits.getEmailInvocations());
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

    private static rflib_TriggerManager.Args createLogEventArgs() {
        rflib_Log_Event__e ev = new rflib_Log_Event__e(
            Context__c = 'Context Foo',
            Log_Messages__c = 'Some messages',
            Log_Level__c = 'ERROR'
        );

        return new rflib_TriggerManager.Args(
            rflib_Log_Event__e.getSObjectType(),
            System.TriggerOperation.AFTER_INSERT,
            new List<SObject>(),
            new Map<Id, SObject>(), 
            new List<SObject> { ev },
            new Map<Id, SObject>(), 
            1
        );
    }

    private static rflib_Logger_Settings__c createLoggerSettings() {
        return createLoggerSettings('ERROR');
    }

    private static rflib_Logger_Settings__c createLoggerSettings(String level) {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();
        settings.Email_Log_Level__c = level;
        return settings;
    }
}
