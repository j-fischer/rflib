import { createElement } from 'lwc';
import RflibBigObjectExplorer from 'c/rflibBigObjectExplorer';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';
import describeConfig from '@salesforce/apex/rflib_BigObjectQueryController.describeConfig';
import queryChunk from '@salesforce/apex/rflib_BigObjectQueryController.queryChunk';

jest.mock(
    'c/rflibLogger',
    () => {
        return require('../../../../../test/jest-mocks/c/rflibLogger');
    },
    { virtual: true }
);

jest.mock('lightning/platformResourceLoader', () => ({ loadStyle: jest.fn(() => Promise.resolve()) }));

jest.mock('@salesforce/apex/rflib_BigObjectQueryController.describeConfig', () => ({ default: jest.fn() }), {
    virtual: true
});

jest.mock('@salesforce/apex/rflib_BigObjectQueryController.queryChunk', () => ({ default: jest.fn() }), {
    virtual: true
});

const ARCHIVE = 'rflib_Application_Event_Archive__b';
const INDEX_FIELDS = ['Occurred_On__c', 'Event_Name__c', 'Related_Record_ID__c', 'Created_By_ID__c'];
const DEFAULT_FILTER = {
    fieldName: 'Occurred_On__c',
    operator: 'RANGE',
    fromValue: '2026-10-07T00:00:00.000Z',
    toValue: '2026-10-14T23:59:59.999Z'
};

function createDescription(overrides = {}) {
    return {
        isValid: true,
        problems: [],
        objectApiName: ARCHIVE,
        objectLabel: 'Application Event Archive',
        fields: [
            { apiName: 'Occurred_On__c', label: 'Occurred On', dataType: 'datetime' },
            { apiName: 'Event_Name__c', label: 'Event Name', dataType: 'text' },
            { apiName: 'Related_Record_ID__c', label: 'Related Record ID', dataType: 'text' },
            { apiName: 'Created_By_ID__c', label: 'Created By ID', dataType: 'text' },
            { apiName: 'Additional_Details__c', label: 'Additional Details', dataType: 'longtext' }
        ],
        indexFields: INDEX_FIELDS,
        displayFields: ['Occurred_On__c', 'Event_Name__c', 'Related_Record_ID__c'],
        detailFields: [...INDEX_FIELDS, 'Additional_Details__c'],
        droppedFields: [],
        defaultFilters: [DEFAULT_FILTER],
        filterableIndexDepth: 1,
        ...overrides
    };
}

function createRecord(index, details = '{}') {
    return {
        Occurred_On__c: new Date(Date.UTC(2026, 9, 10, 0, 0, index)).toISOString(),
        Event_Name__c: 'EVENT_' + index,
        Related_Record_ID__c: 'REL' + index,
        Created_By_ID__c: 'USER',
        Additional_Details__c: details
    };
}

function createChunk(records, { isComplete = false, isStuck = false, message = null, recordsLoaded = 0 } = {}) {
    return {
        records,
        cursor: {
            boundaryValue: records.length ? records[records.length - 1].Occurred_On__c : null,
            seenKeys: [],
            recordsLoaded
        },
        isComplete,
        isStuck,
        message
    };
}

function createDeferred() {
    let resolve;
    const promise = new Promise((res) => {
        resolve = res;
    });
    return { promise, resolve };
}

function flush() {
    return new Promise((resolve) => setTimeout(resolve, 0));
}

function createExplorer(properties = {}) {
    const element = createElement('c-rflib-big-object-explorer', { is: RflibBigObjectExplorer });
    Object.assign(
        element,
        {
            bigObjectApiName: ARCHIVE,
            indexFields: INDEX_FIELDS.join(','),
            indexSortDirection: 'DESC',
            displayFields: 'Occurred_On__c, Event_Name__c, Related_Record_ID__c',
            detailFields: '',
            defaultFilter: 'Occurred_On__c=LAST_N_DAYS:7',
            filterableIndexDepth: 1,
            chunkSize: 2000,
            maxRecords: 100000,
            pageSize: 25
        },
        properties
    );
    return element;
}

function mount(element, toastHandler) {
    if (toastHandler) {
        element.addEventListener(ShowToastEventName, toastHandler);
    }
    document.body.appendChild(element);
    return element;
}

function getList(element) {
    return element.shadowRoot.querySelector('c-rflib-big-object-record-list');
}

function getButton(element, label) {
    return Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find((button) => button.label === label);
}

describe('c-rflib-big-object-explorer', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        // clearAllMocks keeps queued mockResolvedValueOnce results, which would leak into the next test.
        describeConfig.mockReset();
        queryChunk.mockReset();
    });

    it('sends the parsed design attributes to the server', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk.mockResolvedValue(createChunk([], { isComplete: true }));

        mount(createExplorer({ detailFields: 'Occurred_On__c ,Additional_Details__c,' }));
        await flush();

        expect(describeConfig).toHaveBeenCalledWith({
            config: {
                bigObjectApiName: ARCHIVE,
                indexFields: INDEX_FIELDS,
                sortDirection: 'DESC',
                displayFields: ['Occurred_On__c', 'Event_Name__c', 'Related_Record_ID__c'],
                detailFields: ['Occurred_On__c', 'Additional_Details__c'],
                defaultFilter: 'Occurred_On__c=LAST_N_DAYS:7',
                filterableIndexDepth: 1,
                chunkSize: 2000
            }
        });
    });

    it('renders configuration problems inline instead of a toast', async () => {
        describeConfig.mockResolvedValue({
            isValid: false,
            problems: [
                { attribute: 'indexFields', message: 'At least one index field is required.' },
                { attribute: 'displayFields', message: 'The field Foo__c does not exist.' }
            ]
        });
        const toastHandler = jest.fn();

        const element = mount(createExplorer(), toastHandler);
        await flush();

        const problems = element.shadowRoot.querySelectorAll('.config-problem');
        expect(problems.length).toBe(2);
        expect(problems[0].textContent).toContain('indexFields');
        expect(problems[1].textContent).toContain('Foo__c');
        expect(toastHandler).not.toHaveBeenCalled();
        expect(queryChunk).not.toHaveBeenCalled();
        expect(getList(element)).toBeNull();
    });

    it('renders an unexpected describe failure inline', async () => {
        describeConfig.mockRejectedValue({ body: { message: 'Insufficient access' } });

        const element = mount(createExplorer());
        await flush();

        expect(element.shadowRoot.querySelector('.config-problem').textContent).toContain('Insufficient access');
    });

    it('loads every chunk until the range is exhausted', async () => {
        describeConfig.mockResolvedValue(createDescription());
        const firstChunk = createChunk([createRecord(1), createRecord(2)], { recordsLoaded: 2 });
        queryChunk
            .mockResolvedValueOnce(firstChunk)
            .mockResolvedValueOnce(createChunk([createRecord(3)], { isComplete: true, recordsLoaded: 3 }));

        const element = mount(createExplorer());
        await flush();
        await flush();

        expect(queryChunk).toHaveBeenCalledTimes(2);
        expect(queryChunk.mock.calls[0][0].cursor).toBeNull();
        expect(queryChunk.mock.calls[0][0].config.indexFilters).toEqual([DEFAULT_FILTER]);
        expect(queryChunk.mock.calls[1][0].cursor).toEqual(firstChunk.cursor);

        expect(getList(element).records.length).toBe(3);
        expect(element.shadowRoot.querySelector('.slds-page-header__name-meta').textContent).toContain(
            '3 Records Loaded'
        );
        expect(element.shadowRoot.querySelector('.loading-overlay')).toBeNull();
    });

    it('discards a chunk that arrives after a newer load started', async () => {
        describeConfig.mockResolvedValue(createDescription());
        const lateChunk = createDeferred();
        queryChunk
            .mockReturnValueOnce(lateChunk.promise)
            .mockResolvedValueOnce(createChunk([createRecord(9)], { isComplete: true }));

        const element = mount(createExplorer());
        await flush();

        getButton(element, 'Cancel').click();
        await flush();
        getButton(element, 'Query').click();
        await flush();

        lateChunk.resolve(createChunk([createRecord(1), createRecord(2)], { isComplete: true }));
        await flush();

        const records = getList(element).records;
        expect(records.length).toBe(1);
        expect(records[0].Event_Name__c).toBe('EVENT_9');
    });

    it('keeps the records loaded so far when the user cancels', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk
            .mockResolvedValueOnce(createChunk([createRecord(1), createRecord(2)]))
            .mockReturnValueOnce(createDeferred().promise);
        const toastHandler = jest.fn();

        const element = mount(createExplorer(), toastHandler);
        await flush();

        expect(element.shadowRoot.querySelector('.loading-text').textContent).toBe('Loaded 2 records');

        getButton(element, 'Cancel').click();
        await flush();

        expect(element.shadowRoot.querySelector('.loading-overlay')).toBeNull();
        expect(getList(element).records.length).toBe(2);
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Load cancelled');
    });

    it('stops at maxRecords and warns', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk
            .mockResolvedValueOnce(createChunk([createRecord(1), createRecord(2)]))
            .mockResolvedValueOnce(createChunk([createRecord(3), createRecord(4)]));
        const toastHandler = jest.fn();

        const element = mount(createExplorer({ maxRecords: 3 }), toastHandler);
        await flush();
        await flush();

        expect(queryChunk).toHaveBeenCalledTimes(2);
        expect(getList(element).records.length).toBe(3);
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Record limit reached');
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('warning');
    });

    it('caps the last chunk at maxRecords', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk.mockResolvedValueOnce(
            createChunk([createRecord(1), createRecord(2), createRecord(3), createRecord(4)], { isComplete: true })
        );
        const toastHandler = jest.fn();

        const element = mount(createExplorer({ maxRecords: 3 }), toastHandler);
        await flush();

        expect(getList(element).records.length).toBe(3);
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Record limit reached');
    });

    it('does not warn when the last chunk ends exactly at maxRecords', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk.mockResolvedValueOnce(createChunk([createRecord(1), createRecord(2)], { isComplete: true }));
        const toastHandler = jest.fn();

        const element = mount(createExplorer({ maxRecords: 2 }), toastHandler);
        await flush();

        expect(getList(element).records.length).toBe(2);
        expect(toastHandler).not.toHaveBeenCalled();
    });

    it('resolves untouched default filters again on every query', async () => {
        const nextDayFilter = {
            ...DEFAULT_FILTER,
            fromValue: '2026-10-08T00:00:00.000Z',
            toValue: '2026-10-15T23:59:59.999Z'
        };
        describeConfig
            .mockResolvedValueOnce(createDescription())
            .mockResolvedValueOnce(createDescription({ defaultFilters: [nextDayFilter] }));
        queryChunk.mockResolvedValue(createChunk([], { isComplete: true }));

        const element = mount(createExplorer());
        await flush();

        getButton(element, 'Query').click();
        await flush();

        expect(describeConfig).toHaveBeenCalledTimes(2);
        expect(queryChunk.mock.calls[1][0].config.indexFilters).toEqual([nextDayFilter]);
    });

    it('refreshes the defaults the user did not edit when another filter was edited', async () => {
        const tenantDescription = (occurredFilter) =>
            createDescription({
                fields: [
                    { apiName: 'Tenant_Id__c', label: 'Tenant', dataType: 'text' },
                    { apiName: 'Occurred_On__c', label: 'Occurred On', dataType: 'datetime' }
                ],
                indexFields: ['Tenant_Id__c', 'Occurred_On__c'],
                displayFields: ['Tenant_Id__c', 'Occurred_On__c'],
                detailFields: ['Tenant_Id__c', 'Occurred_On__c'],
                defaultFilters: [{ fieldName: 'Tenant_Id__c', operator: 'EQUALS', value: 'ACME' }, occurredFilter],
                filterableIndexDepth: 2
            });
        const nextDayFilter = {
            ...DEFAULT_FILTER,
            fromValue: '2026-10-08T00:00:00.000Z',
            toValue: '2026-10-15T23:59:59.999Z'
        };
        describeConfig
            .mockResolvedValueOnce(tenantDescription(DEFAULT_FILTER))
            .mockResolvedValueOnce(tenantDescription(nextDayFilter));
        queryChunk.mockResolvedValue(createChunk([], { isComplete: true }));

        const element = mount(createExplorer());
        await flush();

        const tenantInput = element.shadowRoot.querySelector('lightning-input[data-field="Tenant_Id__c"]');
        tenantInput.value = 'BETA';
        tenantInput.dispatchEvent(new CustomEvent('change'));
        getButton(element, 'Query').click();
        await flush();

        expect(describeConfig).toHaveBeenCalledTimes(2);
        expect(queryChunk.mock.calls[1][0].config.indexFilters).toEqual([
            { fieldName: 'Tenant_Id__c', operator: 'EQUALS', value: 'BETA' },
            nextDayFilter
        ]);
    });

    it('keeps edited index filters instead of resolving the defaults again', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk.mockResolvedValue(createChunk([], { isComplete: true }));

        const element = mount(createExplorer());
        await flush();

        const fromInput = element.shadowRoot.querySelector('lightning-input[data-field="Occurred_On__c"]');
        fromInput.value = '2026-10-01T00:00:00.000Z';
        fromInput.dispatchEvent(new CustomEvent('change'));
        getButton(element, 'Query').click();
        await flush();

        expect(describeConfig).toHaveBeenCalledTimes(1);
        expect(queryChunk.mock.calls[1][0].config.indexFilters).toEqual([
            { ...DEFAULT_FILTER, fromValue: '2026-10-01T00:00:00.000Z' }
        ]);
    });

    it('stops and explains when the cursor cannot advance', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk.mockResolvedValueOnce(
            createChunk([], { isStuck: true, message: 'More than 2000 records share the value X' })
        );
        const toastHandler = jest.fn();

        mount(createExplorer(), toastHandler);
        await flush();

        expect(queryChunk).toHaveBeenCalledTimes(1);
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('More than 2000 records share the value X');
    });

    it('reports a failed chunk', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk.mockRejectedValueOnce({ body: { message: 'The query against X failed' } });
        const toastHandler = jest.fn();

        const element = mount(createExplorer(), toastHandler);
        await flush();

        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('The query against X failed');
        expect(element.shadowRoot.querySelector('.loading-overlay')).toBeNull();
    });

    describe('when the first chunk projects a large payload', () => {
        const wideDetails = 'x'.repeat(1100);

        beforeEach(() => {
            describeConfig.mockResolvedValue(createDescription());
            queryChunk
                .mockResolvedValueOnce(createChunk([createRecord(1, wideDetails), createRecord(2, wideDetails)]))
                .mockResolvedValueOnce(createChunk([createRecord(3, wideDetails)], { isComplete: true }));
        });

        it('asks before continuing and loads the rest on confirmation', async () => {
            const element = mount(createExplorer());
            await flush();

            const dialog = element.shadowRoot.querySelector('c-rflib-confirmation-dialog');
            expect(dialog.visible).toBe(true);
            expect(dialog.message).toContain('100,000 records');
            expect(queryChunk).toHaveBeenCalledTimes(1);

            dialog.dispatchEvent(new CustomEvent('modalaction', { detail: { status: 'confirm' } }));
            await flush();

            expect(queryChunk).toHaveBeenCalledTimes(2);
            expect(getList(element).records.length).toBe(3);
        });

        it('keeps the first chunk when the user stops', async () => {
            const element = mount(createExplorer());
            await flush();

            element.shadowRoot
                .querySelector('c-rflib-confirmation-dialog')
                .dispatchEvent(new CustomEvent('modalaction', { detail: { status: 'cancel' } }));
            await flush();

            expect(queryChunk).toHaveBeenCalledTimes(1);
            expect(getList(element).records.length).toBe(2);
        });

        it('does not ask when maxRecords keeps the projection small', async () => {
            const element = mount(createExplorer({ maxRecords: 1000 }));
            await flush();
            await flush();

            expect(element.shadowRoot.querySelector('c-rflib-confirmation-dialog').visible).toBe(false);
            expect(queryChunk).toHaveBeenCalledTimes(2);
        });
    });

    it('only unlocks an index filter once every filter above it holds an exact value', async () => {
        describeConfig.mockResolvedValue(
            createDescription({
                fields: [
                    { apiName: 'Tenant_Id__c', label: 'Tenant', dataType: 'text' },
                    { apiName: 'Occurred_On__c', label: 'Occurred On', dataType: 'datetime' }
                ],
                indexFields: ['Tenant_Id__c', 'Occurred_On__c'],
                displayFields: ['Tenant_Id__c', 'Occurred_On__c'],
                detailFields: ['Tenant_Id__c', 'Occurred_On__c'],
                defaultFilters: [],
                filterableIndexDepth: 2
            })
        );
        queryChunk.mockResolvedValue(createChunk([], { isComplete: true }));

        const element = mount(createExplorer());
        await flush();

        const tenantInput = () => element.shadowRoot.querySelector('lightning-input[data-field="Tenant_Id__c"]');
        const dateInputs = () =>
            Array.from(element.shadowRoot.querySelectorAll('lightning-input[data-field="Occurred_On__c"]'));
        const setValue = async (input, value) => {
            input.value = value;
            input.dispatchEvent(new CustomEvent('change'));
            await flush();
        };

        expect(tenantInput().disabled).toBe(false);
        expect(dateInputs().every((input) => input.disabled)).toBe(true);

        await setValue(tenantInput(), 'ACME,BETA');
        expect(dateInputs().every((input) => input.disabled)).toBe(true);

        await setValue(tenantInput(), 'ACME');
        expect(dateInputs().every((input) => !input.disabled)).toBe(true);

        await setValue(dateInputs()[0], '2026-10-01T00:00:00.000Z');
        getButton(element, 'Query').click();
        await flush();

        expect(queryChunk.mock.calls[queryChunk.mock.calls.length - 1][0].config.indexFilters).toEqual([
            { fieldName: 'Tenant_Id__c', operator: 'EQUALS', value: 'ACME' },
            { fieldName: 'Occurred_On__c', operator: 'RANGE', fromValue: '2026-10-01T00:00:00.000Z', toValue: null }
        ]);
    });

    it('shows the default filter in the index filter inputs', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk.mockResolvedValue(createChunk([], { isComplete: true }));

        const element = mount(createExplorer());
        await flush();

        const inputs = element.shadowRoot.querySelectorAll('lightning-input[data-field="Occurred_On__c"]');
        expect(inputs[0].value).toBe(DEFAULT_FILTER.fromValue);
        expect(inputs[1].value).toBe(DEFAULT_FILTER.toValue);
    });

    it('applies label overrides and shows the selected record', async () => {
        describeConfig.mockResolvedValue(createDescription());
        queryChunk.mockResolvedValue(createChunk([createRecord(1)], { isComplete: true }));

        const element = mount(createExplorer({ fieldLabels: 'Event_Name__c=Event, related_record_id__c=Related' }));
        await flush();

        const list = getList(element);
        const labels = list.fields.map((field) => field.label);
        expect(labels).toEqual(['Occurred On', 'Event', 'Related', 'Created By ID', 'Additional Details']);
        expect(element.shadowRoot.querySelector('c-rflib-big-object-record-viewer')).toBeNull();

        const record = list.records[0];
        list.dispatchEvent(new CustomEvent('recordselected', { detail: { key: 'KEY', record } }));
        await flush();

        const viewer = element.shadowRoot.querySelector('c-rflib-big-object-record-viewer');
        expect(viewer.record).toEqual(record);
        expect(viewer.fields.map((field) => field.apiName)).toEqual([...INDEX_FIELDS, 'Additional_Details__c']);
        expect(viewer.title).toBe('EVENT_1 - REL1');
        expect(list.selectedKey).toBe('KEY');

        viewer.dispatchEvent(new CustomEvent('closeviewer'));
        await flush();
        expect(element.shadowRoot.querySelector('c-rflib-big-object-record-viewer')).toBeNull();
        expect(list.selectedKey).toBeNull();
    });

    it('jumps to the page entered in the paginator', async () => {
        describeConfig.mockResolvedValue(createDescription());
        const records = Array.from({ length: 5 }, (value, index) => createRecord(index));
        queryChunk.mockResolvedValue(createChunk(records, { isComplete: true }));

        const element = mount(createExplorer({ pageSize: 2 }));
        await flush();

        const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
        expect(paginator.shouldDisplayPageSelection).toBeTruthy();
        expect(paginator.totalRecords).toBe(5);

        // The paginator passes the typed page number as a string.
        paginator.dispatchEvent(new CustomEvent('gotopage', { detail: '3' }));
        await flush();

        expect(paginator.currentPage).toBe(3);
        expect(getList(element).currentPage).toBe(3);
    });

    it('flags fields hidden from the user', async () => {
        describeConfig.mockResolvedValue(createDescription({ droppedFields: ['Additional_Details__c'] }));
        queryChunk.mockResolvedValue(createChunk([], { isComplete: true }));

        const element = mount(createExplorer({ cardTitle: 'Archive' }));
        await flush();

        expect(element.shadowRoot.querySelector('.dropped-fields').textContent).toContain('Additional_Details__c');
        expect(element.shadowRoot.querySelector('.title').textContent).toBe('Archive');
    });
});
