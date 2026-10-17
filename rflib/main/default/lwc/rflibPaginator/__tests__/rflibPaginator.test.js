import { createElement } from 'lwc';
import Paginator, { getValidPageSize, PAGE_SIZES } from 'c/rflibPaginator';

describe('c-rflib-paginator', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('displays previous and next buttons', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 10;
        element.pageSize = 5;
        document.body.appendChild(element);

        const buttons = element.shadowRoot.querySelectorAll('lightning-button');
        expect(buttons.length).toBe(4);
        expect(buttons[0].label).toBe('First');
        expect(buttons[1].label).toBe('Previous');
        expect(buttons[2].label).toBe('Next');
        expect(buttons[3].label).toBe('Last');
    });

    it('disables first and previous buttons on first page', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            expect(buttons[0].disabled).toBe(true);
            expect(buttons[1].disabled).toBe(true);
            expect(buttons[2].disabled).toBe(false);
            expect(buttons[3].disabled).toBe(false);
        });
    });

    it('disables next and last buttons on last page', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 4;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            expect(buttons[0].disabled).toBe(false);
            expect(buttons[1].disabled).toBe(false);
            expect(buttons[2].disabled).toBe(true);
            expect(buttons[3].disabled).toBe(true);
        });
    });

    it('disables all buttons when total records is 0', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 0;
        element.pageSize = 5;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            expect(buttons[0].disabled).toBe(true); // First page logic
            expect(buttons[1].disabled).toBe(true); // First page logic
            expect(buttons[2].disabled).toBe(true); // Last page logic (totalRecords === 0)
            expect(buttons[3].disabled).toBe(true); // Last page logic
        });
    });

    it('enables all buttons on middle page', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 2;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            expect(buttons[0].disabled).toBe(false);
            expect(buttons[1].disabled).toBe(false);
            expect(buttons[2].disabled).toBe(false);
            expect(buttons[3].disabled).toBe(false);
        });
    });

    it('fires event on previous button click', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 2;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('previous', handler);

        return Promise.resolve().then(() => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            buttons[1].click();
            expect(handler).toHaveBeenCalled();
        });
    });

    it('fires event on next button click', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('next', handler);

        return Promise.resolve().then(() => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            buttons[2].click();
            expect(handler).toHaveBeenCalled();
        });
    });

    it('fires event on first button click', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 2;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('first', handler);

        return Promise.resolve().then(() => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            buttons[0].click();
            expect(handler).toHaveBeenCalled();
        });
    });

    it('fires event on last button click', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('last', handler);

        return Promise.resolve().then(() => {
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            buttons[3].click();
            expect(handler).toHaveBeenCalled();
        });
    });

    it('always displays page selection input with the total number of pages', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('input');
            expect(input).not.toBeNull();
            expect(input.value).toBe('1');
            expect(element.shadowRoot.querySelector('#totalPages').textContent).toBe('4');
        });
    });

    it('fires gotopage event on enter key', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('gotopage', handler);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('input');
            input.value = '3';
            input.dispatchEvent(new KeyboardEvent('keypress', { keyCode: 13 }));

            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].detail).toBe(3);
        });
    });

    it('validates page number input min value', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 2; // Start at 2 so we can go to 1
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('gotopage', handler);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('input');
            input.value = '0'; // Too small
            input.dispatchEvent(new KeyboardEvent('keypress', { keyCode: 13 }));

            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].detail).toBe(1); // Should clip to 1
        });
    });

    it('validates page number input max value', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('gotopage', handler);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('input');
            input.value = '100'; // Too big (max is 4)
            input.dispatchEvent(new KeyboardEvent('keypress', { keyCode: 13 }));

            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].detail).toBe(4); // Should clip to 4
        });
    });

    it('does not fire gotopage event on other keys', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('gotopage', handler);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('input');
            input.value = '2';
            input.dispatchEvent(new KeyboardEvent('keypress', { keyCode: 32 })); // Space key

            expect(handler).not.toHaveBeenCalled();
        });
    });

    it('resets the page number input when the entered value is not a number', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 2;
        element.totalRecords = 20;
        element.pageSize = 5;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('gotopage', handler);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('input');
            input.value = '';
            input.dispatchEvent(new KeyboardEvent('keypress', { keyCode: 13 }));

            expect(handler.mock.calls[0][0].detail).toBe(2);
            expect(input.value).toBe('2');
        });
    });

    it('displays a single page when there are no records', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 0;
        element.pageSize = 10;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(element.shadowRoot.querySelector('#totalPages').textContent).toBe('1');
        });
    });

    it('displays the page size selector with the supported page sizes', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 1;
        element.totalRecords = 200;
        element.pageSize = 25;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const combobox = element.shadowRoot.querySelector('lightning-combobox');
            expect(combobox).not.toBeNull();
            expect(combobox.value).toBe('25');
            expect(combobox.options.map((option) => option.value)).toEqual(['10', '25', '50', '100']);
        });
    });

    it('fires pagesizechange event when a new page size is selected', () => {
        const element = createElement('c-rflib-paginator', {
            is: Paginator
        });
        element.currentPage = 3;
        element.totalRecords = 200;
        element.pageSize = 10;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('pagesizechange', handler);

        return Promise.resolve().then(() => {
            const combobox = element.shadowRoot.querySelector('lightning-combobox');
            combobox.dispatchEvent(new CustomEvent('change', { detail: { value: '50' } }));

            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].detail).toBe(50);
        });
    });

    it('validates page sizes', () => {
        expect(PAGE_SIZES).toEqual([10, 25, 50, 100]);
        expect(getValidPageSize('50', 10)).toBe(50);
        expect(getValidPageSize(100, 10)).toBe(100);
        expect(getValidPageSize('30', 25)).toBe(25);
        expect(getValidPageSize(undefined, 25)).toBe(25);
        expect(getValidPageSize('abc', 10)).toBe(10);
    });
});
