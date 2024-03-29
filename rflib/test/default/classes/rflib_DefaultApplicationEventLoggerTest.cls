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
private class rflib_DefaultApplicationEventLoggerTest {
    
    private static final String EVENT_NAME = 'some-event';
    private static final String RELATED_RECORD_ID = 'record-id';
    private static final String ADDITIONAL_DETAILS = 'additional-details';

    @IsTest
    private static void testLogApplicationEvent_Success() {
        rflib_MockApplicationEventService service = new rflib_MockApplicationEventService();
        
        rflib_DefaultApplicationEventLogger.APPLICATION_EVENT_SERVICE = service;

        Test.startTest();
        new rflib_DefaultApplicationEventLogger().logApplicationEvent(EVENT_NAME, RELATED_RECORD_ID, ADDITIONAL_DETAILS);
        Test.stopTest();

        Assert.areEqual(EVENT_NAME, service.capturedEventName);
        Assert.areEqual(RELATED_RECORD_ID, service.capturedRelatedRecordId);
        Assert.areEqual(ADDITIONAL_DETAILS, service.capturedAdditionalDetails);
    }

    @IsTest
    private static void testLogSaveApplicationEvent_Failure() {
        rflib_MockApplicationEventService service = new rflib_MockApplicationEventService(new ApplicationEventControllerException('foo bar'));
        
        rflib_DefaultApplicationEventLogger.APPLICATION_EVENT_SERVICE = service;

        Test.startTest();
        try{
            new rflib_DefaultApplicationEventLogger().logApplicationEvent(EVENT_NAME, RELATED_RECORD_ID, ADDITIONAL_DETAILS);
            Assert.fail('Expected exception has not been thrown');
        } catch (ApplicationEventControllerException ex) {
            Assert.areEqual('foo bar', ex.getMessage());
        }
        Test.stopTest();

        Assert.areEqual(EVENT_NAME, service.capturedEventName);
        Assert.areEqual(RELATED_RECORD_ID, service.capturedRelatedRecordId);
        Assert.areEqual(ADDITIONAL_DETAILS, service.capturedAdditionalDetails);
    }

    @IsTest
    private static void testLogApplicationEvents_Success() {
        rflib_MockApplicationEventService service = new rflib_MockApplicationEventService();
        
        rflib_DefaultApplicationEventLogger.APPLICATION_EVENT_SERVICE = service;

        Test.startTest();
        new rflib_DefaultApplicationEventLogger().logApplicationEvents(createDetails());
        Test.stopTest();

        Assert.areEqual(EVENT_NAME, service.capturedEventDetails[0].eventName);
        Assert.areEqual(RELATED_RECORD_ID, service.capturedEventDetails[0].relatedRecordId);
        Assert.areEqual(ADDITIONAL_DETAILS, service.capturedEventDetails[0].additionalDetails);
    }

    @IsTest
    private static void testLogSaveApplicationEvents_Failure() {
        rflib_MockApplicationEventService service = new rflib_MockApplicationEventService(new ApplicationEventControllerException('foo bar'));
        
        rflib_DefaultApplicationEventLogger.APPLICATION_EVENT_SERVICE = service;

        Test.startTest();
        try{
            new rflib_DefaultApplicationEventLogger().logApplicationEvents(createDetails());
            Assert.fail('Expected exception has not been thrown');
        } catch (ApplicationEventControllerException ex) {
            Assert.areEqual('foo bar', ex.getMessage());
        }
        Test.stopTest();

        Assert.areEqual(EVENT_NAME, service.capturedEventDetails[0].eventName);
        Assert.areEqual(RELATED_RECORD_ID, service.capturedEventDetails[0].relatedRecordId);
        Assert.areEqual(ADDITIONAL_DETAILS, service.capturedEventDetails[0].additionalDetails);
    }

    private static List<rflib_ApplicationEventDetails> createDetails() {
        return new List<rflib_ApplicationEventDetails> {
            new rflib_ApplicationEventDetails(EVENT_NAME, RELATED_RECORD_ID, ADDITIONAL_DETAILS)
        };
    }

    public class ApplicationEventControllerException extends Exception { }
}