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

import { Blob as NodeBlob } from 'buffer';

// jsdom's Blob exposes only size, type and slice, so the downloaded content could not be read back
// off the Blob the download helper builds. Node's Blob is API compatible for that and adds text().
global.Blob = NodeBlob;

describe('c-rflib-log-event-viewer', () => {
    let downloadedBlobs;

    beforeEach(() => {
        // The download is delivered as a Blob behind an object URL, because the Lightning security
        // layer rejects a data: URL on an anchor href. jsdom implements neither URL.createObjectURL
        // nor anchor navigation, so the object URL is captured here and the content read off the Blob.
        downloadedBlobs = [];
        global.URL.createObjectURL = jest.fn((blob) => {
            downloadedBlobs.push(blob);
            return 'blob:rflib/' + downloadedBlobs.length;
        });
        global.URL.revokeObjectURL = jest.fn();
    });

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
            Log_Messages__c: 'Message 1\nMessage 2',
            Log_Source__c: 'Apex',
            Stacktrace__c: 'Class.Foo.bar: line 1, column 1'
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

            const staticFields = element.shadowRoot.querySelectorAll('.slds-form-element__static');
            const logSourceField = Array.from(staticFields).find(
                (field) => field.textContent === logEvent.Log_Source__c
            );
            expect(logSourceField).toBeTruthy();

            const stacktrace = element.shadowRoot.querySelector('.stacktrace pre code');
            expect(stacktrace.textContent).toBe(logEvent.Stacktrace__c);
        });
    });

    it('displays a placeholder when the log event has no stacktrace', () => {
        const element = createElement('c-rflib-log-event-viewer', {
            is: RflibLogEventViewer
        });

        getApexLogsForRequestId.mockResolvedValue([]);

        // Records archived before the Stacktrace field existed have no value
        element.logEvent = {
            Request_ID__c: 'REQ-123',
            Log_Level__c: 'INFO',
            Context__c: 'TestContext',
            Platform_Info__c: '{}',
            Log_Messages__c: 'Message 1'
        };
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const stacktrace = element.shadowRoot.querySelector('.stacktrace pre code');
            expect(stacktrace.textContent).toBe('No stacktrace available.');
        });
    });

    it('loads apex logs', () => {
        const element = createElement('c-rflib-log-event-viewer', {
            is: RflibLogEventViewer
        });

        getApexLogsForRequestId.mockResolvedValue([
            { id: '07L000000000001AAA', menuLabel: 'Apex Debug Log 0', menuTitle: 'Apex debug log details' },
            { id: '07L000000000002AAA', menuLabel: 'Apex Debug Log 1', menuTitle: 'Apex debug log details' }
        ]);

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
        getApexLogsForRequestId.mockResolvedValue([
            { id: '07L000000000001AAA', menuLabel: 'Apex Debug Log 0', menuTitle: 'Apex debug log details' }
        ]);

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
            // The log file is delivered as a Blob behind an object URL, so the anchor's href is
            // opaque and the content is read back off the captured Blob.
            const clickSpy = jest.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => {});

            const menu = element.shadowRoot.querySelector('lightning-button-menu');
            expect(menu).not.toBeNull();

            menu.dispatchEvent(new CustomEvent('select', { detail: { value: 'rflib-log' } }));

            return Promise.resolve()
                .then(() => {
                    expect(clickSpy).toHaveBeenCalled();
                    expect(global.URL.createObjectURL).toHaveBeenCalledWith(expect.any(Blob));
                    return downloadedBlobs[0].text();
                })
                .then((logFile) => {
                    expect(logFile).toContain('LogContent');
                    clickSpy.mockRestore();
                });
        });
    });
});
