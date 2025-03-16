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
private class rflib_BigObjectStatControllerTest {

    private static final String MOCK_ID = 'rflib_BigObjectStatController.getStats';
    
    @IsTest
    static void testGetStats() {
        // GIVEN
        List<rflib_Big_Object_Stat__c> mockStats = new List<rflib_Big_Object_Stat__c>{
            createStat('rflib_Logs_Archive__b', 100),
            createStat('rflib_Application_Event_Archive__b', 200)
        };
        
        rflib_SOQL.setMock(MOCK_ID, mockStats);

        // WHEN
        Test.startTest();
        List<rflib_Big_Object_Stat__c> result = rflib_BigObjectStatController.getStats(
            'rflib_Logs_Archive__b,rflib_Application_Event_Archive__b',
            'Record_Count__c'
        );
        Test.stopTest();

        // THEN
        Assert.areEqual(2, result.size(), 'Should return correct number of stats');
        Assert.areEqual('rflib_Logs_Archive__b', result[0].Name, 'Should return first object stats');
        Assert.areEqual(100, result[0].Record_Count__c, 'Should return correct record count');
    }

    @IsTest
    static void testGetStatsError() {
        // WHEN
        try {
            rflib_BigObjectStatController.getStats('rflib_Logs_Archive__b', 'Invalid_Field__c');
            Assert.fail('Should throw exception');
        } catch (AuraHandledException ex) {
            // THEN
            Assert.isTrue(ex.getMessage().contains('Invalid_Field__c'), 'Should contain error message. Actual message: ' + ex.getMessage());
        }
    }

    @IsTest
    static void testRefreshStats() {
        // WHEN
        Test.startTest();
        rflib_BigObjectStatController.refreshStats(
            'rflib_Logs_Archive__b',
            new List<String>{ 'CreatedDate__c' },
            'ASC'
        );
        Test.stopTest();

        // THEN
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'rflib_BigObjectCounter'
        ];
        
        Assert.areEqual(1, jobs.size(), 'Should create batch job');
    }

    @IsTest
    static void testRefreshStatsError() {
        // WHEN
        try {
            rflib_BigObjectStatController.refreshStats(null, null, null);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException ex) {
            // THEN
            Assert.isTrue(
                ex.getMessage().contains('Big Object Type cannot be blank'), 
                'Should contain validation message'
            );
        }
    }

    @IsTest
    static void testGetFieldMetadata() {
        // WHEN
        Test.startTest();
        List<rflib_BigObjectStatController.FieldMetadata> result = 
            rflib_BigObjectStatController.getFieldMetadata(
                'Record_Count__c'
            );
        Test.stopTest();

        // THEN
        Assert.areEqual(2, result.size(), 'Should return metadata for all fields');
        Assert.areEqual('Name', result[0].fieldName, 'Should include Name field');
        Assert.areEqual('number', result[1].type, 'Should map Record_Count to number');
    }

    @IsTest
    static void testGetFieldMetadataError() {
        // WHEN
        try {
            rflib_BigObjectStatController.getFieldMetadata('Invalid_Field__c');
            Assert.fail('Should throw exception');
        } catch (AuraHandledException ex) {
            // THEN
            Assert.isTrue(
                ex.getMessage().contains('Failed to get field metadata'), 
                'Should contain invalid field name. error message: ' + ex.getMessage()
            );
        }
    }

    private static rflib_Big_Object_Stat__c createStat(String name, Integer count) {
        return new rflib_Big_Object_Stat__c(
            Name = name,
            Record_Count__c = count
        );
    }
}