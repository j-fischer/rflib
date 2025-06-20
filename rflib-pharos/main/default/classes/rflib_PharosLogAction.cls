/*
 * Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
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
public class rflib_PharosLogAction {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_PharosLogAction');
    
    private static final String PHAROS_LOG_EVENT_OBJECT = 'pharos__Log_Event__e';
    private static final String PHAROS_LOG_EVENT_OBJECT_BODY = 'pharos__Body__c';
    private static final String PHAROS_POST_PROCESSING_SETTINGS_FIELD = 'pharos__Post_Processing_Settings__c';
    
    @TestVisible
    private static String PHAROS_LOG_OBJECT = 'pharos__Log__c';

    @TestVisible
    private static rflib_EventPublisher EVENT_PUBLISHER = new rflib_EventBusPublisher();
    
    static {
        // NOTE: It is critical to turn reporting off so that a log configuration reporting INFO statements
        //       does not create an infinite loop of log events. 
        LOGGER.setReportingLogLevel(rflib_LogLevel.NONE);
        LOGGER.setSystemDebugLevel(rflib_LogLevel.DEBUG);
    }
    
    @InvocableMethod(
        label = 'Create Pharos Log Records' 
        description = 'Creates Pharos Log records based on the given Log Events.'
    )
    public static void createPharosLogRecords(List<rflib_Log_Event__e> logEvents) {
        try {
            LOGGER.debug('createPharosLogRecords started for {0} event(s)', new Object[] { logEvents.size() });
            
            rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getInstance();
            rflib_LogLevel pharosLogLevel = rflib_LogLevel.fromString(settings.Pharos_Log_Level__c);
            
            if (pharosLogLevel == rflib_LogLevel.NONE) {
                LOGGER.info('Pharos logging is disabled');
                return;
            }
            
            List<SObject> pharosLogs = new List<SObject>();
            SObjectType pharosLogType = Schema.getGlobalDescribe().get(PHAROS_LOG_OBJECT);

            if (pharosLogType == null) {
                LOGGER.info('Pharos Log object not found in schema. Ensure the Pharos package is installed.');
                return;
            }
            
            for (rflib_Log_Event__e event : logEvents) {
                if (matchesConfiguredLogLevel(pharosLogLevel, event)) {
                    SObject pharosLog = pharosLogType.newSObject();
                    
                    // Use rflib_FieldMapper to map fields from Log Event to Pharos Log
                    pharosLog = rflib_FieldMapper.mapFields(event, PHAROS_LOG_OBJECT);
                    
                    // Set post-processing settings
                    Map<String, Boolean> postProcessingSettings = rflib_PharosPostProcessingBuilder.getPostProcessingSettings();
                    if (!postProcessingSettings.isEmpty()) {
                        pharosLog.put(PHAROS_POST_PROCESSING_SETTINGS_FIELD, JSON.serialize(postProcessingSettings));
                    }
                    
                    pharosLogs.add(pharosLog);
                }
            }
            
            if (!pharosLogs.isEmpty()) {
                LOGGER.info('Created {0} Pharos Log records', new Object[] { pharosLogs.size() });
                
                SObjectType pharosLogEventType = Schema.getGlobalDescribe().get(PHAROS_LOG_EVENT_OBJECT);
                if (pharosLogEventType == null) {
                    LOGGER.error('Pharos Log Event object not found in schema. Ensure the Pharos package is installed.');
                    return;
                }

                SObject pharosLogEvent = pharosLogEventType.newSObject();
                pharosLogEvent.put(PHAROS_LOG_EVENT_OBJECT_BODY, JSON.serialize(pharosLogs));
                
                EVENT_PUBLISHER.publish(pharosLogEvent);
            }         
        } catch (Exception ex) {
            LOGGER.error('Failed to create Pharos Log records', ex);
        }
    }

    private static Boolean matchesConfiguredLogLevel(rflib_LogLevel pharosLogLevel, rflib_Log_Event__e evt) {
        if (pharosLogLevel != rflib_LogLevel.NONE && rflib_LogLevel.WARN.encompasses(pharosLogLevel) == false) {
            LOGGER.warn('Pharos log level {0} is not supported. Defaulting to WARN.', new Object[] { pharosLogLevel });
            pharosLogLevel = rflib_LogLevel.WARN;
        }

        return pharosLogLevel.encompasses(rflib_LogLevel.fromString(evt.Log_Level__c));
    }
    
    public class rflib_PharosLogActionException extends Exception { }
} 