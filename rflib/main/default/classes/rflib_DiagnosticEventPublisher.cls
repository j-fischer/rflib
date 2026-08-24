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
 * @description Converts normalized platform diagnostic events into `rflib_Log_Event__e` records so that
 *              Salesforce's own diagnostics flow through the same pipeline as application logs, i.e.
 *              the Big Object archive, the notification actions, and the telemetry forwarders.
 *
 *              All diagnostics are reported at FATAL. Within RFLIB, FATAL means that an asynchronous
 *              unit of work terminated without recovering, which is exactly what the events subscribed
 *              to represent. The level is therefore a constant and not configurable.
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_DiagnosticEventPublisher {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_DiagnosticEventPublisher');

    private static final String LOG_LEVEL = rflib_LogLevel.FATAL.toString();
    private static final String LOG_SOURCE = rflib_LogSource.Platform.toString();

    // See https://github.com/j-fischer/rflib/issues/67, Request_ID__c is a required field on the log event.
    private static final String UNKNOWN_REQUEST_ID = 'NULL';

    private static final Integer MAX_TEXT_FIELD_SIZE = 40;
    private static final Integer MAX_MESSAGE_SIZE = 131072;
    private static final Integer MAX_PLATFORM_INFO_SIZE = 32768;

    @TestVisible
    private static rflib_EventPublisher EVENT_PUBLISHER = new rflib_EventBusPublisher();

    static {
        // NOTE: It is critical to turn reporting off so that this class's own log statements do not
        //       create additional log events while it is publishing the diagnostics themselves.
        LOGGER.setReportingLogLevel(rflib_LogLevel.NONE);
        LOGGER.setSystemDebugLevel(rflib_LogLevel.DEBUG);
    }

    /**
     * @description Publish the given diagnostics as log events. 
     *
     *              The log events are constructed directly instead of going through an `rflib_Logger`
     *              for two reasons. A platform event subscriber receives up to 2000 events per
     *              invocation and a logger publishes one event per statement, which would exceed the
     *              transaction's publish limit. The logger also derives `Request_ID__c` from the current
     *              transaction, which inside a subscriber is the Automated Process request rather than
     *              the request that actually failed.
     *
     * @param diagnostics The normalized diagnostics to report.
     */
    public static void publish(List<rflib_DiagnosticEvent> diagnostics) {
        if (diagnostics == null || diagnostics.isEmpty()) {
            return;
        }

        LOGGER.debug('publish() invoked, size=' + diagnostics.size());

        Boolean isMaskingEnabled = rflib_Logger_Settings__c.getOrgDefaults().Enable_Log_Masking__c == true;
        String sourceSystemId = UserInfo.getOrganizationId();

        List<SObject> events = new List<SObject>();
        for (rflib_DiagnosticEvent diagnostic : diagnostics) {
            events.add(new rflib_Log_Event__e(
                Source_System_ID__c = sourceSystemId,
                Request_ID__c = resolveRequestId(diagnostic.requestId),
                Log_Level__c = LOG_LEVEL,
                Context__c = truncate(diagnostic.context, MAX_TEXT_FIELD_SIZE),
                Log_Source__c = LOG_SOURCE,
                Log_Messages__c = prepare(diagnostic.message, isMaskingEnabled),
                Stacktrace__c = prepare(diagnostic.stacktrace, isMaskingEnabled),
                Platform_Info__c = serializeAttributes(diagnostic.attributes)
            ));
        }

        // NOTE: A single publish call keeps this within the transaction's publish limit no matter how
        //       many events the subscriber received, since the limit counts calls and not messages.
        EVENT_PUBLISHER.publish(events);
    }

    private static String resolveRequestId(String requestId) {
        return String.isBlank(requestId) ? UNKNOWN_REQUEST_ID : truncate(requestId, MAX_TEXT_FIELD_SIZE);
    }

    private static String truncate(String value, Integer maxSize) {
        return String.isBlank(value) ? null : value.substring(0, Math.min(value.length(), maxSize));
    }

    private static String prepare(String value, Boolean isMaskingEnabled) {
        if (String.isBlank(value)) {
            return null;
        }

        // NOTE: Masking runs before truncation because the masking rules can change the length of the text.
        String maskedValueIfApplicable = isMaskingEnabled
            ? rflib_StringUtil.replaceWithAllMaskingRules(value)
            : value;

        return rflib_StringUtil.truncateToMaxSize(maskedValueIfApplicable, MAX_MESSAGE_SIZE);
    }

    private static String serializeAttributes(Map<String, Object> attributes) {
        if (attributes == null || attributes.isEmpty()) {
            return null;
        }

        // Null values are dropped so that rflib_PlatformInfoTransformer does not emit empty attributes
        // for fields the source event did not populate.
        Map<String, Object> populatedAttributes = new Map<String, Object>();
        for (String key : attributes.keySet()) {
            Object value = attributes.get(key);
            if (value != null) {
                populatedAttributes.put(key, value);
            }
        }

        return populatedAttributes.isEmpty()
            ? null
            : rflib_StringUtil.truncateToMaxSize(JSON.serialize(populatedAttributes), MAX_PLATFORM_INFO_SIZE);
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    private rflib_DiagnosticEventPublisher() { }
}
