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
public with sharing class rflib_ApplicationEventLoggerAction {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('rflib_ApplicationEventLoggerAction');

    @TestVisible
    private static rflib_ApplicationEventLogger APPLICATION_EVENT_LOGGER = rflib_LoggerUtil.getApplicationEventLogger();

    @InvocableMethod(label='Log Application Event' category='RFLIB' description='Log an Application Event' iconName='resource:rflib_AppEventLoggerActionIcon:icon')
    public static void logApplicationEvent(List<ApplicationEventInfo> applicationEvents) {
        LOGGER.info('Recording Application Events: ' + applicationEvents);
        for (ApplicationEventInfo event : applicationEvents) {   
            APPLICATION_EVENT_LOGGER.logApplicationEvent(event.eventName, event.relatedRecordId, event.additionalDetails);
        }
    }

    public class ApplicationEventInfo {
        @InvocableVariable(label='Event Name' description='The name of the Application Event' required=true)
        public String eventName;
        
        @InvocableVariable(label='Related Record ID' description='The ID of the record associated with the Application Event' required=false)
        public String relatedRecordId;
        
        @InvocableVariable(label='Additional Details' description='Additional Details associated with the event. Can be in any format' required=false)
        public String additionalDetails;
    }

}