/*
 * Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
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
private class rflib_AbstractArchiveCleanupTest {
    
    private static final Integer RETENTION_DAYS = 30;
    
    @TestSetup
    static void setup() {
        rflib_TestUtil.prepareLoggerForUnitTests();
    }
    
    @IsTest
    static void testExecuteBatch() {
        // GIVEN
        List<SObject> testRecords = new List<SObject>{ 
            new Account(Name = 'Test Account 1'),
            new Account(Name = 'Test Account 2')
        };
        
        // Mock the DML executor to avoid callout issues
        List<Database.DeleteResult> successResults = createSuccessDeleteResults(2);
        rflib_MockDmlExecutor mockDmlExecutor = new rflib_MockDmlExecutor(successResults);
        
        TestableArchiveCleanup cleanup = new TestableArchiveCleanup();
        cleanup.dmlExecutor = mockDmlExecutor;
        cleanup.setTestRecords(testRecords);
        
        // WHEN
        Test.startTest();
        Database.BatchableContext bc = new rflib_MockBatchContext();
        cleanup.execute(bc, testRecords);
        Test.stopTest();
        
        // THEN
        System.assertEquals(2, cleanup.getProcessedCount(), 'Should have processed 2 records');
    }
    
    @IsTest
    static void testReferenceDateNormalization() {
        // GIVEN
        TestableArchiveCleanup cleanup = new TestableArchiveCleanup();
        
        // WHEN - Access the reference date directly (marked as @TestVisible in the class)
        Datetime referenceDate = cleanup.referenceDate;
        
        // THEN - Verify the referenceDate is properly normalized to midnight
        Date expectedDate = Date.today().addDays(-RETENTION_DAYS);
        Datetime expectedDateTime = Datetime.newInstance(expectedDate, Time.newInstance(0, 0, 0, 0));
        
        System.assertEquals(expectedDateTime, referenceDate, 
            'Reference date should be normalized to midnight ' + RETENTION_DAYS + ' days ago');
        System.assertEquals(0, referenceDate.hour(), 'Hour should be 0');
        System.assertEquals(0, referenceDate.minute(), 'Minute should be 0');
        System.assertEquals(0, referenceDate.second(), 'Second should be 0');
    }
    
    @IsTest
    static void testFinishWithoutChaining() {
        // GIVEN
        TestableArchiveCleanup cleanup = new TestableArchiveCleanup();
        cleanup.setProcessedCount(10); // Not a multiple of the query limit
        
        // WHEN
        Test.startTest();
        Database.BatchableContext bc = new rflib_MockBatchContext();
        cleanup.finish(bc);
        Test.stopTest();
        
        // THEN
        System.assertEquals(false, cleanup.chainingAttempted, 'Should not attempt to chain when not hitting limit');
    }
    
    @IsTest
    static void testFinishWithChaining() {
        // GIVEN
        TestableArchiveCleanup cleanup = new TestableArchiveCleanup();
        cleanup.setProcessedCount(200); // Set to a multiple of the query limit (200 = 2 * 100)
        cleanup.setQueryLimit(100);
        
        // WHEN
        Test.startTest();
        Database.BatchableContext bc = new rflib_MockBatchContext();
        cleanup.finish(bc);
        Test.stopTest();
        
        // THEN
        System.assertEquals(true, cleanup.chainingAttempted, 'Should attempt to chain when hitting limit');
        System.assertEquals(200, cleanup.chainedTotalProcessed, 'Should pass correct total processed');
        System.assertNotEquals(null, cleanup.chainedReferenceDate, 'Should pass reference date');
    }

    @IsTest
    static void testErrorHandlingInExecute() {
        // GIVEN
        List<SObject> testRecords = new List<SObject>{ new Account(Name = 'Test Account') };
        
        // Use mock that will trigger an exception
        QueryException ex = new QueryException('Simulated error');
        rflib_MockDmlExecutor mockDmlExecutor = new rflib_MockDmlExecutor(ex);
        
        TestableArchiveCleanup cleanup = new TestableArchiveCleanup();
        cleanup.dmlExecutor = mockDmlExecutor;
        
        // WHEN
        Test.startTest();
        try {
            cleanup.execute(null, testRecords);
            System.assert(false, 'Expected exception');
        } catch (rflib_AbstractArchiveCleanup.rflib_ArchiveCleanupException actualEx) {
            // THEN
            System.assert(actualEx.getMessage().contains('Batch processing failed'));
            System.assert(actualEx.getMessage().contains('Simulated error'));
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testErrorHandlingInFinish() {
        // GIVEN
        TestableArchiveCleanup cleanup = new TestableArchiveCleanup();
        cleanup.setProcessedCount(200);
        cleanup.setQueryLimit(100);
        cleanup.throwErrorOnNextChain = true;
        
        // WHEN
        Test.startTest();
        try {
            cleanup.finish(null);
            System.assert(false, 'Expected exception');
        } catch (rflib_AbstractArchiveCleanup.rflib_ArchiveCleanupException actualEx) {
            // THEN
            System.assert(actualEx.getMessage().contains('Batch finish failed'));
            System.assert(actualEx.getMessage().contains('Simulated chain error'));
        }
        Test.stopTest();
    }
    
    private static List<Database.DeleteResult> createSuccessDeleteResults(Integer count) {
        List<Database.DeleteResult> results = new List<Database.DeleteResult>();
        for (Integer i = 0; i < count; i++) {
            results.add(createSuccessDeleteResult());
        }
        return results;
    }
    
    private static Database.DeleteResult createSuccessDeleteResult() {
        return (Database.DeleteResult) JSON.deserialize('{"success":true,"id":"0013000000abcde"}', Database.DeleteResult.class);
    }
    
    // Inner classes can't implement Schedulable and Batchable interfaces directly
    // So we'll create a test class that just extends the abstract class for testing
    private class TestableArchiveCleanup extends rflib_AbstractArchiveCleanup {
        private List<SObject> testRecords;
        private Integer queryLimitValue = 50;
        private Integer batchSizeValue = 10;
        public Boolean chainingAttempted = false;
        public Datetime chainedReferenceDate;
        public Integer chainedTotalProcessed;
        public Boolean throwErrorOnNextChain = false;
        
        public TestableArchiveCleanup() {
            super(rflib_LoggerUtil.getFactory().createLogger('TestableArchiveCleanup'), 
                 RETENTION_DAYS, null, null);
        }
        
        public void setTestRecords(List<SObject> records) {
            this.testRecords = records;
        }
        
        public void setProcessedCount(Integer count) {
            this.totalProcessed = count;
        }
        
        public Integer getProcessedCount() {
            return this.totalProcessed;
        }
        
        public void setQueryLimit(Integer value) {
            this.queryLimitValue = value;
        }
        
        public override Iterable<SObject> start(Database.BatchableContext bc) {
            return testRecords != null ? testRecords : new List<SObject>();
        }
        
        protected override void chainNextBatch(Datetime lastProcessedDate, Integer totalProcessed) {
            if (throwErrorOnNextChain) {
                throw new QueryException('Simulated chain error');
            }
            chainingAttempted = true;
            chainedReferenceDate = lastProcessedDate;
            chainedTotalProcessed = totalProcessed;
        }
        
        protected override Integer getBatchSize() {
            return batchSizeValue;
        }
        
        protected override Integer getQueryLimit() {
            return queryLimitValue;
        }
    }
}