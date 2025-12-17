import { createElement } from 'lwc';
import RflibLogEventListRow from 'c/rflibLogEventListRow';

describe('c-rflib-log-event-list-row', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('displays the correct data for standard fields and ERROR level', () => {
        const evt = {
            CreatedById: '005000000000001',
            CreatedDate: '2021-01-01T00:00:00.000Z',
            Log_Level__c: 'ERROR',
            Request_ID__c: 'REQ-123',
            Context__c: 'TestContext'
        };

        const element = createElement('c-rflib-log-event-list-row', {
            is: RflibLogEventListRow
        });
        element.evt = evt;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const row = element.shadowRoot.querySelector('tr');
            expect(row.className).toContain('log-row');
            expect(row.className).toContain('level-error');

            const dateEl = element.shadowRoot.querySelector('lightning-formatted-date-time');
            expect(dateEl.value).toBe(evt.CreatedDate);

            const cells = element.shadowRoot.querySelectorAll('td div');
            // Index 0 is date (handled above)
            // Index 1 is CreatedBy
            expect(cells[1].textContent).toBe(evt.CreatedById);
            // Index 2 is Request ID
            expect(cells[2].textContent).toBe(evt.Request_ID__c);
            // Index 3 is Log Level
            expect(cells[3].textContent).toBe(evt.Log_Level__c);
            expect(cells[3].className).toContain('log-level');
            expect(cells[3].className).toContain('level-error');
            // Index 4 is Context
            expect(cells[4].textContent).toBe(evt.Context__c);
        });
    });

    it('handles alternative field names (CreatedById__c, CreatedDate__c)', () => {
        const evt = {
            CreatedById__c: '005000000000002',
            CreatedDate__c: '2021-02-01T00:00:00.000Z',
            Log_Level__c: 'INFO',
            Request_ID__c: 'REQ-456',
            Context__c: 'AltContext'
        };

        const element = createElement('c-rflib-log-event-list-row', {
            is: RflibLogEventListRow
        });
        element.evt = evt;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const dateEl = element.shadowRoot.querySelector('lightning-formatted-date-time');
            expect(dateEl.value).toBe(evt.CreatedDate__c);

            const cells = element.shadowRoot.querySelectorAll('td div');
            expect(cells[1].textContent).toBe(evt.CreatedById__c);
        });
    });

    it('applies correct class for WARN level', () => {
        const evt = {
            Log_Level__c: 'WARN'
        };

        const element = createElement('c-rflib-log-event-list-row', {
            is: RflibLogEventListRow
        });
        element.evt = evt;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const row = element.shadowRoot.querySelector('tr');
            expect(row.className).toContain('level-warn');
        });
    });

    it('applies correct class for DEBUG level', () => {
        const evt = {
            Log_Level__c: 'DEBUG'
        };

        const element = createElement('c-rflib-log-event-list-row', {
            is: RflibLogEventListRow
        });
        element.evt = evt;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const row = element.shadowRoot.querySelector('tr');
            expect(row.className).toContain('level-debug');
        });
    });

    it('applies correct class for TRACE level', () => {
        const evt = {
            Log_Level__c: 'TRACE'
        };

        const element = createElement('c-rflib-log-event-list-row', {
            is: RflibLogEventListRow
        });
        element.evt = evt;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const row = element.shadowRoot.querySelector('tr');
            expect(row.className).toContain('level-trace');
        });
    });

    it('applies default class for unknown level', () => {
        const evt = {
            Log_Level__c: 'UNKNOWN'
        };

        const element = createElement('c-rflib-log-event-list-row', {
            is: RflibLogEventListRow
        });
        element.evt = evt;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const row = element.shadowRoot.querySelector('tr');
            expect(row.className).toContain('level-default');
        });
    });
});
