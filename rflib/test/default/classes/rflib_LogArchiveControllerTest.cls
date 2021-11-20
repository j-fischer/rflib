/*
 * Copyright (c) 2019 Johannes Fischer <fischer.jh@gmail.com>
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
private class rflib_LogArchiveControllerTest {

    private static final List<rflib_Logs_Archive__b> RESULT = new List<rflib_Logs_Archive__b> {
        createLogArchiveRecord('Log1')
    };

    private static final Exception EXPECTED_EXCEPTION = new rflib_InvalidStateException('some message');

    @IsTest
    private static void testGetArchivedRecords_Success() {
        rflib_LogArchiveController.QUERY_LOCATOR = new MockLogArchiveQueryLocator(RESULT, null);

        System.assertEquals(RESULT, rflib_LogArchiveController.getArchivedRecords(Datetime.now(), Datetime.now()));
    }

    @IsTest
    private static void testGetArchivedRecords_Failure() {
        rflib_LogArchiveController.QUERY_LOCATOR = new MockLogArchiveQueryLocator(null, EXPECTED_EXCEPTION);

        try {
            rflib_LogArchiveController.getArchivedRecords(Datetime.now(), Datetime.now());
            System.assert(false, 'Expected exception has not been thrown');
        } catch (AuraHandledException actualException) {
            System.assertEquals(EXPECTED_EXCEPTION.getMessage(), actualException.getMessage());
        }
    }
    
    @IsTest
    private static void testClearArchive_Success() {
        rflib_LogArchiveController.QUERY_LOCATOR = new MockLogArchiveQueryLocator(RESULT, null);
        rflib_LogArchiveController.DML_EXECUTOR = new rflib_MockDmlExecutor(new List<Database.DeleteResult> { createSuccessDeleteResult() });

        rflib_LogArchiveController.clearArchive();
    }

    @IsTest
    private static void testClearArchive_Failure() {
        rflib_LogArchiveController.QUERY_LOCATOR = new MockLogArchiveQueryLocator(null, EXPECTED_EXCEPTION);

        try {
            rflib_LogArchiveController.clearArchive();
            System.assert(false, 'Expected exception has not been thrown');
        } catch (AuraHandledException actualException) {
            System.assertEquals(EXPECTED_EXCEPTION.getMessage(), actualException.getMessage());
        }
    }

    @IsTest
    private static void testDefaultLogArchiveQueryLocator_getRecords() {
        //This call is for code coverage purposes only
        List<rflib_Logs_Archive__b> result = new rflib_LogArchiveController.DefaultLogArchiveQueryLocator().getRecords(Datetime.now(), Datetime.now());
        System.assertNotEquals(null, result);
    }    
    
    @IsTest
    private static void testDefaultLogArchiveQueryLocator_getOldestRecords() {
        //This call is for code coverage purposes only
        List<rflib_Logs_Archive__b> result = new rflib_LogArchiveController.DefaultLogArchiveQueryLocator().getOldestRecords();
        System.assertNotEquals(null, result);
    }   

    private static Database.DeleteResult createSuccessDeleteResult() {
        return (Database.DeleteResult) JSON.deserialize('{"success":true,"id":"0013000000abcde"}', Database.DeleteResult.class);
    }
    
    private static rflib_Logs_Archive__b createLogArchiveRecord(String context) {
        return rflib_LogArchiveFactory.create(context);
    }

    public class MockLogArchiveQueryLocator implements rflib_LogArchiveController.ILogArchiveQueryLocator {

        private final List<rflib_Logs_Archive__b> result;

        private final Exception ex;

        public MockLogArchiveQueryLocator(List<rflib_Logs_Archive__b> result, Exception ex) {
            this.result = result;
            this.ex = ex;
        }

        public List<rflib_Logs_Archive__b> getRecords(Datetime startDate, Datetime endDate) {
            if (ex != null) {
                throw ex;
            }

            return result;
        }

        public List<rflib_Logs_Archive__b> getOldestRecords() {
            if (ex != null) {
                throw ex;
            }

            return result;
        }
    }
}
