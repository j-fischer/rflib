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

/**
 * @group Common
 * @description Provides values for any rflib related global settings.
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_GlobalSettings {
    
    public static Integer daysToRetainApplicationEvents {
        get {
            String val = getSetting('Application_Event_Retain_X_Days');
            return val == null ? null : Integer.valueOf(val);
        }
    }
    
    public static Integer archiveLogQueryLimit {
        get {
            String val = getSetting('Archive_Log_Query_Limit');
            return val == null ? null : Integer.valueOf(val);
        }
    }

    public static Boolean useRestQueryModeForPermissionRetrieval {
        get {
            String val = getSetting('Permissions_Explorer_REST_API_Enabled');
            return val == null ? false : Boolean.valueOf(val);
        }
    }
        
    public static Integer publishingLimit {
        get {
            String val = getSetting('Publish_Platform_Event_Transaction_Limit');
            return val == null ? null : Integer.valueOf(val);
        }
    }
    
    public static String traceIdHeaderName {
        get {
            return getSetting('Trace_ID_Header_Name');
        }
    }
    
    public static Boolean useOrgWideEmailAddress {
        get {
            String val = getSetting('Use_Org_Wide_Email_Address');
            return val == null ? true : Boolean.valueOf(val);
        }
    }

    private static final Map<String, String> SETTINGS = new Map<String, String>();

    @SuppressWarnings('PMD.EmptyStatementBlock')
    private rflib_GlobalSettings() { }

    private static String getSetting(String name) {
        if (SETTINGS.isEmpty()) {
            for (rflib_Global_Setting__mdt setting : rflib_Global_Setting__mdt.getAll().values()) {
                SETTINGS.put(setting.DeveloperName, setting.Value__c);
            }
        }

        return SETTINGS.get(name);
    }

    public static void overridePublishingLimit(Integer newLimit) {
        if (newLimit < 0 || newLimit > Limits.getLimitPublishImmediateDML()) {
            throw new rflib_InvalidArgumentException('newLimit', 'value provided (' + newLimit + ') is less than 0 or higher than allowed limit: ' + Limits.getPublishImmediateDML());
        }

        String newLimitStr = newLimit != null ? String.valueOf(newLimit) : rflib_Global_Setting__mdt.getInstance('Publish_Platform_Event_Transaction_Limit').Value__c;
        SETTINGS.put('Publish_Platform_Event_Transaction_Limit', newLimitStr);
    }
}