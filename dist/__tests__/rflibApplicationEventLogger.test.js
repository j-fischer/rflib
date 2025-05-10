/*
 * Copyright (c) 2023 Johannes Fischer <fischer.jh@gmail.com>
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

describe('Application Event Logger Tests', () => {
    let mockDataApi;
    let mockLogger;
    let functionContext;

    beforeEach(() => {
        // Setup mocks
        mockDataApi = {
            query: jest.fn(),
            create: jest.fn()
        };

        mockLogger = {
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

        // Default mock implementations
        mockDataApi.query.mockResolvedValue(loggerSettings.default);
        mockDataApi.create.mockResolvedValue(undefined);
    });

    afterEach(() => {
        jest.clearAllMocks();
        jest.resetModules();
    });

    describe('create application event logger', () => {
        it('factory should return an application event logger instance', async () => {
            const createApplicationEventLogger = require('../rflibLogger.js').createApplicationEventLogger;
            const appEventLogger = createApplicationEventLogger(functionContext, mockLogger);

            await Promise.resolve();
            expect(appEventLogger).toBeDefined();
        });
    });

    describe('successfully create application event', () => {
        it('should create application event', async () => {
            const eventName = 'test-event';
            const relatedRecordId = '001abcdefg12345';
            const additionalDetails = 'some details';

            const createApplicationEventLogger = require('../rflibLogger.js').createApplicationEventLogger;
            const appEventLogger = createApplicationEventLogger(functionContext, mockLogger);

            await Promise.resolve();
            await appEventLogger.logApplicationEvent(eventName, relatedRecordId, additionalDetails);

            expect(mockDataApi.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    type: 'rflib_Application_Event_Occurred_Event__e',
                    fields: expect.objectContaining({
                        Event_Name__c: eventName,
                        Related_Record_ID__c: relatedRecordId,
                        Additional_Details__c: JSON.stringify(additionalDetails)
                    })
                })
            );
        });

        it('should set default related record ID', async () => {
            const eventName = 'test-event';
            const additionalDetails = 'some details';

            const createApplicationEventLogger = require('../rflibLogger.js').createApplicationEventLogger;
            const appEventLogger = createApplicationEventLogger(functionContext, mockLogger);

            await Promise.resolve();
            await appEventLogger.logApplicationEvent(eventName, null, additionalDetails);

            expect(mockDataApi.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    fields: expect.objectContaining({
                        Related_Record_ID__c: 'NO_RECORD_ID'
                    })
                })
            );
        });
    });

    describe('log application event failure', () => {
        it('should log error that the server log failed', async () => {
            const eventName = 'test-event';
            const error = new Error('foo bar error');

            mockDataApi.query.mockResolvedValue(loggerSettings.computeError);
            mockDataApi.create.mockRejectedValue(error);

            const createApplicationEventLogger = require('../rflibLogger.js').createApplicationEventLogger;
            const appEventLogger = createApplicationEventLogger(functionContext, mockLogger);

            await appEventLogger.logApplicationEvent(eventName, null, null);
            await Promise.resolve();

            expect(mockLogger.error).toHaveBeenCalledWith(
                'ERROR|context-id-123|rflib-application-event-logger|Failed to log application event to server for: test-event, error={}'
            );
        });
    });
});
