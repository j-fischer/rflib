import { BrowserContext, expect, Page, test } from '@playwright/test';
import { createOpsCenterSession } from '../fixtures';
import { clickDialogButton, expectToast, selectMenuItem } from '../helpers/lightning';
import { pollUntil } from '../helpers/polling';
import { CONNECTION_MODES, LogMonitorPage } from '../pages/log-monitor.page';
import { TABS } from '../pages/ops-center-app.page';

// Destructive spec: "Clear Archive" wipes rflib_Logs_Archive__b. It must run
// after 02 (archive alert, big object counts) and 04 (log monitor).
test.describe.configure({ mode: 'serial' });

let context: BrowserContext;
let page: Page;
let monitor: LogMonitorPage;

test.beforeAll(async ({ browser }) => {
    ({ context, page } = await createOpsCenterSession(browser, TABS.logMonitor));
    monitor = new LogMonitorPage(page);
});

test.afterAll(async () => {
    await context?.close();
});

async function queryArchiveAndCountRows(): Promise<number> {
    await monitor.queryArchiveButton.click();
    await page.waitForTimeout(3_000);
    return monitor.eventRows().count();
}

test('archive mode queries the seeded archived log events', async () => {
    await monitor.connectInMode(CONNECTION_MODES.archive);
    await expect(monitor.queryArchiveButton).toBeVisible();

    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
    await monitor.setArchiveDateRange(yesterday, tomorrow);

    // Global setup seeds the Big Object directly, so rows are present; specs 01-04 give them ample time
    // to be queryable. Re-query a few times to absorb any residual Big Object read lag.
    await pollUntil(queryArchiveAndCountRows, (count) => count > 0, {
        timeoutMs: 90_000,
        intervalMs: 10_000,
        description: 'archived log events'
    });
    await expect(monitor.eventRows().filter({ hasText: 'TestContext' }).first()).toBeVisible();
});

test('archived events open in the log event viewer', async () => {
    await monitor.eventRows().first().click();
    await expect(monitor.viewer).toBeVisible({ timeout: 30_000 });
    await expect(monitor.viewer.getByText('Log Messages')).toBeVisible();
});

test('clear archive removes expired records after confirmation', async () => {
    await selectMenuItem(monitor.archiveSettingsMenu, 'Clear Archive');
    await expect(page.getByText('Are you sure you want to clear the archive?')).toBeVisible();
    await clickDialogButton(page, 'Clear');

    // Clearing resets the displayed list immediately and reports the count of
    // deleted records via toast. Only records older than the configured
    // retention period are deleted, so the fresh test records survive.
    await expectToast(page, /Cleared \d+ archived records/);
    await expect(monitor.totalLogEventsText).toContainText('0 Total Log Events');

    await pollUntil(queryArchiveAndCountRows, (count) => count > 0, {
        timeoutMs: 90_000,
        intervalMs: 10_000,
        description: 'recent records to remain after clearing expired ones'
    });
});
