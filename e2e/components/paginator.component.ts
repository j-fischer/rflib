import { Locator } from '@playwright/test';

/** Wraps `c-rflib-paginator`. */
export class PaginatorComponent {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): PaginatorComponent {
        return new PaginatorComponent(scope.locator('c-rflib-paginator'));
    }

    // The page selector only renders when the paginator is configured to show it.
    // LWC rewrites `id` attributes to keep them unique, so key off the authored
    // class instead of the `pageNum` id (rflibPaginator.html).
    get pageInput(): Locator {
        return this.root.locator('input.page-selector');
    }

    button(label: 'First' | 'Previous' | 'Next' | 'Last'): Locator {
        return this.root.getByRole('button', { name: label, exact: true });
    }

    async goTo(pageNumber: number): Promise<void> {
        await this.pageInput.fill(String(pageNumber));
        await this.pageInput.press('Enter');
    }

    async currentPage(): Promise<number> {
        return parseInt(await this.pageInput.inputValue(), 10);
    }
}
