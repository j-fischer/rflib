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
private class rflib_LogTimerFlowActionTest {
    
    private static final rflib_MockLoggerFactory MOCK_LOGGER_FACTORY = new rflib_MockLoggerFactory(rflib_LogLevel.TRACE);
    private static final rflib_MockLogger MOCK_STOP_TIMER_LOGGER = new rflib_MockLogger();

    private static void setup() {
        rflib_StopLogTimerFlowAction.LOGGER = MOCK_STOP_TIMER_LOGGER;
        rflib_LoggerUtil.loggerFactory = MOCK_LOGGER_FACTORY;
    }
    
    @IsTest
    private static void testStopNonExistingTimer() {
        setup();

        rflib_StopLogTimerFlowAction.StopLogTimerInfo logTimerInfo = new rflib_StopLogTimerFlowAction.StopLogTimerInfo();
        logTimerInfo.logTimerName = 'unknownTimer';
    
        rflib_StopLogTimerFlowAction.stopLogTimer(new List<rflib_StopLogTimerFlowAction.StopLogTimerInfo> { logTimerInfo });
    
        System.assertEquals(1, MOCK_STOP_TIMER_LOGGER.logDetails.size());
        System.assertEquals(rflib_LogLevel.ERROR, MOCK_STOP_TIMER_LOGGER.logDetails.get(0).logLevel);
        System.assert(MOCK_STOP_TIMER_LOGGER.logDetails.get(0).message.contains('LogTimer with name "{0}" could not be found'), MOCK_STOP_TIMER_LOGGER.logDetails.get(0).message);
    }

    @IsTest
    private static void testLogTimerDoesNotExceedThreshold() {
        setup();
        
        rflib_StartLogTimerFlowAction.StartLogTimerInfo startLogTimerInfo = new rflib_StartLogTimerFlowAction.StartLogTimerInfo();
        startLogTimerInfo.logTimerName = 'timer1';
        startLogTimerInfo.context = 'LogTimerTest';
        startLogTimerInfo.logLevel = 'INFO';
        startLogTimerInfo.threshold = 1000;
        startLogTimerInfo.message = 'Foo Bar';

        rflib_StopLogTimerFlowAction.StopLogTimerInfo stopLogTimerInfo = new rflib_StopLogTimerFlowAction.StopLogTimerInfo();
        stopLogTimerInfo.logTimerName = 'timer1';
    
        rflib_StartLogTimerFlowAction.startLogTimer(new List<rflib_StartLogTimerFlowAction.StartLogTimerInfo> { startLogTimerInfo });
        rflib_StopLogTimerFlowAction.stopLogTimer(new List<rflib_StopLogTimerFlowAction.StopLogTimerInfo> { stopLogTimerInfo });
    
        System.assertEquals(0, MOCK_LOGGER_FACTORY.debugLogCapture.capturedLogMessages.size());
    }

    @IsTest
    private static void testLogTimerExceedsThreshold() {
        setup();
        
        rflib_StartLogTimerFlowAction.StartLogTimerInfo startLogTimerInfo = new rflib_StartLogTimerFlowAction.StartLogTimerInfo();
        startLogTimerInfo.logTimerName = 'timer1';
        startLogTimerInfo.context = 'LogTimerTest';
        startLogTimerInfo.logLevel = 'INFO';
        startLogTimerInfo.threshold = -1;
        startLogTimerInfo.message = 'Foo Bar';

        rflib_StopLogTimerFlowAction.StopLogTimerInfo stopLogTimerInfo = new rflib_StopLogTimerFlowAction.StopLogTimerInfo();
        stopLogTimerInfo.logTimerName = 'timer1';
    
        rflib_StartLogTimerFlowAction.startLogTimer(new List<rflib_StartLogTimerFlowAction.StartLogTimerInfo> { startLogTimerInfo });
        rflib_StopLogTimerFlowAction.stopLogTimer(new List<rflib_StopLogTimerFlowAction.StopLogTimerInfo> { stopLogTimerInfo });
    
        System.assertEquals(1, MOCK_LOGGER_FACTORY.debugLogCapture.capturedLogMessages.size());
        System.assert(MOCK_LOGGER_FACTORY.debugLogCapture.containsInAnyMessage('INFO'));
        System.assert(MOCK_LOGGER_FACTORY.debugLogCapture.containsInAnyMessage('Foo Bar'));
    }


}
