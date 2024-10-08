/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
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
global class rflib_OmniStudioRemoteActions implements System.Callable {
    @TestVisible
    private static rflib_LoggerFactory loggerFactory = rflib_LoggerUtil.getFactory();
    @TestVisible
    private static rflib_ApplicationEventLogger applicationEventLogger = rflib_LoggerUtil.getApplicationEventLogger();

    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return this.invokeMethod(action, input, output, options);
    }

    private Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> option) {
        System.debug('*** Input Parameters *** ' + input);

        String methodNameAsLowerCase = methodName.toLowerCase();
        if (methodNameAsLowerCase == 'logmessage') {
            logMessage(input);
        } else if (methodNameAsLowerCase == 'logapplicationevent') {
            logApplicationEvent(input);
        } else if (methodNameAsLowerCase == 'logfailure') {
            logFailure(input);
        } else {
            output.put('errorMessage', 'Invalid method name: ' + methodName);
            return false;
        }

        return true;
    }

    private static void logFailure(Map<String,Object> input) {
        logMessage(new Map<String,Object>{
            'context' => input.get('context'),
            'level' => 'ERROR',
            'message' => 'Error caught in TryCatchBlock: ' + JSON.serializePretty(input)
        });
    }

    private static void logMessage(Map<String,Object> input) {
        String context = (String)input.get('context') ?? 'rflib_OmniStudioRemoteActions';
        String logLevel = (String)input.get('level');
        String message = (String)input.get('message');
        List<String> args = parseArgs((String)input.get('args'));

        rflib_Logger logger = loggerFactory.createLogger(context);

        switch on logLevel.toUpperCase() {
            when 'FATAL' {
                logger.fatal(message, args);
            }
            when 'ERROR' {
                logger.error(message, args);
            }
            when 'WARN' {
                logger.warn(message, args);
            }
            when 'INFO' {
                logger.info(message, args);
            }
            when 'DEBUG' {
                logger.debug(message, args);
            }
            when else {
                logger.warn(message, args);
            }
        }
    }

    private static void logApplicationEvent(Map<String,Object> input) {
        String eventName = (String)input.get('eventName');
        String relatedRecordId = (String)input.get('relatedRecordId');
        String additionalDetails = (String)input.get('additionalDetails');

        applicationEventLogger.logApplicationEvent(eventName, relatedRecordId, additionalDetails);
    }

    private static List<String> parseArgs(String argsJson) {
        if (String.isNotBlank(argsJson)) {
            try {
                return (List<String>) JSON.deserialize(argsJson, List<String>.class);
            } catch (JSONException e) {
                System.debug('Failed to parse args JSON: ' + e.getMessage());
                return new List<String>();
            }
        }
        return new List<String>();
    }
}
