/**
 * Application Event Archive tab in the Ops Center (RFLIB 11.5.0).
 *
 * Produces:
 *   screenshots/Application_Event_Archive.png               - the archived events of the last seven days
 *   screenshots/Application_Event_Archive_Event_Viewer.png  - the detail pane of a selected event
 *
 * Relies on the 'E2E_ARCHIVE_*' events that the E2E global setup seeds through
 * scripts/apex/SeedApplicationEventArchive.apex.
 *
 * Run: node e2e/tools/capture.mjs recipe e2e/tools/recipes/Application_Event_Archive.mjs
 */
export const target = { tab: 'Application Event Archive', settle: 20000 };

export default async function ({ page, root, shoot, settle }) {
    // The default index filter loads the last seven days in chunks behind an overlay.
    await root.locator('.loading-overlay').waitFor({ state: 'hidden', timeout: 60000 });
    await settle(3000);
    await shoot('screenshots/Application_Event_Archive.png');

    // The retried event carries a JSON payload, which the detail pane pretty-prints.
    await root.locator('c-rflib-big-object-record-list-row').filter({ hasText: 'E2E_ARCHIVE_RETRIED' }).first().click();
    await root.locator('c-rflib-big-object-record-viewer').waitFor({ state: 'visible', timeout: 30000 });
    // The creator's user id resolves to a name with a separate call.
    await settle(5000);
    await shoot('screenshots/Application_Event_Archive_Event_Viewer.png');
}
