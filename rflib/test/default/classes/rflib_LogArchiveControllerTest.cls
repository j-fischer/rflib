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
    private static final String GET_RECORDS_MOCK_ID = 'DefaultLogArchiveQueryLocator.getRecords';
    private static final String GET_SUMMARIES_MOCK_ID = 'DefaultLogArchiveQueryLocator.getRecordSummaries';
    private static final String GET_OLDEST_RECORDS_MOCK_ID = 'DefaultLogArchiveQueryLocator.getOldestRecords';

    private static final List<rflib_Logs_Archive__b> RESULT = new List<rflib_Logs_Archive__b>{
        createLogArchiveRecord('Log1')
    };

    private static final Exception EXPECTED_EXCEPTION = new rflib_InvalidStateException('some message');

    @IsTest
    private static void testGetArchivedRecords_Success() {
        rflib_LogArchiveController.QUERY_LOCATOR = new MockLogArchiveQueryLocator(RESULT, null);

        Test.startTest();
        System.assertEquals(
            RESULT,
            rflib_LogArchiveController.getArchivedRecords(Datetime.now(), Datetime.now()).records
        );
        Test.stopTest();
    }

    @IsTest
    private static void testGetArchivedRecords_Failure() {
        rflib_LogArchiveController.QUERY_LOCATOR = new MockLogArchiveQueryLocator(null, EXPECTED_EXCEPTION);

        Test.startTest();
        try {
            rflib_LogArchiveController.getArchivedRecords(Datetime.now(), Datetime.now());
            System.assert(false, 'Expected exception has not been thrown');
        } catch (AuraHandledException actualException) {
            System.assertEquals(EXPECTED_EXCEPTION.getMessage(), actualException.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testClearArchive_Success() {
        // Given
        rflib_Logs_Archive__b oldLog = createLogRecord(Datetime.now().addDays(-10));
        rflib_SOQL.setMock(GET_OLDEST_RECORDS_MOCK_ID, new List<rflib_Logs_Archive__b>{ oldLog });

        rflib_MockDmlExecutor dmlExecutor = new rflib_MockDmlExecutor(
            new List<Database.DeleteResult>{ createSuccessDeleteResult() }
        );
        rflib_LogArchiveController.DML_EXECUTOR = dmlExecutor;

        // When
        rflib_LogArchiveController.clearArchive();

        // Then
        System.assertEquals(1, dmlExecutor.capturedRecords.size(), 'Should delete one record');
        rflib_Logs_Archive__b deletedRecord = (rflib_Logs_Archive__b) dmlExecutor.capturedRecords[0];
        System.assertEquals(oldLog.CreatedDate__c, deletedRecord.CreatedDate__c, 'Deleted record should match');
    }

    @IsTest
    private static void testClearArchive_Failure() {
        rflib_LogArchiveController.QUERY_LOCATOR = new MockLogArchiveQueryLocator(null, EXPECTED_EXCEPTION);

        Test.startTest();
        try {
            rflib_LogArchiveController.clearArchive();
            System.assert(false, 'Expected exception has not been thrown');
        } catch (AuraHandledException actualException) {
            System.assertEquals(EXPECTED_EXCEPTION.getMessage(), actualException.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    private static void testGetArchivedRecordsWithinDateRange() {
        // Given
        Datetime startDate = Datetime.now().addDays(-1);
        Datetime endDate = Datetime.now();

        rflib_Logs_Archive__b logRecord = createLogRecord(startDate.addHours(1));
        rflib_SOQL.setMock(GET_RECORDS_MOCK_ID, new List<rflib_Logs_Archive__b>{ logRecord });

        // When
        rflib_LogArchiveController.ArchiveQueryResult result = rflib_LogArchiveController.getArchivedRecords(
            startDate,
            endDate
        );

        // Then
        System.assertEquals(1, result.records.size(), 'Should return one log record');
        System.assertEquals(logRecord.CreatedDate__c, result.records[0].CreatedDate__c, 'Request ID should match');
        System.assertEquals('123', result.records[0].Request_ID__c, 'Request ID should match');
        System.assertEquals('Test Context', result.records[0].Context__c, 'Context should match');
        System.assertEquals('INFO', result.records[0].Log_Level__c, 'Log level should match');
    }

    @IsTest
    static void testGetArchivedRecordsWithDefaultDates() {
        // Given
        List<rflib_Logs_Archive__b> expectedRecords = new List<rflib_Logs_Archive__b>{
            createLogRecord(Datetime.now())
        };
        rflib_SOQL.setMock(GET_RECORDS_MOCK_ID, expectedRecords);

        // When
        rflib_LogArchiveController.ArchiveQueryResult result = rflib_LogArchiveController.getArchivedRecords(
            null,
            null
        );

        // Then
        System.assertEquals(expectedRecords.size(), result.records.size(), 'Should return expected number of records');
        System.assertEquals(
            expectedRecords[0].CreatedDate__c,
            result.records[0].CreatedDate__c,
            'Records should match'
        );
    }

    @IsTest
    static void testGetRecentLogSummary_CountsMatchingLevels() {
        // Given
        rflib_SOQL.setMock(
            GET_SUMMARIES_MOCK_ID,
            new List<rflib_Logs_Archive__b>{
                createLogRecordWithLevel('ERROR'),
                createLogRecordWithLevel('ERROR'),
                createLogRecordWithLevel('WARN'),
                createLogRecordWithLevel('INFO')
            }
        );

        // When
        rflib_LogArchiveController.LogSummaryResult result = rflib_LogArchiveController.getRecentLogSummary(
            24,
            'WARN,ERROR,FATAL'
        );

        // Then
        System.assertEquals(3, result.totalCount, 'INFO should be excluded from the total');
        System.assertEquals(24, result.lookbackHours, 'Lookback hours should match');

        Map<String, Integer> countsByLevel = new Map<String, Integer>();
        for (rflib_LogArchiveController.LogLevelCount levelCount : result.levelCounts) {
            countsByLevel.put(levelCount.level, levelCount.count);
        }
        System.assertEquals(2, countsByLevel.get('ERROR'), 'Should count two ERROR records');
        System.assertEquals(1, countsByLevel.get('WARN'), 'Should count one WARN record');
        System.assertEquals(false, countsByLevel.containsKey('FATAL'), 'FATAL with zero count should be omitted');
        System.assertEquals('ERROR', result.levelCounts[0].level, 'ERROR should be ordered before WARN');
    }

    @IsTest
    static void testGetRecentLogSummary_NoMatchesReturnsZero() {
        // Given
        rflib_SOQL.setMock(
            GET_SUMMARIES_MOCK_ID,
            new List<rflib_Logs_Archive__b>{ createLogRecordWithLevel('INFO'), createLogRecordWithLevel('DEBUG') }
        );

        // When
        rflib_LogArchiveController.LogSummaryResult result = rflib_LogArchiveController.getRecentLogSummary(null, null);

        // Then
        System.assertEquals(0, result.totalCount, 'No matching levels should yield a zero total');
        System.assertEquals(24, result.lookbackHours, 'Should default to 24 hours');
        System.assertEquals(true, result.levelCounts.isEmpty(), 'No level counts should be returned');
    }

    @IsTest
    private static void testGetRecentLogSummary_Failure() {
        rflib_LogArchiveController.QUERY_LOCATOR = new MockLogArchiveQueryLocator(null, EXPECTED_EXCEPTION);

        Test.startTest();
        try {
            rflib_LogArchiveController.getRecentLogSummary(24, 'ERROR');
            System.assert(false, 'Expected exception has not been thrown');
        } catch (AuraHandledException actualException) {
            System.assertEquals(EXPECTED_EXCEPTION.getMessage(), actualException.getMessage());
        }
        Test.stopTest();
    }

    private static Database.DeleteResult createSuccessDeleteResult() {
        return (Database.DeleteResult) JSON.deserialize(
            '{"success":true,"id":"0013000000abcde"}',
            Database.DeleteResult.class
        );
    }

    private static rflib_Logs_Archive__b createLogArchiveRecord(String context) {
        return rflib_LogArchiveFactory.create(context);
    }

    private static rflib_Logs_Archive__b createLogRecord(Datetime createdDate) {
        return new rflib_Logs_Archive__b(
            CreatedDate__c = createdDate,
            Request_ID__c = '123',
            Context__c = 'Test Context',
            Log_Level__c = 'INFO',
            Log_Messages__c = 'Test Message',
            Platform_Info__c = 'Test Platform'
        );
    }

    private static rflib_Logs_Archive__b createLogRecordWithLevel(String level) {
        return new rflib_Logs_Archive__b(
            CreatedDate__c = Datetime.now(),
            Request_ID__c = '123',
            Context__c = 'Test Context',
            Log_Level__c = level
        );
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

        public List<rflib_Logs_Archive__b> getRecordSummaries(Datetime startDate, Datetime endDate) {
            if (ex != null) {
                throw ex;
            }

            return result;
        }

        public List<rflib_Logs_Archive__b> getRecordsOlderThan(Datetime referenceDate) {
            if (ex != null) {
                throw ex;
            }

            return result;
        }
    }
}
