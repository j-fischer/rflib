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
private class rflib_BatchApexErrorEventAdapterTest {

    private static final String SETTING_NAME = 'Diagnostic_Event_Batch_Apex_Error_Reporting_Enabled';

    @isTest
    public static void testReportsBatchApexError() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_BatchApexErrorEventAdapter.handle(new List<BatchApexErrorEvent> { createEvent(false) });
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());

        rflib_Log_Event__e evt = (rflib_Log_Event__e) publisher.capturedPlatformEvent;
        System.assertEquals('FATAL', evt.Log_Level__c);
        System.assertEquals('Platform', evt.Log_Source__c);
        System.assertEquals('BatchApexErrorEvent', evt.Context__c);
        System.assertEquals('REQ-1', evt.Request_ID__c);
        System.assertEquals('Class.Foo.execute: line 10, column 1', evt.Stacktrace__c);

        System.assert(
            evt.Log_Messages__c.contains('Batch Apex job 707000000000001AAA failed during the EXECUTE phase'),
            'expected the job ID and phase in the message, but was: ' + evt.Log_Messages__c
        );
        System.assert(evt.Log_Messages__c.contains('System.NullPointerException'), 'expected the exception type in the message');
        System.assert(evt.Log_Messages__c.contains('Job Scope: 001000000000001,001000000000002'), 'expected the job scope in the message');

        System.assert(evt.Platform_Info__c.contains('"Phase":"EXECUTE"'), 'expected the phase as a telemetry attribute');
        System.assert(evt.Platform_Info__c.contains('"AsyncApexJobId":"707000000000001AAA"'), 'expected the job ID as a telemetry attribute');
    }

    @isTest
    public static void testMarksTruncatedJobScope() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_BatchApexErrorEventAdapter.handle(new List<BatchApexErrorEvent> { createEvent(true) });
        Test.stopTest();

        rflib_Log_Event__e evt = (rflib_Log_Event__e) publisher.capturedPlatformEvent;
        System.assert(
            evt.Log_Messages__c.contains('Job Scope (truncated):'),
            'expected the truncation marker, but was: ' + evt.Log_Messages__c
        );
    }

    @isTest
    public static void testDoesNotReportWhenDisabled() {
        rflib_GlobalSettings.SETTINGS.put(SETTING_NAME, 'false');
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_BatchApexErrorEventAdapter.handle(new List<BatchApexErrorEvent> { createEvent(false) });
        Test.stopTest();

        System.assertEquals(0, publisher.getPublishingCounter());
    }

    @isTest
    public static void testReportsAllEventsOfABatch() {
        rflib_MockEventPublisher publisher = setupPublisher();

        List<BatchApexErrorEvent> events = new List<BatchApexErrorEvent>();
        for (Integer i = 0; i < 50; i++) {
            events.add(createEvent(false));
        }

        Test.startTest();
        rflib_BatchApexErrorEventAdapter.handle(events);
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter(), 'the whole subscriber batch must be published in one call');
        System.assertEquals(50, publisher.capturedPlatformEvents.size());
    }

    @isTest
    public static void testSwallowsConversionFailures() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        // A null entry makes the conversion fail. The adapter must not let the exception escape, because
        // an uncaught exception would put the platform event subscriber into an error state.
        rflib_BatchApexErrorEventAdapter.handle(new List<BatchApexErrorEvent> { null });
        Test.stopTest();

        System.assertEquals(0, publisher.getPublishingCounter());
    }

    @isTest
    public static void testTriggerSubscribesToTheEvent() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        // Salesforce is the only publisher of BatchApexErrorEvent, so the subscription can only be
        // exercised by making a batch that opted into Database.RaisesPlatformEvents fail for real.
        Database.executeBatch(new rflib_MockFailingBatch());
        try {
            // The batch runs synchronously here and its exception surfaces to the test rather than
            // being absorbed by the platform, so it has to be caught for the run to continue.
            Test.stopTest();
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(rflib_MockFailingBatch.FAILURE_MESSAGE), 'unexpected failure: ' + ex);
        }

        Test.getEventBus().deliver();

        System.assertEquals(1, publisher.getPublishingCounter(), 'the trigger must report the batch failure');

        rflib_Log_Event__e evt = (rflib_Log_Event__e) publisher.capturedPlatformEvent;
        System.assertEquals('BatchApexErrorEvent', evt.Context__c);
        System.assertEquals('FATAL', evt.Log_Level__c);
        System.assert(
            evt.Log_Messages__c.contains(rflib_MockFailingBatch.FAILURE_MESSAGE),
            'expected the batch exception message, but was: ' + evt.Log_Messages__c
        );
    }

    private static rflib_MockEventPublisher setupPublisher() {
        rflib_MockEventPublisher publisher = new rflib_MockEventPublisher();
        rflib_DiagnosticEventPublisher.EVENT_PUBLISHER = publisher;
        return publisher;
    }

    private static BatchApexErrorEvent createEvent(Boolean isJobScopeTruncated) {
        // Standard platform event fields are not writeable, so the event has to be built from JSON.
        return (BatchApexErrorEvent) JSON.deserialize(
            '{' +
                '"AsyncApexJobId":"707000000000001AAA",' +
                '"Phase":"EXECUTE",' +
                '"ExceptionType":"System.NullPointerException",' +
                '"Message":"Attempt to de-reference a null object",' +
                '"StackTrace":"Class.Foo.execute: line 10, column 1",' +
                '"JobScope":"001000000000001,001000000000002",' +
                '"DoesExceedJobScopeMaxLength":' + isJobScopeTruncated + ',' +
                '"RequestId":"REQ-1"' +
            '}',
            BatchApexErrorEvent.class
        );
    }
}
