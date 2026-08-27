// Publishes a single log event through the real logger so that 09-log-event-pipeline.spec.ts can prove
// the rflib_Log_Event__e Platform Event was delivered to its subscriber. The archive is written by
// rflib_ArchiveLogAction, which is only ever invoked by the RFLIB Log Event Handler Flow, so an archived
// row is evidence that the subscription is bound and the Flow is active.
//
// The context is deliberately distinct from the 'TestContext' used by CreateLogEvent.apex and
// SeedLogArchive.apex, so the spec cannot mistake a seeded row for a row that traveled the pipeline.
rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('E2ELogPipeline');
LOGGER.error('E2E pipeline verification statement');
