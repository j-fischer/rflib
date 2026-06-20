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
const loggerSettings = require('./data/loggerSettings.json');

// Drains the microtask queue across the logger's async initialization (settings query) and the
// deferred platform-event publishes, which are chained off the initialization promise.
const flushPromises = async () => {
    for (let i = 0; i < 5; i++) {
        await Promise.resolve();
    }
};

describe('Logger Tests', () => {
    let mockDataApi;
    let mockComputeLogger;
    let context;

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

        context = {
            id: 'context-id-123',
            org: { id: 'org-id-123' },
            user: { id: 'user-id-123' }
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
            const logger = createLogger(mockDataApi, context, 'factory', {
                computeLogger: mockComputeLogger,
                shouldClearLogs: true
            });

            await flushPromises();

            expect(logger).toBeDefined();
            expect(mockComputeLogger.debug).toHaveBeenCalledWith(expect.stringContaining('Cleared log messages'));
        });
    });

    describe('compute logger', () => {
        let logger;

        beforeEach(async () => {
            logger = require('../rflibLogger').createLogger(mockDataApi, context, 'console', {
                computeLogger: mockComputeLogger
            });
            await flushPromises();
            // Discard the compute-logger calls emitted while settings were loading (e.g. the
            // "Retrieved settings" diagnostic logged at DEBUG before the NONE level is applied),
            // so the level-filtering assertions below see only the calls made under test.
            jest.clearAllMocks();
        });

        function executeComputeLogLevelTest(validLogLevels) {
            const logLevels = ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'];

            validLogLevels.forEach((level) => {
                logger[level.toLowerCase()]('SHOULD LOG to console');
                const mockFn = mockComputeLogger[level === 'FATAL' ? 'error' : level.toLowerCase()];
                expect(mockFn).toHaveBeenCalledWith(
                    expect.stringContaining(`${level}|context-id-123|console|SHOULD LOG to console`)
                );
            });

            logLevels
                .filter((level) => !validLogLevels.includes(level))
                .forEach((level) => {
                    logger[level.toLowerCase()]('should not log to console');
                    const mockFn = mockComputeLogger[level.toLowerCase()];
                    expect(mockFn).not.toHaveBeenCalled();
                });
        }

        it('should log based on configured level', () => {
            logger.setConfig({ computeLogLevel: 'INFO' });
            executeComputeLogLevelTest(['FATAL', 'ERROR', 'WARN', 'INFO']);
        });

        it('should not throw when the compute logger omits an optional method', async () => {
            const partialComputeLogger = {
                // no `trace` — satisfies the optional ComputeLogger type but lacks the method
                debug: jest.fn(),
                info: jest.fn(),
                warn: jest.fn(),
                error: jest.fn()
            };
            const partialLogger = require('../rflibLogger').createLogger(mockDataApi, context, 'partial', {
                computeLogger: partialComputeLogger
            });
            await flushPromises();

            partialLogger.setConfig({ computeLogLevel: 'TRACE' });

            expect(() => partialLogger.trace('no trace sink')).not.toThrow();
            partialLogger.error('present sink');
            expect(partialComputeLogger.error).toHaveBeenCalledWith(expect.stringContaining('present sink'));
        });
    });

    describe('server logging', () => {
        let logger;

        beforeEach(async () => {
            logger = require('../rflibLogger').createLogger(mockDataApi, context, 'server', {
                computeLogger: mockComputeLogger,
                shouldClearLogs: true
            });
            await flushPromises();
        });

        async function executeServerLogLevelTest(serverLogLevel, validLogLevels) {
            logger.setConfig({ serverLogLevel });

            validLogLevels.forEach((level) => {
                logger[level.toLowerCase()]('SHOULD LOG to server');
            });

            await flushPromises();

            expect(mockDataApi.create).toHaveBeenCalledTimes(validLogLevels.length);

            validLogLevels.forEach((level) => {
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

        it('should default Platform_Info__c to a Node runtime telemetry payload', async () => {
            logger.setConfig({ serverLogLevel: 'INFO' });
            logger.error('telemetry check');

            await flushPromises();

            const logEvent = mockDataApi.create.mock.calls
                .map((call) => call[0])
                .find((record) => record.type === 'rflib_Log_Event__e');
            const platformInfo = JSON.parse(logEvent.fields.Platform_Info__c);

            expect(platformInfo.node).toBeDefined();
            expect(platformInfo.node.version).toBe(process.version);
            expect(platformInfo.node.memory).toBeDefined();
        });

        it('should use a caller-supplied platformInfoProvider when given', async () => {
            const customLogger = require('../rflibLogger').createLogger(mockDataApi, context, 'custom', {
                computeLogger: mockComputeLogger,
                platformInfoProvider: () => ({ lwr: { route: '/home', ssr: true } })
            });
            await flushPromises();

            customLogger.setConfig({ serverLogLevel: 'INFO' });
            customLogger.error('custom telemetry');

            await flushPromises();

            const logEvent = mockDataApi.create.mock.calls
                .map((call) => call[0])
                .find((record) => record.fields.Context__c === 'custom');
            const platformInfo = JSON.parse(logEvent.fields.Platform_Info__c);

            expect(platformInfo).toEqual({ lwr: { route: '/home', ssr: true } });
        });
    });

    describe('per-user isolation', () => {
        it('should keep each context log stack separate when loggers run concurrently', async () => {
            const factory = require('../rflibLogger');
            const contextA = { id: 'req-A', org: { id: 'org-id-123' }, user: { id: 'user-A' } };
            const contextB = { id: 'req-B', org: { id: 'org-id-123' }, user: { id: 'user-B' } };

            const loggerA = factory.createLogger(mockDataApi, contextA, 'svcA', { computeLogger: mockComputeLogger });
            const loggerB = factory.createLogger(mockDataApi, contextB, 'svcB', { computeLogger: mockComputeLogger });
            await flushPromises();

            loggerA.setConfig({ serverLogLevel: 'INFO' });
            loggerB.setConfig({ serverLogLevel: 'INFO' });

            // Interleave logging from the two contexts on the same shared process.
            loggerA.info('A-only message 1');
            loggerB.info('B-only message 1');
            loggerA.error('A-only message 2');
            loggerB.error('B-only message 2');

            await flushPromises();

            const logEvents = mockDataApi.create.mock.calls
                .map((call) => call[0])
                .filter((record) => record.type === 'rflib_Log_Event__e');

            const aPublishes = logEvents.filter((record) => record.fields.Request_Id__c === 'req-A');
            const bPublishes = logEvents.filter((record) => record.fields.Request_Id__c === 'req-B');

            expect(aPublishes.length).toBeGreaterThan(0);
            expect(bPublishes.length).toBeGreaterThan(0);

            aPublishes.forEach((record) => {
                expect(record.fields.Log_Messages__c).toContain('A-only');
                expect(record.fields.Log_Messages__c).not.toContain('B-only');
            });
            bPublishes.forEach((record) => {
                expect(record.fields.Log_Messages__c).toContain('B-only');
                expect(record.fields.Log_Messages__c).not.toContain('A-only');
            });
        });
    });

    describe('settings hierarchy', () => {
        it('should resolve the most specific row (user overrides org)', async () => {
            mockDataApi.query.mockResolvedValue([
                {
                    SetupOwnerId: 'org-id-123',
                    Client_Console_Log_Level__c: 'NONE',
                    Client_Server_Log_Level__c: 'ERROR',
                    Client_Log_Size__c: 100
                },
                {
                    SetupOwnerId: 'user-id-123',
                    Client_Console_Log_Level__c: 'NONE',
                    Client_Server_Log_Level__c: 'INFO',
                    Client_Log_Size__c: 100
                }
            ]);

            const logger = require('../rflibLogger').createLogger(mockDataApi, context, 'hierarchy', {
                computeLogger: mockComputeLogger
            });
            await flushPromises();

            // The user row sets serverLogLevel INFO; an INFO statement publishes. With only the
            // org-level ERROR default it would not, proving the user override was resolved.
            logger.info('user override applies');
            await flushPromises();

            const logEvents = mockDataApi.create.mock.calls
                .map((call) => call[0])
                .filter((record) => record.type === 'rflib_Log_Event__e');
            expect(logEvents.some((record) => record.fields.Log_Level__c === 'INFO')).toBe(true);
        });

        it('should merge rows field-by-field so null overrides inherit from less specific rows', async () => {
            mockDataApi.query.mockResolvedValue([
                {
                    SetupOwnerId: 'org-id-123',
                    Client_Console_Log_Level__c: 'NONE',
                    Client_Server_Log_Level__c: 'INFO',
                    Client_Log_Size__c: 100
                },
                {
                    // Sparse user override: only raises the console level; server level / size are null.
                    SetupOwnerId: 'user-id-123',
                    Client_Console_Log_Level__c: 'TRACE',
                    Client_Server_Log_Level__c: null,
                    Client_Log_Size__c: null
                }
            ]);

            const logger = require('../rflibLogger').createLogger(mockDataApi, context, 'merge', {
                computeLogger: mockComputeLogger
            });
            await flushPromises();

            logger.info('inherited server level');
            await flushPromises();

            const logEvents = mockDataApi.create.mock.calls
                .map((call) => call[0])
                .filter((record) => record.type === 'rflib_Log_Event__e');
            // serverLogLevel inherits INFO from the org row (user field is null); had the whole user
            // row replaced it, serverLogLevel would default to WARN and the INFO event would not publish.
            expect(logEvents.some((record) => record.fields.Log_Level__c === 'INFO')).toBe(true);
            // computeLogLevel comes from the user row (TRACE), so the INFO statement also reached stdout.
            expect(mockComputeLogger.info).toHaveBeenCalledWith(expect.stringContaining('inherited server level'));
        });
    });

    describe('log timer', () => {
        let logger;
        let logFactory;

        beforeEach(async () => {
            logFactory = require('../rflibLogger');
            logger = logFactory.createLogger(mockDataApi, context, 'timer', { computeLogger: mockComputeLogger });
            await Promise.resolve();
        });

        it('should log timer events', () => {
            const timerName = 'Test Timer';
            logger.setConfig({ computeLogLevel: 'TRACE' });

            const logTimer = logFactory.startLogTimer(logger, 10, timerName);
            logTimer.done();

            expect(mockComputeLogger.trace).toHaveBeenCalledWith(
                expect.stringMatching(
                    /^TRACE\|context-id-123\|timer\|Test Timer took a total of \d+ms \(threshold=10ms\)\.$/
                )
            );
        });
    });
});
