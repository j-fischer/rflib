import { expect, Locator } from '@playwright/test';
import { formatDateIso, LightningDateTimeInput } from './base';
import { BigObjectRecordListComponent } from './big-object-record-list.component';
import { BigObjectRecordViewerComponent } from './big-object-record-viewer.component';

/**
 * Wraps `c-rflib-big-object-explorer`, the container that loads a Big Object in chunks and hosts the record
 * list and the detail pane. It knows nothing about which Big Object a placement is configured for; the index
 * filters are addressed by field API name through the `data-field` hook in rflibBigObjectExplorer.html.
 */
export class BigObjectExplorerComponent {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): BigObjectExplorerComponent {
        return new BigObjectExplorerComponent(scope.locator('c-rflib-big-object-explorer'));
    }

    get header(): Locator {
        return this.root.locator('.slds-page-header').first();
    }

    get title(): Locator {
        return this.header.locator('.title');
    }

    // Header meta reading "<count> Records Loaded".
    get recordCountText(): Locator {
        return this.header.locator('p').filter({ hasText: 'Records Loaded' });
    }

    // One index filter, rendered in index order in the header. `.index-filter` scopes the lookup away from the
    // record list, whose column filters carry the same data-field values.
    indexFilterRange(fieldName: string, part: 'fromValue' | 'toValue'): LightningDateTimeInput {
        return new LightningDateTimeInput(
            this.header.locator(`.index-filter lightning-input[data-field="${fieldName}"][data-part="${part}"]`)
        );
    }

    get queryButton(): Locator {
        return this.header.getByRole('button', { name: 'Query' });
    }

    // Sets a whole-day range on a datetime index filter, queries, and waits for the load to finish. The record
    // count reads 0 while a load runs, so nothing about the result is meaningful before the overlay hides.
    async queryDateRange(fieldName: string, start: Date, end: Date): Promise<void> {
        await this.indexFilterRange(fieldName, 'fromValue').fill(formatDateIso(start), '12:00 AM');
        await this.indexFilterRange(fieldName, 'toValue').fill(formatDateIso(end), '11:59 PM');
        await this.queryButton.click();
        await expect(this.loadingOverlay).toBeHidden({ timeout: 60_000 });
    }

    get loadingOverlay(): Locator {
        return this.root.locator('.loading-overlay');
    }

    get configProblems(): Locator {
        return this.root.locator('.config-problem');
    }

    get list(): BigObjectRecordListComponent {
        return BigObjectRecordListComponent.within(this.root);
    }

    get viewer(): BigObjectRecordViewerComponent {
        return BigObjectRecordViewerComponent.within(this.root);
    }

    get noRecordSelected(): Locator {
        return this.root.getByText('No Record Selected');
    }
}
