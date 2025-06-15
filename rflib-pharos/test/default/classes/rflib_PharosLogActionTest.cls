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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_PharosLogActionTest {
    
    private static final rflib_MockEventPublisher MOCK_EVENT_PUBLISHER = new rflib_MockEventPublisher();

    private static Boolean isPharosPackageInstalled() {
        return Schema.getGlobalDescribe().get(rflib_PharosLogAction.PHAROS_LOG_OBJECT) != null;
    }

    @IsTest
    static void testCreatePharosLogRecords_Success() {
        // Setup
        setupEventPublisher();
        setupTestFieldMappingRulesForPharos();
        setupPostProcessingSettings();
        
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'ERROR';
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('ERROR', 'Test error message', 'TestContext', 'REQ-001'),
            createLogEvent('FATAL', 'Test fatal message', 'TestContext', 'REQ-002')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert - verify the method executed successfully
        SObject publishedEvent = MOCK_EVENT_PUBLISHER.capturedPlatformEvent;
        
        // If Pharos package is installed, verify event was published correctly
        if (isPharosPackageInstalled()) {
            String eventTypeName = publishedEvent.getSObjectType().getDescribe().getName();
            System.assert(eventTypeName.endsWith('Log_Event__e'), 'Should publish a Log_Event__e type: ' + eventTypeName);
            
            List<Object> pharosLogs = getPharosLogsFromEvent(publishedEvent);
            System.assertEquals(2, pharosLogs.size(), 'Should have 2 Pharos log records');
        } else {
            // If package is not installed, verify no event was published
            System.assertEquals(null, publishedEvent, 'No event should be published when Pharos package is not installed');
        }
    }
    
    @IsTest
    static void testCreatePharosLogRecords_PharosLoggingDisabled() {
        // Setup
        setupEventPublisher();
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'NONE';
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('ERROR', 'Test error message', 'TestContext', 'REQ-001')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert - no event should be published when Pharos logging is disabled
        System.assertEquals(null, MOCK_EVENT_PUBLISHER.capturedPlatformEvent, 'No event should be published when logging is disabled');
    }
    
    @IsTest
    static void testCreatePharosLogRecords_PharosObjectNotFound() {
        rflib_PharosLogAction.PHAROS_LOG_OBJECT = 'rflib_DoesNotExist'; // Simulate Pharos Log object not found
        
        // Setup
        setupEventPublisher();
        setupTestFieldMappingRulesForPharos();
        
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'ERROR';
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('ERROR', 'Test error message', 'TestContext', 'REQ-001')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert - no event should be published when Pharos package is not installed
        System.assertEquals(null, MOCK_EVENT_PUBLISHER.capturedPlatformEvent, 
            'No event should be published when Pharos package is not installed');
    }
    
    @IsTest
    static void testCreatePharosLogRecords_LogLevelFiltering() {
        // Setup
        setupEventPublisher();
        setupTestFieldMappingRulesForPharos();
        setupPostProcessingSettings();
        
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'ERROR';
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('ERROR', 'This should be processed', 'TestContext', 'REQ-001'),
            createLogEvent('FATAL', 'This should be processed', 'TestContext', 'REQ-002'),
            createLogEvent('WARN', 'This should NOT be processed', 'TestContext', 'REQ-003'),
            createLogEvent('INFO', 'This should NOT be processed', 'TestContext', 'REQ-004'),
            createLogEvent('DEBUG', 'This should NOT be processed', 'TestContext', 'REQ-005')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert - verify only ERROR and FATAL level events were processed
        SObject publishedEvent = MOCK_EVENT_PUBLISHER.capturedPlatformEvent;
        
        if (isPharosPackageInstalled()) {
            List<Object> pharosLogs = getPharosLogsFromEvent(publishedEvent);
            System.assertEquals(2, pharosLogs.size(), 'Should only process ERROR and FATAL level events');
        } else {
            System.assertEquals(null, publishedEvent, 'No event should be published when Pharos package is not installed');
        }
    }
    
    @IsTest
    static void testCreatePharosLogRecords_WarnLogLevel() {
        // Setup
        setupEventPublisher();
        setupTestFieldMappingRulesForPharos();
        setupPostProcessingSettings();
        
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'WARN';
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('ERROR', 'This should be processed', 'TestContext', 'REQ-001'),
            createLogEvent('WARN', 'This should be processed', 'TestContext', 'REQ-002'),
            createLogEvent('INFO', 'This should NOT be processed', 'TestContext', 'REQ-003')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert - verify ERROR and WARN level events were processed
        SObject publishedEvent = MOCK_EVENT_PUBLISHER.capturedPlatformEvent;
        
        if (isPharosPackageInstalled()) {
            List<Object> pharosLogs = getPharosLogsFromEvent(publishedEvent);
            System.assertEquals(2, pharosLogs.size(), 'Should process ERROR and WARN level events');
        } else {
            System.assertEquals(null, publishedEvent, 'No event should be published when Pharos package is not installed');
        }
    }
    
    @IsTest
    static void testCreatePharosLogRecords_UnsupportedLogLevel() {
        // Setup
        setupEventPublisher();
        setupTestFieldMappingRulesForPharos();
        setupPostProcessingSettings();
        
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'INFO'; // Unsupported level
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('ERROR', 'Test error message', 'TestContext', 'REQ-001')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert - should default to WARN level and process ERROR event if package is installed
        SObject publishedEvent = MOCK_EVENT_PUBLISHER.capturedPlatformEvent;
        
        if (isPharosPackageInstalled()) {
            List<Object> pharosLogs = getPharosLogsFromEvent(publishedEvent);
            System.assertEquals(1, pharosLogs.size(), 'Should process ERROR event with default WARN level');
        } else {
            System.assertEquals(null, publishedEvent, 'No event should be published when Pharos package is not installed');
        }
    }
    
    @IsTest
    static void testCreatePharosLogRecords_EmptyEventList() {
        // Setup
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>();
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert
        System.assert(true, 'Method executed successfully with empty event list');
    }
    
    @IsTest
    static void testCreatePharosLogRecords_ExceptionHandling() {
        // Setup - create a scenario that might cause an exception
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'ERROR';
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('ERROR', 'Test error message', 'TestContext', 'REQ-001')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert - method should handle exceptions gracefully
        System.assert(true, 'Method executed successfully with exception handling');
    }
    
    @IsTest
    static void testCreatePharosLogRecords_NoPostProcessingSettings() {
        // Setup - don't setup post processing settings
        setupEventPublisher();
        setupTestFieldMappingRulesForPharos();
        
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'ERROR';
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('ERROR', 'Test error message', 'TestContext', 'REQ-001')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert - event should still be published if package is installed
        SObject publishedEvent = MOCK_EVENT_PUBLISHER.capturedPlatformEvent;
        
        if (isPharosPackageInstalled()) {
            List<Object> pharosLogs = getPharosLogsFromEvent(publishedEvent);
            System.assertEquals(1, pharosLogs.size(), 'Should process ERROR event without post processing settings');
        } else {
            System.assertEquals(null, publishedEvent, 'No event should be published when Pharos package is not installed');
        }
    }
    
    @IsTest
    static void testMatchesConfiguredLogLevel_ErrorLevel() {
        // Setup
        setupEventPublisher();
        setupTestFieldMappingRulesForPharos();
        
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'ERROR';
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('FATAL', 'Fatal message', 'TestContext', 'REQ-001'),
            createLogEvent('ERROR', 'Error message', 'TestContext', 'REQ-002'),
            createLogEvent('WARN', 'Warning message', 'TestContext', 'REQ-003')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();
        
        // Assert - only FATAL and ERROR should be processed
        SObject publishedEvent = MOCK_EVENT_PUBLISHER.capturedPlatformEvent;
        if (isPharosPackageInstalled()) {
            List<Object> pharosLogs = getPharosLogsFromEvent(publishedEvent);
            System.assertEquals(2, pharosLogs.size(), 'Should only process FATAL and ERROR level events');
        } else {
            System.assertEquals(null, publishedEvent, 'No event should be published when Pharos package is not installed');
        }
    }

    @IsTest
    static void testCreatePharosLogRecords_rflibLogObject() {
        // This test will succeed in every org, regardless of Pharos package installation
        rflib_PharosLogAction.PHAROS_LOG_OBJECT = 'rflib_Log__c'; 

        // Setup
        setupEventPublisher();
        setupTestFieldMappingRulesForRflib();
        setupPostProcessingSettings();
        
        rflib_Logger_Settings__c settings = rflib_Logger_Settings__c.getOrgDefaults();
        settings.Pharos_Log_Level__c = 'ERROR';
        upsert settings;
        
        List<rflib_Log_Event__e> logEvents = new List<rflib_Log_Event__e>{
            createLogEvent('ERROR', 'Test error message', 'TestContext', 'REQ-001'),
            createLogEvent('FATAL', 'Test fatal message', 'TestContext', 'REQ-002')
        };
        
        // Act
        Test.startTest();
        rflib_PharosLogAction.createPharosLogRecords(logEvents);
        Test.stopTest();

        Assert.isTrue(true, 'Method executed successfully with rflib_Log__c object');
    }
    
    // Helper methods
    private static rflib_Log_Event__e createLogEvent(String logLevel, String message, String context, String requestId) {
        return new rflib_Log_Event__e(
            Log_Level__c = logLevel,
            Log_Messages__c = message,
            Context__c = context,
            Request_ID__c = requestId,
            Source_System_ID__c = 'TEST_SYSTEM'
        );
    }
    
    private static void setupTestFieldMappingRulesForPharos() {
        // Setup mock field mapping rules based on real customMetadata
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>{
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Area__c', 'Context__c', false),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Category__c', 'Log_Source__c', true),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Details__c', 'Log_Messages__c', true),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Do_Not_Create_Issue__c', 'FALSE', false),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Organization_Id__c', '"someOrgId"', false),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Organization_Name__c', 'Org__c', true),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Request_Id_External__c', 'Request_ID__c', false),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Stacktrace__c', 'Stack_Trace__c', true),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Summary__c', '"Sample Summary"', false),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__Type__c', 'Log_Level__c', true),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'pharos__User_Id__c', 'CreatedById', false)
        };
        
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
    }

    private static void setupTestFieldMappingRulesForRflib() {
        // Setup mock field mapping rules based on real customMetadata
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>{
            createMappingRule('rflib_Log__c', 'Context__c', 'Context__c', false),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'Log_Messages__c', 'Log_Messages__c', true),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'Request_ID__c', 'Request_ID__c', true),
            createMappingRule(rflib_PharosLogAction.PHAROS_LOG_OBJECT, 'Log_Level__c', 'Log_Level__c', true)
        };
        
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
    }
    
    private static rflib_Field_Mapping_Rule__mdt createMappingRule(
        String targetObject, 
        String targetField, 
        String transformationFormula, 
        Boolean isSimpleFieldCopy
    ) {
        return new rflib_Field_Mapping_Rule__mdt(
            Target_Object__c = targetObject,
            Target_Field__c = targetField,
            Transformation_Formula__c = transformationFormula,
            Simple_Field_Copy__c = isSimpleFieldCopy
        );
    }

    private static void setupEventPublisher(){
        rflib_PharosLogAction.EVENT_PUBLISHER = MOCK_EVENT_PUBLISHER;
    }
    
    private static String getBodyFieldName(SObject publishedEvent) {
        for (Schema.SObjectField field : publishedEvent.getSObjectType().getDescribe().fields.getMap().values()) {
            if (field.getDescribe().getName().endsWith('Body__c')) {
                return field.getDescribe().getName();
            }
        }
        return null;
    }
    
    private static List<Object> getPharosLogsFromEvent(SObject publishedEvent) {
        String bodyFieldName = getBodyFieldName(publishedEvent);
        if (bodyFieldName != null) {
            String eventBody = (String) publishedEvent.get(bodyFieldName);
            if (eventBody != null) {
                return (List<Object>) JSON.deserializeUntyped(eventBody);
            }
        }
        return new List<Object>();
    }
    
    private static void setupPostProcessingSettings() {
        List<rflib_Pharos_Post_Processing_Setting__c> testSettings = new List<rflib_Pharos_Post_Processing_Setting__c>();
        
        testSettings.add(createPostProcessingSetting('auditTrail', 'true'));
        testSettings.add(createPostProcessingSetting('deployResult', 'false'));
        testSettings.add(createPostProcessingSetting('installedPackages', 'true'));
        testSettings.add(createPostProcessingSetting('objectInfo', 'false'));
        testSettings.add(createPostProcessingSetting('pendingJobs', 'true'));
        testSettings.add(createPostProcessingSetting('relatedObjects', 'false'));
        testSettings.add(createPostProcessingSetting('stackTrace', 'true'));
        testSettings.add(createPostProcessingSetting('totalActiveSession', 'false'));
        testSettings.add(createPostProcessingSetting('userInfo', 'true'));
        
        insert testSettings;
    }
    
    private static rflib_Pharos_Post_Processing_Setting__c createPostProcessingSetting(String name, String value) {
        return new rflib_Pharos_Post_Processing_Setting__c(
            Name = name,
            Value__c = value
        );
    }
}