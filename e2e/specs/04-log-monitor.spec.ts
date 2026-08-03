import { BrowserContext, expect, Page, test } from '@playwright/test';
import { VIEWER_TABS } from '../components';
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
    // The default subscription connects on load; EMP can stall on first subscribe in a fresh scratch
    // org, so tolerate that by reloading until the default "New Messages" connection is reported.
    await monitor.waitForConnectionMode(CONNECTION_MODES.newMessagesOnly);
    await expect(monitor.totalLogEventsText).toBeVisible();
});

test('historic mode connects and streams log events', async () => {
    // "Historic and New Messages" both replays retained events and streams new ones. Durable EMP
    // replay (-2) is unreliable in a scratch org, so the assertion is guaranteed via freshly
    // published events arriving over the "New" half rather than by replay of the seeded events.
    await monitor.connectHistoricAndAwaitEvents();
    await expect(monitor.eventRows().first()).toBeVisible({ timeout: 30_000 });
});

test('receives new log events in real time over the EMP API', async () => {
    // Reload for a fresh default "New Messages" subscription instead of
    // toggling modes, which occasionally stalls the EMP resubscribe.
    await page.reload({ waitUntil: 'domcontentloaded' });
    await expect(monitor.connectionStatusText).toContainText(CONNECTION_MODES.newMessagesOnly, { timeout: 60_000 });
    // Let the CometD subscription finish its handshake before publishing. EMP only pushes events that
    // occur after the subscription is live, so an event published into that gap is silently missed.
    await page.waitForTimeout(3_000);
    const baseline = await monitor.getTotalLogEvents();

    runApex('scripts/apex/CreateLogEvent.apex');

    // Poll for the pushed event, and as a safety net against a single missed delivery (subscription
    // race), publish once more partway through before giving up.
    const deadline = Date.now() + 90_000;
    let republished = false;
    for (;;) {
        if ((await monitor.getTotalLogEvents()) > baseline) {
            break;
        }
        if (Date.now() > deadline) {
            throw new Error('No new log event was received over the EMP API within 90s.');
        }
        if (!republished && Date.now() > deadline - 60_000) {
            runApex('scripts/apex/CreateLogEvent.apex');
            republished = true;
        }
        await page.waitForTimeout(5_000);
    }

    await expect(monitor.eventRows().filter({ hasText: 'TestContext' }).first()).toBeVisible();
});

test('filters log events by level and context', async () => {
    // Reconnect in historic mode with a guaranteed set of rows to filter.
    await monitor.connectHistoricAndAwaitEvents();
    const eventList = monitor.eventList;

    await eventList.search('level', 'FATAL');
    await expect(monitor.eventRows().first()).toBeVisible({ timeout: 30_000 });
    await expect(monitor.eventRows().filter({ hasText: 'DEBUG' })).toHaveCount(0);

    await eventList.searchField('level').fill('');
    await eventList.search('context', 'TestContext');
    await expect(monitor.eventRows().first()).toBeVisible({ timeout: 30_000 });
    await expect(monitor.eventRows().filter({ hasText: 'TestContext' }).first()).toBeVisible();

    await eventList.search('context', '');
});

test('paginates when more than one page of events exists', async () => {
    // Prior tests stream several CreateLogEvent runs over the New channel, which usually leaves
    // >10 captured events; top up once more if the current subscription accumulated fewer.
    let total = await monitor.getTotalLogEvents();
    if (total <= 10) {
        runApex('scripts/apex/CreateLogEvent.apex');
        await expect
            .poll(() => monitor.getTotalLogEvents(), { timeout: 120_000, intervals: [5_000] })
            .toBeGreaterThan(10);
        total = await monitor.getTotalLogEvents();
    }
    expect(total).toBeGreaterThan(10);

    const pageInfo = monitor.eventList.pageInfo;
    await expect(pageInfo).toContainText('Page 1');
    await monitor.paginator.button('Next').click();
    await expect(pageInfo).toContainText('Page 2');
    await monitor.paginator.button('First').click();
    await expect(pageInfo).toContainText('Page 1');
});

test('selecting an event opens the viewer with details, platform info, and stacktrace', async () => {
    const viewer = monitor.viewer;
    await expect(viewer.root).toBeHidden();
    await monitor.eventRows().first().click();
    await expect(viewer.root).toBeVisible({ timeout: 30_000 });

    await expect(viewer.root.getByText('Log Messages')).toBeVisible();
    await viewer.openTab(VIEWER_TABS.platformInfo);
    await expect(viewer.platformInfoTable).toBeVisible();
    await viewer.openTab(VIEWER_TABS.stacktrace);
    await expect(viewer.stacktrace).toBeVisible();
    await viewer.openTab(VIEWER_TABS.logEvent);

    // Download menu offers the RFLIB log file entry.
    await viewer.downloadMenu.open();
    await expect(viewer.downloadMenu.item('RFLIB Log File')).toBeVisible();
    await viewer.downloadMenu.close();
});

test('field visibility settings toggle', async () => {
    const menu = monitor.fieldVisibilityMenu;
    await menu.open();
    const requestIdItem = menu.item('Show Request ID');
    await expect(requestIdItem).toBeVisible();
    await requestIdItem.click();

    // Re-open and toggle back.
    await menu.open();
    await menu.item('Show Request ID').click();
});

test('fullscreen toggle hides and restores the event list', async () => {
    // The toggle is only enabled when an event is selected (done in prior test).
    await expect(monitor.eventList.root).toBeVisible();
    await monitor.fullscreenToggle.click();
    await expect(monitor.eventList.root).toBeHidden();
    await monitor.fullscreenToggle.click();
    await expect(monitor.eventList.root).toBeVisible();
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
