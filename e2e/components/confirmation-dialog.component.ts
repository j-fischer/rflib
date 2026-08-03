import { Locator, Page } from '@playwright/test';

/**
 * Wraps `c-rflib-confirmation-dialog`, the shared confirm modal used by the log
 * monitor, settings editor, job scheduler, and public group manager.
 *
 * The button labels are supplied by the host component and differ per call site
 * ("Delete", "Remove", "Clear"), so confirm is addressed by its SLDS variant
 * (`variant="brand"`) rather than by label.
 */
export class ConfirmationDialogComponent {
    constructor(readonly root: Locator) {}

    // Several dialogs can be mounted at once (one per host component); only the
    // triggered one renders a visible section.
    static visibleIn(page: Page): ConfirmationDialogComponent {
        return new ConfirmationDialogComponent(
            page.locator('c-rflib-confirmation-dialog section[role="dialog"]:visible').last()
        );
    }

    get message(): Locator {
        return this.root.locator('[data-id="message"]');
    }

    async confirm(): Promise<void> {
        await this.root.locator('footer button.slds-button_brand').click();
    }
}
