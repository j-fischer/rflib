/*
 * Copyright (c) 2023 Johannes Fischer <fischer.jh@gmail.com>
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
private class rflib_EventBusPublisherTest {

    @IsTest
    static void testPublish_SingleEvent() {
        rflib_Application_Event_Occurred_Event__e evt = createEvent(1);
        
        Test.startTest();
        Database.SaveResult sr = new rflib_EventBusPublisher().publish(evt);
        Test.stopTest();
        
        Assert.isTrue(sr.isSuccess());
    }

    @IsTest
    static void testPublish_BatchEvents() {
        rflib_Application_Event_Occurred_Event__e evt1 = createEvent(1);
        rflib_Application_Event_Occurred_Event__e evt2 = createEvent(2);
        
        Test.startTest();
        List<Database.SaveResult> sr = new rflib_EventBusPublisher().publish(new List<SObject> { evt1, evt2 });
        Test.stopTest();
        
        Assert.isTrue(sr[0].isSuccess());
        Assert.isTrue(sr[1].isSuccess());
    }

    private static rflib_Application_Event_Occurred_Event__e createEvent(Integer index) {
        return new rflib_Application_Event_Occurred_Event__e(
            Event_Name__c = 'Test Event ' + index, 
            Related_Record_ID__c = '003123456789012345', 
            Additional_Details__c = 'Test Additional Details ' + index,
            Created_By_ID__c = UserInfo.getUserId(),
            Occurred_On__c = DateTime.now()
        );
    }
            
}