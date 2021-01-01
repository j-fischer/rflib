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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_FeatureSwitchPluginTest {
    
    @IsTest
    private static void testUserSwitch() {
        rflib_FeatureSwitchTest.setup();

        executePluginAndAssertSwitchOn(rflib_FeatureSwitchTest.USER_SWITCH);
    }

    @IsTest
    private static void testProfileSwitch() {
        rflib_FeatureSwitchTest.setup();

        executePluginAndAssertSwitchOn(rflib_FeatureSwitchTest.PROFILE_SWITCH);
    }

    @IsTest
    private static void testGlobalSwitch() {
        rflib_FeatureSwitchTest.setup();

        executePluginAndAssertSwitchOn(rflib_FeatureSwitchTest.GLOBAL_SWITCH);
    }

    @IsTest
    private static void testNonExistingSwitch() {
        rflib_FeatureSwitchTest.setup();

        executePluginAndAssertSwitchOff(rflib_FeatureSwitchTest.NON_EXISTING_FEATURE_SWITCH);
    }
    
    @IsTest
    private static void testExistingSwitchWithoutMatch() {
        rflib_FeatureSwitchTest.setup();
        
        executePluginAndAssertSwitchOff(rflib_FeatureSwitchTest.ANOTHER_USER_SWITCH);
    
    }

    @IsTest
    private static void testDescribe() {
        System.runAs(rflib_FeatureSwitchTest.USER) {

            Process.PluginDescribeResult result = new rflib_FeatureSwitchPlugin().describe();

            System.assertEquals('rflib', result.tag);
        }
    }

    private static void executePluginAndAssertSwitchOn(String switchName) {
        executePluginAndAssertSwitch(switchName, true);
    }

    private static void executePluginAndAssertSwitchOff(String switchName) {
        executePluginAndAssertSwitch(switchName, false);
    }

    private static void executePluginAndAssertSwitch(String switchName, Boolean expectedTurnedOnValue) {
        System.runAs(rflib_FeatureSwitchTest.USER) {

            Map<String, Object> inputParams = new Map<String, Object> {
                'switchName' => switchName
            };

            Process.PluginRequest request = new Process.PluginRequest(inputParams);          
            Process.PluginResult result = new rflib_FeatureSwitchPlugin().invoke(request);

            System.assertEquals(expectedTurnedOnValue, result.outputParameters.get('isTurnedOn'));
        }
    }
}
