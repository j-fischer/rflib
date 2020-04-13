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
 * @group Trigger
 * @description This is the core class to manage the invocation of tflib_ITriggerHandler implementations
 *              based on the configuration in the Custom Metadata. 
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public inherited sharing class rflib_TriggerManager {
    
    private static final rflib_Logger LOGGER = rflib_DefaultLogger.createBatchedLoggerFromCustomSettings('rflib_TriggerManager');

    private static rflib_ITriggerHandler ACTIVE_HANDLER;

    private static Map<rflib_TriggerManager.Args, Integer> ON_CONSECUTIVE_RUN_COUNTERS = new Map<rflib_TriggerManager.Args,Integer>();

    @TestVisible
    private static ITriggerConfigurationQueryLocator QUERY_LOCATOR = new DefaultTriggerConfigurationQueryLocator();

    /**
     * Call this method from any trigger with the respective object type. The framwork will handle the rest. 
     * @param  objectType SObjectType for the trigger that invokes the Manager.
     */
    public static void dispatch(Schema.SObjectType objectType) {
        dispatch(new rflib_TriggerManager.Args(
            objectType,
            Trigger.operationType,
            Trigger.old == null ? new List<SObject>() : Trigger.old,
            Trigger.oldMap == null ? new Map<Id, SObject>() : Trigger.oldMap,
            Trigger.new == null ? new List<SObject>() : Trigger.new,
            Trigger.newMap == null ? new Map<Id, SObject>() : Trigger.newMap,
            Trigger.size
        ));
    }

    @TestVisible
    private static void dispatch(rflib_TriggerManager.Args args) {
        List<TriggerHandlerInfo> handlers = getHandlers(args);

        if (rflib_FeatureSwitch.isTurnedOff('All_Triggers')) {
            LOGGER.warn('All Trigger Feature switch turned off, exiting trigger execution.');
            return;
        }

        try {
            runHandlers(args, handlers);
        } finally {
            // If active handler is not NULL, we are in a recursive loop and need to wait for the root transaction to complete.
            if (ACTIVE_HANDLER == null) {
                LOGGER.publishBatchedLogEvents();
            }
        }
    }

    private static void runHandlers(rflib_TriggerManager.Args args, List<TriggerHandlerInfo> handlers) {
        for (TriggerHandlerInfo handlerInfo : handlers) {
            rflib_ITriggerHandler handler = handlerInfo.handler;

            LOGGER.debug('Is consecutive run? ' + (ACTIVE_HANDLER != null));

            if (ACTIVE_HANDLER == null) {
                try {
                    ACTIVE_HANDLER = handler;
                    handler.run(args);
                } catch (Exception ex) {
                    if (handlerInfo.catchException) {
                        LOGGER.warn('run: Handler "{0}" threw an exception with message "{1}". Stacktrace:\n{2}', new object[] { handlerInfo.handlerType, ex.getMessage(), ex.getStackTraceString() });
                        args.addException(ex, handlerInfo.handlerType);
                    } else {
                        LOGGER.error('run: Handler "{0}" threw an exception with message "{1}". Stacktrace:\n{2}', new object[] { handlerInfo.handlerType, ex.getMessage(), ex.getStackTraceString() });
                        throw ex;
                    }
                } finally {
                    ACTIVE_HANDLER = null;
                }
            }

            if (ACTIVE_HANDLER != null) {
                try {
                    handler.onConsecutiveRun(args, incrementAndGetCounter(args));
                } catch (Exception ex) {
                    if (handlerInfo.catchException) {
                        LOGGER.warn('onConsecutiveRun: Handler "{0}" threw an exception with message "{1}". Stacktrace:\n{2}', new object[] { handlerInfo.handlerType, ex.getMessage(), ex.getStackTraceString() });
                        args.addException(ex, handlerInfo.handlerType);
                    } else {
                        LOGGER.error('onConsecutiveRun: Handler "{0}" threw an exception with message "{1}". Stacktrace:\n{2}', new object[] { handlerInfo.handlerType, ex.getMessage(), ex.getStackTraceString() });
                        throw ex;
                    }
                }
            }
        }
    }

    private static Integer incrementAndGetCounter(rflib_TriggerManager.Args args) {
        Integer count = ON_CONSECUTIVE_RUN_COUNTERS.get(args); 
        if (count == null) {
            count = 1;
        } else {
            count++;
        }

        ON_CONSECUTIVE_RUN_COUNTERS.put(args, count);
        return count;
    }

    private static List<TriggerHandlerInfo> getHandlers(rflib_TriggerManager.Args args) {
        List<TriggerHandlerInfo> result = new List<TriggerHandlerInfo>();

        String sObjectName = args.objectType.getDescribe().getName();
        List<rflib_Trigger_Configuration__mdt> triggerHandlers = QUERY_LOCATOR.getRecords(sObjectName, args.operation.name());

        List<String> activeTriggers = new List<String>();
        for (rflib_Trigger_Configuration__mdt handlerInfo : triggerHandlers) {
            activeTriggers.add(handlerInfo.Class_Name__c);
            Type handlerType = Type.forName(handlerInfo.Class_Name__c);
            rflib_ITriggerHandler handler = (rflib_ITriggerHandler) handlerType.newInstance();

            Boolean catchException = handlerInfo.Exception_Behavior__c == 'Catch Exception';
            result.add(new TriggerHandlerInfo(handler, handlerType, catchException));
        }

        LOGGER.debug('{0} active trigger(s) found for operation {1} on object type {2}: {3}', new List<Object> { activeTriggers.size(), args.operation, sObjectName, String.join(activeTriggers, ',') });

        return result;
    }

    public class TriggerHandlerInfo {
        public final rflib_ITriggerHandler handler;
        public final Type handlerType;
        public final Boolean catchException;

        public TriggerHandlerInfo(rflib_ITriggerHandler handler, Type handlerType, Boolean catchException) {
            this.handler = handler;
            this.handlerType = handlerType;
            this.catchException = catchException;
        }
    }    

    /**
    * @group Trigger
    * @description Arguments for the trigger creation.
    */
    public class Args {

        public final Schema.SObjectType objectType;
        public final System.TriggerOperation operation;
        public final List<SObject> oldRecords;
        public final Map<Id, SObject> oldRecordsMap;
        public final List<SObject> newRecords;
        public final Map<Id, SObject> newRecordsMap; 
        public final Integer size;

        private final Map<String, List<Exception>> caughtExceptions = new Map<String, List<Exception>>();

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Args(
            Schema.SObjectType objectType,
            System.TriggerOperation operation,
            List<SObject> oldRecords,
            Map<Id, SObject> oldRecordsMap,
            List<SObject> newRecords,
            Map<Id, SObject> newRecordsMap, 
            Integer size
        ) {
            this.objectType = objectType;
            this.operation = operation;
            this.oldRecords = new List<SObject>(oldRecords);
            this.oldRecordsMap = new Map<Id, SObject>(oldRecordsMap);
            this.newRecords = new List<SObject>(newRecords);
            this.newRecordsMap = new Map<Id, SObject>(newRecordsMap);
            this.size = size;
        }

        public Boolean hasExceptions() {
            return caughtExceptions.size() > 0;
        }

        public Boolean hasNoExceptions() {
            return caughtExceptions.size() == 0;
        }

        public Map<String, List<Exception>> getCaughtExceptions() {
            return new Map<String, List<Exception>>(caughtExceptions);
        }

        public List<Exception> getCaughtExceptionsByType(Type targetType) {
            return new List<Exception>(caughtExceptions.get(targetType.getName()));
        }

        public Boolean equals(Object o) {
            if ( !(o instanceof Args) ) {
                return false;
            }

            rflib_TriggerManager.Args other = (rflib_TriggerManager.Args) o;

            return objectType == other.objectType
                && operation == other.operation;
        }

        public Integer hashCode() {
            Integer prime = 37;
            Integer result = 1;
            result = prime * result + ((objectType == null) ? 0 : System.hashCode(objectType));
            result = prime * result + ((operation == null) ? 0 : System.hashCode(operation));
            return result;
        }

        private void addException(Exception ex, Type t) {
            String typeName = t.getName();
            if (!caughtExceptions.containsKey(typeName)) {
                caughtExceptions.put(typeName, new List<Exception>());
            }

            caughtExceptions.get(typeName).add(ex);
        }
    }

    public interface ITriggerConfigurationQueryLocator {
        List<rflib_Trigger_Configuration__mdt> getRecords(String objectType, String triggerEvent);
    }

    public class DefaultTriggerConfigurationQueryLocator implements ITriggerConfigurationQueryLocator {
        public List<rflib_Trigger_Configuration__mdt> getRecords(String objectTypeName, String triggerEvent) {
            return [SELECT Class_Name__c, Order__c, Exception_Behavior__c
             FROM rflib_Trigger_Configuration__mdt
             WHERE Active__c = true
             AND Object_Name__c = :objectTypeName 
             AND Event__c = :triggerEvent
             ORDER BY Order__c, Class_Name__c ASC
            ];
        }
    }
}
