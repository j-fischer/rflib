rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
settings.Client_Console_Log_Level__c = 'DEBUG';
settings.Log_Event_Reporting_Level__c = 'INFO';
settings.Archive_Log_Level__c = 'INFO';

// The Log Aggregation and Google Chat fields were added in newer RFLIB core releases. When this
// shared setup script runs against an org whose installed RFLIB core predates them (e.g. an older
// version pulled in as a dependency by RFLIB-FS/RFLIB-TF), the fields are absent. Set them via
// dynamic field access so the script skips them instead of failing to compile.
Map<String, Schema.SObjectField> loggerSettingsFields = rflib_Logger_Settings__c.getSObjectType()
    .getDescribe()
    .fields.getMap();

if (loggerSettingsFields.containsKey('log_aggregation_log_level__c')) {
    settings.put('Log_Aggregation_Log_Level__c', 'WARN');
}

// Required fields; records created before the field was introduced may hold null.
for (String requiredLevelField : new List<String>{
    'google_chat_log_level__c',
    'pharos_log_level__c',
    'slack_log_level__c',
    'teams_log_level__c'
}) {
    if (loggerSettingsFields.containsKey(requiredLevelField) && settings.get(requiredLevelField) == null) {
        settings.put(requiredLevelField, 'NONE');
    }
}

upsert settings;