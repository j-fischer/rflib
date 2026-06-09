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
 *              Logger Settings to control which events trigger a notification. The shared
 *              notification algorithm lives in rflib_LogEventNotificationAction; this class only
 *              supplies the Teams specifics.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_SendLogEventTeamsAction extends rflib_LogEventNotificationAction {

    @TestVisible
    private static final String ENDPOINT = 'callout:RFLIB_TEAMS_WEBHOOK';

    @InvocableMethod(label='Send Log Event to Microsoft Teams' category='RFLIB' description='Send Log Events to a Microsoft Teams channel via Incoming Webhook')
    public static void sendToTeams(List<rflib_Log_Event__e> events) {
        new rflib_SendLogEventTeamsAction().process(events);
    }

    protected override String getLoggerName() {
        return 'rflib_SendLogEventTeamsAction';
    }

    protected override String getChannelName() {
        return 'Teams';
    }

    protected override String getEndpoint() {
        return ENDPOINT;
    }

    protected override Integer getMaxNotifications() {
        return rflib_GlobalSettings.maxTeamsNotificationsPerInvocationOrDefault;
    }

    protected override String getConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings) {
        return loggerSettings.Teams_Log_Level__c;
    }

    protected override String getAppEventFailureName() {
        return 'rflib-teams-log-event-failed';
    }

    protected override Boolean isSuccessStatusCode(Integer statusCode) {
        // Power Automate Workflow webhooks return 202 Accepted; legacy O365 connectors return 200.
        return statusCode == 200 || statusCode == 202;
    }

    @TestVisible
    protected override String createPayload(rflib_Log_Event__e evt) {
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
}
