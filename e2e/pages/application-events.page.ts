import { Locator, Page } from '@playwright/test';
import { orgInfo } from '../helpers/sf';

// Standard object list view for rflib_Application_Event__c.
export class ApplicationEventsPage {
    constructor(readonly page: Page) {}

    // Navigates straight to the "All" list view (the tab defaults to Recently
    // Viewed, which is empty in a fresh org).
    async gotoAllListView(): Promise<void> {
        await this.page.goto(`${orgInfo().instanceUrl}/lightning/o/rflib_Application_Event__c/list?filterName=All`, {
            waitUntil: 'domcontentloaded'
        });
        await this.listViewContainer.waitFor({ state: 'visible', timeout: 60_000 });
    }

    get listViewContainer(): Locator {
        return this.page
            .locator('one-record-home-flexipage2, .forceListViewManager, lst-list-view-manager-header')
            .first();
    }

    get rowCountText(): Locator {
        // "X items • Sorted by..." status text below the list view header
        return this.page.locator('.countSortedByFilteredBy, lst-list-view-manager-status-info').first();
    }

    rows(): Locator {
        return this.page.locator('table[role="grid"] tbody tr');
    }

    // Filters the list view through its search box; needed because the grid
    // lazily renders only the first ~20 rows.
    async searchList(text: string): Promise<void> {
        const search = this.page.getByPlaceholder('Search this list...').first();
        await search.fill(text);
        await search.press('Enter');
        await this.page.waitForTimeout(2_000);
    }

    rowWithText(text: string | RegExp): Locator {
        return this.rows().filter({ hasText: text }).first();
    }

    get refreshButton(): Locator {
        return this.page.getByRole('button', { name: 'Refresh', exact: true }).first();
    }
}
