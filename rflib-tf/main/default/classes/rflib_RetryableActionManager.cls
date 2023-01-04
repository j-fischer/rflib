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
 * @description This is the core class to manage the invocation of rflib_RetryableActionHandler implementations
 *              based on the configuration in the Custom Metadata. 
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public inherited sharing class rflib_RetryableActionManager {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_RetryableActionManager');

    @TestVisible
    private static List<rflib_Retryable_Action_Config__mdt> ALL_CONFIG_VALUES = rflib_Retryable_Action_Config__mdt.getAll().values();

    /**
     * This is the dispatch function that is invoked from the Retryable Action trigger.
     * @param  List<rflib_Retryable_Action__e> List of events to be processed.
     */
    public static void dispatch(List<rflib_Retryable_Action__e> events) {
        LOGGER.info('Dispatching actions: ' + events);

        if (rflib_FeatureSwitch.isTurnedOff('All_Retryable_Actions')) {
            LOGGER.warn('The All Retryable Actions Feature switch is turned off, exiting execution.');
            return;
        }

        Map<String, List<rflib_Retryable_Action__e>> actionsByName = new Map<String, List<rflib_Retryable_Action__e>> (); 
        for (rflib_Retryable_Action__e evt : events) {
            if (!actionsByName.containsKey(evt.Action__c)) {
                actionsByName.put(evt.Action__c, new List<rflib_Retryable_Action__e>());
            }

            actionsByName.get(evt.Action__c).add(evt);
        }

        dispatch(actionsByName);
    }
    
    public static void dispatch(Map<String, List<rflib_Retryable_Action__e>> actionsByName) {
        LOGGER.info('Dispatching actions by name: ' + actionsByName);

        Map<String, List<RetryableActionHandlerInfo>> handlersByName = getHandlers(actionsByName.keySet());

        runHandlers(actionsByName, handlersByName);
    }

    private static void runHandlers(Map<String, List<rflib_Retryable_Action__e>> actionsByName, Map<String, List<RetryableActionHandlerInfo>> handlersByName) {
        for (String actionName : handlersByName.keySet()) {

            for (RetryableActionHandlerInfo handlerInfo : handlersByName.get(actionName)) {
                rflib_RetryableActionHandler handler = handlerInfo.handler;
                List<rflib_Retryable_Action__e> actions = actionsByName.get(actionName);

                try {
                    LOGGER.debug('Executing handler {0} with events: {1}', new Object[] { handlerInfo.handlerType.getName(), actions } );
                    handler.execute(actions);
                } catch (Exception ex) {
                    Integer currentRetry = EventBus.TriggerContext.currentContext().retries;
                    if (currentRetry < 8) {
                        if (currentRetry < 6) {
                            LOGGER.info('Executing the actions caused an error, retrying; number of retries=' + currentRetry);
                        } else {
                            LOGGER.warn('Executing the actions caused an error, retrying; number of retries=' + currentRetry);
                        }
                        throw new EventBus.RetryableException('Failed to execute action, retrying action event batch.');
                    } else {
                        LOGGER.fatal('Failed to execute Action Event Batch, cancelling execution of following actions: ' + actionsByName);
                    }
                } 
            }
        }
    }

    private static Map<String, List<RetryableActionHandlerInfo>> getHandlers(Set<String> eventNames) {
        Map<String, List<RetryableActionHandlerInfo>> result = new Map<String, List<RetryableActionHandlerInfo>>();

        Map<String, List<rflib_Retryable_Action_Config__mdt>> actionHandlers = getFilteredAndSortedConfigurationRecords(eventNames);

        List<String> activeHandlers = new List<String>();
        for (String actionName : actionHandlers.keySet()) {
            if (result.get(actionName) == null) {
                result.put(actionName, new List<RetryableActionHandlerInfo>());
            }

            for (rflib_Retryable_Action_Config__mdt handlerInfo : actionHandlers.get(actionName)) {

                activeHandlers.add(handlerInfo.Class_Name__c);
                Type handlerType = Type.forName(handlerInfo.Class_Name__c);
                if (handlerType == null) {
                    LOGGER.error('Could not find Class with name {0} for Action {1}, please review your configuration.', new Object[] { handlerInfo.Class_Name__c, actionName });
                    continue;
                }
                rflib_RetryableActionHandler handler = (rflib_RetryableActionHandler) handlerType.newInstance();

                result.get(actionName).add(new RetryableActionHandlerInfo(handler, handlerType));
            }
        }

        LOGGER.debug('{0} active handlers(s) found for action {1}: {2}', new List<Object> { activeHandlers.size(), String.join(activeHandlers, ',') });

        return result;
    }

    private static Map<String, List<rflib_Retryable_Action_Config__mdt>> getFilteredAndSortedConfigurationRecords(Set<String> actionNames) {
        Map<String, List<RetryableActionConfigurationWrapper>> mapOfSortableLists = new Map<String, List<RetryableActionConfigurationWrapper>>();
        for (rflib_Retryable_Action_Config__mdt config : ALL_CONFIG_VALUES) {
            if (mapOfSortableLists.get(config.Action_Name__c) == null) {
                mapOfSortableLists.put(config.Action_Name__c, new List<RetryableActionConfigurationWrapper>());
            }

            if (config.Active__c && actionNames.contains(config.Action_Name__c)) {
                List<RetryableActionConfigurationWrapper> sortable = mapOfSortableLists.get(config.Action_Name__c);
                sortable.add(new RetryableActionConfigurationWrapper(config));
            }
        }

        for (String actionName : mapOfSortableLists.keySet()) {
            mapOfSortableLists.get(actionName).sort();
        }

        Map<String, List<rflib_Retryable_Action_Config__mdt>> result = new Map<String, List<rflib_Retryable_Action_Config__mdt>>();
        for (String actionName : mapOfSortableLists.keySet()) {
            if (result.get(actionName) == null) {
                result.put(actionName, new List<rflib_Retryable_Action_Config__mdt>());
            }

            for (RetryableActionConfigurationWrapper configWrapper : mapOfSortableLists.get(actionName)) {
                result.get(actionName).add(configWrapper.actionConfig);
            }
        }
        return result;
    }

    public class RetryableActionHandlerInfo {
        public final rflib_RetryableActionHandler handler;
        public final Type handlerType;

        public RetryableActionHandlerInfo(rflib_RetryableActionHandler handler, Type handlerType) {
            this.handler = handler;
            this.handlerType = handlerType;
        }
    }    

    public interface RetryableActionConfigurationQueryLocator {
        Map<String, List<rflib_Retryable_Action_Config__mdt>> getRecords(Set<String> actionNames);
    }

    public class RetryableActionConfigurationWrapper implements Comparable {
 
        public rflib_Retryable_Action_Config__mdt actionConfig;
        
        public RetryableActionConfigurationWrapper(rflib_Retryable_Action_Config__mdt actionConfig) {
           this.actionConfig = actionConfig;
        }
        
        public Integer compareTo(Object compareTo) {
            RetryableActionConfigurationWrapper compareToConfig = (RetryableActionConfigurationWrapper) compareTo;

            if (compareToConfig == null) {
                return 1;
            } else if (actionConfig == null && compareToConfig.actionConfig == null) {
                return 0;
            } else if (actionConfig == null && compareToConfig.actionConfig != null) {
                return -1;
            } else if (actionConfig != null && compareToConfig.actionConfig == null) {
                return 1;
            }

            Integer returnValue = compareFieldValue(compareToConfig, 'Order__c');
            
            return returnValue != 0
                ? returnValue
                : compareFieldValue(compareToConfig, 'Class_Name__c');
        }

        private Integer compareFieldValue(RetryableActionConfigurationWrapper compareTo, String fieldName) {
            Integer returnValue = 0;
            if ((actionConfig.get(fieldName) == null) && (compareTo.actionConfig.get(fieldName) != null)){
                returnValue = -1;
            } else if ((actionConfig.get(fieldName) != null) && (compareTo.actionConfig.get(fieldName) == null)){
                returnValue = 1;
            } else if (String.valueOf(actionConfig.get(fieldName)) > String.valueOf(compareTo.actionConfig.get(fieldName))) {
                returnValue = 1;
            } else if (String.valueOf(actionConfig.get(fieldName)) < String.valueOf(compareTo.actionConfig.get(fieldName))) {
                returnValue = -1;
            }        
            return returnValue;                  
        }
    }
}
