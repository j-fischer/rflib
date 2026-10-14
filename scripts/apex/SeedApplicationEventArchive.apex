// Seeds the rflib_Application_Event_Archive__b Big Object directly for the Big Object Explorer E2E spec.
// The archiver only moves events older than the retention threshold, so waiting for it is not an option;
// Database.insertImmediate writes the rows the way the archiver does. Rows are recent, so the explorer's
// default LAST_N_DAYS:7 filter loads them, and carry the 'E2E_ARCHIVE_' event name prefix the spec filters on.
// Each row has its own related record and a JSON payload, so the spec can search on fields the index cannot
// reach. Re-running the script overwrites rows with identical index values rather than duplicating them.
List<rflib_Application_Event_Archive__b> rows = new List<rflib_Application_Event_Archive__b>();
Datetime occurredOn = Datetime.now().addHours(-1);
List<String> outcomes = new List<String>{ 'accepted', 'rejected', 'retried' };
for (Integer i = 0; i < outcomes.size(); i++) {
    rflib_Application_Event_Archive__b row = new rflib_Application_Event_Archive__b();
    row.Occurred_On__c = occurredOn.addMinutes(-i);
    row.Event_Name__c = 'E2E_ARCHIVE_' + outcomes[i].toUpperCase();
    row.Related_Record_ID__c = 'E2E-REL-' + i;
    row.Created_By_ID__c = UserInfo.getUserId();
    row.Additional_Details__c = '{"outcome":"' + outcomes[i] + '","marker":"e2e-payload-' + outcomes[i] + '"}';
    rows.add(row);
}

Database.insertImmediate(rows);
System.debug('Seeded ' + rows.size() + ' rflib_Application_Event_Archive__b rows for E2E.');
