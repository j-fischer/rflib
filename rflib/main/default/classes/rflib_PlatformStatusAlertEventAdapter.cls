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
 * @description Reports `PlatformStatusAlertEvent` platform events as RFLIB log events. Salesforce
 *              publishes this event when one of its internal services raises an alert while processing
 *              a request, for example a Next Best Action strategy.
 *
 *              Like the flow execution error adapter, this one is invoked from a platform event
 *              triggered Flow. An Apex trigger on this event deploys, but nothing can exercise it from
 *              a test — Apex cannot insert the event and no test can make Salesforce publish one — so a
 *              trigger would ship permanently at zero coverage. The Flow carries no such requirement.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_PlatformStatusAlertEventAdapter {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_PlatformStatusAlertEventAdapter');

    private static final String CONTEXT = 'PlatformStatusAlertEvent';
    private static final String MESSAGE_PATTERN = '{0}/{1} raised a {2} alert: {3} (API error code {4})';

    static {
        // NOTE: See rflib_BatchApexErrorEventAdapter, reporting stays enabled so conversion failures
        //       remain visible; there is no recursion for it to cause.
        LOGGER.setSystemDebugLevel(rflib_LogLevel.DEBUG);
    }

    /**
     * @description Convert and report the given platform status alert events.
     *
     *              Every alert is reported. Unlike the other diagnostic events, this one carries a
     *              `StatusType` and Salesforce does not document its value set, so there is no reliable
     *              way to tell an informational status from a failure yet. Reporting everything is the
     *              safer default because the global setting allows an org to switch the source off
     *              entirely, whereas a wrong filter would silently drop real failures.
     *
     * @param events The events received by the platform event subscriber.
     */
    @InvocableMethod(label='Report Platform Status Alert Event' category='RFLIB' description='Report Platform Status Alert Events as RFLIB log events')
    public static void handle(List<PlatformStatusAlertEvent> events) {
        if (events == null || events.isEmpty()) {
            return;
        }

        if (!rflib_GlobalSettings.platformStatusAlertReportingEnabledOrDefault) {
            LOGGER.debug('Platform status alert reporting is disabled, skipping {0} event(s)', new Object[] { events.size() });
            return;
        }

        List<rflib_DiagnosticEvent> diagnostics = new List<rflib_DiagnosticEvent>();
        for (PlatformStatusAlertEvent evt : events) {
            try {
                diagnostics.add(convert(evt));
            } catch (Exception ex) {
                // NOTE: See rflib_BatchApexErrorEventAdapter, one unusable message must not cost the rest
                //       of the batch, and the publisher guards the publish itself.
                LOGGER.error('Failed to convert a platform status alert event, skipping it', ex);
            }
        }

        rflib_DiagnosticEventPublisher.publish(diagnostics);
    }

    private static rflib_DiagnosticEvent convert(PlatformStatusAlertEvent evt) {
        String message = String.format(
            MESSAGE_PATTERN,
            new Object[] { evt.ServiceName, evt.ComponentName, evt.StatusType, evt.Subject, evt.ApiErrorCode }
        );

        rflib_DiagnosticEvent diagnostic = new rflib_DiagnosticEvent(CONTEXT, evt.RequestId, message);
        diagnostic.attributes = new Map<String, Object> {
            'ServiceName' => evt.ServiceName,
            'ServiceJobId' => evt.ServiceJobId,
            'ComponentName' => evt.ComponentName,
            'SubComponentName' => evt.SubComponentName,
            'StatusType' => evt.StatusType,
            'ApiErrorCode' => evt.ApiErrorCode,
            'RelatedEventIdentifier' => evt.RelatedEventIdentifier,
            'UserId' => evt.UserId,
            'Username' => evt.Username,
            'EventDate' => evt.EventDate
        };

        return diagnostic;
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    private rflib_PlatformStatusAlertEventAdapter() { }
}
