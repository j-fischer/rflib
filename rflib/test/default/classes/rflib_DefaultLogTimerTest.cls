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
private class rflib_DefaultLogTimerTest {

    private static final Integer LOG_ALL_MESSAGE_THRESHOLD = -1;
    private static final Integer DO_NOT_EXCEED_THRESHOLD = 10;

    private static final String LOG_MESSAGE = 'Action Foo Bar';

    private static final rflib_MockLogger MOCK_LOGGER = new rflib_MockLogger();

    private static final rflib_DefaultLogTimer LOG_TIMER = new rflib_DefaultLogTimer();
    
    @IsTest
    private static void testDone_LoggerHasNotBeenStarted() {
        try {
            LOG_TIMER.done();
            System.assert(false, 'Expected InvalidStateException');
        } catch (rflib_InvalidStateException ex) {
            System.assertEquals('Timer has not been started', ex.getMessage());
        }
    }

    @IsTest
    private static void testStart_LoggerAlreadyStarted() {
        LOG_TIMER.start(MOCK_LOGGER, rflib_LogLevel.WARN, LOG_ALL_MESSAGE_THRESHOLD, LOG_MESSAGE);
        
        try {
            LOG_TIMER.start(MOCK_LOGGER, rflib_LogLevel.WARN, LOG_ALL_MESSAGE_THRESHOLD, LOG_MESSAGE);
            System.assert(false, 'Expected InvalidStateException');
        } catch (rflib_InvalidStateException ex) {
            System.assertEquals('Timer has already been started', ex.getMessage());
        }
    }

    @IsTest
    private static void testStartDone_LogsTraceIfBelowThreshold() {
        LOG_TIMER.start(MOCK_LOGGER, rflib_LogLevel.WARN, DO_NOT_EXCEED_THRESHOLD, LOG_MESSAGE);
        
        LOG_TIMER.done();

        assertLogger(rflib_LogLevel.TRACE);
    }

    @IsTest
    private static void testStartDone_LogsProvidedLevelIfPastThreshold() {
        executeLogsProvidedLevelIfPsatThresholdTest(rflib_LogLevel.DEBUG);
        executeLogsProvidedLevelIfPsatThresholdTest(rflib_LogLevel.INFO);
        executeLogsProvidedLevelIfPsatThresholdTest(rflib_LogLevel.WARN);
        executeLogsProvidedLevelIfPsatThresholdTest(rflib_LogLevel.ERROR);
        executeLogsProvidedLevelIfPsatThresholdTest(rflib_LogLevel.FATAL);
    }

    private static void executeLogsProvidedLevelIfPsatThresholdTest(rflib_LogLevel providedLevel) {
        MOCK_LOGGER.logDetails.clear();
        
        rflib_DefaultLogTimer logTimer = new rflib_DefaultLogTimer();

        logTimer.start(MOCK_LOGGER, providedLevel, LOG_ALL_MESSAGE_THRESHOLD, LOG_MESSAGE);
        logTimer.done();

        assertLogger(providedLevel);
    }

    private static void assertLogger(rflib_LogLevel expectedLogLevel) {
        System.assertEquals(1, MOCK_LOGGER.logDetails.size());

        rflib_MockLogger.LogDetails logDetails = MOCK_LOGGER.logDetails.get(0);
        System.assertEquals(expectedLogLevel, logDetails.logLevel);
        System.assert(logDetails.message.contains(LOG_MESSAGE));
        System.assert(logDetails.message.contains('took'));
    }
}
