rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
settings.Client_Console_Log_Level__c = 'DEBUG';
settings.Log_Event_Reporting_Level__c = 'INFO';
settings.Archive_Log_Level__c = 'INFO';
settings.Observability_Log_Level__c = 'WARN';

upsert settings;