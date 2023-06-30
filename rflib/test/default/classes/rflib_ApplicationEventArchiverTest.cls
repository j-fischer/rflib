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
private class rflib_ApplicationEventArchiverTest {

    private static final Date TODAY = Date.today();

    @IsTest
    private static void testExecute() {
        rflib_MockApplicationEventService mockApplicationEventService = new rflib_MockApplicationEventService();

        rflib_ApplicationEventArchiver.APPLICATION_EVENT_SERVICE = mockApplicationEventService;
        rflib_ApplicationEventArchiver.TODAY = TODAY;
        rflib_ApplicationEventArchiver.APPLICATION_EVENT_RETAIN_X_DAYS = new rflib_Global_Setting__mdt(
            DeveloperName = 'Application_Event_Retain_X_Days',
            Value__c = '30'
        );

        List<rflib_Application_Event__c> events = new List<rflib_Application_Event__c>{
            new rflib_Application_Event__c(
                Occurred_On__c = TODAY.addDays(-31),
                Event_Name__c = 'Event1',
                Additional_Details__c = 'Details1',
                Created_By_ID__c = UserInfo.getUserId()
            ),
            new rflib_Application_Event__c(
                Occurred_On__c = TODAY.addDays(-29),
                Event_Name__c = 'Event2',
                Additional_Details__c = 'Details2',
                Created_By_ID__c = UserInfo.getUserId()
            )
        };
        insert events;

        Test.startTest();
        rflib_ApplicationEventArchiver job = new rflib_ApplicationEventArchiver();
        String jobId = System.schedule('testSchedule', '0 0 * * * ?', job);
        Test.stopTest();

        List<rflib_Application_Event__c> archivedEvents = mockApplicationEventService.capturedEvents;
        Assert.areEqual(1, archivedEvents.size());
        Assert.areEqual('Event1', archivedEvents[0].Event_Name__c);
        Assert.areEqual('Details1', archivedEvents[0].Additional_Details__c);
    }
}