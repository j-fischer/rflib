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
/* eslint-disable compat/compat */
import _ from 'lodash';

const loggerSettings = require('./data/loggerSettings.json');

// Mock Salesforce Apex calls
jest.mock(
    '@salesforce/apex/rflib_LoggerController.getSettings',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_LoggerController.log',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

describe('create logger', () => {
    let consoleSpy;
    let getSettingsMock;

    beforeEach(() => {
        consoleSpy = jest.spyOn(console, 'log').mockImplementation();
        getSettingsMock = require('@salesforce/apex/rflib_LoggerController.getSettings').default;
        getSettingsMock.mockResolvedValue(loggerSettings.default);
    });

    afterEach(() => {
        consoleSpy.mockRestore();
        jest.clearAllMocks();
    });

    it('factory should return a logger instance', async () => {
        const createLogger = require('c/rflibLogger').createLogger;
        const logger = createLogger('factory');

        await Promise.resolve();

        expect(logger).toBeDefined();
        await expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringContaining('Retrieved settings for user')
        );
    });
});

describe('console logger', () => {
    let logger;
    let consoleSpy;
    let getSettingsMock;

    beforeEach(() => {
        consoleSpy = jest.spyOn(console, 'log').mockImplementation();
        getSettingsMock = require('@salesforce/apex/rflib_LoggerController.getSettings').default;
        getSettingsMock.mockResolvedValue(loggerSettings.default);
        logger = require('c/rflibLogger').createLogger('console');
        logger.setConfig({ consoleLogLevel: 'NONE', serverLogLevel: "NONE" });
    });

    afterEach(() => {
        consoleSpy.mockRestore();
        jest.clearAllMocks();
        logger.setConfig({ consoleLogLevel: 'NONE', serverLogLevel: "NONE" });
    });

    function executeConsoleLogLevelTest(validLogLevels) {
        const logLevels = ['FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE'];

        validLogLevels.forEach(logLevel => {
            logger[logLevel.toLowerCase()]('SHOULD LOG to console');
            expect(consoleSpy).toHaveBeenCalledWith(`${logLevel}|console|SHOULD LOG to console`)
        });

        _.pullAll(logLevels, validLogLevels).forEach(logLevel => {
            logger[logLevel.toLowerCase()]('should not log to console');
            expect(consoleSpy).not.toHaveBeenCalledWith(
                expect.stringContaining(`${logLevel}|console|should not log to console`)
            );
        });
    }

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
});

describe('server logger', () => {
    let logger;
    let logToServerMock;
    let getSettingsMock;

    beforeEach(async () => {
        jest.isolateModules(() => {
            // Setup mocks
            getSettingsMock = jest.fn().mockResolvedValue(loggerSettings.default);
            require('@salesforce/apex/rflib_LoggerController.getSettings').default = getSettingsMock;
            
            logToServerMock = jest.fn().mockResolvedValue(undefined);
            require('@salesforce/apex/rflib_LoggerController.log').default = logToServerMock;
            
            // Create logger instance
            const loggerModule = require('c/rflibLogger');
            logger = loggerModule.createLogger('test');
        });
        
        // Wait for initialization
        await Promise.resolve();
    });

    afterEach(() => {
        jest.resetModules();
        jest.clearAllMocks();
    });

    async function executeServerLogLevelTest(serverLogLevel, validLogLevels) {
        // Set config
        logger.setConfig({ serverLogLevel });
        
        // Execute logs
        for (const level of validLogLevels) {
            logger[level.toLowerCase()]('test message');
        }
        
        // Wait for all promises
        await Promise.resolve();
        
        // Verify
        expect(logToServerMock).toHaveBeenCalledTimes(validLogLevels.length);
        validLogLevels.forEach(level => {
            expect(logToServerMock).toHaveBeenCalledWith(
                expect.objectContaining({
                    level,
                    message: expect.stringContaining(`${level}|test|test message`)
                })
            );
        });
    }

    it('should not log when setting is set to NONE', () => {
        executeServerLogLevelTest('NONE', []);
    });

    it('should log FATAL when setting is set to FATAL', () => {
        executeServerLogLevelTest('FATAL', ['FATAL']);
    });

    it('should log ERROR when setting is set to ERROR', () => {
        executeServerLogLevelTest('ERROR', ['FATAL', 'ERROR']);
    });

    it('should log WARN when setting is set to WARN', () => {
        executeServerLogLevelTest('WARN', ['FATAL', 'ERROR', 'WARN']);
    });

    it('should log INFO when setting is set to INFO', () => {
        executeServerLogLevelTest('INFO', ['FATAL', 'ERROR', 'WARN', 'INFO']);
    });

    it('should not log DEBUG when setting is set to DEBUG', () => {
        executeServerLogLevelTest('DEBUG', ['FATAL', 'ERROR', 'WARN', 'INFO']);
    });

    it('should not log TRACE when setting is set to TRACE', () => {
        executeServerLogLevelTest('TRACE', ['FATAL', 'ERROR', 'WARN', 'INFO']);
    });
});

describe('server logger failure', () => {
    let consoleSpy;
    let getSettingsMock;
    let logToServerMock;

    beforeEach(() => {
        consoleSpy = jest.spyOn(console, 'log').mockImplementation();
        getSettingsMock = require('@salesforce/apex/rflib_LoggerController.getSettings').default;
        logToServerMock = require('@salesforce/apex/rflib_LoggerController.log').default;
        getSettingsMock.mockResolvedValue(loggerSettings.default);
    });

    afterEach(() => {
        consoleSpy.mockRestore();
        jest.clearAllMocks();
    });

    it('should log to the console that the server log failed', async () => {
        logToServerMock.mockRejectedValue(new Error('foo bar error'));

        const logger = require('c/rflibLogger').createLogger('server');
        
        await Promise.resolve().then(() => {
            logger.setConfig({ serverLogLevel: 'FATAL' });
            logger.fatal('some message');
        });

        await new Promise(process.nextTick);

        await expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringContaining('Failed to log message to server for')
        );
    });
});

describe('log timer', () => {
    let logger;
    let consoleSpy;
    let logFactory;    
    let getSettingsMock;

    beforeEach(() => {
        jest.useFakeTimers();
        consoleSpy = jest.spyOn(console, 'log').mockImplementation();
        getSettingsMock = require('@salesforce/apex/rflib_LoggerController.getSettings').default;
        getSettingsMock.mockResolvedValue(loggerSettings.default);

        logger = require('c/rflibLogger').createLogger('timer');
        logFactory = require('c/rflibLogger');
    });

    afterEach(() => {
        jest.useRealTimers();
        jest.clearAllMocks();
        consoleSpy.mockRestore();
    });

    it('should log with default log level', () => {
        logger.setConfig({
            consoleLogLevel: 'INFO'
        });
        
        const timerName = 'Foo Bar';
        const logTimer = logFactory.startLogTimer(logger, 10, timerName);

        jest.advanceTimersByTime(11);
        logTimer.done();

        expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringMatching(/^WARN\|timer\|Foo Bar took a total of \d+ms \(threshold=10ms\)\.$/)
        );
    });

    it('should log with custom log level if provided', () => {
        logger.setConfig({
            consoleLogLevel: 'INFO'
        });

        const timerName = 'Foo Bar';
        const logLevel = 'ERROR';
        const logTimer = logFactory.startLogTimer(logger, 10, timerName, logLevel);

        jest.advanceTimersByTime(11);
        logTimer.done();

        expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringMatching(/^ERROR\|timer\|Foo Bar took a total of \d+ms \(threshold=10ms\)\.$/)
        );
    });

    it('should log warning if invalid level is provided', () => {
        logger.setConfig({
            consoleLogLevel: 'INFO'
        });

        const timerName = 'Foo Bar';
        const logLevel = 'INVALID';
        const logTimer = logFactory.startLogTimer(logger, 10, timerName, logLevel);

        jest.advanceTimersByTime(11);
        logTimer.done();

        expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringMatching(/^WARN\|timer\|Foo Bar took a total of \d+ms \(threshold=10ms\)\. NOTE: Invalid log Level provided$/)
        );
    });
});

describe('format string tests', () => {
    let logger;
    let consoleSpy;

    beforeEach(() => {
        consoleSpy = jest.spyOn(console, 'log').mockImplementation();
        
        const getSettingsMock = require('@salesforce/apex/rflib_LoggerController.getSettings').default;
        getSettingsMock.mockResolvedValue(loggerSettings.default);
        logger = require('c/rflibLogger').createLogger('TestLogger');
    });

    afterEach(() => {
        consoleSpy.mockRestore();
        jest.clearAllMocks();
    });

    it('should format primitive types correctly', () => {
        logger.setConfig({
            consoleLogLevel: 'INFO'
        });

        logger.info('Types: {0}, {1}, {2}, {3}, {4}', 
            undefined, 
            null, 
            'string', 
            42, 
            true
        );

        expect(consoleSpy).toHaveBeenCalledWith( 
            expect.stringContaining('Types: undefined, null, string, 42, true')
        );
    });

    it('should format complex types correctly', () => {
        const testObj = { name: 'test' };
        const testArr = [1, 2, 3];
        const testFn = () => {};
        const testSymbol = Symbol('test');
        // eslint-disable-next-line no-undef
        const testBigInt = BigInt(9007199254740991);

        logger.setConfig({
            consoleLogLevel: 'INFO'
        });

        logger.info('Complex: {0}, {1}, {2}, {3}, {4}', 
            testObj,
            testArr,
            testFn,
            testSymbol,
            testBigInt
        );

        expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringContaining('Complex: {"name":"test"}, [1,2,3], function, Symbol(test), 9007199254740991')
        );
    });

    it('should handle circular references', () => {
        const circular = {};
        circular.self = circular;

        logger.setConfig({
            consoleLogLevel: 'INFO'
        });

        logger.info('Circular: {0}', circular);

        expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringContaining('Circular: [Circular Object]')
        );
    });

    it('should handle missing arguments', () => {
        logger.setConfig({
            consoleLogLevel: 'INFO'
        });

        logger.info('Missing: {0}, {1}', 'exists');

        expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringContaining('Missing: exists, undefined')
        );
    });

    it('should handle nested objects and arrays', () => {
        const complex = {
            arr: [1, { nested: 'value' }, [3, 4]],
            obj: { deep: { deeper: 'content' } }
        };

        logger.setConfig({
            consoleLogLevel: 'INFO'
        });

        logger.info('Nested: {0}', complex);

        expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringContaining('Nested: {"arr":[1,{"nested":"value"},[3,4]],"obj":{"deep":{"deeper":"content"}}}')
        );
    });

    it('should handle array with mixed types', () => {
        const mixedArray = [
            42,
            'string',
            { obj: 'value' },
            [1, 2],
            null,
            undefined
        ];

        logger.setConfig({
            consoleLogLevel: 'INFO'
        });

        logger.info('Mixed array: {0}', mixedArray);

        expect(consoleSpy).toHaveBeenCalledWith(
            expect.stringContaining('Mixed array: [42,"string",{"obj":"value"},[1,2],null,null]')
        );
    });
});

describe('change stack size', () => {
    let logger;
    let logToServerMock;
    let getSettingsMock;

    beforeEach(async () => {
        jest.isolateModules(() => {
            // Setup mocks
            getSettingsMock = jest.fn().mockResolvedValue(loggerSettings.default);
            require('@salesforce/apex/rflib_LoggerController.getSettings').default = getSettingsMock;
            
            logToServerMock = jest.fn().mockResolvedValue(undefined);
            require('@salesforce/apex/rflib_LoggerController.log').default = logToServerMock;
            
            // Create logger instance
            const loggerModule = require('c/rflibLogger');
            logger = loggerModule.createLogger('test');
        });
        
        // Wait for initialization
        await Promise.resolve();
    });

    afterEach(() => {
        jest.resetModules();
        jest.clearAllMocks();
    });

    it('should shift log stack when capacity is reached', async () => {
        // Set config
        logger.setConfig({ serverLogLevel: 'INFO', stackSize: 2 });
        
        logger.debug('debug message 1');
        logger.info('info message 1');
        
        // Wait for all promises
        await Promise.resolve();
        
        // Verify
        expect(logToServerMock).toHaveBeenNthCalledWith(
            1, 
            expect.objectContaining({
                level: 'INFO',
                message: expect.stringContaining(`DEBUG|test|debug message 1`)
            })
        );

        // The info message should drop the debug message from the stack
        logger.info('info message 2');
        
        // Wait for all promises
        await Promise.resolve();

        expect(logToServerMock).toHaveBeenNthCalledWith(
            2,
            expect.objectContaining({
                level: 'INFO',
                message: expect.not.stringContaining(`DEBUG|test|debug message 1`)
            })
        );
    });
});