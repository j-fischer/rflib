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

/**
 * @group Logger
 * @description Reports `FlowExecutionErrorEvent` platform events as RFLIB log events. Salesforce
 *              publishes this event when a screen flow fails at runtime.
 *
 *              This event does not carry a Request ID. The interview GUID is reported in its place so
 *              that the log event's required correlation field is populated and the diagnostic can be
 *              traced back to the specific flow interview. It does not correlate to Apex log statements
 *              of the same transaction the way a real Request ID would.
 *
 *              Unlike the other diagnostic adapters, this one is invoked from a platform event triggered
 *              Flow rather than an Apex trigger. Salesforce rejects triggers on this event with
 *              "SObject type does not allow triggers", so the Flow is the only supported subscriber for
 *              a packaged subscription.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_FlowExecutionErrorEventAdapter {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_FlowExecutionErrorEventAdapter');

    private static final String CONTEXT = 'FlowExecutionErrorEvent';
    private static final String MESSAGE_PATTERN = 'Screen flow {0} failed at element {1}: {2}';

    static {
        LOGGER.setReportingLogLevel(rflib_LogLevel.NONE);
        LOGGER.setSystemDebugLevel(rflib_LogLevel.DEBUG);
    }

    /**
     * @description Convert and report the given flow execution error events.
     * @param events The events received by the platform event subscriber.
     */
    @InvocableMethod(label='Report Flow Execution Error Event' category='RFLIB' description='Report Flow Execution Error Events as RFLIB log events')
    public static void handle(List<FlowExecutionErrorEvent> events) {
        if (!rflib_GlobalSettings.flowExecutionErrorReportingEnabledOrDefault) {
            LOGGER.debug('Flow execution error reporting is disabled, skipping {0} event(s)', new Object[] { events.size() });
            return;
        }

        try {
            List<rflib_DiagnosticEvent> diagnostics = new List<rflib_DiagnosticEvent>();
            for (FlowExecutionErrorEvent evt : events) {
                diagnostics.add(convert(evt));
            }

            rflib_DiagnosticEventPublisher.publish(diagnostics);
        } catch (Exception ex) {
            // NOTE: See rflib_BatchApexErrorEventAdapter, exceptions are swallowed to keep the subscriber
            //       out of an error state that would stall the whole channel.
            LOGGER.error('Failed to report flow execution error events', ex);
        }
    }

    private static rflib_DiagnosticEvent convert(FlowExecutionErrorEvent evt) {
        String message = String.format(
            MESSAGE_PATTERN,
            new Object[] { evt.FlowApiName, evt.ElementApiName, evt.ErrorMessage }
        );

        rflib_DiagnosticEvent diagnostic = new rflib_DiagnosticEvent(CONTEXT, evt.InterviewGuid, message);
        diagnostic.attributes = new Map<String, Object> {
            'FlowApiName' => evt.FlowApiName,
            'FlowVersionId' => evt.FlowVersionId,
            'ElementApiName' => evt.ElementApiName,
            'InterviewGuid' => evt.InterviewGuid,
            'InterviewStartDate' => evt.InterviewStartDate,
            'InterviewStartedById' => evt.InterviewStartedById,
            'EventDate' => evt.EventDate
        };

        return diagnostic;
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    private rflib_FlowExecutionErrorEventAdapter() { }
}
