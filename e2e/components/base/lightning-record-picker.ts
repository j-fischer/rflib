import { Locator } from '@playwright/test';

/** Wraps a `lightning-record-picker` type-ahead. */
export class LightningRecordPicker {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): LightningRecordPicker {
        return new LightningRecordPicker(scope.locator('lightning-record-picker'));
    }

    get input(): Locator {
        return this.root.locator('input').first();
    }

    // Options render in an overlay that may escape the picker's subtree, so match
    // page-wide first and fall back to a picker-scoped lookup.
    async pick(searchText: string, optionText?: string): Promise<void> {
        const page = this.root.page();
        await this.input.click();
        await this.input.fill(searchText);
        const option = page
            .getByRole('option', { name: optionText ?? searchText })
            .or(this.root.getByRole('option').filter({ hasText: optionText ?? searchText }))
            .first();
        await option.click({ timeout: 30_000 });
    }
}
