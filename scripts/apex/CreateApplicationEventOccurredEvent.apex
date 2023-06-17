List<rflib_Application_Event_Occurred_Event__e> events =  new List<rflib_Application_Event_Occurred_Event__e> {
    new rflib_Application_Event_Occurred_Event__e(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays(-1),
        Event_Name__c = 'Yesterday Test Event',
        Related_Record_ID__c = null,
        Additional_Details__c = null
    ),

    new rflib_Application_Event_Occurred_Event__e(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now(),
        Event_Name__c = 'Today Test Event',
        Related_Record_ID__c = null,
        Additional_Details__c = null
    )
};

EventBus.publish(events);