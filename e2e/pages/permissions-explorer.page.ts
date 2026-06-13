import { expect, Locator, Page } from '@playwright/test';
import { selectMenuItem, waitForSpinners } from '../helpers/lightning';

export const PERMISSION_TYPES = {
    objectProfiles: 'Object Permission For Profiles',
    objectPermissionSets: 'Object Permission for Permission Sets',
    fieldProfiles: 'Field Permissions for Profiles',
    apexPermissionSets: 'Apex Permissions for Permission Sets',
    objectUser: 'Object Permission for a User'
} as const;

export class PermissionsExplorerPage {
    constructor(readonly page: Page) {}

    get root(): Locator {
        return this.page.locator('c-rflib-permissions-explorer').first();
    }

    get header(): Locator {
        return this.root.locator('.slds-page-header').first();
    }

    get totalRecordsTitle(): Locator {
        return this.header.locator('h1').filter({ hasText: 'Total Permission Records' });
    }

    get permissionTypeText(): Locator {
        return this.header.locator('p').filter({ hasText: 'Permission Type' });
    }

    // Header button group renders three menus in fixed order: permission type,
    // export, page size.
    get permissionTypeMenu(): Locator {
        return this.header.locator('lightning-button-menu').nth(0);
    }

    get exportMenu(): Locator {
        return this.header.locator('lightning-button-menu').nth(1);
    }

    get pageSizeMenu(): Locator {
        return this.header.locator('lightning-button-menu').nth(2);
    }

    async selectPermissionType(label: string): Promise<void> {
        await selectMenuItem(this.permissionTypeMenu, label);
        await expect(this.permissionTypeText).toContainText(label, { timeout: 30_000 });
        await this.waitForLoad();
    }

    async waitForLoad(): Promise<void> {
        // Loading large orgs pages through records; allow generous time.
        await waitForSpinners(this.root, 180_000);
    }

    async getTotalRecords(): Promise<number> {
        const text = (await this.totalRecordsTitle.textContent()) ?? '0';
        return parseInt(text.trim().split(' ')[0], 10);
    }

    get table(): Locator {
        return this.root.locator('c-rflib-permissions-table');
    }

    get tableRows(): Locator {
        return this.table.locator('tbody tr');
    }

    get userPicker(): Locator {
        return this.root.locator('lightning-record-picker');
    }

    get aggregateButton(): Locator {
        return this.root.getByRole('button', { name: 'Aggregate Permissions' });
    }

    get resetButton(): Locator {
        return this.root.getByRole('button', { name: 'Reset Permissions' });
    }

    get exportFilterModal(): Locator {
        return this.root.locator('section[role="dialog"]').filter({ hasText: 'Export Filters' });
    }

    get paginator(): Locator {
        return this.root.locator('c-rflib-paginator');
    }
}
