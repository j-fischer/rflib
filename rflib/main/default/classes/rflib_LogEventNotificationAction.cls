/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
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
 * @description Abstract base for Invocable Actions that forward RFLIB Log Events to an external
 *              chat channel via an Incoming Webhook (Slack, Microsoft Teams, Google Chat, ...).
 *              It owns the shared algorithm — log level matching with a WARN floor, the
 *              per-invocation notification cap, the HTTP callout, message truncation, and failure
 *              handling — while each concrete channel supplies its endpoint, configuration accessors
 *              and channel-specific payload through the abstract hooks below.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public abstract with sharing class rflib_LogEventNotificationAction {

    private static final rflib_ApplicationEventLogger APP_EVENT_LOGGER = rflib_LoggerUtil.getApplicationEventLogger();

    // Webhook payloads have channel-specific size limits (Slack section 3000 chars, Teams ~28KB total,
    // Google Chat 32KB). Cap per-block text well below the smallest to keep the total payload safe.
    // Apex does not allow protected static members, so these are protected instance constants.
    protected final Integer MAX_BLOCK_TEXT_LENGTH = 2800;

    // INFO and below are never appropriate for chat alerting; enforce WARN as the floor.
    @TestVisible
    protected final rflib_LogLevel MINIMUM_LOG_LEVEL = rflib_LogLevel.WARN;

    private rflib_Logger logger;

    /**
     * @description Runs the shared notification algorithm for the given events. Concrete channel
     *              classes expose this through their own static @InvocableMethod wrapper.
     */
    protected void process(List<rflib_Log_Event__e> events) {
        try {
            rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();
            Integer maxNotifications = getMaxNotifications();
            Integer sent = 0;

            for (rflib_Log_Event__e evt : events) {
                if (sent >= maxNotifications) {
                    getLogger().warn('Max notifications per invocation (' + maxNotifications + ') reached; remaining events skipped.');
                    break;
                }
                if (matchesConfiguredLogLevel(loggerSettings, evt)) {
                    sendMessage(evt);
                    sent++;
                }
            }
        } catch (Exception ex) {
            getLogger().error('Failed to send log event(s) to ' + getChannelName(), ex);
            APP_EVENT_LOGGER.logApplicationEvent(getAppEventFailureName(), null, getLogger().printLogs());
        }
    }

    @TestVisible
    protected Boolean matchesConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings, rflib_Log_Event__e evt) {
        rflib_LogLevel configuredLevel = rflib_LogLevel.fromString(getConfiguredLogLevel(loggerSettings));

        // NONE means disabled; skip the floor check so it stays disabled.
        // For any level below WARN (INFO, DEBUG, TRACE), clamp up to WARN.
        // encompasses() returns false when either side is NONE, so we guard that first.
        if (configuredLevel != rflib_LogLevel.NONE && !MINIMUM_LOG_LEVEL.encompasses(configuredLevel)) {
            getLogger().warn(getChannelName() + ' log level is configured below the minimum of WARN. Clamping to WARN.');
            configuredLevel = MINIMUM_LOG_LEVEL;
        }

        return configuredLevel.encompasses(rflib_LogLevel.fromString(evt.Log_Level__c));
    }

    private void sendMessage(rflib_Log_Event__e evt) {
        try {
            rflib_HttpRequest req = new rflib_HttpRequest(getLogger());
            req.setEndpoint(getEndpoint());
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(createPayload(evt));

            HttpResponse res = req.send();
            if (isSuccessStatusCode(res.getStatusCode())) {
                getLogger().debug('Successfully sent log event to ' + getChannelName() + ' for context: ' + evt.Context__c);
            } else {
                getLogger().debug('Failed to send log event to ' + getChannelName() + '. Status: ' + res.getStatus() + ' for context: ' + evt.Context__c);
                APP_EVENT_LOGGER.logApplicationEvent(getAppEventFailureName(), null, JSON.serialize(res));
            }
        } catch (Exception ex) {
            getLogger().error('Failed to send log event to ' + getChannelName() + ' for context: ' + evt.Context__c, ex);
            APP_EVENT_LOGGER.logApplicationEvent(getAppEventFailureName(), null, getLogger().printLogs());
        }
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

    protected String truncate(String value, Integer maxLength) {
        if (String.isBlank(value)) {
            return 'N/A';
        }
        if (value.length() <= maxLength) {
            return value;
        }
        return '[TRUNCATED]\n' + value.right(maxLength);
    }

    protected String getFormattedPlatformInfo(rflib_Log_Event__e evt) {
        if (String.isBlank(evt.Platform_Info__c)) {
            return 'N/A';
        }
        try {
            return JSON.serializePretty(JSON.deserializeUntyped(evt.Platform_Info__c));
        } catch (Exception ex) {
            return evt.Platform_Info__c;
        }
    }

    // ---- Channel-specific hooks --------------------------------------------------------------

    /** @description Name of the Apex logger / class, used for log context (e.g. 'rflib_SendLogEventSlackAction'). */
    protected abstract String getLoggerName();

    /** @description Human readable channel name used in log messages (e.g. 'Slack', 'Teams', 'Google Chat'). */
    protected abstract String getChannelName();

    /** @description Named Credential callout endpoint (e.g. 'callout:RFLIB_SLACK_WEBHOOK'). */
    protected abstract String getEndpoint();

    /** @description Maximum number of notifications to send per invocation. */
    protected abstract Integer getMaxNotifications();

    /** @description The configured channel log level from the Logger Settings record. */
    protected abstract String getConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings);

    /** @description Application Event name logged when a notification fails (e.g. 'rflib-slack-log-event-failed'). */
    protected abstract String getAppEventFailureName();

    /** @description Whether the given HTTP status code represents a successful delivery. */
    protected abstract Boolean isSuccessStatusCode(Integer statusCode);

    /** @description Serialized channel-specific message payload for the given event. */
    protected abstract String createPayload(rflib_Log_Event__e evt);
}
