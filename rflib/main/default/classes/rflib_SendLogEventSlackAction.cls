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
 *              trigger a notification. The shared notification algorithm lives in
 *              rflib_LogEventNotificationAction; this class only supplies the Slack specifics.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_SendLogEventSlackAction extends rflib_LogEventNotificationAction {

    @TestVisible
    private static final String ENDPOINT = 'callout:RFLIB_SLACK_WEBHOOK';

    @InvocableMethod(label='Send Log Event to Slack' category='RFLIB' description='Send Log Events to a Slack channel via Incoming Webhook')
    public static void sendToSlack(List<rflib_Log_Event__e> events) {
        new rflib_SendLogEventSlackAction().process(events);
    }

    protected override String getLoggerName() {
        return 'rflib_SendLogEventSlackAction';
    }

    protected override String getChannelName() {
        return 'Slack';
    }

    protected override String getEndpoint() {
        return ENDPOINT;
    }

    protected override Integer getMaxNotifications() {
        return rflib_GlobalSettings.maxSlackNotificationsPerInvocationOrDefault;
    }

    protected override String getConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings) {
        return loggerSettings.Slack_Log_Level__c;
    }

    protected override String getAppEventFailureName() {
        return 'rflib-slack-log-event-failed';
    }

    protected override Boolean isSuccessStatusCode(Integer statusCode) {
        return statusCode == 200;
    }

    @TestVisible
    protected override String createPayload(rflib_Log_Event__e evt) {
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
                createMrkdwnField('*Org Name:*\n' + UserInfo.getOrganizationName()),
                createMrkdwnField('*Log Level:*\n' + evt.Log_Level__c),
                createMrkdwnField('*Created By:*\n' + evt.CreatedById),
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
}
