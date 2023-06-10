List<rflib_Application_Event__c> events =  new List<rflib_Application_Event__c> {
    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays(-47),
        Event_Name__c = 'Test Event to Archive',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays(-1),
        Event_Name__c = 'Yesterday Test Event',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now(),
        Event_Name__c = 'Today Test Event',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays(-47),
        Event_Name__c = 'An Event',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays(-1),
        Event_Name__c = 'An Event',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now(),
        Event_Name__c = 'An Event',
        Additional_Details__c = null
    ),

      new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays(-13),
        Event_Name__c = 'An Event',
        Additional_Details__c = null
    )
};

insert events;