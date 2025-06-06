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

const featureSwitches = require('./data/featureSwitches.json');

// Mock Apex controller
const mockGetAllFeatureSwitches = jest.fn();
jest.mock(
    '@salesforce/apex/rflib_FeatureSwitchesController.getAllSwitchValues',
    () => ({ default: mockGetAllFeatureSwitches }),
    { virtual: true }
);

describe('isFeatureSwitchTurnedOn()', () => {
    let isFeatureSwitchTurnedOn;

    beforeEach(() => {
        mockGetAllFeatureSwitches.mockResolvedValue(featureSwitches.default);
        isFeatureSwitchTurnedOn = require('c/rflibFeatureSwitches').isFeatureSwitchTurnedOn;
    });

    afterEach(() => {
        jest.clearAllMocks();
        jest.resetModules();
    });

    it('feature switch is set to true', async () => {
        const switchValue = await isFeatureSwitchTurnedOn('activeSwitch');
        expect(switchValue).toBeTruthy();
        expect(mockGetAllFeatureSwitches).toHaveBeenCalled();
    });

    it('feature switch is set to false', async () => {
        const switchValue = await isFeatureSwitchTurnedOn('inactiveSwitch');
        expect(switchValue).toBeFalsy();
        expect(mockGetAllFeatureSwitches).toHaveBeenCalled();
    });

    it('feature switch does not exist', async () => {
        const switchValue = await isFeatureSwitchTurnedOn('unknownSwitch');
        expect(switchValue).toBeFalsy();
        expect(mockGetAllFeatureSwitches).toHaveBeenCalled();
    });
});
