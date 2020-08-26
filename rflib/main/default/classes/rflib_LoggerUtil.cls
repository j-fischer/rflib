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
 * @description Utility class for the logging framework.
 */ 
public with sharing class rflib_LoggerUtil {
    
    private static rflib_LoggerFactory loggerFactory;

    /**
     * Return an instance of `rflib_LoggerFactory` based on the configuration of the `Logger Class Name` field in the Logger Settings. 
     * @return   An instance of the configured `rflib_LoggerFactory`.
     */
    public static rflib_LoggerFactory getFactory() {
        if (loggerFactory == null) {
            rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();
    
            String loggerFactoryTypeName = settings != null && String.isNotBlank(settings.Logger_Factory_Class__c) ?
                settings.Logger_Factory_Class__c : 
                'rflib_DefaultLoggerFactory';
    
            Type handlerType = Type.forName(loggerFactoryTypeName);
            loggerFactory =  (rflib_LoggerFactory) handlerType.newInstance();
        }

        return loggerFactory;
    }

    /**
     * Return an instance of `rflib_LogTimer` based on the configuration of the `Log Timer Class Name` field in the Logger Settings. 
     * Uses `WARN` as the default log level.
     * @return   An instance of the configured `rflib_LogTimer`.
     */
    public static rflib_LogTimer createLogTimer(rflib_Logger logger, Integer threshold, String message) {
        return createLogTimer(logger, threshold, message, rflib_LogLevel.WARN);
    }

    /**
     * Return an instance of `rflib_LogTimer` based on the configuration of the `Log Timer Class Name` field in the Logger Settings. 
     * @return   An instance of the configured `rflib_LogTimer`.
     */
    public static rflib_LogTimer createLogTimer(rflib_Logger logger, Integer threshold, String message, rflib_LogLevel logLevel) {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();

        String logTimerTypeName = settings != null && String.isNotBlank(settings.Log_Timer_Class__c) ?
            settings.Log_Timer_Class__c : 
            'rflib_DefaultLogTimer';

        Type handlerType = Type.forName(logTimerTypeName);
        rflib_LogTimer logTimer =  (rflib_LogTimer) handlerType.newInstance();

        logTimer.start(logger, logLevel, threshold, message);

        return logTimer;
    }
    
    private rflib_LoggerUtil() { }
}
