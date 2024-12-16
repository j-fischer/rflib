/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
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
private class rflib_LogEventViewerControllerTest {

    private static final String REQUEST_ID = '7rL5o000000CcJwCAK';

    private List<SObject> queryResults = new List<SObject>();

    @IsTest
    static void testGetApexLogsForRequestId_Success() {
        // Given
        DateTime now = DateTime.now();
        ApexLog mockLog = new ApexLog();

        rflib_LogEventViewerController.QUERY_EXECUTOR = new rflib_MockQueryExecutor(
            0, 
            new List<ApexLog> { mockLog }
        );

        // When
        Test.startTest();
        List<rflib_LogEventViewerController.ApexLogInfo> result = rflib_LogEventViewerController.getApexLogsForRequestId(REQUEST_ID);
        Test.stopTest();

        // Then
        System.assertEquals(1, result.size());
    }

    @IsTest
    static void testGetApexLogsForRequestId_NoResults() {
        // Given
        rflib_LogEventViewerController.QUERY_EXECUTOR = new rflib_MockQueryExecutor(
            0, 
            new List<ApexLog>()
        );

        // When
        Test.startTest();
        List<rflib_LogEventViewerController.ApexLogInfo> result = rflib_LogEventViewerController.getApexLogsForRequestId(REQUEST_ID);
        Test.stopTest();

        // Then
        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testGetApexLogsForRequestId_QueryException() {
        // Given
        rflib_LogEventViewerController.QUERY_EXECUTOR = new rflib_MockQueryExecutor(
            new TestException('Test exception')
        );

        // When
        Test.startTest();
        try {
            rflib_LogEventViewerController.getApexLogsForRequestId(REQUEST_ID);
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException ex) {
            // Then
            System.assert(ex.getMessage().contains('Test exception'), 'Unexpected exception message');
        }
        Test.stopTest();
    }

    private class TestException extends Exception {}
}