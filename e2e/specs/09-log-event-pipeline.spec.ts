import { expect, test } from '@playwright/test';
import { pollUntil } from '../helpers/polling';
import { pipelineMarker, soql } from '../helpers/sf';

// Verifies that a published rflib_Log_Event__e actually reaches its subscriber. Nothing else in the
// suite covers this: the archive specs assert against rows SeedLogArchive.apex writes straight to the
// Big Object precisely to avoid the pipeline's lag, and the Log Monitor's live mode reads the event
// stream over CometD, which bypasses the subscriber entirely. An Apex test cannot cover it either,
// because a platform event triggered Flow does not run under Test.getEventBus().deliver().
//
// The archive is written by rflib_ArchiveLogAction, and that action is only ever invoked by the RFLIB
// Log Event Handler Flow, so an archived row is evidence the subscription is bound and the Flow active.
// The event itself is published by global setup; this spec runs last so the delivery has had the whole
// suite to complete. It needs no browser session.
test.describe.configure({ mode: 'serial' });

const PIPELINE_MESSAGE = 'E2E pipeline verification statement';
const SEEDED_REQUEST_ID_PREFIX = 'e2e-seed-';

// Guards against clock skew between this machine and the org: CreatedDate__c is stamped org-side, so a
// slightly slow org clock could otherwise place the row just before the recorded publish time. The
// window is far shorter than a suite run, so it cannot reach back into a previous run's rows.
const CLOCK_SKEW_ALLOWANCE_MS = 120_000;

// SOQL datetime literals reject the milliseconds that toISOString() emits.
function soqlDateTime(date: Date): string {
    return date.toISOString().replace(/\.\d{3}Z$/, 'Z');
}

// The Big Object index is (CreatedDate__c, Context__c, Log_Level__c, Request_ID__c) and no field may be
// filtered after a range operator, so the context is narrowed here rather than in the WHERE clause.
function archivedPipelineRows(sinceIso: string, context: string): Record<string, string>[] {
    const rows = soql(
        'SELECT Context__c, Log_Level__c, Request_ID__c, Log_Messages__c, Log_Source__c ' +
            `FROM rflib_Logs_Archive__b WHERE CreatedDate__c >= ${sinceIso}`
    );
    return rows.filter((row) => row.Context__c === context);
}

test('a log event published during setup reaches the archive through the subscriber flow', async () => {
    // Generous because the budget has to cover the worst case: running this spec on its own, where only
    // seconds separate global setup's publish from the assertion and the platform event -> Flow ->
    // Big Object hop has been observed to take over two minutes. In a full suite run the preceding specs
    // have already absorbed that lag, so the first poll returns immediately and none of this is spent.
    test.setTimeout(600_000);

    const marker = pipelineMarker();
    const since = soqlDateTime(new Date(Date.parse(marker.publishedAt) - CLOCK_SKEW_ALLOWANCE_MS));

    const rows = await pollUntil(
        async () => archivedPipelineRows(since, marker.context),
        (current) => current.length > 0,
        {
            timeoutMs: 540_000,
            intervalMs: 10_000,
            description: 'the log event published during setup to be archived by the subscriber flow'
        }
    );

    const archived = rows[rows.length - 1];
    expect(archived.Log_Level__c).toBe('ERROR');
    expect(archived.Log_Source__c).toBe('Apex');
    expect(archived.Log_Messages__c).toContain(PIPELINE_MESSAGE);

    // A Request ID assigned by Salesforce, not one written directly to the Big Object by the seed
    // script, which is what makes this row evidence of a real trip through the pipeline.
    expect(archived.Request_ID__c).not.toContain(SEEDED_REQUEST_ID_PREFIX);
    expect(archived.Request_ID__c.length).toBeGreaterThan(0);
});
