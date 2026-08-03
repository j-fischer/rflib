import { BrowserContext, expect, Page, test } from '@playwright/test';
import { PERMISSIONS_SEARCH } from '../components';
import { createOpsCenterSession } from '../fixtures';
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

test('exports all permissions to CSV', async () => {
    const downloadPromise = page.waitForEvent('download', { timeout: 120_000 });
    await explorer.exportMenu.select('All');
    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/\.csv$/i);
});

test('exports filtered permissions through the filter modal with help text', async () => {
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
    expect(download.suggestedFilename()).toMatch(/\.csv$/i);
    await expect(modal).toBeHidden({ timeout: 30_000 });
});
