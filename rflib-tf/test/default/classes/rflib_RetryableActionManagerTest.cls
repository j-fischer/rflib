/*
 * Copyright (c) 2022 Johannes Fischer <fischer.jh@gmail.com>
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
private class rflib_RetryableActionManagerTest {

    private static final Exception EX = new rflib_TestException('This is a rflib_MockRetryableActionHandlerException');

    private static void setup() {
        rflib_TestUtil.prepareLoggerForUnitTests();

        rflib_RetryableActionManager.ALL_CONFIG_VALUES = new List<rflib_Retryable_Action_Config__mdt> {
            createConfiguration('Action_One', 1)
        };
    }

    @IsTest
    public static void testRun_AllRetryableActionsFeatureSwitchOff() {
        setup();

        rflib_FeatureSwitch.featureSwitches = new Map<String,Map<String,Boolean>> {
            'All_Retryable_Actions' => new Map<String,Boolean> {
                rflib_FeatureSwitch.GLOBAL_SCOPE => false   
            }
        };

        Test.startTest();
        rflib_RetryableActionManager.dispatch(createEvents());
        Test.stopTest();

        System.assertEquals(0, rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.size());
    }

    @IsTest
    public static void testExecute_OneHandler() {
        setup();

        List<rflib_Retryable_Action__e> events = createEvents();
        
        Test.startTest();
        rflib_RetryableActionManager.dispatch(events);
        Test.stopTest();

        System.assertEquals(2, rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.size());
        System.assertEquals('recId1', rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.get(0).Record_ID__c);
        System.assertEquals('recId3', rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.get(1).Record_ID__c);
    }

    @IsTest
    public static void testExecute_MultipleHandler() {
        setup();

        rflib_RetryableActionManager.ALL_CONFIG_VALUES = new List<rflib_Retryable_Action_Config__mdt> {
            createConfiguration('Action_One', 1),
            createConfiguration('Action_One', 2)
        };

        List<rflib_Retryable_Action__e> events = createEvents();
        
        Test.startTest();
        rflib_RetryableActionManager.dispatch(events);
        Test.stopTest();

        // It would be expected that each handler is a different class, but the test scenario was simplified with a single mock.
        System.assertEquals(4, rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.size());
        System.assertEquals('recId1', rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.get(0).Record_ID__c);
        System.assertEquals('recId3', rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.get(1).Record_ID__c);
        System.assertEquals('recId1', rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.get(2).Record_ID__c);
        System.assertEquals('recId3', rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.get(3).Record_ID__c);
    }

    @IsTest
    public static void testExecute_DeactivatedHandler() {
        setup();

        rflib_RetryableActionManager.ALL_CONFIG_VALUES = new List<rflib_Retryable_Action_Config__mdt> {
            createConfiguration('Action_One', 1, false),
            createConfiguration('Action_Two', 1)
        };

        List<rflib_Retryable_Action__e> events = createEvents();
        
        Test.startTest();
        rflib_RetryableActionManager.dispatch(events);
        Test.stopTest();

        System.assertEquals(1, rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.size());
        System.assertEquals('recId2', rflib_MockRetryableActionHandler.CAPTURED_ACTION_EVENTS.get(0).Record_ID__c);
    }

    private static List<rflib_Retryable_Action__e> createEvents() {
        return new List<rflib_Retryable_Action__e> {
            new rflib_Retryable_Action__e(
                Record_ID__c = 'recId1',
                Action__c = 'Action_One'
            ),
            new rflib_Retryable_Action__e(
                Record_ID__c = 'recId2',
                Action__c = 'Action_Two'
            ),
            new rflib_Retryable_Action__e(
                Record_ID__c = 'recId3',
                Action__c = 'Action_One'
            )
        };
    }

    private static rflib_Retryable_Action_Config__mdt createConfiguration(String actionName, Integer order) {
        return createConfiguration(
            actionName,
            order,
            true
        );
    }
    
    private static rflib_Retryable_Action_Config__mdt createConfiguration(String actionName, Integer order, Boolean active) {
        return new rflib_Retryable_Action_Config__mdt(
            Active__c = active,
            Class_Name__c = 'rflib_MockRetryableActionHandler',
            Action_Name__c = actionName,
            Order__c = order
        );
    }
}
