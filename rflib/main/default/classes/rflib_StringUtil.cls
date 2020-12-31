/*
 * Copyright (c) 2019 Johannes Fischer <fischer.jh@gmail.com>
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
 * 3. Neither the name of mosquitto nor the names of its
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
    
    @TestVisible
    private static List<rflib_Masking_Rule__mdt> allMaskingRules {
        get {
            if (allMaskingRules == null) {
                // TODO: Replace with new syntax when Spring 21 is released.
                allMaskingRules = [SELECT Target__c, Target_type__c, Replacement__c FROM rflib_Masking_Rule__mdt WHERE Is_Active__c = true ORDER BY Order__c ASC];
            }
            return allMaskingRules;
        }
        private set;
    }

    /**     
     * Replace parts of a text based on all active Masking rules that are stored in the Masking
     * Rule Custom Metadata Type. The rules will be appliead based on the order defined in the records
     * and used to ensure that protected information such as PII can be removed from larger text 
     * paragraphs. 
     * 
     * @param  source The source that may require text replacements. 
     * @return        The source with the all targets of the given rule replaced. 
     */
    public static String replaceWithAllMaskingRules(String source) {
        return replaceWithRules(source, allMaskingRules);
    }
    
    /**
     * Replace parts of a text based on a multiple Masking rules that are provided. It can be 
     * used to ensure that protected information such as PII can be removed from larger text 
     * paragraphs. 
     * 
     * @param  source The source that may require text replacements. 
     * @param  rules  The Masking Rules that will be applied to the source in order.
     * @return        The source with the all targets of the given rule replaced. 
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
     * used to ensure that protected information such as PII can be removed from larger text 
     * paragraphs. 
     * 
     * @param  source The source that may require text replacements. 
     * @param  rule   The Masking Rule that will be applied to the source.
     * @return        The source with the all targets of the given rule replaced. 
     */
    public static String replaceWithRule(String source, rflib_Masking_Rule__mdt rule) {
        switch on rule.Target_Type__c {
            when 'RegEx' {
                return source.replaceAll(rule.Target__c, rule.Replacement__c);
            }
        }
        return source;
    }
    
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private rflib_StringUtil() { }
}
