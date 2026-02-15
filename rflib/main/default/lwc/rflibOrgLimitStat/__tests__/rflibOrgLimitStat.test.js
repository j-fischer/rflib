import { createElement } from 'lwc';
import RflibOrgLimitStat from 'c/rflibOrgLimitStat';
import getOrgLimits from '@salesforce/apex/rflib_OrgLimitsController.getOrgLimits';

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

jest.mock(
    '@salesforce/apex/rflib_OrgLimitsController.getOrgLimits',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

const MOCK_ORG_LIMITS = {
    DailyApiRequests: { currentValue: 5000, totalLimit: 100000 },
    DataStorageMB: { currentValue: 200, totalLimit: 1024 }
};

function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
}

describe('c-rflib-org-limit-stat', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    function createComponent(props = {}) {
        const element = createElement('c-rflib-org-limit-stat', {
            is: RflibOrgLimitStat
        });
        Object.assign(element, { title: 'Daily API Requests', limitName: 'DailyApiRequests', ...props });
        return element;
    }

    it('renders the card with the correct title', async () => {
        getOrgLimits.mockResolvedValue(MOCK_ORG_LIMITS);

        const element = createComponent();
        document.body.appendChild(element);

        await flushPromises();

        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card).not.toBeNull();
        expect(card.title).toBe('Daily API Requests');
    });

    it('fetches and displays org limits on mount', async () => {
        getOrgLimits.mockResolvedValue(MOCK_ORG_LIMITS);

        const element = createComponent();
        document.body.appendChild(element);

        await flushPromises();

        const paragraphs = element.shadowRoot.querySelectorAll('p');
        expect(paragraphs.length).toBeGreaterThan(0);
        expect(paragraphs[0].textContent).toContain('5000');
        expect(paragraphs[0].textContent).toContain('100000');

        const progressBar = element.shadowRoot.querySelector('lightning-progress-bar');
        expect(progressBar).not.toBeNull();
        expect(progressBar.value).toBe(5);
    });

    it('defaults to zero when limit name is not found in results', async () => {
        getOrgLimits.mockResolvedValue(MOCK_ORG_LIMITS);

        const element = createComponent({ limitName: 'NonExistentLimit' });
        document.body.appendChild(element);

        await flushPromises();

        const paragraphs = element.shadowRoot.querySelectorAll('p');
        expect(paragraphs[0].textContent).toContain('0');

        const progressBar = element.shadowRoot.querySelector('lightning-progress-bar');
        expect(progressBar.value).toBe(0);
    });

    it('handles zero total limit without division-by-zero', async () => {
        getOrgLimits.mockResolvedValue({
            TestLimit: { currentValue: 50, totalLimit: 0 }
        });

        const element = createComponent({ limitName: 'TestLimit' });
        document.body.appendChild(element);

        await flushPromises();

        const progressBar = element.shadowRoot.querySelector('lightning-progress-bar');
        expect(progressBar.value).toBe(0);
    });

    it('refreshes data when the refresh button is clicked', async () => {
        getOrgLimits.mockResolvedValue(MOCK_ORG_LIMITS);

        const element = createComponent();
        document.body.appendChild(element);

        await flushPromises();

        // Initial call from connectedCallback
        expect(getOrgLimits).toHaveBeenCalledTimes(1);

        // Update mock for the second call
        getOrgLimits.mockResolvedValue({
            DailyApiRequests: { currentValue: 7500, totalLimit: 100000 }
        });

        const refreshBtn = element.shadowRoot.querySelector('lightning-button-icon');
        refreshBtn.click();

        await flushPromises();

        expect(getOrgLimits).toHaveBeenCalledTimes(2);

        const paragraphs = element.shadowRoot.querySelectorAll('p');
        expect(paragraphs[0].textContent).toContain('7500');
        expect(paragraphs[0].textContent).toContain('100000');
    });

    it('calculates limit progression correctly', async () => {
        getOrgLimits.mockResolvedValue({
            DataStorageMB: { currentValue: 512, totalLimit: 1024 }
        });

        const element = createComponent({ limitName: 'DataStorageMB', title: 'Data Storage' });
        document.body.appendChild(element);

        await flushPromises();

        const progressBar = element.shadowRoot.querySelector('lightning-progress-bar');
        expect(progressBar.value).toBe(50);
    });
});
