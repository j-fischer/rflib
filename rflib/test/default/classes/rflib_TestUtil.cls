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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
public class rflib_TestUtil {
    private rflib_TestUtil() { }

    public static void prepareLoggerForUnitTests() {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();
        settings.General_Log_Level__c = 'DEBUG';
        settings.System_Debug_Log_Level__c = 'TRACE';
        settings.Log_Event_Reporting_Level__c = 'NONE';
        settings.Email_Log_Level__c = 'NONE';
        settings.Archive_Log_Level__c = 'NONE';
        settings.Log_Aggregation_Log_Level__c = 'NONE';
        settings.Batched_Log_Event_Reporting_Level__c = 'NONE';
        settings.Logger_Factory_Class__c = 'rflib_MockLoggerFactory';
        settings.Log_Timer_Class__c = 'rflib_MockLogTimer';
        settings.Log_Finalizer_Class__c = 'rflib_MockLogFinalizer';
        settings.Application_Event_Logger_Class__c = 'rflib_MockApplicationEventLogger';
        
        upsert settings;
    }
}
