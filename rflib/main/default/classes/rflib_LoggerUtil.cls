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
     * Return an instance of `rflib_LoggerFactory` based on the configuration of the `Logger Factory Class` field in the Logger Settings. 
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
     * Return an instance of `Finalizer` based on the configuration of the `Log Finalizer Class Name` field in the Logger Settings. 
     * @return   An instance of the configured `Finalizer`.
     */
    public static rflib_LogFinalizer createLogFinalizer(rflib_Logger logger) {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();

        String logFinalizerTypeName = settings != null && String.isNotBlank(settings.Log_Finalizer_Class__c) ?
            settings.Logger_Factory_Class__c : 
            'rflib_DefaultLogFinalizer';

        Type handlerType = Type.forName(logFinalizerTypeName);
        rflib_LogFinalizer logFinalizer =  (rflib_LogFinalizer) handlerType.newInstance();
        logFinalizer.setLogger(logger);

        return logFinalizer;
    }
    
    private rflib_LoggerUtil() { }
}
