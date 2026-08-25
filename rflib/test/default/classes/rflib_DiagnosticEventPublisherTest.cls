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
private class rflib_DiagnosticEventPublisherTest {

    @isTest
    public static void testPublishesFatalLogEvent() {
        rflib_MockEventPublisher publisher = setupPublisher();

        rflib_DiagnosticEvent diagnostic = new rflib_DiagnosticEvent('BatchApexErrorEvent', 'REQ-123', 'Something failed');
        diagnostic.stacktrace = 'Class.Foo.bar: line 1, column 1';
        diagnostic.attributes = new Map<String, Object> { 'Phase' => 'EXECUTE' };

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent> { diagnostic });
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());
        System.assertEquals(1, publisher.capturedPlatformEvents.size());

        rflib_Log_Event__e evt = (rflib_Log_Event__e) publisher.capturedPlatformEvent;
        System.assertEquals('FATAL', evt.Log_Level__c, 'diagnostics are always reported at FATAL');
        System.assertEquals('Platform', evt.Log_Source__c);
        System.assertEquals('BatchApexErrorEvent', evt.Context__c);
        System.assertEquals('REQ-123', evt.Request_ID__c);
        System.assertEquals('Something failed', evt.Log_Messages__c);
        System.assertEquals('Class.Foo.bar: line 1, column 1', evt.Stacktrace__c);
        System.assertEquals(UserInfo.getOrganizationId(), evt.Source_System_ID__c);
        System.assertEquals('{"Phase":"EXECUTE"}', evt.Platform_Info__c);
    }

    @isTest
    public static void testIgnoresEmptyAndNullInput() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(null);
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent>());
        Test.stopTest();

        System.assertEquals(0, publisher.getPublishingCounter());
        System.assertEquals(null, publisher.capturedPlatformEvents);
    }

    @isTest
    public static void testPublishesAllEventsInSingleCall() {
        rflib_MockEventPublisher publisher = setupPublisher();

        List<rflib_DiagnosticEvent> diagnostics = new List<rflib_DiagnosticEvent>();
        for (Integer i = 0; i < 200; i++) {
            diagnostics.add(new rflib_DiagnosticEvent('BatchApexErrorEvent', 'REQ-' + i, 'Failure ' + i));
        }

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(diagnostics);
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter(), 'a subscriber batch must result in a single publish call');
        System.assertEquals(200, publisher.capturedPlatformEvents.size());
    }

    @isTest
    public static void testUsesFallbackForBlankRequestId() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent> {
            new rflib_DiagnosticEvent('FlowExecutionErrorEvent', null, 'Something failed')
        });
        Test.stopTest();

        rflib_Log_Event__e evt = (rflib_Log_Event__e) publisher.capturedPlatformEvent;
        System.assertEquals('NULL', evt.Request_ID__c, 'Request_ID__c is required and needs a fallback value');
    }

    @isTest
    public static void testTruncatesContextToFieldLength() {
        rflib_MockEventPublisher publisher = setupPublisher();

        String longContext = 'C'.repeat(60);

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent> {
            new rflib_DiagnosticEvent(longContext, 'R'.repeat(60), 'Something failed')
        });
        Test.stopTest();

        rflib_Log_Event__e evt = (rflib_Log_Event__e) publisher.capturedPlatformEvent;
        System.assertEquals(40, evt.Context__c.length());
        System.assertEquals(40, evt.Request_ID__c.length());
    }

    @isTest
    public static void testOmitsPlatformInfoWhenNoAttributesArePopulated() {
        rflib_MockEventPublisher publisher = setupPublisher();

        rflib_DiagnosticEvent withoutAttributes = new rflib_DiagnosticEvent('BatchApexErrorEvent', 'REQ-1', 'Failed');
        rflib_DiagnosticEvent withNullAttributes = new rflib_DiagnosticEvent('BatchApexErrorEvent', 'REQ-2', 'Failed');
        withNullAttributes.attributes = new Map<String, Object> { 'Phase' => null, 'ExceptionType' => null };

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent> { withoutAttributes, withNullAttributes });
        Test.stopTest();

        System.assertEquals(null, ((rflib_Log_Event__e) publisher.capturedPlatformEvents[0]).Platform_Info__c);
        System.assertEquals(
            null,
            ((rflib_Log_Event__e) publisher.capturedPlatformEvents[1]).Platform_Info__c,
            'attributes without a value must not produce empty telemetry entries'
        );
    }

    @isTest
    public static void testOmitsStacktraceWhenNotProvided() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent> {
            new rflib_DiagnosticEvent('PlatformStatusAlertEvent', 'REQ-1', 'Failed')
        });
        Test.stopTest();

        System.assertEquals(null, ((rflib_Log_Event__e) publisher.capturedPlatformEvent).Stacktrace__c);
    }

    @isTest
    public static void testPublishesWhenMaskingIsEnabled() {
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Enable_Log_Masking__c = true;
        upsert settings;

        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent> {
            new rflib_DiagnosticEvent('BatchApexErrorEvent', 'REQ-1', 'Something failed')
        });
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());
        System.assertNotEquals(null, ((rflib_Log_Event__e) publisher.capturedPlatformEvent).Log_Messages__c);
    }

    @isTest
    public static void testSkipsDiagnosticsThatCannotBeBuilt() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent> {
            new rflib_DiagnosticEvent('BatchApexErrorEvent', 'REQ-1', 'Failed'),
            null,
            new rflib_DiagnosticEvent('BatchApexErrorEvent', 'REQ-2', 'Failed')
        });
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter());
        System.assertEquals(
            2,
            publisher.capturedPlatformEvents.size(),
            'the diagnostics that could be built must still be published'
        );
    }

    @isTest
    public static void testDoesNotPublishWhenNoDiagnosticCouldBeBuilt() {
        rflib_MockEventPublisher publisher = setupPublisher();

        Test.startTest();
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent> { null });
        Test.stopTest();

        System.assertEquals(0, publisher.getPublishingCounter());
    }

    @isTest
    public static void testDoesNotPropagatePublishFailures() {
        rflib_ThrowingEventPublisher publisher = new rflib_ThrowingEventPublisher();
        rflib_DiagnosticEventPublisher.EVENT_PUBLISHER = publisher;

        Test.startTest();
        // An exception escaping here would leave the platform event subscriber in an error state and
        // stall the channel for every event that follows, so the publisher has to absorb it.
        rflib_DiagnosticEventPublisher.publish(new List<rflib_DiagnosticEvent> {
            new rflib_DiagnosticEvent('BatchApexErrorEvent', 'REQ-1', 'Failed')
        });
        Test.stopTest();

        System.assertEquals(1, publisher.getPublishingCounter(), 'the publish must have been attempted');
    }

    private static rflib_MockEventPublisher setupPublisher() {
        rflib_MockEventPublisher publisher = new rflib_MockEventPublisher();
        rflib_DiagnosticEventPublisher.EVENT_PUBLISHER = publisher;
        return publisher;
    }

    /**
     * An event publisher that always fails, used to prove the diagnostic publisher absorbs the failure.
     */
    private class rflib_ThrowingEventPublisher implements rflib_EventPublisher {
        private Integer attempts = 0;

        public Integer getPublishingCounter() {
            return attempts;
        }

        public Database.SaveResult publish(SObject event) {
            attempts++;
            throw new rflib_InvalidStateException('Simulated publish failure');
        }

        public List<Database.SaveResult> publish(List<SObject> events) {
            attempts++;
            throw new rflib_InvalidStateException('Simulated publish failure');
        }
    }
}
