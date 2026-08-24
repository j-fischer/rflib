/*
 * Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
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
private class rflib_FlowExecutionErrorEventAdapterTest {

    private static final String SETTING_NAME = 'Diagnostic_Event_Flow_Execution_Error_Reporting_Enabled';

    @isTest
    public static void testReportsFlowExecutionError() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_FlowExecutionErrorEventAdapter.handle(new List<FlowExecutionErrorEvent> { createEvent() });
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());

        rflib_Log_Event__e evt = (rflib_Log_Event__e) publisher.capturedPlatformEvent;
        System.assertEquals('FATAL', evt.Log_Level__c);
        System.assertEquals('Platform', evt.Log_Source__c);
        System.assertEquals('FlowExecutionErrorEvent', evt.Context__c);
        System.assertEquals(null, evt.Stacktrace__c, 'this event does not provide a stacktrace');

        System.assertEquals(
            'a1b2c3d4-0000-0000-0000-000000000001',
            evt.Request_ID__c,
            'the interview GUID stands in for the missing Request ID'
        );

        System.assert(
            evt.Log_Messages__c.contains('Screen flow My_Screen_Flow failed at element Screen_1'),
            'expected the flow and element name in the message, but was: ' + evt.Log_Messages__c
        );
        System.assert(evt.Log_Messages__c.contains('The record could not be saved'), 'expected the error message');

        System.assert(evt.Platform_Info__c.contains('"FlowApiName":"My_Screen_Flow"'), 'expected the flow name as a telemetry attribute');
        System.assert(evt.Platform_Info__c.contains('"ElementApiName":"Screen_1"'), 'expected the element name as a telemetry attribute');
    }

    @isTest
    public static void testDoesNotReportWhenDisabled() {
        rflib_GlobalSettings.SETTINGS.put(SETTING_NAME, 'false');
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_FlowExecutionErrorEventAdapter.handle(new List<FlowExecutionErrorEvent> { createEvent() });
        Test.stopTest();

        System.assertEquals(0, publisher.getPublishingCounter());
    }

    @isTest
    public static void testReportsAllEventsOfABatch() {
        rflib_MockEventPublisher publisher = setupPublisher();

        List<FlowExecutionErrorEvent> events = new List<FlowExecutionErrorEvent>();
        for (Integer i = 0; i < 50; i++) {
            events.add(createEvent());
        }

        Test.startTest();
        rflib_FlowExecutionErrorEventAdapter.handle(events);
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());
        System.assertEquals(50, publisher.capturedPlatformEvents.size());
    }

    @isTest
    public static void testSwallowsConversionFailures() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_FlowExecutionErrorEventAdapter.handle(new List<FlowExecutionErrorEvent> { null });
        Test.stopTest();

        System.assertEquals(0, publisher.getPublishingCounter());
    }

    private static rflib_MockEventPublisher setupPublisher() {
        rflib_MockEventPublisher publisher = new rflib_MockEventPublisher();
        rflib_DiagnosticEventPublisher.EVENT_PUBLISHER = publisher;
        return publisher;
    }

    private static FlowExecutionErrorEvent createEvent() {
        // Standard platform event fields are not writeable, so the event has to be built from JSON.
        return (FlowExecutionErrorEvent) JSON.deserialize(
            '{' +
                '"FlowApiName":"My_Screen_Flow",' +
                '"FlowVersionId":"301000000000001AAA",' +
                '"ElementApiName":"Screen_1",' +
                '"ErrorMessage":"The record could not be saved",' +
                '"InterviewGuid":"a1b2c3d4-0000-0000-0000-000000000001",' +
                '"InterviewStartedById":"005000000000001AAA"' +
            '}',
            FlowExecutionErrorEvent.class
        );
    }
}
