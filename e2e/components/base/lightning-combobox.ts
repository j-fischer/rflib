import { Locator } from '@playwright/test';

/** Wraps a `lightning-combobox`. */
export class LightningCombobox {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): LightningCombobox {
        return new LightningCombobox(scope.locator('lightning-combobox'));
    }

    // The trigger renders as a button in the readonly variant and as an input in the
    // filterable variant.
    get trigger(): Locator {
        return this.root.locator('button, input').first();
    }

    async select(optionText: string | RegExp, exact = false): Promise<void> {
        await this.trigger.click();
        await this.root.getByRole('option', { name: optionText, exact }).first().click();
    }
}
