/*
 * Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
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
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_BigObjectStatController {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_BigObjectStatController');
    
    @AuraEnabled(cacheable=true)
    public static List<rflib_Big_Object_Stat__c> getStats(String bigObjects, String fields) {
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'Retrieving big object stats for {0}', new Object[] { bigObjects });

            Set<String> bigObjectSet = new Set<String>(bigObjects.split(','));
            List<String> fieldList = new List<String>{ 'Id', 'Name' };
            fieldList.addAll(fields.split(','));
            
            return rflib_SOQL.of(rflib_Big_Object_Stat__c.SObjectType)
                .with(fieldList)
                .whereAre(rflib_SOQL.Filter.with('Name').isIn(bigObjectSet))
                .systemMode()
                .mockId('rflib_BigObjectStatController.getStats')
                .toList();
                
        } catch (Exception ex) {
            LOGGER.error('Failed to retrieve big object stats', ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void refreshStats(String bigObjectName, List<String> indexFields, String orderBy) {
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'Refreshing stats for {0} with index fields {1} order by {2}', 
                new Object[] { bigObjectName, indexFields, orderBy });

            Id jobId = Database.executeBatch(new rflib_BigObjectCounter(
                bigObjectName,
                'rflib_Big_Object_Stat__c',
                'Record_Count__c',
                0,
                null,
                null,
                50000,
                indexFields,
                orderBy
            ), 2000);

            rflib_LoggerUtil.logInternal(LOGGER, 'Job ID: {0}', new Object[] { jobId });
        } catch (Exception ex) {
            LOGGER.error('Failed to refresh stats for ' + bigObjectName, ex);
            throw rflib_ControllerUtil.createAuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<FieldMetadata> getFieldMetadata(String fields) {
        try {
            rflib_LoggerUtil.logInternal(LOGGER, 'Getting field metadata for fields: {0}', new Object[] { fields });
            
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
            throw rflib_ControllerUtil.createAuraHandledException('Failed to get field metadata: ' + ex.getMessage());
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
