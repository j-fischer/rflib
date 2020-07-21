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
import _ from 'lodash';
import JsMock from 'js-mock';
import Matcher from 'hamjest';

let mockGetSettings, mockLogMessageToServer, mockConsoleLog;
JsMock.watch(() => {
    mockGetSettings = JsMock.mock('getSettings');
    mockLogMessageToServer = JsMock.mock('logMessageToServer');
    mockConsoleLog = JsMock.mockGlobal('console.log');
});

jest.mock(
    '@salesforce/apex/rflib_LoggerController.getSettings',
    () => {
        return { default: mockGetSettings };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_LoggerController.log',
    () => {
        return { default: mockLogMessageToServer };
    },
    { virtual: true }
);

const loggerSettings = require('./data/loggerSettings.json');

describe('createLogger()', () => {
    beforeEach(mockConsoleLog.activate);

    afterEach(JsMock.assertWatched);

    it('factory should return a logger instance', () => {
        mockConsoleLog
            .expect()
            .once()
            .with(Matcher.containsString('Retrieved settings for user'));

        mockGetSettings
            .once()
            .with()
            .returns(Promise.resolve(loggerSettings.default));

        const createLogger = require('c/rflibLogger').createLogger;

        let logger = createLogger('factory');
        return Promise.resolve().then(() => {
            expect(logger).toBeDefined();
        });
    });
});

describe('console logger', () => {
    let logger;
    beforeEach(() => {
        mockConsoleLog.activate();
        mockGetSettings
            .allowing()
            .with()
            .returns(Promise.resolve(loggerSettings.default));

        logger = require('c/rflibLogger').createLogger('console');
    });

    afterEach(() => {
        JsMock.assertWatched();

        logger.setConfig({
            consoleLogLevel: 'NONE'
        });
    });

    it('should not log when setting is set to NONE', () => {
        executeConsoleLogLevelTest([]);
    });

    it('should log FATAL when setting is set to FATAL', () => {
        logger.setConfig({
            consoleLogLevel: 'FATAL'
        });

        executeConsoleLogLevelTest(['FATAL']);
    });

    it('should log ERROR when setting is set to ERROR', () => {
        logger.setConfig({
            consoleLogLevel: 'ERROR'
        });

        executeConsoleLogLevelTest(['FATAL', 'ERROR']);
    });

    it('should log WARN when setting is set to WARN', () => {
        logger.setConfig({
            consoleLogLevel: 'WARN'
        });

        executeConsoleLogLevelTest(['FATAL', 'ERROR', 'WARN']);
    });

    it('should log INFO when setting is set to INFO', () => {
        logger.setConfig({
            consoleLogLevel: 'INFO'
        });

        executeConsoleLogLevelTest(['FATAL', 'ERROR', 'WARN', 'INFO']);
    });

    it('should log DEBUG when setting is set to DEBUG', () => {
        logger.setConfig({
            consoleLogLevel: 'DEBUG'
        });

        executeConsoleLogLevelTest(['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG']);
    });

    it('should log TRACE when setting is set to TRACE', () => {
        logger.setConfig({
            consoleLogLevel: 'TRACE'
        });

        executeConsoleLogLevelTest(['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE']);
    });

    function executeConsoleLogLevelTest(validLogLevels) {
        let logLevels = ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'];

        _.each(validLogLevels, logLevel => {
            mockConsoleLog
                .expect()
                .once()
                .with(Matcher.containsStrings('console', logLevel, 'SHOULD LOG'));

            logger[logLevel.toLowerCase()]('SHOULD LOG to console');
        });

        _.each(_.pullAll(logLevels, validLogLevels), logLevel => {
            logger[logLevel.toLowerCase()]('should not log to console');
        });
    }
});

describe('server logger', () => {
    beforeEach(() => {
        mockConsoleLog.restore();

        mockGetSettings
            .allowing()
            .with()
            .returns(Promise.resolve(loggerSettings.default));
    });

    afterEach(JsMock.assertWatched);

    it('should not log when setting is set to NONE', () => {
        return executeServerLogLevelTest('NONE', []);
    });

    it('should log FATAL when setting is set to FATAL', () => {
        return executeServerLogLevelTest('FATAL', ['FATAL']);
    });

    it('should not log ERROR when setting is set to ERROR', () => {
        return executeServerLogLevelTest('ERROR', ['FATAL', 'ERROR']);
    });

    it('should not log WARN when setting is set to WARN', () => {
        return executeServerLogLevelTest('WARN', ['FATAL', 'ERROR', 'WARN']);
    });

    it('should not log INFO when setting is set to INFO', () => {
        return executeServerLogLevelTest('INFO', ['FATAL', 'ERROR', 'WARN', 'INFO']);
    });

    it('should not log DEBUG when setting is set to DEBUG', () => {
        return executeServerLogLevelTest('DEBUG', ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG']);
    });

    it('should not log TRACE when setting is set to TRACE', () => {
        return executeServerLogLevelTest('TRACE', ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE']);
    });

    function executeServerLogLevelTest(serverLogLevel, validLogLevels) {
        let logLevels = ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'];

        const willLogConfigChange = _.includes(['INFO', 'DEBUG', 'TRACE'], serverLogLevel);
        const expectedServerLogInvocations = willLogConfigChange ? validLogLevels.length + 1 : validLogLevels.length;

        mockLogMessageToServer.exactly(expectedServerLogInvocations);
        let index = 1;

        if (willLogConfigChange) {
            mockLogMessageToServer
                .onCall(index++)
                .with(
                    Matcher.hasProperties({
                        level: 'INFO',
                        context: 'server',
                        message: Matcher.containsString('Setting new logger configuration for server')
                    })
                )
                .returns(Promise.resolve());
        }

        _.each(validLogLevels, logLevel => {
            mockLogMessageToServer
                .onCall(index++)
                .with(
                    Matcher.hasProperties({
                        level: logLevel,
                        context: 'server',
                        message: Matcher.allOf(
                            Matcher.endsWith('SHOULD LOG to server'),
                            Matcher.containsString('should not log to server')
                        )
                    })
                )
                .returns(Promise.resolve());
        });

        let logger = require('c/rflibLogger').createLogger('server');

        return Promise.resolve().then(() => {
            logger.setConfig({
                serverLogLevel: serverLogLevel
            });

            _.each(_.pullAll(logLevels, validLogLevels), logLevel => {
                logger[logLevel.toLowerCase()]('should not log to server');
            });

            _.each(validLogLevels, logLevel => {
                logger[logLevel.toLowerCase()]('SHOULD LOG to server');
            });
        });
    }
});

describe('server logger failure', () => {
    beforeEach(() => {
        mockConsoleLog.activate();
    });

    afterEach(JsMock.assertWatched);

    it('should log to the console that the server log failed', () => {
        mockGetSettings
            .allowing()
            .with()
            .returns(Promise.resolve(loggerSettings.default));

        mockLogMessageToServer.once().returns(Promise.reject(new Error('foo bar error')));

        mockConsoleLog
            .expect()
            .once()
            .with(
                Matcher.allOf(
                    Matcher.containsString('Failed to log message to server for'),
                    Matcher.containsString('foo bar error')
                )
            );

        let logger = require('c/rflibLogger').createLogger('server');

        return Promise.resolve().then(() => {
            logger.setConfig({
                serverLogLevel: 'FATAL'
            });

            logger.fatal('some message');
        });
    });
});
