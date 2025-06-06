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
public class rflib_GlobalSettings {

    @TestVisible
    private static final Integer APPLICATION_EVENT_RETAIN_X_DAYS_DEFAULT_VALUE = 45;

    @TestVisible
    private static final Integer APPLICATION_EVENT_ARCHIVE_RETAIN_X_DAYS_DEFAULT_VALUE = 180;
    
    @TestVisible
    private static final Integer LOG_ARCHIVE_RETAIN_X_DAYS_DEFAULT_VALUE = 180;

    @TestVisible
    private static final Integer ARCHIVE_LOG_QUERY_LIMIT_DEFAULT_VALUE = 50000;
    
    @TestVisible
    private static final Integer ARCHIVE_APP_EVENT_QUERY_LIMIT_DEFAULT_VALUE = 10000;
    
    @TestVisible
    private static final Boolean PERMISSIONS_EXPLORER_REST_API_ENABLED_DEFAULT_VALUE = false;
    
    @TestVisible
    private static final Integer PUBLISH_PLATFORM_EVENT_TRANSACTION_LIMIT_DEFAULT_VALUE = 150;
    
    @TestVisible
    private static final String TRACE_ID_HEADER_NAME_DEFAULT_VALUE = 'X-Trace-ID';
    
    @TestVisible
    private static final String TRACE_ID_VALUE_FORMAT_DEFAULT_VALUE = 'USER18_REQUEST_ID'; 
    
    @TestVisible
    private static final Boolean USE_DEFAULT_WORKFLOW_USER_FOR_LOG_EVENTS_DEFAULT_VALUE = false;    
    
    @TestVisible
    private static final Boolean HTTP_REQUEST_MOCKING_ENABLED_DEFAULT_VALUE = false;    
    
    @TestVisible
    private static final Boolean HTTP_REQUEST_MOCKING_ALLOW_IN_PRODUCTION_DEFAULT_VALUE = false;    
    
    @TestVisible
    private static final Boolean HTTP_REQUEST_MOCKING_THROW_ERROR_IF_MOCK_NOT_FOUND_DEFAULT_VALUE = false; 
    
    @TestVisible
    private static final Boolean RFLIB_DEVELOPMENT_MODE_ENABLED_DEFAULT_VALUE = false;

    @TestVisible
    private static final Boolean APP_EVENT_MASKING_ENABLED_DEFAULT_VALUE = false;

    @TestVisible
    private static final Integer LOG_ARCHIVE_CLEANUP_BATCH_SIZE_DEFAULT_VALUE = 2000;

    @TestVisible
    private static final Integer LOG_ARCHIVE_CLEANUP_QUERY_LIMIT_DEFAULT_VALUE = 50000;

    @TestVisible
    private static final Integer APP_EVENT_ARCHIVE_CLEANUP_BATCH_SIZE_DEFAULT_VALUE = 2000;

    @TestVisible
    private static final Integer APP_EVENT_ARCHIVE_CLEANUP_QUERY_LIMIT_DEFAULT_VALUE = 50000;

    public static Integer daysToRetainApplicationEventsOrDefault {
        get {
            String val = getSetting('Application_Event_Retain_X_Days');
            return String.isBlank(val) ? APPLICATION_EVENT_RETAIN_X_DAYS_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }

    public static Integer daysToRetainApplicationEventArchiveOrDefault {
        get {
            String val = getSetting('Application_Event_Archive_Retain_X_Days');
            return String.isBlank(val) ? APPLICATION_EVENT_ARCHIVE_RETAIN_X_DAYS_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }

    public static Integer daysToRetainArchivedLogsOrDefault {
        get {
            String val = getSetting('Log_Archive_Retain_X_Days');
            return String.isBlank(val) ? LOG_ARCHIVE_RETAIN_X_DAYS_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }
    
    public static Integer archiveLogQueryLimitOrDefault {
        get {
            String val = getSetting('Archive_Log_Query_Limit');
            return String.isBlank(val) ? ARCHIVE_LOG_QUERY_LIMIT_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }

    public static Integer archiveAppEventQueryLimitOrDefault {
        get {
            String val = getSetting('Archive_App_Event_Query_Limit');
            return String.isBlank(val) ? ARCHIVE_APP_EVENT_QUERY_LIMIT_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }

    public static Boolean useRestQueryModeForPermissionRetrievalOrDefault {
        get {
            String val = getSetting('Permissions_Explorer_REST_API_Enabled');
            return String.isBlank(val) ? PERMISSIONS_EXPLORER_REST_API_ENABLED_DEFAULT_VALUE : Boolean.valueOf(val);
        }
    }
        
    public static Integer publishingLimitOrDefault {
        get {
            String val = getSetting('Publish_Platform_Event_Transaction_Limit');
            return String.isBlank(val) ? PUBLISH_PLATFORM_EVENT_TRANSACTION_LIMIT_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }
    
    public static String traceIdHeaderNameOrDefault {
        get {
            String val = getSetting('Trace_ID_Header_Name');
            return String.isBlank(val) ? TRACE_ID_HEADER_NAME_DEFAULT_VALUE : val;
        }
    }

    public static String traceIdValueFormatOrDefault {
        get {
            String val = getSetting('Trace_ID_Value_Format');
            return String.isBlank(val) ? TRACE_ID_VALUE_FORMAT_DEFAULT_VALUE : val;
        }
    }
    
    public static Boolean useDefaultWorkflowUserForLogEventsOrDefault {
        get {
            String val = getSetting('Use_Default_Workflow_User_for_Log_Events');
            return String.isBlank(val) ? USE_DEFAULT_WORKFLOW_USER_FOR_LOG_EVENTS_DEFAULT_VALUE : Boolean.valueOf(val);
        }
    }
    
    public static Boolean httpRequestMockingEnabledOrDefault {
        get {
            String val = getSetting('Http_Mocking_Enabled');
            return String.isBlank(val) ? HTTP_REQUEST_MOCKING_ENABLED_DEFAULT_VALUE : Boolean.valueOf(val);
        }
    }
    
    public static Boolean httpRequestMockingAllowInProductionOrDefault {
        get {
            String val = getSetting('Http_Mocking_Allow_In_Production');
            return String.isBlank(val) ? HTTP_REQUEST_MOCKING_ALLOW_IN_PRODUCTION_DEFAULT_VALUE : Boolean.valueOf(val);
        }
    }
    
    public static Boolean httpRequestMockingThrowErrorIfNotMockNotFoundOrDefault {
        get {
            String val = getSetting('Http_Mocking_Throw_Error_If_Not_Found');
            return String.isBlank(val) ? HTTP_REQUEST_MOCKING_THROW_ERROR_IF_MOCK_NOT_FOUND_DEFAULT_VALUE : Boolean.valueOf(val);
        }
    }

    public static Integer logArchiveCleanupBatchSizeOrDefault {
        get {
            String val = getSetting('Log_Archive_Cleanup_Batch_Size');
            return String.isBlank(val) ? LOG_ARCHIVE_CLEANUP_BATCH_SIZE_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }

    public static Integer logArchiveCleanupQueryLimitOrDefault {
        get {
            String val = getSetting('Log_Archive_Cleanup_Query_Limit');
            return String.isBlank(val) ? LOG_ARCHIVE_CLEANUP_QUERY_LIMIT_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }

    public static Integer appEventArchiveCleanupBatchSizeOrDefault {
        get {
            String val = getSetting('App_Event_Archive_Cleanup_Batch_Size');
            return String.isBlank(val) ? APP_EVENT_ARCHIVE_CLEANUP_BATCH_SIZE_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }

    public static Integer appEventArchiveCleanupQueryLimitOrDefault {
        get {
            String val = getSetting('App_Event_Archive_Cleanup_Query_Limit');
            return String.isBlank(val) ? APP_EVENT_ARCHIVE_CLEANUP_QUERY_LIMIT_DEFAULT_VALUE : Integer.valueOf(val);
        }
    }

    public static Boolean isDevelopmentModeEnabled {
        get {
            String val = getSetting('RFLIB_Development_Mode_Enabled');
            return String.isBlank(val) ? RFLIB_DEVELOPMENT_MODE_ENABLED_DEFAULT_VALUE : Boolean.valueOf(val);
        }
    }

    public static Boolean isApplicationEventMaskingEnabled {
        get {
            String val = getSetting('App_Event_Masking_Enabled');
            return String.isBlank(val) ? APP_EVENT_MASKING_ENABLED_DEFAULT_VALUE : Boolean.valueOf(val);
        }
    }

    @TestVisible
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

    public static void overridePublishingLimitOrDefault(Integer newLimit) {
        if (newLimit < 0 || newLimit > Limits.getLimitPublishImmediateDML()) {
            throw new rflib_InvalidArgumentException('newLimit', 'value provided (' + newLimit + ') is less than 0 or higher than allowed limit: ' + Limits.getPublishImmediateDML());
        }

        String keyName = 'Publish_Platform_Event_Transaction_Limit';
        String newLimitStr = newLimit != null ? String.valueOf(newLimit) : rflib_Global_Setting__mdt.getInstance(keyName)?.Value__c;
        SETTINGS.put(keyName, newLimitStr);
    }
}