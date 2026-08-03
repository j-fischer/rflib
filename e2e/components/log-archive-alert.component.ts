import { Locator, Page } from '@playwright/test';

/** Wraps `c-rflib-log-archive-alert`, the Management Console severity banner. */
export class LogArchiveAlertComponent {
    constructor(readonly root: Locator) {}

    static on(page: Page): LogArchiveAlertComponent {
        return new LogArchiveAlertComponent(page.locator('c-rflib-log-archive-alert'));
    }

    // The banner renders only when recent high-severity logs exist.
    get banner(): Locator {
        return this.root.locator('div[role="alert"]');
    }

    get investigateLink(): Locator {
        return this.banner.getByRole('link', { name: 'Investigate in the Log Monitor' });
    }
}
