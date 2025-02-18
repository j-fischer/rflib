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
 * @description Logger controller to allow for clients to submit log messages.
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_LoggerController {
    
    /**
     * Retrieve the configuration settings for this users.
     */
    @AuraEnabled
    public static rflib_Logger_Settings__c getSettings(){
        return rflib_Logger_Settings__c.getInstance();
    }

    /**
     * Log action to be invoked from the client. THe statement will be logged using a custom settings logger.
     * This controller is used by the rflib_logger LWC module.
     * 
     * @param  platformInfo The platform information for the log statement.
     * @param  level   The level for the log statement.
     * @param  context The context for the log statement. 
     * @param  message message description
     * @param  stacktrace The stacktrace for the log statement.
     */
    @AuraEnabled
    public static void log(String platformInfo, String level, String context, String message, String stacktrace) {
        rflib_Logger logger = rflib_LoggerUtil.getFactory().createLogger(context);

        /* Overwriting configuration values for general log level, system log level, and reporting level to ensure that the 
         * client side log messages are managed by the client specific settings only, so that those log statements
         * are not "swallowed" by the server side settings. 
         */
        logger.setGeneralLogLevel(rflib_LogLevel.DEBUG);
        logger.setSystemDebugLevel(rflib_LogLevel.DEBUG);
        logger.setReportingLogLevel(rflib_LogLevel.INFO);
        logger.setFlushLogCacheLevel(rflib_LogLevel.NONE);

        logger.setPlatformInfo(platformInfo);
        logger.setStacktrace(stacktrace);

        switch on level.toUpperCase() {
            when 'TRACE' {
                System.debug(rflib_LogLevel.fromString(level).getLoggingLevel(), message);
            }
            
            when 'DEBUG' {
                System.debug(rflib_LogLevel.fromString(level).getLoggingLevel(), message);
            }

            when 'INFO' {
                logger.info(message);
            }

            when 'WARN' {
                logger.warn(message);
            }

            when 'ERROR' {
                logger.error(message);
            }

            when 'FATAL' {
                logger.fatal(message);
            }

            when else {
                logger.fatal('Failed to log {0} message for {1}: {2}', new List<Object> { level, context, message });
            }
        }
    }
}
