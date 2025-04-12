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
private class rflib_FieldMapperTest {
    
    private static final String SOURCE_OBJECT_TYPE = 'rflib_Log_Event__e';
    private static final String TARGET_OBJECT_TYPE = 'rflib_Application_Event__c';
    private static final String INVALID_TARGET_TYPE = 'InvalidObject';
    
    @IsTest
    static void testMapFields_Success() {
        // Arrange
        rflib_Log_Event__e sourceLogEvent = new rflib_Log_Event__e(
            Context__c = 'Test Context',
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'Test Log Messages',
            Request_ID__c = 'TEST-REQ-001',
            Source_System_ID__c = 'TEST_SYSTEM'
        );
        
        // Setup mock field mapping rules
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>{
            createMappingRule(TARGET_OBJECT_TYPE, 'Event_Name__c', 'Context__c', true),
            createMappingRule(TARGET_OBJECT_TYPE, 'Additional_Details__c', 'Log_Messages__c', true),
            createMappingRule(TARGET_OBJECT_TYPE, 'Created_By_ID__c', 'Source_System_ID__c', true),
            createMappingRule(TARGET_OBJECT_TYPE, 'Related_Record_ID__c', 'Request_ID__c', true)
        };
        
        // Set up mock response for SOQL query
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
        
        // Act
        Test.startTest();
        rflib_Application_Event__c mappedEvent = (rflib_Application_Event__c)rflib_FieldMapper.mapFields(sourceLogEvent, TARGET_OBJECT_TYPE);
        Test.stopTest();
        
        // Assert
        System.assertEquals('Test Context', mappedEvent.Event_Name__c);
        System.assertEquals('Test Log Messages', mappedEvent.Additional_Details__c);
        System.assertEquals('TEST_SYSTEM', mappedEvent.Created_By_ID__c);
        System.assertEquals('TEST-REQ-001', mappedEvent.Related_Record_ID__c);
    }
    
    @IsTest
    static void testMapFields_NullSourceObject() {
        // Arrange
        rflib_Log_Event__e sourceLogEvent = null;
        
        // Set up mock - even though it won't be used due to null check happening first
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>{
            createMappingRule(TARGET_OBJECT_TYPE, 'Event_Name__c', 'Context__c', true)
        };
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
        
        // Act & Assert
        Test.startTest();
        try {
            rflib_FieldMapper.mapFields(sourceLogEvent, TARGET_OBJECT_TYPE);
            System.assert(false, 'Expected exception was not thrown');
        } catch (rflib_FieldMapper.FieldMappingException ex) {
            System.assertEquals('Source object cannot be null', ex.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testMapFields_InvalidTargetObject() {
        // Arrange
        rflib_Log_Event__e sourceLogEvent = new rflib_Log_Event__e(
            Context__c = 'Test Context',
            Log_Level__c = 'ERROR'
        );
        
        // Set up mock for mapping rules
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>{
            createMappingRule(INVALID_TARGET_TYPE, 'Some_Field__c', 'Context__c', true)
        };
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
        
        // Act & Assert
        Test.startTest();
        try {
            rflib_FieldMapper.mapFields(sourceLogEvent, INVALID_TARGET_TYPE);
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Invalid object name'), 
                         'Expected exception message about invalid object but got: ' + ex.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testMapFields_NoMappingRules() {
        // Arrange
        rflib_Log_Event__e sourceLogEvent = new rflib_Log_Event__e(
            Context__c = 'Test Context',
            Log_Level__c = 'ERROR'
        );
        
        // Set up mock with empty list of mapping rules
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>();
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
        
        // Act
        Test.startTest();
        rflib_Application_Event__c mappedEvent = (rflib_Application_Event__c)rflib_FieldMapper.mapFields(sourceLogEvent, TARGET_OBJECT_TYPE);
        Test.stopTest();
        
        // Assert
        // Should return an empty target object
        System.assertNotEquals(null, mappedEvent);
        System.assertEquals(null, mappedEvent.Event_Name__c);
        System.assertEquals(null, mappedEvent.Additional_Details__c);
    }
    
    @IsTest
    static void testMapFields_SimpleFieldCopy_MissingField() {
        // Arrange
        rflib_Log_Event__e sourceLogEvent = new rflib_Log_Event__e(
            Context__c = 'Test Context',
            Log_Level__c = 'ERROR'
        );
        
        // Setup mock mapping rule with a non-existent field
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>{
            createMappingRule(TARGET_OBJECT_TYPE, 'Event_Name__c', 'NonExistentField', true)
        };
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
        
        // Act
        Test.startTest();
        rflib_Application_Event__c mappedEvent = (rflib_Application_Event__c)rflib_FieldMapper.mapFields(sourceLogEvent, TARGET_OBJECT_TYPE);
        Test.stopTest();
        
        // Assert
        // Should not throw an exception but field should be null
        System.assertEquals(null, mappedEvent.Event_Name__c);
    }
    
    @IsTest
    static void testMapFields_TransformationFormula_Invalid() {
        // Arrange
        rflib_Log_Event__e sourceLogEvent = new rflib_Log_Event__e(
            Context__c = 'Test Context',
            Log_Level__c = 'ERROR'
        );
        
        // Setup mock mapping rule with an invalid formula
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>{
            createMappingRule(TARGET_OBJECT_TYPE, 'Event_Name__c', 'NonExistentField + 123', false)
        };
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
        
        // Act & Assert
        Test.startTest();
        try {
            rflib_FieldMapper.mapFields(sourceLogEvent, TARGET_OBJECT_TYPE);
            System.assert(false, 'Expected exception was not thrown');
        } catch (Exception ex) {
            // Should throw a formula evaluation exception
            System.assert(ex.getMessage().contains('Error evaluating formula') || 
                          ex.getMessage().contains('Field does not exist'), 
                          'Expected formula error but got: ' + ex.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testMapFields_VariousFieldTypes() {
        // Arrange
        rflib_Log_Event__e sourceLogEvent = new rflib_Log_Event__e(
            Context__c = 'Test Context',
            Log_Level__c = 'ERROR',
            Log_Messages__c = 'Detailed Log Information',
            Request_ID__c = 'TEST-REQ-001',
            Source_System_ID__c = 'TEST_SYSTEM'
        );
        
        // Setup mock mapping rules for different field types
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>{
            createMappingRule(TARGET_OBJECT_TYPE, 'Event_Name__c', 'Context__c', true), // String
            createMappingRule(TARGET_OBJECT_TYPE, 'Additional_Details__c', 'Log_Messages__c + " - Source: " + Source_System_ID__c', false), // String concatenation
            createMappingRule(TARGET_OBJECT_TYPE, 'Occurred_On__c', 'NOW()', false), // DateTime
            createMappingRule(TARGET_OBJECT_TYPE, 'Related_Record_ID__c', 'IF(Log_Level__c = "ERROR", Request_ID__c, "NO-ID")', false) // Conditional
        };
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
        
        // Act
        Test.startTest();
        rflib_Application_Event__c mappedEvent = (rflib_Application_Event__c)rflib_FieldMapper.mapFields(sourceLogEvent, TARGET_OBJECT_TYPE);
        Test.stopTest();
        
        // Assert
        System.assertEquals('Test Context', mappedEvent.Event_Name__c);
        System.assertEquals('Detailed Log Information - Source: TEST_SYSTEM', mappedEvent.Additional_Details__c);
        System.assertNotEquals(null, mappedEvent.Occurred_On__c); // NOW() will be the current time
        System.assertEquals('TEST-REQ-001', mappedEvent.Related_Record_ID__c);
    }
    
    @IsTest
    static void testMapFields_UnsupportedFieldType() {
        // This test is more about code coverage since it's hard to mock an unsupported field type
        // All standard field types are supported, but we'll create a test to simulate the error path
        
        // Arrange
        rflib_Log_Event__e sourceLogEvent = new rflib_Log_Event__e(
            Context__c = 'Test Context',
            Log_Level__c = 'ERROR'
        );
        
        // Setup a simple mapping rule
        List<rflib_Field_Mapping_Rule__mdt> mappingRules = new List<rflib_Field_Mapping_Rule__mdt>{
            createMappingRule(TARGET_OBJECT_TYPE, 'Event_Name__c', 'Context__c', false)
        };
        rflib_SOQL.setMock('FieldMappingRule.getRules', mappingRules);
        
        // Act & Assert
        Test.startTest();
        try {
            rflib_FieldMapper.mapFields(sourceLogEvent, TARGET_OBJECT_TYPE);
            System.assert(false, 'Expected exception was not thrown');
        } catch (rflib_FieldMapper.FieldMappingException ex) {
            System.assertEquals('Unsupported field type for formula evaluation: STRING', ex.getMessage());
        }
        Test.stopTest();
    }
    
    // Helper method to create a mapping rule
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
}