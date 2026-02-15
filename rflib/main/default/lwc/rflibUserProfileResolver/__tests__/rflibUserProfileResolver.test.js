import { createElement } from 'lwc';
import RflibUserProfileResolver from 'c/rflibUserProfileResolver';
import getUserByUserId from '@salesforce/apex/rflib_UserProfileResolverController.getUserByUserId';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

// Mock Apex
jest.mock('@salesforce/apex/rflib_UserProfileResolverController.getUserByUserId', () => ({ default: jest.fn() }), {
    virtual: true
});

// Mock Logger
jest.mock('c/rflibLogger', () => ({
    createLogger: jest.fn(() => ({
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn()
    }))
}));

async function flushPromises() {
    return Promise.resolve();
}

describe('c-rflib-user-profile-resolver', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    function createComponent() {
        const element = createElement('c-rflib-user-profile-resolver', {
            is: RflibUserProfileResolver
        });
        document.body.appendChild(element);
        return element;
    }

    it('renders the find user profile button and hides modal by default', () => {
        const element = createComponent();

        const button = element.shadowRoot.querySelector('lightning-button');
        expect(button).not.toBeNull();
        expect(button.label).toBe('Find user profile');

        // Modal should not be visible
        const modal = element.shadowRoot.querySelector('section[role="dialog"]');
        expect(modal).toBeNull();
    });

    it('opens modal when find user profile button is clicked', async () => {
        const element = createComponent();

        const button = element.shadowRoot.querySelector('lightning-button');
        button.click();
        await flushPromises();

        const modal = element.shadowRoot.querySelector('section[role="dialog"]');
        expect(modal).not.toBeNull();

        const heading = element.shadowRoot.querySelector('h2');
        expect(heading.textContent).toBe('Find User Profile');
    });

    it('closes modal when Cancel button is clicked', async () => {
        const element = createComponent();

        // Open modal
        const openButton = element.shadowRoot.querySelector('lightning-button');
        openButton.click();
        await flushPromises();

        // Click Cancel
        const cancelButton = element.shadowRoot.querySelector('button[title="Cancel"]');
        cancelButton.click();
        await flushPromises();

        const modal = element.shadowRoot.querySelector('section[role="dialog"]');
        expect(modal).toBeNull();
    });

    it('closes modal when close (X) button is clicked', async () => {
        const element = createComponent();

        // Open modal
        const openButton = element.shadowRoot.querySelector('lightning-button');
        openButton.click();
        await flushPromises();

        // Click close button
        const closeButton = element.shadowRoot.querySelector('button[title="Close"]');
        closeButton.click();
        await flushPromises();

        const modal = element.shadowRoot.querySelector('section[role="dialog"]');
        expect(modal).toBeNull();
    });

    it('updates userId when record picker selection changes', async () => {
        const element = createComponent();

        // Open modal to access the record picker
        const openButton = element.shadowRoot.querySelector('lightning-button');
        openButton.click();
        await flushPromises();

        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        expect(recordPicker).not.toBeNull();

        // Simulate user selection
        recordPicker.dispatchEvent(
            new CustomEvent('change', {
                detail: { recordId: '005000000000001' }
            })
        );
        await flushPromises();

        // Selecting the same user again should not cause issues
        recordPicker.dispatchEvent(
            new CustomEvent('change', {
                detail: { recordId: '005000000000001' }
            })
        );
        await flushPromises();

        // Selecting a different user
        recordPicker.dispatchEvent(
            new CustomEvent('change', {
                detail: { recordId: '005000000000002' }
            })
        );
        await flushPromises();
    });

    it('dispatches profileselected event and closes modal on successful insert', async () => {
        const mockUser = {
            Id: '005000000000001',
            Name: 'Test User',
            Profile: { Name: 'System Administrator' }
        };
        getUserByUserId.mockResolvedValue(mockUser);

        const element = createComponent();

        const profileSelectedHandler = jest.fn();
        element.addEventListener('profileselected', profileSelectedHandler);

        // Open modal
        const openButton = element.shadowRoot.querySelector('lightning-button');
        openButton.click();
        await flushPromises();

        // Select a user
        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        recordPicker.dispatchEvent(
            new CustomEvent('change', {
                detail: { recordId: '005000000000001' }
            })
        );
        await flushPromises();

        // Click Insert
        const insertButton = element.shadowRoot.querySelector('button[title="OK"]');
        insertButton.click();

        await flushPromises();
        await flushPromises();

        // Verify Apex was called
        expect(getUserByUserId).toHaveBeenCalledWith({ userId: '005000000000001' });

        // Verify profileselected event was dispatched with profile name
        expect(profileSelectedHandler).toHaveBeenCalledTimes(1);
        expect(profileSelectedHandler.mock.calls[0][0].detail).toBe('System Administrator');

        // Modal should be closed
        const modal = element.shadowRoot.querySelector('section[role="dialog"]');
        expect(modal).toBeNull();
    });

    it('shows error toast and closes modal on failed insert', async () => {
        const mockError = { body: { message: 'User not found' } };
        getUserByUserId.mockRejectedValue(mockError);

        const element = createComponent();

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Open modal
        const openButton = element.shadowRoot.querySelector('lightning-button');
        openButton.click();
        await flushPromises();

        // Click Insert (without selecting a user, userId is empty string)
        const insertButton = element.shadowRoot.querySelector('button[title="OK"]');
        insertButton.click();

        await flushPromises();
        await flushPromises();

        // Verify error toast was dispatched
        expect(toastHandler).toHaveBeenCalledTimes(1);
        const toastDetail = toastHandler.mock.calls[0][0].detail;
        expect(toastDetail.title).toBe('Failed to retrieve permissions');
        expect(toastDetail.variant).toBe('error');

        // Modal should be closed (finally block)
        const modal = element.shadowRoot.querySelector('section[role="dialog"]');
        expect(modal).toBeNull();
    });

    it('renders record picker with correct filter and matching info', async () => {
        const element = createComponent();

        // Open modal
        const openButton = element.shadowRoot.querySelector('lightning-button');
        openButton.click();
        await flushPromises();

        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        expect(recordPicker.objectApiName).toBe('User');
        expect(recordPicker.label).toBe('Select a user');
        expect(recordPicker.filter).toEqual({
            criteria: [
                {
                    fieldPath: 'IsActive',
                    operator: 'eq',
                    value: true
                }
            ]
        });
        expect(recordPicker.matchingInfo).toEqual({
            primaryField: { fieldPath: 'Name' }
        });
    });
});
