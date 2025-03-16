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
private class rflib_BigObjectCounterTest {

    private static final String BIG_OBJECT_TYPE = 'rflib_Log_Archive__b';
    private static final String TARGET_OBJECT = 'rflib_Big_Object_Stat__c';
    private static final String TARGET_FIELD = 'Record_Count__c';
    private static final String QUERY_MOCK_ID = 'rflib_BigObjectCounter.query';
    private static final List<String> INDEX_FIELDS = new List<String> {'CreatedDate__c','Context__c','Log_Level__c','Request_ID__c'};
    
    @TestSetup
    static void setupTestData() {
        rflib_Big_Object_Stat__c countRecord = new rflib_Big_Object_Stat__c(
            Name = BIG_OBJECT_TYPE,
            Record_Count__c = 0
        );
        insert countRecord;
    }
    
    @IsTest
    private static void testInitialBatch() {
        // GIVEN
        List<SObject> mockBigObjects = createBigObjects(5);
        rflib_SOQL.setMock(QUERY_MOCK_ID, mockBigObjects);
        
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            BIG_OBJECT_TYPE,
            TARGET_OBJECT,
            TARGET_FIELD,
            0,
            null,
            '',
            10,
            INDEX_FIELDS,
            'ASC'
        );
        
        // WHEN
        Test.startTest();
        Database.BatchableContext mockBC = createMockBatchableContext();
        List<SObject> scope = (List<SObject>)counter.start(mockBC);
        counter.execute(mockBC, scope);
        counter.finish(mockBC);
        Test.stopTest();
        
        // THEN
        rflib_Big_Object_Stat__c result = [SELECT Id, Record_Count__c FROM rflib_Big_Object_Stat__c WHERE Name = :BIG_OBJECT_TYPE LIMIT 1];
        System.assertEquals(5, result.Record_Count__c, 'Count should be updated to 5');
    }
    
    @IsTest
    private static void testContinuationBatch() {
        // GIVEN
        List<SObject> mockBigObjects = createBigObjects(5);
        rflib_SOQL.setMock(QUERY_MOCK_ID, mockBigObjects);
        
        // Start with existing count of 10
        Datetime lastIndexValue = Datetime.now();
        String lastCompoundKeys = '2023-01-01||Record1';
        
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            BIG_OBJECT_TYPE,
            TARGET_OBJECT,
            TARGET_FIELD,
            10,
            lastIndexValue,
            lastCompoundKeys,
            10,
            INDEX_FIELDS,
            'ASC'
        );
        
        // WHEN
        Test.startTest();
        Database.BatchableContext mockBC = createMockBatchableContext();
        List<SObject> scope = (List<SObject>)counter.start(mockBC);
        counter.execute(mockBC, scope);
        counter.finish(mockBC);
        Test.stopTest();
        
        // THEN
        rflib_Big_Object_Stat__c result = [SELECT Id, Record_Count__c FROM rflib_Big_Object_Stat__c WHERE Name = :BIG_OBJECT_TYPE LIMIT 1];
        System.assertEquals(15, result.Record_Count__c, 'Count should be updated from 10 to 15');
    }
    
    @IsTest
    private static void testEmptyBatch() {
        // GIVEN
        rflib_SOQL.setMock(QUERY_MOCK_ID, new List<SObject>());
        
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            BIG_OBJECT_TYPE,
            TARGET_OBJECT,
            TARGET_FIELD,
            10,
            Datetime.now(),
            '',
            10,
            INDEX_FIELDS,
            'ASC'
        );
        
        // WHEN
        Test.startTest();
        Database.BatchableContext mockBC = createMockBatchableContext();
        List<SObject> scope = (List<SObject>)counter.start(mockBC);
        counter.execute(mockBC, scope);
        counter.finish(mockBC);
        Test.stopTest();
        
        // THEN
        rflib_Big_Object_Stat__c result = [SELECT Id, Record_Count__c FROM rflib_Big_Object_Stat__c WHERE Name = :BIG_OBJECT_TYPE LIMIT 1];
        System.assertEquals(10, result.Record_Count__c, 'Count should remain at 10');
    }
    
    @IsTest
    private static void testChainBatchWhenPageSizeFilled() {
        // GIVEN
        // Create exactly pageSize records to trigger chaining
        List<SObject> mockBigObjects = createBigObjects(5);
        rflib_SOQL.setMock(QUERY_MOCK_ID, mockBigObjects);
        
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            BIG_OBJECT_TYPE,
            TARGET_OBJECT,
            TARGET_FIELD,
            0,
            null,
            '',
            5, // pageSize equals mockBigObjects.size()
            INDEX_FIELDS,
            'ASC'
        );
        
        // WHEN
        Test.startTest();
        Database.BatchableContext mockBC = createMockBatchableContext();
        List<SObject> scope = (List<SObject>)counter.start(mockBC);
        counter.execute(mockBC, scope);
        counter.finish(mockBC);
        Test.stopTest();
        
        // THEN
        rflib_Big_Object_Stat__c result = [SELECT Id, Record_Count__c FROM rflib_Big_Object_Stat__c WHERE Name = :BIG_OBJECT_TYPE LIMIT 1];
        System.assertEquals(5, result.Record_Count__c, 'Count should be updated to 5');
        // We can't directly test if a new batch was chained, but the counter should have processed all records
    }
    
    @IsTest
    private static void testCompoundKeyTracking() {
        // GIVEN
        // Create objects with some duplicate keys to test compound key tracking
        List<SObject> mockBigObjects = new List<SObject>();
        
        Datetime createdDate = Datetime.now().addDays(-1);
        mockBigObjects.addAll(createBigObjects(3, createdDate));
        mockBigObjects.addAll(createBigObjects(3));
        
        rflib_SOQL.setMock(QUERY_MOCK_ID, mockBigObjects);
        
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            BIG_OBJECT_TYPE,
            TARGET_OBJECT,
            TARGET_FIELD,
            0,
            null,
            '',
            10,
            INDEX_FIELDS,
            'ASC'
        );
        
        // WHEN
        Test.startTest();
        Database.BatchableContext mockBC = createMockBatchableContext();
        List<SObject> scope = (List<SObject>)counter.start(mockBC);
        counter.execute(mockBC, scope);
        counter.finish(mockBC);
        Test.stopTest();
        
        // THEN
        rflib_Big_Object_Stat__c result = [SELECT Id, Record_Count__c FROM rflib_Big_Object_Stat__c WHERE Name = :BIG_OBJECT_TYPE LIMIT 1];
        System.assertEquals(6, result.Record_Count__c, 'Count should be 6 even with distinct compound keys');
    }
    
    @IsTest
    private static void testConstructorValidation() {
        // WHEN & THEN - Test invalid inputs
        try {
            new rflib_BigObjectCounter(
                '',  // Empty big object type
                TARGET_OBJECT,
                TARGET_FIELD,
                0,
                null,
                '',
                10,
                INDEX_FIELDS,
                'ASC'
            );
            System.assert(false, 'Should have thrown exception for empty big object type');
        } catch (rflib_BigObjectCounter.rflib_BigObjectCounterException ex) {
            System.assert(ex.getMessage().contains('Big Object Type cannot be blank'), 'Expected validation error message');
        }
        
        try {
            new rflib_BigObjectCounter(
                BIG_OBJECT_TYPE,
                '',  // Empty target object
                TARGET_FIELD,
                0,
                null,
                '',
                10,
                INDEX_FIELDS,
                'ASC'
            );
            System.assert(false, 'Should have thrown exception for empty target object');
        } catch (rflib_BigObjectCounter.rflib_BigObjectCounterException ex) {
            System.assert(ex.getMessage().contains('Target Object API Name cannot be blank'), 'Expected validation error message');
        }
        
        try {
            new rflib_BigObjectCounter(
                BIG_OBJECT_TYPE,
                TARGET_OBJECT,
                '',  // Empty target field
                0,
                null,
                '',
                10,
                INDEX_FIELDS,
                'ASC'
            );
            System.assert(false, 'Should have thrown exception for empty target field');
        } catch (rflib_BigObjectCounter.rflib_BigObjectCounterException ex) {
            System.assert(ex.getMessage().contains('Target Counter Field cannot be blank'), 'Expected validation error message');
        }
        
        try {
            new rflib_BigObjectCounter(
                BIG_OBJECT_TYPE,
                TARGET_OBJECT,
                TARGET_FIELD,
                0,
                null,
                '',
                10,
                null,  // Null index fields
                'ASC'
            );
            System.assert(false, 'Should have thrown exception for null index fields');
        } catch (rflib_BigObjectCounter.rflib_BigObjectCounterException ex) {
            System.assert(ex.getMessage().contains('Index Fields cannot be empty'), 'Expected validation error message');
        }
    }
    
    @IsTest
    private static void testProcessingError() {
        // GIVEN
        // Create a mock implementation that will throw an exception during execute
        List<SObject> mockBigObjects = createBigObjects(5);
        rflib_SOQL.setMock(QUERY_MOCK_ID, mockBigObjects);
        
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            BIG_OBJECT_TYPE,
            TARGET_OBJECT,
            'Invalid_Field__c', 
            0,
            null,
            '',
            10,
            INDEX_FIELDS,
            'ASC'
        );
        
        // WHEN
        Test.startTest();
        try {
            Database.BatchableContext mockBC = createMockBatchableContext();
            List<SObject> scope = (List<SObject>)counter.start(mockBC);
            counter.execute(mockBC, scope);
            counter.finish(mockBC);
            counter.execute(mockBC, scope);
            System.assert(false, 'Should have thrown exception during execute');
        } catch (rflib_BigObjectCounter.rflib_BigObjectCounterException ex) {
            System.assert(ex.getMessage().contains('Finish processing failed'), 'Error message does not match. Actual error message: ' + ex.getMessage());
        }
        
        Test.stopTest();
    }

    private static List<SObject> createBigObjects(Integer count) {
        return createBigObjects(count, Datetime.now()); 
    }

    private static List<SObject> createBigObjects(Integer count, Datetime createdDate) {
        List<SObject> bigObjects = new List<SObject>();
        for (Integer i = 0; i < count; i++) {
            bigObjects.add(new rflib_Logs_Archive__b(
                CreatedDate__c = createdDate,
                CreatedById__c = UserInfo.getUserId(),
                Request_ID__c = '123',
                Context__c = 'Log Message ' + i,
                Log_Level__c = 'INFO',
                Log_Messages__c = 'Some messages',
                Platform_Info__c = '{ someKey: "someValue" }'
            ));
        }
        return bigObjects;
    }
    
    private static Database.BatchableContext createMockBatchableContext() {
        return new BatchableContextMock();
    }
    
    private class BatchableContextMock implements Database.BatchableContext {

        public Id getChildJobId() {
            // cspell:disable-next-line
            return '01n30000004wEYDAA3'; // Mock job ID
        }

	    public Id getJobId() {
            // cspell:disable-next-line
            return '01n30000004wEYDAA2'; // Mock job ID
        }
    }
}