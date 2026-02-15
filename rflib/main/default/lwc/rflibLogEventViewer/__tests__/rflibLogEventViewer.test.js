import { createElement } from 'lwc';
import RflibLogEventViewer from 'c/rflibLogEventViewer';
import getApexLogsForRequestId from '@salesforce/apex/rflib_LogEventViewerController.getApexLogsForRequestId';
import { getRecord } from 'lightning/uiRecordApi';

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

// Mock Apex
jest.mock(
    '@salesforce/apex/rflib_LogEventViewerController.getApexLogsForRequestId',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

const mockGetRecord = require('lightning/uiRecordApi').getRecord;

describe('c-rflib-log-event-viewer', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders log event details', () => {
        const element = createElement('c-rflib-log-event-viewer', {
            is: RflibLogEventViewer
        });

        // Ensure mock returns promise (even if empty) to avoid undefined errors
        getApexLogsForRequestId.mockResolvedValue([]);

        const logEvent = {
            Request_ID__c: 'REQ-123',
            Log_Level__c: 'INFO',
            Context__c: 'TestContext',
            CreatedById: '005User',
            CreatedDate: '2021-01-01',
            Platform_Info__c: '{"Browser": "Chrome"}',
            Log_Messages__c: 'Message 1\nMessage 2'
        };

        element.logEvent = logEvent;
        element.userId = '005User';
        document.body.appendChild(element);

        // Mock getRecord response
        mockGetRecord.emit({
            fields: {
                Name: { value: 'Test User' },
                Phone: { value: '555-1234' },
                Email: { value: 'test@example.com' },
                Profile: {
                    value: {
                        fields: { Name: { value: 'System Administrator' } }
                    }
                }
            }
        });

        return Promise.resolve().then(() => {
            const card = element.shadowRoot.querySelector('lightning-card');
            expect(card.title).toBe('REQ-123 - INFO - TestContext');

            // Check messages are processed
            const messages = element.shadowRoot.querySelectorAll('c-rflib-log-event-viewer-message');
            expect(messages.length).toBe(2);
        });
    });

    it('loads apex logs', () => {
        const element = createElement('c-rflib-log-event-viewer', {
            is: RflibLogEventViewer
        });

        getApexLogsForRequestId.mockResolvedValue(['Log1', 'Log2']);

        const logEvent = {
            Request_ID__c: 'REQ-123',
            Log_Messages__c: '',
            Platform_Info__c: '{}'
        };

        element.logEvent = logEvent;
        document.body.appendChild(element);

        // Wait for microtasks
        return Promise.resolve().then(() => {
            expect(getApexLogsForRequestId).toHaveBeenCalledWith({ requestId: 'REQ-123' });
        });
    });

    it('handles download actions', () => {
        const element = createElement('c-rflib-log-event-viewer', {
            is: RflibLogEventViewer
        });

        // We need apex logs to show the menu
        getApexLogsForRequestId.mockResolvedValue(['LogId1']);

        const logEvent = {
            Request_ID__c: 'REQ-123',
            Log_Messages__c: 'LogContent',
            Platform_Info__c: '{}',
            CreatedById: 'User1',
            CreatedDate: '2021-01-01',
            Context__c: 'Ctx'
        };

        element.logEvent = logEvent;
        document.body.appendChild(element);

        // Wait for apex logs to load
        return Promise.resolve().then(() => {
            // Mock window.URL.createObjectURL or simulated click
            const clickSpy = jest.fn();

            // Use real element to pass type checks
            const realCreateElement = document.createElement.bind(document);
            jest.spyOn(document, 'createElement').mockImplementation((tagName) => {
                const el = realCreateElement(tagName);
                if (tagName === 'a') {
                    // We can't overwrite click easily on DOM element in some envs, but let's try
                    // Or just spy on it
                    el.click = clickSpy;
                }
                return el;
            });

            // Find the menu - it should be visible now
            const menu = element.shadowRoot.querySelector('lightning-button-menu');
            expect(menu).not.toBeNull();

            menu.dispatchEvent(new CustomEvent('select', { detail: { value: 'rflib-log' } }));

            return Promise.resolve().then(() => {
                expect(document.createElement).toHaveBeenCalledWith('a');
                expect(clickSpy).toHaveBeenCalled();
            });
        });
    });
});
