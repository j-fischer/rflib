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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_OmniStudioRemoteActionsTest {

    private static final rflib_MockLoggerFactory loggerFactory = new rflib_MockLoggerFactory(rflib_LogLevel.DEBUG);
    private static final rflib_MockApplicationEventLogger applicationEventLogger = new rflib_MockApplicationEventLogger();

    static void setup() {
        rflib_OmniStudioRemoteActions.loggerFactory = loggerFactory;
        rflib_OmniStudioRemoteActions.applicationEventLogger = applicationEventLogger;
    }

    @IsTest
    private static void testLogMessage_Fatal() {
        runLogMessageTest('FATAL', 'FATAL');
    }

    @IsTest
    private static void testLogMessage_Error() {
        runLogMessageTest('ERROR', 'ERROR');
    }

    @IsTest
    private static void testLogMessage_Warn() {
        runLogMessageTest('WARN', 'WARN');
    }

    @IsTest
    private static void testLogMessage_Info() {
        runLogMessageTest('INFO', 'INFO');
    }

    @IsTest
    private static void testLogMessage_Debug() {
        runLogMessageTest('DEBUG', 'DEBUG');
    }

    @IsTest
    private static void testLogMessage_UnknownLogLevel() {
        runLogMessageTest('FOOBAR', 'WARN');
    }

    @IsTest
    private static void testLogApplicationEvent() {
        setup();

        rflib_MockApplicationEventLogger mockAppEventLogger = new rflib_MockApplicationEventLogger();
        rflib_OmniStudioRemoteActions.applicationEventLogger = mockAppEventLogger;

        String eventName = 'TestEvent';
        String relatedRecordId = '001xx000003DHP0';
        String additionalDetails = 'Additional details for the event';

        Map<String, Object> input = new Map<String, Object>{
            'eventName' => eventName,
            'relatedRecordId' => relatedRecordId,
            'additionalDetails' => additionalDetails
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
        rflib_OmniStudioRemoteActions controller = new rflib_OmniStudioRemoteActions();
        Boolean result = (Boolean) controller.call('LogApplicationEvent', args);
        Test.stopTest();

        Assert.isTrue(result, 'Expected method to return true');
        Assert.isNull(output.get('errorMessage'), 'Expected no error message');
        Assert.areEqual(eventName, mockAppEventLogger.capturedEventName);
        Assert.areEqual(relatedRecordId, mockAppEventLogger.capturedRelatedRecordId);
        Assert.areEqual(additionalDetails, mockAppEventLogger.capturedAdditionalDetails);
    }

    @IsTest
    private static void testLogFailure() {
        setup();

        String context = 'TestFailureContext';
        String message = 'This is a test failure message';
        String argsJson = '["arg1", "arg2"]';

        Map<String, Object> input = new Map<String, Object>{
            'context' => context,
            'message' => message,
            'args' => argsJson
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
        rflib_OmniStudioRemoteActions controller = new rflib_OmniStudioRemoteActions();
        Boolean result = (Boolean) controller.call('LogFailure', args);
        Test.stopTest();

        Assert.isTrue(result, 'Expected method to return true');
        Assert.isNull(output.get('errorMessage'), 'Expected no error message');
        Assert.isTrue(loggerFactory.debugLogCapture.containsInAnyMessage('ERROR'), 'debugLogger did not contain ERROR message');
    }

    @IsTest
    private static void testInvalidMethodName() {
        setup();

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> option = new Map<String, Object>();

        Test.startTest();
        rflib_OmniStudioRemoteActions controller = new rflib_OmniStudioRemoteActions();
        Map<String, Object> callableInput = new Map<String, Object>{'input' => input, 'output' => output, 'option' => option};
        Boolean result = (Boolean) controller.call('InvalidMethod', callableInput);
        Test.stopTest();

        Assert.isFalse(result, 'Expected method to return false');
        Assert.areEqual('Invalid method name: InvalidMethod', output.get('errorMessage'));
    }

    @IsTest
    private static void testCallMethod() {
        setup();

        String action = 'LogMessage';
        String context = 'TestContext';
        String logLevel = 'INFO';
        String message = 'This is a test log message';
        String argsJson = '["arg1", "arg2"]'; // Note: Those args should be ignored. 

        Map<String, Object> input = new Map<String, Object>{
            'context' => context,
            'level' => logLevel,
            'message' => message,
            'args' => argsJson
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
        rflib_OmniStudioRemoteActions controller = new rflib_OmniStudioRemoteActions();
        Object result = controller.call(action, args);
        Test.stopTest();

        Assert.isTrue((Boolean)result, 'Expected method to return true');
        Assert.isNull(output.get('errorMessage'), 'Expected no error message');
        Assert.isTrue(loggerFactory.debugLogCapture.containsInAnyMessage(logLevel), 'debugLogger did not contain ' + logLevel + ' message');
    }

    @IsTest
    private static void testDefaultContextValue() {
        setup();

        String logLevel = 'INFO';
        String message = 'This is a test log message';
        String argsJson = '["arg1", "arg2"]';

        Map<String, Object> input = new Map<String, Object>{
            'level' => logLevel,
            'message' => message,
            'args' => argsJson
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
        rflib_OmniStudioRemoteActions controller = new rflib_OmniStudioRemoteActions();
        Boolean result = (Boolean) controller.call('LogMessage', args);
        Test.stopTest();

        Assert.isTrue(result, 'Expected method to return true');
        Assert.isNull(output.get('errorMessage'), 'Expected no error message');
        Assert.isTrue(loggerFactory.debugLogCapture.containsInAnyMessage('rflib_OmniStudioRemoteActions'), 'Expected default context value was not used');
    }

    @IsTest
    private static void testDefaultLogLevelValue() {
        setup();

        String context = 'TestContext';
        String message = 'This is a test log message';
        String argsJson = '["arg1", "arg2"]';

        Map<String, Object> input = new Map<String, Object>{
            'context' => context,
            'message' => message,
            'args' => argsJson
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
        rflib_OmniStudioRemoteActions controller = new rflib_OmniStudioRemoteActions();
        Boolean result = (Boolean) controller.call('LogMessage', args);
        Test.stopTest();

        Assert.isTrue(result, 'Expected method to return true');
        Assert.isNull(output.get('errorMessage'), 'Expected no error message');
        Assert.isTrue(loggerFactory.debugLogCapture.containsInAnyMessage('WARN'), 'Expected default log level value was not used');
    }

    @IsTest
    private static void testDefaultMessageValue() {
        setup();

        String context = 'TestContext';
        String logLevel = 'INFO';

        Map<String, Object> input = new Map<String, Object>{
            'context' => context,
            'level' => logLevel
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
        rflib_OmniStudioRemoteActions controller = new rflib_OmniStudioRemoteActions();
        Boolean result = (Boolean) controller.call('LogMessage', args);
        Test.stopTest();

        Assert.isTrue(result, 'Expected method to return true');
        Assert.isNull(output.get('errorMessage'), 'Expected no error message');
        Assert.isTrue(loggerFactory.debugLogCapture.containsInAnyMessage('context'), 'Expected default message value was not used');
    }

    private static void runLogMessageTest(String logLevel, String expectedLogLevel) {
        setup();

        String context = 'TestContext';
        String message = 'This is a test log message';
        String argsJson = '["arg1", "arg2"]';

        Map<String, Object> input = new Map<String, Object>{
            'context' => context,
            'level' => logLevel,
            'message' => message,
            'args' => argsJson
        };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
        rflib_OmniStudioRemoteActions controller = new rflib_OmniStudioRemoteActions();
        Boolean result = (Boolean) controller.call('LogMessage', args);
        Test.stopTest();

        Assert.isTrue(result, 'Expected method to return true');
        Assert.isNull(output.get('errorMessage'), 'Expected no error message');
        Assert.isTrue(loggerFactory.debugLogCapture.containsInAnyMessage(expectedLogLevel), 'debugLogger did not contain ' + expectedLogLevel + ' message');
    }
}