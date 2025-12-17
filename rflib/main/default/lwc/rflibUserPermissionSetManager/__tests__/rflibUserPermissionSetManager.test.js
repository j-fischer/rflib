
import { createElement } from 'lwc';
import RflibUserPermissionSetManager from 'c/rflibUserPermissionSetManager';
import assignPermissionSet from '@salesforce/apex/rflib_UserPermSetManagerController.assignPermissionSet';
import deletePermissionSetAssignment from '@salesforce/apex/rflib_UserPermSetManagerController.deletePermissionSetAssignment';
import { refreshApex } from '@salesforce/apex';

// Generic wire adapter mock factory following LWC protocol
const createWireAdapterMock = () => {
    let _dataCallback;
    const adapter = jest.fn((dataCallback) => {
        _dataCallback = dataCallback;
        return {
            connect: jest.fn(),
            disconnect: jest.fn(),
            update: jest.fn()
        };
    });

    // Attach helper methods to the mock function so we can control it
    adapter.emit = (data) => {
        if (_dataCallback) {
            _dataCallback({ data, error: undefined });
        }
    };

    adapter.error = (error) => {
        if (_dataCallback) {
            _dataCallback({ data: undefined, error });
        }
    };

    adapter.getLastConfig = jest.fn();

    return adapter;
};

// Create Adapters
const mockGetAssignedPermissionSetsAdapter = createWireAdapterMock();
const mockGetAllPermissionSetsAdapter = createWireAdapterMock();

// Mock Wired Apex Methods
jest.mock(
    '@salesforce/apex/rflib_UserPermSetManagerController.getAssignedPermissionSets',
    () => ({ default: mockGetAssignedPermissionSetsAdapter }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_UserPermSetManagerController.getAllPermissionSets',
    () => ({ default: mockGetAllPermissionSetsAdapter }),
    { virtual: true }
);

// Mock Imperative Apex Calls
jest.mock(
    '@salesforce/apex/rflib_UserPermSetManagerController.assignPermissionSet',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_UserPermSetManagerController.deletePermissionSetAssignment',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

// Mock refreshApex
jest.mock(
    '@salesforce/apex',
    () => ({
        refreshApex: jest.fn(() => Promise.resolve())
    }),
    { virtual: true }
);

// Mock Logger
jest.mock('c/rflibLogger', () => {
    return {
        createLogger: jest.fn(() => ({
            debug: jest.fn(),
            error: jest.fn()
        }))
    };
});

const MOCK_ASSIGNED_PS = [
    { Id: 'psa1', Label: 'Admin', Name: 'Admin_PS' },
    { Id: 'psa2', Label: 'User', Name: 'User_PS' }
];

const MOCK_ALL_PS = [
    { Id: 'ps1', Label: 'Admin', Name: 'Admin_PS' },
    { Id: 'ps2', Label: 'User', Name: 'User_PS' },
    { Id: 'ps3', Label: 'Viewer', Name: 'Viewer_PS' }
];

describe('c-rflib-user-permission-set-manager', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('initializes and displays data correctly', async () => {
        const element = createElement('c-rflib-user-permission-set-manager', {
            is: RflibUserPermissionSetManager
        });
        element.userAlias = 'testUser';
        element.title = 'Permission Sets';
        document.body.appendChild(element);

        // Emit data
        mockGetAssignedPermissionSetsAdapter.emit(MOCK_ASSIGNED_PS);
        mockGetAllPermissionSetsAdapter.emit(MOCK_ALL_PS);

        await Promise.resolve();

        // Verify Title
        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card.title).toBe('Permission Sets');

        // Verify Datatable
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable.data).toEqual(MOCK_ASSIGNED_PS);

        // Verify Combobox
        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        expect(combobox.options.length).toBe(3);
    });

    it('handles delete permission set flow', async () => {
        deletePermissionSetAssignment.mockResolvedValue();

        const element = createElement('c-rflib-user-permission-set-manager', {
            is: RflibUserPermissionSetManager
        });
        document.body.appendChild(element);

        mockGetAssignedPermissionSetsAdapter.emit(MOCK_ASSIGNED_PS);
        await Promise.resolve();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');

        // Simulate row action (Delete)
        datatable.dispatchEvent(new CustomEvent('rowaction', {
            detail: {
                row: MOCK_ASSIGNED_PS[0]
            }
        }));

        await Promise.resolve();

        // Check if modal is open
        const modalHeader = element.shadowRoot.querySelector('.slds-modal__header h2');
        expect(modalHeader.textContent).toBe('Confirm Delete');

        // Click Cancel
        const cancelBtn = element.shadowRoot.querySelectorAll('lightning-button')[1];
        cancelBtn.click();
        await Promise.resolve();

        // Modal should be gone
        expect(element.shadowRoot.querySelector('.slds-modal')).toBeNull();

        // Trigger delete again
        datatable.dispatchEvent(new CustomEvent('rowaction', {
            detail: {
                row: MOCK_ASSIGNED_PS[0]
            }
        }));
        await Promise.resolve();

        // Confirm Delete
        const confirmBtn = element.shadowRoot.querySelectorAll('lightning-button')[2];
        confirmBtn.click();

        await Promise.resolve();

        expect(deletePermissionSetAssignment).toHaveBeenCalledWith({ permissionSetAssignmentId: 'psa1' });
        expect(refreshApex).toHaveBeenCalled();
    });

    it('handles assign permission set flow', async () => {
        assignPermissionSet.mockResolvedValue();

        const element = createElement('c-rflib-user-permission-set-manager', {
            is: RflibUserPermissionSetManager
        });
        element.userAlias = 'testUser';
        document.body.appendChild(element);

        mockGetAllPermissionSetsAdapter.emit(MOCK_ALL_PS);
        await Promise.resolve();

        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        const assignBtn = element.shadowRoot.querySelector('lightning-button');

        // Initially disabled
        expect(assignBtn.disabled).toBe(true);

        // Select Permission Set
        combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'ps3' } }));
        await Promise.resolve();

        expect(assignBtn.disabled).toBe(false);

        // Click Assign
        assignBtn.click();
        await Promise.resolve();

        // Check Modal
        const modalHeader = element.shadowRoot.querySelector('.slds-modal__header h2');
        expect(modalHeader.textContent).toBe('Confirm Assignment');

        // Confirm
        const confirmBtn = element.shadowRoot.querySelectorAll('lightning-button')[2];
        confirmBtn.click();

        await Promise.resolve();

        expect(assignPermissionSet).toHaveBeenCalledWith({ permissionSetId: 'ps3', alias: 'testUser' });
        expect(refreshApex).toHaveBeenCalled();
        expect(assignBtn.disabled).toBe(true);
    });

    it('handles error on load', async () => {
         const element = createElement('c-rflib-user-permission-set-manager', {
             is: RflibUserPermissionSetManager
         });
         document.body.appendChild(element);

         mockGetAssignedPermissionSetsAdapter.error();
         await Promise.resolve();
    });

    it('handles error on delete', async () => {
        deletePermissionSetAssignment.mockRejectedValue({ body: { message: 'Error' } });

        const element = createElement('c-rflib-user-permission-set-manager', {
            is: RflibUserPermissionSetManager
        });
        document.body.appendChild(element);

        mockGetAssignedPermissionSetsAdapter.emit(MOCK_ASSIGNED_PS);
        await Promise.resolve();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(new CustomEvent('rowaction', {
            detail: { row: MOCK_ASSIGNED_PS[0] }
        }));
        await Promise.resolve();

        const confirmBtn = element.shadowRoot.querySelectorAll('lightning-button')[2];
        confirmBtn.click();
        await Promise.resolve();

        expect(deletePermissionSetAssignment).toHaveBeenCalled();
    });

    it('handles error on assign', async () => {
        assignPermissionSet.mockRejectedValue({ body: { message: 'Error' } });

        const element = createElement('c-rflib-user-permission-set-manager', {
            is: RflibUserPermissionSetManager
        });
        document.body.appendChild(element);

        mockGetAllPermissionSetsAdapter.emit(MOCK_ALL_PS);
        await Promise.resolve();

        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'ps3' } }));
        await Promise.resolve();

        const assignBtn = element.shadowRoot.querySelector('lightning-button');
        assignBtn.click();
        await Promise.resolve();

        const confirmBtn = element.shadowRoot.querySelectorAll('lightning-button')[2];
        confirmBtn.click();
        await Promise.resolve();

        expect(assignPermissionSet).toHaveBeenCalled();
    });
});
