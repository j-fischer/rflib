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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_StringUtilTest {
    
    private static final String SOURCE = 'aBc123def5!@_#(_';

    @IsTest
    private static void testReplaceWithAllMaskingRules_WithoutRules() {
        rflib_StringUtil.allActiveMaskingRules = new List<rflib_Masking_Rule__mdt>();

        Test.startTest();
        System.assertEquals(SOURCE, rflib_StringUtil.replaceWithAllMaskingRules(SOURCE));
        Test.stopTest();
    }

    @IsTest
    private static void testReplaceWithAllMaskingRules_WithRules() {
        List<rflib_Masking_Rule__mdt> rules = new List<rflib_Masking_Rule__mdt> {
            createRule('[0-9]+', '*'),
            createRule('[@(!_]+', '-'),
            createRule('[A-Z]+', '#')
        };

        rflib_StringUtil.allActiveMaskingRules = rules;

        Test.startTest();
        String result = rflib_StringUtil.replaceWithAllMaskingRules(SOURCE);
        Test.stopTest();

        System.assertEquals('a#c*def*-#-', result);
    }

    @IsTest
    private static void testReplaceWithRules() {
        List<rflib_Masking_Rule__mdt> rules = new List<rflib_Masking_Rule__mdt> {
            createRule('[0-9]+', '*'),
            createRule('[A-Z]+', '#')
        };

        Test.startTest();
        String result = rflib_StringUtil.replaceWithRules(SOURCE, rules);
        Test.stopTest();

        System.assertEquals('a#c*def*!@_#(_', result);
    }

    @IsTest
    public static void testReplaceWithRule_Regex() {
        rflib_Masking_Rule__mdt rule = createRule('[0-9]+', '*****');

        Test.startTest();
        String result = rflib_StringUtil.replaceWithRule(SOURCE, rule);
        Test.stopTest();

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

        Test.startTest();
        String result = rflib_StringUtil.replaceWithRule(SOURCE, rule);
        Test.stopTest();

        System.assertEquals(source, result);
    }

    @IsTest
    public static void testRuleWrapper() {
        rflib_StringUtil.WrappedMaskingRules rule1 = new rflib_StringUtil.WrappedMaskingRules(createRule(1));
        rflib_StringUtil.WrappedMaskingRules rule2 = new rflib_StringUtil.WrappedMaskingRules(createRule(2));
        rflib_StringUtil.WrappedMaskingRules rule3 = new rflib_StringUtil.WrappedMaskingRules(createRule(3));
        rflib_StringUtil.WrappedMaskingRules rule4 = new rflib_StringUtil.WrappedMaskingRules(createRule(2));
        rflib_StringUtil.WrappedMaskingRules noRule = new rflib_StringUtil.WrappedMaskingRules(null);

        System.assertEquals(1, rule1.compareTo(null));
        System.assertEquals(1, rule1.compareTo(noRule));
        System.assertEquals(-1, noRule.compareTo(rule1));
        System.assertEquals(0, rule2.compareTo(rule4));
        System.assertEquals(0, noRule.compareTo(noRule));
        System.assertEquals(-1, noRule.compareTo(rule1));
        System.assertEquals(-1, rule1.compareTo(rule2));
        System.assertEquals(-1, rule2.compareTo(rule3));
        System.assertEquals(1, rule3.compareTo(rule2));
        System.assertEquals(1, rule3.compareTo(rule1));
    }

    @IsTest
    private static void testMaskingRules() {
            // This test is for code coverage purposes only
            Test.startTest();
            System.assertNotEquals(null, rflib_StringUtil.replaceWithAllMaskingRules(SOURCE));
            Test.stopTest();
    }

    @IsTest
    private static void testConvertListToStringForQuery_NullList() {
        List<String> testList = null;
        String result = rflib_StringUtil.convertListToStringForQuery(testList);
        System.assertEquals('(\'\')', result, 'The result should be (\'\') for a null list.');
    }

    @IsTest
    private static void testConvertListToStringForQuery_EmptyList() {
        List<String> testList = new List<String>();
        String result = rflib_StringUtil.convertListToStringForQuery(testList);
        System.assertEquals('(\'\')', result, 'The result should be (\'\') for an empty list.');
    }

    @IsTest
    private static void testConvertListToStringForQuery_OneElementList() {
        List<String> testList = new List<String>{'Test1'};
        String result = rflib_StringUtil.convertListToStringForQuery(testList);
        System.assertEquals('(\'Test1\')', result, 'The result should correctly format a single-element list.');
    }

    @IsTest
    private static void testConvertListToStringForQuery_MultipleElementsList() {
        List<String> testList = new List<String>{'Test1', 'Test2', 'Test3'};
        String result = rflib_StringUtil.convertListToStringForQuery(testList);
        System.assertEquals('(\'Test1\',\'Test2\',\'Test3\')', result, 'The result should correctly format a multi-element list.');
    }

    private static rflib_Masking_Rule__mdt createRule(String target, String replacement) {
        return createRule(target, replacement, 1);
    }

    private static rflib_Masking_Rule__mdt createRule(Integer order) {
        return createRule('[0-9]+', '*****', order);
    }

    private static rflib_Masking_Rule__mdt createRule(String target, String replacement, Integer order) {
        return new rflib_Masking_Rule__mdt(
            Target__c = target,
            Target_Type__c = 'RegEx',
            Replacement__c = replacement,
            Is_Active__c = true,
            Order__c = order
        );
    }
}
