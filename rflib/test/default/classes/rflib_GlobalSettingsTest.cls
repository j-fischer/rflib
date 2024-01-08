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
        String expectedValue = rflib_Global_Setting__mdt.getInstance('Trace_ID_Header_Name').Value__c;

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.traceIdHeaderNameOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testPublishingLimitOrDefault() {
        Integer expectedValue = Integer.valueOf(rflib_Global_Setting__mdt.getInstance('Publish_Platform_Event_Transaction_Limit').Value__c);

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.publishingLimitOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testOverridePublishingLimitOrDefault_Success() {
        Integer expectedValue = Integer.valueOf(rflib_Global_Setting__mdt.getInstance('Publish_Platform_Event_Transaction_Limit').Value__c);

        Test.startTest();
        rflib_GlobalSettings.overridePublishingLimitOrDefault(5);
        System.assertEquals(5, rflib_GlobalSettings.publishingLimitOrDefault);
        Test.stopTest();
    }


    @IsTest
    static void testOverridePublishingLimitOrDefault_NullValue() {
        Integer expectedValue = Integer.valueOf(rflib_Global_Setting__mdt.getInstance('Publish_Platform_Event_Transaction_Limit').Value__c);

        Test.startTest();
        rflib_GlobalSettings.overridePublishingLimitOrDefault(0);
        System.assertEquals(0, rflib_GlobalSettings.publishingLimitOrDefault);
        
        rflib_GlobalSettings.overridePublishingLimitOrDefault(null);
        System.assertEquals(expectedValue, rflib_GlobalSettings.publishingLimitOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testOverridePublishingLimitOrDefault_ValueExceedsLimit() {
        Integer expectedValue = Integer.valueOf(rflib_Global_Setting__mdt.getInstance('Publish_Platform_Event_Transaction_Limit').Value__c);

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
        Integer expectedValue = Integer.valueOf(rflib_Global_Setting__mdt.getInstance('Application_Event_Retain_X_Days').Value__c);

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.daysToRetainApplicationEventsOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testArchiveLogQueryLimit() {
        Integer expectedValue = Integer.valueOf(rflib_Global_Setting__mdt.getInstance('Archive_Log_Query_Limit').Value__c);

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.archiveLogQueryLimitOrDefault);
        Test.stopTest();
    }

    @IsTest
    static void testUseRestQueryModeForPermissionRetrieval() {
        Boolean expectedValue = Boolean.valueOf(rflib_Global_Setting__mdt.getInstance('Permissions_Explorer_REST_API_Enabled').Value__c);

        Test.startTest();
        System.assertEquals(expectedValue, rflib_GlobalSettings.useRestQueryModeForPermissionRetrievalOrDefault);
        Test.stopTest();
    }
}
