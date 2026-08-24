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
 * @description Reports `BatchApexErrorEvent` platform events as RFLIB log events. Salesforce publishes
 *              this event when a batch class that declares `Database.RaisesPlatformEvents` fails with
 *              an unhandled exception.
 *
 *              Note that Salesforce only publishes the event for batch classes that opt in through that
 *              interface, so existing batch jobs are not captured until they declare it.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_BatchApexErrorEventAdapter {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_BatchApexErrorEventAdapter');

    private static final String CONTEXT = 'BatchApexErrorEvent';
    private static final String MESSAGE_PATTERN = 'Batch Apex job {0} failed during the {1} phase: {2}: {3}';
    private static final String JOB_SCOPE_PATTERN = '\nJob Scope: {0}';
    private static final String TRUNCATED_JOB_SCOPE_PATTERN = '\nJob Scope (truncated): {0}';

    static {
        LOGGER.setReportingLogLevel(rflib_LogLevel.NONE);
        LOGGER.setSystemDebugLevel(rflib_LogLevel.DEBUG);
    }

    /**
     * @description Convert and report the given batch Apex error events.
     * @param events The events received by the platform event subscriber.
     */
    public static void handle(List<BatchApexErrorEvent> events) {
        if (!rflib_GlobalSettings.batchApexErrorReportingEnabledOrDefault) {
            LOGGER.debug('Batch Apex error reporting is disabled, skipping {0} event(s)', new Object[] { events.size() });
            return;
        }

        try {
            List<rflib_DiagnosticEvent> diagnostics = new List<rflib_DiagnosticEvent>();
            for (BatchApexErrorEvent evt : events) {
                diagnostics.add(convert(evt));
            }

            rflib_DiagnosticEventPublisher.publish(diagnostics);
        } catch (Exception ex) {
            // NOTE: Exceptions are swallowed on purpose. An uncaught exception would leave the subscriber
            //       in an error state and stall the entire channel, which loses far more diagnostics than
            //       the single batch that failed to convert.
            LOGGER.error('Failed to report Batch Apex error events', ex);
        }
    }

    private static rflib_DiagnosticEvent convert(BatchApexErrorEvent evt) {
        String summary = String.format(
            MESSAGE_PATTERN,
            new Object[] { evt.AsyncApexJobId, evt.Phase, evt.ExceptionType, evt.Message }
        );

        String message = String.isBlank(evt.JobScope) ? summary : summary + formatJobScope(evt);

        rflib_DiagnosticEvent diagnostic = new rflib_DiagnosticEvent(CONTEXT, evt.RequestId, message);
        diagnostic.stacktrace = evt.StackTrace;
        diagnostic.attributes = new Map<String, Object> {
            'AsyncApexJobId' => evt.AsyncApexJobId,
            'Phase' => evt.Phase,
            'ExceptionType' => evt.ExceptionType,
            'DoesExceedJobScopeMaxLength' => evt.DoesExceedJobScopeMaxLength,
            'EventUuid' => evt.EventUuid,
            'ReplayId' => evt.ReplayId
        };

        return diagnostic;
    }

    private static String formatJobScope(BatchApexErrorEvent evt) {
        String pattern = evt.DoesExceedJobScopeMaxLength == true ? TRUNCATED_JOB_SCOPE_PATTERN : JOB_SCOPE_PATTERN;
        return String.format(pattern, new Object[] { evt.JobScope });
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    private rflib_BatchApexErrorEventAdapter() { }
}
