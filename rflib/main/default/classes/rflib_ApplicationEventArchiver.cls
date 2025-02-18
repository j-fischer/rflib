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

/**
 * @group Application Events
 * @description `Schedulable` to move records from the `rflib_Application_Event__c` object to the `rflib_Application_Event_Archive__b` Big Object archive.  
 *               The class should be scheduled upon installation if the use of application events is intended. Schedule can vary by org. 
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public inherited sharing class rflib_ApplicationEventArchiver implements Schedulable {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_ApplicationEventArchiver');

    @TestVisible
    private static Date TODAY = Date.today();

    @TestVisible
    private static rflib_ApplicationEventService APPLICATION_EVENT_SERVICE = new rflib_DefaultApplicationEventService();

    /**
     * @description Move records from the `rflib_Application_Event__c` object to the `rflib_Application_Event_Archive__b` Big Object archive.
     * @param  ctx ctx The `SchedulableContext`, which is not used.
     */
    public void execute(SchedulableContext ctx) {
        try {
            LOGGER.info('execute() invoked');
    
            Date threshold = TODAY.addDays(rflib_GlobalSettings.daysToRetainApplicationEventsOrDefault * (-1));
    
            List<rflib_Application_Event__c> applicationEvents = rflib_SOQL.of(rflib_Application_Event__c.SObjectType)
                .with(
                    rflib_Application_Event__c.Created_By_ID__c,
                    rflib_Application_Event__c.Occurred_On__c,
                    rflib_Application_Event__c.Event_Name__c,
                    rflib_Application_Event__c.Related_Record_ID__c,
                    rflib_Application_Event__c.Additional_Details__c
                )
                .whereAre(rflib_SOQL.Filter
                    .with(rflib_Application_Event__c.Occurred_On__c)
                    .lessThan(threshold))
                .setLimit(rflib_GlobalSettings.archiveAppEventQueryLimitOrDefault)
                .systemMode()
                .mockId('rflib_ApplicationEventArchiver.execute')
                .toList();
    
            APPLICATION_EVENT_SERVICE.archiveEvents(applicationEvents);
        } catch (Exception ex) {
            LOGGER.fatal('Failed to archive application events', ex);
        } 
    }
}