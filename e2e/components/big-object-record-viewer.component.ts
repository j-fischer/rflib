import { Locator } from '@playwright/test';

/**
 * Wraps `c-rflib-big-object-record-viewer`. Every detail field renders inside a block carrying the field's
 * API name in `data-field` (rflibBigObjectRecordViewer.html), so a field is addressed by API name rather than
 * by its position, which depends on the placement's detailFields.
 */
export class BigObjectRecordViewerComponent {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): BigObjectRecordViewerComponent {
        return new BigObjectRecordViewerComponent(scope.locator('c-rflib-big-object-record-viewer'));
    }

    field(fieldName: string): Locator {
        return this.root.locator(`div[data-field="${fieldName}"]`);
    }

    // The monospace block a long text field renders, pretty-printed when the value is JSON.
    longText(fieldName: string): Locator {
        return this.field(fieldName).locator('pre.long-text');
    }

    // The name resolved for a field holding a user id.
    userName(fieldName: string): Locator {
        return this.field(fieldName).locator('.user-name');
    }

    get closeButton(): Locator {
        return this.root.locator('lightning-button-icon[data-id="close-viewer"] button');
    }
}
