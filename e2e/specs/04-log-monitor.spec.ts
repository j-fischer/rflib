import { BrowserContext, expect, Page, test } from '@playwright/test';
import { createOpsCenterSession } from '../fixtures';
import { runApex } from '../helpers/sf';
import { CONNECTION_MODES, LogMonitorPage } from '../pages/log-monitor.page';
import { TABS } from '../pages/ops-center-app.page';

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

test('starts in "New Messages" connection mode', async () => {
    await expect(monitor.root).toBeVisible({ timeout: 60_000 });
    await expect(monitor.connectionStatusText).toContainText(CONNECTION_MODES.newMessagesOnly);
    await expect(monitor.totalLogEventsText).toBeVisible();
});

test('historic mode replays the seeded log events', async () => {
    // Big Object archival / event-bus replay can lag several minutes in a fresh scratch org, and a
    // historic subscription only queries when it connects — a stale one will not pick up events that
    // surface afterwards. So poll for a while, and if nothing has replayed yet reload for a fresh
    // subscription and try again, over several rounds, before failing.
    const MAX_ATTEMPTS = 5;
    for (let attempt = 1; ; attempt++) {
        await monitor.setConnectionMode(CONNECTION_MODES.historicAndNew);
        try {
            await expect
                .poll(() => monitor.getTotalLogEvents(), { timeout: 60_000, intervals: [5_000] })
                .toBeGreaterThan(0);
            break;
        } catch (error) {
            if (attempt >= MAX_ATTEMPTS) {
                throw error;
            }
            await page.reload({ waitUntil: 'domcontentloaded' });
            await expect(monitor.root).toBeVisible({ timeout: 60_000 });
        }
    }
    await expect(monitor.eventRows().first()).toBeVisible({ timeout: 30_000 });
});

test('receives new log events in real time over the EMP API', async () => {
    // Reload for a fresh default "New Messages" subscription instead of
    // toggling modes, which occasionally stalls the EMP resubscribe.
    await page.reload({ waitUntil: 'domcontentloaded' });
    await expect(monitor.connectionStatusText).toContainText(CONNECTION_MODES.newMessagesOnly, { timeout: 60_000 });
    const baseline = await monitor.getTotalLogEvents();

    runApex('scripts/apex/CreateLogEvent.apex');

    await expect
        .poll(() => monitor.getTotalLogEvents(), { timeout: 120_000, intervals: [5_000] })
        .toBeGreaterThan(baseline);
    await expect(monitor.eventRows().filter({ hasText: 'TestContext' }).first()).toBeVisible();
});

test('filters log events by level and context', async () => {
    // Reconnect in historic mode so there is a stable set of rows to filter.
    await monitor.setConnectionMode(CONNECTION_MODES.historicAndNew);
    await expect.poll(() => monitor.getTotalLogEvents(), { timeout: 120_000, intervals: [5_000] }).toBeGreaterThan(0);

    await monitor.searchField('Level...').fill('FATAL');
    await monitor.searchButton.click();
    await expect(monitor.eventRows().first()).toBeVisible({ timeout: 30_000 });
    await expect(monitor.eventRows().filter({ hasText: 'DEBUG' })).toHaveCount(0);

    await monitor.searchField('Level...').fill('');
    await monitor.searchField('Context...').fill('TestContext');
    await monitor.searchButton.click();
    await expect(monitor.eventRows().first()).toBeVisible({ timeout: 30_000 });
    await expect(monitor.eventRows().filter({ hasText: 'TestContext' }).first()).toBeVisible();

    await monitor.searchField('Context...').fill('');
    await monitor.searchButton.click();
});

test('paginates when more than one page of events exists', async () => {
    // Two CreateLogEvent runs (global setup + real-time test) provide >10 events
    // in replay; top up once more if the org delivered fewer.
    let total = await monitor.getTotalLogEvents();
    if (total <= 10) {
        runApex('scripts/apex/CreateLogEvent.apex');
        await expect
            .poll(() => monitor.getTotalLogEvents(), { timeout: 120_000, intervals: [5_000] })
            .toBeGreaterThan(10);
        total = await monitor.getTotalLogEvents();
    }
    expect(total).toBeGreaterThan(10);

    const footer = monitor.eventList.locator('p').filter({ hasText: 'Page' });
    await expect(footer).toContainText('Page 1');
    await monitor.root.locator('c-rflib-paginator').getByRole('button', { name: 'Next' }).click();
    await expect(footer).toContainText('Page 2');
    await monitor.root.locator('c-rflib-paginator').getByRole('button', { name: 'First' }).click();
    await expect(footer).toContainText('Page 1');
});

test('selecting an event opens the viewer with details, platform info, and stacktrace', async () => {
    await expect(monitor.viewer).toBeHidden();
    await monitor.eventRows().first().click();
    await expect(monitor.viewer).toBeVisible({ timeout: 30_000 });

    await expect(monitor.viewer.getByText('Log Messages')).toBeVisible();
    await monitor.viewer.getByRole('tab', { name: 'Platform Info' }).click();
    await expect(monitor.viewer.locator('table').first()).toBeVisible();
    await monitor.viewer.getByRole('tab', { name: 'Stacktrace' }).click();
    await expect(monitor.viewer.locator('pre').first()).toBeVisible();
    await monitor.viewer.getByRole('tab', { name: 'Log Event' }).click();

    // Download menu offers the RFLIB log file entry.
    await monitor.viewer.locator('lightning-button-menu button').first().click();
    await expect(page.getByRole('menuitem', { name: 'RFLIB Log File' })).toBeVisible();
    await page.keyboard.press('Escape');
});

test('field visibility settings toggle', async () => {
    const menu = monitor.fieldVisibilityMenu;
    await menu.click();
    const requestIdItem = page
        .getByRole('menuitemcheckbox', { name: 'Show Request ID' })
        .or(page.getByRole('menuitem', { name: 'Show Request ID' }))
        .first();
    await expect(requestIdItem).toBeVisible();
    await requestIdItem.click();

    // Re-open and toggle back.
    await menu.click();
    await page
        .getByRole('menuitemcheckbox', { name: 'Show Request ID' })
        .or(page.getByRole('menuitem', { name: 'Show Request ID' }))
        .first()
        .click();
});

test('fullscreen toggle hides and restores the event list', async () => {
    // The toggle is only enabled when an event is selected (done in prior test).
    await expect(monitor.eventList).toBeVisible();
    await monitor.fullscreenToggle.click();
    await expect(monitor.eventList).toBeHidden();
    await monitor.fullscreenToggle.click();
    await expect(monitor.eventList).toBeVisible();
});

test('exports captured events to CSV', async () => {
    const downloadPromise = page.waitForEvent('download', { timeout: 60_000 });
    await monitor.exportButton.click();
    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/\.csv$/i);
});

test('clear logs empties the captured event list', async () => {
    await monitor.clearLogsButton.click();
    await expect(monitor.totalLogEventsText).toContainText('0 Total Log Events', { timeout: 30_000 });
    await expect(monitor.eventRows()).toHaveCount(0);
});
