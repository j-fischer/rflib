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
private class rflib_LoggerUtilTest {

    private static final rflib_MockLogger LOGGER = new rflib_MockLogger();

    @IsTest
    private static void testGetFacotry_DefaultValue() {
        rflib_LoggerFactory factory = rflib_LoggerUtil.getFactory();

        System.assert(factory instanceof rflib_DefaultLoggerFactory, 'Default Logger Factory instance should be of type rflib_DefaultLoggerFactory');
    }

    @IsTest
    private static void testGetFacotry_ConfiguredValue() {
        rflib_TestUtil.prepareLoggerForUnitTests();

        rflib_LoggerFactory factory = rflib_LoggerUtil.getFactory();

        System.assert(factory instanceof rflib_MockLoggerFactory, 'Configured Logger Factory instance should be of type rflib_MockLoggerFactory');
    }

    @IsTest
    private static void testCreateLogTimer_DefaultValue() {
        rflib_LogTimer logTimer = rflib_LoggerUtil.startLogTimer(LOGGER, 500, 'some message');

        System.assert(logTimer instanceof rflib_DefaultLogTimer, 'Default Logger Timer instance should be of type rflib_DefaultLogTimer');
    }

    @IsTest
    private static void testCreateLogTimer_ConfiguredValue() {
        rflib_TestUtil.prepareLoggerForUnitTests();

        rflib_LogTimer logTimer = rflib_LoggerUtil.startLogTimer(LOGGER, 500, 'some message');

        System.assert(logTimer instanceof rflib_MockLogTimer, 'Configured LogTimer instance should be of type rflib_MockLogTimer');
    }

    @IsTest
    private static void testCreateLogFinalizer_DefaultValue() {
        rflib_LogFinalizer logFinalizer = rflib_LoggerUtil.createLogFinalizer(LOGGER);

        System.assert(logFinalizer instanceof rflib_DefaultLogFinalizer, 'Default LogFinalizer instance should be of type rflib_DefaultLogFinalizer');
    }

    @IsTest
    private static void testCreateLogFinalizer_ConfiguredValue() {
        rflib_TestUtil.prepareLoggerForUnitTests();

        rflib_LogFinalizer logFinalizer = rflib_LoggerUtil.createLogFinalizer(LOGGER);

        System.assert(logFinalizer instanceof rflib_MockLogFinalizer, 'Configured LogFinalizer instance should be of type rflib_MockLogFinalizer');
    }
}
