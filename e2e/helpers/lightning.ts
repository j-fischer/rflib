import { expect, Locator, Page } from '@playwright/test';

export async function expectToast(page: Page, text?: string | RegExp): Promise<void> {
    const toast = page.locator('.slds-notify_container .slds-notify, lightning-toast, .slds-notify_toast').first();
    await expect(toast).toBeVisible({ timeout: 30_000 });
    if (text) {
        await expect(toast).toContainText(text);
    }
}

export async function waitForToastsToClear(page: Page): Promise<void> {
    await expect(page.locator('.slds-notify_container .slds-notify, lightning-toast')).toHaveCount(0, {
        timeout: 30_000
    });
}

// Clicks a button inside the visible modal/confirmation dialog.
export async function clickDialogButton(page: Page, buttonLabel: string): Promise<void> {
    const dialog = page.locator('section[role="dialog"]:visible').last();
    await dialog.getByRole('button', { name: buttonLabel, exact: true }).click();
}

// Selects an item from a lightning-button-menu by opening it and clicking the item label.
export async function selectMenuItem(menuButton: Locator, itemLabel: string): Promise<void> {
    const page = menuButton.page();
    await menuButton.click();
    const item = page
        .getByRole('menuitem', { name: itemLabel })
        .or(page.getByRole('menuitemcheckbox', { name: itemLabel }))
        .or(page.locator('lightning-menu-item').filter({ hasText: itemLabel }))
        .first();
    await item.click();
}

// Searches and selects a record in a lightning-record-picker.
export async function pickRecord(picker: Locator, searchText: string, optionText?: string): Promise<void> {
    const page = picker.page();
    const input = picker.locator('input').first();
    await input.click();
    await input.fill(searchText);
    const option = page
        .getByRole('option', { name: optionText ?? searchText })
        .or(picker.getByRole('option').filter({ hasText: optionText ?? searchText }))
        .first();
    await option.click({ timeout: 30_000 });
}

// Selects an option in a lightning-combobox by label.
export async function selectComboboxOption(combobox: Locator, optionText: string | RegExp): Promise<Locator> {
    await combobox.locator('button, input').first().click();
    const option = combobox.getByRole('option', { name: optionText }).first();
    await option.click();
    return option;
}

// Returns the datatable row (tr) containing the given text within a scope.
export function datatableRow(scope: Locator, text: string | RegExp): Locator {
    return scope.locator('lightning-datatable tbody tr').filter({ hasText: text }).first();
}

// Opens the row-level action menu of a lightning-datatable row and clicks an action.
export async function clickRowAction(row: Locator, actionLabel: string): Promise<void> {
    const page = row.page();
    const menuButton = row
        .getByRole('button', { name: /show actions/i })
        .or(row.locator('lightning-primitive-cell-actions button'))
        .first();
    await menuButton.click();
    await page.getByRole('menuitem', { name: actionLabel }).first().click();
}

// Fills a lightning-input of type "datetime" (renders separate date and time inputs).
export async function fillDateTime(dateTimeInput: Locator, dateStr: string, timeStr: string): Promise<void> {
    const dateInput = dateTimeInput.locator('input').first();
    await dateInput.click();
    await dateInput.fill(dateStr);
    await dateInput.press('Escape'); // close the calendar popup
    const timeInput = dateTimeInput.locator('input').nth(1);
    await timeInput.click();
    await timeInput.fill(timeStr);
    await timeInput.press('Escape');
    await timeInput.press('Tab'); // blur to fire the change event
}

export async function waitForSpinners(scope: Page | Locator, timeout = 60_000): Promise<void> {
    await expect(scope.locator('lightning-spinner')).toHaveCount(0, { timeout });
}

// Formats a Date as M/D/YYYY (en-US scratch org default locale).
export function formatDateUs(date: Date): string {
    return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
}
