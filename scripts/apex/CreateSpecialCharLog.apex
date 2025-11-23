// Create a log event with special characters
rflib_Log_Event__e event = new rflib_Log_Event__e();
event.Log_Level__c = 'INFO';
event.Context__c = 'CSV Export Test';
event.Log_Messages__c = 'Message with "quotes", \nnewlines, and, commas.';
event.Request_ID__c = 'REQ-SPECIAL-CHARS';

EventBus.publish(event);
System.debug('Published special char log event');
