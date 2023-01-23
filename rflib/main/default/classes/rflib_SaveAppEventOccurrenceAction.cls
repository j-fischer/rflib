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
public with sharing class rflib_SaveAppEventOccurrenceAction {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('rflib_SaveAppEventOccurrenceAction');
    
    @TestVisible
    private static rflib_ApplicationEventService APPLICATION_EVENT_SERVICE  = new rflib_DefaultApplicationEventService();

    // Need to use an Apex Action because of this missing feature for Long Text fields: https://ideas.salesforce.com/s/idea/a0B8W00000J8A6cUAF/long-text-areas-in-flow
    @InvocableMethod(label='Save Application Event' category='RFLIB' description='Saves an Application Event Occurrence to the Application Event Custom Object')
    public static void saveApplicationEvent(List<rflib_Application_Event_Occurred_Event__e> events) {
        try {
            LOGGER.info('saveApplicationEvent(): events=' + events);
            
            List<rflib_Application_Event__c> eventsToSave = new List<rflib_Application_Event__c>();
            for (rflib_Application_Event_Occurred_Event__e ev : events) {
                eventsToSave.add(convert(ev));
            } 
        
            LOGGER.info('Inserting events; ' + eventsToSave);
            insert events;
        } catch (Exception ex) {
            LOGGER.error('Failed to insert application events', ex);
        }
    }

    private static rflib_Application_Event__c convert(rflib_Application_Event_Occurred_Event__e evt) {
        return new rflib_Application_Event__c(
            Created_By_ID__c = evt.Created_By_ID__c,
            Occurred_On__c = evt.Occurred_On__c,
            Event_Name__c = evt.Event_Name__c,
            Related_Record_ID__c = evt.Related_Record_ID__c,
            Additional_Details__c = evt.Additional_Details__c
        );
    }

}