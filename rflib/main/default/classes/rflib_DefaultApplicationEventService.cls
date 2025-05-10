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
@SuppressWarnings('PMD.ClassNamingConventions')
public inherited sharing class rflib_DefaultApplicationEventService implements rflib_ApplicationEventService {

    public static final String NO_RECORD_ID = 'NO_RECORD_ID';
    public static Integer QUERY_RECORD_LIMIT = 50000;

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_DefaultApplicationEventService');

    public static final Integer MAX_ADDITIONAL_DETAIL_SIZE = 32768;

    @TestVisible
    private static rflib_BigObjectDatabaseExecutor BIG_OBJECT_DB_EXECUTOR = new rflib_DefaultBigObjectDatabaseExecutor();

    @TestVisible
    private static IBigObjectQueryLocator QUERY_LOCATOR = new DefaultLogArchiveQueryLocator();

    @TestVisible
    private static rflib_DmlExecutor DML_EXECUTOR = new rflib_DatabaseDmlExecutor();

    @TestVisible
    private static rflib_EventPublisher EVENT_PUBLISHER = new rflib_EventBusPublisher();

    @TestVisible
    private static DateTime NOW {
        get {
            if (NOW == null) {
                return DateTime.now();
            }
            return NOW;
        }
        set;
    }

    public void publishApplicationEvent(String eventName, String relatedRecordId, String additionalDetails) {
        LOGGER.debug('publishApplicationEvent({0}, {1}, {2})', new Object[] { eventName, relatedRecordId, additionalDetails });

        publishApplicationEvents(new List<rflib_ApplicationEventDetails> { 
            new rflib_ApplicationEventDetails(eventName, relatedRecordId, additionalDetails)
        });
    }

    public void publishApplicationEvents(List<rflib_ApplicationEventDetails> applicationEvents) {
        LOGGER.debug('publishApplicationEvents({0})', new Object[] { applicationEvents });

        Integer publishingLimitOrDefault = rflib_GlobalSettings.publishingLimitOrDefault != null 
            ? rflib_GlobalSettings.publishingLimitOrDefault
            : Limits.getLimitPublishImmediateDML();
            
        if (Limits.getPublishImmediateDML() == Limits.getLimitPublishImmediateDML()) {
            System.debug(LoggingLevel.ERROR, 'RFLIB: PublishImmediateDML Governor Limit reached; failed to publish application events');
            return;
        }

        if (EVENT_PUBLISHER.getPublishingCounter() == publishingLimitOrDefault) {
            System.debug(LoggingLevel.ERROR, 'RFLIB: Publish Immediate DML limit (' + publishingLimitOrDefault +') reached; failed to publish application events: ');
            return;
        }

        DateTime occurredOn = NOW;

        List<rflib_Application_Event_Occurred_Event__e> eventsToPublish = new List<rflib_Application_Event_Occurred_Event__e>();
        for (rflib_ApplicationEventDetails evt : applicationEvents) {
            Integer additionalDetailsLength = evt.additionalDetails != null ? evt.additionalDetails.length() : 0;
            String additionalDetailsToSave = additionalDetailsLength < MAX_ADDITIONAL_DETAIL_SIZE
                ? evt.additionalDetails
                : evt.additionalDetails.substring(additionalDetailsLength - MAX_ADDITIONAL_DETAIL_SIZE);

            eventsToPublish.add(new rflib_Application_Event_Occurred_Event__e(
                Event_Name__c = evt.eventName,
                Occurred_On__c = occurredOn,
                Related_Record_ID__c = String.isNotBlank(evt.relatedRecordId) ? evt.relatedRecordId : NO_RECORD_ID,
                Additional_Details__c = additionalDetailsToSave,
                Created_By_ID__c = UserInfo.getUserId()
            ));
        }

        if (EVENT_PUBLISHER.getPublishingCounter() == (publishingLimitOrDefault - 1)) {
            eventsToPublish.add(new rflib_Application_Event_Occurred_Event__e(
                Event_Name__c = 'application-event-publishing-limit-reached',
                Occurred_On__c = occurredOn,
                Related_Record_ID__c = NO_RECORD_ID,
                Additional_Details__c = null,
                Created_By_ID__c = UserInfo.getUserId()
            ));
        }
        
        EVENT_PUBLISHER.publish(eventsToPublish);
    }

    public void archiveEvents(List<rflib_Application_Event__c> events) {
        LOGGER.debug('archiveEvents({0})', new Object[] { events });
        
        if (events.isEmpty()) {
            LOGGER.debug('No events found, cancelling');
            return;
        }
        
        List<rflib_Application_Event_Archive__b> archivedRecords = new List<rflib_Application_Event_Archive__b>();
        for (rflib_Application_Event__c evt : events) {
            archivedRecords.add(convert(evt));
        }

        BIG_OBJECT_DB_EXECUTOR.insertImmediate(archivedRecords); //Consider adding a insertImmediateAndDelete(Map<SOBJECT, SOBJECT>) with keys being the records to insert and values being the records to delete
        delete events;
    }

    private rflib_Application_Event_Archive__b convert(rflib_Application_Event__c evt) {
        return new rflib_Application_Event_Archive__b(
            Created_By_ID__c = evt.Created_By_ID__c,
            Occurred_On__c = evt.Occurred_On__c,
            Event_Name__c = evt.Event_Name__c,
            Related_Record_ID__c = String.isNotBlank(evt.Related_Record_ID__c) ? evt.Related_Record_ID__c : NO_RECORD_ID,
            Additional_Details__c = evt.Additional_Details__c
        );
    }

    public class ApplicationEventArchiveCleanupQueueable implements Queueable {

        private Date cleanupDate;

        public ApplicationEventArchiveCleanupQueueable(Date cleanupDate) {
            this.cleanupDate = cleanupDate;
        }

        public void execute(QueueableContext ctx) {
            try {
                List<SObject> recordsToDelete = QUERY_LOCATOR.getRecordsOlderThan(cleanupDate);
                DML_EXECUTOR.deleteImmediate(recordsToDelete);
    
                If (recordsToDelete.size() == QUERY_RECORD_LIMIT) {
                    System.enqueueJob(new ApplicationEventArchiveCleanupQueueable(cleanupDate));
                }
            } catch (Exception ex) {
                LOGGER.fatal('Failed to clean up Application Event Archive', ex);
            }
        }
    }
    
    public interface IBigObjectQueryLocator {
        List<SObject> getRecordsOlderThan(Datetime startDate);
    }

    public class DefaultLogArchiveQueryLocator implements IBigObjectQueryLocator {

        public List<SObject> getRecordsOlderThan(Datetime startDate) {
            return [
                SELECT Occurred_On__c, Event_Name__c, Created_By_ID__c, Related_Record_ID__c 
                FROM rflib_Application_Event_Archive__b
                WHERE Occurred_On__c > :startDate
                LIMIT :QUERY_RECORD_LIMIT
            ];
        }
    }
}