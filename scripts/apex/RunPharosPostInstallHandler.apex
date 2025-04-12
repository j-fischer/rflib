new rflib_PharosPostInstallHandler().createDefaultSettings();

rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
settings.Pharos_Log_Level__c = 'WARN';

upsert settings;