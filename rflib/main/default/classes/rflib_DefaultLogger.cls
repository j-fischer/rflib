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

  @TestVisible private static final Integer MAX_MESSAGE_SIZE = 131072;
  @TestVisible private static final List<String> LOG_STATEMENTS = new List<String>(); 

  @TestVisible private static String PLATFORM_INFO = null; 

  private static rflib_DefaultLogger.BatchLogEventExecutor BATCH_EXECUTOR = new rflib_DefaultLogger.BatchLogEventExecutor();

  private final String context;
  private final rflib_EventPublisher eventPublisher;
  private final rflib_DefaultLogger.DebugLogger debugLogger;
  private final List<String> logMessages;

  private Integer logCacheSize = 100;
  private Boolean isLogMaskingEnabled = false;

  private rflib_LogLevel generalLogLevel = rflib_LogLevel.DEBUG;
  private rflib_LogLevel systemDebugLevel = rflib_LogLevel.DEBUG;
  private rflib_LogLevel reportingLogLevel = rflib_LogLevel.WARN;
  private rflib_LogLevel flushLogStackLevel = rflib_LogLevel.NONE;
  private rflib_LogLevel batchReportingLogLevel = rflib_LogLevel.NONE;

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
   * DEPRECATED - Use `new rflib_DefaultLoggerFactory.createBatchedLogger()` instead.
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
   * DEPRECATED - Use `new rflib_DefaultLoggerFactory.createLogger()` or `new rflib_DefaultLoggerFactory.createBatchedLogger()` 
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

    logger.setLogMaskingState(settings.Enable_Log_Masking__c);

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
      shouldBatchEvents ? 
        (rflib_EventPublisher) new rflib_DefaultLogger.BatchLogEventPublisher() : 
        (rflib_EventPublisher) new rflib_DefaultLogger.LogEventPublisher(), 
      new rflib_DefaultLogger.SystemDebugLogger(), 
      context
    );
  }

  @TestVisible
  private rflib_DefaultLogger(
        rflib_EventPublisher eventPublisher, 
        rflib_DefaultLogger.DebugLogger debugLogger, 
        String context) {
    this(eventPublisher, debugLogger, context, LOG_STATEMENTS);
  }

  private rflib_DefaultLogger(
        rflib_EventPublisher eventPublisher, 
        rflib_DefaultLogger.DebugLogger debugLogger, 
        String context,
        List<String> logMessages) {
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
    reportingLogLevel = rflib_LogLevel.INFO.encompasses(newLevel) || rflib_LogLevel.NONE == newLevel ? 
      newLevel : 
      rflib_LogLevel.INFO;
  }

  public void setFlushLogCacheLevel(rflib_LogLevel newLevel) {
    // NOTE: Because this log level is aligned with the reporting log level, the same restrictions 
    //       apply with respect to the supported levels.
    flushLogStackLevel = rflib_LogLevel.INFO.encompasses(newLevel) || rflib_LogLevel.NONE == newLevel ? 
      newLevel : 
      rflib_LogLevel.INFO;
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

  public void setPlatformInfo(String platformInfo) {
    PLATFORM_INFO = platformInfo;
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

  public void info(String message){
    info(message, null);
  }

  public void info(String message, Object[] args) {
    logMessage(rflib_LogLevel.INFO, message, args, null);
  }

  public void warn(String message){
    warn(message, null);
  }

  public void warn(String message, Object[] args) {
    logMessage(rflib_LogLevel.WARN, message, args, null);
  }

  public void error(String message){
    error(message, null, null);
  }

  public void error(String message, Exception ex){
    error(message, null, ex);
  }

  public void error(String message, Object[] args) {
    error(message, args, null);
  }

  public void error(String message, Object[] args, Exception ex) {
    logMessage(rflib_LogLevel.ERROR, message, args, ex);
  }

  public void fatal(String message){
    fatal(message, null, null);
  }

  public void fatal(String message, Exception ex){
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
    String maskedLogMessagesIfApplicable = isLogMaskingEnabled ? 
      rflib_StringUtil.replaceWithAllMaskingRules(messagesAsStr) :
      messagesAsStr;
    
    Integer messageSize = maskedLogMessagesIfApplicable.length();
    
    // see https://github.com/j-fischer/rflib/issues/67
    String requestId = Request.getCurrent().getRequestId();
    if (requestId == null) {
      requestId = 'NULL';
    }

    rflib_Log_Event__e eventToLog = new rflib_Log_Event__e(
      Request_ID__c = requestId.substring(0, Math.min(requestId.length(), 40)),
      Log_Level__c = logLevel.toString(),
      Context__c = context.substring(0, Math.min(context.length(), 40)),
      Platform_Info__c = getPlatformInformation(),
      Log_Messages__c = messageSize < MAX_MESSAGE_SIZE
        ? maskedLogMessagesIfApplicable 
        : maskedLogMessagesIfApplicable.substring(messageSize - MAX_MESSAGE_SIZE)
    );

    if (batchReportingLogLevel.encompasses(logLevel)) {
      BATCH_EXECUTOR.addEvent(eventToLog);
    } else {
      eventPublisher.publish(eventToLog);
      
      if (flushLogStackLevel.encompasses(logLevel)) {
        LOG_STATEMENTS.clear();
      }
    }
  }

  private void logMessage(rflib_LogLevel logLevel, String message, Object[] args, Exception ex) {
    
    String messageToLog = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss') + '|' + logLevel + '|' + rflib_TraceId.value + '|' + context;
    
    messageToLog = args == null 
      ? messageToLog + '|' + message
      : messageToLog + '|' + String.format(message, args);

    if (ex != null) {
      messageToLog = messageToLog + '\nMessage: ' + ex.getMessage() + '\nStracktrace: ' + ex.getStackTraceString();
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
    
    if (reportingLogLevel.encompasses(logLevel)) {
      reportLogs(logLevel);
    }
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
      rflib_Log_Event__e event = (rflib_Log_Event__e) evt;
      Integer publishingLimit = rflib_GlobalSettings.publishingLimit != null 
        ? rflib_GlobalSettings.publishingLimit
        : Limits.getLimitPublishImmediateDML();
        
      if (Limits.getPublishImmediateDML() == Limits.getLimitPublishImmediateDML()) {
        System.debug(LoggingLevel.ERROR, 'RFLIB: PublishImmediateDML Governor Limit reached; failed to publish ' + JSON.serialize(event));
        return null;
      }

      if (eventBusPublisher.getPublishingCounter() == publishingLimit) {
        System.debug(LoggingLevel.ERROR, 'RFLIB: Publish Immediate DML limit (' + publishingLimit +') reached; failed to publish ' + JSON.serialize(event));
        return null;
      }
      
      Database.SaveResult result = eventBusPublisher.publish(getUpdatedLogEventIfLimitIsReached(event, publishingLimit));
      
      if(!result.isSuccess()) {
        System.debug(LoggingLevel.ERROR, JSON.serialize(result.getErrors()));
      }

      return result;
    }

    private rflib_Log_Event__e getUpdatedLogEventIfLimitIsReached(rflib_Log_Event__e logEvent, Integer publishingLimit) {
      if (eventBusPublisher.getPublishingCounter() < (publishingLimit - 1)) {
        return logEvent;
      }

      String rflibInfoMessage = '>>>>> RFLIB: Publish Immediate DML limit (' + publishingLimit +') reached; THIS IS THE LAST EVENT FOR THIS TRANSACTION  <<<<<\n\n';
      Integer rflibInfoMessageSize = rflibInfoMessage.length();

      Integer expectedMessageSize = logEvent.Log_Messages__c.length() + rflibInfoMessageSize;

      String logMessage = expectedMessageSize < MAX_MESSAGE_SIZE
        ? rflibInfoMessage + logEvent.Log_Messages__c 
        : rflibInfoMessage + logEvent.Log_Messages__c.substring(expectedMessageSize - MAX_MESSAGE_SIZE);

      logEvent.Log_Messages__c = logMessage;

      return logEvent;
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
  }

  private class BatchLogEventExecutor implements Queueable {

    private final rflib_EventPublisher eventBusPublisher = new rflib_EventBusPublisher(); 
    
    private rflib_Log_Event__e lastEventToBePublished;

    public void addEvent(rflib_Log_Event__e event) {
      lastEventToBePublished = event;
    }

    public void execute(QueueableContext ctx) {
      if (lastEventToBePublished == null) {
        System.debug(LoggingLevel.INFO, 'There is no log event to be published; exiting.');
        return;
      }
      Database.SaveResult result = eventBusPublisher.publish(lastEventToBePublished);
      
      if(!result.isSuccess()) {
        System.debug(LoggingLevel.ERROR, JSON.serialize(result.getErrors()));
      }
    }
  }
}
