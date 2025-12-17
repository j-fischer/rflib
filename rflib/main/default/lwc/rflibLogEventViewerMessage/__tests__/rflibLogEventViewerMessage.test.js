import { createElement } from 'lwc';
import RflibLogEventViewerMessage from 'c/rflibLogEventViewerMessage';

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

describe('c-rflib-log-event-viewer-message', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders simple text message', () => {
        const element = createElement('c-rflib-log-event-viewer-message', {
            is: RflibLogEventViewerMessage
        });

        element.message = {
            id: 1,
            content: 'Simple log message',
            lineId: 1, // odd -> dark
            isText: true
        };

        element.fieldVisibility = {
            showDate: true,
            showLogLevel: true,
            showCreatedBy: true,
            showRequestId: true,
            showContext: true
        };

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const formattedText = element.shadowRoot.querySelector('lightning-formatted-text');
            expect(formattedText).not.toBeNull();
            expect(formattedText.value).toBe('Simple log message');

            const wrapper = element.shadowRoot.querySelector('.wrapper');
            expect(wrapper.className).toContain('dark');
        });
    });

    it('renders structured message with all fields visible', () => {
        const element = createElement('c-rflib-log-event-viewer-message', {
            is: RflibLogEventViewerMessage
        });

        // date|level|user|req|ctx|msg
        const content = '2021-01-01|INFO|User1|Req1|Ctx1|Actual Message';

        element.message = {
            id: 2,
            content: content,
            lineId: 2, // even -> light
            isText: true
        };

        element.fieldVisibility = {
            showDate: true,
            showLogLevel: true,
            showCreatedBy: true,
            showRequestId: true,
            showContext: true
        };

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const formattedText = element.shadowRoot.querySelector('lightning-formatted-text');
            expect(formattedText.value).toBe('2021-01-01 | INFO | User1 | Req1 | Ctx1 | Actual Message');

            const wrapper = element.shadowRoot.querySelector('.wrapper');
            expect(wrapper.className).toContain('light');
        });
    });

    it('hides fields based on visibility settings', () => {
        const element = createElement('c-rflib-log-event-viewer-message', {
            is: RflibLogEventViewerMessage
        });

        const content = '2021-01-01|INFO|User1|Req1|Ctx1|Actual Message';

        element.message = {
            id: 3,
            content: content,
            lineId: 3,
            isText: true
        };

        // Hide all except message
        element.fieldVisibility = {
            showDate: false,
            showLogLevel: false,
            showCreatedBy: false,
            showRequestId: false,
            showContext: false
        };

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const formattedText = element.shadowRoot.querySelector('lightning-formatted-text');
            expect(formattedText.value).toBe('Actual Message');
        });
    });

    it('renders JSON message with expand/collapse capability', () => {
        const element = createElement('c-rflib-log-event-viewer-message', {
            is: RflibLogEventViewerMessage
        });

        const jsonContent = '{"key":"value"}';
        const formattedJson = '{\n  "key": "value"\n}';

        element.message = {
            id: 4,
            content: jsonContent,
            isJson: true,
            isText: false,
            formattedJson: formattedJson,
            preview: '{"key":"value"}',
            lineId: 4
        };

        element.fieldVisibility = {};

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            // Check preview mode
            const preview = element.shadowRoot.querySelector('.json-label');
            expect(preview).not.toBeNull();
            expect(preview.textContent).toBe('{"key":"value"}');

            // Click expand button
            const button = element.shadowRoot.querySelector('lightning-button-icon');
            button.click();
        })
        .then(() => {
            // Check expanded mode
            const pre = element.shadowRoot.querySelector('pre');
            expect(pre).not.toBeNull();
            expect(pre.textContent).toBe(formattedJson);

            // Click collapse button
            const button = element.shadowRoot.querySelector('lightning-button-icon');
            button.click();
        })
        .then(() => {
            // Back to preview
            const pre = element.shadowRoot.querySelector('pre');
            expect(pre).toBeNull();
            const preview = element.shadowRoot.querySelector('.json-label');
            expect(preview).not.toBeNull();
        });
    });
});
