public with sharing class rflib_BigObjectStatController {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_BigObjectStatController');
    
    @AuraEnabled(cacheable=true)
    public static List<rflib_Big_Object_Stat__c> getStats(String bigObjects, String fields) {
        try {
            LOGGER.info('Retrieving big object stats for {0}', new Object[] { bigObjects });

            Set<String> bigObjectSet = new Set<String>(bigObjects.split(','));
            List<String> fieldList = new List<String>{ 'Id', 'Name' };
            fieldList.addAll(fields.split(','));
            
            return rflib_SOQL.of(rflib_Big_Object_Stat__c.SObjectType)
                .with(fieldList)
                .whereAre(rflib_SOQL.Filter.with('Name').isIn(bigObjectSet))
                .systemMode()
                .toList();
                
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve big object stats', ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void refreshStats(String bigObjectName) {
        try {
            LOGGER.info('Refreshing stats for {0}', new Object[] { bigObjectName });

            String query = 'SELECT Id FROM ' + bigObjectName;
            Database.executeBatch(new rflib_BigObjectCounter(
                query,
                bigObjectName,
                'rflib_Big_Object_Stat__c',
                'Record_Count__c',
                0
            ));
        } catch (Exception ex) {
            LOGGER.error('Failed to refresh stats for ' + bigObjectName, ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
