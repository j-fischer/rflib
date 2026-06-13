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

    private rflib_Logger logger;

    /**
     * @description Runs the shared forwarding algorithm for the given events. Concrete forwarder
     *              classes expose this through their own static @InvocableMethod wrapper.
     */
    protected void process(List<rflib_Log_Event__e> events) {
        try {
            if (!isConfigured()) {
                getLogger().debug('Forwarder ' + getLoggerName() + ' is not configured. Nothing to do here.');
                return;
            }

            rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();

            List<rflib_Log_Event__e> eventsToSend = new List<rflib_Log_Event__e>();
            for (rflib_Log_Event__e evt : events) {
                if (matchesConfiguredLogLevel(loggerSettings, evt)) {
                    eventsToSend.add(evt);
                }
            }

            if (eventsToSend.isEmpty()) {
                getLogger().debug('No events to send found. Nothing to do here.');
                return;
            }

            for (List<rflib_Log_Event__e> batch : chunk(eventsToSend)) {
                send(batch);
            }
        } catch (Exception ex) {
            getLogger().error('Failed to forward log event(s) via ' + getLoggerName(), ex);
            APP_EVENT_LOGGER.logApplicationEvent(getAppEventFailureName(), null, getLogger().printLogs());
        }
    }

    @TestVisible
    protected Boolean matchesConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings, rflib_Log_Event__e evt) {
        return rflib_LogLevel.fromString(getConfiguredLogLevel(loggerSettings))
            .encompasses(rflib_LogLevel.fromString(evt.Log_Level__c));
    }

    private void send(List<rflib_Log_Event__e> batch) {
        try {
            rflib_HttpRequest req = new rflib_HttpRequest(getLogger());
            req.setEndpoint(getEndpoint());
            req.setMethod('POST');
            req.setHeader('Content-Type', getContentType());
            req.setBody(createPayload(batch));

            HttpResponse res = req.send();
            if (isSuccessResponse(res)) {
                getLogger().debug('Successfully sent data to remote service');
            } else {
                getLogger().debug('Failed to send data to remote service. Status: ' + res.getStatus());
                APP_EVENT_LOGGER.logApplicationEvent(getAppEventFailureName(), null, JSON.serialize(res));
            }
        } catch (Exception ex) {
            getLogger().error('Failed to send data to remote service', ex);
            APP_EVENT_LOGGER.logApplicationEvent(getAppEventFailureName(), null, getLogger().printLogs());
        }
    }

    private List<List<rflib_Log_Event__e>> chunk(List<rflib_Log_Event__e> events) {
        Integer maxPerCallout = getMaxEventsPerCallout();
        if (maxPerCallout == null || maxPerCallout < 1) {
            return new List<List<rflib_Log_Event__e>>{ events };
        }

        List<List<rflib_Log_Event__e>> batches = new List<List<rflib_Log_Event__e>>();
        List<rflib_Log_Event__e> current = new List<rflib_Log_Event__e>();
        for (rflib_Log_Event__e evt : events) {
            if (current.size() == maxPerCallout) {
                batches.add(current);
                current = new List<rflib_Log_Event__e>();
            }
            current.add(evt);
        }
        batches.add(current);
        return batches;
    }

    private rflib_Logger getLogger() {
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
     * @description Truncates a value to the given length, keeping the MOST RECENT content (the tail).
     *              Returns 'N/A' when blank. Mirrors rflib_LogEventNotificationAction.truncate().
     */
    protected String truncate(String value, Integer maxLength) {
        if (String.isBlank(value)) {
            return 'N/A';
        }
        if (value.length() <= maxLength) {
            return value;
        }
        return '[TRUNCATED]\n' + value.right(maxLength);
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
}
