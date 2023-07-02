/*
 * Copyright (c) 2023 Johannes Fischer <fischer.jh@gmail.com>
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
public with sharing class rflib_GetFeatureSwitchValueAction {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_GetFeatureSwitchValueAction');

    @InvocableMethod(label='Get Feature Switch Value' category='RFLIB' description='Returns the Feature Switch Value for a given switch' iconName='resource:rflib_FeatureSwitchActionIcon:icon')
    public static List<FeatureSwitchInfoResult> getFeatureSwitchValue(List<FeatureSwitchInfoRequest> switchInfoList) {

        LOGGER.debug('Flow Action invoked for switches with name: ' + switchInfoList); 
    
        List<FeatureSwitchInfoResult> result = new List<FeatureSwitchInfoResult>();
        for (FeatureSwitchInfoRequest switchRequest : switchInfoList) {
            FeatureSwitchInfoResult switchInfo = new FeatureSwitchInfoResult();
            switchInfo.name = switchRequest.name;
            switchInfo.isTurnedOn = rflib_FeatureSwitch.isTurnedOn(switchRequest.name);
            result.add(switchInfo);
        }

        LOGGER.info('Results: ' + result); 

        return result;
    }
    
    public class FeatureSwitchInfoRequest {

        @InvocableVariable(
            label = 'Switch Name'
            description = 'The name of the Feature Switch'
            required=true
        )
        public String name;
    }

    public class FeatureSwitchInfoResult {

        @InvocableVariable(
            label = 'Switch Name'
            description = 'The name of the Feature Switch'
        )
        public String name;

        @InvocableVariable(
            label = 'Is Turned On'
            description = 'Indicates whether the provided switch name is turned on or not'
        )
        public Boolean isTurnedOn;
    }
}