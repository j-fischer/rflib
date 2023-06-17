List<rflib_Application_Event__c> events =  new List<rflib_Application_Event__c> {
    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays((-1) * (Integer.valueOf((Math.random() * 10)) + 35)),
        Event_Name__c = 'bot-request',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays((-1) * (Integer.valueOf((Math.random() * 10)))),
        Event_Name__c = 'bot-request',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now(),
        Event_Name__c = 'bot-request',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays((-1) * (Integer.valueOf((Math.random() * 10)) + 35)),
        Event_Name__c = 'bot-request-success',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays((-1) * (Integer.valueOf((Math.random() * 10)))),
        Event_Name__c = 'bot-request-success',
        Additional_Details__c = null
    ),

    new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now(),
        Event_Name__c = 'bot-request-failure',
        Additional_Details__c = null
    ),

      new rflib_Application_Event__c(
        Created_By_ID__c = UserInfo.getUserId(),
        Occurred_On__c = DateTime.now().addDays((-1) * (Integer.valueOf((Math.random() * 10)) + 10)),
        Event_Name__c = 'import-sample-data',
        Additional_Details__c = null
    )
};

insert events;