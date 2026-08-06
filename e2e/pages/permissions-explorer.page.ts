import { expect, Locator, Page } from '@playwright/test';
import { PaginatorComponent, PermissionsTableComponent } from '../components';
import { LightningButtonMenu, LightningRecordPicker, waitForSpinners } from '../components/base';

export const PERMISSION_TYPES = {
    objectProfiles: 'Object Permission For Profiles',
    objectPermissionSets: 'Object Permission for Permission Sets',
    fieldProfiles: 'Field Permissions for Profiles',
    apexPermissionSets: 'Apex Permissions for Permission Sets',
    objectUser: 'Object Permission for a User'
} as const;

// Labels of the export filter fields, taken from the form element labels in
// rflibPermissionsExplorer.html. The two name inputs share a placeholder, so the
// label is the only thing that tells them apart.
export const EXPORT_FILTERS = {
    securityObject: 'Profile/Permission Set Name',
    object: 'Object/Class/Page Name',
    field: 'Field Name'
} as const;

export type ExportFilterLabel = (typeof EXPORT_FILTERS)[keyof typeof EXPORT_FILTERS];

const PERMISSION_TYPE_LABELS = new RegExp(Object.values(PERMISSION_TYPES).join('|'));

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

    // The three header menus are distinguished by what they announce, not by order:
    // the permission type menu is labelled with the selected type, the export menu
    // with "Export to CSV", and the icon-only page size menu by its alternative-text.
    get permissionTypeMenu(): LightningButtonMenu {
        return new LightningButtonMenu(
            this.header.locator('lightning-button-menu').filter({ hasText: PERMISSION_TYPE_LABELS }).first()
        );
    }

    get exportMenu(): LightningButtonMenu {
        return new LightningButtonMenu(this.header.getByRole('button', { name: 'Export to CSV' }));
    }

    // The page size menu is icon-only, so alternative-text is its only label. Falls
    // back to its position in the header button group (type, export, page size) if a
    // release stops rendering the assistive text.
    get pageSizeMenu(): LightningButtonMenu {
        return new LightningButtonMenu(
            this.header
                .getByRole('button', { name: 'Select page size' })
                .or(this.header.locator('lightning-button-menu').nth(2))
                .first()
        );
    }

    async selectPermissionType(label: string): Promise<void> {
        await this.permissionTypeMenu.select(label);
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

    get table(): PermissionsTableComponent {
        return PermissionsTableComponent.within(this.root);
    }

    get tableRows(): Locator {
        return this.table.rows;
    }

    get userPicker(): LightningRecordPicker {
        return LightningRecordPicker.within(this.root);
    }

    get aggregateButton(): Locator {
        return this.root.getByRole('button', { name: 'Aggregate Permissions' });
    }

    get resetButton(): Locator {
        return this.root.getByRole('button', { name: 'Reset Permissions' });
    }

    get paginator(): PaginatorComponent {
        return PaginatorComponent.within(this.root);
    }

    // Only rendered for the field permission types (rflibPermissionsExplorer.html).
    get nonPermissionableToggle(): Locator {
        return this.root.locator('lightning-input[data-id="include-non-permissionable-fields"]');
    }

    // `lightning-input type="toggle"` renders a transparent checkbox behind a faux span, so the
    // click has to land on the span while the state is read from the underlying input.
    get nonPermissionableCheckbox(): Locator {
        return this.nonPermissionableToggle.locator('input[type="checkbox"]');
    }

    async setNonPermissionableFields(enabled: boolean): Promise<void> {
        if ((await this.nonPermissionableCheckbox.isChecked()) === enabled) {
            return;
        }

        await this.nonPermissionableToggle.locator('.slds-checkbox_faux').click();
        await expect(this.nonPermissionableCheckbox).toBeChecked({ checked: enabled });
        await this.waitForLoad();
    }

    get exportFilterModal(): Locator {
        return this.root.locator('section[role="dialog"]').filter({ hasText: 'Export Filters' });
    }

    // Each filter input sits in its own .slds-form-element next to its label.
    exportFilterInput(label: ExportFilterLabel): Locator {
        return this.exportFilterModal
            .locator('.slds-form-element')
            .filter({ hasText: label })
            .locator('lightning-input input');
    }

    get exportFilterHelpToggle(): Locator {
        return this.exportFilterModal.getByText('Click to learn how filtering works');
    }

    get exportFilterExportButton(): Locator {
        return this.exportFilterModal.getByRole('button', { name: 'Export', exact: true });
    }
}
