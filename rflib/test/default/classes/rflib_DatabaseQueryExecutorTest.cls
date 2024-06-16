@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_DatabaseQueryExecutorTest {
   
    @IsTest
    private static void testCountQuery() {
        String query = 'SELECT COUNT() FROM rflib_Application_Event__c';
        
        Test.startTest();
        System.assertEquals(Database.countQuery(query), new rflib_DatabaseQueryExecutor().countQuery(query));
        Test.stopTest();
    }

    @IsTest
    private static void testQuery() {
        String query = 'SELECT Id FROM rflib_Application_Event__c ORDER BY CreatedDate DESC LIMIT 200';
        
        Test.startTest();
        System.assertEquals(
            [SELECT Id FROM rflib_Application_Event__c ORDER BY CreatedDate DESC LIMIT 200], 
            new rflib_DatabaseQueryExecutor().query(query)
        );
        Test.stopTest();
    }
    
    @IsTest
    private static void testFetch() {
        List<rflib_Application_Event__c> events = new List<rflib_Application_Event__c>();
        for (Integer i = 0; i < 5000; i++) {
            events.add(new rflib_Application_Event__c(
                Name = 'Test Event ' + i,
                Event_Name__c = 'test-event-' + ((Integer) i / 1000),
                Occurred_On__c = DateTime.now(),
                Related_Record_ID__c = 'NA',
                Created_By_ID__c = UserInfo.getUserId()
            ));
        }
        insert events;
        
        String query = 'SELECT Id FROM rflib_Application_Event__c ORDER BY CreatedDate DESC';
        
        Test.startTest();
        
        // Test the fetch method with a start position and count
        rflib_DatabaseCursorQueryResult result = new rflib_DatabaseQueryExecutor().fetch(query, 0, 200);
        System.assertEquals(200, result.records.size(), 'Expected 200 records fetched');
        System.assertEquals(5000, result.totalQueryNumRecords, 'Expected total number of records to be 5000');
        System.assertEquals(0, result.position, 'Expected start position to be 0');
        
        // Test fetching from a different position
        result = new rflib_DatabaseQueryExecutor().fetch(query, 200, 200);
        System.assertEquals(200, result.records.size(), 'Expected 200 records fetched from position 200');
        System.assertEquals(5000, result.totalQueryNumRecords, 'Expected total number of records to be 5000');
        System.assertEquals(200, result.position, 'Expected start position to be 200');
        
        // Test fetching with a count that exceeds the remaining records
        result = new rflib_DatabaseQueryExecutor().fetch(query, 4900, 200);
        System.assertEquals(100, result.records.size(), 'Expected 100 records fetched from position 4900');
        System.assertEquals(5000, result.totalQueryNumRecords, 'Expected total number of records to be 5000');
        System.assertEquals(4900, result.position, 'Expected start position to be 4900');
        
        Test.stopTest();
    }
}
