
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
private class rflib_DefaultLoggerFactoryTest {
   
    @TestSetup
    static void makeData(){
        insert new rflib_Logger_Settings__c(
            Log_Size__c = 50,
            Enable_Log_Masking__c = true,
            System_Debug_Log_Level__c = 'WARN',
            Log_Event_Reporting_Level__c = 'ERROR',
            Log_Aggregation_Log_Level__c = 'WARN',
            Flush_Log_Cache_Level__c = 'INFO',
            General_Log_Level__c = 'INFO',
            Org_Wide_Email_Sender_Address__c = 'foo@email.com',
            Batched_Log_Event_Reporting_Level__c = 'INFO'
        );
    }

    @isTest
    public static void testCreateLogger() {
        Test.startTest();
        Assert.isNotNull(new rflib_DefaultLoggerFactory().createLogger('logger'));
        Test.stopTest();
    }

    @isTest
    public static void testCreateBatchedLogger() {
        Test.startTest();
        Assert.isNotNull(new rflib_DefaultLoggerFactory().createBatchedLogger('logger'));
        Test.stopTest();
    }

    @IsTest
    public static void testLoggerSettings() {
        Test.startTest();
        rflib_DefaultLogger logger = (rflib_DefaultLogger) new rflib_DefaultLoggerFactory().createLogger('logger');
        Test.stopTest();

        Assert.areEqual(rflib_LogLevel.INFO, logger.generalLogLevel);
        Assert.areEqual(rflib_LogLevel.WARN, logger.systemDebugLevel);
        Assert.areEqual(rflib_LogLevel.ERROR, logger.reportingLogLevel);
        Assert.areEqual(rflib_LogLevel.INFO, logger.flushLogStackLevel);
        Assert.areEqual(rflib_LogLevel.INFO, logger.batchReportingLogLevel);
        Assert.areEqual(rflib_LogLevel.WARN, logger.logAggregationLogLevel);
        
        Assert.areEqual(50, logger.logCacheSize);
        Assert.areEqual(true, logger.isLogMaskingEnabled);
    }
}
