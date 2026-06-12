import { BrowserContext, expect, Page, test } from '@playwright/test';
import { createOpsCenterSession } from '../fixtures';
import { OpsCenterApp, TABS } from '../pages/ops-center-app.page';

test.describe.configure({ mode: 'serial' });

let context: BrowserContext;
let page: Page;
let app: OpsCenterApp;

test.beforeAll(async ({ browser }) => {
    ({ context, page, app } = await createOpsCenterSession(browser));
});

test.afterAll(async () => {
    await context?.close();
});

test('opens RFLIB Ops Center through the App Launcher search', async () => {
    // The full App Launcher flow (waffle -> search -> select) ran in beforeAll;
    // verify it landed in the right app.
    await app.expectAppHeader();
    expect(page.url()).toContain('/lightning/');
});

test('shows all six Ops Center tabs', async () => {
    for (const label of Object.values(TABS)) {
        await expect(app.tabLink(label)).toBeVisible();
    }
});

test('Management Console tab renders the dashboard components', async () => {
    await app.gotoTab(TABS.managementConsole);
    await expect(page.locator('c-rflib-org-limit-stat').first()).toBeVisible({ timeout: 60_000 });
    await expect(page.locator('c-rflib-big-object-stat')).toBeVisible();
});

test('Logger Settings tab renders the custom settings editor', async () => {
    await app.gotoTab(TABS.loggerSettings);
    await expect(page.locator('c-rflib-custom-settings-editor')).toBeVisible({ timeout: 60_000 });
});

test('Log Monitor tab renders the log event monitor', async () => {
    await app.gotoTab(TABS.logMonitor);
    await expect(page.locator('c-rflib-log-event-monitor')).toBeVisible({ timeout: 60_000 });
    await expect(page.getByText('Total Log Events')).toBeVisible();
});

test('Permissions Explorer tab renders the permissions explorer', async () => {
    await app.gotoTab(TABS.permissionsExplorer);
    await expect(page.locator('c-rflib-permissions-explorer')).toBeVisible({ timeout: 60_000 });
});

test('Application Events Dashboard tab activates', async () => {
    await app.gotoTab(TABS.appEventsDashboard);
    await page.waitForURL(/rflib_Application_Events_Dashboard/, { timeout: 60_000 });
    await app.expectAppHeader();
});

test('Application Events tab shows the object list view', async () => {
    await app.gotoTab(TABS.applicationEvents);
    await page.waitForURL(/rflib_Application_Event__c/, { timeout: 60_000 });
    await expect(
        page.locator('.forceListViewManager, lst-list-view-manager-header, one-record-home-flexipage2').first()
    ).toBeVisible({ timeout: 60_000 });
});
