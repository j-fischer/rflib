/*
 * Copyright (c) 2023 Johannes Fischer <fischer.jh@gmail.com>
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
 * 3. Neither the name of rflib nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
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
private class rflib_PharosPostProcessingBuilderTest {
    
    @IsTest
    static void testGetPostProcessingSettings() {
        // Setup test data
        setupTestSettings();
        
        // Execute test
        Map<String, Boolean> settings = rflib_PharosPostProcessingBuilder.getPostProcessingSettings();
        
        // Verify results
        System.assertEquals(true, settings.get('auditTrail'));
        System.assertEquals(false, settings.get('deployResult'));
        System.assertEquals(true, settings.get('installedPackages'));
        System.assertEquals(false, settings.get('objectInfo'));
        System.assertEquals(true, settings.get('pendingJobs'));
        System.assertEquals(false, settings.get('relatedObjects'));
        System.assertEquals(true, settings.get('stackTrace'));
        System.assertEquals(false, settings.get('totalActiveSession'));
        System.assertEquals(true, settings.get('userInfo'));
    }
    
    @IsTest
    static void testGetPostProcessingSettingsNoSettings() {
        // Execute test with no settings configured
        Map<String, Boolean> settings = rflib_PharosPostProcessingBuilder.getPostProcessingSettings();
        
        // Verify that default settings were created
        System.assertNotEquals(0, settings.size(), 'Default settings should have been created');
        
        // Verify that settings match the default values
        Map<String, rflib_Pharos_Post_Processing_Setting__c> customSettings = rflib_Pharos_Post_Processing_Setting__c.getAll();
        System.assertNotEquals(0, customSettings.size(), 'Custom settings should have been created');
        
        // Each setting in the map should match its corresponding custom setting
        for (String settingName : settings.keySet()) {
            rflib_Pharos_Post_Processing_Setting__c customSetting = customSettings.get(settingName);
            System.assertNotEquals(null, customSetting, 'Custom setting should exist for ' + settingName);
            System.assertEquals(
                Boolean.valueOf(customSetting.Value__c), 
                settings.get(settingName), 
                'Setting value mismatch for ' + settingName
            );
        }
    }
    
    private static void setupTestSettings() {
        List<rflib_Pharos_Post_Processing_Setting__c> testSettings = new List<rflib_Pharos_Post_Processing_Setting__c>();
        
        // Create alternating true/false values for testing
        testSettings.add(createSetting('auditTrail', 'true'));
        testSettings.add(createSetting('deployResult', 'false'));
        testSettings.add(createSetting('installedPackages', 'true'));
        testSettings.add(createSetting('objectInfo', 'false'));
        testSettings.add(createSetting('pendingJobs', 'true'));
        testSettings.add(createSetting('relatedObjects', 'false'));
        testSettings.add(createSetting('stackTrace', 'true'));
        testSettings.add(createSetting('totalActiveSession', 'false'));
        testSettings.add(createSetting('userInfo', 'true'));
        
        insert testSettings;
    }
    
    private static rflib_Pharos_Post_Processing_Setting__c createSetting(String name, String value) {
        rflib_Pharos_Post_Processing_Setting__c setting = new rflib_Pharos_Post_Processing_Setting__c();
        setting.Name = name;
        setting.Value__c = value;
        return setting;
    }
}