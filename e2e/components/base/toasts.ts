import { expect, Page } from '@playwright/test';

// Toasts render through the platform's notification container, which varies by
// release between the SLDS markup and the lightning-toast component.
const TOAST_SELECTOR = '.slds-notify_container .slds-notify, lightning-toast, .slds-notify_toast';

export async function expectToast(page: Page, text?: string | RegExp): Promise<void> {
    const toast = page.locator(TOAST_SELECTOR).first();
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
