/*
 * Copyright (c) 2021 Johannes Fischer <fischer.jh@gmail.com>
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

 /**
 * @group Logger
 * @description Utility class for string operations. 
 */ 
@SuppressWarnings('PMD.ClassNamingConventions, PMD.ApexSharingViolations')
public class rflib_StringUtil {
    
    /**
     * Enum to specify where to truncate a string from
     */
    public enum TruncateFrom {
        START,    // Truncate from the beginning of the string
        TAIL      // Truncate from the end of the string (default)
    }

    @TestVisible
    private static List<rflib_Masking_Rule__mdt> allActiveMaskingRules {
        get {
            if (allActiveMaskingRules == null) {
                List<WrappedMaskingRules> wrappedMaskingRules = new List<WrappedMaskingRules>();
                for (rflib_Masking_Rule__mdt rule : rflib_Masking_Rule__mdt.getAll().values()) {
                    if (rule.Is_Active__c) {
                        wrappedMaskingRules.add(new WrappedMaskingRules(rule));
                    }
                }

                wrappedMaskingRules.sort();
                
                allActiveMaskingRules = new List<rflib_Masking_Rule__mdt>();
                for (WrappedMaskingRules wrapper : wrappedMaskingRules) {
                    allActiveMaskingRules.add(wrapper.rule);
                }
            }
            return allActiveMaskingRules;
        }
        private set;
    }

    /**     
     * Replace parts of a text using all active Masking rules that are stored in the Masking
     * Rule Custom Metadata Type. The rules will be applied based on the order defined in the records
     * and used to ensure that protected information such as PII is removed from larger text 
     * paragraphs. 
     * 
     * @param  source The source that may require text replacements. 
     * @return        The source with all targets of the given rule replaced. 
     */
    public static String replaceWithAllMaskingRules(String source) {
        return replaceWithRules(source, allActiveMaskingRules);
    }
    
    /**
     * Replace parts of a text based on a multiple Masking rules that are provided. It can be 
     * used to ensure that protected information such as PII is removed from larger text 
     * paragraphs. 
     * 
     * @param  source The source that may require text replacements. 
     * @param  rules  The Masking Rules that will be applied to the source in order.
     * @return        The source with all targets of the given rule replaced. 
     */
    public static String replaceWithRules(String source, List<rflib_Masking_Rule__mdt> rules) {
        String result = source;
        for (rflib_Masking_Rule__mdt rule : rules) {
            result = replaceWithRule(result, rule);
        }
        return result;
    }
    
    /**
     * Replace parts of a text based on a single Masking rule that is provided. It can be 
     * used to ensure that protected information such as PII is removed from larger text 
     * paragraphs. 
     * 
     * @param  source The source that may require text replacements. 
     * @param  rule   The Masking Rule that will be applied to the source.
     * @return        The source with all targets of the given rule replaced. 
     */
    public static String replaceWithRule(String source, rflib_Masking_Rule__mdt rule) {
        switch on rule.Target_Type__c {
            when 'RegEx' {
                return source.replaceAll(rule.Target__c, rule.Replacement__c);
            }
        }
        return source;
    }

    /**
     * Convert a list of strings to a representation that can be used in dynamic queries as part of the 
     * `IN` condition. 
     * 
     * @param  theList A list of strings.
     * @return         A string representation of list in the format: ('elem1', 'elem2', ...) or ('') if list is null or empty.
     */
    public static String convertListToStringForQuery(List<String> theList) {
        if (theList == null || theList.isEmpty()) {
            return '(\'\')';
        }

        String result = '(';
        for (String theString : theList) {
            if (result != '(') {
                result += ',';
            }
    
            result += '\'' + theString + '\'';
        }
    
        result += ')';
        return result;
    }

    /**
     * Truncates a string to a specified maximum size if it exceeds that size.
     * By default, truncates from the end of the string.
     * @param text The text to potentially truncate
     * @param maxSize The maximum allowed size for the text
     * @return The original text if within size limits, or truncated version if over
     */
    public static String truncateToMaxSize(String text, Integer maxSize) {
        return truncateToMaxSize(text, maxSize, TruncateFrom.TAIL);
    }

    /**
     * Truncates a string to a specified maximum size if it exceeds that size.
     * @param text The text to potentially truncate
     * @param maxSize The maximum allowed size for the text
     * @param truncateFrom Specifies where to truncate the string from (START, TAIL)
     * @return The original text if within size limits, or truncated version if over
     */
    public static String truncateToMaxSize(String text, Integer maxSize, TruncateFrom truncateFrom) {
        if (text == null) {
            return null;
        }
        Integer textLength = text.length();
        if (textLength <= maxSize) {
            return text;
        }

        switch on truncateFrom {
            when START {
                return text.substring(textLength - maxSize);
            }
            when else {
                return text.substring(0, maxSize);
            }
        }
    }
    
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private rflib_StringUtil() { }

    public class WrappedMaskingRules {
        public rflib_Masking_Rule__mdt rule;
        
        public WrappedMaskingRules(rflib_Masking_Rule__mdt rule) {
           this.rule = rule;
        }
        
        public Integer compareTo(Object compareTo) {
            WrappedMaskingRules compareToRule = (WrappedMaskingRules) compareTo;
            
            if (compareTo == null) {
                return 1;
            } else if (rule == null && compareToRule.rule == null){
                return 0;
            } else if (rule == null && compareToRule.rule != null){
                return -1;
            } else if (rule != null && compareToRule.rule == null){
                return 1;
            } if (rule.Order__c == null && compareToRule.rule.Order__c != null){
                return -1;
            } else if (rule.Order__c != null && compareToRule.rule.Order__c == null){
                return 1;
            } else if (rule.Order__c > compareToRule.rule.Order__c) {
                return 1;
            } else if (rule.Order__c < compareToRule.rule.Order__c) {
                return -1;
            } else {
                return 0;
            }
        }
    }
}
