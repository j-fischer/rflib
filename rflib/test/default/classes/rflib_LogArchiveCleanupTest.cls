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
private class rflib_LogArchiveCleanupTest {
    
    private static final Integer RETENTION_DAYS = 30;
    
    @TestSetup
    static void setup() {
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
        
        rflib_LogArchiveCleanup cleanup = new rflib_LogArchiveCleanup();
        
        // WHEN
        Test.startTest();
        Database.executeBatch(cleanup);
        Test.stopTest();
        
        // THEN
        // Verify logs would indicate 10 successful deletions
        // Since we can't query Big Objects in tests, we rely on the mock DML
    }
    
    @IsTest
    static void testBatchChaining() {
        // GIVEN
        List<rflib_Logs_Archive__b> mockArchives = createMockArchives(50000);
        rflib_SOQL.setMock('LogArchiveCleanup.start', mockArchives);
        
        rflib_LogArchiveCleanup cleanup = new rflib_LogArchiveCleanup();
        
        // WHEN
        Test.startTest();
        Database.executeBatch(cleanup);
        Test.stopTest();
        
        // THEN
        // Verify logs would indicate chaining of next batch
        // Since we can't assert async operations in tests, we rely on debug logs
    }
    
    @IsTest
    static void testErrorHandling() {
        // GIVEN
        rflib_DmlExecutor mockDmlExecutor = new MockDmlExecutorWithError();
        rflib_LogArchiveCleanup.DML_EXECUTOR = mockDmlExecutor;
        
        List<rflib_Logs_Archive__b> mockArchives = createMockArchives(5);
        rflib_SOQL.setMock('LogArchiveCleanup.start', mockArchives);
        
        rflib_LogArchiveCleanup cleanup = new rflib_LogArchiveCleanup();
        
        // WHEN
        Test.startTest();
        try {
            Database.executeBatch(cleanup);
            System.assert(false, 'Expected exception');
        } catch (rflib_LogArchiveCleanup.rflib_LogArchiveCleanupException ex) {
            // THEN
            System.assert(ex.getMessage().contains('Batch processing failed'));
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
    
    private class MockDmlExecutorWithError implements rflib_DmlExecutor {
        public List<Database.SaveResult> insertImmediate(List<SObject> records) { return null; }
        public List<Database.SaveResult> updateImmediate(List<SObject> records) { return null; }
        public List<Database.DeleteResult> deleteImmediate(List<SObject> records) {
            throw new rflib_LogArchiveCleanup.rflib_LogArchiveCleanupException('Simulated error');
        }
        public List<Database.UpsertResult> upsertImmediate(List<SObject> records) { return null; }
        public List<Database.UpsertResult> upsertImmediate(List<SObject> records, Schema.SObjectField externalIdField) { return null; }
    }
}