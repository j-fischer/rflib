import { createElement } from 'lwc';
import RflibLogArchiveAlert from 'c/rflibLogArchiveAlert';
import getRecentLogSummary from '@salesforce/apex/rflib_LogArchiveController.getRecentLogSummary';
import { getNavigateCalledWith } from 'lightning/navigation';

jest.mock('c/rflibLogger', () => {
    return {
        createLogger: jest.fn(() => ({
            debug: jest.fn(),
            info: jest.fn(),
            warn: jest.fn(),
            error: jest.fn(),
            fatal: jest.fn()
        }))
    };
});

jest.mock(
    '@salesforce/apex/rflib_LogArchiveController.getRecentLogSummary',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
}

describe('c-rflib-log-archive-alert', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    function createComponent(props = {}) {
        const element = createElement('c-rflib-log-archive-alert', {
            is: RflibLogArchiveAlert
        });
        Object.assign(element, props);
        document.body.appendChild(element);
        return element;
    }

    it('renders a banner with per-level counts and a Log Monitor link when matches exist', async () => {
        const element = createComponent();

        getRecentLogSummary.emit({
            lookbackHours: 24,
            totalCount: 7,
            levelCounts: [
                { level: 'ERROR', count: 2 },
                { level: 'WARN', count: 5 }
            ]
        });

        await flushPromises();

        const banner = element.shadowRoot.querySelector('.slds-notify_alert');
        expect(banner).not.toBeNull();
        expect(banner.textContent).toContain('2 ERROR');
        expect(banner.textContent).toContain('5 WARN');
        expect(banner.textContent).toContain('24 hours');

        const link = element.shadowRoot.querySelector('a');
        expect(link).not.toBeNull();
    });

    it('renders nothing when there are no matching log events', async () => {
        const element = createComponent();

        getRecentLogSummary.emit({
            lookbackHours: 24,
            totalCount: 0,
            levelCounts: []
        });

        await flushPromises();

        expect(element.shadowRoot.querySelector('.slds-notify_alert')).toBeNull();
    });

    it('renders nothing when the summary query fails', async () => {
        const element = createComponent();

        getRecentLogSummary.error();

        await flushPromises();

        expect(element.shadowRoot.querySelector('.slds-notify_alert')).toBeNull();
    });

    it('navigates to the Log Monitor tab when the link is clicked', async () => {
        const element = createComponent();

        getRecentLogSummary.emit({
            lookbackHours: 24,
            totalCount: 1,
            levelCounts: [{ level: 'FATAL', count: 1 }]
        });

        await flushPromises();

        const link = element.shadowRoot.querySelector('a');
        link.click();

        await flushPromises();

        expect(getNavigateCalledWith()).toEqual({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'rflib_Log_Monitor'
            }
        });
    });

    it('uses the error theme when severe levels are present', async () => {
        const element = createComponent();

        getRecentLogSummary.emit({
            lookbackHours: 24,
            totalCount: 1,
            levelCounts: [{ level: 'ERROR', count: 1 }]
        });

        await flushPromises();

        const banner = element.shadowRoot.querySelector('.slds-notify_alert');
        expect(banner.classList).toContain('slds-theme_error');
    });

    it('uses the warning theme when only WARN entries are present', async () => {
        const element = createComponent();

        getRecentLogSummary.emit({
            lookbackHours: 12,
            totalCount: 3,
            levelCounts: [{ level: 'WARN', count: 3 }]
        });

        await flushPromises();

        const banner = element.shadowRoot.querySelector('.slds-notify_alert');
        expect(banner.classList).toContain('slds-theme_warning');
        expect(banner.textContent).toContain('12 hours');
    });

    it('passes configured properties to the wired Apex method', async () => {
        createComponent({ lookbackHours: 48, logLevels: 'ERROR' });

        await flushPromises();

        const config = getRecentLogSummary.getLastConfig();
        expect(config).toEqual({ lookbackHours: 48, logLevels: 'ERROR' });
    });
});
