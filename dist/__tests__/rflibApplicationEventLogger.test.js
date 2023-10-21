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
/* eslint-disable jest/expect-expect */
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
            create: function () {}
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
let mockComputeLogger;
JsMock.watch(() => {
    functionContext.org.dataApi = JsMock.mock('dataApi', functionContext.org.dataApi);
    mockComputeLogger = JsMock.mock('computeLogger', computeLogger);
});

const loggerSettings = require('./data/loggerSettings.json');

describe('create application event logger', () => {
    beforeEach(() => {
        functionContext.org.dataApi.query.allowing().returns(Promise.resolve(loggerSettings.default));
        mockComputeLogger.debug.allowing();
        mockComputeLogger.info.allowing();
    });

    afterEach(JsMock.assertWatched);

    it('factory should return an application event logger instance', () => {
        const createApplicationEventLogger = require('../rflibLogger.js').createApplicationEventLogger;
        let appEventLogger = createApplicationEventLogger(functionContext, mockComputeLogger);

        return Promise.resolve().then(() => {
            expect(appEventLogger).toBeDefined();
        });
    });
});

describe('successfully create application event', () => {
    beforeEach(() => {
        functionContext.org.dataApi.query.allowing().returns(Promise.resolve(loggerSettings.default));
        mockComputeLogger.debug.allowing();
        mockComputeLogger.info.allowing();
    });

    afterEach(JsMock.assertWatched);

    it('should create application event', () => {
        const eventName = 'test-event';
        const relatedRecordId = '001abcdefg12345';
        const additionalDetails = 'some details';

        functionContext.org.dataApi.create
            .once()
            .with(
                Matcher.hasProperties({
                    type: 'rflib_Application_Event_Occurred_Event__e',
                    fields: Matcher.hasProperties({
                        Event_Name__c: eventName,
                        Related_Record_ID__c: relatedRecordId,
                        Additional_Details__c: JSON.stringify(additionalDetails)
                    })
                })
            )
            .returns(Promise.resolve());

        const createApplicationEventLogger = require('../rflibLogger.js').createApplicationEventLogger;
        let appEventLogger = createApplicationEventLogger(functionContext, mockComputeLogger);

        return Promise.resolve().then(() => {
            appEventLogger.logApplicationEvent(eventName, relatedRecordId, additionalDetails);
        });
    });

    it('should set default related record ID', () => {
        const eventName = 'test-event';
        const additionalDetails = 'some details';

        functionContext.org.dataApi.create
            .once()
            .with(
                Matcher.hasProperties({
                    type: 'rflib_Application_Event_Occurred_Event__e',
                    fields: Matcher.hasProperties({
                        Event_Name__c: eventName,
                        Related_Record_ID__c: 'NO_RECORD_ID',
                        Additional_Details__c: JSON.stringify(additionalDetails)
                    })
                })
            )
            .returns(Promise.resolve());

        const createApplicationEventLogger = require('../rflibLogger.js').createApplicationEventLogger;
        let appEventLogger = createApplicationEventLogger(functionContext, mockComputeLogger);

        return Promise.resolve().then(() => {
            appEventLogger.logApplicationEvent(eventName, null, additionalDetails);
        });
    });
});

describe('log application event failure', () => {
    afterEach(JsMock.assertWatched);

    it('should log error that the server log failed', () => {
        const eventName = 'test-event';

        mockComputeLogger.debug.allowing().with(Matcher.containsString('Retrieved settings for user'));
        mockComputeLogger.info.allowing().with(Matcher.containsString('Setting new logger configuration for'));

        functionContext.org.dataApi.query.allowing().returns(Promise.resolve(loggerSettings.computeError));
        functionContext.org.dataApi.create.once().returns(Promise.reject(new Error('foo bar error')));

        mockComputeLogger.error
            .expect()
            .once()
            .with(
                Matcher.allOf(
                    Matcher.containsString('Failed to log application event to server for:'),
                    Matcher.containsString(eventName),
                    Matcher.containsString('foo bar error')
                )
            );

        const createApplicationEventLogger = require('../rflibLogger.js').createApplicationEventLogger;
        let appEventLogger = createApplicationEventLogger(functionContext, mockComputeLogger);

        return Promise.resolve().then(() => {
            appEventLogger.logApplicationEvent(eventName, null, null);
        });
    });
});
