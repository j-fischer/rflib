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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_DefaultApplicationEventServiceTest {

    private static final rflib_MockEventPublisher MOCK_EVENT_PUBLISHER = new rflib_MockEventPublisher();
    private static final rflib_MockBigObjectDatabaseExecutor MOCK_BIG_OBJECT_DB_EXECUTOR = new rflib_MockBigObjectDatabaseExecutor();

    @isTest
    static void testSaveApplicationEvent() {
        String eventName = 'Test Event';
        String relatedRecordId = '003123456789012345';
        String additionalDetails = 'Test Additional Details';
        
        rflib_DefaultApplicationEventService.EVENT_PUBLISHER = MOCK_EVENT_PUBLISHER;
        rflib_DefaultApplicationEventService service = new rflib_DefaultApplicationEventService();
        Test.startTest();
        service.saveApplicationEvent(eventName, relatedRecordId, additionalDetails);
        Test.stopTest();

        rflib_Application_Event_Occurred_Event__e event = (rflib_Application_Event_Occurred_Event__e) MOCK_EVENT_PUBLISHER.capturedPlatformEvent;
        Assert.areEqual(eventName, event.Event_Name__c);
        Assert.areEqual(relatedRecordId, event.Related_Record_ID__c);
        Assert.areEqual(additionalDetails, event.Additional_Details__c);
        Assert.areEqual(UserInfo.getUserId(), event.Created_By_ID__c);
    }

    @isTest
    static void testArchiveEvents() {
        rflib_Application_Event__c evt1 = createApplicationEvent('Test Event 1', 'Id1', 'Test Additional Details 1');
        rflib_Application_Event__c evt2 = createApplicationEvent('Test Event 2', 'Id2', 'Test Additional Details 2');
        insert new List<rflib_Application_Event__c>{evt1, evt2};
        
        rflib_DefaultApplicationEventService.BIG_OBJECT_DB_EXECUTOR = MOCK_BIG_OBJECT_DB_EXECUTOR;
        rflib_DefaultApplicationEventService service = new rflib_DefaultApplicationEventService();
        Test.startTest();
        service.archiveEvents(new List<rflib_Application_Event__c>{evt1, evt2});
        Test.stopTest();

        List<rflib_Application_Event__c> eventRecords = [SELECT Id FROM rflib_Application_Event__c];
        Assert.areEqual(0, eventRecords.size());
        
        List<rflib_Application_Event_Archive__b> archiveRecords = (List<rflib_Application_Event_Archive__b>) MOCK_BIG_OBJECT_DB_EXECUTOR.records;
        Assert.areEqual(2, archiveRecords.size());
        validateArchiveRecord(archiveRecords[0], 'Test Event 1', 'Id1', 'Test Additional Details 1');
        validateArchiveRecord(archiveRecords[1], 'Test Event 2', 'Id2', 'Test Additional Details 2');
    }

    private static void validateArchiveRecord(rflib_Application_Event_Archive__b actualRecord, String expectedEventName, String expectedRecordId, String expectedAdditionalDetails) {
        Assert.areEqual(expectedEventName, actualRecord.Event_Name__c);
        Assert.areEqual(expectedRecordId, actualRecord.Related_Record_ID__c);
        Assert.areEqual(expectedAdditionalDetails, actualRecord.Additional_Details__c);
    }
    
    private static rflib_Application_Event__c createApplicationEvent(String eventName, String recordId, String additionalDetails) {
        return new rflib_Application_Event__c(
            Event_Name__c = eventName, 
            Related_Record_ID__c = recordId, 
            Additional_Details__c = additionalDetails,
            Created_By_ID__c = UserInfo.getUserId(), 
            Occurred_On__c = Datetime.now()
        );
    }
}
