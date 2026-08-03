import { Locator } from '@playwright/test';

/**
 * Wraps a `lightning-button-menu`.
 *
 * Menu items are rendered into an overlay outside the menu's own subtree, so item
 * lookup is page-scoped rather than scoped to the menu root.
 */
export class LightningButtonMenu {
    constructor(readonly root: Locator) {}

    async open(): Promise<void> {
        await this.root.click();
    }

    // The item role varies with the menu: plain menus render "menuitem", menus with
    // checked items render "menuitemcheckbox", and some variants expose neither.
    item(label: string): Locator {
        const page = this.root.page();
        return page
            .getByRole('menuitem', { name: label })
            .or(page.getByRole('menuitemcheckbox', { name: label }))
            .or(page.locator('lightning-menu-item').filter({ hasText: label }))
            .first();
    }

    async select(label: string): Promise<void> {
        await this.open();
        await this.item(label).click();
    }

    // Dismisses a menu that is left open, e.g. after asserting on its items.
    async close(): Promise<void> {
        await this.root.page().keyboard.press('Escape');
    }
}
