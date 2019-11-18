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
private class rflib_LogEventTriggerTest {

    private static final String AFTER_INSERT = TriggerOperation.AFTER_INSERT.name();
    
    @IsTest
    public static void testTriggerExecution() {
        rflib_TriggerManager.QUERY_LOCATOR = new rflib_MockTriggerConfigQueryLocator(
            createConfiguration(), 
            rflib_Log_Event__e.SObjectType.getDescribe().getName(), 
            AFTER_INSERT
        );

        rflib_Log_Event__e ev = createEvent();

        Test.startTest();
        EventBus.publish(ev);
        Test.stopTest();

        System.assertEquals(1, rflib_MockTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.size());

        rflib_TriggerManager.Args args = rflib_MockTriggerHandler.CAPTURED_RUN_TRIGGER_ARGS.get(0);
        rflib_Log_Event__e capturedEvent = (rflib_Log_Event__e) args.newRecords.get(0); 
        System.assertEquals(ev.Context__c, capturedEvent.Context__c);
    }

    private static rflib_Log_Event__e createEvent() {
        return new rflib_Log_Event__e(
            Context__c = 'rflib_LogEventTriggerTest',
            Log_Messages__c = 'Some log messages'
        );
    }

    private static rflib_Trigger_Configuration__mdt createConfiguration() {
        return new rflib_Trigger_Configuration__mdt(
            Active__c = true,
            Class_Name__c = 'rflib_MockTriggerHandler',
            Object_Name__c = 'rflib_Log_Event__e',
            Event__c = 'AFTER_INSERT',
            Order__c = 1
        );
    }
}
