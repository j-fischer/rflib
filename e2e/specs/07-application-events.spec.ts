import { BrowserContext, expect, Page, test } from '@playwright/test';
import { createOpsCenterSession } from '../fixtures';
import { pollUntil } from '../helpers/polling';
import { runApex } from '../helpers/sf';
import { ApplicationEventsPage } from '../pages/application-events.page';
import { TABS } from '../pages/ops-center-app.page';

test.describe.configure({ mode: 'serial' });

let context: BrowserContext;
let page: Page;
let events: ApplicationEventsPage;

test.beforeAll(async ({ browser }) => {
    ({ context, page } = await createOpsCenterSession(browser, TABS.applicationEvents));
    events = new ApplicationEventsPage(page);
});

test.afterAll(async () => {
    await context?.close();
});

test('the All list view shows the seeded application events', async () => {
    await events.gotoAllListView();
    await expect(events.rows().first()).toBeVisible({ timeout: 60_000 });

    // The grid lazily renders only the first ~20 rows, so verify each seeded
    // event name through the list search box instead of scanning rows.
    for (const eventName of ['bot-request-success', 'import-sample-data']) {
        await events.searchList(eventName);
        await expect(events.rowWithText(eventName)).toBeVisible({ timeout: 30_000 });
    }
});

test('platform events create application event records asynchronously', async () => {
    test.setTimeout(480_000);
    runApex('scripts/apex/CreateApplicationEventOccurredEvent.apex');

    // The platform event flow runs asynchronously and queue processing in
    // scratch orgs can lag by several minutes. The list view only renders the
    // first ~20 rows, so filter via the list search box instead of scrolling.
    await pollUntil(
        async () => {
            await events.gotoAllListView();
            await events.searchList('Test Event');
            return events.rowWithText('Today Test Event').isVisible();
        },
        (visible) => visible,
        { timeoutMs: 420_000, intervalMs: 10_000, description: 'application event from platform event' }
    );
    await expect(events.rowWithText('Yesterday Test Event')).toBeVisible();
});

test('delete-all script empties the application events list', async () => {
    runApex('scripts/apex/DeleteAllApplicationEvents.apex');

    await pollUntil(
        async () => {
            await events.gotoAllListView();
            return events.rows().count();
        },
        (count) => count === 0,
        { timeoutMs: 120_000, intervalMs: 10_000, description: 'empty application events list' }
    );

    // Restore seed data so a re-run of the suite still finds records.
    runApex('scripts/apex/CreateApplicationEvent.apex');
});
