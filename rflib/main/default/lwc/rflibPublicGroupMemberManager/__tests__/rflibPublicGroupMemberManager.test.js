import { createElement } from 'lwc';
import RflibPublicGroupMemberManager from 'c/rflibPublicGroupMemberManager';
import canUserModifyGroupMemberships from '@salesforce/apex/rflib_PublicGroupMemberManagerController.canUserModifyGroupMemberships';
import getGroupMembers from '@salesforce/apex/rflib_PublicGroupMemberManagerController.getGroupMembers';
import addUserToGroup from '@salesforce/apex/rflib_PublicGroupMemberManagerController.addUserToGroup';
import removeUserFromGroup from '@salesforce/apex/rflib_PublicGroupMemberManagerController.removeUserFromGroup';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

// Mock all four imperative Apex methods
jest.mock(
    '@salesforce/apex/rflib_PublicGroupMemberManagerController.canUserModifyGroupMemberships',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock('@salesforce/apex/rflib_PublicGroupMemberManagerController.getGroupMembers', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/rflib_PublicGroupMemberManagerController.addUserToGroup', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock(
    '@salesforce/apex/rflib_PublicGroupMemberManagerController.removeUserFromGroup',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

// Mock Logger
jest.mock(
    'c/rflibLogger',
    () => ({
        createLogger: jest.fn(() => ({
            debug: jest.fn(),
            error: jest.fn()
        }))
    }),
    { virtual: true }
);

// Mock data
const MOCK_GROUP_MEMBERS = [
    { Id: 'user1', Name: 'Alice Smith', Email: 'alice@test.com' },
    { Id: 'user2', Name: 'Bob Jones', Email: 'bob@test.com' }
];

async function flushPromises() {
    return Promise.resolve();
}

describe('c-rflib-public-group-member-manager', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        canUserModifyGroupMemberships.mockReset();
        getGroupMembers.mockReset();
        addUserToGroup.mockReset();
        removeUserFromGroup.mockReset();
    });

    function createComponent(props = {}) {
        const element = createElement('c-rflib-public-group-member-manager', {
            is: RflibPublicGroupMemberManager
        });
        Object.assign(element, props);
        document.body.appendChild(element);
        return element;
    }

    async function createInitializedComponent(props = {}, { canModify = true } = {}) {
        canUserModifyGroupMemberships.mockResolvedValue(canModify);
        getGroupMembers.mockResolvedValue(MOCK_GROUP_MEMBERS);

        const element = createComponent(props);
        await flushPromises();
        await flushPromises();
        return element;
    }

    // --- Initialization & Rendering ---

    it('renders title and datatable with group members after initialization', async () => {
        const element = await createInitializedComponent({
            title: 'My Group',
            groupApiName: 'TestGroup'
        });

        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card.title).toBe('My Group');

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toEqual(MOCK_GROUP_MEMBERS);

        expect(getGroupMembers).toHaveBeenCalledWith({ groupApiName: 'TestGroup' });
    });

    it('includes action column and shows user picker when user has modify permission', async () => {
        const element = await createInitializedComponent(
            { title: 'Admin Group', groupApiName: 'AdminGroup' },
            { canModify: true }
        );

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        // Should have 3 columns: Name, Email, and Action
        expect(datatable.columns).toHaveLength(3);
        expect(datatable.columns[2].type).toBe('action');

        // User picker and Add button should be visible
        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        expect(recordPicker).not.toBeNull();

        const addButton = element.shadowRoot.querySelector('lightning-button');
        expect(addButton).not.toBeNull();
        expect(addButton.label).toBe('Add User');
    });

    it('excludes action column and hides user picker when user lacks modify permission', async () => {
        const element = await createInitializedComponent(
            { title: 'Read Only Group', groupApiName: 'ReadOnlyGroup' },
            { canModify: false }
        );

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        // Should have only 2 columns: Name and Email
        expect(datatable.columns).toHaveLength(2);
        expect(datatable.columns[0].label).toBe('Name');
        expect(datatable.columns[1].label).toBe('Email');

        // User picker and Add button should NOT be visible
        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        expect(recordPicker).toBeNull();

        const addButton = element.shadowRoot.querySelector('lightning-button');
        expect(addButton).toBeNull();
    });

    // --- Error handling on init ---

    it('shows error toast when permission check fails', async () => {
        canUserModifyGroupMemberships.mockRejectedValue({ body: { message: 'Permission denied' } });
        getGroupMembers.mockResolvedValue([]);

        const element = createComponent({ groupApiName: 'TestGroup' });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Error');
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('Permission denied');
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
    });

    it('shows error toast when loading group members fails', async () => {
        canUserModifyGroupMemberships.mockResolvedValue(true);
        getGroupMembers.mockRejectedValue({ body: { message: 'Load failed' } });

        const element = createComponent({ groupApiName: 'TestGroup' });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Error');
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('Failed to load group members.');
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
    });

    // --- User selection behavior ---

    it('enables Add button when a user is selected and disables it when cleared', async () => {
        const element = await createInitializedComponent({ groupApiName: 'TestGroup' }, { canModify: true });

        const addButton = element.shadowRoot.querySelector('lightning-button');
        expect(addButton.disabled).toBe(true);

        // Select a user
        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        recordPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000001' } }));
        await flushPromises();

        expect(addButton.disabled).toBe(false);

        // Clear selection
        recordPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: null } }));
        await flushPromises();

        expect(addButton.disabled).toBe(true);
    });

    // --- Add user flow ---

    it('adds user to group, shows success toast, and reloads members', async () => {
        addUserToGroup.mockResolvedValue();
        const reloadMembers = [
            ...MOCK_GROUP_MEMBERS,
            { Id: 'user3', Name: 'Charlie Brown', Email: 'charlie@test.com' }
        ];

        const element = await createInitializedComponent({ groupApiName: 'TestGroup' }, { canModify: true });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Select a user
        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        recordPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000003' } }));
        await flushPromises();

        // Set up the reload to return updated members
        getGroupMembers.mockResolvedValue(reloadMembers);

        // Click Add User
        const addButton = element.shadowRoot.querySelector('lightning-button');
        addButton.click();
        await flushPromises();
        await flushPromises();

        expect(addUserToGroup).toHaveBeenCalledWith({ groupApiName: 'TestGroup', userId: '005xx000003' });
        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Success');
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');

        // Members should reload
        await flushPromises();
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable.data).toEqual(reloadMembers);
    });

    it('shows error toast when adding user fails', async () => {
        addUserToGroup.mockRejectedValue({ body: { message: 'Duplicate member' } });

        const element = await createInitializedComponent({ groupApiName: 'TestGroup' }, { canModify: true });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Select a user and click Add
        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        recordPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000003' } }));
        await flushPromises();

        const addButton = element.shadowRoot.querySelector('lightning-button');
        addButton.click();
        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Error');
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('Duplicate member');
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
    });

    it('shows fallback error message when adding user fails without body message', async () => {
        addUserToGroup.mockRejectedValue({ body: {} });

        const element = await createInitializedComponent({ groupApiName: 'TestGroup' }, { canModify: true });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        recordPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000003' } }));
        await flushPromises();

        const addButton = element.shadowRoot.querySelector('lightning-button');
        addButton.click();
        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('Failed to add user to the group.');
    });

    // --- Remove user flow ---

    it('opens confirmation dialog on remove row action', async () => {
        const element = await createInitializedComponent({ groupApiName: 'TestGroup' }, { canModify: true });

        // Trigger remove row action
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: { row: { Id: 'user1' }, action: { name: 'remove' } }
            })
        );
        await flushPromises();

        // Confirmation dialog should be visible
        const dialog = element.shadowRoot.querySelector('c-rflib-confirmation-dialog');
        expect(dialog).not.toBeNull();
        expect(dialog.visible).toBe(true);
        expect(dialog.title).toBe('Confirm Removal');
    });

    it('confirms removal, shows success toast, and reloads members', async () => {
        removeUserFromGroup.mockResolvedValue();
        const updatedMembers = [MOCK_GROUP_MEMBERS[1]]; // Only Bob remains

        const element = await createInitializedComponent({ groupApiName: 'TestGroup' }, { canModify: true });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Trigger remove row action
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: { row: { Id: 'user1' }, action: { name: 'remove' } }
            })
        );
        await flushPromises();

        // Set up reload to return updated members
        getGroupMembers.mockResolvedValue(updatedMembers);

        // Confirm the removal via modal action
        const dialog = element.shadowRoot.querySelector('c-rflib-confirmation-dialog');
        dialog.dispatchEvent(
            new CustomEvent('modalaction', {
                detail: { status: 'confirm' }
            })
        );
        await flushPromises();
        await flushPromises();

        expect(removeUserFromGroup).toHaveBeenCalledWith({ groupApiName: 'TestGroup', userId: 'user1' });
        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Success');
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');

        // Members should reload
        await flushPromises();
        expect(datatable.data).toEqual(updatedMembers);
    });

    it('shows error toast when removal fails', async () => {
        removeUserFromGroup.mockRejectedValue({ body: { message: 'Cannot remove owner' } });

        const element = await createInitializedComponent({ groupApiName: 'TestGroup' }, { canModify: true });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Trigger remove row action
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: { row: { Id: 'user1' }, action: { name: 'remove' } }
            })
        );
        await flushPromises();

        // Confirm the removal
        const dialog = element.shadowRoot.querySelector('c-rflib-confirmation-dialog');
        dialog.dispatchEvent(
            new CustomEvent('modalaction', {
                detail: { status: 'confirm' }
            })
        );
        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Error');
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('Cannot remove owner');
    });

    it('cancels removal and hides dialog without calling Apex', async () => {
        const element = await createInitializedComponent({ groupApiName: 'TestGroup' }, { canModify: true });

        // Trigger remove row action
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: { row: { Id: 'user1' }, action: { name: 'remove' } }
            })
        );
        await flushPromises();

        let dialog = element.shadowRoot.querySelector('c-rflib-confirmation-dialog');
        expect(dialog.visible).toBe(true);

        // Cancel the removal
        dialog.dispatchEvent(
            new CustomEvent('modalaction', {
                detail: { status: 'cancel' }
            })
        );
        await flushPromises();

        // Dialog should be hidden and removeUserFromGroup should NOT have been called
        dialog = element.shadowRoot.querySelector('c-rflib-confirmation-dialog');
        expect(dialog.visible).toBe(false);
        expect(removeUserFromGroup).not.toHaveBeenCalled();
    });

    // --- Loading state ---

    it('sets isLoading to false after group members are loaded', async () => {
        canUserModifyGroupMemberships.mockResolvedValue(true);
        getGroupMembers.mockResolvedValue(MOCK_GROUP_MEMBERS);

        const element = createComponent({ groupApiName: 'TestGroup' });

        // After init completes, isLoading should be false (no spinner)
        await flushPromises();
        await flushPromises();

        const spinner = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner).toBeNull();
    });
});
