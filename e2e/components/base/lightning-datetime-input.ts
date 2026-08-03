import { Locator } from '@playwright/test';

/**
 * Wraps a `lightning-input` of `type="datetime"`, which renders a separate date
 * input and time input behind a single custom element.
 */
export class LightningDateTimeInput {
    constructor(readonly root: Locator) {}

    async fill(dateStr: string, timeStr: string): Promise<void> {
        const dateInput = this.root.locator('input').first();
        await dateInput.click();
        await dateInput.fill(dateStr);
        await dateInput.press('Escape'); // close the calendar popup

        // Exactly two inputs are rendered, date then time, so position is the hook.
        const timeInput = this.root.locator('input').nth(1);
        await timeInput.click();
        await timeInput.fill(timeStr);
        await timeInput.press('Escape');
        await timeInput.press('Tab'); // blur to fire the change event
    }
}

/** Formats a Date as M/D/YYYY (en-US scratch org default locale). */
export function formatDateUs(date: Date): string {
    return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;
}
