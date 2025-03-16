rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
    'rflib_Logs_Archive__b',
    'rflib_Big_Object_Stat__c',
    'Record_Count__c',
    0,
    null,
    null,
    100,
    new String[]{'CreatedDate__c','Context__c','Log_Level__c','Request_ID__c'},
    'ASC'
);

Database.executeBatch(counter, 50);