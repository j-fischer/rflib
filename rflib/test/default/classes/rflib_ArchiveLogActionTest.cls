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
private class rflib_ArchiveLogActionTest {

    @isTest
    public static void testLogArchiveLevelDoesNotMatch() {
        createLoggerSettings('FATAL');

        rflib_MockBigObjectDatabaseExecutor dbExecutor = new rflib_MockBigObjectDatabaseExecutor();
        rflib_ArchiveLogAction.BIG_OBJECT_DB_EXECUTOR = dbExecutor;
        
        Test.startTest();
        System.assertEquals(null, dbExecutor.records);
        rflib_ArchiveLogAction.archiveLogIfApplicable(createLogEventList());
        System.assertEquals(null, dbExecutor.records);
        Test.stopTest();
    }

    @isTest
    public static void testSuccess() {
        createLoggerSettings('ERROR');
        
        rflib_MockBigObjectDatabaseExecutor dbExecutor = new rflib_MockBigObjectDatabaseExecutor();
        rflib_ArchiveLogAction.BIG_OBJECT_DB_EXECUTOR = dbExecutor;

        Test.startTest();
        System.assertEquals(null, dbExecutor.records);
        rflib_ArchiveLogAction.archiveLogIfApplicable(createLogEventList());
        System.assertNotEquals(null, dbExecutor.records);
        Test.stopTest();
    }

    private static List<rflib_Log_Event__e> createLogEventList() {
        rflib_Log_Event__e ev = new rflib_Log_Event__e(
            Request_ID__c = 'Some Request ID',
            Context__c = 'Context Foo',
            Log_Messages__c = 'Some messages',
            Log_Level__c = 'ERROR'
        );

        return new List<rflib_Log_Event__e> { ev };
    }

    private static rflib_Logger_Settings__c createLoggerSettings() {
        return createLoggerSettings('ERROR');
    }

    private static rflib_Logger_Settings__c createLoggerSettings(String level) {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();
        settings.Archive_Log_Level__c = level;
        
        upsert settings;
        return settings;
    }
}
