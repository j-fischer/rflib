trigger rflib_BatchApexErrorEventTrigger on BatchApexErrorEvent (after insert) {
    rflib_BatchApexErrorEventAdapter.handle(Trigger.new);
}
