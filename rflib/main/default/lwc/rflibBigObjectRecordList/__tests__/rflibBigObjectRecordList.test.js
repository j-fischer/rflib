import { createElement } from 'lwc';
import RflibBigObjectRecordList from 'c/rflibBigObjectRecordList';

jest.mock(
    'c/rflibLogger',
    () => {
        return require('../../../../../test/jest-mocks/c/rflibLogger');
    },
    { virtual: true }
);

const FIELDS = [
    { apiName: 'Occurred_On__c', label: 'Occurred On', dataType: 'datetime' },
    { apiName: 'Event_Name__c', label: 'Event', dataType: 'text' },
    { apiName: 'Related_Record_ID__c', label: 'Related Record', dataType: 'text' },
    { apiName: 'Amount__c', label: 'Amount', dataType: 'number' },
    { apiName: 'Additional_Details__c', label: 'Details', dataType: 'longtext' }
];

const DISPLAY_FIELDS = ['Occurred_On__c', 'Event_Name__c', 'Related_Record_ID__c', 'Amount__c'];
const INDEX_FIELDS = ['Occurred_On__c', 'Event_Name__c', 'Related_Record_ID__c'];

const RECORD_A = {
    Occurred_On__c: '2026-10-03T10:00:00.000Z',
    Event_Name__c: 'LOGIN',
    Related_Record_ID__c: '001A',
    Amount__c: 10,
    Additional_Details__c: '{"user":"alice"}'
};
const RECORD_B = {
    Occurred_On__c: '2026-10-02T10:00:00.000Z',
    Event_Name__c: 'LOGOUT',
    Related_Record_ID__c: '001B',
    Amount__c: 20,
    Additional_Details__c: '{"user":"bob"}'
};
// Null fields are absent from a serialized record.
const RECORD_C = {
    Occurred_On__c: '2026-10-01T10:00:00.000Z',
    Event_Name__c: 'LOGIN',
    Related_Record_ID__c: '001C'
};
const RECORDS = [RECORD_A, RECORD_B, RECORD_C];

function keyOf(record) {
    return JSON.stringify(INDEX_FIELDS.map((fieldName) => record[fieldName]));
}

function createList(records = RECORDS, pageSize = 10) {
    const element = createElement('c-rflib-big-object-record-list', { is: RflibBigObjectRecordList });
    element.fields = FIELDS;
    element.displayFields = DISPLAY_FIELDS;
    element.indexFields = INDEX_FIELDS;
    element.pageSize = pageSize;
    element.records = records;
    document.body.appendChild(element);
    return element;
}

function getRows(element) {
    return Array.from(element.shadowRoot.querySelectorAll('c-rflib-big-object-record-list-row')).map(
        (rowElement) => rowElement.row
    );
}

function setFilter(element, selector, value) {
    const input = element.shadowRoot.querySelector(selector);
    input.value = value;
    input.dispatchEvent(new CustomEvent('change'));
}

function search(element) {
    element.shadowRoot.querySelector('lightning-button').click();
}

describe('c-rflib-big-object-record-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        jest.useRealTimers();
    });

    it('renders the configured columns and the first page', async () => {
        const element = createList(RECORDS, 2);
        await Promise.resolve();

        const headers = Array.from(element.shadowRoot.querySelectorAll('th')).map((th) => th.textContent);
        expect(headers).toEqual(['Occurred On', 'Event', 'Related Record', 'Amount']);
        expect(element.shadowRoot.querySelector('lightning-card').title).toBe('3 Displayed Records');

        const rows = getRows(element);
        expect(rows.length).toBe(2);
        expect(rows[0].key).toBe(keyOf(RECORD_A));
        expect(rows[0].cells.map((cell) => cell.key)).toEqual(DISPLAY_FIELDS);
        expect(rows[0].cells[0].isDatetime).toBe(true);
        expect(rows[0].cells[3].isNumber).toBe(true);
    });

    it('pages through the filtered records', async () => {
        const element = createList(RECORDS, 2);
        await Promise.resolve();

        element.currentPage = 2;
        await Promise.resolve();

        const rows = getRows(element);
        expect(rows.length).toBe(1);
        expect(rows[0].record).toEqual(RECORD_C);
    });

    it('combines column filters and the global search with AND, case-sensitively', async () => {
        const element = createList();
        await Promise.resolve();

        setFilter(element, 'lightning-input[data-field="Event_Name__c"]', 'LOGIN');
        search(element);
        await Promise.resolve();
        expect(getRows(element).map((row) => row.record)).toEqual([RECORD_A, RECORD_C]);

        setFilter(element, 'lightning-input[data-id="global-search"]', 'alice');
        search(element);
        await Promise.resolve();
        expect(getRows(element).map((row) => row.record)).toEqual([RECORD_A]);

        setFilter(element, 'lightning-input[data-id="global-search"]', 'ALICE');
        search(element);
        await Promise.resolve();
        expect(getRows(element).length).toBe(0);
    });

    it('reaches fields that are only shown in the detail pane through the global search', async () => {
        const element = createList();
        await Promise.resolve();

        setFilter(element, 'lightning-input[data-id="global-search"]', '"user":"bob"');
        search(element);
        await Promise.resolve();

        expect(getRows(element).map((row) => row.record)).toEqual([RECORD_B]);
    });

    it('filters numbers and dates by range and tolerates absent fields', async () => {
        const element = createList();
        await Promise.resolve();

        setFilter(element, 'lightning-input[data-field="Amount__c"][data-part="fromValue"]', '15');
        search(element);
        await Promise.resolve();
        expect(getRows(element).map((row) => row.record)).toEqual([RECORD_B]);

        setFilter(element, 'lightning-input[data-field="Amount__c"][data-part="fromValue"]', '');
        setFilter(element, 'lightning-input[data-field="Occurred_On__c"][data-part="fromValue"]', '2026-10-02');
        setFilter(element, 'lightning-input[data-field="Occurred_On__c"][data-part="toValue"]', '2026-10-03');
        search(element);
        await Promise.resolve();
        expect(getRows(element).map((row) => row.record)).toEqual([RECORD_A, RECORD_B]);

        setFilter(element, 'lightning-input[data-field="Related_Record_ID__c"]', '001');
        setFilter(element, 'lightning-input[data-id="global-search"]', 'user');
        search(element);
        await Promise.resolve();
        expect(getRows(element).length).toBe(2);
    });

    it('runs the search on Enter', async () => {
        const element = createList();
        await Promise.resolve();

        setFilter(element, 'lightning-input[data-field="Event_Name__c"]', 'LOGOUT');
        element.shadowRoot.querySelector('.filter-bar').dispatchEvent(new KeyboardEvent('keyup', { key: 'Enter' }));
        await Promise.resolve();

        expect(getRows(element).map((row) => row.record)).toEqual([RECORD_B]);
    });

    it('keeps the selected record selected when the filter changes', async () => {
        const element = createList();
        element.selectedKey = keyOf(RECORD_C);
        await Promise.resolve();

        expect(getRows(element)[2].isSelected).toBe(true);

        setFilter(element, 'lightning-input[data-field="Event_Name__c"]', 'LOGIN');
        search(element);
        await Promise.resolve();

        const rows = getRows(element);
        expect(rows[0].isSelected).toBe(false);
        expect(rows[1].record).toEqual(RECORD_C);
        expect(rows[1].isSelected).toBe(true);
    });

    it('dispatches the key and record of a clicked row', async () => {
        const element = createList();
        const handler = jest.fn();
        element.addEventListener('recordselected', handler);
        await Promise.resolve();

        element.shadowRoot.querySelectorAll('c-rflib-big-object-record-list-row')[1].click();

        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail).toEqual({ key: keyOf(RECORD_B), record: RECORD_B });
    });

    it('reports the filtered count and page after every refresh', async () => {
        const element = createList(RECORDS, 2);
        const handler = jest.fn();
        element.addEventListener('refreshed', handler);

        setFilter(element, 'lightning-input[data-field="Event_Name__c"]', 'LOGOUT');
        search(element);
        await Promise.resolve();

        const detail = JSON.parse(handler.mock.calls[handler.mock.calls.length - 1][0].detail);
        expect(detail).toEqual({ numDisplayedRecords: 1, currentPage: 1 });
    });

    it('shows a spinner while searching a large set and filters 10,000 wide records within budget', async () => {
        jest.useFakeTimers();

        const details = 'x'.repeat(2000);
        const records = [];
        for (let i = 0; i < 10000; i++) {
            records.push({
                Occurred_On__c: new Date(Date.UTC(2026, 9, 1, 0, 0, i)).toISOString(),
                Event_Name__c: 'EVENT_' + (i % 10),
                Related_Record_ID__c: 'REL' + i,
                Amount__c: i,
                Additional_Details__c: details + i
            });
        }

        const element = createList(records);
        await Promise.resolve();

        // A term that matches nothing forces a full scan of every field of every record.
        setFilter(element, 'lightning-input[data-id="global-search"]', 'no such value');
        search(element);
        await Promise.resolve();
        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();

        const start = Date.now();
        jest.runAllTimers();
        const elapsed = Date.now() - start;
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
        expect(getRows(element).length).toBe(0);
        // Catches an accidental copy of the whole set or a quadratic predicate, both of which take seconds here.
        expect(elapsed).toBeLessThan(1000);
    });
});
