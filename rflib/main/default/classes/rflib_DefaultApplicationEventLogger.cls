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
public inherited sharing class rflib_DefaultApplicationEventLogger implements rflib_ApplicationEventLogger {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_DefaultApplicationEventLogger');

    @TestVisible
    private static rflib_ApplicationEventService APPLICATION_EVENT_SERVICE = new rflib_DefaultApplicationEventService();
    
    public void logApplicationEvent(String eventName, String relatedRecordId, String additionalDetails){
        try {
            LOGGER.debug('logApplicationEvent({0}, {1}, {2})', new Object[] { eventName, relatedRecordId, additionalDetails });

            APPLICATION_EVENT_SERVICE.publishApplicationEvent(eventName, relatedRecordId, additionalDetails);
        } catch (Exception ex) {
            LOGGER.error('Failed to log save application event', ex);
            throw ex;
        }
    }

    public void logApplicationEvents(List<rflib_ApplicationEventDetails> applicationEvents){
        try {
            LOGGER.debug('logApplicationEvent({0})', new Object[] { applicationEvents });

            APPLICATION_EVENT_SERVICE.publishApplicationEvents(applicationEvents);
        } catch (Exception ex) {
            LOGGER.error('Failed to log save application events', ex);
            throw ex;
        }
    }
}