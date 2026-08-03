import { Locator } from '@playwright/test';

/**
 * Wraps a `lightning-datatable`.
 *
 * Construct with `within(scope)` when the datatable is the only one inside a
 * component, which is the case for every RFLIB component that uses one.
 */
export class LightningDatatable {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): LightningDatatable {
        return new LightningDatatable(scope.locator('lightning-datatable'));
    }

    get rows(): Locator {
        return this.root.locator('tbody tr');
    }

    row(text: string | RegExp): Locator {
        return this.rows.filter({ hasText: text }).first();
    }

    rowCount(): Promise<number> {
        return this.rows.count();
    }

    // Opens a row's action menu and clicks the named action. The menu trigger is
    // labelled "Show actions" but falls back to the primitive cell markup, which is
    // what older API versions render.
    async rowAction(rowText: string | RegExp, actionLabel: string): Promise<void> {
        const row = this.row(rowText);
        const menuButton = row
            .getByRole('button', { name: /show actions/i })
            .or(row.locator('lightning-primitive-cell-actions button'))
            .first();
        await menuButton.click();
        await row.page().getByRole('menuitem', { name: actionLabel }).first().click();
    }
}
