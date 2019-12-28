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
 * @group Feature Switch
 * @description Use this class to retrieve hierarchical feature switch values. 
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public without sharing class rflib_FeatureSwitch {
    
    private static final rflib_Logger LOGGER = rflib_DefaultLogger.createFromCustomSettings('rflib_FeatureSwitch');

    @TestVisible
    private static final String GLOBAL_SCOPE = '__GLOBAL__';

    @TestVisible
    private static Map<String, Map<String, Boolean>> featureSwitches {
        get {
            if (featureSwitches == null) {
                featureSwitches = getAllFeatureSwitches();
            }
            return featureSwitches;
        }
        private set;
    }

    /**
     * Returns whether a feature switch is turned on or not. The evaluation will consider the proper
     * hierarchy of the settings, meaning it will return either the value specifically configured for
     * the current user, the current user's profile, or the global fallback. 
     *
     * If the switch is not configured in the Custom Metadata for the user's hierarchy, the return value
     * will be `false`.
     * 
     * @param switchName The name of the feature switch to be evaluated.
     */
    public static Boolean isTurnedOn(String switchName) {
        LOGGER.info('Evaluating feature switch ' + switchName);

        Boolean result = getFeatureSwitchValue(switchName);

        LOGGER.info('Feature switch {0} is turned on? {1}', new Object[] { switchName, result });

        return result;
    } 

    /**
     * Returns whether a feature switch is turned off or not. The evaluation will consider the proper
     * hierarchy of the settings, meaning it will return either the value specifically configured for
     * the current user, the current user's profile, or the global fallback. 
     *
     * If the switch is not configured in the Custom Metadata for the user's hierarchy, the return value
     * will be `true`.
     * 
     * @param switchName The name of the feature switch to be evaluated.
     */
    public static Boolean isTurnedOff(String switchName) {
        LOGGER.info('Evaluating feature switch ' + switchName);

        Boolean result = getFeatureSwitchValue(switchName) == false;

        LOGGER.info('Feature switch {0} is turned off? {1}', new Object[] { switchName, result });

        return result;
    } 

    private static Boolean getFeatureSwitchValue(String switchName) {
        if (!featureSwitches.containsKey(switchName)) {
            return false;
        }

        Map<String, Boolean> scopedFeatureSwitchValues = featureSwitches.get(switchName);
        if (scopedFeatureSwitchValues.containsKey(UserInfo.getUserName())) {
            return scopedFeatureSwitchValues.get(UserInfo.getUserName());
        }

        String profileName = getProfileName(UserInfo.getProfileId());
        if (scopedFeatureSwitchValues.containsKey(profileName)) {
            return scopedFeatureSwitchValues.get(profileName);
        }

        return scopedFeatureSwitchValues.containsKey(GLOBAL_SCOPE)
            ? scopedFeatureSwitchValues.get(GLOBAL_SCOPE)
            : false;
    }

    private static String getProfileName(Id profileId) {
        Profile p = [SELECT Name FROM Profile WHERE Id = :profileId];
        return p.Name;
    }

    private static Map<String, Map<String, Boolean>> getAllFeatureSwitches() {
        List<rflib_Feature_Switch__mdt> allFeaturesSwitches = [
            SELECT DeveloperName, Scope_Name__c, Scope_Type__c, Turned_On__c 
            FROM rflib_Feature_Switch__mdt
        ];

        LOGGER.debug('All feature switch values: ' + JSON.serialize(allFeaturesSwitches));

        Map<String, Map<String, Boolean>> result = new Map<String, Map<String, Boolean>>();
        for (rflib_Feature_Switch__mdt featureSwitch : allFeaturesSwitches) {
            if (!result.containsKey(featureSwitch.DeveloperName)) {
                result.put(featureSwitch.DeveloperName, new Map<String, Boolean>());
            }

            Map<String, Boolean> scopedSwitchSettings = result.get(featureSwitch.DeveloperName);
            if (featureSwitch.Scope_type__c == 'Global') {
                scopedSwitchSettings.put(GLOBAL_SCOPE, featureSwitch.Turned_On__c);
            } else {
                scopedSwitchSettings.put(featureSwitch.Scope_Name__c, featureSwitch.Turned_On__c);
            }
        }

        return result;
    }
}
