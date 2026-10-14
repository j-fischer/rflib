import { Locator } from '@playwright/test';

/**
 * Wraps `c-rflib-big-object-record-list`. Its columns come from the placement's displayFields, so the
 * filters are addressed by field API name: rflibBigObjectRecordList.html writes the field into `data-field`
 * and the filter part (`value`, `fromValue`, `toValue`) into `data-part`, and reads both back through
 * `dataset`, which makes them stable hooks.
 */
export class BigObjectRecordListComponent {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): BigObjectRecordListComponent {
        return new BigObjectRecordListComponent(scope.locator('c-rflib-big-object-record-list'));
    }

    // Text filter of a text column.
    columnFilter(fieldName: string): Locator {
        return this.root.locator(`lightning-input[data-field="${fieldName}"][data-part="value"] input`);
    }

    // The global search box, which scans every queried field, including detail-only ones.
    get globalSearch(): Locator {
        return this.root.locator('lightning-input[data-id="global-search"] input');
    }

    get searchButton(): Locator {
        return this.root.getByRole('button', { name: 'Search' });
    }

    async filterColumn(fieldName: string, value: string): Promise<void> {
        await this.columnFilter(fieldName).fill(value);
        await this.searchButton.click();
    }

    async searchAllFields(value: string): Promise<void> {
        await this.globalSearch.fill(value);
        await this.searchButton.click();
    }

    get rows(): Locator {
        return this.root.locator('c-rflib-big-object-record-list-row');
    }

    // Card title reading "<count> Displayed Records".
    get title(): Locator {
        return this.root.getByText(/Displayed Records/).first();
    }
}
