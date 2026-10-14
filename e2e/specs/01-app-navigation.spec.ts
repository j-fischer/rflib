import { BrowserContext, expect, Page, test } from '@playwright/test';
import { createOpsCenterSession } from '../fixtures';
import { ApplicationEventsPage } from '../pages/application-events.page';
import { OpsCenterApp, ROOT_COMPONENT_TAGS, TABS } from '../pages/ops-center-app.page';

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

test('shows all seven Ops Center tabs', async () => {
    for (const label of Object.values(TABS)) {
        await expect(app.tabLink(label)).toBeVisible();
    }
});

test('Management Console tab renders the dashboard components', async () => {
    await app.gotoTab(TABS.managementConsole);
    await expect(app.rootComponent(ROOT_COMPONENT_TAGS.orgLimitStat).first()).toBeVisible({ timeout: 60_000 });
    await expect(app.rootComponent(ROOT_COMPONENT_TAGS.bigObjectStat)).toBeVisible();
});

test('Logger Settings tab renders the custom settings editor', async () => {
    await app.gotoTab(TABS.loggerSettings);
    await expect(app.rootComponent(ROOT_COMPONENT_TAGS.customSettingsEditor)).toBeVisible({ timeout: 60_000 });
});

test('Log Monitor tab renders the log event monitor', async () => {
    await app.gotoTab(TABS.logMonitor);
    await expect(app.rootComponent(ROOT_COMPONENT_TAGS.logEventMonitor)).toBeVisible({ timeout: 60_000 });
    await expect(page.getByText('Total Log Events')).toBeVisible();
});

test('Permissions Explorer tab renders the permissions explorer', async () => {
    await app.gotoTab(TABS.permissionsExplorer);
    await expect(app.rootComponent(ROOT_COMPONENT_TAGS.permissionsExplorer)).toBeVisible({ timeout: 60_000 });
});

test('Application Events Dashboard tab activates', async () => {
    await app.gotoTab(TABS.appEventsDashboard);
    await page.waitForURL(/rflib_Application_Events_Dashboard/, { timeout: 60_000 });
    await app.expectAppHeader();
});

test('Application Events tab shows the object list view', async () => {
    await app.gotoTab(TABS.applicationEvents);
    await page.waitForURL(/rflib_Application_Event__c/, { timeout: 60_000 });
    await expect(new ApplicationEventsPage(page).listViewContainer).toBeVisible({ timeout: 60_000 });
});

test('Application Event Archive tab renders the big object explorer', async () => {
    // Clicked straight after the Application Events list view, the tab can light up while Lightning drops the
    // navigation, leaving the list view on screen. Re-click until the URL actually moves.
    await expect(async () => {
        await app.gotoTab(TABS.appEventArchive);
        await expect(page).toHaveURL(/rflib_Application_Event_Archive_Explorer/, { timeout: 10_000 });
    }).toPass({ timeout: 60_000 });
    await expect(app.rootComponent(ROOT_COMPONENT_TAGS.bigObjectExplorer)).toBeVisible({ timeout: 60_000 });
    await expect(page.getByText('Records Loaded')).toBeVisible({ timeout: 60_000 });
});
