import { BrowserContext, expect, Page, test } from '@playwright/test';
import { PERMISSIONS_SEARCH } from '../components';
import { createOpsCenterSession } from '../fixtures';
import { parseCsv, readCsvDownload, readDownload } from '../helpers/downloads';
import { orgInfo } from '../helpers/sf';
import { TABS } from '../pages/ops-center-app.page';
import { EXPORT_FILTERS, PERMISSION_TYPES, PermissionsExplorerPage } from '../pages/permissions-explorer.page';

test.describe.configure({ mode: 'serial' });

let context: BrowserContext;
let page: Page;
let explorer: PermissionsExplorerPage;

test.beforeAll(async ({ browser }) => {
    ({ context, page } = await createOpsCenterSession(browser, TABS.permissionsExplorer));
    explorer = new PermissionsExplorerPage(page);
});

test.afterAll(async () => {
    await context?.close();
});

test('loads object permissions for profiles by default', async () => {
    await expect(explorer.root).toBeVisible({ timeout: 60_000 });
    await expect(explorer.permissionTypeText).toContainText(PERMISSION_TYPES.objectProfiles);
    await explorer.waitForLoad();
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 120_000 }).toBeGreaterThan(0);
    await expect(explorer.tableRows.first()).toBeVisible();
});

test('switches between permission types', async () => {
    for (const type of [
        PERMISSION_TYPES.objectPermissionSets,
        PERMISSION_TYPES.fieldProfiles,
        PERMISSION_TYPES.apexPermissionSets
    ]) {
        await explorer.selectPermissionType(type);
        await expect.poll(() => explorer.getTotalRecords(), { timeout: 180_000 }).toBeGreaterThan(0);
        await expect(explorer.tableRows.first()).toBeVisible();
    }
});

test('user mode aggregates and resets permissions', async () => {
    await explorer.selectPermissionType(PERMISSION_TYPES.objectUser);
    await expect(explorer.userPicker.root).toBeVisible();

    await explorer.userPicker.pick(orgInfo().adminName);
    await expect(explorer.aggregateButton).toBeEnabled();
    await explorer.aggregateButton.click();
    await explorer.waitForLoad();
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 180_000 }).toBeGreaterThan(0);

    await explorer.resetButton.click();
    await explorer.waitForLoad();
    await expect(explorer.aggregateButton).toBeVisible({ timeout: 60_000 });
});

test('search filters the permissions table', async () => {
    await explorer.selectPermissionType(PERMISSION_TYPES.objectProfiles);
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 180_000 }).toBeGreaterThan(0);

    await explorer.table.search(PERMISSIONS_SEARCH.object, 'Account');
    await expect(explorer.tableRows.first()).toBeVisible({ timeout: 30_000 });
    await expect(explorer.tableRows.first()).toContainText('Account');

    await explorer.table.search(PERMISSIONS_SEARCH.object, '');
});

test('page size selection shows more rows per page', async () => {
    const rowsAtTen = await explorer.tableRows.count();
    expect(rowsAtTen).toBeLessThanOrEqual(10);

    await explorer.pageSizeMenu.select('50');
    await expect.poll(() => explorer.tableRows.count(), { timeout: 60_000 }).toBeGreaterThan(10);

    await explorer.pageSizeMenu.select('10');
    await expect.poll(() => explorer.tableRows.count(), { timeout: 60_000 }).toBeLessThanOrEqual(10);
});

test('paginator navigates pages including go-to-page', async () => {
    const paginator = explorer.paginator;
    await expect(paginator.pageInput).toHaveValue('1');

    await paginator.button('Next').click();
    await expect(paginator.pageInput).toHaveValue('2');

    await paginator.button('Last').click();
    expect(await paginator.currentPage()).toBeGreaterThan(1);

    await paginator.goTo(1);
    await expect(paginator.pageInput).toHaveValue('1');
});

// The export used to be asserted by file name alone, which is why it went unnoticed when the
// download stopped being produced at all. Every export test below reads the bytes back.

const OBJECT_CSV_HEADER = [
    'PROFILE/PERMISSION SET',
    'OBJECT',
    'READ ACCESS',
    'CREATE ACCESS',
    'EDIT ACCESS',
    'DELETE ACCESS',
    'VIEW ALL FIELDS',
    'VIEW ALL RECORDS',
    'MODIFY ALL RECORDS'
];

const FIELD_CSV_HEADER = ['PROFILE/PERMISSION SET', 'OBJECT', 'FIELD', 'READ ACCESS', 'EDIT ACCESS', 'FLS CONTROLLED'];

const APEX_CSV_HEADER = ['PROFILE/PERMISSION SET', 'CLASS/PAGE', 'CLASS/PAGE ACCESS'];

test('exports all object permissions to CSV', async () => {
    await explorer.selectPermissionType(PERMISSION_TYPES.objectProfiles);
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 180_000 }).toBeGreaterThan(0);
    const totalRecords = await explorer.getTotalRecords();

    const download = await explorer.exportAll();
    expect(download.suggestedFilename()).toMatch(/\.csv$/i);
    // toISOString() puts colons in the name, which Windows rejects and browsers silently rewrite.
    expect(download.suggestedFilename()).not.toContain(':');

    const { header, rows } = await readCsvDownload(download);
    expect(header).toEqual(OBJECT_CSV_HEADER);
    expect(rows).toHaveLength(totalRecords);
    rows.forEach((row) => expect(row).toHaveLength(OBJECT_CSV_HEADER.length));
});

test('exports filtered permissions through the filter modal with help text', async () => {
    const unfilteredCount = await explorer.getTotalRecords();

    await explorer.exportMenu.select('Filtered');
    const modal = explorer.exportFilterModal;
    await expect(modal).toBeVisible();

    // Collapsible help section explains the filter logic.
    await explorer.exportFilterHelpToggle.click();
    await expect(modal.getByText('Values within the same field are combined with OR logic')).toBeVisible();

    await explorer.exportFilterInput(EXPORT_FILTERS.object).fill('Account');
    const downloadPromise = page.waitForEvent('download', { timeout: 120_000 });
    await explorer.exportFilterExportButton.click();
    const download = await downloadPromise;
    await expect(modal).toBeHidden({ timeout: 30_000 });

    const { header, rows } = await readCsvDownload(download);
    expect(header).toEqual(OBJECT_CSV_HEADER);
    expect(rows.length).toBeGreaterThan(0);
    expect(rows.length).toBeLessThan(unfilteredCount);
    rows.forEach((row) => expect(row[1]).toContain('Account'));
});

test('exports field permissions with the FLS controlled column', async () => {
    await explorer.selectPermissionType(PERMISSION_TYPES.fieldProfiles);
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 180_000 }).toBeGreaterThan(0);
    const totalRecords = await explorer.getTotalRecords();

    const { header, rows } = await readCsvDownload(await explorer.exportAll());
    expect(header).toEqual(FIELD_CSV_HEADER);
    expect(rows).toHaveLength(totalRecords);
    // With fields without FLS hidden, every exported row is backed by a stored FieldPermissions record.
    rows.forEach((row) => expect(row[5]).toBe('true'));
});

// A SetupEntityAccess record has none of the object access fields. Exporting it in the object format
// produced a nine column file whose access columns all read "null".
test('exports Apex permissions in the class and page format', async () => {
    await explorer.selectPermissionType(PERMISSION_TYPES.apexPermissionSets);
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 180_000 }).toBeGreaterThan(0);
    const totalRecords = await explorer.getTotalRecords();

    const download = await explorer.exportAll();
    const text = await readDownload(download);
    expect(text).not.toContain('null');

    const { header, rows } = parseCsv(text);
    expect(header).toEqual(APEX_CSV_HEADER);
    expect(rows).toHaveLength(totalRecords);
    rows.forEach((row) => expect(row[2]).toBe('true'));
});

// Account.CreatedById is never subject to Field Level Security, so Salesforce cannot store a
// FieldPermissions record for it. That makes it a stable probe in any org: it can only reach the
// table through the Fields Without FLS menu, and being an audit field it is readable but not writable,
// which proves the Edit value comes from the field definition rather than being hardcoded.
test('shows fields without FLS for Account through the Fields Without FLS menu', async () => {
    await explorer.selectPermissionType(PERMISSION_TYPES.fieldProfiles);
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 180_000 }).toBeGreaterThan(0);

    const baseline = await explorer.getTotalRecords();

    // Offered only for the field permission types.
    await expect(explorer.fieldsWithoutFlsMenu.root).toBeVisible();

    await explorer.table.search(PERMISSIONS_SEARCH.object, 'Account');
    await explorer.table.search(PERMISSIONS_SEARCH.field, 'CreatedById');

    // Default on load is Hidden, so the field is absent until the mode is switched.
    await expect(explorer.tableRows).toHaveCount(0);

    await explorer.selectFieldsWithoutFls('Shown');
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 180_000 }).toBeGreaterThan(baseline);

    const createdByRow = explorer.tableRows.first();
    await expect(createdByRow).toBeVisible({ timeout: 30_000 });
    await expect(createdByRow).toContainText('CreatedById');
    await expect(createdByRow).toHaveClass(/not-fls-controlled/);

    // Readable because the object is readable, but an audit field is never writable.
    const cells = createdByRow.locator('td');
    await expect(cells.nth(3)).toHaveText('true');
    await expect(cells.nth(4)).toHaveText('false');

    // Hiding again has to restore the untouched result set, not a rebuilt approximation.
    await explorer.selectFieldsWithoutFls('Hidden');
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 60_000 }).toBe(baseline);
    await expect(explorer.tableRows).toHaveCount(0);

    await explorer.table.search(PERMISSIONS_SEARCH.field, '');
    await explorer.table.search(PERMISSIONS_SEARCH.object, '');
});

// Paging used to re-filter and clone every loaded record to render ten of them, which on a large
// result set cost seconds per click. Both the widest view and the one with the most rows are timed,
// since showing fields without FLS roughly doubles the record count.
test('pages through object field permissions well under a second per click', async () => {
    await explorer.selectPermissionType(PERMISSION_TYPES.fieldProfiles);
    await expect.poll(() => explorer.getTotalRecords(), { timeout: 180_000 }).toBeGreaterThan(0);

    const paginator = explorer.paginator;

    const timePageChange = async (action: () => Promise<void>, expectedPage: number) => {
        const start = Date.now();
        await action();
        // The value only settles once the rows for the new page have rendered.
        await expect(paginator.pageInput).toHaveValue(String(expectedPage), { timeout: 30_000 });
        await expect(explorer.tableRows.first()).toBeVisible();
        return Date.now() - start;
    };

    // Reached through the First button rather than goTo(): filling the number input does not
    // reliably replace its current value, which silently lands on a different page. The button is
    // disabled on page one, so clicking it unconditionally would hang instead of being a no-op.
    const goToFirstPage = async () => {
        if ((await paginator.currentPage()) !== 1) {
            await paginator.button('First').click();
        }
        await expect(paginator.pageInput).toHaveValue('1', { timeout: 30_000 });
    };

    await goToFirstPage();
    const lastPage = await paginator.totalPages();
    expect(lastPage).toBeGreaterThan(1);

    const toLast = await timePageChange(() => paginator.button('Last').click(), lastPage);
    expect(toLast).toBeLessThan(1000);

    const toFirst = await timePageChange(() => paginator.button('First').click(), 1);
    expect(toFirst).toBeLessThan(1000);

    const toNext = await timePageChange(() => paginator.button('Next').click(), 2);
    expect(toNext).toBeLessThan(1000);

    // Showing fields without FLS is the heavier case: more rows to page through.
    await explorer.selectFieldsWithoutFls('Shown');
    await goToFirstPage();

    const withFieldsWithoutFls = await timePageChange(() => paginator.button('Next').click(), 2);
    expect(withFieldsWithoutFls).toBeLessThan(1000);

    await explorer.selectFieldsWithoutFls('Hidden');
    await goToFirstPage();
});

// The table used to print its own "Page X of Y" line directly above the paginator's.
test('renders the page indicator only once', async () => {
    await expect(explorer.paginator.pageInput).toBeVisible();
    await expect(explorer.root.getByText(/^Page \d+ of \d+$/)).toHaveCount(0);
});
