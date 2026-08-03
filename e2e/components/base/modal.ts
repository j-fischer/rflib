import { Locator, Page } from '@playwright/test';

/**
 * The topmost visible SLDS modal. Modals stack (a confirmation can open on top of
 * an editor), so the last visible dialog is the one the user is acting on.
 */
function visibleDialog(page: Page): Locator {
    return page.locator('section[role="dialog"]:visible').last();
}

/**
 * Clicks a button in the topmost visible modal by its label.
 *
 * Prefer a component object where one exists - `ConfirmationDialog` keys off the
 * button variant instead of the label. This stays for the hand-rolled modals that
 * have no reusable component behind them.
 */
export async function clickDialogButton(page: Page, buttonLabel: string): Promise<void> {
    await visibleDialog(page).getByRole('button', { name: buttonLabel, exact: true }).click();
}
