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
 * @description Plugin for Flow Builder to retrieve the hierarchical value of a feature switch. 
 */ 
global class rflib_FeatureSwitchPlugin implements Process.Plugin {

    private static final rflib_Logger LOGGER = rflib_DefaultLogger.createFromCustomSettings('rflib_FeatureSwitchPlugin');

    /**
     * Returns whether a feature switch is turned on or not. The evaluation will consider the proper
     * hierarchy of the settings, meaning it will return either the value specifically configured for
     * the current user, the current user's profile, or the global fallback. 
     *
     * If the switch is not configured in the Custom Metadata for the user's hierarchy, the return value
     * will be `false`.
     * 
     * @param request The `Process.PluginRequest` including the `siwtchName` input parameter.
     * @return A `Process.PluginResult` including the `turnedOn` output parameter.
     */
    global Process.PluginResult invoke(Process.PluginRequest request) {
        String switchName = (String) request.inputParameters.get('switchName');
        LOGGER.info('Flow Plugin invoked for switch with name: ' + switchName); 
    
        Boolean isTurnedOn = rflib_FeatureSwitch.isTurnedOn(switchName);

        Map<String,Object> result = new Map<String,Object> {
          'isTurnedOn' => isTurnedOn
        }; 

        return new Process.PluginResult(result); 
    } 

    /**
     * Describes the tool element for the Flow Builder.
     * 
     * @return A `Process.PluginDescribeResult` describing the action.
     */
    global Process.PluginDescribeResult describe() { 
        Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
        result.name = 'Is Feature Switch Turned On';
        result.description = 'Returns the value for a feature switch including the user and profile hierarchy';
        result.tag = 'rflib';
        result.inputParameters = new 
           List<Process.PluginDescribeResult.InputParameter>{ 
                new Process.PluginDescribeResult.InputParameter('switchName', 
                    Process.PluginDescribeResult.ParameterType.STRING, true) 
            }; 

        result.outputParameters = new 
            List<Process.PluginDescribeResult.OutputParameter>{              
                new Process.PluginDescribeResult.OutputParameter('isTurnedOn', 
                    Process.PluginDescribeResult.ParameterType.BOOLEAN)
            }; 
        return result; 
    }
}
