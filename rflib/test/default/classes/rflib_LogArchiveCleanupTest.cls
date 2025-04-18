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
        rflib_GlobalSettings.SETTINGS.put('Log_Archive_Cleanup_Batch_Size', '2000');
        rflib_GlobalSettings.SETTINGS.put('Log_Archive_Cleanup_Query_Limit', '50000');
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
        
        rflib_LogArchiveCleanup cleanup = new rflib_LogArchiveCleanup();
        cleanup.dmlExecutor = mockDmlExecutor;

        rflib_MockBatchContext mockBatchContext = new rflib_MockBatchContext();
        
        // WHEN
        Test.startTest();
        List<SObject> result = (List<SObject>) cleanup.start(mockBatchContext);
        cleanup.execute(mockBatchContext, result);
        cleanup.finish(mockBatchContext);
        Test.stopTest();
        
        Assert.areEqual(10, mockDmlExecutor.capturedRecords.size(), 'Should capture 10 records for deletion');
    }
    
    @IsTest
    static void testStartMethod() {
        // GIVEN
        List<rflib_Logs_Archive__b> mockArchives = createMockArchives(10);
        rflib_SOQL.setMock('LogArchiveCleanup.start', mockArchives);
        
        rflib_LogArchiveCleanup cleanup = new rflib_LogArchiveCleanup();
        
        // WHEN
        Test.startTest();
        List<SObject> result = (List<SObject>) cleanup.start(null);
        Test.stopTest();
        
        // THEN
        System.assertEquals(10, result.size(), 'Should return 10 records from start method');
    }
    
    @IsTest
    static void testQueryLimit() {
        // Set specific values in settings
        rflib_GlobalSettings.SETTINGS.put('Log_Archive_Cleanup_Query_Limit', '30000');
        
        rflib_LogArchiveCleanup cleanup = new rflib_LogArchiveCleanup();

        cleanup.start(null);
        
        String queryStr = rflib_LogArchiveCleanup.QUERY.toString();
        Assert.isTrue(queryStr.contains('LIMIT 30000'), 'Query should contain the custom limit: ' + queryStr);
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
    
    private static Database.DeleteResult createSuccessDeleteResult() {
        return (Database.DeleteResult) JSON.deserialize('{"success":true,"id":"0013000000abcde"}', Database.DeleteResult.class);
    }
}