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
 * @description Utility class for the logging framework.
 */
public with sharing class rflib_LoggerUtil {
    @TestVisible
    private static rflib_LoggerFactory loggerFactory;

    /**
     * Return an instance of `rflib_LoggerFactory` based on the configuration of the `Logger Class Name` field in the Logger Settings.
     * @return   An instance of the configured `rflib_LoggerFactory`.
     */
    public static rflib_LoggerFactory getFactory() {
        if (loggerFactory == null) {
            rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();

            String loggerFactoryTypeName = settings != null && String.isNotBlank(settings.Logger_Factory_Class__c)
                ? settings.Logger_Factory_Class__c
                : 'rflib_DefaultLoggerFactory';

            Type handlerType = Type.forName(loggerFactoryTypeName);
            loggerFactory = (rflib_LoggerFactory) handlerType.newInstance();
        }

        return loggerFactory;
    }

    /**
     * Return an instance of `rflib_LogTimer` based on the configuration of the `Log Timer Class Name` field in the Logger Settings.
     * Uses `WARN` as the default log level.
     *
     * @param  logger The logger to be used when logging the message.
     * @param  threshold The threshold after which the elevated duration statement will be logged, otherwise it uses a TRACE level.
     * @param  message The message to be logged along with the duration of the execution.
     *
     * @return   An instance of the configured `rflib_LogTimer`.
     */
    public static rflib_LogTimer startLogTimer(rflib_Logger logger, Integer threshold, String message) {
        return startLogTimer(logger, threshold, message, rflib_LogLevel.WARN);
    }

    /**
     * Return an instance of `rflib_LogTimer` based on the configuration of the `Log Timer Class Name` field in the Logger Settings.
     *
     * @param  logger The logger to be used when logging the message.
     * @param  threshold The threshold after which the elevated duration statement will be logged, otherwise it uses a TRACE level.
     * @param  message The message to be logged along with the duration of the execution.
     * @param  logLevel The log level to be used when logging the message.
     *
     * @return   An instance of the configured `rflib_LogTimer`.
     */
    public static rflib_LogTimer startLogTimer(
        rflib_Logger logger,
        Integer threshold,
        String message,
        rflib_LogLevel logLevel
    ) {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();

        String logTimerTypeName = settings != null && String.isNotBlank(settings.Log_Timer_Class__c)
            ? settings.Log_Timer_Class__c
            : 'rflib_DefaultLogTimer';

        Type handlerType = Type.forName(logTimerTypeName);
        rflib_LogTimer logTimer = (rflib_LogTimer) handlerType.newInstance();

        logTimer.start(logger, logLevel, threshold, message);

        return logTimer;
    }

    /**
     * Return an instance of `Finalizer` based on the configuration of the `Log Finalizer Class Name` field in the Logger Settings.
     * @return   An instance of the configured `Finalizer`.
     */
    public static rflib_LogFinalizer createLogFinalizer(rflib_Logger logger) {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();

        String logFinalizerTypeName = settings != null && String.isNotBlank(settings.Log_Finalizer_Class__c)
            ? settings.Log_Finalizer_Class__c
            : 'rflib_DefaultLogFinalizer';

        Type handlerType = Type.forName(logFinalizerTypeName);
        rflib_LogFinalizer logFinalizer = (rflib_LogFinalizer) handlerType.newInstance();
        logFinalizer.setLogger(logger);

        return logFinalizer;
    }

    /**
     * Return an instance of `rflib_ApplicationEventLogger` based on the configuration of the `Application Event Logger Class Name` field in the Logger Settings.
     *
     * @return   An instance of the configured `rflib_ApplicationEventLogger`.
     */
    public static rflib_ApplicationEventLogger getApplicationEventLogger() {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();

        String logTimerTypeName = settings != null && String.isNotBlank(settings.Application_Event_Logger_Class__c)
            ? settings.Application_Event_Logger_Class__c
            : 'rflib_DefaultApplicationEventLogger';

        Type handlerType = Type.forName(logTimerTypeName);
        return (rflib_ApplicationEventLogger) handlerType.newInstance();
    }

    /**
     * Sets the `rflib_Logger`'s configuration using the values from the `Logger_Settings__c` custom setting for the current user.
     */
    public static void setLoggerSettings(rflib_Logger logger) {
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

        if (String.isNotBlank(settings.Flush_Log_Cache_Level__c)) {
            logger.setFlushLogCacheLevel(rflib_LogLevel.fromString(settings.Flush_Log_Cache_Level__c));
        }

        if (String.isNotBlank(settings.Batched_Log_Event_Reporting_Level__c)) {
            logger.setBatchReportingLogLevel(rflib_LogLevel.fromString(settings.Batched_Log_Event_Reporting_Level__c));
        }

        if (String.isNotBlank(settings.Log_Aggregation_Log_Level__c)) {
            logger.setLogAggregationLogLevel(rflib_LogLevel.fromString(settings.Log_Aggregation_Log_Level__c));
        }

        if (String.isNotBlank(settings.Apex_Contexts_to_Monitor__c)) {
            logger.setMonitoredContexts(settings.Apex_Contexts_to_Monitor__c);
        }

        logger.setLogMaskingState(settings.Enable_Log_Masking__c);
    }

    /**
     * Logs a message at the appropriate level (`INFO` or `DEBUG`) based on the value of the global setting
     * `RFLIB_Development_Mode_Enabled`. This method is intended for use in internal UI components.
     *
     * When `RFLIB_Development_Mode_Enabled` is `TRUE`, the message is logged at the `INFO` level.
     * When `RFLIB_Development_Mode_Enabled` is `FALSE`, the message is logged at the `DEBUG` level.
     *
     * @param logger The `rflib_Logger` instance to use for logging.
     * @param message The message to log. This should describe the action being logged.
     */
    public static void logInternal(rflib_Logger logger, String message) {
        logInternal(logger, message, null);
    }

    /**
     * Logs a message with optional arguments at the appropriate level (`INFO` or `DEBUG`) based on the value
     * of the global setting `RFLIB_Development_Mode_Enabled`. This method is intended for use in internal UI components.
     *
     * When `RFLIB_Development_Mode_Enabled` is `TRUE`, the message is logged at the `INFO` level.
     * When `RFLIB_Development_Mode_Enabled` is `FALSE`, the message is logged at the `DEBUG` level.
     *
     * @param logger The `rflib_Logger` instance to use for logging.
     * @param message The message to log. This should describe the action being logged.
     * @param args Optional arguments to include in the log message. These will be substituted into placeholders
     *             in the message string using `String.format`.
     */
    public static void logInternal(rflib_Logger logger, String message, Object[] args) {
        if (rflib_GlobalSettings.isDevelopmentModeEnabled) {
            logger.info(message, args);
        } else {
            logger.debug(message, args);
        }
    }

    private rflib_LoggerUtil() {
    }
}
