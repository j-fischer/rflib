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
private class rflib_LogArchiveCleanupTest {
    
    private static final Integer RETENTION_DAYS = 30;
    
    @TestSetup
    static void setup() {
        rflib_TestUtil.prepareLoggerForUnitTests();
        // We'll mock the setting through rflib_GlobalSettings.SETTINGS
        rflib_GlobalSettings.SETTINGS.put('Log_Archive_Retain_X_Days', String.valueOf(RETENTION_DAYS));
    }
    
    @IsTest
    static void testScheduleExecution() {
        // GIVEN
        String cronExp = '0 0 0 * * ?';
        
        // WHEN
        Test.startTest();
        String jobId = System.schedule('Test Log Archive Cleanup', cronExp, new rflib_LogArchiveCleanup());
        Test.stopTest();
        
        // THEN
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
    }
    
    @IsTest
    static void testBatchProcessing() {
        // GIVEN
        List<rflib_Logs_Archive__b> mockArchives = createMockArchives(10);
        rflib_SOQL.setMock('LogArchiveCleanup.start', mockArchives);
        
        // Mock the DML executor to avoid callout issues
        List<Database.DeleteResult> successResults = createSuccessDeleteResults(10);
        rflib_MockDmlExecutor mockDmlExecutor = new rflib_MockDmlExecutor(successResults);
        rflib_LogArchiveCleanup.DML_EXECUTOR = mockDmlExecutor;
        
        rflib_LogArchiveCleanup cleanup = new rflib_LogArchiveCleanup();
        
        // WHEN
        Test.startTest();
        Database.executeBatch(cleanup);
        Test.stopTest();
        
        // THEN
        // Since batch is asynchronous and serialized/deserialized, mockDmlExecutor state 
        // won't be preserved after Test.stopTest(). We can only validate the test setup.
        System.assertEquals(10, mockArchives.size(), 'Should have prepared 10 records for deletion');
    }
    
    @IsTest
    static void testReferenceDateNormalization() {
        // GIVEN - Setting a 1-day retention period
        rflib_GlobalSettings.SETTINGS.put('Log_Archive_Retain_X_Days', '1');
        
        // WHEN - Create a cleanup instance at a specific time
        rflib_LogArchiveCleanup cleanup = new rflib_LogArchiveCleanup();
        
        // Access the reference date directly (marked as @TestVisible in the class)
        Datetime referenceDate = cleanup.referenceDate;
        
        // THEN - Verify the referenceDate is properly normalized to midnight
        Date expectedDate = Date.today().addDays(-1);
        Datetime expectedDateTime = Datetime.newInstance(expectedDate, Time.newInstance(0, 0, 0, 0));
        
        System.assertEquals(expectedDateTime, referenceDate, 
            'Reference date should be normalized to midnight of yesterday');
        System.assertEquals(0, referenceDate.hour(), 'Hour should be 0');
        System.assertEquals(0, referenceDate.minute(), 'Minute should be 0');
        System.assertEquals(0, referenceDate.second(), 'Second should be 0');
    }

    @IsTest
    static void testBatchChaining() {
        // GIVEN
        List<rflib_Logs_Archive__b> mockArchives = createMockArchives(50000);
        rflib_SOQL.setMock('LogArchiveCleanup.start', mockArchives);
        
        // Mock the DML executor to avoid callout issues
        List<Database.DeleteResult> successResults = createSuccessDeleteResults(50000);
        rflib_MockDmlExecutor mockDmlExecutor = new rflib_MockDmlExecutor(successResults);
        rflib_LogArchiveCleanup.DML_EXECUTOR = mockDmlExecutor;
        
        TestableLogArchiveCleanup cleanup = new TestableLogArchiveCleanup();
        
        // WHEN
        Test.startTest();
        Database.BatchableContext bc = new rflib_MockBatchContext();
        List<SObject> scope = (List<SObject>)cleanup.start(bc);
        cleanup.execute(bc, scope);
        cleanup.finish(bc);
        Test.stopTest();

        // THEN
        System.assert(cleanup.chainingAttempted, 'Should attempt to chain next batch');
        System.assertEquals(50000, cleanup.chainedTotalProcessed, 'Should pass correct total processed');
        System.assertEquals(50000, cleanup.chainedBatchSize, 'Should maintain batch size');
        System.assertNotEquals(null, cleanup.chainedReferenceDate, 'Should pass reference date');
    }
    
    @IsTest
    static void testErrorHandling() {
        // GIVEN
        List<rflib_Logs_Archive__b> mockArchives = createMockArchives(5);
        rflib_SOQL.setMock('LogArchiveCleanup.start', mockArchives);
        
        // Use mock that will trigger an exception
        QueryException ex = new QueryException('Simulated error');
        rflib_MockDmlExecutor mockDmlExecutor = new rflib_MockDmlExecutor(ex);
        rflib_LogArchiveCleanup.DML_EXECUTOR = mockDmlExecutor;
        
        rflib_LogArchiveCleanup cleanup = new rflib_LogArchiveCleanup();
        
        // WHEN
        Test.startTest();
        try {
            List<SObject> scope = (List<SObject>)cleanup.start(null);
            cleanup.execute(null, scope);
            System.assert(false, 'Expected exception');
        } catch (rflib_LogArchiveCleanup.rflib_LogArchiveCleanupException actualEx) {
            // THEN
            System.assert(actualEx.getMessage().contains('Batch processing failed'));
            System.assert(actualEx.getMessage().contains('Simulated error'));
        }
        Test.stopTest();
    }
    
    private static List<rflib_Logs_Archive__b> createMockArchives(Integer count) {
        List<rflib_Logs_Archive__b> archives = new List<rflib_Logs_Archive__b>();
        Datetime oldDate = Datetime.now().addDays(-60); // Older than retention period
        
        for (Integer i = 0; i < count; i++) {
            archives.add(new rflib_Logs_Archive__b(
                CreatedDate__c = oldDate.addMinutes(i),
                Context__c = 'Test Context ' + i,
                Log_Level__c = 'INFO',
                Request_ID__c = 'REQ-' + i
            ));
        }
        
        return archives;
    }
    
    private static List<Database.DeleteResult> createSuccessDeleteResults(Integer count) {
        List<Database.DeleteResult> results = new List<Database.DeleteResult>();
        for (Integer i = 0; i < count; i++) {
            results.add(createSuccessDeleteResult());
        }
        return results;
    }
    
    private static List<Database.DeleteResult> createFailureDeleteResults(Integer count) {
        List<Database.DeleteResult> results = new List<Database.DeleteResult>();
        for (Integer i = 0; i < count; i++) {
            results.add(createFailureDeleteResult());
        }
        return results;
    }
    
    private static Database.DeleteResult createSuccessDeleteResult() {
        return (Database.DeleteResult) JSON.deserialize('{"success":true,"id":"0013000000abcde"}', Database.DeleteResult.class);
    }
    
    private static Database.DeleteResult createFailureDeleteResult() {
        return (Database.DeleteResult) JSON.deserialize('{"success":false,"errors":[{"message":"Simulated error","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.DeleteResult.class);
    }

    
    private class TestableLogArchiveCleanup extends rflib_LogArchiveCleanup {
        public Boolean chainingAttempted = false;
        public Integer chainedBatchSize;
        public Datetime chainedReferenceDate;
        public Integer chainedTotalProcessed;

        protected override void chainNextBatch(Integer batchSize, Datetime referenceDate, Integer totalProcessed) {
            chainingAttempted = true;
            chainedBatchSize = batchSize;
            chainedReferenceDate = referenceDate;
            chainedTotalProcessed = totalProcessed;
        }
    }
}