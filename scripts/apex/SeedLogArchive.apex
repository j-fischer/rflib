// Seeds the rflib_Logs_Archive__b Big Object directly so the archive-dependent E2E specs
// (the Management Console "log archive alert" and the Log Monitor "Archive" mode) have
// deterministic, recent data. Writing straight to the Big Object with Database.insertImmediate
// skips the multi-hop platform-event -> flow -> archive pipeline that can lag minutes in a fresh
// scratch org, so the rows are queryable shortly after global setup instead of being raced by the
// early specs. Rows are recent (within the alert's 24h lookback) and carry the 'TestContext' the
// specs filter on; distinct index values prevent the Big Object from collapsing them into one row.
List<rflib_Logs_Archive__b> rows = new List<rflib_Logs_Archive__b>();
List<String> levels = new List<String>{ 'ERROR', 'WARN', 'FATAL', 'INFO' };
for (Integer i = 0; i < levels.size(); i++) {
    rflib_Logs_Archive__b row = new rflib_Logs_Archive__b();
    row.CreatedDate__c = Datetime.now().addSeconds(-i);
    row.CreatedById__c = UserInfo.getUserId();
    row.Context__c = 'TestContext';
    row.Log_Level__c = levels[i];
    row.Request_ID__c = 'e2e-seed-' + levels[i];
    row.Log_Messages__c = 'E2E seeded ' + levels[i] + ' archive entry for deterministic UI tests';
    row.Platform_Info__c = '{"CPU Time":12,"Heap Size":4080}';
    rows.add(row);
}

Database.insertImmediate(rows);
System.debug('Seeded ' + rows.size() + ' rflib_Logs_Archive__b rows for E2E.');
