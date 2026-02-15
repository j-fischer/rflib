import { createElement } from 'lwc';
import RflibUserPermissionSetManager from 'c/rflibUserPermissionSetManager';
import assignPermissionSet from '@salesforce/apex/rflib_UserPermSetManagerController.assignPermissionSet';
import deletePermissionSetAssignment from '@salesforce/apex/rflib_UserPermSetManagerController.deletePermissionSetAssignment';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

// Wire data callbacks - set by the wire adapter when the component connects
let getAssignedPermSetsCallback;
let getAllPermSetsCallback;

// Mock wired Apex method: getAssignedPermissionSets
jest.mock(
    '@salesforce/apex/rflib_UserPermSetManagerController.getAssignedPermissionSets',
    () => ({
        default: function getAssignedPermissionSets(cb) {
            getAssignedPermSetsCallback = cb;
            return {
                connect() {},
                disconnect() {},
                update() {}
            };
        }
    }),
    { virtual: true }
);

// Mock wired Apex method: getAllPermissionSets
jest.mock(
    '@salesforce/apex/rflib_UserPermSetManagerController.getAllPermissionSets',
    () => ({
        default: function getAllPermissionSets(cb) {
            getAllPermSetsCallback = cb;
            return {
                connect() {},
                disconnect() {},
                update() {}
            };
        }
    }),
    { virtual: true }
);

// Mock imperative Apex methods
jest.mock('@salesforce/apex/rflib_UserPermSetManagerController.assignPermissionSet', () => ({ default: jest.fn() }), {
    virtual: true
});

jest.mock(
    '@salesforce/apex/rflib_UserPermSetManagerController.deletePermissionSetAssignment',
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
const MOCK_ASSIGNED_PS = [
    { Id: 'psa1', Label: 'PS1 Label', Name: 'PS1' },
    { Id: 'psa2', Label: 'PS2 Label', Name: 'PS2' }
];

const MOCK_ALL_PS = [
    { Id: 'ps1', Label: 'PS1 Label', Name: 'PS1' },
    { Id: 'ps2', Label: 'PS2 Label', Name: 'PS2' },
    { Id: 'ps3', Label: 'PS3 Label', Name: 'PS3' }
];

// Helper: emit wire data
function emitAssignedPermSetsData(data) {
    if (getAssignedPermSetsCallback) {
        getAssignedPermSetsCallback({ data, error: undefined });
    }
}

function emitAssignedPermSetsError(error) {
    if (getAssignedPermSetsCallback) {
        getAssignedPermSetsCallback({ data: undefined, error });
    }
}

function emitAllPermSetsData(data) {
    if (getAllPermSetsCallback) {
        getAllPermSetsCallback({ data, error: undefined });
    }
}

function emitAllPermSetsError(error) {
    if (getAllPermSetsCallback) {
        getAllPermSetsCallback({ data: undefined, error });
    }
}

// Helper: find a lightning-button by its label
function findButton(root, buttonLabel) {
    const buttons = root.querySelectorAll('lightning-button');
    return Array.from(buttons).find((btn) => btn.label === buttonLabel);
}

describe('c-rflib-user-permission-set-manager', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        // Reset only the imperative mocks
        assignPermissionSet.mockReset();
        deletePermissionSetAssignment.mockReset();
        refreshApex.mockReset();
        // Reset callbacks
        getAssignedPermSetsCallback = undefined;
        getAllPermSetsCallback = undefined;
    });

    function createComponent(props = {}) {
        const element = createElement('c-rflib-user-permission-set-manager', {
            is: RflibUserPermissionSetManager
        });
        Object.assign(element, props);
        document.body.appendChild(element);
        return element;
    }

    async function createAndPopulateComponent(props = {}) {
        const element = createComponent(props);
        emitAssignedPermSetsData(MOCK_ASSIGNED_PS);
        emitAllPermSetsData(MOCK_ALL_PS);
        await Promise.resolve();
        return element;
    }

    it('renders assigned permission sets when wire data is received', async () => {
        const element = await createAndPopulateComponent({
            userAlias: 'testUser',
            title: 'Test Title'
        });

        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card.title).toBe('Test Title');

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toEqual(MOCK_ASSIGNED_PS);
    });

    it('renders combobox options in Label (Name) format', async () => {
        const element = await createAndPopulateComponent();

        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        expect(combobox).not.toBeNull();
        expect(combobox.options).toEqual([
            { label: 'PS1 Label (PS1)', value: 'ps1' },
            { label: 'PS2 Label (PS2)', value: 'ps2' },
            { label: 'PS3 Label (PS3)', value: 'ps3' }
        ]);
    });

    it('shows error toast when getAssignedPermissionSets wire emits error', async () => {
        const element = createComponent({ userAlias: 'testUser' });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        emitAssignedPermSetsError({ body: { message: 'Wire error' } });
        await Promise.resolve();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Error');
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
    });

    it('shows error toast when getAllPermissionSets wire emits error', async () => {
        const element = createComponent();
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        emitAllPermSetsError({ body: { message: 'All PS wire error' } });
        await Promise.resolve();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Error');
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('Failed to load all permission sets');
    });

    it('handles delete permission set flow and shows success toast', async () => {
        deletePermissionSetAssignment.mockResolvedValue();
        refreshApex.mockResolvedValue();

        const element = await createAndPopulateComponent({ userAlias: 'testUser' });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Click delete on first row
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            // cspell:disable-next-line
            new CustomEvent('rowaction', {
                detail: { row: { Id: 'psa1' }, action: { name: 'delete' } }
            })
        );
        await Promise.resolve();

        // Confirm delete modal is open
        const modal = element.shadowRoot.querySelector('.slds-modal');
        expect(modal).not.toBeNull();

        // Click Delete (Confirm) button
        const deleteBtn = findButton(element.shadowRoot, 'Delete');
        expect(deleteBtn).not.toBeUndefined();
        deleteBtn.click();
        await Promise.resolve();
        await Promise.resolve();

        expect(deletePermissionSetAssignment).toHaveBeenCalledWith({ permissionSetAssignmentId: 'psa1' });

        // Wait for toast
        await Promise.resolve();
        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Success');
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');
    });

    it('shows error toast when delete fails', async () => {
        deletePermissionSetAssignment.mockRejectedValue({ body: { message: 'Delete failed' } });

        const element = await createAndPopulateComponent({ userAlias: 'testUser' });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Row action to delete
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            // cspell:disable-next-line
            new CustomEvent('rowaction', {
                detail: { row: { Id: 'psa1' }, action: { name: 'delete' } }
            })
        );
        await Promise.resolve();

        // Confirm delete
        const deleteBtn = findButton(element.shadowRoot, 'Delete');
        deleteBtn.click();
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Error');
    });

    it('handles assign permission set flow and shows success toast', async () => {
        assignPermissionSet.mockResolvedValue();
        refreshApex.mockResolvedValue();

        const element = await createAndPopulateComponent({ userAlias: 'testUser' });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Select a permission set
        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'ps3' } }));
        await Promise.resolve();

        // Click top-level Assign button to open modal
        const assignBtn = findButton(element.shadowRoot, 'Assign');
        expect(assignBtn.disabled).toBe(false);
        assignBtn.click();
        await Promise.resolve();

        // Confirm assign modal - find the second Assign button (inside modal footer)
        const allAssignBtns = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).filter(
            (btn) => btn.label === 'Assign'
        );
        // The first Assign is the top-level, the second is in the modal
        const confirmAssignBtn = allAssignBtns[allAssignBtns.length - 1];
        confirmAssignBtn.click();
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        expect(assignPermissionSet).toHaveBeenCalledWith({ permissionSetId: 'ps3', alias: 'testUser' });
        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Success');
    });

    it('shows error toast when assign fails', async () => {
        assignPermissionSet.mockRejectedValue({ body: { message: 'Assign failed' } });

        const element = await createAndPopulateComponent({ userAlias: 'testUser' });
        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        // Select and assign
        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'ps3' } }));
        await Promise.resolve();

        const assignBtn = findButton(element.shadowRoot, 'Assign');
        assignBtn.click();
        await Promise.resolve();

        // Find modal's Assign button
        const allAssignBtns = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).filter(
            (btn) => btn.label === 'Assign'
        );
        const confirmAssignBtn = allAssignBtns[allAssignBtns.length - 1];
        confirmAssignBtn.click();
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.title).toBe('Error');
    });

    it('closes assign modal when cancel is clicked', async () => {
        const element = await createAndPopulateComponent({ userAlias: 'testUser' });

        // Select a permission set and open assign modal
        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'ps3' } }));
        await Promise.resolve();

        const assignBtn = findButton(element.shadowRoot, 'Assign');
        assignBtn.click();
        await Promise.resolve();

        // Assign modal should be open
        let modal = element.shadowRoot.querySelector('.slds-modal');
        expect(modal).not.toBeNull();

        // Click Cancel
        const cancelBtn = findButton(element.shadowRoot, 'Cancel');
        cancelBtn.click();
        await Promise.resolve();

        // Modal should be closed
        modal = element.shadowRoot.querySelector('.slds-modal');
        expect(modal).toBeNull();
    });

    it('re-disables the assign button when permission set selection is cleared', async () => {
        const element = await createAndPopulateComponent({ userAlias: 'testUser' });

        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        const assignBtn = findButton(element.shadowRoot, 'Assign');

        // Initially disabled
        expect(assignBtn.disabled).toBe(true);

        // Select a permission set
        combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'ps3' } }));
        await Promise.resolve();
        expect(assignBtn.disabled).toBe(false);

        // Clear selection
        combobox.dispatchEvent(new CustomEvent('change', { detail: { value: '' } }));
        await Promise.resolve();
        expect(assignBtn.disabled).toBe(true);
    });
});
