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
const loggerSettings = require('./data/loggerSettings.json');

describe('Logger Tests', () => {
    let mockDataApi;
    let mockComputeLogger;
    let functionContext;
    
    beforeEach(() => {
        jest.useFakeTimers();
        
        // Setup mocks
        mockDataApi = {
            query: jest.fn(),
            create: jest.fn()
        };

        mockComputeLogger = {
            trace: jest.fn(),
            debug: jest.fn(),
            info: jest.fn(),
            warn: jest.fn(),
            error: jest.fn()
        };

        functionContext = {
            id: 'context-id-123',
            org: {
                id: 'org-id-123',
                user: { id: 'user-id-123' },
                dataApi: mockDataApi
            }
        };

        // Default implementations
        mockDataApi.query.mockResolvedValue(loggerSettings.default);
        mockDataApi.create.mockResolvedValue(undefined);
    });

    afterEach(() => {
        jest.clearAllMocks();
        jest.useRealTimers();
    });

    describe('create logger', () => {
        it('factory should return a logger instance', async () => {
            const createLogger = require('../rflibLogger').createLogger;
            const logger = createLogger(functionContext, mockComputeLogger, 'factory', true);
            
            await Promise.resolve();
            
            expect(logger).toBeDefined();
            expect(mockComputeLogger.debug).toHaveBeenCalledWith(
                expect.stringContaining('Cleared log messages')
            );
        });
    });

    describe('compute logger', () => {
        let logger;

        beforeEach(async () => {
            logger = require('../rflibLogger').createLogger(
                functionContext, 
                mockComputeLogger, 
                'console'
            );
            await Promise.resolve();
        });

        function executeComputeLogLevelTest(validLogLevels) {
            const logLevels = ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'];
            
            validLogLevels.forEach(level => {
                logger[level.toLowerCase()]('SHOULD LOG to console');
                const mockFn = mockComputeLogger[level === 'FATAL' ? 'error' : level.toLowerCase()];
                expect(mockFn).toHaveBeenCalledWith(
                    expect.stringContaining(`${level}|context-id-123|console|SHOULD LOG to console`)
                );
            });

            logLevels
                .filter(level => !validLogLevels.includes(level))
                .forEach(level => {
                    logger[level.toLowerCase()]('should not log to console');
                    const mockFn = mockComputeLogger[level.toLowerCase()];
                    expect(mockFn).not.toHaveBeenCalled();
                });
        }

        it('should log based on configured level', () => {
            logger.setConfig({ computeLogLevel: 'INFO' });
            executeComputeLogLevelTest(['FATAL', 'ERROR', 'WARN', 'INFO']);
        });
    });

    describe('server logging', () => {
        let logger;

        beforeEach(async () => {
            logger = require('../rflibLogger').createLogger(
                functionContext, 
                mockComputeLogger, 
                'server',
                true
            );
            await Promise.resolve();
        });

        async function executeServerLogLevelTest(serverLogLevel, validLogLevels) {
            logger.setConfig({ serverLogLevel });

            validLogLevels.forEach(level => {
                logger[level.toLowerCase()]('SHOULD LOG to server');
            });

            await Promise.resolve();

            expect(mockDataApi.create).toHaveBeenCalledTimes(validLogLevels.length);
            
            validLogLevels.forEach(level => {
                expect(mockDataApi.create).toHaveBeenCalledWith(
                    expect.objectContaining({
                        type: 'rflib_Log_Event__e',
                        fields: expect.objectContaining({
                            Log_Level__c: level,
                            Context__c: 'server'
                        })
                    })
                );
            });
        }

        it('should handle server logging levels', async () => {
            await executeServerLogLevelTest('INFO', ['FATAL', 'ERROR', 'WARN', 'INFO']);
        });
    });

    describe('log timer', () => {
        let logger;
        let logFactory;

        beforeEach(async () => {
            logFactory = require('../rflibLogger');
            logger = logFactory.createLogger(functionContext, mockComputeLogger, 'timer');
            await Promise.resolve();
        });

        it('should log timer events', () => {
            const timerName = 'Test Timer';
            logger.setConfig({ computeLogLevel: 'TRACE' });
            
            const logTimer = logFactory.startLogTimer(logger, 10, timerName);
            logTimer.done();

            expect(mockComputeLogger.trace).toHaveBeenCalledWith(
                expect.stringMatching(/^TRACE\|context-id-123\|timer\|Test Timer took a total of \d+ms \(threshold=10ms\)\.$/)
            );
        });
    });
});