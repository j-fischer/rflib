import { createElement } from 'lwc';
import RflibBigObjectStat from 'c/rflibBigObjectStat';
import getStats from '@salesforce/apex/rflib_BigObjectStatController.getStats';
import refreshStats from '@salesforce/apex/rflib_BigObjectStatController.refreshStats';
import getFieldMetadata from '@salesforce/apex/rflib_BigObjectStatController.getFieldMetadata';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';

// Mock Apex Wire Adapters
const mockGetStats = {
    data: [
        { Id: '1', Name: 'BigObject1', Count: 100 },
        { Id: '2', Name: 'BigObject2', Count: 200 }
    ],
    error: undefined
};

const mockFieldMetadata = {
    data: [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Count', fieldName: 'Count', type: 'number' }
    ],
    error: undefined
};

// Mock rflibLogger
jest.mock('c/rflibLogger', () => {
    return {
        createLogger: jest.fn(() => ({
            debug: jest.fn(),
            info: jest.fn(),
            warn: jest.fn(),
            error: jest.fn()
        }))
    };
});

// Mock Apex Methods
jest.mock(
    '@salesforce/apex/rflib_BigObjectStatController.refreshStats',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_BigObjectStatController.getStats',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_BigObjectStatController.getFieldMetadata',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

// Mock lightning/empApi
jest.mock(
    'lightning/empApi',
    () => {
        return {
            subscribe: jest.fn().mockResolvedValue({}),
            unsubscribe: jest.fn().mockResolvedValue({})
        };
    },
    { virtual: true }
);

// Mock refreshApex
jest.mock(
    '@salesforce/apex',
    () => {
        return {
            refreshApex: jest.fn().mockResolvedValue()
        };
    },
    { virtual: true }
);

const MOCK_CONFIGS = JSON.stringify([
    {
        name: 'BigObject1',
        indexFields: ['Field1', 'Field2'],
        orderBy: 'Field1'
    },
    {
        name: 'BigObject2',
        indexFields: ['FieldA'],
        orderBy: 'FieldA'
    }
]);

const MOCK_FIELDS = 'Name, Count';

describe('c-rflib-big-object-stat', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('initializes correctly with valid config', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;
        document.body.appendChild(element);

        // Verify wire adapters were called
        // Since getStats and getFieldMetadata are wire adapters, we check if they emit data
        getStats.emit(mockGetStats.data);
        getFieldMetadata.emit(mockFieldMetadata.data);

        // Wait for any asynchronous DOM updates
        await Promise.resolve();

        // Check if datatable is rendered
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toEqual(mockGetStats.data);

        // Verify columns (needs to check internal logic of mapping, but at least we check columns prop)
        // The last column is the action column
        expect(datatable.columns.length).toBe(3);
        expect(datatable.columns[0].label).toBe('Name');
    });

    it('shows error toast on invalid config', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = 'invalid-json';
        element.fieldsToDisplay = MOCK_FIELDS;

        const handler = jest.fn();
        element.addEventListener(ShowToastEventName, handler);

        document.body.appendChild(element);

        await Promise.resolve();

        expect(handler).toHaveBeenCalled();
        const toastEvent = handler.mock.calls[0][0];
        expect(toastEvent.detail.title).toBe('Configuration Error');
    });

    it('handles getStats error', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;

        const handler = jest.fn();
        element.addEventListener(ShowToastEventName, handler);

        document.body.appendChild(element);

        getStats.error('Error fetching stats');

        await Promise.resolve();

        expect(handler).toHaveBeenCalled();
        expect(handler.mock.calls[0][0].detail.title).toBe('Error Loading Stats');
    });

    it('handles getFieldMetadata error', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;

        const handler = jest.fn();
        element.addEventListener(ShowToastEventName, handler);

        document.body.appendChild(element);

        getFieldMetadata.error('Error fetching metadata');

        await Promise.resolve();

        expect(handler).toHaveBeenCalled();
        expect(handler.mock.calls[0][0].detail.title).toBe('Configuration Error');
    });

    it('shows empty state when no stats available', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;
        document.body.appendChild(element);

        getStats.emit([]); // Empty data
        getFieldMetadata.emit(mockFieldMetadata.data);

        await Promise.resolve();

        const illustration = element.shadowRoot.querySelector('.slds-illustration');
        expect(illustration).not.toBeNull();
        expect(illustration.textContent).toContain('No Statistics Available');
    });

    it('calls refreshStats for all objects on "Count All" click', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;

        const handler = jest.fn();
        element.addEventListener(ShowToastEventName, handler);

        document.body.appendChild(element);

        getStats.emit(mockGetStats.data);
        getFieldMetadata.emit(mockFieldMetadata.data);

        await Promise.resolve();

        const countAllBtn = element.shadowRoot.querySelector('lightning-button');
        countAllBtn.click();

        expect(refreshStats).toHaveBeenCalledTimes(2); // 2 configs in MOCK_CONFIGS

        // Check parameters for one of the calls
        expect(refreshStats).toHaveBeenCalledWith(expect.objectContaining({
            bigObjectName: 'BigObject1'
        }));

        // Should show success toast
        expect(handler).toHaveBeenCalled();
        expect(handler.mock.calls[0][0].detail.title).toBe('Success');
    });

    it('handles error during "Count All"', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        // We'll set an invalid config that is not an array to trigger the error in countAllBigObjects
        // But invalid JSON is handled in connectedCallback.
        // Let's force an error by mocking refreshStats to throw synchronously.

        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;

        const handler = jest.fn();
        element.addEventListener(ShowToastEventName, handler);

        // Mock implementation to throw synchronously to hit the catch block in countAllBigObjects
        refreshStats.mockImplementation(() => {
            throw new Error('Refresh failed');
        });

        document.body.appendChild(element);

        await Promise.resolve();

        const countAllBtn = element.shadowRoot.querySelector('lightning-button');
        countAllBtn.click();

        // Wait for async click handler
        await Promise.resolve();

        expect(handler).toHaveBeenCalled();
        expect(handler.mock.calls[0][0].detail.title).toBe('Refresh Error');
    });

    it('calls refreshStats for specific object on row action', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;
        document.body.appendChild(element);

        getStats.emit(mockGetStats.data);
        getFieldMetadata.emit(mockFieldMetadata.data);

        await Promise.resolve();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');

        // Trigger row action
        const row = { Name: 'BigObject1' };
        datatable.dispatchEvent(new CustomEvent('rowaction', {
            detail: {
                action: { name: 'refresh' },
                row: row
            }
        }));

        expect(refreshStats).toHaveBeenCalledWith(expect.objectContaining({
            bigObjectName: 'BigObject1'
        }));
    });

    it('handles error during row action refresh', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;

        const handler = jest.fn();
        element.addEventListener(ShowToastEventName, handler);

        refreshStats.mockRejectedValue(new Error('Refresh failed'));

        document.body.appendChild(element);
        getStats.emit(mockGetStats.data);
        await Promise.resolve();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');

        // Trigger row action
        const row = { Name: 'BigObject1' };
        datatable.dispatchEvent(new CustomEvent('rowaction', {
            detail: {
                action: { name: 'refresh' },
                row: row
            }
        }));

        // Wait for async handling
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        expect(handler).toHaveBeenCalled();
        expect(handler.mock.calls[0][0].detail.title).toBe('Refresh Error');
    });

    it('subscribes to CDC events on connect and handles event', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;
        document.body.appendChild(element);

        // Check subscription
        expect(subscribe).toHaveBeenCalled();
        const subscriptionCallback = subscribe.mock.calls[0][2];

        // Simulate event
        await subscriptionCallback({ data: { payload: {} } });

        expect(refreshApex).toHaveBeenCalled();
    });

    it('unsubscribes on disconnect', async () => {
        const element = createElement('c-rflib-big-object-stat', {
            is: RflibBigObjectStat
        });
        element.bigObjectConfigs = MOCK_CONFIGS;
        element.fieldsToDisplay = MOCK_FIELDS;
        document.body.appendChild(element);

        // Verify subscribe was called and get the mock subscription object
        await Promise.resolve();

        document.body.removeChild(element);

        expect(unsubscribe).toHaveBeenCalled();
    });
});
