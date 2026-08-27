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
private class rflib_PlatformStatusAlertAdapterTest {

    private static final String SETTING_NAME = 'Diagnostic_Event_Platform_Status_Alert_Reporting_Enabled';

    @isTest
    public static void testReportsPlatformStatusAlert() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_PlatformStatusAlertEventAdapter.handle(new List<PlatformStatusAlertEvent> { createEvent('Error') });
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());

        rflib_Log_Event__e evt = (rflib_Log_Event__e) publisher.capturedPlatformEvent;
        System.assertEquals('FATAL', evt.Log_Level__c);
        System.assertEquals('Platform', evt.Log_Source__c);
        System.assertEquals('PlatformStatusAlertEvent', evt.Context__c);
        System.assertEquals('REQ-9', evt.Request_ID__c);
        System.assertEquals(null, evt.Stacktrace__c, 'this event does not provide a stacktrace');

        System.assert(
            evt.Log_Messages__c.contains('NextBestAction/Strategy raised a Error alert'),
            'expected the service and component in the message, but was: ' + evt.Log_Messages__c
        );
        System.assert(evt.Log_Messages__c.contains('Invalid formula expression'), 'expected the subject in the message');
        System.assert(evt.Log_Messages__c.contains('INVALID_FORMULA'), 'expected the API error code in the message');

        System.assert(evt.Platform_Info__c.contains('"StatusType":"Error"'), 'expected the status type as a telemetry attribute');
        System.assert(evt.Platform_Info__c.contains('"ServiceName":"NextBestAction"'), 'expected the service name as a telemetry attribute');
    }

    @isTest
    public static void testReportsAlertsOfAnyStatusType() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        // The StatusType value set is not documented by Salesforce, so every alert is reported until the
        // real values are known. Under-reporting a diagnostic is worse than over-reporting one.
        rflib_PlatformStatusAlertEventAdapter.handle(new List<PlatformStatusAlertEvent> { createEvent('Information') });
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());
    }

    @isTest
    public static void testDoesNotReportWhenDisabled() {
        rflib_GlobalSettings.SETTINGS.put(SETTING_NAME, 'false');
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_PlatformStatusAlertEventAdapter.handle(new List<PlatformStatusAlertEvent> { createEvent('Error') });
        Test.stopTest();

        System.assertEquals(0, publisher.getPublishingCounter());
    }

    @isTest
    public static void testReportsAllEventsOfABatch() {
        rflib_MockEventPublisher publisher = setupPublisher();

        List<PlatformStatusAlertEvent> events = new List<PlatformStatusAlertEvent>();
        for (Integer i = 0; i < 50; i++) {
            events.add(createEvent('Error'));
        }

        Test.startTest();
        rflib_PlatformStatusAlertEventAdapter.handle(events);
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());
        System.assertEquals(50, publisher.capturedPlatformEvents.size());
    }

    @isTest
    public static void testSwallowsConversionFailures() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_PlatformStatusAlertEventAdapter.handle(new List<PlatformStatusAlertEvent> { null });
        Test.stopTest();

        System.assertEquals(0, publisher.getPublishingCounter());
    }

    @isTest
    public static void testUnconvertibleEventDoesNotDiscardTheBatch() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_PlatformStatusAlertEventAdapter.handle(
            new List<PlatformStatusAlertEvent> { createEvent('Error'), null, createEvent('Error') }
        );
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());
        System.assertEquals(
            2,
            publisher.capturedPlatformEvents.size(),
            'the events that could be converted must still be reported'
        );
    }

    @isTest
    public static void testIgnoresNullInputWhenReportingIsDisabled() {
        // handle() is invocable, so any Flow can pass an uninitialized collection to it. The null check
        // has to run before anything dereferences the list, including the disabled-path logging.
        rflib_GlobalSettings.SETTINGS.put(SETTING_NAME, 'false');
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_PlatformStatusAlertEventAdapter.handle(null);
        Test.stopTest();

        System.assertEquals(0, publisher.getPublishingCounter());
    }

    private static rflib_MockEventPublisher setupPublisher() {
        rflib_MockEventPublisher publisher = new rflib_MockEventPublisher();
        rflib_DiagnosticEventPublisher.EVENT_PUBLISHER = publisher;
        return publisher;
    }

    private static PlatformStatusAlertEvent createEvent(String statusType) {
        // Standard platform event fields are not writeable, so the event has to be built from JSON.
        return (PlatformStatusAlertEvent) JSON.deserialize(
            '{' +
                '"ServiceName":"NextBestAction",' +
                '"ServiceJobId":"job-1",' +
                '"ComponentName":"Strategy",' +
                '"SubComponentName":"Recommendation",' +
                '"StatusType":"' + statusType + '",' +
                '"Subject":"Invalid formula expression",' +
                '"ApiErrorCode":"INVALID_FORMULA",' +
                '"RequestId":"REQ-9",' +
                '"Username":"user@example.com"' +
            '}',
            PlatformStatusAlertEvent.class
        );
    }
}
