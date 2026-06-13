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

test('the Application Events Dashboard tab activates without breaking the app', async () => {
    await app.gotoTab(TABS.appEventsDashboard);
    await page.waitForURL(/rflib_Application_Events_Dashboard/, { timeout: 60_000 });

    // The flexipage embeds an analytics dashboard with a hardcoded ID that does
    // not exist in a scratch org, so assert only that the page shell renders:
    // the tab heading and the embedded dashboard's iframe container.
    await expect(page.getByRole('heading', { name: 'Application Events Dashboard' })).toBeVisible({
        timeout: 90_000
    });
    await expect(page.locator('iframe').first()).toBeAttached({ timeout: 90_000 });
    await app.expectAppHeader();

    // Navigation away still works after visiting the dashboard tab.
    await app.gotoTab(TABS.managementConsole);
    await expect(page.locator('c-rflib-org-limit-stat').first()).toBeVisible({ timeout: 60_000 });
});
