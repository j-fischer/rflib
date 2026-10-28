/*
 * Copyright (c) 2026 Johannes Fischer <fischer.jh@gmail.com>
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
/**
 * Creates loggers that throw when a DEBUG or INFO statement is logged, so tests can reach the error
 * handling of code whose own operations cannot fail. Set it as `rflib_LoggerUtil.loggerFactory` before
 * the class under test is referenced, as classes create their logger when they load.
 */
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
public class rflib_MockFailingLoggerFactory implements rflib_LoggerFactory {

    public static final String FAILURE_MESSAGE = 'Logging failed';

    public rflib_Logger createLogger(String context) {
        return createFailingLogger();
    }

    public rflib_Logger createBatchedLogger(String context) {
        return createFailingLogger();
    }

    private rflib_Logger createFailingLogger() {
        rflib_MockLogger logger = new rflib_MockLogger();
        logger.exceptionsToThrow.put(rflib_LogLevel.DEBUG, new FailingLoggerException(FAILURE_MESSAGE));
        logger.exceptionsToThrow.put(rflib_LogLevel.INFO, new FailingLoggerException(FAILURE_MESSAGE));
        return logger;
    }

    public class FailingLoggerException extends Exception {}
}
