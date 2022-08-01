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
 * @group RetryableAction
 * @description This is the core class to manage the invocation of rflib_RetryableAction implementations
 *              based on the configuration in the Custom Metadata. 
 */ 
public inherited sharing class rflib_RetryableActionManager {
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('rflib_RetryableActionManager');

    private static Map<String, rflib_RetryableActionHandler> ACTIVE_HANDLERS = new Map<String, rflib_RetryableActionHandler>();

    @TestVisible
    private static RetryableActionConfigurationQueryLocator QUERY_LOCATOR = new DefaultRetryableActionConfigurationQueryLocator();

    /**
     * This is the handler that is invoked from the Retryable Action trigger.
     * @param  List<rflib_Retryable_Action__e> List of events to be processed.
     */
    public static void dispatch(List<rflib_Retryable_Action__e> events) {
        Map<String, List<rflib_Retryable_Action__e>> actionsByName = new Map<String, List<rflib_Retryable_Action__e>> (); 
        for (rflib_Retryable_Action__e evt : events) {
            if (!actionsByName.containsKey(evt.Action__c)) {
                actionsByName.put(evt.Action__c, new List<rflib_Retryable_Action__e>());
            }

            actionsByName.get(evt.Action__c).add(evt);
        }
    }
    
    public static void dispatch(Map<String, List<rflib_Retryable_Action__e>> actionsByName) {
        if (FeatureManagement.checkPermission('rflib_Bypass_All_Actions')) {
            LOGGER.warn('"Bypass All Actions" permission detected, exiting trigger execution.');
            return;
        }

        Map<String, List<rflib_RetryableActionHandler>> handlersByName = getHandlers(actionsByName.keySet());

        runHandlers(actionsByName, handlersByName);
    }

    private static void runHandlers(Map<String, List<rflib_Retryable_Action__e>> actionsByName, Map<String, List<rflib_RetryableActionHandler>> handlersByName) {
        for (String actionName : handlersByName.keySet()) {

            for (rflib_RetryableActionHandler handler : handlersByName.get(actionName)) {
                try {
                    handler.execute(actionsByName.get(actionName));
                } catch (Exception ex) {
                    if (EventBus.TriggerContext.currentContext().retries < 8) {
                        throw new EventBus.RetryableException('Condition is not met, so retrying the trigger again.');
                    } else {
    
                    }
                } 
            }
        }
    }

    private static Map<String, List<rflib_RetryableActionHandler>> getHandlers(Set<String> eventNames) {
        Map<String, List<rflib_RetryableActionHandler>> result = new Map<String, List<rflib_RetryableActionHandler>>();

        List<rflib_Retryable_Action_Config__mdt> actionHandlers = QUERY_LOCATOR.getRecords(eventNames);

        List<String> activeTriggers = new List<String>();
        for (rflib_Retryable_Action_Config__mdt handlerInfo : actionHandlers) {
            // activeTriggers.add(handlerInfo.Class_Name__c);
            // Type handlerType = Type.forName(handlerInfo.Class_Name__c);
            // if (handlerType == null) {
            //     LOGGER.error('Could not find Class with name {0} for Object {1} and operation {2}, please review your configuration.', new Object[] { handlerInfo.Class_Name__c, sObjectName, args.operation.name() });
            //     continue;
            // }
            // rflib_TriggerHandler handler = (rflib_TriggerHandler) handlerType.newInstance();

            // Boolean catchException = handlerInfo.Exception_Behavior__c == 'Catch Exception';
            // result.add(new TriggerHandlerInfo(handler, handlerType, catchException));
        }

        LOGGER.debug('{0} active trigger(s) found for operation {1} on object type {2}: {3}', new List<Object> { activeTriggers.size(), String.join(activeTriggers, ',') });

        return result;
    }

    public class TriggerHandlerInfo {
        public final rflib_TriggerHandler handler;
        public final Type handlerType;
        public final Boolean catchException;

        public TriggerHandlerInfo(rflib_TriggerHandler handler, Type handlerType, Boolean catchException) {
            this.handler = handler;
            this.handlerType = handlerType;
            this.catchException = catchException;
        }
    }    


    public interface RetryableActionConfigurationQueryLocator {
        List<rflib_Retryable_Action_Config__mdt> getRecords(String actionName);
    }

    public class DefaultRetryableActionConfigurationQueryLocator implements RetryableActionConfigurationQueryLocator {

        @TestVisible
        private List<rflib_Retryable_Action_Config__mdt> allConfigValues = rflib_Retryable_Action_Config__mdt.getAll().values();

        public List<rflib_Retryable_Action_Config__mdt> getRecords(String actionName) {
            List<TriggerConfigurationWrapper> sortable = new List<TriggerConfigurationWrapper>();
            for (rflib_Retryable_Action_Config__mdt config : allConfigValues) {
                if (config.Active__c && config.Action_Name__c == actionName) {
                    sortable.add(new TriggerConfigurationWrapper(config));
                }
            }

            sortable.sort();

            List<rflib_Trigger_Configuration__mdt> result = new List<rflib_Trigger_Configuration__mdt>();
            for (TriggerConfigurationWrapper configWrapper : sortable) {
                result.add(configWrapper.triggerConfig);
            }
            return result;
        }
    }

    public class TriggerConfigurationWrapper implements Comparable {
 
        public rflib_Trigger_Configuration__mdt triggerConfig;
        
        public TriggerConfigurationWrapper(rflib_Trigger_Configuration__mdt triggerConfig) {
           this.triggerConfig = triggerConfig;
        }
        
        public Integer compareTo(Object compareTo) {
            TriggerConfigurationWrapper compareToConfig = (TriggerConfigurationWrapper) compareTo;

            if (compareToConfig == null) {
                return 1;
            } else if (triggerConfig == null && compareToConfig.triggerConfig == null) {
                return 0;
            } else if (triggerConfig == null && compareToConfig.triggerConfig != null) {
                return -1;
            } else if (triggerConfig != null && compareToConfig.triggerConfig == null) {
                return 1;
            }

            Integer returnValue = compareFieldValue(compareToConfig, 'Order__c');
            
            return returnValue != 0
                ? returnValue
                : compareFieldValue(compareToConfig, 'Class_Name__c');
        }

        private Integer compareFieldValue(TriggerConfigurationWrapper compareTo, String fieldName) {
            Integer returnValue = 0;
            if ((triggerConfig.get(fieldName) == null) && (compareTo.triggerConfig.get(fieldName) != null)){
                returnValue = -1;
            } else if ((triggerConfig.get(fieldName) != null) && (compareTo.triggerConfig.get(fieldName) == null)){
                returnValue = 1;
            } else if (String.valueOf(triggerConfig.get(fieldName)) > String.valueOf(compareTo.triggerConfig.get(fieldName))) {
                returnValue = 1;
            } else if (String.valueOf(triggerConfig.get(fieldName)) < String.valueOf(compareTo.triggerConfig.get(fieldName))) {
                returnValue = -1;
            }        
            return returnValue;                  
        }
    }
}
