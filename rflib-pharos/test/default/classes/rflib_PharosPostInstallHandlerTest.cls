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
private class rflib_PharosPostInstallHandlerTest {
    
    @IsTest
    static void testPostInstallHandlerCreatesSettings() {
        // Verify no settings exist before install
        Map<String, rflib_Pharos_Post_Processing_Setting__c> preInstallSettings = rflib_Pharos_Post_Processing_Setting__c.getAll();
        System.assertEquals(0, preInstallSettings.size());
        
        // Execute install handler
        Test.startTest();
        rflib_PharosPostInstallHandler installHandler = new rflib_PharosPostInstallHandler();
        installHandler.onInstall(null); // InstallContext is null for testing
        Test.stopTest();
        
        // Verify settings were created
        Map<String, rflib_Pharos_Post_Processing_Setting__c> postInstallSettings = rflib_Pharos_Post_Processing_Setting__c.getAll();
        System.assertEquals(9, postInstallSettings.size());
        
        // Verify all settings exist with default value 'true'
        System.assertEquals('true', postInstallSettings.get('auditTrail').Value__c);
        System.assertEquals('true', postInstallSettings.get('deployResult').Value__c);
        System.assertEquals('true', postInstallSettings.get('installedPackages').Value__c);
        System.assertEquals('true', postInstallSettings.get('objectInfo').Value__c);
        System.assertEquals('true', postInstallSettings.get('pendingJobs').Value__c);
        System.assertEquals('true', postInstallSettings.get('relatedObjects').Value__c);
        System.assertEquals('true', postInstallSettings.get('stackTrace').Value__c);
        System.assertEquals('true', postInstallSettings.get('totalActiveSession').Value__c);
        System.assertEquals('true', postInstallSettings.get('userInfo').Value__c);
    }
    
    @IsTest
    static void testPostInstallHandlerPreservesExistingSettings() {
        // Create some existing settings with custom values
        rflib_Pharos_Post_Processing_Setting__c existingSetting = new rflib_Pharos_Post_Processing_Setting__c(
            Name = 'auditTrail', 
            Value__c = 'false'
        );
        insert existingSetting;
        
        // Execute install handler
        Test.startTest();
        rflib_PharosPostInstallHandler installHandler = new rflib_PharosPostInstallHandler();
        installHandler.onInstall(null);
        Test.stopTest();
        
        // Verify existing setting was preserved
        Map<String, rflib_Pharos_Post_Processing_Setting__c> postInstallSettings = rflib_Pharos_Post_Processing_Setting__c.getAll();
        System.assertEquals('false', postInstallSettings.get('auditTrail').Value__c);
        
        // Verify other settings were created
        System.assertEquals(9, postInstallSettings.size());
    }
}