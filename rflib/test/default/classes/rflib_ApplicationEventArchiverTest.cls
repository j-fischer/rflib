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
    private static final String QUERY_MOCK_ID = 'rflib_ApplicationEventArchiver.execute';

    @IsTest
    private static void testExecute() {
        // GIVEN
        rflib_MockApplicationEventService mockService = new rflib_MockApplicationEventService();
        rflib_ApplicationEventArchiver.APPLICATION_EVENT_SERVICE = mockService;
        rflib_ApplicationEventArchiver.TODAY = TODAY;
        
        List<rflib_Application_Event__c> events = new List<rflib_Application_Event__c>{
            createEvent(TODAY.addDays(-31), 'Event1'),
            createEvent(TODAY.addDays(-29), 'Event2')
        };

        rflib_SOQL.setMock(QUERY_MOCK_ID, events);

        // WHEN
        Test.startTest();
        new rflib_ApplicationEventArchiver().execute(null);
        Test.stopTest();

        // THEN
        System.assertEquals(2, events.size(), 'Expected all events to be processed');
        System.assertEquals(events, mockService.capturedEvents, 'Events should be captured by mock service');
    }

    @IsTest
    private static void testExecuteWithNoEvents() {
        // GIVEN
        rflib_MockApplicationEventService mockService = new rflib_MockApplicationEventService();
        rflib_ApplicationEventArchiver.APPLICATION_EVENT_SERVICE = mockService;
        rflib_ApplicationEventArchiver.TODAY = TODAY;

        rflib_SOQL.setMock(QUERY_MOCK_ID, new List<rflib_Application_Event__c>());

        // WHEN
        Test.startTest();
        new rflib_ApplicationEventArchiver().execute(null);
        Test.stopTest();

        // THEN
        System.assertEquals(0, mockService.capturedEvents.size(), 'No events should be captured');
    }

    @IsTest
    private static void testExecuteWithQueryLimit() {
        // GIVEN
        rflib_MockApplicationEventService mockService = new rflib_MockApplicationEventService();
        rflib_ApplicationEventArchiver.APPLICATION_EVENT_SERVICE = mockService;
        rflib_ApplicationEventArchiver.TODAY = TODAY;

        rflib_GlobalSettings.SETTINGS.put('Archive_App_Event_Query_Limit', '1');
        rflib_GlobalSettings.SETTINGS.put('Application_Event_Retain_X_Days', '1');
        
        List<rflib_Application_Event__c> events = new List<rflib_Application_Event__c>{
            createEvent(TODAY.addDays(-2), 'Event1'),
            createEvent(TODAY.addDays(-3), 'Event2')
        };

        insert events;

        Assert.areEqual(2, [SELECT Id FROM rflib_Application_Event__c].size(), 'Should have 2 events');

        // WHEN
        Test.startTest();
        new rflib_ApplicationEventArchiver().execute(null);
        Test.stopTest();

        // THEN
        Assert.areEqual(1, mockService.capturedEvents.size(), 'Should respect query limit');
    }

    @IsTest
    private static void testExecuteWithNumberOfRetainedDays() {
        // GIVEN
        rflib_MockApplicationEventService mockService = new rflib_MockApplicationEventService();
        rflib_ApplicationEventArchiver.APPLICATION_EVENT_SERVICE = mockService;
        rflib_ApplicationEventArchiver.TODAY = TODAY;

        rflib_GlobalSettings.SETTINGS.put('Archive_App_Event_Query_Limit', '10000');
        rflib_GlobalSettings.SETTINGS.put('Application_Event_Retain_X_Days', '30');
        
        List<rflib_Application_Event__c> events = new List<rflib_Application_Event__c>{
            createEvent(TODAY.addDays(-31), 'Event1'),
            createEvent(TODAY.addDays(-29), 'Event2')
        };

        insert events;

        // WHEN
        Test.startTest();
        new rflib_ApplicationEventArchiver().execute(null);
        Test.stopTest();

        // THEN
        System.assertEquals(1, mockService.capturedEvents.size(), 'Expected only one event to be archived');
        System.assertEquals('Event1', mockService.capturedEvents.get(0).Event_Name__c, 'Expected only one event to be archived');
    }

    @IsTest
    private static void testExecuteWithError() {
        // GIVEN
        Exception expectedException = new IllegalArgumentException('Test Exception');
        rflib_MockApplicationEventService mockService = new rflib_MockApplicationEventService(expectedException);
        rflib_ApplicationEventArchiver.APPLICATION_EVENT_SERVICE = mockService;
        rflib_ApplicationEventArchiver.TODAY = TODAY;
        
        List<rflib_Application_Event__c> events = new List<rflib_Application_Event__c>{
            createEvent(TODAY.addDays(-31), 'Event1')
        };

        rflib_SOQL.setMock('rflib_ApplicationEventArchiver.execute', events);

        // WHEN
        Test.startTest();
        new rflib_ApplicationEventArchiver().execute(null);
        Test.stopTest();

        // THEN - Exception should be caught and logged
        Assert.isNotNull(mockService.capturedEvents, 'Events should be captured even on error');
    }

    private static rflib_Application_Event__c createEvent(Date occurredOn, String name) {
        return new rflib_Application_Event__c(
            Occurred_On__c = occurredOn,
            Event_Name__c = name,
            Additional_Details__c = 'Details' + name,
            Created_By_ID__c = UserInfo.getUserId()
        );
    }
}