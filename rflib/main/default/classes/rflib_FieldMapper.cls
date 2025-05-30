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
public class rflib_FieldMapper {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_FieldMapper');

    public class FieldMappingException extends Exception {}

    static {
        // NOTE: It is critical to turn reporting off so that a log configuration reporting INFO statements
        //       does not create an infinite loop of log events. 
        LOGGER.setReportingLogLevel(rflib_LogLevel.NONE);
        LOGGER.setSystemDebugLevel(rflib_LogLevel.DEBUG);
    }

    /**
     * Maps fields from a source object to a target object based on rflib_Field_Mapping_Rule__mdt rules
     * @param sourceObject The source SObject instance
     * @param targetObjectType The API name of the target object
     * @return A new instance of the target object with mapped fields
     */
    public static SObject mapFields(SObject sourceObject, String targetObjectType) {
        rflib_Field_Mapping_Rule__mdt activeRule = null;    
        try {
            LOGGER.debug('Mapping fields from source object {0} to target object {1}', new Object[] {
                sourceObject?.getSObjectType()?.getDescribe()?.getName(),
                targetObjectType
            });

            if (sourceObject == null) {
                LOGGER.debug('Source object cannot be null');
                throw new FieldMappingException('Source object cannot be null');
            }

            if (String.isBlank(targetObjectType)) {
                LOGGER.debug('Target object type cannot be null or empty');
                throw new FieldMappingException('Target object type cannot be null or empty');
            }
            
            // Create new instance of target object
            Schema.SObjectType targetSObjectType = Schema.getGlobalDescribe().get(targetObjectType);
            if (targetSObjectType == null) {
                LOGGER.error('Invalid target object type: {0}', new Object[] { targetObjectType });
                throw new FieldMappingException('Invalid target object type: ' + targetObjectType);
            }

            SObject targetObject = targetSObjectType.newSObject();
            
            List<rflib_Field_Mapping_Rule__mdt> mappingRules = 
                rflib_SOQL.of(rflib_Field_Mapping_Rule__mdt.SObjectType)
                    .with(rflib_Field_Mapping_Rule__mdt.Target_Object__c)
                    .with(rflib_Field_Mapping_Rule__mdt.Target_Field__c)
                    .with(rflib_Field_Mapping_Rule__mdt.Transformation_Formula__c)
                    .with(rflib_Field_Mapping_Rule__mdt.Simple_Field_Copy__c)
                    .whereAre(rflib_SOQL.Filter.with(rflib_Field_Mapping_Rule__mdt.Target_Object__c).equal(targetObjectType))
                    .mockId('FieldMappingRule.getRules')
                    .toList();

            LOGGER.debug('Found {0} mapping rules for target object {1}: {2}', new Object[] {
                mappingRules.size(),
                targetObjectType,
                JSON.serialize(mappingRules)
            });
            
            Map<String, Schema.SObjectField> targetFields = targetObject.getSObjectType()
                .getDescribe().fields.getMap();
            
            for (rflib_Field_Mapping_Rule__mdt rule : mappingRules) {
                activeRule = rule;
                Object value = null;

                if (rule.Simple_Field_Copy__c) {
                    // Use the formula field value as a source field name for direct copy
                    try {
                        value = sourceObject.get(rule.Transformation_Formula__c);
                    } catch (SObjectException ex) {
                        LOGGER.warn('Field {0} not found on source object {1}', 
                            new Object[] { rule.Transformation_Formula__c, sourceObject.getSObjectType().getDescribe().getName() });
                    }
                } else {
                    // If there's a transformation formula, evaluate it
                    value = evaluateFormula(rule, sourceObject, targetFields.get(rule.Target_Field__c));
                }

                LOGGER.trace('Mapped value for field {0} to {1}; simple copy: {2}',
                        new Object[] { rule.Target_Field__c, value, rule.Simple_Field_Copy__c });
                
                if (value != null) {
                    targetObject.put(rule.Target_Field__c, value);
                }
            }

            LOGGER.debug('Mapped fields from source object {0} to target object {1}: {2}', new Object[] {
                sourceObject.getSObjectType().getDescribe().getName(),
                targetObjectType,
                JSON.serialize(targetObject)
            });
            
            return targetObject;
            
        } catch (FieldMappingException ex) {
            LOGGER.error('Field mapping error: {0}', new Object[] { ex.getMessage() });
            throw ex;
        } catch (Exception ex) {
            LOGGER.error('Error mapping fields from source object {0} to target object {1} for field {2}: {3}', new Object[] {
                sourceObject?.getSObjectType()?.getDescribe()?.getName(),
                targetObjectType,
                activeRule?.Target_Field__c,
                ex.getMessage()
            });
            throw new FieldMappingException('Error during field mapping: ' + ex.getMessage());
        }
    }
    
    private static Object evaluateFormula(
        rflib_Field_Mapping_Rule__mdt rule, 
        SObject sourceObject,
        Schema.SObjectField targetField
    ) {
        if (rule == null) {
            throw new FieldMappingException('Mapping rule cannot be null');
        }
        
        if (targetField == null) {
            throw new FieldMappingException('Target field ' + rule.Target_Field__c + ' not found on target object');
        }

        try {
            FormulaEval.FormulaInstance ff = Formula.builder()
                .withReturnType(getFormulaReturnType(targetField))
                .withType(sourceObject.getSObjectType())
                .withFormula(rule.Transformation_Formula__c)
                .build();
            
            return ff.evaluate(sourceObject);
        } catch (Exception ex) {
            throw new FieldMappingException('Error evaluating formula for field ' + rule.Target_Field__c + ': ' + ex.getMessage());
        }
    }
    
    private static FormulaEval.FormulaReturnType getFormulaReturnType(Schema.SObjectField targetField) {
        if (targetField == null) {
            throw new FieldMappingException('Target field cannot be null');
        }

        Schema.DisplayType fieldType = targetField.getDescribe().getType();
        
        switch on fieldType {
            when STRING, ID, PICKLIST, TEXTAREA {
                return FormulaEval.FormulaReturnType.STRING;
            }
            when INTEGER, LONG {
                return FormulaEval.FormulaReturnType.INTEGER;
            }
            when DOUBLE {
                return FormulaEval.FormulaReturnType.DECIMAL;
            }
            when BOOLEAN {
                return FormulaEval.FormulaReturnType.BOOLEAN;
            }
            when DATE {
                return FormulaEval.FormulaReturnType.DATE;
            }
            when DATETIME {
                return FormulaEval.FormulaReturnType.DATETIME;
            }
            when TIME {
                return FormulaEval.FormulaReturnType.TIME;
            }
            when else {
                throw new FieldMappingException('Unsupported field type for formula evaluation: ' + fieldType);
            }
        }
    }
}