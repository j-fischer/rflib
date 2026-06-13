import { BrowserContext, expect, Page, test } from '@playwright/test';
import { createOpsCenterSession } from '../fixtures';
import { clickDialogButton, clickRowAction, pickRecord, waitForToastsToClear } from '../helpers/lightning';
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
    const leftoverRow = settings.row(adminName);
    if (await leftoverRow.isVisible()) {
        await clickRowAction(leftoverRow, 'Delete');
        await clickDialogButton(page, 'Delete');
        await expect(settings.row(adminName)).toBeHidden({ timeout: 60_000 });
        await waitForToastsToClear(page);
    }

    await settings.newButton.click();
    await expect(settings.modal).toBeVisible();

    const typeSelector = settings.modal.locator('lightning-combobox');
    await typeSelector.locator('button, input').first().click();
    await typeSelector.getByRole('option', { name: 'User', exact: true }).click();

    await pickRecord(settings.modal.locator('lightning-record-picker'), adminName);

    await settings.modalField('General_Log_Level__c').fill('DEBUG');
    await settings.modalField('Client_Console_Log_Level__c').fill('TRACE');

    await settings.modal.getByRole('button', { name: 'Save' }).click();
    const newRow = settings.row(adminName);
    await expect(newRow).toBeVisible({ timeout: 60_000 });
    await expect(newRow).toContainText('DEBUG');
    await waitForToastsToClear(page);
});

test('edits the user-level setting through the row action', async () => {
    const row = settings.row(orgInfo().adminName);
    await clickRowAction(row, 'Edit');
    await expect(settings.modal).toBeVisible();

    await settings.modalField('General_Log_Level__c').fill('WARN');
    await settings.modal.getByRole('button', { name: 'Save' }).click();

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
    await clickRowAction(settings.row(adminName), 'Delete');
    await clickDialogButton(page, 'Delete');
    await expect(settings.row(adminName)).toBeHidden({ timeout: 60_000 });
    // The org default row must never be deleted by the test.
    await expect(settings.row('Organization')).toBeVisible();
});
