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
@IsTest
private class rflib_BigObjectStatTriggerHandlerTest {

    private static final rflib_MockEventPublisher MOCK_EVENT_PUBLISHER = new rflib_MockEventPublisher();

    @IsTest
    static void testAfterInsert_publishesEvent() {
        rflib_BigObjectStatTriggerHandler.EVENT_PUBLISHER = MOCK_EVENT_PUBLISHER;
        
        List<rflib_Big_Object_Stat__c> stats = new List<rflib_Big_Object_Stat__c>();
        for (Integer i = 0; i < 5; i++) {
            stats.add(new rflib_Big_Object_Stat__c());
        }

        insert stats; 

        Assert.areEqual(1, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published once');
        validateEvent(MOCK_EVENT_PUBLISHER.capturedPlatformEvents.get(0));
    }

    @IsTest
    static void testAfterUpdate_publishesEvent() {
        rflib_BigObjectStatTriggerHandler.EVENT_PUBLISHER = MOCK_EVENT_PUBLISHER;

        List<rflib_Big_Object_Stat__c> stats = new List<rflib_Big_Object_Stat__c>();
        for (Integer i = 0; i < 3; i++) {
            stats.add(new rflib_Big_Object_Stat__c());
        }
        insert stats;
        Assert.areEqual(1, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published once');

        update stats;

        Assert.areEqual(2, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published twice');
        validateEvent(MOCK_EVENT_PUBLISHER.capturedPlatformEvents.get(0));
    }

    @IsTest
    static void testAfterDelete_publishesEvent() {
        rflib_BigObjectStatTriggerHandler.EVENT_PUBLISHER = MOCK_EVENT_PUBLISHER;

        List<rflib_Big_Object_Stat__c> stats = new List<rflib_Big_Object_Stat__c>();
        for (Integer i = 0; i < 4; i++) {
            stats.add(new rflib_Big_Object_Stat__c());
        }
        insert stats;
        Assert.areEqual(1, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published once');
        
        delete stats;

        Assert.areEqual(2, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published twice');
        validateEvent(MOCK_EVENT_PUBLISHER.capturedPlatformEvents.get(0));
    }

    static void validateEvent(SObject e) {
        Assert.isInstanceOfType(e, rflib_Big_Object_Stat_Event__e.class, 'Event should be a Big Object Stat Event');
    }
}
