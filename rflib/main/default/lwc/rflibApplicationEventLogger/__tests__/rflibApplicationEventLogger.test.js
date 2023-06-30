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
import JsMock from 'js-mock';
import Matcher from 'hamjest';

const loggerFactory = {
    createLogger: function () {}
};
const logger = {
    trace: function () {},
    debug: function () {},
    info: function () {},
    warn: function () {},
    error: function () {}
};

let mockSaveApplicationEvent, mockLoggerFactory, mockLogger;
JsMock.watch(() => {
    mockSaveApplicationEvent = JsMock.mock('mockSaveApplicationEvent');
    mockLoggerFactory = JsMock.mock('mockLoggerFactory', loggerFactory);
    mockLogger = JsMock.mock('logger', logger);
});

jest.mock(
    '@salesforce/apex/rflib_ApplicationEventController.logApplicationEvent',
    () => {
        return { default: mockSaveApplicationEvent };
    },
    { virtual: true }
);
jest.mock(
    'c/rflibLogger',
    () => {
        return mockLoggerFactory;
    },
    { virtual: true }
);

describe('log application event', () => {
    let applicationEventLogger;

    beforeEach(() => {
        mockLoggerFactory.createLogger.allowing().with('ApplicationEventLogger').returns(mockLogger);

        applicationEventLogger = require('../rflibApplicationEventLogger');
    });

    afterEach(() => {
        JsMock.assertWatched();
    });

    it('should submit application event to server', () => {
        let eventName = 'Foo Bar';
        let relatedRecordId = 'rec123';
        let additionalDetails = 'Details Foo Bar';

        mockLogger.info
            .expect()
            .once()
            .with(
                'Logging Application Event "{0}" for record "{1}" with details: {2}',
                eventName,
                relatedRecordId,
                additionalDetails
            );
        mockLogger.debug.expect().once().with('Application Event successfully recorded');

        mockSaveApplicationEvent
            .expect()
            .once()
            .with(
                Matcher.hasProperties({
                    eventName: eventName,
                    relatedRecordId: relatedRecordId,
                    additionalDetails: additionalDetails
                })
            )
            .returns(Promise.resolve());

        applicationEventLogger.logApplicationEvent(eventName, relatedRecordId, additionalDetails);
    });

    it('should log error if application event logging fails', async () => {
        let eventName = 'Foo Bar';
        let relatedRecordId = 'rec123';
        let additionalDetails = 'Details Foo Bar';

        mockLogger.info
            .expect()
            .once()
            .with(
                'Logging Application Event "{0}" for record "{1}" with details: {2}',
                eventName,
                relatedRecordId,
                additionalDetails
            );
        mockLogger.error
            .expect()
            .once()
            .with(
                'Failed to log application event to server for: {0}, error={1}',
                eventName,
                Matcher.containsString('foobar')
            );

        mockSaveApplicationEvent
            .expect()
            .once()
            .with(
                Matcher.hasProperties({
                    eventName: eventName,
                    relatedRecordId: relatedRecordId,
                    additionalDetails: additionalDetails
                })
            )
            .returns(Promise.reject('foobar'));

        applicationEventLogger.logApplicationEvent(eventName, relatedRecordId, additionalDetails);
    });
});
