import { createElement } from 'lwc';
import RflibBigObjectRecordViewer from 'c/rflibBigObjectRecordViewer';
import { getRecords } from 'lightning/uiRecordApi';
import { getNavigateCalledWith } from 'lightning/navigation';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

jest.mock(
    'c/rflibLogger',
    () => {
        return require('../../../../../test/jest-mocks/c/rflibLogger');
    },
    { virtual: true }
);

// A valid case-safe 18 character user id: no upper case letters in the first 15 characters gives the checksum AAA.
const USER_ID = '005000000000000AAA';
const ACCOUNT_ID_15 = '001000000000001';

const FIELDS = [
    { apiName: 'Occurred_On__c', label: 'Occurred On', dataType: 'datetime' },
    { apiName: 'Event_Name__c', label: 'Event', dataType: 'text' },
    { apiName: 'Created_By_ID__c', label: 'Created By', dataType: 'text' },
    { apiName: 'Related_Record_ID__c', label: 'Related Record', dataType: 'text' },
    { apiName: 'Amount__c', label: 'Amount', dataType: 'number' },
    { apiName: 'Additional_Details__c', label: 'Details', dataType: 'longtext' }
];

const RECORD = {
    Occurred_On__c: '2026-10-01T12:00:00.000Z',
    Event_Name__c: 'LOGIN',
    Created_By_ID__c: USER_ID,
    Related_Record_ID__c: ACCOUNT_ID_15,
    Amount__c: 12.5,
    Additional_Details__c: '{"user":"alice","roles":["admin"]}'
};

function createViewer(record = RECORD) {
    const element = createElement('c-rflib-big-object-record-viewer', { is: RflibBigObjectRecordViewer });
    element.fields = FIELDS;
    element.record = record;
    element.title = 'LOGIN - 001000000000001';
    document.body.appendChild(element);
    return element;
}

function getFieldElement(element, fieldName) {
    return element.shadowRoot.querySelector(`div[data-field="${fieldName}"]`);
}

describe('c-rflib-big-object-record-viewer', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders every detail field with the renderer of its type', async () => {
        const element = createViewer();
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('lightning-card').title).toBe('LOGIN - 001000000000001');
        expect(getFieldElement(element, 'Occurred_On__c').querySelector('lightning-formatted-date-time').value).toBe(
            '2026-10-01T12:00:00.000Z'
        );
        expect(getFieldElement(element, 'Amount__c').querySelector('lightning-formatted-number').value).toBe(12.5);
        expect(getFieldElement(element, 'Event_Name__c').querySelector('.text-value').textContent).toBe('LOGIN');
    });

    it('pretty-prints JSON in long text fields and toggles raw and collapsed views', async () => {
        const element = createViewer();
        await Promise.resolve();

        const details = getFieldElement(element, 'Additional_Details__c');
        expect(details.querySelector('code').textContent).toBe(
            JSON.stringify(JSON.parse(RECORD.Additional_Details__c), null, 2)
        );

        const [expandButton, formatButton] = details.querySelectorAll('lightning-button');
        expect(formatButton.label).toBe('Show Raw');

        formatButton.click();
        await Promise.resolve();
        expect(getFieldElement(element, 'Additional_Details__c').querySelector('code').textContent).toBe(
            RECORD.Additional_Details__c
        );

        expandButton.click();
        await Promise.resolve();
        expect(getFieldElement(element, 'Additional_Details__c').querySelector('code')).toBeNull();
    });

    it('shows long text that is not JSON as it is', async () => {
        const element = createViewer({ ...RECORD, Additional_Details__c: 'plain {text' });
        await Promise.resolve();

        const details = getFieldElement(element, 'Additional_Details__c');
        expect(details.querySelector('code').textContent).toBe('plain {text');
        expect(details.querySelectorAll('lightning-button').length).toBe(1);
    });

    it('renders record ids as links and resolves user names', async () => {
        const element = createViewer();
        await Promise.resolve();

        expect(getRecords.getLastConfig()).toEqual({ records: [{ recordIds: [USER_ID], fields: ['User.Name'] }] });

        const relatedLink = getFieldElement(element, 'Related_Record_ID__c').querySelector('lightning-button');
        expect(relatedLink.label).toBe(ACCOUNT_ID_15);

        relatedLink.click();
        expect(getNavigateCalledWith()).toEqual({
            type: 'standard__recordPage',
            attributes: { recordId: ACCOUNT_ID_15, actionName: 'view' }
        });

        getRecords.emit({
            results: [{ statusCode: 200, result: { id: USER_ID, fields: { Name: { value: 'Alice Admin' } } } }]
        });
        await Promise.resolve();

        expect(getFieldElement(element, 'Created_By_ID__c').querySelector('.user-name').textContent).toBe(
            'Alice Admin'
        );
    });

    it('does not mistake id-shaped text for a record id', async () => {
        const element = createViewer({
            ...RECORD,
            Created_By_ID__c: '005000000000000ABC',
            Related_Record_ID__c: 'ABCDEFGHIJKLMNO'
        });
        await Promise.resolve();

        expect(getFieldElement(element, 'Created_By_ID__c').querySelector('lightning-button')).toBeNull();
        expect(getFieldElement(element, 'Related_Record_ID__c').querySelector('.text-value').textContent).toBe(
            'ABCDEFGHIJKLMNO'
        );
    });

    it('renders a dash for absent fields', async () => {
        const element = createViewer({ Event_Name__c: 'LOGIN' });
        await Promise.resolve();

        expect(getFieldElement(element, 'Amount__c').querySelector('.slds-text-color_weak')).not.toBeNull();
    });

    it('copies the record as JSON', async () => {
        const writeText = jest.fn().mockResolvedValue(undefined);
        Object.defineProperty(navigator, 'clipboard', { value: { writeText }, configurable: true });

        const element = createViewer();
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);
        await Promise.resolve();

        element.shadowRoot.querySelector('lightning-button-icon[data-id="copy-record"]').click();
        await Promise.resolve();
        await Promise.resolve();

        expect(writeText).toHaveBeenCalledWith(JSON.stringify(RECORD, null, 2));
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');
    });

    it('reports a clipboard failure', async () => {
        const writeText = jest.fn().mockRejectedValue(new Error('denied'));
        Object.defineProperty(navigator, 'clipboard', { value: { writeText }, configurable: true });

        const element = createViewer();
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);
        await Promise.resolve();

        getFieldElement(element, 'Related_Record_ID__c').querySelector('lightning-button-icon').click();
        await Promise.resolve();
        await Promise.resolve();

        expect(writeText).toHaveBeenCalledWith(ACCOUNT_ID_15);
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
    });

    it('dispatches the full screen and close events', async () => {
        const element = createViewer();
        const fullscreenHandler = jest.fn();
        const closeHandler = jest.fn();
        element.addEventListener('togglefullscreen', fullscreenHandler);
        element.addEventListener('closeviewer', closeHandler);
        await Promise.resolve();

        element.shadowRoot.querySelector('lightning-button-icon[data-id="toggle-fullscreen"]').click();
        element.shadowRoot.querySelector('lightning-button-icon[data-id="close-viewer"]').click();

        expect(fullscreenHandler).toHaveBeenCalledTimes(1);
        expect(closeHandler).toHaveBeenCalledTimes(1);
    });
});
