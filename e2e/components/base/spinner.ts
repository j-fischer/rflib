import { expect, Locator, Page } from '@playwright/test';

/** Waits until no `lightning-spinner` is rendered within the scope. */
export async function waitForSpinners(scope: Page | Locator, timeout = 60_000): Promise<void> {
    await expect(scope.locator('lightning-spinner')).toHaveCount(0, { timeout });
}
