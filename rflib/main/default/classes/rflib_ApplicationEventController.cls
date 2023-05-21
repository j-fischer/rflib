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
 * @description Controller to save `rflib_Application_Event__c` records originating from Lightning frontend components.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_ApplicationEventController {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('rflib_ApplicationEventController');

    @TestVisible
    private static rflib_ApplicationEventService APPLICATION_EVENT_SERVICE = new rflib_DefaultApplicationEventService();
    
    /**
     * @description Save an application event that occurred in the UI.
     * @param  eventName         Name of the event.
     * @param  relatedRecordId   The record ID the event is related to.
     * @param  additionalDetails Any relevant additional information part of the event. 
     */
     @AuraEnabled
    public static void saveApplicationEvent(String eventName, String relatedRecordId, String additionalDetails){
        try {
            LOGGER.info('saveApplicationEvent({0}, {1}, {2})', new Object[] { eventName, relatedRecordId, additionalDetails });

            APPLICATION_EVENT_SERVICE.saveApplicationEvent(eventName, relatedRecordId, additionalDetails);
        } catch (Exception ex) {
            LOGGER.error('Failed to save application event', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }

}