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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_TriggerManagerTest {
    private static final String ABORT_TRANSACTION = 'Abort Transaction';
    private static final String CATCH_EXCEPTION = 'Catch Exception';

    private static final String MOCK_TRIGGER_HANDLER = 'rflib_MockTriggerHandler';
    private static final String MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER = 'rflib_MockSingleRunOnlyTriggerHandler';
    private static final String MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER_OVERRIDE = 'rflib_MockSROTriggerHandlerOverride';

    private static final String AFTER_INSERT = TriggerOperation.AFTER_INSERT.name();
    private static final String AFTER_UPDATE = TriggerOperation.AFTER_UPDATE.name();
    private static final String OBJECT_TYPE_NAME = rflib_Log_Event__e.SObjectType.getDescribe().getName();

    private static final Exception EX = new MockTriggerHandlerException('This is a MockTriggerHandlerException');

    private static final User STANDARD_USER = rflib_TestUserFactory.insertAndRetrieve('Jane', 'Smith', 'Standard User');
    private static final User BYPASS_TRIGGERS_USER = rflib_TestUserFactory.insertWithCustomPermissionAndRetrieve(
        'John',
        'Smith',
        'Standard User',
        'rflib_Bypass_All_Triggers'
    );

    private static Boolean SIMPLE_HANDLER_MOCK_RUN_INVOKED = false;
    private static Boolean SIMPLE_HANDLER_MOCK_CONSECUTIVERUN_INVOKED = false;

    static {
        rflib_FeatureSwitch.DEFAULT_VALUE = false; // Needs to be set for backwards version compatibility
    }

    private static void setup(String exceptionBehaviour) {
        rflib_TriggerManager.QUERY_LOCATOR = new rflib_MockTriggerConfigQueryLocator(
            createConfiguration(exceptionBehaviour),
            OBJECT_TYPE_NAME,
            AFTER_INSERT
        );
    }

    private static void setup(String className, String exceptionBehaviour) {
        rflib_TriggerManager.QUERY_LOCATOR = new rflib_MockTriggerConfigQueryLocator(
            createConfiguration(className, exceptionBehaviour),
            OBJECT_TYPE_NAME,
            AFTER_INSERT
        );
    }

    @IsTest
    public static void testRun_DisableAllTriggersFeatureSwitchOn() {
        setup(ABORT_TRANSACTION);

        rflib_FeatureSwitch.featureSwitches = new Map<String, Map<String, Boolean>>{
            'rflib_Disable_All_Triggers' => new Map<String, Boolean>{ rflib_FeatureSwitch.GLOBAL_SCOPE => true }
        };

        rflib_TriggerManager.dispatch(createArgs(createEvent()));

        Assert.areEqual(0, rflib_MockTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.size());
    }

    @IsTest
    public static void testRun_DisableAllTriggersFeatureSwitchOnSingleRunOnly() {
        setup(MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER, ABORT_TRANSACTION);

        rflib_FeatureSwitch.featureSwitches = new Map<String, Map<String, Boolean>>{
            'rflib_Disable_All_Triggers' => new Map<String, Boolean>{ rflib_FeatureSwitch.GLOBAL_SCOPE => true }
        };

        rflib_TriggerManager.dispatch(createArgs(createEvent()));

        Assert.areEqual(0, rflib_MockSingleRunOnlyTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.size());
    }

    @IsTest
    public static void testRun_BypassAllTriggerPermissionSet() {
        setup(ABORT_TRANSACTION);

        System.runAs(BYPASS_TRIGGERS_USER) {
            rflib_TriggerManager.dispatch(createArgs(createEvent()));

            Assert.areEqual(0, rflib_MockTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.size());
        }
    }

    @IsTest
    public static void testRun_BypassAllTriggerPermissionSetSingleRunOnly() {
        setup(MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER, ABORT_TRANSACTION);

        System.runAs(BYPASS_TRIGGERS_USER) {
            rflib_TriggerManager.dispatch(createArgs(createEvent()));

            Assert.areEqual(0, rflib_MockSingleRunOnlyTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.size());
        }
    }

    @IsTest
    public static void testRun_Success() {
        setup(ABORT_TRANSACTION);

        rflib_Log_Event__e ev = createEvent();

        System.runAs(STANDARD_USER) {
            rflib_TriggerManager.dispatch(createArgs(ev));

            assertRunTriggerArgs(ev);
        }
    }

    @IsTest
    public static void testRun_SuccessSingleRunOnly() {
        setup(MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER, ABORT_TRANSACTION);

        rflib_Log_Event__e ev = createEvent();

        System.runAs(STANDARD_USER) {
            rflib_TriggerManager.dispatch(createArgs(ev));

            assertRunTriggerArgs(ev, rflib_MockSingleRunOnlyTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS);
        }
    }

    @IsTest
    public static void testRun_ExceptionCaught() {
        setup(CATCH_EXCEPTION);

        rflib_MockTriggerHandler.EXCEPTION_ON_RUN = EX;

        rflib_Log_Event__e ev = createEvent();

        System.runAs(STANDARD_USER) {
            rflib_TriggerManager.dispatch(createArgs(ev));

            rflib_TriggerManager.Args args = assertRunTriggerArgs(ev);

            Assert.isTrue(args.hasExceptions());
            Assert.areEqual(
                ex.getMessage(),
                args.getCaughtExceptionsByType(rflib_MockTriggerHandler.class).get(0).getMessage()
            );
        }
    }

    @IsTest
    public static void testRun_ExceptionCaughtSingleRunOnly() {
        setup(MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER, CATCH_EXCEPTION);

        rflib_MockSingleRunOnlyTriggerHandler.EXCEPTION_ON_RUN = EX;

        rflib_Log_Event__e ev = createEvent();

        System.runAs(STANDARD_USER) {
            rflib_TriggerManager.dispatch(createArgs(ev));

            rflib_TriggerManager.Args args = assertRunTriggerArgs(
                ev,
                rflib_MockSingleRunOnlyTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS
            );

            Assert.isTrue(args.hasExceptions());
            Assert.areEqual(
                ex.getMessage(),
                args.getCaughtExceptionsByType(rflib_MockSingleRunOnlyTriggerHandler.class).get(0).getMessage()
            );
        }
    }

    @IsTest
    public static void testRun_ExceptionThrown() {
        setup(ABORT_TRANSACTION);

        rflib_MockTriggerHandler.EXCEPTION_ON_RUN = EX;

        rflib_Log_Event__e ev = createEvent();

        try {
            System.runAs(STANDARD_USER) {
                rflib_TriggerManager.dispatch(createArgs(ev));
                Assert.fail('Expected exception has not been thrown');
            }
        } catch (Exception actualException) {
            Assert.areEqual(EX.getMessage(), actualException.getMessage());
        }

        assertRunTriggerArgs(ev);
    }

    @IsTest
    public static void testRun_ExceptionThrownSingleRunOnly() {
        setup(MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER, ABORT_TRANSACTION);

        rflib_MockSingleRunOnlyTriggerHandler.EXCEPTION_ON_RUN = EX;

        rflib_Log_Event__e ev = createEvent();

        try {
            System.runAs(STANDARD_USER) {
                rflib_TriggerManager.dispatch(createArgs(ev));
                Assert.fail('Expected exception has not been thrown');
            }
        } catch (Exception actualException) {
            Assert.areEqual(EX.getMessage(), actualException.getMessage());
        }

        assertRunTriggerArgs(ev, rflib_MockSingleRunOnlyTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS);
    }

    @IsTest
    public static void testOnConsecutiveRun_Success() {
        setup(ABORT_TRANSACTION);

        rflib_Log_Event__e ev = createEvent();

        System.runAs(STANDARD_USER) {
            rflib_MockTriggerHandler.ACTION_WHEN_CALLED = new TriggerRecursiveRun(new Set<String>{ 'run' });

            rflib_TriggerManager.dispatch(createArgs(ev));

            assertRunTriggerArgs(ev);

            assertConsecutiveRunTriggerArgs(ev);
        }
    }

    @IsTest
    public static void testOnConsecutiveRun_SuccessSingleRunOnly() {
        setup(MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER, ABORT_TRANSACTION);

        rflib_Log_Event__e ev = createEvent();

        System.runAs(STANDARD_USER) {
            rflib_MockSingleRunOnlyTriggerHandler.ACTION_WHEN_CALLED = new TriggerRecursiveRun(
                new Set<String>{ 'run' }
            );

            rflib_TriggerManager.dispatch(createArgs(ev));

            assertRunTriggerArgs(ev, rflib_MockSingleRunOnlyTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS);
        }
    }

    @IsTest
    public static void testOnConsecutiveRun_SuccessSingleRunOnlyOverride() {
        setup(MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER_OVERRIDE, ABORT_TRANSACTION);

        rflib_Log_Event__e ev = createEvent();

        System.runAs(STANDARD_USER) {
            rflib_MockSROTriggerHandlerOverride.ACTION_WHEN_CALLED = new TriggerRecursiveRun(new Set<String>{ 'run' });

            rflib_TriggerManager.dispatch(createArgs(ev));

            assertRunTriggerArgs(ev, rflib_MockSROTriggerHandlerOverride.CAPTURED_RUN_TRIGGER_ARGS);

            assertConsecutiveRunTriggerArgs(
                ev,
                rflib_MockSROTriggerHandlerOverride.CAPTURED_CONSECUTIVE_RUN_TRIGGER_ARGS
            );
        }
    }

    @IsTest
    public static void testOnConsecutiveRun_ExceptionCaught() {
        setup(CATCH_EXCEPTION);

        rflib_Log_Event__e ev = createEvent();

        rflib_MockTriggerHandler.ACTION_WHEN_CALLED = new TriggerRecursiveRun(new Set<String>{ 'run' });
        rflib_MockTriggerHandler.EXCEPTION_ON_CONSECUTIVE_RUN = EX;

        System.runAs(STANDARD_USER) {
            rflib_TriggerManager.dispatch(createArgs(ev));

            assertRunTriggerArgs(ev);
        }

        rflib_TriggerManager.Args args = assertConsecutiveRunTriggerArgs(ev);

        Assert.isTrue(args.hasExceptions());
        Assert.areEqual(
            ex.getMessage(),
            args.getCaughtExceptionsByType(rflib_MockTriggerHandler.class).get(0).getMessage()
        );
    }

    @IsTest
    public static void testOnConsecutiveRun_ExceptionCaughtSingleRunOnlyOverride() {
        setup(MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER_OVERRIDE, CATCH_EXCEPTION);

        rflib_Log_Event__e ev = createEvent();

        rflib_MockSROTriggerHandlerOverride.ACTION_WHEN_CALLED = new TriggerRecursiveRun(new Set<String>{ 'run' });
        rflib_MockSROTriggerHandlerOverride.EXCEPTION_ON_CONSECUTIVE_RUN = EX;

        System.runAs(STANDARD_USER) {
            rflib_TriggerManager.dispatch(createArgs(ev));

            assertRunTriggerArgs(ev, rflib_MockSROTriggerHandlerOverride.CAPTURED_RUN_TRIGGER_ARGS);
        }

        rflib_TriggerManager.Args args = assertConsecutiveRunTriggerArgs(
            ev,
            rflib_MockSROTriggerHandlerOverride.CAPTURED_CONSECUTIVE_RUN_TRIGGER_ARGS
        );

        Assert.isTrue(args.hasExceptions());
        Assert.areEqual(
            ex.getMessage(),
            args.getCaughtExceptionsByType(rflib_MockSROTriggerHandlerOverride.class).get(0).getMessage()
        );
    }

    @IsTest
    public static void testOnConsecutiveRun_ExceptionThrown() {
        setup(ABORT_TRANSACTION);

        rflib_MockTriggerHandler.ACTION_WHEN_CALLED = new TriggerRecursiveRun(new Set<String>{ 'run' });
        rflib_MockTriggerHandler.EXCEPTION_ON_CONSECUTIVE_RUN = EX;

        rflib_Log_Event__e ev = createEvent();

        try {
            System.runAs(STANDARD_USER) {
                rflib_TriggerManager.dispatch(createArgs(ev));
                Assert.fail('Expected exception has not been thrown');
            }
        } catch (Exception actualException) {
            Assert.areEqual(EX.getMessage(), actualException.getMessage());
        }

        assertRunTriggerArgs(ev);
        assertConsecutiveRunTriggerArgs(ev);
    }

    @IsTest
    public static void testOnConsecutiveRun_ExceptionThrownSingleRunOnlyOverride() {
        setup(MOCK_SINGLE_RUN_ONLY_TRIGGER_HANDLER_OVERRIDE, ABORT_TRANSACTION);

        rflib_MockSROTriggerHandlerOverride.ACTION_WHEN_CALLED = new TriggerRecursiveRun(new Set<String>{ 'run' });
        rflib_MockSROTriggerHandlerOverride.EXCEPTION_ON_CONSECUTIVE_RUN = EX;

        rflib_Log_Event__e ev = createEvent();

        try {
            System.runAs(STANDARD_USER) {
                rflib_TriggerManager.dispatch(createArgs(ev));
                Assert.fail('Expected exception has not been thrown');
            }
        } catch (Exception actualException) {
            Assert.areEqual(EX.getMessage(), actualException.getMessage());
        }

        assertRunTriggerArgs(ev, rflib_MockSROTriggerHandlerOverride.CAPTURED_RUN_TRIGGER_ARGS);
        assertConsecutiveRunTriggerArgs(ev, rflib_MockSROTriggerHandlerOverride.CAPTURED_CONSECUTIVE_RUN_TRIGGER_ARGS);
    }

    @IsTest
    public static void testDefaultTriggerConfigurationQueryLocator() {
        List<rflib_Trigger_Configuration__mdt> expectedResult = [
            SELECT Class_Name__c, Order__c, Exception_Behavior__c
            FROM rflib_Trigger_Configuration__mdt
            WHERE Active__c = TRUE AND Object_Name__c = :OBJECT_TYPE_NAME AND Event__c = :AFTER_INSERT
            ORDER BY Order__c, Class_Name__c ASC
        ];

        List<rflib_Trigger_Configuration__mdt> actualResult = new rflib_TriggerManager.DefaultTriggerConfigurationQueryLocator()
            .getRecords(OBJECT_TYPE_NAME, AFTER_INSERT);

        Assert.areEqual(expectedResult.size(), actualResult.size());
    }

    @IsTest
    public static void testDefaultTriggerConfigurationQueryLocatorSorting() {
        rflib_Trigger_Configuration__mdt config3 = createConfiguration(
            true,
            'rflib_MockTriggerHandler3',
            OBJECT_TYPE_NAME,
            AFTER_INSERT,
            2,
            ABORT_TRANSACTION
        );
        rflib_Trigger_Configuration__mdt config2 = createConfiguration(
            true,
            'rflib_MockTriggerHandler2',
            OBJECT_TYPE_NAME,
            AFTER_INSERT,
            2,
            ABORT_TRANSACTION
        );
        rflib_Trigger_Configuration__mdt config1 = createConfiguration(
            true,
            'rflib_MockTriggerHandler1',
            OBJECT_TYPE_NAME,
            AFTER_INSERT,
            1,
            ABORT_TRANSACTION
        );

        List<rflib_Trigger_Configuration__mdt> configMetadata = new List<rflib_Trigger_Configuration__mdt>{
            config3,
            config2,
            config1,
            createConfiguration(false, 'InvalidHandler', OBJECT_TYPE_NAME, AFTER_INSERT, 1, ABORT_TRANSACTION),
            createConfiguration(true, 'InvalidHandler', 'SomeOtherObject', AFTER_INSERT, 1, ABORT_TRANSACTION),
            createConfiguration(
                true,
                'InvalidHandler',
                OBJECT_TYPE_NAME,
                TriggerOperation.AFTER_UPDATE.name(),
                1,
                ABORT_TRANSACTION
            )
        };

        rflib_TriggerManager.DefaultTriggerConfigurationQueryLocator locator = new rflib_TriggerManager.DefaultTriggerConfigurationQueryLocator();
        locator.allConfigValues = configMetadata;
        List<rflib_Trigger_Configuration__mdt> actualResult = locator.getRecords(OBJECT_TYPE_NAME, AFTER_INSERT);

        Assert.areEqual(3, actualResult.size());
        Assert.areEqual(config1.Class_Name__c, actualResult.get(0).Class_Name__c);
        Assert.areEqual(config2.Class_Name__c, actualResult.get(1).Class_Name__c);
        Assert.areEqual(config3.Class_Name__c, actualResult.get(2).Class_Name__c);
    }

    @IsTest
    public static void testConfigWrapper() {
        rflib_TriggerManager.TriggerConfigurationWrapper wrapper1 = new rflib_TriggerManager.TriggerConfigurationWrapper(
            createConfiguration(MOCK_TRIGGER_HANDLER, 1)
        );
        rflib_TriggerManager.TriggerConfigurationWrapper wrapper2 = new rflib_TriggerManager.TriggerConfigurationWrapper(
            createConfiguration(MOCK_TRIGGER_HANDLER, 2)
        );
        rflib_TriggerManager.TriggerConfigurationWrapper wrapper3 = new rflib_TriggerManager.TriggerConfigurationWrapper(
            createConfiguration(MOCK_TRIGGER_HANDLER, 3)
        );
        rflib_TriggerManager.TriggerConfigurationWrapper wrapper4 = new rflib_TriggerManager.TriggerConfigurationWrapper(
            createConfiguration(MOCK_TRIGGER_HANDLER, 2)
        );
        rflib_TriggerManager.TriggerConfigurationWrapper wrapper5 = new rflib_TriggerManager.TriggerConfigurationWrapper(
            createConfiguration('rflib_ATriggerHandler', 2)
        );
        rflib_TriggerManager.TriggerConfigurationWrapper noWrapper = new rflib_TriggerManager.TriggerConfigurationWrapper(
            null
        );

        Assert.areEqual(1, wrapper1.compareTo(null));
        Assert.areEqual(1, wrapper1.compareTo(noWrapper));
        Assert.areEqual(-1, noWrapper.compareTo(wrapper1));
        Assert.areEqual(0, wrapper2.compareTo(wrapper4));
        Assert.areEqual(0, noWrapper.compareTo(noWrapper));
        Assert.areEqual(-1, noWrapper.compareTo(wrapper1));
        Assert.areEqual(-1, wrapper1.compareTo(wrapper2));
        Assert.areEqual(-1, wrapper2.compareTo(wrapper3));
        Assert.areEqual(1, wrapper3.compareTo(wrapper2));
        Assert.areEqual(1, wrapper3.compareTo(wrapper1));
        Assert.areEqual(-1, wrapper5.compareTo(wrapper2));
        Assert.areEqual(1, wrapper2.compareTo(wrapper5));
    }

    @IsTest
    public static void testInvalidHandlerName() {
        rflib_TriggerManager.QUERY_LOCATOR = new rflib_MockTriggerConfigQueryLocator(
            createConfiguration('rflib_InvalidClassName', 1),
            OBJECT_TYPE_NAME,
            AFTER_INSERT
        );

        rflib_Log_Event__e ev = createEvent();

        System.runAs(STANDARD_USER) {
            rflib_TriggerManager.dispatch(createArgs(ev));

            Assert.areEqual(0, rflib_MockTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.size());
        }
    }

    @IsTest
    public static void testChainedHandlerInvocation() {
        rflib_TriggerManager.QUERY_LOCATOR = new rflib_MockTriggerConfigQueryLocator(
            new Map<String, Map<String, List<rflib_Trigger_Configuration__mdt>>>{
                OBJECT_TYPE_NAME => new Map<String, List<rflib_Trigger_Configuration__mdt>>{
                    AFTER_INSERT => new List<rflib_Trigger_Configuration__mdt>{
                        createConfiguration(ABORT_TRANSACTION)
                    },
                    AFTER_UPDATE => new List<rflib_Trigger_Configuration__mdt>{
                        createConfiguration(
                            true,
                            'rflib_TriggerManagerTest.SimpleMockTriggerHandler',
                            OBJECT_TYPE_NAME,
                            AFTER_UPDATE,
                            1,
                            ABORT_TRANSACTION
                        )
                    }
                }
            }
        );

        rflib_Log_Event__e ev = createEvent();

        System.runAs(STANDARD_USER) {
            rflib_MockTriggerHandler.ACTION_WHEN_CALLED = new TriggerChainRun(
                createArgs(ev, TriggerOperation.AFTER_UPDATE)
            );

            rflib_TriggerManager.dispatch(createArgs(ev));

            assertRunTriggerArgs(ev);

            Assert.isTrue(SIMPLE_HANDLER_MOCK_RUN_INVOKED);
            Assert.isFalse(SIMPLE_HANDLER_MOCK_CONSECUTIVERUN_INVOKED);
        }
    }

    private static rflib_TriggerManager.Args assertRunTriggerArgs(rflib_Log_Event__e ev) {
        Assert.areEqual(1, rflib_MockTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.size());

        rflib_TriggerManager.Args args = rflib_MockTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.get(0);

        rflib_Log_Event__e capturedEvent = (rflib_Log_Event__e) args.newRecords.get(0);
        Assert.areEqual(ev.Context__c, capturedEvent.Context__c);

        return args;
    }

    private static rflib_TriggerManager.Args assertRunTriggerArgs(
        rflib_Log_Event__e ev,
        List<rflib_TriggerManager.Args> args
    ) {
        Assert.areEqual(1, args.size());

        rflib_TriggerManager.Args capturedArgs = args.get(0);

        rflib_Log_Event__e capturedEvent = (rflib_Log_Event__e) capturedArgs.newRecords.get(0);
        Assert.areEqual(ev.Context__c, capturedEvent.Context__c);

        return capturedArgs;
    }

    private static rflib_TriggerManager.Args assertConsecutiveRunTriggerArgs(rflib_Log_Event__e ev) {
        Assert.areEqual(1, rflib_MockTriggerHandler.CAPTURED_CONSECUTIVE_RUN_TRIGGER_ARGS.size());

        rflib_TriggerManager.Args args = rflib_MockTriggerHandler.CAPTURED_CONSECUTIVE_RUN_TRIGGER_ARGS.get(0);

        rflib_Log_Event__e capturedEvent = (rflib_Log_Event__e) args.newRecords.get(0);
        Assert.areEqual(ev.Context__c, capturedEvent.Context__c);

        return args;
    }

    private static rflib_TriggerManager.Args assertConsecutiveRunTriggerArgs(
        rflib_Log_Event__e ev,
        List<rflib_TriggerManager.Args> args
    ) {
        Assert.areEqual(1, args.size());

        rflib_TriggerManager.Args capturedArgs = args.get(0);

        rflib_Log_Event__e capturedEvent = (rflib_Log_Event__e) capturedArgs.newRecords.get(0);
        Assert.areEqual(ev.Context__c, capturedEvent.Context__c);

        return capturedArgs;
    }

    private static rflib_TriggerManager.Args createArgs(rflib_Log_Event__e record) {
        return createArgs(record, TriggerOperation.AFTER_INSERT);
    }

    private static rflib_TriggerManager.Args createArgs(rflib_Log_Event__e record, TriggerOperation operation) {
        return new rflib_TriggerManager.Args(
            rflib_Log_Event__e.SObjectType,
            operation,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>{ record },
            new Map<Id, SObject>(),
            1
        );
    }

    private static rflib_Log_Event__e createEvent() {
        return new rflib_Log_Event__e(
            Request_ID__c = 'Some Request ID',
            Log_Level__c = 'INFO',
            Context__c = 'rflib_TriggerManagerTest',
            Log_Messages__c = 'Some log messages'
        );
    }

    private static rflib_Trigger_Configuration__mdt createConfiguration(String exceptionBehaviour) {
        return createConfiguration(true, MOCK_TRIGGER_HANDLER, OBJECT_TYPE_NAME, 'AFTER_INSERT', 1, exceptionBehaviour);
    }

    private static rflib_Trigger_Configuration__mdt createConfiguration(String className, String exceptionBehaviour) {
        return createConfiguration(true, className, OBJECT_TYPE_NAME, 'AFTER_INSERT', 1, exceptionBehaviour);
    }

    private static rflib_Trigger_Configuration__mdt createConfiguration(String name, Integer order) {
        return createConfiguration(true, name, OBJECT_TYPE_NAME, 'AFTER_INSERT', order, ABORT_TRANSACTION);
    }

    private static rflib_Trigger_Configuration__mdt createConfiguration(
        Boolean active,
        String className,
        String objectName,
        String eventName,
        Integer order,
        String exceptionBehaviour
    ) {
        return new rflib_Trigger_Configuration__mdt(
            Active__c = active,
            Class_Name__c = className,
            Object_Name__c = objectName,
            Event__c = eventName,
            Order__c = order,
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

    public class TriggerChainRun implements Callable {
        private rflib_TriggerManager.Args triggerArgs;

        public TriggerChainRun(rflib_TriggerManager.Args triggerArgs) {
            this.triggerArgs = triggerArgs;
        }

        public Object call(String action, Map<String, Object> args) {
            rflib_TriggerManager.dispatch(triggerArgs);

            return null;
        }
    }

    public class SimpleMockTriggerHandler implements rflib_TriggerHandler {
        public void run(rflib_TriggerManager.Args args) {
            SIMPLE_HANDLER_MOCK_RUN_INVOKED = true;
        }

        public void onConsecutiveRun(rflib_TriggerManager.Args args, Integer numInvocation) {
            SIMPLE_HANDLER_MOCK_CONSECUTIVERUN_INVOKED = true;
        }
    }

    public class MockTriggerHandlerException extends Exception {
    }
}
