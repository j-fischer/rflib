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
  * @group Application Event
  * @description Service interface for application events. 
  */
@SuppressWarnings('PMD.ClassNamingConventions')
public interface rflib_ApplicationEventService {

    /**
     * @description Archive rflib_Application_Event__c records to the corresponding Big Object. The records will also be deleted from the Custom Object. 
     * @param  events the records to be archived.
     */
    void archiveEvents(List<rflib_Application_Event__c> events);

    /**
     * @description Save an `rflib_Application_Event__c` record with the details provided in the parameters. All other fields are auto-calculated. 
     * @param  eventName         Name of the application event. 
     * @param  relatedRecordId   The ID of the record related to the event.
     * @param  additionalDetails Any relevant information associated with the event.
     */
    void publishApplicationEvent(String eventName, String relatedRecordId, String additionalDetails);

    /**
     * @description Save multiple `rflib_Application_Event__c` records with the details provided in the parameters. All other fields are auto-calculated. 
     * @param  applicationEvents List of `rflib_ApplicationEventDetails` to be created.
     */
    void publishApplicationEvents(List<rflib_ApplicationEventDetails> applicationEvents);
}
