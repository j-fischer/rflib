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

    @InvocableMethod(label='Log Message' category='RFLIB' description='Log message(s) to the current transaction log')
    public static void logMessage(List<LogMessageInfo> logMessages) {

        for (LogMessageInfo messageInfo : logMessages) {
            rflib_Logger logger = messageInfo.useBatchReporting ? 
                loggerFactory.createBatchedLogger(messageInfo.context) :
                loggerFactory.createLogger(messageInfo.context);

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
    }

    public class LogMessageInfo {

        @InvocableVariable(label='Context' description='The context of your log message, i.e. Flow/Process name' required=true)
        public String context;
        
        @InvocableVariable(label='Log Level' description='The log level for the message: TRACE, DEBUG, INFO, WARN, ERROR, FATAL' required=true)
        public String logLevel;
        
        @InvocableVariable(label='Message' description='The actual log message' required=true)
        public String message;

        @InvocableVariable(label='Use Batch Reporting' description='Will configure the logger to always use batch reporting for the given message' required=false)
        public Boolean useBatchReporting = false;
        
        @InvocableVariable(label='Message Arguments' description='The arguments to be inserted into the message. Arguments must be of type string' required=false)
        public List<String> args;
    }
}
