/*
 * Copyright (c) 2021 Johannes Fischer <fischer.jh@gmail.com>
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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_GlobalSettingsTest {
    @IsTest
    static void testTraceIdHeaderNameOrDefault() {
        String expectedValue = getConfiguredStringValueOrDefault(
            'Trace_ID_Header_Name',
            rflib_GlobalSettings.TRACE_ID_HEADER_NAME_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.traceIdHeaderNameOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testPublishingLimitOrDefault() {
        Integer expectedValue = getConfiguredIntegerValueOrDefault(
            'Publish_Platform_Event_Transaction_Limit',
            rflib_GlobalSettings.PUBLISH_PLATFORM_EVENT_TRANSACTION_LIMIT_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.publishingLimitOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testOverridePublishingLimitOrDefault_Success() {
        Integer expectedValue = getConfiguredIntegerValueOrDefault(
            'Publish_Platform_Event_Transaction_Limit',
            rflib_GlobalSettings.PUBLISH_PLATFORM_EVENT_TRANSACTION_LIMIT_DEFAULT_VALUE
        );

        Test.startTest();
        rflib_GlobalSettings.overridePublishingLimitOrDefault(5);
        System.assertEquals(5, rflib_GlobalSettings.publishingLimitOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testOverridePublishingLimitOrDefault_NullValue() {
        Integer expectedValue = getConfiguredIntegerValueOrDefault(
            'Publish_Platform_Event_Transaction_Limit',
            rflib_GlobalSettings.PUBLISH_PLATFORM_EVENT_TRANSACTION_LIMIT_DEFAULT_VALUE
        );

        Test.startTest();
        rflib_GlobalSettings.overridePublishingLimitOrDefault(0);
        System.assertEquals(0, rflib_GlobalSettings.publishingLimitOrDefault);

        rflib_GlobalSettings.overridePublishingLimitOrDefault(null);
        System.assertEquals(expectedValue, rflib_GlobalSettings.publishingLimitOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testOverridePublishingLimitOrDefault_ValueExceedsLimit() {
        Integer expectedValue = getConfiguredIntegerValueOrDefault(
            'Publish_Platform_Event_Transaction_Limit',
            rflib_GlobalSettings.PUBLISH_PLATFORM_EVENT_TRANSACTION_LIMIT_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.publishingLimitOrDefault);

        try {
            rflib_GlobalSettings.overridePublishingLimitOrDefault(Limits.getLimitPublishImmediateDML() + 1);
            System.assert(false, 'Expected rflib_InvalidArgumentException has not been thrown');
        } catch (rflib_InvalidArgumentException ex) {
            System.assert(ex.getMessage().contains('is less than 0 or higher than allowed limit'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testDaysToRetainApplicationEvents() {
        Integer expectedValue = getConfiguredIntegerValueOrDefault(
            'Application_Event_Retain_X_Days',
            rflib_GlobalSettings.APPLICATION_EVENT_RETAIN_X_DAYS_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.daysToRetainApplicationEventsOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testArchiveLogQueryLimit() {
        Integer expectedValue = getConfiguredIntegerValueOrDefault(
            'Archive_Log_Query_Limit',
            rflib_GlobalSettings.ARCHIVE_LOG_QUERY_LIMIT_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.archiveLogQueryLimitOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testArchiveAppEventQueryLimit() {
        Integer expectedValue = getConfiguredIntegerValueOrDefault(
            'Archive_App_Event_Query_Limit',
            rflib_GlobalSettings.ARCHIVE_APP_EVENT_QUERY_LIMIT_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.archiveAppEventQueryLimitOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testUseRestQueryModeForPermissionRetrieval() {
        Boolean expectedValue = getConfiguredBooleanValueOrDefault(
            'Permissions_Explorer_REST_API_Enabled',
            rflib_GlobalSettings.PERMISSIONS_EXPLORER_REST_API_ENABLED_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.useRestQueryModeForPermissionRetrievalOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testUseDefaultWorkflowUserForLogEvents() {
        Boolean expectedValue = getConfiguredBooleanValueOrDefault(
            'Use_Default_Workflow_User_for_Log_Events',
            rflib_GlobalSettings.USE_DEFAULT_WORKFLOW_USER_FOR_LOG_EVENTS_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.useDefaultWorkflowUserForLogEventsOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testHttpRequestMockingEnabledOrDefault() {
        Boolean expectedValue = getConfiguredBooleanValueOrDefault(
            'Http_Mocking_Enabled',
            rflib_GlobalSettings.HTTP_REQUEST_MOCKING_ENABLED_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.httpRequestMockingEnabledOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testHttpRequestMockingAllowInProductionOrDefault() {
        Boolean expectedValue = getConfiguredBooleanValueOrDefault(
            'Http_Mocking_Allow_In_Production',
            rflib_GlobalSettings.HTTP_REQUEST_MOCKING_ALLOW_IN_PRODUCTION_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.httpRequestMockingAllowInProductionOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testHttpRequestMockingThrowErrorIfNotMockNotFoundOrDefault() {
        Boolean expectedValue = getConfiguredBooleanValueOrDefault(
            'Http_Mocking_Throw_Error_If_Not_Found',
            rflib_GlobalSettings.HTTP_REQUEST_MOCKING_THROW_ERROR_IF_MOCK_NOT_FOUND_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.httpRequestMockingThrowErrorIfNotMockNotFoundOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testTraceIdModeOrDefault() {
        String expectedValue = getConfiguredStringValueOrDefault(
            'Trace_ID_Value_Format',
            rflib_GlobalSettings.TRACE_ID_VALUE_FORMAT_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.traceIdValueFormatOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testIsDevelopmentModeEnabledOrDefault() {
        Boolean expectedValue = getConfiguredBooleanValueOrDefault(
            'RFLIB_Development_Mode_Enabled',
            rflib_GlobalSettings.RFLIB_DEVELOPMENT_MODE_ENABLED_DEFAULT_VALUE
        );

        Test.startTest();
        System.assertEquals(
            expectedValue,
            rflib_GlobalSettings.isDevelopmentModeEnabled,
            'Expected default value of RFLIB_Development_Mode_Enabled to be FALSE.'
        );
        Test.stopTest();
    }

    private static String getConfiguredStringValueOrDefault(String settingName, String defaultValue) {
        String value = rflib_Global_Setting__mdt.getInstance(settingName)?.Value__c;

        return String.isBlank(value) ? defaultValue : value;
    }

    private static Integer getConfiguredIntegerValueOrDefault(String settingName, Integer defaultValue) {
        String value = rflib_Global_Setting__mdt.getInstance(settingName)?.Value__c;

        return String.isBlank(value) ? defaultValue : Integer.valueOf(value);
    }

    private static Boolean getConfiguredBooleanValueOrDefault(String settingName, Boolean defaultValue) {
        String value = rflib_Global_Setting__mdt.getInstance(settingName)?.Value__c;

        return String.isBlank(value) ? defaultValue : Boolean.valueOf(value);
    }
}
