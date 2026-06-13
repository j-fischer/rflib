import { Locator, Page } from '@playwright/test';

export class LoggerSettingsPage {
    constructor(readonly page: Page) {}

    get root(): Locator {
        return this.page.locator('c-rflib-custom-settings-editor').first();
    }

    get refreshButton(): Locator {
        return this.root.getByRole('button', { name: 'Refresh', exact: true });
    }

    get newButton(): Locator {
        return this.root.getByRole('button', { name: 'New', exact: true });
    }

    get datatable(): Locator {
        return this.root.locator('lightning-datatable');
    }

    row(text: string | RegExp): Locator {
        return this.datatable.locator('tbody tr').filter({ hasText: text }).first();
    }

    get modal(): Locator {
        return this.root.locator('section[role="dialog"]');
    }

    modalField(apiName: string): Locator {
        return this.modal.locator(`[data-field-name="${apiName}"]`);
    }
}
