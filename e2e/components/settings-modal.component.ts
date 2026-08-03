import { Locator } from '@playwright/test';
import { LightningCombobox, LightningRecordPicker } from './base';

/** Wraps the new/edit modal of `c-rflib-custom-settings-editor`. */
export class SettingsModalComponent {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): SettingsModalComponent {
        return new SettingsModalComponent(scope.locator('section[role="dialog"]'));
    }

    // Fields are generated from the custom setting's describe; each input carries
    // `data-field-name` with the field's API name (rflibCustomSettingsEditor.html).
    field(apiName: string): Locator {
        return this.root.locator(`[data-field-name="${apiName}"]`);
    }

    // Only rendered for a new setting: Organization / Profile / User.
    get typeSelector(): LightningCombobox {
        return LightningCombobox.within(this.root);
    }

    // Rendered once the type is Profile or User.
    get ownerPicker(): LightningRecordPicker {
        return LightningRecordPicker.within(this.root);
    }

    get saveButton(): Locator {
        return this.root.getByRole('button', { name: 'Save' });
    }
}
