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
 * @description Default rflib_Logger implementation, which is based on the configuration
 *              stored in the Logger Settings Custom Setting object.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public without sharing class rflib_DefaultLogger implements rflib_Logger {
    @TestVisible
    private static final Integer MAX_MESSAGE_SIZE = 131072;
    @TestVisible
    private static final List<String> LOG_STATEMENTS = new List<String>();

    @TestVisible
    private static String PLATFORM_INFO = null;
    @TestVisible 
    private static String STACKTRACE = null;

    private static final String APPLICATION_EVENT_NAME_PATTERN = 'log-{0}-{1}';

    private static rflib_DefaultLogger.BatchLogEventExecutor BATCH_EXECUTOR = new rflib_DefaultLogger.BatchLogEventExecutor();

    private final String context;
    private final rflib_EventPublisher eventPublisher;
    private final rflib_DefaultLogger.DebugLogger debugLogger;
    private final List<String> logMessages;

    @TestVisible private Integer logCacheSize = 100;
    @TestVisible private Boolean isLogMaskingEnabled = false;
    @TestVisible private Boolean isMonitoredContext = false;

    @TestVisible private rflib_LogLevel generalLogLevel = rflib_LogLevel.DEBUG;
    @TestVisible private rflib_LogLevel systemDebugLevel = rflib_LogLevel.DEBUG;
    @TestVisible private rflib_LogLevel reportingLogLevel = rflib_LogLevel.WARN;
    @TestVisible private rflib_LogLevel flushLogStackLevel = rflib_LogLevel.NONE;
    @TestVisible private rflib_LogLevel batchReportingLogLevel = rflib_LogLevel.NONE;
    @TestVisible private rflib_LogLevel logAggregationLogLevel = rflib_LogLevel.NONE;
    
    @TestVisible private rflib_LogSource logSource = rflib_LogSource.Apex;
    
    /**
     * DEPRECATED - Use `new rflib_DefaultLoggerFactory.createLogger()` instead.
     *
     * Create an rflib_Logger instance for the given context based on the configuration of the Logger Custom Settings
     * associated with this user. Events are published immediately.
     *
     * @param  context The context identifier for this logger instance.
     * @return         A logger instance for the given context.
     */
    public static rflib_Logger createFromCustomSettings(String context) {
        return createFromCustomSettings(context, false);
    }

    /**
     * DEPRECATED - Use `new rflib_DefaultLoggerFactory.createLogger()` instead.
     *
     * Create an rflib_Logger instance for the given context based on the configuration of the Logger Custom Settings
     * associated with this user. Events are published in batches.
     *
     * @param  context The context identifier for this logger instance.
     * @return         A logger instance for the given context.
     */
    public static rflib_Logger createBatchedLoggerFromCustomSettings(String context) {
        return createFromCustomSettings(context, true);
    }

    /**
     * DEPRECATED - Use `new rflib_DefaultLoggerFactory.createLogger()` or `new rflib_DefaultLoggerFactory.createLogger()`
     *              depending on the value for `shouldPublishEventsInBatch` instead.
     *
     * Create an rflib_Logger instance for the given context based on the configuration of the Logger Custom Settings
     * associated with this user.
     *
     * @param  context The context identifier for this logger instance.
     * @param  shouldBatchEvents `Boolean` flag to indicate whether to publish events in batch or not. Batched events will require the invocation of `rflib_Logger.publishBatchedLogEvents()` to be dispatched.
     * @return         A logger instance for the given context.
     */
    public static rflib_Logger createFromCustomSettings(String context, Boolean shouldPublishEventsInBatch) {
        rflib_Logger logger = rflib_DefaultLogger.create(context, shouldPublishEventsInBatch);

        rflib_LoggerUtil.setLoggerSettings(logger);

        return logger;
    }

    /**
     * Create a default logger instance for the given context. Default values for the logger are:
     *    - cache size: 100
     *    - general log level: DEBUG
     *    - system debug level: DEBUG
     *    - reporting log level: WARN
     *    - event publishing: immediate
     *
     * @param  context The context for this logger.
     * @return         The new logger instance for the given context.
     */
    public static rflib_Logger create(String context) {
        return create(context, false);
    }

    /**
     * Create a default logger instance for the given context. Default values for the logger are:
     *    - cache size: 100
     *    - general log level: DEBUG
     *    - system debug level: DEBUG
     *    - reporting log level: WARN
     *    - event publishing: immediate
     *
     * @param  context The context for this logger.
     * @return         The new logger instance for the given context.
     */
    public static rflib_Logger createBatchedLogger(String context) {
        return create(context, true);
    }

    /**
     * Create a default logger instance for the given context. Default values for the logger are:
     *    - cache size: 100
     *    - general log level: DEBUG
     *    - system debug level: DEBUG
     *    - reporting log level: WARN
     *    - event publishing: immediate
     *
     * @param  context The context for this logger.
     * @param  shouldBatchEvents `Boolean` flag to indicate whether to publish events in batch or not. Batched events will require the invocation of `rflib_Logger.publishBatchedLogEvents()` to be dispatched.
     * @return         The new logger instance for the given context.
     */
    public static rflib_Logger create(String context, Boolean shouldBatchEvents) {
        return new rflib_DefaultLogger(context, shouldBatchEvents);
    }

    private rflib_DefaultLogger(String context, Boolean shouldBatchEvents) {
        this(
            shouldBatchEvents
                ? (rflib_EventPublisher) new rflib_DefaultLogger.BatchLogEventPublisher()
                : (rflib_EventPublisher) new rflib_DefaultLogger.LogEventPublisher(),
            new rflib_DefaultLogger.SystemDebugLogger(),
            context
        );
    }

    @TestVisible
    private rflib_DefaultLogger(
        rflib_EventPublisher eventPublisher,
        rflib_DefaultLogger.DebugLogger debugLogger,
        String context
    ) {
        this(eventPublisher, debugLogger, context, LOG_STATEMENTS);
    }

    private rflib_DefaultLogger(
        rflib_EventPublisher eventPublisher,
        rflib_DefaultLogger.DebugLogger debugLogger,
        String context,
        List<String> logMessages
    ) {
        this.eventPublisher = eventPublisher;
        this.debugLogger = debugLogger;
        this.context = context;
        this.logMessages = logMessages;
    }

    public void setLogCacheSize(Integer newSize) {
        logCacheSize = newSize;

        Integer numberOfCollectedMessages = logMessages.size();
        if (numberOfCollectedMessages > newSize) {
            for (Integer i = 0; i < (numberOfCollectedMessages - newSize); i++) {
                logMessages.remove(0);
            }
        }
    }

    public void setReportingLogLevel(rflib_LogLevel newLevel) {
        // NOTE: The reporting level can only be INFO or higher to prevent accidental
        //       "floods" of Log Events being created. Following best practices, DEBUG and TRACE statements
        //       should be used within loops and should ideally never cause a Log Event to be sent out.
        //       It is recommended that most log statements should be INFO level to provide the most transparency
        //       when reducing the reporting log level down to INFO.
        //       See https://github.com/j-fischer/rflib/issues/6 for more details.
        reportingLogLevel = rflib_LogLevel.INFO.encompasses(newLevel) || rflib_LogLevel.NONE == newLevel
            ? newLevel
            : rflib_LogLevel.INFO;
    }

    public void setFlushLogCacheLevel(rflib_LogLevel newLevel) {
        // NOTE: Because this log level is aligned with the reporting log level, the same restrictions
        //       apply with respect to the supported levels.
        flushLogStackLevel = rflib_LogLevel.INFO.encompasses(newLevel) || rflib_LogLevel.NONE == newLevel
            ? newLevel
            : rflib_LogLevel.INFO;
    }

    public void setBatchReportingLogLevel(rflib_LogLevel newLevel) {
        batchReportingLogLevel = newLevel;
    }

    public void setSystemDebugLevel(rflib_LogLevel newLevel) {
        systemDebugLevel = newLevel;
    }

    public void setGeneralLogLevel(rflib_LogLevel newLevel) {
        generalLogLevel = newLevel;
    }

    public void setLogMaskingState(Boolean isEnabled) {
        isLogMaskingEnabled = isEnabled;
    }

    public void setLogAggregationLogLevel(rflib_LogLevel newLevel) {
        // NOTE: The observability level can only be WARN or higher to prevent accidental
        //       "floods" of Application Events being created. Following best practices, DEBUG and TRACE statements
        //       should be used within loops and should ideally never cause a Log Event to be sent out.
        //       It is recommended that most log statements should be INFO level to provide the most transparency
        //       for logging purposes, while the observability has the focus to highlight issues in the application.
        logAggregationLogLevel = rflib_LogLevel.WARN.encompasses(newLevel) || rflib_LogLevel.NONE == newLevel
            ? newLevel
            : rflib_LogLevel.WARN;
    }

    public void setMonitoredContexts(String contextsToMonitor) {
        isMonitoredContext = false;
        if (String.isBlank(contextsToMonitor)) {
            return;
        }
    
        for (String monitoredContext : contextsToMonitor.split(',')) {
            if (context.toLowerCase().equals(monitoredContext.trim().toLowerCase())) {
                isMonitoredContext = true;
                return;
            }
        }
    }

    public void setPlatformInfo(String platformInfo) {
        PLATFORM_INFO = platformInfo;
    }

    public void setStacktrace(String newStacktrace) {
        STACKTRACE = newStacktrace;
    }
    
    public void setLogSource(rflib_LogSource source) {
        logSource = source;
    }
    
    public void trace(String message) {
        trace(message, null);
    }

    public void trace(String message, Object[] args) {
        logMessage(rflib_LogLevel.TRACE, message, args, null);
    }

    public void debug(String message) {
        debug(message, null);
    }

    public void debug(String message, Object[] args) {
        logMessage(rflib_LogLevel.DEBUG, message, args, null);
    }

    public void info(String message) {
        info(message, null);
    }

    public void info(String message, Object[] args) {
        logMessage(rflib_LogLevel.INFO, message, args, null);
    }

    public void warn(String message) {
        warn(message, null);
    }

    public void warn(String message, Object[] args) {
        logMessage(rflib_LogLevel.WARN, message, args, null);
    }

    public void error(String message) {
        error(message, null, null);
    }

    public void error(String message, Exception ex) {
        error(message, null, ex);
    }

    public void error(String message, Object[] args) {
        error(message, args, null);
    }

    public void error(String message, Object[] args, Exception ex) {
        logMessage(rflib_LogLevel.ERROR, message, args, ex);
    }

    public void fatal(String message) {
        fatal(message, null, null);
    }

    public void fatal(String message, Exception ex) {
        fatal(message, null, ex);
    }

    public void fatal(String message, Object[] args) {
        fatal(message, args, null);
    }

    public void fatal(String message, Object[] args, Exception ex) {
        logMessage(rflib_LogLevel.FATAL, message, args, ex);
    }

    public String printLogs() {
        String logMessages = 'Log statements reported by ' + context + ':\n' + String.join(logMessages, '\n');
        debugLogger.debug(LoggingLevel.DEBUG, logMessages);
        return logMessages;
    }

    public void reportLogs() {
        reportLogs(rflib_LogLevel.DEBUG);
    }

    public void publishBatchedLogEvents() {
        if (Limits.getDmlStatements() < Limits.getLimitDmlStatements()) {
            BATCH_EXECUTOR.execute(null);
        } else {
            System.enqueueJob(BATCH_EXECUTOR);
        }

        BATCH_EXECUTOR = new rflib_DefaultLogger.BatchLogEventExecutor();
    }

    private void reportLogs(rflib_LogLevel logLevel) {
        String messagesAsStr = String.join(logMessages, '\n');

        // It is important to run the masking rules first as those could change the size of the string, possibly making it larger.
        String maskedLogMessagesIfApplicable = isLogMaskingEnabled
            ? rflib_StringUtil.replaceWithAllMaskingRules(messagesAsStr)
            : messagesAsStr;

        Integer messageSize = maskedLogMessagesIfApplicable.length();

        // see https://github.com/j-fischer/rflib/issues/67
        String requestId = Request.getCurrent().getRequestId();
        if (requestId == null) {
            requestId = 'NULL';
        }

        String logMessageToPublish = messageSize < MAX_MESSAGE_SIZE
            ? maskedLogMessagesIfApplicable
            : maskedLogMessagesIfApplicable.substring(messageSize - MAX_MESSAGE_SIZE);

        List<SObject> platformEventsToLog = new List<SObject>();

        rflib_Log_Event__e eventToLog = new rflib_Log_Event__e(
            Source_System_ID__c = UserInfo.getOrganizationId(),
            Request_ID__c = requestId.substring(0, Math.min(requestId.length(), 40)),
            Log_Level__c = logLevel.toString(),
            Context__c = context.substring(0, Math.min(context.length(), 40)),
            Platform_Info__c = getPlatformInformation(),
            Log_Messages__c = logMessageToPublish,
            Stacktrace__c = getStacktrace()
        );

        platformEventsToLog.add(eventToLog);

        if (logAggregationLogLevel.encompasses(logLevel)) {
            String eventName = String.format(
                APPLICATION_EVENT_NAME_PATTERN,
                new List<String>{ logLevel.toString().toLowerCase(), context }
            );
            rflib_Application_Event_Occurred_Event__e appEventToLog = new rflib_Application_Event_Occurred_Event__e(
                Event_Name__c = eventName,
                Occurred_On__c = DateTime.now(),
                Related_Record_ID__c = rflib_DefaultApplicationEventService.NO_RECORD_ID,
                Additional_Details__c = logMessageToPublish,
                Created_By_ID__c = UserInfo.getUserId()
            );

            platformEventsToLog.add(appEventToLog);
        }

        if (batchReportingLogLevel.encompasses(logLevel)) {
            BATCH_EXECUTOR.addEvent(platformEventsToLog);
        } else {
            eventPublisher.publish(platformEventsToLog);

            if (flushLogStackLevel.encompasses(logLevel)) {
                LOG_STATEMENTS.clear();
            }
        }
    }

    private void logMessage(rflib_LogLevel logLevel, String message, Object[] args, Exception ex) {
        String messageToLog =
            DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss') +
            '|' +
            logLevel +
            '|' +
            rflib_TraceId.value +
            '|' +
            context;

        messageToLog = args == null || args.isEmpty()
            ? messageToLog + '|' + message
            : messageToLog + '|' + String.format(message, args);

        if (ex != null) {
            messageToLog =
                messageToLog +
                '\nMessage: ' +
                ex.getMessage() +
                '\nStracktrace: ' +
                ex.getStackTraceString();
        }

        if (systemDebugLevel.encompasses(logLevel)) {
            debugLogger.debug(logLevel.getLoggingLevel(), messageToLog);
        }

        if (!generalLogLevel.encompasses(logLevel)) {
            return;
        }

        if (logMessages.size() >= logCacheSize) {
            logMessages.remove(0);
        }

        logMessages.add(messageToLog);

        if (reportingLogLevel.encompasses(logLevel) || (reportingLogLevel != rflib_LogLevel.NONE && isMonitoredContext && rflib_LogLevel.INFO.encompasses(logLevel))) {
            reportLogs(logLevel);
        }
    }

    private String getStacktrace() {
        if (String.isNotBlank(STACKTRACE)) {
            return STACKTRACE;
        }

        String fullStacktrace = new DmlException().getStackTraceString();
        List<String> stackLines = fullStacktrace.split('\n');
        List<String> filteredLines = new List<String>();
        
        for (String line : stackLines) {
            if (!line.containsIgnoreCase('rflib_Default')) {
                filteredLines.add(line);
            }
        }
        
        return String.join(filteredLines, '\n');
    }

    private String getPlatformInformation() {
        if (String.isNotBlank(PLATFORM_INFO)) {
            return PLATFORM_INFO;
        }

        Map<String, Object> platformInfo = new Map<String, Object>();
        platformInfo.put('SOQL queries', Limits.getQueries());
        platformInfo.put('Query Rows', Limits.getQueryRows());
        platformInfo.put('SOSL Queries', Limits.getSoslQueries());
        platformInfo.put('DML Statements', Limits.getDmlStatements());
        platformInfo.put('DML Rows', Limits.getDmlRows());
        platformInfo.put('CPU Time', Limits.getCpuTime());
        platformInfo.put('Heap Size', Limits.getHeapSize());
        platformInfo.put('Callouts', Limits.getCallouts());
        platformInfo.put('Email Invocations', Limits.getEmailInvocations());
        platformInfo.put('Future Calls', Limits.getFutureCalls());
        platformInfo.put('Queueable Jobs', Limits.getQueueableJobs());
        platformInfo.put('Mobile Apex Push Calls', Limits.getMobilePushApexCalls());
        platformInfo.put('Publish Immediate DML', Limits.getPublishImmediateDML());
        platformInfo.put('Database Time', Limits.getDatabaseTime());
        platformInfo.put('Apex Curser Rows', Limits.getApexCursorRows());
        platformInfo.put('Fetch Call on Apex Curser', Limits.getFetchCallsOnApexCursor());

        return JSON.serialize(platformInfo);
    }

    public interface DebugLogger {
        void debug(LoggingLevel level, String message);
    }

    public class SystemDebugLogger implements DebugLogger {
        public void debug(LoggingLevel level, String message) {
            System.debug(level, message);
        }
    }

    public class LogEventPublisher implements rflib_EventPublisher {
        private final rflib_EventPublisher eventBusPublisher = new rflib_EventBusPublisher();

        public Integer getPublishingCounter() {
            return eventBusPublisher.getPublishingCounter();
        }

        public Database.SaveResult publish(SObject evt) {
            List<Database.SaveResult> result = publish(new List<SObject>{ evt });
            return result == null ? null : result[0];
        }

        public List<Database.SaveResult> publish(List<SObject> events) {
            Integer publishingLimitOrDefault = rflib_GlobalSettings.publishingLimitOrDefault != null
                ? rflib_GlobalSettings.publishingLimitOrDefault
                : Limits.getLimitPublishImmediateDML();

            if (Limits.getPublishImmediateDML() == Limits.getLimitPublishImmediateDML()) {
                System.debug(
                    LoggingLevel.ERROR,
                    'RFLIB: PublishImmediateDML Governor Limit reached; failed to publish ' + JSON.serialize(events)
                );
                return null;
            }

            if (eventBusPublisher.getPublishingCounter() == publishingLimitOrDefault) {
                System.debug(
                    LoggingLevel.ERROR,
                    'RFLIB: Publish Immediate DML limit (' +
                        publishingLimitOrDefault +
                        ') reached; failed to publish ' +
                        JSON.serialize(events)
                );
                return null;
            }

            // IMPORTANT: When using a List<SObject> for publishing a platform event within a read-only transaction (i.e. cacheable=true)
            // Salesforce will automatically assume that the events are not published immediately and consume a DML operation for the request.
            // Casting a list to a specific event allows Salesforce to infer that the event is published immediately, which will not cause a runtime exception.
            List<rflib_Log_Event__e> logEventsToPublish = new List<rflib_Log_Event__e>();
            List<rflib_Application_Event_Occurred_Event__e> appEventsToPublish = new List<rflib_Application_Event_Occurred_Event__e>();

            for (SObject evt : events) {
                Schema.SObjectType evtType = evt.getSObjectType();

                if (evtType == rflib_Log_Event__e.SObjectType) {
                    logEventsToPublish.add((rflib_Log_Event__e) evt);
                } else if (evtType == rflib_Application_Event_Occurred_Event__e.SObjectType) {
                    appEventsToPublish.add((rflib_Application_Event_Occurred_Event__e) evt);
                } else {
                    System.debug('Unhandled event type: ' + evtType.getDescribe().getName());
                }
            }

            List<Database.SaveResult> results = new List<Database.SaveResult>();
            results.addAll(
                eventBusPublisher.publish(addLogEventIfLimitIsReached(logEventsToPublish, publishingLimitOrDefault))
            );
            if (appEventsToPublish.size() > 0) {
                if (Limits.getPublishImmediateDML() == Limits.getLimitPublishImmediateDML() || eventBusPublisher.getPublishingCounter() == publishingLimitOrDefault) {
                    System.debug(
                        LoggingLevel.ERROR,
                        'RFLIB: PublishImmediateDML Governor Limit reached; failed to publish ' +
                        JSON.serialize(appEventsToPublish)
                    );
                } else {
                    results.addAll(eventBusPublisher.publish(appEventsToPublish));
                }
            }

            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    System.debug(LoggingLevel.ERROR, JSON.serialize(result.getErrors()));
                }
            }

            return results;
        }

        private List<SObject> addLogEventIfLimitIsReached(List<SObject> logEvents, Integer publishingLimitOrDefault) {
            if (eventBusPublisher.getPublishingCounter() < (publishingLimitOrDefault - 1)) {
                return logEvents;
            }

            String rflibInfoMessage =
                '>>>>> RFLIB: Publish Immediate DML limit (' +
                publishingLimitOrDefault +
                ') reached; THIS IS THE LAST EVENT FOR THIS TRANSACTION  <<<<<\n\n';
            String requestId = Request.getCurrent().getRequestId();
            if (requestId == null) {
                requestId = 'NULL';
            }

            logEvents.add(
                new rflib_Log_Event__e(
                    Request_ID__c = requestId.substring(0, Math.min(requestId.length(), 40)),
                    Log_Level__c = rflib_LogLevel.WARN.toString(),
                    Context__c = 'RFLIB_INTERNAL_WARNING',
                    Platform_Info__c = 'N/A',
                    Log_Messages__c = rflibInfoMessage
                )
            );

            return logEvents;
        }
    }

    public class BatchLogEventPublisher implements rflib_EventPublisher {
        private Integer publishingCounter = 0;

        public Integer getPublishingCounter() {
            return publishingCounter;
        }

        public Database.SaveResult publish(SObject event) {
            publishingCounter++;
            BATCH_EXECUTOR.addEvent((rflib_Log_Event__e) event);
            return null;
        }

        public List<Database.SaveResult> publish(List<SObject> events) {
            publishingCounter++;
            for (SObject event : events) {
                BATCH_EXECUTOR.addEvent((rflib_Log_Event__e) event);
            }
            return null;
        }
    }

    private class BatchLogEventExecutor implements Queueable {
        private final rflib_EventPublisher eventBusPublisher = new rflib_EventBusPublisher();

        private List<SObject> allEventsToBePublished = new List<SObject>();

        private rflib_Log_Event__e lastEventToBePublished;

        public void addEvent(rflib_Log_Event__e event) {
            lastEventToBePublished = event;
        }

        public void addEvent(List<SObject> platformEvents) {
            for (SObject pe : platformEvents) {
                if (pe instanceof rflib_Log_Event__e) {
                    addEvent((rflib_Log_Event__e) pe);
                } else {
                    allEventsToBePublished.add(pe);
                }
            }
        }

        public void execute(QueueableContext ctx) {
            if (lastEventToBePublished == null) {
                System.debug(LoggingLevel.INFO, 'There is no log event to be published; exiting.');
                return;
            }
            Database.SaveResult result = eventBusPublisher.publish(lastEventToBePublished);

            if (!result.isSuccess()) {
                System.debug(LoggingLevel.ERROR, JSON.serialize(result.getErrors()));
            }
        }
    }
}
