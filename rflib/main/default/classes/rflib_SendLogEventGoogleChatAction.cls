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
 * @description Invocable Action that sends log event details to a Google Chat space via
 *              an Incoming Webhook. Configure a Named Credential named RFLIB_GOOGLE_CHAT_WEBHOOK
 *              with the Google Chat webhook URL (Authentication Protocol: No Authentication; the
 *              key and token are part of the webhook URL itself). Set Google_Chat_Log_Level__c in
 *              the Logger Settings to control which events trigger a notification. The shared
 *              notification algorithm lives in rflib_LogEventNotificationAction; this class only
 *              supplies the Google Chat specifics.
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_SendLogEventGoogleChatAction extends rflib_LogEventNotificationAction {

    @TestVisible
    private static final String ENDPOINT = 'callout:RFLIB_GOOGLE_CHAT_WEBHOOK';

    @InvocableMethod(label='Send Log Event to Google Chat' category='RFLIB' description='Send Log Events to a Google Chat space via Incoming Webhook')
    public static void sendToGoogleChat(List<rflib_Log_Event__e> events) {
        new rflib_SendLogEventGoogleChatAction().process(events);
    }

    protected override String getLoggerName() {
        return 'rflib_SendLogEventGoogleChatAction';
    }

    protected override String getChannelName() {
        return 'Google Chat';
    }

    protected override String getEndpoint() {
        return ENDPOINT;
    }

    protected override Integer getMaxNotifications() {
        return rflib_GlobalSettings.maxGoogleChatNotificationsPerInvocationOrDefault;
    }

    protected override String getConfiguredLogLevel(rflib_Logger_Settings__c loggerSettings) {
        return loggerSettings.Google_Chat_Log_Level__c;
    }

    protected override String getAppEventFailureName() {
        return 'rflib-google-chat-log-event-failed';
    }

    protected override Boolean isSuccessStatusCode(Integer statusCode) {
        return statusCode == 200;
    }

    @TestVisible
    protected override String createPayload(rflib_Log_Event__e evt) {
        String logMessages = escapeHtml(truncate(evt.Log_Messages__c, MAX_BLOCK_TEXT_LENGTH));
        String platformInfo = escapeHtml(truncate(getFormattedPlatformInfo(evt), MAX_BLOCK_TEXT_LENGTH));

        Map<String, Object> card = new Map<String, Object>{
            'header' => new Map<String, Object>{
                'title' => 'RFLIB Log Event – ' + evt.Log_Level__c,
                'subtitle' => escapeHtml(UserInfo.getOrganizationName())
            },
            'sections' => new List<Object>{
                new Map<String, Object>{
                    'widgets' => new List<Object>{
                        createDecoratedText('Log Level', evt.Log_Level__c),
                        createDecoratedText('Created By', evt.CreatedById),
                        createDecoratedText('Context', evt.Context__c),
                        createDecoratedText('Request ID', evt.Request_ID__c)
                    }
                },
                createTextParagraphSection('Log Messages', logMessages),
                createTextParagraphSection('Platform Info', platformInfo)
            }
        };

        Map<String, Object> cardWithId = new Map<String, Object>{
            'cardId' => 'rflib-log-event',
            'card' => card
        };

        return JSON.serialize(new Map<String, Object>{
            'cardsV2' => new List<Object>{ cardWithId }
        });
    }

    private static Map<String, Object> createDecoratedText(String topLabel, String text) {
        return new Map<String, Object>{
            'decoratedText' => new Map<String, Object>{
                'topLabel' => topLabel,
                'text' => String.isBlank(text) ? 'N/A' : escapeHtml(text)
            }
        };
    }

    private static Map<String, Object> createTextParagraphSection(String header, String text) {
        return new Map<String, Object>{
            'header' => header,
            'widgets' => new List<Object>{
                new Map<String, Object>{
                    'textParagraph' => new Map<String, Object>{ 'text' => text }
                }
            }
        };
    }

    // Google Chat renders textParagraph and decoratedText content as limited HTML, so raw log
    // content containing angle brackets (XML/HTML snippets, generic type names, '<init>' stack
    // frames) would be interpreted as markup or silently dropped. Escape the HTML-significant
    // characters so the log text is delivered verbatim. '&' must be replaced first to avoid
    // double-escaping the entities introduced for '<' and '>'.
    private static String escapeHtml(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;');
    }
}
