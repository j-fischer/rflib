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
public with sharing class rflib_PharosPostInstallHandler implements InstallHandler {
    
    /**
     * Implements the InstallHandler interface to create default post-processing settings
     * if they don't already exist.
     */
    public void onInstall(InstallContext context) {
        createDefaultSettings();
    }
    
    /**
     * Creates default settings for Pharos post-processing if they don't already exist.
     * All settings are initialized with 'true' to enable all post-processing by default.
     */
    public void createDefaultSettings() {
        Map<String, rflib_Pharos_Post_Processing_Setting__c> existingSettings = rflib_Pharos_Post_Processing_Setting__c.getAll();
        List<rflib_Pharos_Post_Processing_Setting__c> settingsToInsert = new List<rflib_Pharos_Post_Processing_Setting__c>();
        
        // Define default settings
        Map<String, String> defaultSettings = new Map<String, String> {
            'auditTrail' => 'false',
            'deployResult' => 'true',
            'installedPackages' => 'true',
            'objectInfo' => 'false',
            'pendingJobs' => 'true',
            'relatedObjects' => 'false',
            'stackTrace' => 'true',
            'totalActiveSession' => 'true',
            'userInfo' => 'true'
        };
        
        // Check and create each setting if it doesn't exist
        for (String settingName : defaultSettings.keySet()) {
            if (!existingSettings.containsKey(settingName)) {
                settingsToInsert.add(createSetting(settingName, defaultSettings.get(settingName)));
            }
        }
        
        // Insert all new settings
        if (!settingsToInsert.isEmpty()) {
            insert settingsToInsert;
        }
    }
    
    /**
     * Helper method to create a new post-processing setting.
     */
    private rflib_Pharos_Post_Processing_Setting__c createSetting(String name, String value) {
        rflib_Pharos_Post_Processing_Setting__c setting = new rflib_Pharos_Post_Processing_Setting__c();
        setting.Name = name;
        setting.Value__c = value;
        return setting;
    }
}