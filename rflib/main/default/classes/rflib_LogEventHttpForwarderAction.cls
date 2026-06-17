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
 * @description Abstract base for Invocable Actions that forward RFLIB Log Events in bulk to an
 *              external HTTP log destination (AWS CloudWatch, Azure Application Insights, an
 *              OpenTelemetry collector, ...). It owns the shared algorithm — log level matching,
 *              optional batching into multiple callouts, the HTTP POST via rflib_HttpRequest, and
 *              failure handling — while each concrete forwarder supplies its endpoint, configuration
 *              accessors, success criteria and destination-specific payload through the hooks below.
 *
 *              This base intentionally differs from rflib_LogEventNotificationAction: log forwarding
 *              ships ALL configured levels (including DEBUG/TRACE) in batched callouts with no
 *              per-invocation cap, whereas the notification base targets chat channels with a WARN
 *              floor, a notification cap, and one callout per event.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public abstract with sharing class rflib_LogEventHttpForwarderAction {
    private static final rflib_ApplicationEventLogger APP_EVENT_LOGGER = rflib_LoggerUtil.getApplicationEventLogger();

    // Caps each queued failure detail. Failures are deferred into failurePayloads (see process()) and
    // published only after every callout, so during an outage many entries are held in memory at once.
    // getLogger().printLogs() is NOT used for them: rflib_HttpRequest logs the full request body, so the
    // buffer it returns is MB-sized and, across multiple failed batches, would exhaust Apex heap before
    // the application-event service truncates the detail. A bounded summary keeps each entry small while
    // still capturing the actionable error. Matches the application event's own ~32 KB detail cap.
    private static final Integer MAX_FAILURE_DETAIL_LENGTH = 32768;

    // Overrides the Apex per-transaction callout limit in tests so the budget guard in sendInBatches can
    // be exercised without making 100 real callouts. Null in production -> Limits.getLimitCallouts().
    @TestVisible
    private static Integer calloutLimitOverride = null;

    // Total budget for the consolidated failure detail published per invocation. Failures accumulate up
    // to this size; beyond it only a count is retained. This caps heap during the publish phase, where
    // rflib_DefaultApplicationEventLogger DEBUG-caches the detail in the shared 100-entry log buffer —
    // so even 100 failed batches publish a single bounded event instead of replaying MBs of strings.
    private static final Integer MAX_TOTAL_FAILURE_DETAIL = 32768;

    private rflib_Logger logger;
    private rflib_Logger calloutLogger;

    // Per-invocation failure accumulator (instance scoped: a fresh action instance handles each call).
    private final List<String> failurePayloads = new List<String>();
    private Integer failureDetailBytes = 0;
    private Integer omittedFailureCount = 0;

    /**
     * @description Runs the shared forwarding algorithm for the given events. Concrete forwarder
     *              classes expose this through their own static @InvocableMethod wrapper.
     */
    protected void process(List<rflib_Log_Event__e> events) {
        // Failures are accumulated (see addFailure) and published only AFTER every callout completes.
        // Publishing an application event mid-loop performs DML / EventBus.publish, which marks the
        // transaction as having uncommitted work and makes the NEXT HTTP callout in a multi-batch send
        // fail with "You have uncommitted work pending."
        try {
            Integer incomingCount = events == null ? 0 : events.size();
            rflib_LoggerUtil.logInternal(
                getLogger(),
                'Forwarder {0} received {1} log event(s)',
                new List<Object>{ getLoggerName(), incomingCount }
            );

            if (!isConfigured()) {
                rflib_LoggerUtil.logInternal(
                    getLogger(),
                    'Forwarder {0} is not configured. Nothing to do here.',
                    new List<Object>{ getLoggerName() }
                );
                return;
            }

            rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();
            String configuredLogLevel = getConfiguredLogLevel(loggerSettings);

            List<rflib_Log_Event__e> eventsToSend = new List<rflib_Log_Event__e>();
            for (rflib_Log_Event__e evt : events) {
                if (matchesConfiguredLogLevel(loggerSettings, evt)) {
                    eventsToSend.add(evt);
                }
            }

            rflib_LoggerUtil.logInternal(
                getLogger(),
                '{0} of {1} event(s) match the configured log level ({2}) for {3}',
                new List<Object>{ eventsToSend.size(), incomingCount, configuredLogLevel, getLoggerName() }
            );

            if (eventsToSend.isEmpty()) {
                rflib_LoggerUtil.logInternal(getLogger(), 'No events to send found. Nothing to do here.');
                return;
            }

            sendInBatches(eventsToSend);
        } catch (Exception ex) {
            getLogger().error('Failed to forward log event(s) via ' + getLoggerName(), ex);
            addFailure(summarizeFailure(ex));
        }

        // Safe to do DML now: all callouts for this invocation are complete. Publish a SINGLE consolidated
        // failure event (bounded detail) rather than one per failed batch — the latter would replay every
        // detail through the application-event logger's shared cache and exhaust heap on large outages.
        Integer totalFailures = failurePayloads.size() + omittedFailureCount;
        if (totalFailures == 0) {
            return;
        }
        rflib_LoggerUtil.logInternal(
            getLogger(),
            'Publishing a consolidated {0} failure application event for {1} failure(s)',
            new List<Object>{ getAppEventFailureName(), totalFailures }
        );
        String combined =
            totalFailures +
            ' failure(s) while forwarding via ' +
            getLoggerName() +
            ':\n' +
            String.join(failurePayloads, '\n---\n');
        if (omittedFailureCount > 0) {
            combined += '\n---\n(' + omittedFailureCount + ' additional failure detail(s) omitted to bound heap)';
        }
        APP_EVENT_LOGGER.logApplicationEvent(getAppEventFailureName(), null, boundDetail(combined));
    }

    /**
     * @description Accumulates a bounded failure detail for the single consolidated failure event
     *              published at the end of the invocation. Stops retaining full detail once the total
     *              budget is reached, tracking only a count thereafter, so a large multi-batch outage
     *              cannot grow the retained detail (or the publish-phase log cache) without bound.
     */
    private void addFailure(String detail) {
        String bounded = boundDetail(detail);
        if (String.isBlank(bounded)) {
            return;
        }
        if (failureDetailBytes + bounded.length() <= MAX_TOTAL_FAILURE_DETAIL) {
            failurePayloads.add(bounded);
            failureDetailBytes += bounded.length();
        } else {
            omittedFailureCount++;
        }
    }

    private Boolean matchesConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings, rflib_Log_Event__e evt) {
        return rflib_LogLevel.fromString(getConfiguredLogLevel(loggerSettings))
            .encompasses(rflib_LogLevel.fromString(evt.Log_Level__c));
    }

    private void send(List<rflib_Log_Event__e> batch) {
        try {
            String payload = createPayload(batch);
            rflib_LoggerUtil.logInternal(
                getLogger(),
                'Sending {0} event(s) ({1} bytes) to {2}',
                new List<Object>{ batch.size(), Blob.valueOf(payload).size(), getEndpoint() }
            );

            rflib_HttpRequest req = new rflib_HttpRequest(getCalloutLogger());
            req.setEndpoint(getEndpoint());
            req.setMethod('POST');
            req.setHeader('Content-Type', getContentType());
            req.setBody(payload);

            HttpResponse res = req.send();
            if (isSuccessResponse(res)) {
                rflib_LoggerUtil.logInternal(
                    getLogger(),
                    'Successfully sent data to remote service. Status: {0}',
                    new List<Object>{ res.getStatusCode() }
                );
            } else {
                // Bound the response body ONCE, before composing any diagnostic. An endpoint can return a
                // multi-MB error page; concatenating the raw body (even if addFailure truncates afterwards)
                // would materialize another multi-MB string on top of the request payload and response
                // already held, risking Apex heap. The bounded copy is reused for the log and the failure.
                String boundedBody = boundDetail(res.getBody());
                rflib_LoggerUtil.logInternal(
                    getLogger(),
                    'Failed to send data to remote service. Status: {0}, Response: {1}',
                    new List<Object>{ res.getStatus(), boundedBody }
                );
                // Snapshot the failure now, but defer publishing until all callouts are done. Build the
                // detail from the response (status + body) rather than JSON.serialize(res) — HttpResponse
                // is not JSON-serializable (throws "Apex Type unsupported in JSON").
                addFailure(
                    'Failed to send data to remote service. Status: ' +
                        res.getStatusCode() +
                        ' ' +
                        res.getStatus() +
                        ', Response: ' +
                        boundedBody
                );
            }
        } catch (Exception ex) {
            getLogger().error('Failed to send data to remote service', ex);
            addFailure(summarizeFailure(ex));
        }
    }

    /**
     * @description Builds a heap-safe, bounded diagnostic for a forwarding failure: the exception type,
     *              message and stack trace. Deliberately excludes the request body that the logger
     *              buffer would carry, so queued failures stay small during a multi-batch outage.
     */
    private String summarizeFailure(Exception ex) {
        return boundDetail(ex.getTypeName() + ': ' + ex.getMessage() + '\n' + ex.getStackTraceString());
    }

    /**
     * @description Bounds a diagnostic detail string to MAX_FAILURE_DETAIL_LENGTH so large response or
     *              error bodies cannot accumulate in the shared log buffer / queued failure payloads.
     *              Available to subclasses that log destination-specific failure responses.
     */
    protected String boundDetail(String detail) {
        if (String.isBlank(detail) || detail.length() <= MAX_FAILURE_DETAIL_LENGTH) {
            return detail;
        }
        return detail.left(MAX_FAILURE_DETAIL_LENGTH);
    }

    /**
     * @description Sends the events in batches bounded by BOTH the per-callout record count
     *              (getMaxEventsPerCallout) AND, when a forwarder defines one, the serialized byte
     *              budget (getMaxBytesPerCallout). Bounding by bytes prevents a batch of large events
     *              from producing a request that exceeds the Salesforce callout body limit (6 MB sync
     *              / 12 MB async). A single event that already exceeds the byte budget is still sent on
     *              its own — it cannot be split further.
     */
    private void sendInBatches(List<rflib_Log_Event__e> events) {
        Integer maxCount = getMaxEventsPerCallout();
        Integer maxBytes = getMaxBytesPerCallout();

        Integer undelivered = 0;
        List<rflib_Log_Event__e> current = new List<rflib_Log_Event__e>();
        Integer currentBytes = 0;
        for (Integer idx = 0; idx < events.size(); idx++) {
            // Once the per-transaction callout budget is exhausted, stop building AND serializing: the
            // pending batch plus every remaining event are undelivered. This avoids spending CPU/heap on
            // payloads that can never be sent (and aborting before the undelivered summary is published).
            if (Limits.getCallouts() >= calloutLimit()) {
                undelivered += current.size() + (events.size() - idx);
                current = new List<rflib_Log_Event__e>();
                currentBytes = 0;
                break;
            }

            rflib_Log_Event__e evt = events[idx];
            // Estimate this event's serialized contribution by rendering it on its own. For NDJSON
            // (per-line) forwarders this is exact; for envelope forwarders it slightly overcounts the
            // shared wrapper, which only makes batches more conservative.
            Integer evtBytes = maxBytes > 0
                ? Blob.valueOf(createPayload(new List<rflib_Log_Event__e>{ evt })).size()
                : 0;

            Boolean overCount = maxCount > 0 && current.size() >= maxCount;
            Boolean overBytes = maxBytes > 0 && !current.isEmpty() && (currentBytes + evtBytes) > maxBytes;
            // The top-of-loop check guarantees the budget is available for this batch send.
            if (!current.isEmpty() && (overCount || overBytes)) {
                send(current);
                current = new List<rflib_Log_Event__e>();
                currentBytes = 0;
            }

            current.add(evt);
            currentBytes += evtBytes;
        }

        if (!current.isEmpty()) {
            if (Limits.getCallouts() >= calloutLimit()) {
                undelivered += current.size();
            } else {
                send(current);
            }
        }

        if (undelivered > 0) {
            // The remaining batches would exceed the per-transaction callout limit. Rather than letting
            // the (uncatchable) limit exception abort the whole flow element — losing the events AND the
            // deferred failure records — surface the shortfall so it can be alerted on. Reduce volume or
            // route through an OpenTelemetry collector for batches this large.
            rflib_LoggerUtil.logInternal(
                getLogger(),
                '{0} event(s) not delivered by {1}: reached the per-transaction callout limit ({2})',
                new List<Object>{ undelivered, getLoggerName(), calloutLimit() }
            );
            addFailure(
                undelivered +
                    ' log event(s) were not delivered by ' +
                    getLoggerName() +
                    ': reached the per-transaction callout limit (' +
                    calloutLimit() +
                    '). Reduce volume or route through an OpenTelemetry collector.'
            );
        }
    }

    private Integer calloutLimit() {
        return calloutLimitOverride != null ? calloutLimitOverride : Limits.getLimitCallouts();
    }

    /**
     * @description Returns the shared logger for this forwarder. Reporting is turned OFF so that
     *              forwarder log statements (even at INFO via rflib_LoggerUtil.logInternal) are never
     *              re-published as Log Events, which would cause an infinite forwarding loop. Subclasses
     *              must log through this logger for the same reason.
     */
    protected rflib_Logger getLogger() {
        if (logger == null) {
            logger = rflib_LoggerUtil.getFactory().createLogger(getLoggerName());
            // NOTE: It is critical to turn reporting off so that a log configuration reporting INFO statements
            //       does not create an infinite loop of log events.
            logger.setReportingLogLevel(rflib_LogLevel.NONE);
            logger.setSystemDebugLevel(rflib_LogLevel.DEBUG);
        }
        return logger;
    }

    /**
     * @description Returns a dedicated logger for the HTTP callout. rflib_HttpRequest.send() logs the full
     *              request and response bodies at INFO; for bulk forwarders each request body is up to ~MB,
     *              and the logger caches INFO entries in the shared static buffer (up to 100). Across the
     *              multiple batches of a large invocation that would leave every body in heap until the
     *              transaction ends and can exhaust the Apex heap limit before delivery. This logger sets
     *              the general log level to NONE so those bodies are never cached, while keeping reporting
     *              off (loop-safe) and system debug on so the bodies remain visible in the debug log for
     *              troubleshooting. The forwarder's own diagnostics still flow through getLogger().
     */
    private rflib_Logger getCalloutLogger() {
        if (calloutLogger == null) {
            calloutLogger = rflib_LoggerUtil.getFactory().createLogger(getLoggerName() + '.callout');
            calloutLogger.setReportingLogLevel(rflib_LogLevel.NONE);
            calloutLogger.setGeneralLogLevel(rflib_LogLevel.NONE);
            calloutLogger.setSystemDebugLevel(rflib_LogLevel.DEBUG);
        }
        return calloutLogger;
    }

    private static final String TRUNCATION_PREFIX = '[TRUNCATED]\n';

    /**
     * @description Truncates a value to at most the given length (prefix included), keeping the MOST
     *              RECENT content (the tail). Returns 'N/A' when blank. The '[TRUNCATED]\n' marker is
     *              counted against maxLength so the result never exceeds the destination's field limit.
     */
    protected String truncate(String value, Integer maxLength) {
        if (String.isBlank(value)) {
            return 'N/A';
        }
        if (value.length() <= maxLength) {
            return value;
        }
        Integer tailLength = maxLength - TRUNCATION_PREFIX.length();
        if (tailLength <= 0) {
            return value.right(maxLength);
        }
        return TRUNCATION_PREFIX + value.right(tailLength);
    }

    // ---- Forwarder-specific hooks ------------------------------------------------------------

    /** @description Name of the Apex logger / class, used for log context (e.g. 'rflib_HttpCalloutLogAction'). */
    protected abstract String getLoggerName();

    /** @description Named Credential callout endpoint incl. any path (e.g. 'callout:RFLIB_HTTP_CALLOUT_LOG'). */
    protected abstract String getEndpoint();

    /** @description The configured forwarder log level from the Logger Settings record. */
    protected abstract String getConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings);

    /** @description Application Event name logged when a callout fails (e.g. 'rflib-http-callout-log-event-failed'). */
    protected abstract String getAppEventFailureName();

    /** @description Serialized destination-specific request body for the given batch of events. */
    protected abstract String createPayload(List<rflib_Log_Event__e> events);

    /** @description The Content-Type header for the callout. Defaults to 'application/json'. */
    protected virtual String getContentType() {
        return 'application/json';
    }

    /** @description Whether the given HTTP response represents a successful delivery. Defaults to a 200 status check. */
    protected virtual Boolean isSuccessResponse(HttpResponse res) {
        return res.getStatusCode() == 200;
    }

    /** @description Whether the forwarder has the prerequisite configuration to run. Defaults to true. */
    protected virtual Boolean isConfigured() {
        return true;
    }

    /** @description Maximum events per callout; values &lt; 1 mean a single callout for the whole batch. Defaults to -1. */
    protected virtual Integer getMaxEventsPerCallout() {
        return -1;
    }

    /** @description Maximum serialized request size in bytes per callout; values &lt; 1 disable the byte bound. Defaults to -1. */
    protected virtual Integer getMaxBytesPerCallout() {
        return -1;
    }
}
