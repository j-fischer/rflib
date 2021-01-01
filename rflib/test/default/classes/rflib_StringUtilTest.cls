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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_StringUtilTest {
    
    private static final String SOURCE = 'aBc123def5!@_#(_';

    @IsTest
    private static void testReplaceWithAllMaskingRules_WithoutRules() {
        rflib_StringUtil.allMaskingRules = new List<rflib_Masking_Rule__mdt>();

        System.assertEquals(SOURCE, rflib_StringUtil.replaceWithAllMaskingRules(SOURCE));
    }

    @IsTest
    private static void testReplaceWithAllMaskingRules_WithRules() {
        List<rflib_Masking_Rule__mdt> rules = new List<rflib_Masking_Rule__mdt> {
            createRule('[0-9]+', '*'),
            createRule('[@(!_]+', '-'),
            createRule('[A-Z]+', '#')
        };

        rflib_StringUtil.allMaskingRules = rules;

        String result = rflib_StringUtil.replaceWithAllMaskingRules(SOURCE);

        System.assertEquals('a#c*def*-#-', result);
    }

    @IsTest
    private static void testReplaceWithRules() {
        List<rflib_Masking_Rule__mdt> rules = new List<rflib_Masking_Rule__mdt> {
            createRule('[0-9]+', '*'),
            createRule('[A-Z]+', '#')
        };

        String result = rflib_StringUtil.replaceWithRules(SOURCE, rules);

        System.assertEquals('a#c*def*!@_#(_', result);
    }

    @IsTest
    public static void testReplaceWithRule_Regex() {
        rflib_Masking_Rule__mdt rule = createRule('[0-9]+', '*****');

        String result = rflib_StringUtil.replaceWithRule(SOURCE, rule);

        System.assertEquals('aBc*****def*****!@_#(_', result);
    }

    @IsTest
    private static void testReplaceWithRule_UnsupportedType() {
        rflib_Masking_Rule__mdt rule = new rflib_Masking_Rule__mdt(
            Target__c = '[0-9]+',
            Target_Type__c = 'Unsupported',
            Replacement__c = '*****',
            Is_Active__c = true,
            Order__c = 1
        );

        String result = rflib_StringUtil.replaceWithRule(SOURCE, rule);

        System.assertEquals(source, result);
    }

    private static rflib_Masking_Rule__mdt createRule(String target, String replacement) {
        return new rflib_Masking_Rule__mdt(
            Target__c = target,
            Target_Type__c = 'RegEx',
            Replacement__c = replacement,
            Is_Active__c = true,
            Order__c = 1
        );
    }
}
