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
/* eslint-disable jest/expect-expect */
import _ from 'lodash';
import JsMock from 'js-mock';
import Matcher from 'hamjest';

const functionContext = {
    id: 'context-id-123',
    org: {
        id: 'org-id-123',
        user: {
            id: 'user-id-123'
        },

        dataApi: {
            query: function () {},
            newUnitOfWork: function () {},
            commitUnitOfWork: function () {}
        }
    }
};
const computeLogger = {
    trace: function () {},
    debug: function () {},
    info: function () {},
    warn: function () {},
    error: function () {}
};
const uow = {
    registerCreate: function () {}
};
let mockComputeLogger, mockUow;
JsMock.watch(() => {
    functionContext.org.dataApi = JsMock.mock('dataApi', functionContext.org.dataApi);
    mockUow = JsMock.mock('uow', uow);
    mockComputeLogger = JsMock.mock('computeLogger', computeLogger);
});

const loggerSettings = require('./data/loggerSettings.json');

describe('create logger', () => {
    afterEach(JsMock.assertWatched);

    it('factory should return a logger instance', () => {
        functionContext.org.dataApi.query
            .once()
            .with(
                "SELECT Archive_Log_Level__c, Functions_Log_Size__c, Functions_Compute_Log_Level__c, Functions_Server_Log_Level__c FROM rflib_Logger_Settings__c WHERE SetupOwnerId = 'org-id-123'"
            )
            .returns(Promise.resolve(loggerSettings.default));
        functionContext.org.dataApi.newUnitOfWork.twice().returns(mockUow);

        mockComputeLogger.debug.expect().twice();
        mockComputeLogger.debug.expect().onFirstCall().with(Matcher.containsString('Cleared log messages'));
        mockComputeLogger.debug.expect().onSecondCall().with(Matcher.containsString('Retrieved settings for user'));

        const createLogger = require('../rflibLogger.js').createLogger;

        let logger = createLogger(functionContext, mockComputeLogger, 'factory', true);

        return Promise.resolve().then(() => {
            expect(logger).toBeDefined();
        });
    });
});

describe('compute logger', () => {
    let logger;
    beforeEach(() => {
        functionContext.org.dataApi.query.allowing().returns(Promise.resolve(loggerSettings.default));
        functionContext.org.dataApi.newUnitOfWork.allowing().returns(mockUow);
        functionContext.org.dataApi.commitUnitOfWork.allowing().with(mockUow).returns(Promise.resolve());
        mockComputeLogger.debug.allowing().with(Matcher.containsString('Retrieved settings for user'));
        mockComputeLogger.info.allowing().with(Matcher.containsString('Setting new logger configuration for'));

        logger = require('../rflibLogger.js').createLogger(functionContext, mockComputeLogger, 'console');
    });

    afterEach(JsMock.assertWatched);

    it('should not log when setting is set to NONE', () => {
        executecomputeLogLevelTest([]);
    });

    it('should log FATAL when setting is set to FATAL', () => {
        logger.setConfig({
            computeLogLevel: 'FATAL'
        });

        executecomputeLogLevelTest(['FATAL']);
    });

    it('should log ERROR when setting is set to ERROR', () => {
        logger.setConfig({
            computeLogLevel: 'ERROR'
        });

        executecomputeLogLevelTest(['FATAL', 'ERROR']);
    });

    it('should log WARN when setting is set to WARN', () => {
        logger.setConfig({
            computeLogLevel: 'WARN'
        });

        executecomputeLogLevelTest(['FATAL', 'ERROR', 'WARN']);
    });

    it('should log INFO when setting is set to INFO', () => {
        logger.setConfig({
            computeLogLevel: 'INFO'
        });

        executecomputeLogLevelTest(['FATAL', 'ERROR', 'WARN', 'INFO']);
    });

    it('should log DEBUG when setting is set to DEBUG', () => {
        logger.setConfig({
            computeLogLevel: 'DEBUG'
        });

        executecomputeLogLevelTest(['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG']);
    });

    it('should log TRACE when setting is set to TRACE', () => {
        logger.setConfig({
            computeLogLevel: 'TRACE'
        });

        executecomputeLogLevelTest(['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE']);
    });

    function executecomputeLogLevelTest(validLogLevels) {
        let logLevels = ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'];

        _.each(validLogLevels, (logLevel) => {
            mockComputeLogger[logLevel === 'FATAL' ? 'error' : logLevel.toLowerCase()]
                .expect()
                .once()
                .with(Matcher.containsStrings('console', logLevel, 'SHOULD LOG'));

            logger[logLevel.toLowerCase()]('SHOULD LOG to console');
        });

        _.each(_.pullAll(logLevels, validLogLevels), (logLevel) => {
            logger[logLevel.toLowerCase()]('should not log to console');
        });
    }
});

describe('log reporting', () => {
    beforeEach(() => {
        functionContext.org.dataApi.query.allowing().returns(Promise.resolve(loggerSettings.default));
        functionContext.org.dataApi.newUnitOfWork.allowing().returns(mockUow);
        functionContext.org.dataApi.commitUnitOfWork.allowing().with(mockUow).returns(Promise.resolve());
        mockComputeLogger.debug.allowing().with(Matcher.containsString('Retrieved settings for user'));
        mockComputeLogger.info.allowing().with(Matcher.containsString('Setting new logger configuration for'));
    });

    afterEach(JsMock.assertWatched);

    it('should not log when setting is set to NONE', () => {
        return executeServerLogLevelTest('NONE', []);
    });

    it('should log FATAL when setting is set to FATAL', () => {
        return executeServerLogLevelTest('FATAL', ['FATAL']);
    });

    it('should log ERROR when setting is set to ERROR', () => {
        return executeServerLogLevelTest('ERROR', ['FATAL', 'ERROR']);
    });

    it('should log WARN when setting is set to WARN', () => {
        return executeServerLogLevelTest('WARN', ['FATAL', 'ERROR', 'WARN']);
    });

    it('should log INFO when setting is set to INFO', () => {
        return executeServerLogLevelTest('INFO', ['FATAL', 'ERROR', 'WARN', 'INFO']);
    });

    it('should not log DEBUG when setting is set to DEBUG', () => {
        return executeServerLogLevelTest('DEBUG', ['FATAL', 'ERROR', 'WARN', 'INFO']);
    });

    it('should not log TRACE when setting is set to TRACE', () => {
        return executeServerLogLevelTest('TRACE', ['FATAL', 'ERROR', 'WARN', 'INFO']);
    });

    function executeServerLogLevelTest(serverLogLevel, validLogLevels) {
        let logLevels = ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'];

        const expectedServerLogInvocations = validLogLevels.length;

        mockUow.registerCreate.exactly(expectedServerLogInvocations);
        functionContext.org.dataApi.newUnitOfWork.allowing().returns(mockUow);
        functionContext.org.dataApi.commitUnitOfWork.exactly(expectedServerLogInvocations);
        let index = 1;

        _.each(validLogLevels, (logLevel) => {
            mockUow.registerCreate
                .onCall(index)
                .with(
                    Matcher.hasProperties({
                        fields: Matcher.hasProperties({
                            Log_Level__c: logLevel,
                            Context__c: 'server',
                            Log_Messages__c: Matcher.allOf(
                                Matcher.endsWith('SHOULD LOG to server'),
                                Matcher.containsString('should not log to server')
                            )
                        })
                    })
                )
                .returns(mockUow);
            functionContext.org.dataApi.commitUnitOfWork
                .onCall(index++)
                .with(mockUow)
                .returns(Promise.resolve());
        });

        mockComputeLogger.debug.allowing();
        let logger = require('../rflibLogger.js').createLogger(functionContext, mockComputeLogger, 'server', true);

        return Promise.resolve().then(() => {
            logger.setConfig({
                serverLogLevel: serverLogLevel
            });

            _.each(_.pullAll(logLevels, validLogLevels), (logLevel) => {
                logger[logLevel.toLowerCase()]('should not log to server');
            });

            _.each(validLogLevels, (logLevel) => {
                logger[logLevel.toLowerCase()]('SHOULD LOG to server');
            });
        });
    }
});

describe('log reporting failure', () => {
    afterEach(JsMock.assertWatched);

    it('should log to the console that the server log failed', () => {
        mockComputeLogger.debug.allowing().with(Matcher.containsString('Retrieved settings for user'));
        mockComputeLogger.info.allowing().with(Matcher.containsString('Setting new logger configuration for'));

        mockUow.registerCreate.once();

        functionContext.org.dataApi.query.allowing().returns(Promise.resolve(loggerSettings.default));
        functionContext.org.dataApi.newUnitOfWork.allowing().returns(mockUow);
        functionContext.org.dataApi.commitUnitOfWork
            .once()
            .with(mockUow)
            .returns(Promise.reject(new Error('foo bar error')));

        mockComputeLogger.error
            .expect()
            .once()
            .with(
                Matcher.allOf(
                    Matcher.containsString('Failed to log message to server for'),
                    Matcher.containsString('foo bar error')
                )
            );

        mockComputeLogger.debug.allowing();
        let logger = require('../rflibLogger.js').createLogger(functionContext, mockComputeLogger, 'server');

        return Promise.resolve().then(() => {
            logger.setConfig({
                serverLogLevel: 'FATAL'
            });

            logger.fatal('some message');
        });
    });
});

describe('log timer', () => {
    let logFactory;
    let logger;

    beforeEach(() => {
        functionContext.org.dataApi.query.allowing().returns(Promise.resolve(loggerSettings.default));
        functionContext.org.dataApi.newUnitOfWork.allowing().returns(mockUow);
        functionContext.org.dataApi.commitUnitOfWork.allowing().with(mockUow).returns(Promise.resolve());

        mockComputeLogger.debug.allowing();
        mockComputeLogger.info.allowing().with(Matcher.containsString('Setting new logger configuration for'));

        logFactory = require('../rflibLogger.js');
        logger = logFactory.createLogger(functionContext, mockComputeLogger, 'log timer', true);

        logger.setConfig({
            computeLogLevel: 'NONE',
            serverLogLevel: 'NONE'
        });
    });

    afterEach(JsMock.assertWatched);

    it('should log TRACE statement if threshold was not exceeded', () => {
        logger.setConfig({
            computeLogLevel: 'TRACE'
        });

        let timerName = 'Foo Bar';

        mockComputeLogger.trace
            .expect()
            .once()
            .with(Matcher.containsStrings('log timer', 'TRACE', timerName, 'took a total of', 'threshold'));

        let logTimer = logFactory.startLogTimer(logger, 10, timerName);

        logTimer.done();
    });

    it('should log if threshold is exceeded', async () => {
        let timerName = 'Foo Bar';
        let logLevel = 'WARN';

        logger.setConfig({
            computeLogLevel: logLevel
        });

        mockComputeLogger.warn
            .expect()
            .once()
            .with(Matcher.containsStrings('log timer', logLevel, timerName, 'took a total of', 'threshold'));

        let logTimer = logFactory.startLogTimer(logger, -1, timerName);

        logTimer.done();
    });

    it('should log with custom log level if provided', async () => {
        let timerName = 'Foo Bar';
        let logLevel = 'ERROR';

        logger.setConfig({
            computeLogLevel: logLevel
        });

        mockComputeLogger.error
            .expect()
            .once()
            .with(Matcher.containsStrings('log timer', logLevel, timerName, 'took a total of', 'threshold'));

        let logTimer = logFactory.startLogTimer(logger, -1, timerName, logLevel);

        logTimer.done();
    });
});
