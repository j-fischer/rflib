import { BrowserContext, expect, Page, test } from '@playwright/test';
import { ConfirmationDialogComponent } from '../components';
import { waitForToastsToClear } from '../components/base';
import { createOpsCenterSession } from '../fixtures';
import { orgInfo } from '../helpers/sf';
import { LoggerSettingsPage } from '../pages/logger-settings.page';
import { TABS } from '../pages/ops-center-app.page';

test.describe.configure({ mode: 'serial' });

let context: BrowserContext;
let page: Page;
let settings: LoggerSettingsPage;

test.beforeAll(async ({ browser }) => {
    ({ context, page } = await createOpsCenterSession(browser, TABS.loggerSettings));
    settings = new LoggerSettingsPage(page);
});

test.afterAll(async () => {
    await context?.close();
});

async function deleteSetting(rowText: string): Promise<void> {
    await settings.table.rowAction(rowText, 'Delete');
    await ConfirmationDialogComponent.visibleIn(page).confirm();
}

test('shows the org default settings configured by the setup script', async () => {
    const orgRow = settings.row('Organization');
    await expect(orgRow).toBeVisible({ timeout: 60_000 });
    // ConfigureCustomSettings.apex sets Log_Event_Reporting_Level__c and
    // Archive_Log_Level__c to INFO on the org defaults.
    await expect(orgRow).toContainText('INFO');
});

test('creates a new user-level logger setting', async () => {
    const adminName = orgInfo().adminName;

    // Re-runnability: delete a leftover row from a previous run.
    if (await settings.row(adminName).isVisible()) {
        await deleteSetting(adminName);
        await expect(settings.row(adminName)).toBeHidden({ timeout: 60_000 });
        await waitForToastsToClear(page);
    }

    await settings.newButton.click();
    const modal = settings.modal;
    await expect(modal.root).toBeVisible();

    await modal.typeSelector.select('User', true);
    await modal.ownerPicker.pick(adminName);

    await modal.field('General_Log_Level__c').fill('DEBUG');
    await modal.field('Client_Console_Log_Level__c').fill('TRACE');

    await modal.saveButton.click();
    const newRow = settings.row(adminName);
    await expect(newRow).toBeVisible({ timeout: 60_000 });
    await expect(newRow).toContainText('DEBUG');
    await waitForToastsToClear(page);
});

test('edits the user-level setting through the row action', async () => {
    await settings.table.rowAction(orgInfo().adminName, 'Edit');
    const modal = settings.modal;
    await expect(modal.root).toBeVisible();

    await modal.field('General_Log_Level__c').fill('WARN');
    await modal.saveButton.click();

    await expect(settings.row(orgInfo().adminName)).toContainText('WARN', { timeout: 60_000 });
    await waitForToastsToClear(page);
});

test('refresh reloads the settings table', async () => {
    await settings.refreshButton.click();
    await expect(settings.row('Organization')).toBeVisible({ timeout: 60_000 });
    await expect(settings.row(orgInfo().adminName)).toBeVisible({ timeout: 60_000 });
});

test('deletes the user-level setting with confirmation', async () => {
    const adminName = orgInfo().adminName;
    await deleteSetting(adminName);
    await expect(settings.row(adminName)).toBeHidden({ timeout: 60_000 });
    // The org default row must never be deleted by the test.
    await expect(settings.row('Organization')).toBeVisible();
});
