rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
settings.Client_Console_Log_Level__c = 'DEBUG';
settings.Log_Event_Reporting_Level__c = 'INFO';
settings.Archive_Log_Level__c = 'INFO';
settings.Log_Aggregation_Log_Level__c = 'WARN';

// Required field; records created before the field was introduced may hold null.
if (settings.Google_Chat_Log_Level__c == null) {
    settings.Google_Chat_Log_Level__c = 'NONE';
}

upsert settings;