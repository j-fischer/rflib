/*
 * Copyright (c) 2024 Johannes Fischer
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
public with sharing class rflib_CustomSettingsEditorController {
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory()
        .createLogger('rflib_CustomSettingsEditorController');

    @AuraEnabled(cacheable=true)
    public static String getCustomSettingLabel(String customSettingsApiName) {
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(customSettingsApiName);
        if (sObjectType != null) {
            DescribeSObjectResult describeResult = sObjectType.getDescribe();
            return describeResult.getLabel();
        } else {
            throw new AuraHandledException(
                'Custom Setting with API Name ' + customSettingsApiName + ' does not exist.'
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean canUserModifyLoggerSettings(String customSettingsApiName) {
        try {
            LOGGER.info('canUserModifyLoggerSettings({0}) invoked', new List<Object>{ customSettingsApiName });
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            if (!schemaMap.containsKey(customSettingsApiName)) {
                LOGGER.error(
                    'Custom Setting with API Name {0} does not exist.',
                    new List<Object>{ customSettingsApiName }
                );
                throw new AuraHandledException(
                    'Custom Setting with API Name ' + customSettingsApiName + ' does not exist.'
                );
            }

            Schema.SObjectType customSettingType = schemaMap.get(customSettingsApiName);
            Boolean isUpdateable = customSettingType.getDescribe().isUpdateable();
            LOGGER.info('Custom Setting is updateable: {0}', new List<Object>{ isUpdateable });

            return isUpdateable;
        } catch (Exception ex) {
            LOGGER.error('Error in canUserModifyLoggerSettings: {0}', new List<Object>{ ex.getMessage() });
            throw new AuraHandledException('An error occurred while checking user permissions: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<CustomSettingWrapper> getCustomSettings(String customSettingsApiName) {
        try {
            LOGGER.info('getCustomSettings({0}) invoked', new List<Object>{ customSettingsApiName });

            if (String.isBlank(customSettingsApiName)) {
                LOGGER.error('Custom Settings API Name cannot be empty.');
                throw new AuraHandledException('Custom Settings API Name cannot be empty.');
            }

            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            if (!schemaMap.containsKey(customSettingsApiName)) {
                LOGGER.error(
                    'Custom Setting with API Name {0} does not exist.',
                    new List<Object>{ customSettingsApiName }
                );
                throw new AuraHandledException(
                    'Custom Setting with API Name ' + customSettingsApiName + ' does not exist.'
                );
            }

            Schema.SObjectType customSettingType = schemaMap.get(customSettingsApiName);
            DescribeSObjectResult describeResult = customSettingType.getDescribe();

            if (!describeResult.isCustomSetting()) {
                LOGGER.error('The provided API Name does not belong to a Custom Setting.');
                throw new AuraHandledException('The provided API Name does not belong to a Custom Setting.');
            }

            String query = 'SELECT Id, SetupOwnerId, SetupOwner.Type, SetupOwner.Name, ';
            List<String> fieldNames = new List<String>();

            for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
                String fieldName = field.getDescribe().getName();
                if (fieldName != 'Id' && fieldName != 'SetupOwnerId') {
                    fieldNames.add(fieldName);
                }
            }

            query += String.join(fieldNames, ', ') + ' FROM ' + customSettingsApiName;

            LOGGER.info('Executing query: {0}', new List<Object>{ query });
            List<SObject> customSettingRecords = Database.query(query);

            List<CustomSettingWrapper> wrapperList = new List<CustomSettingWrapper>();
            for (SObject record : customSettingRecords) {
                CustomSettingWrapper wrapper = new CustomSettingWrapper();
                wrapper.id = (String) record.get('Id');

                SObject setupOwner = record.getSObject('SetupOwner');
                String setupOwnerId = (String) record.get('SetupOwnerId');
                String setupOwnerPrefix = setupOwnerId.substring(0, 3);
                String setupOwnerTypeLabel;

                switch on setupOwnerPrefix {
                    when '00D' {
                        setupOwnerTypeLabel = 'Organization';
                    }
                    when '00E' {
                        setupOwnerTypeLabel = 'Profile';
                    }
                    when else {
                        setupOwnerTypeLabel = (String) setupOwner.get('Type');
                    }
                }

                wrapper.setupOwnerType = setupOwnerTypeLabel;
                wrapper.setupOwnerName = (String) setupOwner.get('Name');

                wrapper.fields = new Map<String, Object>();
                wrapper.fieldLabels = new Map<String, String>();

                for (String fieldName : fieldNames) {
                    wrapper.fields.put(fieldName, record.get(fieldName));
                    Schema.SObjectField field = describeResult.fields.getMap().get(fieldName);
                    wrapper.fieldLabels.put(fieldName, field.getDescribe().getLabel());
                }

                LOGGER.debug('CustomSettingWrapper created: {0}', new List<Object>{ wrapper });
                wrapperList.add(wrapper);
            }

            LOGGER.info('Total custom settings retrieved: {0}', new List<Object>{ wrapperList.size() });
            return wrapperList;
        } catch (Exception ex) {
            LOGGER.error('Error in getCustomSettings', ex);
            throw new AuraHandledException('An error occurred while retrieving custom settings: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteCustomSettingRecord(String customSettingsApiName, String recordId) {
        try {
            LOGGER.info(
                'deleteCustomSettingRecord({0}, {1}) invoked',
                new List<Object>{ customSettingsApiName, recordId }
            );
            if (String.isBlank(recordId)) {
                LOGGER.error('Record Id cannot be empty.');
                throw new AuraHandledException('Record Id cannot be empty.');
            }

            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(customSettingsApiName);
            if (targetType == null) {
                LOGGER.error(
                    'Custom Setting with API Name {0} does not exist.',
                    new List<Object>{ customSettingsApiName }
                );
                throw new AuraHandledException(
                    'Custom Setting with API Name ' + customSettingsApiName + ' does not exist.'
                );
            }

            SObject record = targetType.newSObject();
            record.put('Id', recordId);

            delete record;
            LOGGER.info('Record deleted successfully. Record ID: {0}', new List<Object>{ recordId });
        } catch (Exception ex) {
            LOGGER.error('Error in deleteCustomSettingRecord: {0}', new List<Object>{ ex.getMessage() });
            throw new AuraHandledException(
                'An error occurred while deleting the custom setting record: ' + ex.getMessage()
            );
        }
    }

    @AuraEnabled
    public static void saveCustomSetting(SObject customSettingRecord) {
        try {
            LOGGER.info('saveCustomSetting invoked for record: {0}', new List<Object>{ customSettingRecord });
            if (customSettingRecord == null) {
                LOGGER.error('Custom Setting record cannot be null.');
                throw new AuraHandledException('Custom Setting record cannot be null.');
            }

            upsert customSettingRecord;
            LOGGER.info(
                'Custom Setting saved successfully. Record ID: {0}',
                new List<Object>{ customSettingRecord.Id }
            );
        } catch (Exception ex) {
            LOGGER.error('Error in saveCustomSetting: {0}', new List<Object>{ ex.getMessage() });
            throw new AuraHandledException(
                'An error occurred while saving the custom setting record: ' + ex.getMessage()
            );
        }
    }

    public class CustomSettingWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String setupOwnerType;
        @AuraEnabled
        public String setupOwnerName;
        @AuraEnabled
        public Map<String, Object> fields;
        @AuraEnabled
        public Map<String, String> fieldLabels;
    }
}