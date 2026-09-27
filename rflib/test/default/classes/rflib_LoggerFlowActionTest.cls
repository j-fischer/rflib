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
private class rflib_LoggerFlowActionTest {
    
    private static final rflib_MockLoggerFactory loggerFactory = new rflib_MockLoggerFactory();

    @IsTest
    private static void testLogMessage_Fatal() {
        rflib_LoggerFlowAction.loggerFactory = loggerFactory;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(createMessageInfo('fatal'));
        Test.stopTest();

        System.assert(loggerFactory.debugLogCapture.containsInAnyMessage('FATAL'), 'debugLogger did not contain FATAL message'); 
    }
    
    @IsTest
    private static void testLogMessage_Error() {
        rflib_LoggerFlowAction.loggerFactory = loggerFactory;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(createMessageInfo('error'));
        Test.stopTest();

        System.assert(loggerFactory.debugLogCapture.containsInAnyMessage('ERROR'), 'debugLogger did not contain ERROR message');
    }

    @IsTest
    private static void testLogMessage_Warn() {
        rflib_LoggerFlowAction.loggerFactory = loggerFactory;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(createMessageInfo('warn'));
        Test.stopTest();

        System.assert(loggerFactory.debugLogCapture.containsInAnyMessage('WARN'), 'debugLogger did not contain WARN message');
    }

    @IsTest
    private static void testLogMessage_Info() {
        rflib_LoggerFlowAction.loggerFactory = loggerFactory;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(createMessageInfo('info'));
        Test.stopTest();

        System.assert(loggerFactory.debugLogCapture.containsInAnyMessage('INFO'), 'debugLogger did not contain INFO message');
    }

    @IsTest
    private static void testLogMessage_ValidateLogSource() {
        rflib_MockLoggerFactory mockLoggerFactory = new rflib_MockLoggerFactory(rflib_LogLevel.INFO, rflib_LogLevel.INFO);
        rflib_LoggerFlowAction.loggerFactory = mockLoggerFactory;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(createMessageInfo('info'));
        Test.stopTest();

        // Verify that the log source is set to Flow
        System.assertEquals(rflib_LogSource.Flow.toString(), mockLoggerFactory.eventCapture.getEvent().Log_Source__c);
    }

    @IsTest
    private static void testLogMessage_Debug() {
        rflib_MockLoggerFactory debugLogFactory = new rflib_MockLoggerFactory(rflib_LogLevel.DEBUG);
        rflib_LoggerFlowAction.loggerFactory = debugLogFactory;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(createMessageInfo('debug'));
        Test.stopTest();

        System.assert(debugLogFactory.debugLogCapture.containsInAnyMessage('DEBUG'), 'debugLogger did not contain DEBUG message');
    }

    @IsTest
    private static void testLogMessage_UnknownLogLevel() {
        rflib_MockLoggerFactory debugLogFactory = new rflib_MockLoggerFactory(rflib_LogLevel.DEBUG);
        rflib_LoggerFlowAction.loggerFactory = debugLogFactory;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(createMessageInfo('foobar'));
        Test.stopTest();

        System.assert(debugLogFactory.debugLogCapture.containsInAnyMessage('DEBUG'), 'debugLogger did not contain DEBUG message for unknown log level');
    }

    @IsTest
    private static void testLogMessage_NullBatchReporting() {
        rflib_LoggerFlowAction.loggerFactory = loggerFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = createMessageInfo('info');
        messages[0].useBatchReporting = null;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(messages);
        Test.stopTest();

        System.assert(loggerFactory.debugLogCapture.containsInAnyMessage('INFO'), 'debugLogger did not contain INFO message');
    }

    @IsTest
    private static void testLogMessage_TerminateTransaction() {
        rflib_LoggerFlowAction.loggerFactory = loggerFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = createMessageInfo('error');
        messages[0].message = 'Fault in {0}';
        messages[0].args = new List<String> { 'Create_Contact' };
        messages[0].terminateTransaction = true;

        Test.startTest();
        try {
            rflib_LoggerFlowAction.logMessage(messages);
            Assert.fail('Expected FlowTerminationException to be thrown');
        } catch (rflib_LoggerFlowAction.FlowTerminationException ex) {
            Assert.areEqual('Fault in Create_Contact', ex.getMessage(), 'Exception message did not match the formatted log message');
        }
        Test.stopTest();

        Assert.isTrue(loggerFactory.debugLogCapture.containsInAnyMessage('ERROR'), 'debugLogger did not contain ERROR message');
    }

    @IsTest
    private static void testLogMessage_TerminateTransactionPublishesImmediately() {
        BatchingLoggerFactory batchingFactory = new BatchingLoggerFactory();
        rflib_LoggerFlowAction.loggerFactory = batchingFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = createMessageInfo('error');
        messages[0].useBatchReporting = true;
        messages[0].terminateTransaction = true;

        Test.startTest();
        try {
            rflib_LoggerFlowAction.logMessage(messages);
            Assert.fail('Expected FlowTerminationException to be thrown');
        } catch (rflib_LoggerFlowAction.FlowTerminationException ex) {
            Assert.areEqual('This is a message', ex.getMessage(), 'Exception message did not match the log message');
        }
        Test.stopTest();

        Assert.areEqual(0, batchingFactory.batchedLoggerCount, 'A terminating message must not use a batched logger');
        Assert.areEqual(1, batchingFactory.publisher.publishCount, 'Log event was not published before terminating');
        Assert.areEqual('ERROR', batchingFactory.publisher.getLastLogEvent().Log_Level__c, 'Published event has the wrong log level');
    }

    @IsTest
    private static void testLogMessage_TerminateTransactionBulkPublishesOnce() {
        BatchingLoggerFactory batchingFactory = new BatchingLoggerFactory();
        rflib_LoggerFlowAction.loggerFactory = batchingFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = new List<rflib_LoggerFlowAction.LogMessageInfo>();
        for (Integer i = 0; i < 200; i++) {
            rflib_LoggerFlowAction.LogMessageInfo messageInfo = createMessageInfo('error')[0];
            messageInfo.message = 'Fault in record {0}';
            messageInfo.args = new List<String> { String.valueOf(i) };
            messageInfo.terminateTransaction = true;
            messages.add(messageInfo);
        }

        Test.startTest();
        try {
            rflib_LoggerFlowAction.logMessage(messages);
            Assert.fail('Expected FlowTerminationException to be thrown');
        } catch (rflib_LoggerFlowAction.FlowTerminationException ex) {
            Assert.areEqual('Fault in record 0', ex.getMessage(), 'Exception message did not match the first terminating message');
        }
        Test.stopTest();

        Assert.areEqual(1, batchingFactory.publisher.publishCount, 'Bulk terminating messages must be published as a single event');

        rflib_Log_Event__e logEvent = batchingFactory.publisher.getLastLogEvent();
        Assert.areEqual('ERROR', logEvent.Log_Level__c, 'Published event has the wrong log level');
        Assert.isTrue(logEvent.Log_Messages__c.contains('Fault in record 199'), 'Published event is missing the last message');
        Assert.isTrue(logEvent.Log_Messages__c.contains('Fault in record 150'), 'Published event is missing buffered messages');
    }

    @IsTest
    private static void testLogMessage_TerminateTransactionBulkPublishesMostSevereMessage() {
        BatchingLoggerFactory batchingFactory = new BatchingLoggerFactory(rflib_LogLevel.ERROR);
        rflib_LoggerFlowAction.loggerFactory = batchingFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = new List<rflib_LoggerFlowAction.LogMessageInfo> {
            createTerminatingMessageInfo('foobar', 'Unknown level first'),
            createTerminatingMessageInfo('fatal', 'Fatal second'),
            createTerminatingMessageInfo('error', 'Error third'),
            createTerminatingMessageInfo('info', 'Info last')
        };

        Test.startTest();
        try {
            rflib_LoggerFlowAction.logMessage(messages);
            Assert.fail('Expected FlowTerminationException to be thrown');
        } catch (rflib_LoggerFlowAction.FlowTerminationException ex) {
            Assert.areEqual('Unknown level first', ex.getMessage(), 'Exception message did not match the first terminating message');
        }
        Test.stopTest();

        Assert.areEqual(1, batchingFactory.publisher.publishCount, 'Bulk terminating messages must be published as a single event');

        rflib_Log_Event__e logEvent = batchingFactory.publisher.getLastLogEvent();
        Assert.areEqual('FATAL', logEvent.Log_Level__c, 'Event must be published at the most severe level');
        for (String message : new List<String> { 'Unknown level first', 'Fatal second', 'Error third', 'Info last' }) {
            Assert.isTrue(logEvent.Log_Messages__c.contains(message), 'Published event is missing: ' + message);
        }
    }

    @IsTest
    private static void testLogMessage_TerminateTransactionCombinesNonTerminatingMessages() {
        BatchingLoggerFactory batchingFactory = new BatchingLoggerFactory(rflib_LogLevel.ERROR);
        rflib_LoggerFlowAction.loggerFactory = batchingFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = new List<rflib_LoggerFlowAction.LogMessageInfo>();
        rflib_LoggerFlowAction.LogMessageInfo fatalMessage = createMessageInfo('fatal')[0];
        fatalMessage.message = 'Fatal non-terminating';
        fatalMessage.useBatchReporting = true;
        messages.add(fatalMessage);

        for (Integer i = 0; i < 159; i++) {
            rflib_LoggerFlowAction.LogMessageInfo errorMessage = createMessageInfo('error')[0];
            errorMessage.message = 'Error non-terminating {0}';
            errorMessage.args = new List<String> { String.valueOf(i) };
            messages.add(errorMessage);
        }
        messages.add(createTerminatingMessageInfo('info', 'Info terminating'));

        Test.startTest();
        try {
            rflib_LoggerFlowAction.logMessage(messages);
            Assert.fail('Expected FlowTerminationException to be thrown');
        } catch (rflib_LoggerFlowAction.FlowTerminationException ex) {
            Assert.areEqual('Info terminating', ex.getMessage(), 'Exception message did not match the terminating message');
        }
        Test.stopTest();

        Assert.areEqual(0, batchingFactory.batchedLoggerCount, 'A terminating invocation must not use batched loggers');
        Assert.areEqual(1, batchingFactory.publisher.publishCount, 'A terminating invocation must be published as a single event');

        rflib_Log_Event__e logEvent = batchingFactory.publisher.getLastLogEvent();
        Assert.areEqual('FATAL', logEvent.Log_Level__c, 'Event must be published at the most severe level');
        for (String message : new List<String> { 'Fatal non-terminating', 'Error non-terminating 158', 'Info terminating' }) {
            Assert.isTrue(logEvent.Log_Messages__c.contains(message), 'Published event is missing: ' + message);
        }
    }

    @IsTest
    private static void testLogMessage_TerminateTransactionWithNullMessage() {
        BatchingLoggerFactory batchingFactory = new BatchingLoggerFactory();
        rflib_LoggerFlowAction.loggerFactory = batchingFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = new List<rflib_LoggerFlowAction.LogMessageInfo> {
            createTerminatingMessageInfo('error', null)
        };

        Test.startTest();
        try {
            rflib_LoggerFlowAction.logMessage(messages);
            Assert.fail('Expected FlowTerminationException to be thrown');
        } catch (rflib_LoggerFlowAction.FlowTerminationException ex) {
            Assert.areEqual(
                'The Flow was terminated by the RFLIB Log Message action.',
                ex.getMessage(),
                'Exception message did not fall back to the default message'
            );
        }
        Test.stopTest();

        Assert.areEqual(1, batchingFactory.publisher.publishCount, 'Log event was not published before terminating');
    }

    @IsTest
    private static void testLogMessage_BatchReportingWithoutTermination() {
        BatchingLoggerFactory batchingFactory = new BatchingLoggerFactory();
        rflib_LoggerFlowAction.loggerFactory = batchingFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = createMessageInfo('error');
        messages[0].useBatchReporting = true;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(messages);
        Test.stopTest();

        Assert.areEqual(1, batchingFactory.batchedLoggerCount, 'Batch reporting did not use a batched logger');
        Assert.areEqual(0, batchingFactory.publisher.publishCount, 'Batched log event should not be published immediately');
    }

    @IsTest
    private static void testLogMessage_TerminateTransactionFalse() {
        rflib_LoggerFlowAction.loggerFactory = loggerFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = createMessageInfo('error');
        messages[0].terminateTransaction = false;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(messages);
        Test.stopTest();

        Assert.isTrue(loggerFactory.debugLogCapture.containsInAnyMessage('ERROR'), 'debugLogger did not contain ERROR message');
    }

    @IsTest
    private static void testLogMessage_TerminateTransactionNull() {
        rflib_LoggerFlowAction.loggerFactory = loggerFactory;

        List<rflib_LoggerFlowAction.LogMessageInfo> messages = createMessageInfo('error');
        messages[0].terminateTransaction = null;

        Test.startTest();
        rflib_LoggerFlowAction.logMessage(messages);
        Test.stopTest();

        Assert.isTrue(loggerFactory.debugLogCapture.containsInAnyMessage('ERROR'), 'debugLogger did not contain ERROR message');
    }

    private static List<rflib_LoggerFlowAction.LogMessageInfo> createMessageInfo(String logLevel) {
        rflib_LoggerFlowAction.LogMessageInfo result = new rflib_LoggerFlowAction.LogMessageInfo();

        result.context = 'rflib_LoggerFlowActionTest';
        result.logLevel = logLevel;
        result.message = 'This is a message';

        return new List<rflib_LoggerFlowAction.LogMessageInfo> { result };
    }

    private static rflib_LoggerFlowAction.LogMessageInfo createTerminatingMessageInfo(String logLevel, String message) {
        rflib_LoggerFlowAction.LogMessageInfo result = createMessageInfo(logLevel)[0];
        result.message = message;
        result.terminateTransaction = true;
        return result;
    }

    // Creates loggers that queue log events until the end of the transaction, like the Batched Log Event Reporting Level setting
    private class BatchingLoggerFactory implements rflib_LoggerFactory {
        public final CountingEventPublisher publisher = new CountingEventPublisher();
        public final rflib_MockLoggerFactory.DebugLogCapture debugLogCapture = new rflib_MockLoggerFactory.DebugLogCapture();
        public Integer batchedLoggerCount = 0;

        private final rflib_LogLevel reportingLogLevel;

        public BatchingLoggerFactory() {
            this(rflib_LogLevel.INFO);
        }

        public BatchingLoggerFactory(rflib_LogLevel reportingLogLevel) {
            this.reportingLogLevel = reportingLogLevel;
        }

        public rflib_Logger createLogger(String context) {
            rflib_DefaultLogger result = new rflib_DefaultLogger(publisher, debugLogCapture, context);
            result.setReportingLogLevel(reportingLogLevel);
            result.setBatchReportingLogLevel(rflib_LogLevel.INFO);
            return result;
        }

        public rflib_Logger createBatchedLogger(String context) {
            batchedLoggerCount++;
            return createLogger(context);
        }
    }

    // Counts every publish call, since each one consumes a Publish Immediate DML statement
    private class CountingEventPublisher implements rflib_EventPublisher {
        public Integer publishCount = 0;
        private rflib_Log_Event__e lastLogEvent;

        public Integer getPublishingCounter() {
            return publishCount;
        }

        public Database.SaveResult publish(SObject event) {
            publish(new List<SObject> { event });
            return null;
        }

        public List<Database.SaveResult> publish(List<SObject> events) {
            publishCount++;
            for (SObject event : events) {
                if (event instanceof rflib_Log_Event__e) {
                    lastLogEvent = (rflib_Log_Event__e) event;
                }
            }
            return null;
        }

        public rflib_Log_Event__e getLastLogEvent() {
            Assert.isNotNull(lastLogEvent, 'No log event was published');
            return lastLogEvent;
        }
    }
    
}
