import { Locator } from '@playwright/test';

// The search inputs carry `data-field` in rflibLogEventList.html and the component
// reads it back through `dataset.field`, so it is a stable hook. The surrounding
// column classes are not - they swap on focus to expand the active field.
const SEARCH_FIELDS = ['createdBy', 'requestId', 'context', 'level', 'logMessage'] as const;

export type LogSearchField = (typeof SEARCH_FIELDS)[number];

/** Wraps `c-rflib-log-event-list`. */
export class LogEventListComponent {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): LogEventListComponent {
        return new LogEventListComponent(scope.locator('c-rflib-log-event-list'));
    }

    searchField(field: LogSearchField): Locator {
        return this.root.locator(`lightning-input[data-field="${field}"] input`);
    }

    get searchButton(): Locator {
        return this.root.getByRole('button', { name: 'Search' });
    }

    // Sets one search field and runs the search. Pass an empty value to clear it.
    async search(field: LogSearchField, value: string): Promise<void> {
        await this.searchField(field).fill(value);
        await this.searchButton.click();
    }

    get rows(): Locator {
        return this.root.locator('c-rflib-log-event-list-row');
    }

    // Footer reading "<count> Page <n> of <total>".
    get pageInfo(): Locator {
        return this.root.locator('p').filter({ hasText: 'Page' });
    }
}
