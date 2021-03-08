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
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_StartLogTimerFlowAction {    

    public static final Map<String, rflib_LogTimer> STARTED_LOG_TIMERS = new Map<String, rflib_LogTimer>();

    @TestVisible
    private static rflib_LoggerFactory loggerFactory = rflib_LoggerUtil.getFactory();

    @InvocableMethod(label='Start Log Timer' category='RFLIB' description='Start a Log Timer')
    public static void startLogTimer(List<StartLogTimerInfo> logTimerInfos) {

        for (StartLogTimerInfo logTimerInfo : logTimerInfos) {
            rflib_Logger logger = loggerFactory.createLogger(logTimerInfo.context);

           rflib_LogTimer logTimer = rflib_LoggerUtil.startLogTimer(logger, logTimerInfo.threshold, logTimerInfo.message, rflib_LogLevel.fromString(logTimerInfo.logLevel));
           
           STARTED_LOG_TIMERS.put(logTimerInfo.logTimerName, logTimer);
        }
    }

    public class StartLogTimerInfo {

        @InvocableVariable(label='Log Timer Name' description='An unique identifier for the log timer for the current transaction' required=true)
        public String logTimerName;

        @InvocableVariable(label='Context' description='The context of your log message, i.e. Flow/Process name' required=true)
        public String context;
        
        @InvocableVariable(label='Timer Threshold' description='The time in milliseconds after which the timer will log the message under the provided log level' required=true)
        public Integer threshold;
        
        @InvocableVariable(label='Log Level' description='The log level used when the timer exceeds the threshold: INFO, WARN, ERROR, FATAL' required=true)
        public String logLevel;
        
        @InvocableVariable(label='Message' description='The actual log message' required=true)
        public String message;

        @InvocableVariable(label='Use Batch Reporting' description='Will configure the logger to always use batch reporting for the given message' required=false)
        public Boolean useBatchReporting = false;
    }
}
