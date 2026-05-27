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
 * @description Invocable Action that sends log event details to a Microsoft Teams channel via
 *              an Incoming Webhook (Power Automate Workflow or legacy Office 365 connector).
 *              Configure a Named Credential named RFLIB_TEAMS_WEBHOOK with the Teams webhook
 *              URL (Authentication Protocol: No Authentication). Set Teams_Log_Level__c in the
 *              Logger Settings to control which events trigger a notification.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_SendLogEventTeamsAction {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_SendLogEventTeamsAction');

    private static final rflib_ApplicationEventLogger APP_EVENT_LOGGER = rflib_LoggerUtil.getApplicationEventLogger();

    @TestVisible
    private static final String ENDPOINT = 'callout:RFLIB_TEAMS_WEBHOOK';

    // Adaptive Cards in Teams have a 28KB total payload limit; cap per-block text to keep total payload safe.
    private static final Integer MAX_BLOCK_TEXT_LENGTH = 2800;

    // INFO and below are never appropriate for Teams alerting; enforce WARN as the floor.
    @TestVisible
    private static final rflib_LogLevel MINIMUM_LOG_LEVEL = rflib_LogLevel.WARN;

    static {
        // NOTE: It is critical to turn reporting off so that a log configuration reporting INFO statements
        //       does not create an infinite loop of log events.
        LOGGER.setReportingLogLevel(rflib_LogLevel.NONE);
        LOGGER.setSystemDebugLevel(rflib_LogLevel.DEBUG);
    }

    @InvocableMethod(label='Send Log Event to Microsoft Teams' category='RFLIB' description='Send Log Events to a Microsoft Teams channel via Incoming Webhook')
    public static void sendToTeams(List<rflib_Log_Event__e> events) {
        try {
            rflib_Logger_Settings__c loggerSettings = rflib_Logger_Settings__c.getInstance();
            Integer maxNotifications = rflib_GlobalSettings.maxTeamsNotificationsPerInvocationOrDefault;
            Integer sent = 0;

            for (rflib_Log_Event__e evt : events) {
                if (sent >= maxNotifications) {
                    LOGGER.warn('Max Teams notifications per invocation (' + maxNotifications + ') reached; remaining events skipped.');
                    break;
                }
                if (matchesConfiguredLogLevel(loggerSettings, evt)) {
                    sendMessage(evt);
                    sent++;
                }
            }
        } catch (Exception ex) {
            LOGGER.error('Failed to send log event(s) to Teams', ex);
            APP_EVENT_LOGGER.logApplicationEvent('rflib-teams-log-event-failed', null, LOGGER.printLogs());
        }
    }

    private static Boolean matchesConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings, rflib_Log_Event__e evt) {
        rflib_LogLevel configuredLevel = rflib_LogLevel.fromString(loggerSettings.Teams_Log_Level__c);

        // NONE means disabled; skip the floor check so it stays disabled.
        // For any level below WARN (INFO, DEBUG, TRACE), clamp up to WARN.
        // encompasses() returns false when either side is NONE, so we guard that first.
        if (configuredLevel != rflib_LogLevel.NONE && !MINIMUM_LOG_LEVEL.encompasses(configuredLevel)) {
            LOGGER.warn('Teams_Log_Level__c is configured below the minimum of WARN. Clamping to WARN.');
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
            req.setBody(createTeamsPayload(evt));

            HttpResponse res = req.send();
            // Power Automate Workflow webhooks return 202 Accepted; legacy O365 connectors return 200.
            if (res.getStatusCode() == 200 || res.getStatusCode() == 202) {
                LOGGER.debug('Successfully sent log event to Teams for context: ' + evt.Context__c);
            } else {
                LOGGER.debug('Failed to send log event to Teams. Status: ' + res.getStatus() + ' for context: ' + evt.Context__c);
                APP_EVENT_LOGGER.logApplicationEvent('rflib-teams-log-event-failed', null, JSON.serialize(res));
            }
        } catch (Exception ex) {
            LOGGER.error('Failed to send log event to Teams for context: ' + evt.Context__c, ex);
            APP_EVENT_LOGGER.logApplicationEvent('rflib-teams-log-event-failed', null, LOGGER.printLogs());
        }
    }

    @TestVisible
    private static String createTeamsPayload(rflib_Log_Event__e evt) {
        String logMessages = truncate(evt.Log_Messages__c, MAX_BLOCK_TEXT_LENGTH);
        String platformInfo = truncate(getFormattedPlatformInfo(evt), MAX_BLOCK_TEXT_LENGTH);

        List<Object> body = new List<Object>{
            createHeaderTextBlock('RFLIB Log Event – ' + evt.Log_Level__c),
            createMetadataFactSet(evt),
            createLabelTextBlock('Log Messages:'),
            createMonospaceTextBlock(logMessages),
            createLabelTextBlock('Platform Info:'),
            createMonospaceTextBlock(platformInfo)
        };

        Map<String, Object> adaptiveCard = new Map<String, Object>{
            '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
            'type' => 'AdaptiveCard',
            'version' => '1.4',
            'body' => body
        };

        Map<String, Object> attachment = new Map<String, Object>{
            'contentType' => 'application/vnd.microsoft.card.adaptive',
            'contentUrl' => null,
            'content' => adaptiveCard
        };

        return JSON.serialize(new Map<String, Object>{
            'type' => 'message',
            'attachments' => new List<Object>{ attachment }
        });
    }

    private static Map<String, Object> createHeaderTextBlock(String text) {
        return new Map<String, Object>{
            'type' => 'TextBlock',
            'size' => 'Large',
            'weight' => 'Bolder',
            'wrap' => true,
            'text' => text
        };
    }

    private static Map<String, Object> createMetadataFactSet(rflib_Log_Event__e evt) {
        return new Map<String, Object>{
            'type' => 'FactSet',
            'facts' => new List<Object>{
                createFact('Org Name:', UserInfo.getOrganizationName()),
                createFact('Log Level:', evt.Log_Level__c),
                createFact('Created By:', evt.CreatedById),
                createFact('Context:', evt.Context__c),
                createFact('Request ID:', evt.Request_ID__c)
            }
        };
    }

    private static Map<String, Object> createLabelTextBlock(String text) {
        return new Map<String, Object>{
            'type' => 'TextBlock',
            'weight' => 'Bolder',
            'separator' => true,
            'wrap' => true,
            'text' => text
        };
    }

    private static Map<String, Object> createMonospaceTextBlock(String text) {
        return new Map<String, Object>{
            'type' => 'TextBlock',
            'fontType' => 'Monospace',
            'wrap' => true,
            'text' => text
        };
    }

    private static Map<String, Object> createFact(String title, String value) {
        return new Map<String, Object>{
            'title' => title,
            'value' => value
        };
    }

    private static String truncate(String value, Integer maxLength) {
        if (String.isBlank(value)) {
            return 'N/A';
        }
        if (value.length() <= maxLength) {
            return value;
        }
        return '[TRUNCATED]\n' + value.right(maxLength);
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
