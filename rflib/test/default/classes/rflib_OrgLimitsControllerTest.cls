/*
 * Copyright (c) 2026 Johannes Fischer <fischer.jh@gmail.com>
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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_OrgLimitsControllerTest {

    @IsTest
    private static void testGetOrgLimits() {
        Test.startTest();
        Map<String, rflib_OrgLimitsController.SerializableOrgLimit> result = rflib_OrgLimitsController.getOrgLimits();
        Test.stopTest();

        Map<String, OrgLimit> expectedLimits = OrgLimits.getMap();
        Assert.areEqual(expectedLimits.keySet(), result.keySet(), 'All org limits should be returned');

        String limitName = new List<String>(expectedLimits.keySet())[0];
        rflib_OrgLimitsController.SerializableOrgLimit actualLimit = result.get(limitName);
        Assert.areEqual(limitName, actualLimit.name, 'The limit name should be mapped');
        Assert.areEqual(expectedLimits.get(limitName).getLimit(), actualLimit.totalLimit, 'The total limit should be mapped');
        Assert.areEqual(expectedLimits.get(limitName).getValue(), actualLimit.currentValue, 'The current value should be mapped');
    }

    @IsTest
    private static void testGetOrgLimits_ErrorIsRethrown() {
        // Reading the org limits cannot fail on its own, so the logger fails instead to reach the error handling
        rflib_LoggerUtil.loggerFactory = new rflib_MockFailingLoggerFactory();

        Test.startTest();
        try {
            rflib_OrgLimitsController.getOrgLimits();
            Assert.fail('Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            Assert.areEqual(rflib_MockFailingLoggerFactory.FAILURE_MESSAGE, e.getMessage(), 'The original error should be rethrown');
        }
        Test.stopTest();
    }
}
