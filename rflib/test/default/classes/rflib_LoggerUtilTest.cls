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
private class rflib_LoggerUtilTest {

    private static final rflib_MockLogger LOGGER = new rflib_MockLogger();

    @IsTest
    private static void testGetFactory_DefaultValue() {
        Test.startTest();
        rflib_LoggerFactory factory = rflib_LoggerUtil.getFactory();
        Test.stopTest();

        Assert.isTrue(factory instanceof rflib_DefaultLoggerFactory, 'Default Logger Factory instance should be of type rflib_DefaultLoggerFactory');
    }

    @IsTest
    private static void testGetFactory_ConfiguredValue() {
        rflib_TestUtil.prepareLoggerForUnitTests();

        Test.startTest();
        rflib_LoggerFactory factory = rflib_LoggerUtil.getFactory();
        Test.stopTest();

        Assert.isTrue(factory instanceof rflib_MockLoggerFactory, 'Configured Logger Factory instance should be of type rflib_MockLoggerFactory');
    }

    @IsTest
    private static void testCreateLogTimer_DefaultValue() {
        Test.startTest();
        rflib_LogTimer logTimer = rflib_LoggerUtil.startLogTimer(LOGGER, 500, 'some message');
        Test.stopTest();

        Assert.isTrue(logTimer instanceof rflib_DefaultLogTimer, 'Default Logger Timer instance should be of type rflib_DefaultLogTimer');
    }

    @IsTest
    private static void testCreateLogTimer_ConfiguredValue() {
        rflib_TestUtil.prepareLoggerForUnitTests();

        Test.startTest();
        rflib_LogTimer logTimer = rflib_LoggerUtil.startLogTimer(LOGGER, 500, 'some message');
        Test.stopTest();

        Assert.isTrue(logTimer instanceof rflib_MockLogTimer, 'Configured LogTimer instance should be of type rflib_MockLogTimer');
    }

    @IsTest
    private static void testCreateLogFinalizer_DefaultValue() {
        Test.startTest();
        rflib_LogFinalizer logFinalizer = rflib_LoggerUtil.createLogFinalizer(LOGGER);
        Test.stopTest();

        Assert.isTrue(logFinalizer instanceof rflib_DefaultLogFinalizer, 'Default LogFinalizer instance should be of type rflib_DefaultLogFinalizer');
    }

    @IsTest
    private static void testCreateLogFinalizer_ConfiguredValue() {
        rflib_TestUtil.prepareLoggerForUnitTests();

        Test.startTest();
        rflib_LogFinalizer logFinalizer = rflib_LoggerUtil.createLogFinalizer(LOGGER);
        Test.stopTest();

        Assert.isTrue(logFinalizer instanceof rflib_MockLogFinalizer, 'Configured LogFinalizer instance should be of type rflib_MockLogFinalizer');
    }

    @IsTest
    private static void testGetApplicationEventLogger_DefaultValue() {
        Test.startTest();
        rflib_ApplicationEventLogger appEventLogger = rflib_LoggerUtil.getApplicationEventLogger();
        Test.stopTest();

        Assert.isTrue(appEventLogger instanceof rflib_DefaultApplicationEventLogger, 'Default Application Event Logger instance should be of type rflib_DefaultApplicationEventLogger');
    }

    @IsTest
    private static void testGetApplicationEventLogger_ConfiguredValue() {
        rflib_TestUtil.prepareLoggerForUnitTests();

        Test.startTest();
        rflib_ApplicationEventLogger appEventLogger = rflib_LoggerUtil.getApplicationEventLogger();
        Test.stopTest();

        Assert.isTrue(appEventLogger instanceof rflib_MockApplicationEventLogger, 'Configured Logger Factory instance should be of type rflib_MockApplicationEventLogger');
    }
    
    @isTest
    static void testSetLoggerSettings() {
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
    }}
