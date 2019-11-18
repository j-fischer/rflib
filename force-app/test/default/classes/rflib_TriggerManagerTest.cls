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
 @IsTest
 @SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_TriggerManagerTest {

    private static final String ABORT_TRANSACTION = 'Abort Transaction';
    private static final String CATCH_EXCEPTION = 'Catch Exception';

    private static final String AFTER_INSERT = TriggerOperation.AFTER_INSERT.name();
    private static final String OBJECT_TYPE_NAME = rflib_Log_Event__e.SObjectType.getDescribe().getName();

    private static final Exception EX = new MockTriggerHandlerException('This is a MockTriggerHandlerException');

    private static void setup(String exceptionBehaviour) {
        rflib_TriggerManager.QUERY_LOCATOR = new rflib_MockTriggerConfigQueryLocator(
            createConfiguration(exceptionBehaviour), 
            OBJECT_TYPE_NAME, 
            AFTER_INSERT
        );
    }

    @IsTest
    public static void testRun_Success() {
        setup(ABORT_TRANSACTION);

        rflib_Log_Event__e ev = createEvent();

        rflib_TriggerManager.dispatch(createArgs(ev));

        assertRunTriggerArgs(ev);
    }

    @IsTest
    public static void testRun_ExceptionCaught() {
        setup(CATCH_EXCEPTION);

        rflib_MockTriggerHandler.EXCEPTION_ON_RUN = EX;

        rflib_Log_Event__e ev = createEvent();

        rflib_TriggerManager.dispatch(createArgs(ev));

        rflib_TriggerManager.Args args = assertRunTriggerArgs(ev);

        System.assertEquals(true, args.hasExceptions());
        System.assertEquals(ex.getMessage(), args.getCaughtExceptionsByType(rflib_MockTriggerHandler.class).get(0).getMessage());
    }

    @IsTest
    public static void testRun_ExceptionThrown() {
        setup(ABORT_TRANSACTION);

        rflib_MockTriggerHandler.EXCEPTION_ON_RUN = EX;

        rflib_Log_Event__e ev = createEvent();

        try {
            rflib_TriggerManager.dispatch(createArgs(ev));
            System.assert(false, 'Expected exception has not been thrown');
        } catch (Exception actualException) {
            System.assertEquals(EX.getMessage(), actualException.getMessage());
        }

        assertRunTriggerArgs(ev);
    }

    @IsTest
    public static void testOnConsecutiveRun_Sucess() {
        setup(ABORT_TRANSACTION);

        rflib_Log_Event__e ev = createEvent();

        rflib_MockTriggerHandler.ACTION_WHEN_CALLED = new TriggerRecursiveRun(new Set<String> { 'run' });

        rflib_TriggerManager.dispatch(createArgs(ev));

        assertRunTriggerArgs(ev);

        assertConsecutiveRunTriggerArgs(ev);
    }

    @IsTest
    public static void testOnConsecutiveRun_ExceptionCaught() {
        setup(CATCH_EXCEPTION);

        rflib_Log_Event__e ev = createEvent();

        rflib_MockTriggerHandler.ACTION_WHEN_CALLED = new TriggerRecursiveRun(new Set<String> { 'run' });
        rflib_MockTriggerHandler.EXCEPTION_ON_CONSECUTIVE_RUN = EX;

        rflib_TriggerManager.dispatch(createArgs(ev));

        assertRunTriggerArgs(ev);

        rflib_TriggerManager.Args args = assertConsecutiveRunTriggerArgs(ev);

        System.assertEquals(true, args.hasExceptions());
        System.assertEquals(ex.getMessage(), args.getCaughtExceptionsByType(rflib_MockTriggerHandler.class).get(0).getMessage());
    }

    @IsTest
    public static void testOnConsecutiveRun_ExceptionThrown() {
        setup(ABORT_TRANSACTION);

        rflib_MockTriggerHandler.ACTION_WHEN_CALLED = new TriggerRecursiveRun(new Set<String> { 'run' });
        rflib_MockTriggerHandler.EXCEPTION_ON_CONSECUTIVE_RUN = EX;

        rflib_Log_Event__e ev = createEvent();

        try {
            rflib_TriggerManager.dispatch(createArgs(ev));
            System.assert(false, 'Expected exception has not been thrown');
        } catch (Exception actualException) {
            System.assertEquals(EX.getMessage(), actualException.getMessage());
        }

        assertRunTriggerArgs(ev);
        assertConsecutiveRunTriggerArgs(ev);
    }

    @IsTest
    public static void testDefaultTriggerConfigurationQueryLocator() {
        List<rflib_Trigger_Configuration__mdt> expectedResult = [
            SELECT Class_Name__c, Order__c, Exception_Behavior__c
            FROM rflib_Trigger_Configuration__mdt
            WHERE Active__c = true
            AND Object_Name__c = :OBJECT_TYPE_NAME
            AND Event__c = :AFTER_INSERT
            ORDER BY Order__c, Class_Name__c ASC
        ];

        List<rflib_Trigger_Configuration__mdt> actualResult = new rflib_TriggerManager.DefaultTriggerConfigurationQueryLocator().getRecords(OBJECT_TYPE_NAME, AFTER_INSERT);

        System.assertEquals(expectedResult.size(), actualResult.size());
    }

    private static rflib_TriggerManager.Args assertRunTriggerArgs(rflib_Log_Event__e ev) {
        System.assertEquals(1, rflib_MockTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.size());

        rflib_TriggerManager.Args args = rflib_MockTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.get(0);

        rflib_Log_Event__e capturedEvent = (rflib_Log_Event__e) args.newRecords.get(0); 
        System.assertEquals(ev.Context__c, capturedEvent.Context__c);

        return args;
    }

    private static rflib_TriggerManager.Args assertConsecutiveRunTriggerArgs(rflib_Log_Event__e ev) {
        System.assertEquals(1, rflib_MockTriggerHandler.CAPTURED_CONSECUTIVE_RUN_TRIGGER_ARGS.size());

        rflib_TriggerManager.Args args = rflib_MockTriggerHandler.CAPTURED_CONSECUTIVE_RUN_TRIGGER_ARGS.get(0);

        rflib_Log_Event__e capturedEvent = (rflib_Log_Event__e) args.newRecords.get(0); 
        System.assertEquals(ev.Context__c, capturedEvent.Context__c);

        return args;
    }

    private static rflib_TriggerManager.Args createArgs(rflib_Log_Event__e record) {
        return new rflib_TriggerManager.Args(
            rflib_Log_Event__e.SObjectType,
            TriggerOperation.AFTER_INSERT,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject> { record },
            new Map<Id, SObject>(),
            1
        );
    }

    private static rflib_Log_Event__e createEvent() {
        return new rflib_Log_Event__e(
            Context__c = 'rflib_TriggerManagerTest',
            Log_Messages__c = 'Some log messages'
        );
    }

    private static rflib_Trigger_Configuration__mdt createConfiguration(String exceptionBehaviour) {
        return new rflib_Trigger_Configuration__mdt(
            Active__c = true,
            Class_Name__c = 'rflib_MockTriggerHandler',
            Object_Name__c = 'rflib_Log_Event__e',
            Event__c = 'AFTER_INSERT',
            Order__c = 1,
            Exception_Behavior__c = exceptionBehaviour
        );
    }

    public class TriggerRecursiveRun implements Callable {
        
        private Set<String> actions;

        public TriggerRecursiveRun(Set<String> actions) {
            this.actions = actions;
        }
        
        public Object call(String action, Map<String, Object> args) {
            rflib_TriggerManager.Args triggerArgs = (rflib_TriggerManager.Args) args.get('triggerArgs');

            if (actions.contains(action)) {
                rflib_TriggerManager.dispatch(triggerArgs);
            }

            return null;
        }
    }

    public class MockTriggerHandlerException extends Exception { }
}
