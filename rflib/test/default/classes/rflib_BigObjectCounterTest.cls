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
private class rflib_BigObjectCounterTest {
    
    private static final String TEST_QUERY = 'SELECT Id FROM Test_Big_Object__b';
    private static final String TEST_BIG_OBJECT = 'Test_Big_Object__b';
    private static final String TEST_TARGET_OBJECT = 'rflib_Big_Object_Stat__c';
    private static final String TEST_COUNTER_FIELD = 'Record_Count__c';

    @TestSetup
    static void setup() {
        rflib_Big_Object_Stat__c countRecord = new rflib_Big_Object_Stat__c(
            Name = TEST_BIG_OBJECT,
            Record_Count__c = 0
        );
        insert countRecord;
    }

    @IsTest
    static void should_InitializeCorrectly_when_ConstructorCalled() {
        // Given
        Integer initialCount = 0;

        // When
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            TEST_QUERY,
            TEST_BIG_OBJECT,
            TEST_TARGET_OBJECT,
            TEST_COUNTER_FIELD,
            initialCount
        );

        // Then
        System.assertEquals(TEST_QUERY, counter.query);
        System.assertEquals(TEST_BIG_OBJECT, counter.bigObjectType);
        System.assertEquals(TEST_TARGET_OBJECT, counter.targetObjectApiName);
        System.assertEquals(TEST_COUNTER_FIELD, counter.targetCounterFieldApiName);
        System.assertEquals(initialCount, counter.currentCount);
    }

    @IsTest
    static void should_IncrementCount_when_ExecuteBatchCalled() {
        // Given
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            TEST_QUERY,
            TEST_BIG_OBJECT,
            TEST_TARGET_OBJECT,
            TEST_COUNTER_FIELD,
            0
        );

        List<SObject> mockRecords = new List<SObject>();
        for(Integer i = 0; i < 5; i++) {
            mockRecords.add(new rflib_Application_Event__c(
                Event_Name__c = 'Test Event ' + i,
                Occurred_On__c = Datetime.now()
            )); 
        }

        // When
        Test.startTest();
        counter.execute(null, mockRecords);
        Test.stopTest();

        // Then
        System.assertEquals(5, counter.currentCount);
    }

    @IsTest
    static void should_UpdateTargetRecord_when_FinishCalled() {
        // Given
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            TEST_QUERY,
            TEST_BIG_OBJECT,
            TEST_TARGET_OBJECT,
            TEST_COUNTER_FIELD,
            100
        );

        // When
        Test.startTest();
        counter.finish(null);
        Test.stopTest();

        // Then
        rflib_Big_Object_Stat__c updatedRecord = [
            SELECT Id, Record_Count__c, LastModifiedDate 
            FROM rflib_Big_Object_Stat__c 
            WHERE Name = :TEST_BIG_OBJECT
            LIMIT 1
        ];

        System.assertEquals(100, updatedRecord.Record_Count__c);
    }

    @IsTest
    static void should_ThrowException_when_NoTargetRecordFound() {
        // Given
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            TEST_QUERY,
            'NonExistent_Big_Object__b',
            TEST_TARGET_OBJECT,
            TEST_COUNTER_FIELD,
            100
        );

        // When/Then
        Test.startTest();
        try {
            counter.finish(null);
            System.assert(false, 'Expected exception was not thrown');
        } catch (rflib_BigObjectCounter.rflib_BigObjectCounterException ex) {
            System.assert(ex.getMessage().contains('No target record found'));
        }
        Test.stopTest();
    }

    @IsTest
    static void should_ReturnQueryLocator_when_StartCalled() {
        // Given
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            'SELECT Id FROM Account',  // Using standard object for test
            TEST_BIG_OBJECT,
            TEST_TARGET_OBJECT,
            TEST_COUNTER_FIELD,
            0
        );

        // When
        Test.startTest();
        Database.QueryLocator locator = counter.start(null);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, locator);
    }

    @IsTest
    static void should_ThrowException_when_InvalidQueryProvided() {
        // Given
        rflib_BigObjectCounter counter = new rflib_BigObjectCounter(
            'INVALID QUERY',
            TEST_BIG_OBJECT,
            TEST_TARGET_OBJECT,
            TEST_COUNTER_FIELD,
            0
        );

        // When/Then
        Test.startTest();
        try {
            counter.start(null);
            System.assert(false, 'Expected exception was not thrown');
        } catch (rflib_BigObjectCounter.rflib_BigObjectCounterException ex) {
            System.assert(ex.getMessage().contains('Failed to create query locator'));
        }
        Test.stopTest();
    }
}