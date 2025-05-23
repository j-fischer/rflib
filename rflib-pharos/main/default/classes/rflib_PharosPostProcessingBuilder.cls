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
public with sharing class rflib_PharosPostProcessingBuilder {
    
    /**
     * Returns a map of post-processing settings based on the configuration stored in the custom settings.
     * This map will be used in the rflib_PharosLogAction to set the pharos__Post_Processing_Settings__c field.
     * 
     * @return Map<String, Boolean> containing the post-processing settings.
     */
    public static Map<String, Boolean> getPostProcessingSettings() {
        Map<String, Boolean> postProcessingSettings = new Map<String, Boolean>();
        Map<String, rflib_Pharos_Post_Processing_Setting__c> settings = rflib_Pharos_Post_Processing_Setting__c.getAll();
        
        // Add all keys from custom settings with their boolean values
        for (String settingName : settings.keySet()) {
            rflib_Pharos_Post_Processing_Setting__c setting = settings.get(settingName);
            postProcessingSettings.put(settingName, Boolean.valueOf(setting.Value__c));
        }
        
        return postProcessingSettings;
    }
}