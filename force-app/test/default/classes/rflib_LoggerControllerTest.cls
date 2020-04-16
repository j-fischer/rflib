
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
private class rflib_LoggerControllerTest {

    @TestSetup
    private static void setup(){
        rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getOrgDefaults();

        loggerSettings.General_Log_Level__c = 'None';
        loggerSettings.System_Debug_Log_Level__c = 'None';
        loggerSettings.Log_Event_Reporting_Level__c = 'None';
        loggerSettings.Org_Wide_Email_Sender_Address__c = 'foo@bar.com';
        loggerSettings.Logger_Factory_Class__c = 'rflib_DefaultLoggerFactory';

        upsert loggerSettings;
    }

    @IsTest
    public static void testGetSettings() {
        rflib_Logger_Settings__c actualSettings = rflib_LoggerController.getSettings();

        System.assertEquals('None', actualSettings.General_Log_Level__c);
        System.assertEquals('None', actualSettings.System_Debug_Log_Level__c);
        System.assertEquals('None', actualSettings.Log_Event_Reporting_Level__c);
    }

    @isTest
    public static void testLog_Debug() {
        executeTestLogMessage('Debug');
    } 

    @isTest
    public static void testLog_Info() {
        executeTestLogMessage('Info');
    } 

    @isTest
    public static void testLog_Warn() {
        executeTestLogMessage('Warn');
    } 

    @isTest
    public static void testLog_Error() {
        executeTestLogMessage('Error');
    }   

    @isTest
    public static void testLog_Fatal() {
        executeTestLogMessage('Fatal');
    } 

    @isTest
    public static void testLog_UnknownLevel() {
        executeTestLogMessage('Foo');
    } 

    private static void executeTestLogMessage(String level) {
        String context = 'someContext';
        String message = 'some message';

        System.assertEquals(0, rflib_DefaultLogger.LOG_STATEMENTS.size());

        rflib_LoggerController.log(level, context, message);
        
        System.assertEquals(1, rflib_DefaultLogger.LOG_STATEMENTS.size());

        String expectedLogLevel = level == 'Foo' ? 'FATAL' : level.toUpperCase();
        System.assert(rflib_DefaultLogger.LOG_STATEMENTS.get(0).contains(expectedLogLevel), 'LogLevel should be part of the log statement');
        System.assert(rflib_DefaultLogger.LOG_STATEMENTS.get(0).contains(context), 'Context should be part of the log statement');
        System.assert(rflib_DefaultLogger.LOG_STATEMENTS.get(0).contains(message), 'Message should be part of the log statement');
    }
}
