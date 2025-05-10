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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_SaveAppEventOccurrenceActionTest {
    
    @isTest
    static void testSaveApplicationEvent_success() {
        // Create test event
        rflib_Application_Event_Occurred_Event__e testEvent = new rflib_Application_Event_Occurred_Event__e(
            Event_Name__c = 'Test Event',
            Occurred_On__c = DateTime.now(),
            Related_Record_ID__c = '001000000000001',
            Additional_Details__c = 'Test Details',
            Created_By_ID__c = UserInfo.getUserId()
        );
        
        Test.startTest();
        rflib_SaveAppEventOccurrenceAction.saveApplicationEvent(new List<rflib_Application_Event_Occurred_Event__e>{ testEvent });
        Test.stopTest();
        
        // Verify event was saved
        List<rflib_Application_Event__c> savedEvents = [
            SELECT Id, Event_Name__c, Related_Record_ID__c, Additional_Details__c, Created_By_ID__c
            FROM rflib_Application_Event__c
        ];
        
        Assert.areEqual(1, savedEvents.size(), 'Expected one event to be saved');
        rflib_Application_Event__c savedEvent = savedEvents[0];
        Assert.areEqual('Test Event', savedEvent.Event_Name__c);
        Assert.areEqual('001000000000001', savedEvent.Related_Record_ID__c);
        Assert.areEqual('Test Details', savedEvent.Additional_Details__c);
        Assert.areEqual(UserInfo.getUserId(), savedEvent.Created_By_ID__c);
    }
    
    @isTest
    static void testSaveApplicationEvent_withMasking_Enabled() {
        // Enable masking setting
        rflib_GlobalSettings.SETTINGS.put('App_Event_Masking_Enabled', 'true');

        // Set up masking rules
        rflib_Masking_Rule__mdt testRule = new rflib_Masking_Rule__mdt(
            DeveloperName = 'Test_Masking_Rule',
            MasterLabel = 'Test Masking Rule',
            Is_Active__c = true,
            Target__c = 'SENSITIVE_DATA',
            Target_Type__c = 'RegEx',
            Replacement__c = 'MASKED_VALUE',
            Order__c = 1
        );

        rflib_StringUtil.allActiveMaskingRules = new List<rflib_Masking_Rule__mdt>{ testRule };

        // Create test event with sensitive data
        rflib_Application_Event_Occurred_Event__e testEvent = new rflib_Application_Event_Occurred_Event__e(
            Event_Name__c = 'Test Event',
            Occurred_On__c = DateTime.now(),
            Related_Record_ID__c = '001000000000001',
            Additional_Details__c = 'This contains SENSITIVE_DATA that should be masked',
            Created_By_ID__c = UserInfo.getUserId()
        );

        Test.startTest();
        rflib_SaveAppEventOccurrenceAction.saveApplicationEvent(new List<rflib_Application_Event_Occurred_Event__e>{ testEvent });
        Test.stopTest();

        // Verify event was saved with masked data
        List<rflib_Application_Event__c> savedEvents = [
            SELECT Id, Event_Name__c, Related_Record_ID__c, Additional_Details__c, Created_By_ID__c
            FROM rflib_Application_Event__c
        ];

        Assert.areEqual(1, savedEvents.size(), 'Expected one event to be saved');
        rflib_Application_Event__c savedEvent = savedEvents[0];

        // Verify masking was applied
        String expectedMaskedDetails = 'This contains MASKED_VALUE that should be masked';
        Assert.areEqual(expectedMaskedDetails, savedEvent.Additional_Details__c, 'The sensitive data should be masked');
    }

    @isTest
    static void testSaveApplicationEvent_withMasking_Disabled() {
        // Ensure masking setting is disabled
        rflib_GlobalSettings.SETTINGS.put('App_Event_Masking_Enabled', 'false');

        // Set up masking rules
        rflib_Masking_Rule__mdt testRule = new rflib_Masking_Rule__mdt(
            DeveloperName = 'Test_Masking_Rule',
            MasterLabel = 'Test Masking Rule',
            Is_Active__c = true,
            Target__c = 'SENSITIVE_DATA',
            Target_Type__c = 'RegEx',
            Replacement__c = 'MASKED_VALUE',
            Order__c = 1
        );

        rflib_StringUtil.allActiveMaskingRules = new List<rflib_Masking_Rule__mdt>{ testRule };

        // Create test event with sensitive data
        rflib_Application_Event_Occurred_Event__e testEvent = new rflib_Application_Event_Occurred_Event__e(
            Event_Name__c = 'Test Event',
            Occurred_On__c = DateTime.now(),
            Related_Record_ID__c = '001000000000001',
            Additional_Details__c = 'This contains SENSITIVE_DATA that should be masked',
            Created_By_ID__c = UserInfo.getUserId()
        );

        Test.startTest();
        rflib_SaveAppEventOccurrenceAction.saveApplicationEvent(new List<rflib_Application_Event_Occurred_Event__e>{ testEvent });
        Test.stopTest();

        // Verify event was saved with unmasked data
        List<rflib_Application_Event__c> savedEvents = [
            SELECT Id, Event_Name__c, Related_Record_ID__c, Additional_Details__c, Created_By_ID__c
            FROM rflib_Application_Event__c
        ];

        Assert.areEqual(1, savedEvents.size(), 'Expected one event to be saved');
        rflib_Application_Event__c savedEvent = savedEvents[0];

        // Verify masking was NOT applied
        String expectedDetails = 'This contains SENSITIVE_DATA that should be masked';
        Assert.areEqual(expectedDetails, savedEvent.Additional_Details__c, 'The sensitive data should not be masked when setting is disabled');
    }
    
    @isTest
    static void testSaveApplicationEvent_withLongMaskedDetails() {
        // Enable masking setting
        rflib_GlobalSettings.SETTINGS.put('App_Event_Masking_Enabled', 'true');

        // Create a masking rule that increases the length of content
        rflib_Masking_Rule__mdt testRule = new rflib_Masking_Rule__mdt(
            DeveloperName = 'Expansion_Rule',
            MasterLabel = 'Expansion Rule',
            Is_Active__c = true,
            Target__c = 'short',
            Target_Type__c = 'RegEx',
            Replacement__c = 'this is a much longer replacement text',
            Order__c = 1
        );

        rflib_StringUtil.allActiveMaskingRules = new List<rflib_Masking_Rule__mdt>{ testRule };
        
        // Create a string that when masked would exceed the max length
        String baseText = 'short ';
        String longText = '';
        
        // Build a string that, when masking replaces "short" with the longer text,
        // would exceed MAX_ADDITIONAL_DETAIL_SIZE (32768)
        Integer repetitions = (rflib_DefaultApplicationEventService.MAX_ADDITIONAL_DETAIL_SIZE / baseText.length()) + 100;
        for (Integer i = 0; i < repetitions; i++) {
            longText += baseText;
        }
        
        // Create test event with text that will expand when masked
        rflib_Application_Event_Occurred_Event__e testEvent = new rflib_Application_Event_Occurred_Event__e(
            Event_Name__c = 'Test Event',
            Occurred_On__c = DateTime.now(),
            Related_Record_ID__c = '001000000000001',
            Additional_Details__c = longText,
            Created_By_ID__c = UserInfo.getUserId()
        );
        
        Test.startTest();
        rflib_SaveAppEventOccurrenceAction.saveApplicationEvent(new List<rflib_Application_Event_Occurred_Event__e>{ testEvent });
        Test.stopTest();
        
        // Verify event was saved with truncated details
        List<rflib_Application_Event__c> savedEvents = [
            SELECT Id, Additional_Details__c
            FROM rflib_Application_Event__c
        ];
        
        Assert.areEqual(1, savedEvents.size(), 'Expected one event to be saved');
        rflib_Application_Event__c savedEvent = savedEvents[0];
        
        // Verify the length doesn't exceed MAX_ADDITIONAL_DETAIL_SIZE
        Assert.isTrue(savedEvent.Additional_Details__c.length() <= rflib_DefaultApplicationEventService.MAX_ADDITIONAL_DETAIL_SIZE, 
            'Masked text should be truncated to max length');
    }
}