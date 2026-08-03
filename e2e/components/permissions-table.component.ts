import { Locator } from '@playwright/test';

// Each search input has a distinct placeholder in rflibPermissionsTable.html, so
// they need no positional disambiguation.
export const PERMISSIONS_SEARCH = {
    securityObject: 'Search profile/permission set name...',
    object: 'Search Object/Class/Page...',
    field: 'Search field...'
} as const;

export type PermissionsSearchPlaceholder = (typeof PERMISSIONS_SEARCH)[keyof typeof PERMISSIONS_SEARCH];

/**
 * Wraps `c-rflib-permissions-table`.
 *
 * The component renders plain `<table>` markup rather than a `lightning-datatable`,
 * so rows are addressed directly instead of through the base datatable wrapper.
 */
export class PermissionsTableComponent {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): PermissionsTableComponent {
        return new PermissionsTableComponent(scope.locator('c-rflib-permissions-table'));
    }

    get rows(): Locator {
        return this.root.locator('tbody tr');
    }

    searchInput(placeholder: PermissionsSearchPlaceholder): Locator {
        return this.root.getByPlaceholder(placeholder);
    }

    // Submits via Enter, which the component listens for on the surrounding column.
    async search(placeholder: PermissionsSearchPlaceholder, value: string): Promise<void> {
        const input = this.searchInput(placeholder);
        await input.fill(value);
        await input.press('Enter');
    }
}
