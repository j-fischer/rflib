import { Locator, Page } from '@playwright/test';
import { SettingsModalComponent } from '../components';
import { LightningDatatable } from '../components/base';

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

    get table(): LightningDatatable {
        return LightningDatatable.within(this.root);
    }

    row(text: string | RegExp): Locator {
        return this.table.row(text);
    }

    get modal(): SettingsModalComponent {
        return SettingsModalComponent.within(this.root);
    }
}
