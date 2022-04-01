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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
@TestVisible
private class rflib_FeatureSwitchTest {
    
    private static final String TRIGGER_SWITCH = 'All_Triggers';

    @TestVisible private static final String USER_SWITCH = 'FeatureSwitch1';
    @TestVisible private static final String GROUP_SWITCH = 'FeatureSwitchGroup';
    @TestVisible private static final String PROFILE_SWITCH = 'FeatureSwitch2';
    @TestVisible private static final String GLOBAL_SWITCH = 'FeatureSwitch3';
    @TestVisible private static final String ANOTHER_USER_SWITCH = 'FeatureSwitch4';
    @TestVisible private static final String NON_EXISTING_FEATURE_SWITCH = 'DoesNotExist';

    @TestVisible private static final User USER = rflib_UserFactory.insertAndRetrieve('John', 'Smith', 'Standard User');

    @TestVisible
    private static void setup() {
        rflib_FeatureSwitch.featureSwitches = new Map<String,Map<String,Boolean>> {
            USER_SWITCH => new Map<String,Boolean> {
                'john.smith@rflib.com' => true,
                'Some_Group' => false,
                'Standard User' => false,
                rflib_FeatureSwitch.GLOBAL_SCOPE => false
            },

            GROUP_SWITCH => new Map<String,Boolean> {
                'Some_Group' => true,
                'Standard User' => false,
                rflib_FeatureSwitch.GLOBAL_SCOPE => false
            },

            PROFILE_SWITCH => new Map<String,Boolean> {
                'Standard User' => true,
                rflib_FeatureSwitch.GLOBAL_SCOPE => false
            },

            GLOBAL_SWITCH => new Map<String,Boolean> {
                rflib_FeatureSwitch.GLOBAL_SCOPE => true
            },

            ANOTHER_USER_SWITCH => new Map<String,Boolean> {
                'another_user@rflib.com' => true
            }
        };

        rflib_FeatureSwitch.DEFAULT_VALUE = false;

        Group someGroup = new Group(
            DeveloperName = 'Some_Group',
            Name = 'Some Group'
        );

        insert someGroup;

        insert new GroupMember(
            GroupId = someGroup.Id,
            UserOrGroupId = USER.Id
        );

        rflib_FeatureSwitch.directPublicGroupAssociations = null;
    }

    @IsTest
    private static void testUserSwitch() {
        setup();

        System.runAs(USER) {
           System.assertEquals(true, rflib_FeatureSwitch.isTurnedOn(USER_SWITCH));
           System.assertEquals(false, rflib_FeatureSwitch.isTurnedOff(USER_SWITCH));
        }
    }

    @IsTest
    private static void testGroupSwitch() {
        setup();

        System.runAs(USER) {
           System.assertEquals(true, rflib_FeatureSwitch.isTurnedOn(GROUP_SWITCH));
           System.assertEquals(false, rflib_FeatureSwitch.isTurnedOff(GROUP_SWITCH));
        }
    }

    @IsTest
    private static void testProfileSwitch() {
        setup();

        System.runAs(USER) {
           System.assertEquals(true, rflib_FeatureSwitch.isTurnedOn(PROFILE_SWITCH));
           System.assertEquals(false, rflib_FeatureSwitch.isTurnedOff(PROFILE_SWITCH));
        }
    }

    @IsTest
    private static void testGlobalSwitch() {
        setup();

        System.runAs(USER) {
           System.assertEquals(true, rflib_FeatureSwitch.isTurnedOn(GLOBAL_SWITCH));
           System.assertEquals(false, rflib_FeatureSwitch.isTurnedOff(GLOBAL_SWITCH));
        }
    }

    @IsTest
    private static void testNonExistingSwitch() {
        setup();

        System.runAs(USER) {
           System.assertEquals(false, rflib_FeatureSwitch.isTurnedOn(NON_EXISTING_FEATURE_SWITCH));
           System.assertEquals(true, rflib_FeatureSwitch.isTurnedOff(NON_EXISTING_FEATURE_SWITCH));
        }
    }

    @IsTest
    private static void testExistingSwitchWithoutMatch() {
        setup();

        System.runAs(USER) {
           System.assertEquals(false, rflib_FeatureSwitch.isTurnedOn(ANOTHER_USER_SWITCH));
           System.assertEquals(true, rflib_FeatureSwitch.isTurnedOff(ANOTHER_USER_SWITCH));
        }
    }

    @IsTest
    private static void testGetAllScopedValues() {
        setup();

        System.runAs(USER) {
            Map<String,Boolean> result = rflib_FeatureSwitch.getAllScopedValues();
            System.assertEquals(5, result.size());

            System.assertEquals(true, result.get(USER_SWITCH));
            System.assertEquals(true, result.get(GROUP_SWITCH));
            System.assertEquals(true, result.get(PROFILE_SWITCH));
            System.assertEquals(true, result.get(GLOBAL_SWITCH));
            System.assertEquals(false, result.get(ANOTHER_USER_SWITCH));
        }
    }
}
