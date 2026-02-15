import { createElement } from 'lwc';
import RflibLogEventList from 'c/rflibLogEventList';

const MOCK_LOG_EVENTS = [
    {
        id: 0,
        CreatedById: '005000000001',
        CreatedDate: '2021-01-01T00:00:00.000Z',
        Log_Level__c: 'ERROR',
        Context__c: 'Referral',
        Request_ID__c: 'REQ-001',
        Log_Messages__c: 'Error occurred'
    },
    {
        id: 1,
        CreatedById: '005000000002',
        CreatedDate: '2021-01-01T00:01:00.000Z',
        Log_Level__c: 'INFO',
        Context__c: 'Payment',
        Request_ID__c: 'REQ-002',
        Log_Messages__c: 'Payment processed'
    },
    {
        id: 2,
        CreatedById: '005000000001',
        CreatedDate: '2021-01-01T00:02:00.000Z',
        Log_Level__c: 'DEBUG',
        Context__c: 'Referral',
        Request_ID__c: 'REQ-003',
        Log_Messages__c: 'Debug info'
    }
];

// Mock c/rflibLogger
jest.mock('c/rflibLogger', () => {
    return {
        createLogger: jest.fn(() => ({
            debug: jest.fn(),
            error: jest.fn(),
            info: jest.fn(),
            warn: jest.fn(),
            fatal: jest.fn()
        }))
    };
});

describe('c-rflib-log-event-list', () => {
    afterEach(() => {
        jest.clearAllMocks();
    });

    it('renders and displays logs (empty state)', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });

        element.pageSize = 10;
        element.logEvents = [];
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
            expect(rows.length).toBe(0);

            const card = element.shadowRoot.querySelector('lightning-card');
            expect(card.title).toBe('0 Displayed Log Events');
        });
    });

    it('renders and displays logs with data', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });

        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
            expect(rows.length).toBe(3);

            const card = element.shadowRoot.querySelector('lightning-card');
            expect(card.title).toBe('3 Displayed Log Events'); // Assuming title format matches the implementation
        });
    });

    it('handles pagination correctly', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });

        element.pageSize = 2; // Set small page size
        element.logEvents = MOCK_LOG_EVENTS; // 3 events total
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(2); // First page

                // Change page
                element.currentPage = 2;
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(1); // Second page
            });
    });

    it('filters logs by request ID', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });

        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="requestId"]');
                input.value = 'REQ-002';
                input.dispatchEvent(new CustomEvent('change'));

                const searchBtn = element.shadowRoot.querySelector('lightning-button');
                searchBtn.click();
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(1);
                // Accessing the custom element's public property or checking passed data would be ideal,
                // but checking length confirms filtering happened.
            });
    });

    it('filters logs by Created By', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });

        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="createdBy"]');
                input.value = '005000000001';
                input.dispatchEvent(new CustomEvent('change'));

                const searchBtn = element.shadowRoot.querySelector('lightning-button');
                searchBtn.click();
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(2);
            });
    });

    it('filters logs by Level', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });

        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="level"]');
                input.value = 'ERROR';
                input.dispatchEvent(new CustomEvent('change'));

                const searchBtn = element.shadowRoot.querySelector('lightning-button');
                searchBtn.click();
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(1);
            });
    });

    it('filters logs by Context', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });

        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="context"]');
                input.value = 'Referral';
                input.dispatchEvent(new CustomEvent('change'));

                const searchBtn = element.shadowRoot.querySelector('lightning-button');
                searchBtn.click();
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(2);
            });
    });

    it('filters logs by Log Message', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });

        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="logMessage"]');
                input.value = 'Payment';
                input.dispatchEvent(new CustomEvent('change'));

                const searchBtn = element.shadowRoot.querySelector('lightning-button');
                searchBtn.click();
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(1);
            });
    });

    it('handles row selection', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });

        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('logselected', handler);

        return Promise.resolve()
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                rows[0].click();
            })
            .then(() => {
                expect(handler).toHaveBeenCalled();
                const detail = JSON.parse(handler.mock.calls[0][0].detail);
                expect(detail.id).toBe(0);
            });
    });

    it('executes search on enter key press', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="createdBy"]');
                input.value = '005000000001';
                input.dispatchEvent(new CustomEvent('change'));

                // Simulate Enter key press
                const keyEvent = new KeyboardEvent('keypress', { which: 13, bubbles: true, composed: true });
                input.closest('div').dispatchEvent(keyEvent);
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(2);
            });
    });

    // Test for other key presses (should verify coverage for handleKey* methods)
    it('executes search on enter key press for other fields', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="level"]');
                input.value = 'ERROR';
                input.dispatchEvent(new CustomEvent('change'));

                const keyEvent = new KeyboardEvent('keypress', { which: 13, bubbles: true, composed: true });
                input.closest('div').dispatchEvent(keyEvent);
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(1);
            });
    });

    it('executes search on enter key press for context', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="context"]');
                input.value = 'Referral';
                input.dispatchEvent(new CustomEvent('change'));

                const keyEvent = new KeyboardEvent('keypress', { which: 13, bubbles: true, composed: true });
                input.closest('div').dispatchEvent(keyEvent);
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(2);
            });
    });

    it('executes search on enter key press for request id', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="requestId"]');
                input.value = 'REQ-002';
                input.dispatchEvent(new CustomEvent('change'));

                const keyEvent = new KeyboardEvent('keypress', { which: 13, bubbles: true, composed: true });
                input.closest('div').dispatchEvent(keyEvent);
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(1);
            });
    });

    it('executes search on enter key press for log message', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        element.pageSize = 10;
        element.logEvents = MOCK_LOG_EVENTS;
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="logMessage"]');
                input.value = 'Payment';
                input.dispatchEvent(new CustomEvent('change'));

                const keyEvent = new KeyboardEvent('keypress', { which: 13, bubbles: true, composed: true });
                input.closest('div').dispatchEvent(keyEvent);
            })
            .then(() => {
                const rows = element.shadowRoot.querySelectorAll('c-rflib-log-event-list-row');
                expect(rows.length).toBe(1);
            });
    });

    it('updates focus state on search fields', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('lightning-input[data-field="createdBy"]');
            input.dispatchEvent(new CustomEvent('focus'));

            return Promise.resolve().then(() => {
                const container = input.closest('div');
                expect(container.className).toContain('search-field-expanded');
            });
        });
    });

    it('updates focus state on other search fields', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('lightning-input[data-field="level"]');
            input.dispatchEvent(new CustomEvent('focus'));

            return Promise.resolve().then(() => {
                const container = input.closest('div');
                expect(container.className).toContain('search-field-expanded');
            });
        });
    });

    it('updates focus state on context search field', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('lightning-input[data-field="context"]');
            input.dispatchEvent(new CustomEvent('focus'));

            return Promise.resolve().then(() => {
                const container = input.closest('div');
                expect(container.className).toContain('search-field-expanded');
            });
        });
    });

    it('updates focus state on request ID search field', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('lightning-input[data-field="requestId"]');
            input.dispatchEvent(new CustomEvent('focus'));

            return Promise.resolve().then(() => {
                const container = input.closest('div');
                expect(container.className).toContain('search-field-expanded');
            });
        });
    });

    it('updates focus state on log message search field', () => {
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const input = element.shadowRoot.querySelector('lightning-input[data-field="logMessage"]');
            input.dispatchEvent(new CustomEvent('focus'));

            return Promise.resolve().then(() => {
                const container = input.closest('div');
                expect(container.className).toContain('search-field-expanded');
            });
        });
    });

    it('clears focus on blur', () => {
        jest.useFakeTimers();
        const element = createElement('c-rflib-log-event-list', {
            is: RflibLogEventList
        });
        document.body.appendChild(element);

        return Promise.resolve()
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="createdBy"]');
                input.dispatchEvent(new CustomEvent('focus'));

                return Promise.resolve();
            })
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="createdBy"]');
                input.dispatchEvent(new CustomEvent('blur'));
                jest.runAllTimers();

                return Promise.resolve();
            })
            .then(() => {
                const input = element.shadowRoot.querySelector('lightning-input[data-field="createdBy"]');
                const container = input.closest('div');
                expect(container.className).toContain('slds-size_1-of-6'); // Default class
            });
    });
});
