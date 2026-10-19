import { createElement } from 'lwc';
import RflibBigObjectRecordListRow from 'c/rflibBigObjectRecordListRow';

const ROW = {
    key: '2026-10-01T12:00:00.000Z||LOGIN',
    isSelected: false,
    cells: [
        { key: 'Occurred_On__c', value: '2026-10-01T12:00:00.000Z', isDatetime: true },
        { key: 'Due_Date__c', value: '2026-10-02', isDate: true },
        { key: 'Count__c', value: 42, isNumber: true },
        { key: 'Event_Name__c', value: 'LOGIN' }
    ]
};

describe('c-rflib-big-object-record-list-row', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders every cell with the renderer of its type', async () => {
        const element = createElement('c-rflib-big-object-record-list-row', { is: RflibBigObjectRecordListRow });
        element.row = ROW;
        document.body.appendChild(element);
        await Promise.resolve();

        const cells = element.shadowRoot.querySelectorAll('td');
        expect(cells.length).toBe(4);

        const dateTimes = element.shadowRoot.querySelectorAll('lightning-formatted-date-time');
        expect(dateTimes.length).toBe(2);
        expect(dateTimes[0].value).toBe('2026-10-01T12:00:00.000Z');
        expect(dateTimes[1].timeZone).toBe('UTC');

        expect(element.shadowRoot.querySelector('lightning-formatted-number').value).toBe(42);
        expect(cells[3].textContent).toBe('LOGIN');
        expect(element.shadowRoot.querySelector('tr').className).toBe('record-row');
    });

    it('marks a selected row', async () => {
        const element = createElement('c-rflib-big-object-record-list-row', { is: RflibBigObjectRecordListRow });
        element.row = { ...ROW, isSelected: true };
        document.body.appendChild(element);
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('tr').className).toBe('record-row selected');
    });
});
