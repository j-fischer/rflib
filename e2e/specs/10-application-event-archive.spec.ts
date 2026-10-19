import { BrowserContext, expect, Page, test } from '@playwright/test';
import { createOpsCenterSession } from '../fixtures';
import { orgInfo } from '../helpers/sf';
import { ApplicationEventArchivePage, ARCHIVE_FIELDS } from '../pages/application-event-archive.page';
import { TABS } from '../pages/ops-center-app.page';

// Global setup seeds rflib_Application_Event_Archive__b with three recent 'E2E_ARCHIVE_*' events through
// scripts/apex/SeedApplicationEventArchive.apex. Every suite run seeds three more, so assertions look for the
// seeded events rather than an exact row count.
const SEEDED_EVENT_PREFIX = 'E2E_ARCHIVE_';

test.describe.configure({ mode: 'serial' });

let context: BrowserContext;
let page: Page;
let archive: ApplicationEventArchivePage;

test.beforeAll(async ({ browser }) => {
    ({ context, page } = await createOpsCenterSession(browser, TABS.appEventArchive));
    archive = new ApplicationEventArchivePage(page);
});

test.afterAll(async () => {
    await context?.close();
});

test('loads the archived events of the last seven days', async () => {
    const { explorer } = archive;
    await expect(explorer.title).toHaveText('Application Event Archive', { timeout: 60_000 });
    await expect(explorer.loadingOverlay).toBeHidden({ timeout: 60_000 });

    await expect(explorer.list.rows.filter({ hasText: SEEDED_EVENT_PREFIX }).first()).toBeVisible();
    await expect
        .poll(() => explorer.list.rows.filter({ hasText: SEEDED_EVENT_PREFIX }).count())
        .toBeGreaterThanOrEqual(3);
    await expect(explorer.recordCountText).toContainText('Records Loaded');
});

test('filters on a field the Big Object index cannot reach', async () => {
    const { list } = archive.explorer;

    // Related_Record_ID__c is the third index field, unreachable by a server-side range query on the archive.
    await list.filterColumn(ARCHIVE_FIELDS.relatedRecord, 'E2E-REL-1');

    await expect(list.rows.filter({ hasText: 'E2E_ARCHIVE_REJECTED' }).first()).toBeVisible();
    await expect(list.rows.filter({ hasText: 'E2E-REL-0' })).toHaveCount(0);
    await expect(list.rows.filter({ hasText: 'E2E-REL-2' })).toHaveCount(0);

    await list.filterColumn(ARCHIVE_FIELDS.relatedRecord, '');
});

test('searches the text inside the JSON payload of the detail-only field', async () => {
    const { list } = archive.explorer;

    // Additional_Details__c is not a column, so only the global search reaches it.
    await list.searchAllFields('e2e-payload-retried');

    await expect(list.rows.filter({ hasText: 'E2E_ARCHIVE_RETRIED' }).first()).toBeVisible();
    await expect(list.rows.filter({ hasText: 'E2E_ARCHIVE_ACCEPTED' })).toHaveCount(0);
});

test('shows every field of the selected event in the detail pane', async () => {
    const { explorer } = archive;
    await expect(explorer.noRecordSelected).toBeVisible();

    await explorer.list.rows.filter({ hasText: 'E2E_ARCHIVE_RETRIED' }).first().click();

    const viewer = explorer.viewer;
    await expect(viewer.root).toBeVisible({ timeout: 30_000 });
    await expect(viewer.field(ARCHIVE_FIELDS.eventName)).toContainText('E2E_ARCHIVE_RETRIED');
    await expect(viewer.field(ARCHIVE_FIELDS.relatedRecord)).toContainText('E2E-REL-2');

    // The JSON payload is pretty-printed, and the creator's user id resolves to a name.
    await expect(viewer.longText(ARCHIVE_FIELDS.details)).toContainText('"outcome": "retried"');
    await expect(viewer.userName(ARCHIVE_FIELDS.createdBy)).toHaveText(orgInfo().adminName, { timeout: 30_000 });

    await viewer.closeButton.click();
    await expect(explorer.noRecordSelected).toBeVisible();

    await explorer.list.searchAllFields('');
});

test('queries the archive again for a different index range', async () => {
    const { explorer } = archive;

    // A window long before the seeded events: the server-side range query returns none of them.
    await explorer.queryDateRange(ARCHIVE_FIELDS.occurredOn, new Date(2019, 0, 1), new Date(2019, 0, 2));
    await expect(explorer.recordCountText).toContainText('0 Records Loaded');
    await expect(explorer.list.rows).toHaveCount(0);

    // Widening the window to include today brings the seeded events back.
    const oneDay = 24 * 60 * 60 * 1000;
    await explorer.queryDateRange(
        ARCHIVE_FIELDS.occurredOn,
        new Date(Date.now() - oneDay),
        new Date(Date.now() + oneDay)
    );
    await expect(explorer.list.rows.filter({ hasText: SEEDED_EVENT_PREFIX }).first()).toBeVisible();
});
