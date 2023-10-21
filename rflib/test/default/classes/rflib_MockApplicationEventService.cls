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
public class rflib_MockApplicationEventService implements rflib_ApplicationEventService {
    
    public String capturedEventName { get; private set; }
    public String capturedRelatedRecordId { get; private set; }
    public String capturedAdditionalDetails { get; private set; }
    
    public List<rflib_Application_Event__c> capturedEvents { get; private set; }
    public List<rflib_ApplicationEventDetails> capturedEventDetails { get; private set; }
    
    private Exception exceptionToThrow;

    public rflib_MockApplicationEventService() {
        this(null);
    }

    public rflib_MockApplicationEventService(
        Exception exceptionToThrow
    ) {
        this.exceptionToThrow = exceptionToThrow;
    }

    public void archiveEvents(List<rflib_Application_Event__c> events) {
        this.capturedEvents = events;

        if (exceptionToThrow != null) {
            throw exceptionToThrow;
        }
    }

    public void publishApplicationEvent(String eventName, String relatedRecordId, String additionalDetails) {
        this.capturedEventName = eventName;
        this.capturedRelatedRecordId = relatedRecordId;
        this.capturedAdditionalDetails = additionalDetails;

        if (exceptionToThrow != null) {
            throw exceptionToThrow;
        }
    }

    public void publishApplicationEvents(List<rflib_ApplicationEventDetails> applicationEvents) {
        this.capturedEventDetails = applicationEvents;

        if (exceptionToThrow != null) {
            throw exceptionToThrow;
        }
    }
}