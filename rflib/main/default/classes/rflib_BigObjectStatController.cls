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
    public static void refreshStats(String bigObjectName, List<String> indexFields, String orderBy) {
        try {
            LOGGER.info('Refreshing stats for {0} with index fields {1}', 
                new Object[] { bigObjectName, indexFields });

            Database.executeBatch(new rflib_BigObjectCounter(
                bigObjectName,
                'rflib_Big_Object_Stat__c',
                'Record_Count__c',
                0,
                null,
                null,
                50000,
                indexFields,
                orderBy
            ));
        } catch (Exception ex) {
            LOGGER.error('Failed to refresh stats for ' + bigObjectName, ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<FieldMetadata> getFieldMetadata(String fields) {
        try {
            LOGGER.debug('Getting field metadata for fields: {0}', new Object[] { fields });
            
            List<FieldMetadata> metadata = new List<FieldMetadata>();
            SObjectType statType = rflib_Big_Object_Stat__c.SObjectType;
            Map<String, Schema.SObjectField> fieldMap = statType.getDescribe().fields.getMap();
            
            metadata.add(new FieldMetadata('Name', 'Name', 'Big Object Name', 'text'));
            
            for (String field : fields.split(',')) {
                field = field.trim();
                Schema.DescribeFieldResult describe = fieldMap.get(field).getDescribe();
                
                String fieldType = mapFieldType(describe);
                metadata.add(new FieldMetadata(
                    describe.getName(),
                    describe.getName(),
                    describe.getLabel(),
                    fieldType
                ));
            }
            
            return metadata;
        } catch (Exception ex) {
            LOGGER.error('Failed to get field metadata', ex);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    private static String mapFieldType(Schema.DescribeFieldResult field) {
        switch on field.getType() {
            when CURRENCY {
                return 'currency';
            }
            when DATETIME {
                return 'date';
            }
            when PERCENT {
                return 'percent';
            }
            when PHONE {
                return 'phone';
            }
            when URL {
                return 'url';
            }
            when INTEGER, DOUBLE, LONG {
                return 'number';
            }
            when else {
                return 'text';
            }
        }
    }
    
    public class FieldMetadata {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        
        public FieldMetadata(String fieldName, String apiName, String label, String type) {
            this.fieldName = fieldName;
            this.apiName = apiName;
            this.label = label;
            this.type = type;
        }
    }
}
