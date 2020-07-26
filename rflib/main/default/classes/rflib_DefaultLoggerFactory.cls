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
 * @description `rflib_LoggerFactory` implementation to create a `rflib_DefaultLogger` instance configured based on the `rflib_Logger_Settings__c`. 
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_DefaultLoggerFactory implements rflib_LoggerFactory  {
    
    public rflib_Logger createLogger(String context) {
        return createFromCustomSettings(context, false);
    }
    
    public rflib_Logger createBatchedLogger(String context) {
        return createFromCustomSettings(context, true);
    }

    private rflib_Logger createFromCustomSettings(String context, Boolean shouldPublishEventsInBatch) {
        rflib_Logger logger = shouldPublishEventsInBatch ? 
            rflib_DefaultLogger.createBatchedLogger(context) :
            rflib_DefaultLogger.create(context);
    
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();
        if (settings.Log_Size__c != null) {
            logger.setLogCacheSize(Integer.valueOf(settings.Log_Size__c));
        }
    
        if (String.isNotBlank(settings.General_Log_Level__c)) {
            logger.setGeneralLogLevel(rflib_LogLevel.fromString(settings.General_Log_Level__c));
        }
    
        if (String.isNotBlank(settings.System_Debug_Log_Level__c)) {
            logger.setSystemDebugLevel(rflib_LogLevel.fromString(settings.System_Debug_Log_Level__c));
        }
    
        if (String.isNotBlank(settings.Log_Event_Reporting_Level__c)) {
            logger.setReportingLogLevel(rflib_LogLevel.fromString(settings.Log_Event_Reporting_Level__c));
        }
    
        if (String.isNotBlank(settings.Batched_Log_Event_Reporting_Level__c)) {
            logger.setBatchReportingLogLevel(rflib_LogLevel.fromString(settings.Batched_Log_Event_Reporting_Level__c));
        }
    
        return logger;
    }
    
    
}
