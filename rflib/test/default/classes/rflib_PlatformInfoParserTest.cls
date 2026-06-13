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
private class rflib_PlatformInfoParserTest {

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testFlatten_ApexFormat() {
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Platform_Info__c = '{"CPU Time":123,"SOQL queries":5,"Heap Size":4096}'
        );

        Test.startTest();
        Map<String, Object> result = rflib_PlatformInfoParser.flatten(evt);
        Test.stopTest();

        Assert.areEqual(3, result.size(), 'Expected three flattened Apex attributes.');
        Assert.areEqual(123, result.get('rflib.apex.cpu_time'), 'CPU Time should map to rflib.apex.cpu_time.');
        Assert.areEqual(5, result.get('rflib.apex.soql_queries'), 'SOQL queries should map to rflib.apex.soql_queries.');
        Assert.areEqual(4096, result.get('rflib.apex.heap_size'), 'Heap Size should map to rflib.apex.heap_size.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testFlatten_BrowserFormat() {
        String browserInfo = '{"timeOrigin":1699999999999,"timing":{"domComplete":1234,"navigationStart":1000},"navigation":{"type":0,"redirectCount":0},"userAgent":"Mozilla/5.0 (Test)"}';
        rflib_Log_Event__e evt = new rflib_Log_Event__e(Platform_Info__c = browserInfo);

        Test.startTest();
        Map<String, Object> result = rflib_PlatformInfoParser.flatten(evt);
        Test.stopTest();

        Assert.areEqual('Mozilla/5.0 (Test)', result.get('user_agent.original'), 'userAgent should map to the OTel semantic attribute.');
        Assert.areEqual(1699999999999L, result.get('rflib.browser.time_origin'), 'timeOrigin should be flattened and snake_cased.');
        Assert.areEqual(1234, result.get('rflib.browser.timing.dom_complete'), 'Nested timing.domComplete should be flattened.');
        Assert.areEqual(1000, result.get('rflib.browser.timing.navigation_start'), 'Nested timing.navigationStart should be flattened.');
        Assert.areEqual(0, result.get('rflib.browser.navigation.type'), 'Nested navigation.type should be flattened.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testFlatten_GenericNestedFormat() {
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Platform_Info__c = '{"custom":{"nestedValue":7},"flag":true}'
        );

        Test.startTest();
        Map<String, Object> result = rflib_PlatformInfoParser.flatten(evt);
        Test.stopTest();

        Assert.areEqual(7, result.get('rflib.platform.custom.nested_value'), 'Generic nested values should flatten under rflib.platform.');
        Assert.areEqual(true, result.get('rflib.platform.flag'), 'Boolean values should be preserved.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testFlatten_ListValues() {
        rflib_Log_Event__e evt = new rflib_Log_Event__e(
            Platform_Info__c = '{"items":["a","b"],"nested":{"more":1}}'
        );

        Test.startTest();
        Map<String, Object> result = rflib_PlatformInfoParser.flatten(evt);
        Test.stopTest();

        Assert.areEqual('a', result.get('rflib.platform.items.0'), 'List items should be indexed.');
        Assert.areEqual('b', result.get('rflib.platform.items.1'), 'List items should be indexed.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testFlatten_MalformedJson() {
        rflib_Log_Event__e evt = new rflib_Log_Event__e(Platform_Info__c = 'not-json');

        Test.startTest();
        Map<String, Object> result = rflib_PlatformInfoParser.flatten(evt);
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Malformed JSON should yield a single raw entry.');
        Assert.areEqual('not-json', result.get('rflib.platform_info'), 'Malformed JSON should be preserved as the raw string.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testFlatten_NonObjectJson() {
        rflib_Log_Event__e evt = new rflib_Log_Event__e(Platform_Info__c = '[1,2,3]');

        Test.startTest();
        Map<String, Object> result = rflib_PlatformInfoParser.flatten(evt);
        Test.stopTest();

        Assert.areEqual('[1,2,3]', result.get('rflib.platform_info'), 'Non-object JSON should be preserved as the raw string.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testFlatten_Blank() {
        Assert.areEqual(0, rflib_PlatformInfoParser.flatten(new rflib_Log_Event__e(Platform_Info__c = '')).size(), 'Blank info should yield an empty map.');
        Assert.areEqual(0, rflib_PlatformInfoParser.flatten(new rflib_Log_Event__e()).size(), 'Null info should yield an empty map.');
        Assert.areEqual(0, rflib_PlatformInfoParser.flatten(null).size(), 'Null event should yield an empty map.');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    private static void testNormalizeKey() {
        Assert.areEqual('cpu_time', rflib_PlatformInfoParser.normalizeKey('CPU Time'));
        Assert.areEqual('soql_queries', rflib_PlatformInfoParser.normalizeKey('SOQL queries'));
        Assert.areEqual('time_origin', rflib_PlatformInfoParser.normalizeKey('timeOrigin'));
        Assert.areEqual('dom_complete', rflib_PlatformInfoParser.normalizeKey('domComplete'));
        Assert.areEqual('redirect_count', rflib_PlatformInfoParser.normalizeKey('redirectCount'));
    }
}
