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
 * @description Executes an action configurable in Process and Flow Builder to log a message. 
 *              In the context of a record change, these message will be merged with the messages
 *              of a trigger and reported in context. 
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_LoggerFlowAction {
    
    @TestVisible
    private static rflib_LoggerFactory loggerFactory = rflib_LoggerUtil.getFactory();

    private static final String DEFAULT_TERMINATION_MESSAGE = 'The Flow was terminated by the RFLIB Log Message action.';

    @InvocableMethod(label='Log Message' category='RFLIB' description='Log message(s) to the current transaction log' iconName='resource:rflib_LoggerActionIcon:icon')
    public static void logMessage(List<LogMessageInfo> logMessages) {
        Integer firstTerminatingIndex = -1;
        for (Integer i = 0; i < logMessages.size(); i++) {
            if (logMessages[i].terminateTransaction == true) {
                firstTerminatingIndex = i;
                break;
            }
        }

        if (firstTerminatingIndex < 0) {
            for (LogMessageInfo messageInfo : logMessages) {
                logSingleMessage(messageInfo, false, false);
            }
            return;
        }

        // Bulkified interviews terminate together, and the transaction is rolled back. To guarantee that the log survives
        // within the Publish Immediate DML limit, all messages are combined into a single event, published by the most
        // severe message. It is logged last, so the event contains all other buffered messages.
        Integer publishingIndex = 0;
        rflib_LogLevel publishingLevel = getEffectiveLogLevel(logMessages[0].logLevel);
        for (Integer i = 1; i < logMessages.size(); i++) {
            rflib_LogLevel logLevel = getEffectiveLogLevel(logMessages[i].logLevel);
            if (publishingLevel.encompasses(logLevel)) {
                publishingIndex = i;
                publishingLevel = logLevel;
            }
        }

        for (Integer i = 0; i < logMessages.size(); i++) {
            if (i != publishingIndex) {
                logSingleMessage(logMessages[i], true, false);
            }
        }
        logSingleMessage(logMessages[publishingIndex], true, true);

        throw new FlowTerminationException(getTerminationMessage(logMessages[firstTerminatingIndex]));
    }

    private static void logSingleMessage(LogMessageInfo messageInfo, Boolean isTerminating, Boolean isPublishing) {
        // Batched events are dispatched after the transaction, which a termination rolls back, so messages of a
        // terminating invocation are published immediately. rflib_Log_Event__e is PublishImmediately and survives the rollback.
        rflib_Logger logger = messageInfo.useBatchReporting == true && !isTerminating ?
            loggerFactory.createBatchedLogger(messageInfo.context) :
            loggerFactory.createLogger(messageInfo.context);

        if (isTerminating) {
            logger.setBatchReportingLogLevel(rflib_LogLevel.NONE);

            if (!isPublishing) {
                logger.setReportingLogLevel(rflib_LogLevel.NONE);
            }
        }

        // Set the log source to Flow
        logger.setLogSource(rflib_LogSource.Flow);

        switch on messageInfo.logLevel.toUpperCase() {
            when 'FATAL' {
                logger.fatal(messageInfo.message, messageInfo.args);
            }

            when 'ERROR' {
                logger.error(messageInfo.message, messageInfo.args);
            }

            when 'WARN' {
                logger.warn(messageInfo.message, messageInfo.args);
            }

            when 'INFO' {
                logger.info(messageInfo.message, messageInfo.args);
            }

            when 'DEBUG' {
                logger.debug(messageInfo.message, messageInfo.args);
            }

            when else {
                logger.debug(messageInfo.message, messageInfo.args);
            }
        }
    }

    // A Flow resource mapped to the message can be null at runtime, which must not prevent the termination
    private static String getTerminationMessage(LogMessageInfo messageInfo) {
        if (String.isBlank(messageInfo.message)) {
            return DEFAULT_TERMINATION_MESSAGE;
        }

        return messageInfo.args == null || messageInfo.args.isEmpty()
            ? messageInfo.message
            : String.format(messageInfo.message, messageInfo.args);
    }

    // Unknown log levels are logged as DEBUG
    private static rflib_LogLevel getEffectiveLogLevel(String logLevel) {
        rflib_LogLevel result = rflib_LogLevel.fromString(logLevel);
        return result == rflib_LogLevel.NONE ? rflib_LogLevel.DEBUG : result;
    }

    /**
     * @description Thrown when a log message requests the termination of the transaction. The exception is not caught
     *              by the Flow, which fails the interview the same way as a fault without a fault path.
     */
    public class FlowTerminationException extends Exception {}

    public class LogMessageInfo {

        @InvocableVariable(
            label='Context' 
            description='The context of your log message, i.e. Flow/Process name' 
            required=true
            placeholderText='40 chars max, consider using the name of flow'
        )
        public String context;
        
        @InvocableVariable(
            label='Log Level' 
            description='The log level for the message: TRACE, DEBUG, INFO, WARN, ERROR, FATAL' 
            required=true
            placeholderText='INFO, WARN, ERROR, or FATAL'
        )
        public String logLevel;
        
        @InvocableVariable(
            label='Message' 
            description='The actual log message' 
            required=true
            placeholderText='Any text, supports expressions'
        )
        public String message;

        @InvocableVariable(
            label='Use Batch Reporting' 
            description='Will configure the logger to always use batch reporting for the given message' 
            required=false
        )
        public Boolean useBatchReporting = false;
        
        @InvocableVariable(
            label='Message Arguments' 
            description='The arguments to be inserted into the message. Arguments must be of type string' 
            required=false
        )
        public List<String> args;

        @InvocableVariable(
            label='Terminate Transaction'
            description='When true, the action throws an exception after logging so that the Flow fails as if no fault path was defined. The log event is published immediately, ignoring batch reporting. Use on fault paths only.'
            required=false
        )
        public Boolean terminateTransaction = false;
    }
}
