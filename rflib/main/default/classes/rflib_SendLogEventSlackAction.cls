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
 * @description Invocable Action that sends log event details to a Slack channel via
 *              an Incoming Webhook. Configure a Named Credential named RFLIB_SLACK_WEBHOOK
 *              with the Slack webhook URL (Authentication Protocol: No Authentication).
 *              Set Slack_Log_Level__c in the Logger Settings to control which events
 *              trigger a notification.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_SendLogEventSlackAction {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_SendLogEventSlackAction');

    private static final rflib_ApplicationEventLogger APP_EVENT_LOGGER = rflib_LoggerUtil.getApplicationEventLogger();

    @TestVisible
    private static final String ENDPOINT = 'callout:RFLIB_SLACK_WEBHOOK';

    // Slack Block Kit limits: section text max 3000 chars, header text max 150 chars.
    private static final Integer MAX_BLOCK_TEXT_LENGTH = 2800;

    // INFO and below are never appropriate for Slack alerting; enforce WARN as the floor.
    @TestVisible
    private static final rflib_LogLevel MINIMUM_LOG_LEVEL = rflib_LogLevel.WARN;

    static {
        // NOTE: It is critical to turn reporting off so that a log configuration reporting INFO statements
        //       does not create an infinite loop of log events.
        LOGGER.setReportingLogLevel(rflib_LogLevel.NONE);
        LOGGER.setSystemDebugLevel(rflib_LogLevel.DEBUG);
    }

    @InvocableMethod(label='Send Log Event to Slack' category='RFLIB' description='Send Log Events to a Slack channel via Incoming Webhook')
    public static void sendToSlack(List<rflib_Log_Event__e> events) {
        try {
            rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();

            for (rflib_Log_Event__e evt : events) {
                if (matchesConfiguredLogLevel(loggerSettings, evt)) {
                    sendMessage(evt);
                }
            }
        } catch (Exception ex) {
            LOGGER.error('Failed to send log event(s) to Slack', ex);
            APP_EVENT_LOGGER.logApplicationEvent('rflib-slack-log-event-failed', null, LOGGER.printLogs());
        }
    }

    private static Boolean matchesConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings, rflib_Log_Event__e evt) {
        rflib_LogLevel configuredLevel = rflib_LogLevel.fromString(loggerSettings.Slack_Log_Level__c);

        // NONE means disabled; skip the floor check so it stays disabled.
        // For any level below WARN (INFO, DEBUG, TRACE), clamp up to WARN.
        // encompasses() returns false when either side is NONE, so we guard that first.
        if (configuredLevel != rflib_LogLevel.NONE && !MINIMUM_LOG_LEVEL.encompasses(configuredLevel)) {
            LOGGER.warn('Slack_Log_Level__c is configured below the minimum of WARN. Clamping to WARN.');
            configuredLevel = MINIMUM_LOG_LEVEL;
        }

        return configuredLevel.encompasses(rflib_LogLevel.fromString(evt.Log_Level__c));
    }

    private static void sendMessage(rflib_Log_Event__e evt) {
        try {
            rflib_HttpRequest req = new rflib_HttpRequest(LOGGER);
            req.setEndpoint(ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(createSlackPayload(evt));

            HttpResponse res = req.send();
            if (res.getStatusCode() == 200) {
                LOGGER.debug('Successfully sent log event to Slack for context: ' + evt.Context__c);
            } else {
                LOGGER.debug('Failed to send log event to Slack. Status: ' + res.getStatus() + ' for context: ' + evt.Context__c);
                APP_EVENT_LOGGER.logApplicationEvent('rflib-slack-log-event-failed', null, JSON.serialize(res));
            }
        } catch (Exception ex) {
            LOGGER.error('Failed to send log event to Slack for context: ' + evt.Context__c, ex);
            APP_EVENT_LOGGER.logApplicationEvent('rflib-slack-log-event-failed', null, LOGGER.printLogs());
        }
    }

    @TestVisible
    private static String createSlackPayload(rflib_Log_Event__e evt) {
        String logMessages = truncate(evt.Log_Messages__c, MAX_BLOCK_TEXT_LENGTH);
        String platformInfo = truncate(getFormattedPlatformInfo(evt), MAX_BLOCK_TEXT_LENGTH);

        List<Object> blocks = new List<Object>{
            createHeaderBlock('RFLIB Log Event – ' + evt.Log_Level__c),
            createMetadataSection(evt),
            new Map<String, Object>{ 'type' => 'divider' },
            createTextSection('*Log Messages:*\n```' + logMessages + '```'),
            createTextSection('*Platform Info:*\n```' + platformInfo + '```')
        };

        return JSON.serialize(new Map<String, Object>{ 'blocks' => blocks });
    }

    private static Map<String, Object> createHeaderBlock(String text) {
        return new Map<String, Object>{
            'type' => 'header',
            'text' => new Map<String, Object>{
                'type' => 'plain_text',
                'text' => text
            }
        };
    }

    private static Map<String, Object> createMetadataSection(rflib_Log_Event__e evt) {
        return new Map<String, Object>{
            'type' => 'section',
            'fields' => new List<Object>{
                createMrkdwnField('*Created By:*\n' + evt.CreatedById),
                createMrkdwnField('*Log Level:*\n' + evt.Log_Level__c),
                createMrkdwnField('*Context:*\n' + evt.Context__c),
                createMrkdwnField('*Request ID:*\n' + evt.Request_ID__c)
            }
        };
    }

    private static Map<String, Object> createTextSection(String text) {
        return new Map<String, Object>{
            'type' => 'section',
            'text' => new Map<String, Object>{
                'type' => 'mrkdwn',
                'text' => text
            }
        };
    }

    private static Map<String, Object> createMrkdwnField(String text) {
        return new Map<String, Object>{
            'type' => 'mrkdwn',
            'text' => text
        };
    }

    private static String truncate(String value, Integer maxLength) {
        if (String.isBlank(value)) {
            return 'N/A';
        }
        if (value.length() <= maxLength) {
            return value;
        }
        return value.left(maxLength) + '\n[TRUNCATED]';
    }

    private static String getFormattedPlatformInfo(rflib_Log_Event__e evt) {
        if (String.isBlank(evt.Platform_Info__c)) {
            return 'N/A';
        }
        try {
            return JSON.serializePretty(JSON.deserializeUntyped(evt.Platform_Info__c));
        } catch (Exception ex) {
            return evt.Platform_Info__c;
        }
    }
}
