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
describe('log application event', () => {
    let applicationEventLogger;
    let mockSaveApplicationEvent;
    let mockLogger;
    let mockLoggerFactory;

    beforeEach(() => {
        // Setup logger mocks
        mockLogger = {
            trace: jest.fn(),
            debug: jest.fn(),
            info: jest.fn(),
            warn: jest.fn(),
            error: jest.fn()
        };

        // Setup logger factory mock
        mockLoggerFactory = {
            createLogger: jest.fn().mockReturnValue(mockLogger)
        };

        // Setup save event mock
        mockSaveApplicationEvent = jest.fn();

        // Setup module mocks
        jest.mock('@salesforce/apex/rflib_ApplicationEventController.logApplicationEvent', 
            () => ({ default: mockSaveApplicationEvent }), 
            { virtual: true }
        );
        
        jest.mock('c/rflibLogger', 
            () => mockLoggerFactory, 
            { virtual: true }
        );

        applicationEventLogger = require('../rflibApplicationEventLogger');
    });

    afterEach(() => {
        jest.clearAllMocks();
        jest.resetModules();
    });

    it('should submit application event to server', async () => {
        const eventName = 'Foo Bar';
        const relatedRecordId = 'rec123';
        const additionalDetails = 'Details Foo Bar';

        mockSaveApplicationEvent.mockResolvedValue(undefined);

        await applicationEventLogger.logApplicationEvent(eventName, relatedRecordId, additionalDetails);

        expect(mockLogger.info).toHaveBeenCalledWith(
            'Logging Application Event "{0}" for record "{1}" with details: {2}',
            eventName,
            relatedRecordId,
            additionalDetails
        );
        
        expect(mockLogger.debug).toHaveBeenCalledWith('Application Event successfully recorded');
        
        expect(mockSaveApplicationEvent).toHaveBeenCalledWith(
            expect.objectContaining({
                eventName,
                relatedRecordId,
                additionalDetails
            })
        );
    });

    it('should log error if application event logging fails', async () => {
        const eventName = 'Foo Bar';
        const relatedRecordId = 'rec123';
        const additionalDetails = 'Details Foo Bar';
        const error = 'foobar';

        mockSaveApplicationEvent.mockRejectedValue(error);

        await applicationEventLogger.logApplicationEvent(eventName, relatedRecordId, additionalDetails);

        // Wait for all promises
        await Promise.resolve();

        expect(mockLogger.info).toHaveBeenCalledWith(
            'Logging Application Event "{0}" for record "{1}" with details: {2}',
            eventName,
            relatedRecordId,
            additionalDetails
        );
        
        expect(mockLogger.error).toHaveBeenCalledWith(
            'Failed to log application event to server for: {0}, error={1}',
            eventName,
            expect.stringContaining('foobar')
        );
        
        expect(mockSaveApplicationEvent).toHaveBeenCalledWith(
            expect.objectContaining({
                eventName,
                relatedRecordId,
                additionalDetails
            })
        );
    });
});