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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_CustomSettingsEditorControllerTest {
    
    private static final String TEST_CUSTOM_SETTINGS_API_NAME = 'rflib_Logger_Settings__c';
    
    private static final User ADMIN_USER = rflib_TestUserFactory.insertAndRetrieve('Alice', 'Admin', 'System Administrator');
    private static final User STANDARD_USER = rflib_TestUserFactory.insertAndRetrieve('Bob', 'Viewer', 'Standard User');
    
    private static void setupTestData() {
        List<rflib_Logger_Settings__c> customSettingRecords = new List<rflib_Logger_Settings__c>();
        
        customSettingRecords.add(new rflib_Logger_Settings__c(
            SetupOwnerId = ADMIN_USER.Id,
            Name = 'LoggerSetting1',
            Log_Size__c = 100
        ));
        
        customSettingRecords.add(new rflib_Logger_Settings__c(
            SetupOwnerId = STANDARD_USER.Id,
            Name = 'LoggerSetting2',
            Log_Size__c = 200
        ));
        
        insert customSettingRecords;
    }
    
    private static Boolean listContains(List<rflib_CustomSettingsEditorController.CustomSettingWrapper> listToCheck, String recordId) {
        for (rflib_CustomSettingsEditorController.CustomSettingWrapper wrapper : listToCheck) {
            if (wrapper.id == recordId) {
                return true;
            }
        }
        return false;
    }
    
    @IsTest
    private static void testGetCustomSettingLabel_Success() {
        setupTestData();
        
        Test.startTest();
        String label = rflib_CustomSettingsEditorController.getCustomSettingLabel(TEST_CUSTOM_SETTINGS_API_NAME);
        Test.stopTest();
        
        Assert.areEqual(rflib_Logger_Settings__c.SObjectType.getDescribe().getLabel(), label, 'The label should match the Custom Setting label.');
    }
    
    @IsTest
    private static void testGetCustomSettingLabel_NonExistent() {
        Test.startTest();
        try {
            rflib_CustomSettingsEditorController.getCustomSettingLabel('NonExistentCustomSetting__c');
            Assert.fail('Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('does not exist'), 'Exception message should indicate non-existence.');
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testCanUserModifyCustomSettings_WithPermissions() {
        setupTestData();
        
        Boolean canModify;
        Test.startTest();
        System.runAs(ADMIN_USER) {
            canModify = rflib_CustomSettingsEditorController.canUserModifyCustomSettings(TEST_CUSTOM_SETTINGS_API_NAME);
        }
        Test.stopTest();
        
        Assert.isTrue(canModify, 'User with edit permissions should be able to modify Custom Settings.');
    }
    
    @IsTest
    private static void testGetCustomSettings_Success() {
        setupTestData();
        
        Test.startTest();
        List<rflib_CustomSettingsEditorController.CustomSettingWrapper> settings = rflib_CustomSettingsEditorController.getCustomSettings(TEST_CUSTOM_SETTINGS_API_NAME);
        Test.stopTest();
        
        Assert.areEqual(2, settings.size(), 'There should be 2 Custom Setting records.');
    }
    
    @IsTest
    private static void testGetCustomSettings_NonExistent() {
        Test.startTest();
        try {
            rflib_CustomSettingsEditorController.getCustomSettings('NonExistentCustomSetting__c');
            Assert.fail('Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('does not exist'), 'Exception message should indicate non-existence.');
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testGetCustomSettingFields_Success() {
        setupTestData();
        
        Test.startTest();
        List<rflib_CustomSettingsEditorController.FieldInfoWrapper> fields = rflib_CustomSettingsEditorController.getCustomSettingFields(TEST_CUSTOM_SETTINGS_API_NAME);
        Test.stopTest();
        
        Assert.isTrue(fields.size() > 0, 'There should be at least one field in the Custom Setting.');
    }
    
    @IsTest
    private static void testGetCustomSettingFields_NonExistent() {
        Test.startTest();
        try {
            rflib_CustomSettingsEditorController.getCustomSettingFields('NonExistentCustomSetting__c');
            Assert.fail('Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('does not exist'), 'Exception message should indicate non-existence.');
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testDeleteCustomSettingRecord_Success() {
        setupTestData();
        
        Test.startTest();
        List<rflib_Logger_Settings__c> settings = [SELECT Id FROM rflib_Logger_Settings__c LIMIT 1];
        String recordId = settings[0].Id;
        
        rflib_CustomSettingsEditorController.deleteCustomSettingRecord(TEST_CUSTOM_SETTINGS_API_NAME, recordId);
        Test.stopTest();
        
        List<rflib_Logger_Settings__c> remaining = [SELECT Id FROM rflib_Logger_Settings__c WHERE Id = :recordId];
        Assert.areEqual(0, remaining.size(), 'The Custom Setting record should be deleted.');
    }
    
    @IsTest
    private static void testDeleteCustomSettingRecord_NonExistentRecordId() {
        setupTestData();
        
        Test.startTest();
        try {
            rflib_CustomSettingsEditorController.deleteCustomSettingRecord(TEST_CUSTOM_SETTINGS_API_NAME, 'a0B000000000001');
            Assert.fail('Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Invalid id'), 'Exception message should indicate invalid record, actual message: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testSaveCustomSetting_Insert() {
        setupTestData();
        
        rflib_Logger_Settings__c newSetting = new rflib_Logger_Settings__c(
            Name = 'LoggerSetting3',
            Log_Size__c = 300
        );
        
        Test.startTest();
        rflib_CustomSettingsEditorController.saveCustomSetting(newSetting);
        Test.stopTest();
        
        rflib_Logger_Settings__c insertedSetting = [SELECT Id, Name, Log_Size__c FROM rflib_Logger_Settings__c WHERE Name = 'LoggerSetting3' LIMIT 1];
        Assert.areNotEqual(null, insertedSetting.Id, 'The Custom Setting record should be inserted.');
        Assert.areEqual(300, insertedSetting.Log_Size__c, 'The Log_Size__c field should match the inserted value.');
    }
    
    @IsTest
    private static void testSaveCustomSetting_Update() {
        setupTestData();
        
        rflib_Logger_Settings__c existingSetting = [SELECT Id, Name, Log_Size__c FROM rflib_Logger_Settings__c LIMIT 1];
        existingSetting.Log_Size__c = 150;
        
        Test.startTest();
        rflib_CustomSettingsEditorController.saveCustomSetting(existingSetting);
        Test.stopTest();
        
        rflib_Logger_Settings__c updatedSetting = [SELECT Id, Name, Log_Size__c FROM rflib_Logger_Settings__c WHERE Id = :existingSetting.Id LIMIT 1];
        Assert.areEqual(150, updatedSetting.Log_Size__c, 'The Log_Size__c field should be updated.');
    }
    
    @IsTest
    private static void testSaveCustomSetting_NullRecord() {
        Test.startTest();
        try {
            rflib_CustomSettingsEditorController.saveCustomSetting(null);
            Assert.fail('Expected AuraHandledException was not thrown for null record.');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('cannot be null'), 'Exception message should indicate null record.');
        }
        Test.stopTest();
    }
}
