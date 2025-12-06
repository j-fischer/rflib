/*
 * Test class for rflib_BigObjectStatTriggerHandler
 * Covers AFTER INSERT/UPDATE/DELETE paths via the real trigger:
 *   rflib_BigObjectStatTrigger on rflib_Big_Object_Stat__c
 *
 * Notes:
 * - The handler publishes platform events without referencing record fields,
 *   so we create minimal records. If rflib_Big_Object_Stat__c has required
 *   fields in your org, add them below accordingly.
 * - We cannot directly assert EventBus results, but executing without
 *   exceptions provides functional coverage of publish paths.
 */
@IsTest
private class rflib_BigObjectStatTriggerHandlerTest {

    private static final rflib_MockEventPublisher MOCK_EVENT_PUBLISHER = new rflib_MockEventPublisher();

    @IsTest
    static void testAfterInsert_publishesEvent() {
        rflib_BigObjectStatTriggerHandler.EVENT_PUBLISHER = MOCK_EVENT_PUBLISHER;
        
        List<rflib_Big_Object_Stat__c> stats = new List<rflib_Big_Object_Stat__c>();
        for (Integer i = 0; i < 5; i++) {
            stats.add(new rflib_Big_Object_Stat__c());
        }

        insert stats; 

        Assert.areEqual(1, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published once');
        validateEvent(MOCK_EVENT_PUBLISHER.capturedPlatformEvents.get(0));
    }

    @IsTest
    static void testAfterUpdate_publishesEvent() {
        rflib_BigObjectStatTriggerHandler.EVENT_PUBLISHER = MOCK_EVENT_PUBLISHER;

        List<rflib_Big_Object_Stat__c> stats = new List<rflib_Big_Object_Stat__c>();
        for (Integer i = 0; i < 3; i++) {
            stats.add(new rflib_Big_Object_Stat__c());
        }
        insert stats;
        Assert.areEqual(1, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published once');

        update stats;

        Assert.areEqual(2, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published twice');
        validateEvent(MOCK_EVENT_PUBLISHER.capturedPlatformEvents.get(0));
    }

    @IsTest
    static void testAfterDelete_publishesEvent() {
        rflib_BigObjectStatTriggerHandler.EVENT_PUBLISHER = MOCK_EVENT_PUBLISHER;

        List<rflib_Big_Object_Stat__c> stats = new List<rflib_Big_Object_Stat__c>();
        for (Integer i = 0; i < 4; i++) {
            stats.add(new rflib_Big_Object_Stat__c());
        }
        insert stats;
        Assert.areEqual(1, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published once');
        
        delete stats;

        Assert.areEqual(2, MOCK_EVENT_PUBLISHER.getPublishingCounter(), 'Events should have been published twice');
        validateEvent(MOCK_EVENT_PUBLISHER.capturedPlatformEvents.get(0));
    }

    static void validateEvent(SObject e) {
        Assert.isInstanceOfType(e, rflib_Big_Object_Stat_Event__e.class, 'Event should be a Big Object Stat Event');
    }
}
