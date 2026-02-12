import { createElement } from 'lwc';
import RflibPermissionsExplorer from 'c/rflibPermissionsExplorer';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

// Import the Apex methods (which will be mocked)
import getObjectLevelSecurityForAllProfiles from '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles';
import getFieldLevelSecurityForAllProfiles from '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles';
import getObjectLevelSecurityForAllPermissionSets from '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSets';
import getObjectLevelSecurityForAllPermissionSetGroups from '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSetGroups';
import getFieldLevelSecurityForAllPermissionSets from '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSets';
import getFieldLevelSecurityForAllPermissionSetGroups from '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSetGroups';
import getApexSecurityForAllProfiles from '@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForAllProfiles';
import getApexSecurityForAllPermissionSets from '@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForAllPermissionSets';
import getApexSecurityForAllPermissionSetGroups from '@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForAllPermissionSetGroups';
import getObjectLevelSecurityForUser from '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForUser';
import getFieldLevelSecurityForUser from '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForUser';
import getApexSecurityForUser from '@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForUser';

// Mock rflibLogger
jest.mock(
    'c/rflibLogger',
    () => {
        return require('../../../../../test/jest-mocks/c/rflibLogger');
    },
    { virtual: true }
);

// Mock Data
const MOCK_RECORDS = [
    {
        SecurityObjectName: 'Admin',
        SobjectType: 'Account',
        Field: 'Name',
        PermissionsRead: true,
        PermissionsEdit: true,
        PermissionsCreate: true,
        PermissionsDelete: true,
        PermissionsViewAllFields: true,
        PermissionsViewAllRecords: true,
        PermissionsModifyAllRecords: true
    }
];

const MOCK_APEX_RESPONSE = {
    records: MOCK_RECORDS,
    totalNumOfRecords: 1,
    nextRecordsUrl: null,
    nextPosition: 0
};

const MOCK_FIELD_RECORDS = [
    {
        SecurityObjectName: 'Admin',
        SobjectType: 'Account',
        Field: 'Name',
        PermissionsRead: true,
        PermissionsEdit: true
    },
    {
        SecurityObjectName: 'Admin',
        SobjectType: 'Account',
        Field: 'Phone',
        PermissionsRead: true,
        PermissionsEdit: false
    },
    {
        SecurityObjectName: 'Sales',
        SobjectType: 'Account',
        Field: 'Name',
        PermissionsRead: true,
        PermissionsEdit: false
    }
];

const MOCK_FIELD_APEX_RESPONSE = {
    records: MOCK_FIELD_RECORDS,
    totalNumOfRecords: 3,
    nextRecordsUrl: null,
    nextPosition: 2
};

const MOCK_MULTI_OBJECT_RECORDS = [
    {
        SecurityObjectName: 'Admin',
        SobjectType: 'Account',
        PermissionsRead: true,
        PermissionsEdit: true,
        PermissionsCreate: true,
        PermissionsDelete: true,
        PermissionsViewAllFields: true,
        PermissionsViewAllRecords: true,
        PermissionsModifyAllRecords: true
    },
    {
        SecurityObjectName: 'Sales',
        SobjectType: 'Account',
        PermissionsRead: true,
        PermissionsEdit: false,
        PermissionsCreate: false,
        PermissionsDelete: false,
        PermissionsViewAllFields: false,
        PermissionsViewAllRecords: false,
        PermissionsModifyAllRecords: false
    },
    {
        SecurityObjectName: 'Admin',
        SobjectType: 'Contact',
        PermissionsRead: true,
        PermissionsEdit: true,
        PermissionsCreate: true,
        PermissionsDelete: false,
        PermissionsViewAllFields: false,
        PermissionsViewAllRecords: true,
        PermissionsModifyAllRecords: false
    }
];

const MOCK_MULTI_OBJECT_APEX_RESPONSE = {
    records: MOCK_MULTI_OBJECT_RECORDS,
    totalNumOfRecords: 3,
    nextRecordsUrl: null,
    nextPosition: 2
};

// Mock all Apex methods explicitly with inline jest.fn()
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSets',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSetGroups',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSets',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSetGroups',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForAllProfiles',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForAllPermissionSets',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForAllPermissionSetGroups',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForUser',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForUser',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForUser',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

async function flushPromises() {
    return Promise.resolve();
}

function selectPermissionType(element, permissionTypeValue) {
    const menu = element.shadowRoot.querySelector('lightning-button-menu');
    menu.dispatchEvent(new CustomEvent('select', { detail: { value: permissionTypeValue } }));
}

function getExportMenu(element) {
    const menus = element.shadowRoot.querySelectorAll('lightning-button-menu');
    return menus[1];
}

function getSettingsMenu(element) {
    const menus = element.shadowRoot.querySelectorAll('lightning-button-menu');
    return menus[2];
}

describe('c-rflib-permissions-explorer', () => {
    const ALL_APEX_MOCKS = [
        getObjectLevelSecurityForAllProfiles,
        getFieldLevelSecurityForAllProfiles,
        getObjectLevelSecurityForAllPermissionSets,
        getObjectLevelSecurityForAllPermissionSetGroups,
        getFieldLevelSecurityForAllPermissionSets,
        getFieldLevelSecurityForAllPermissionSetGroups,
        getApexSecurityForAllProfiles,
        getApexSecurityForAllPermissionSets,
        getApexSecurityForAllPermissionSetGroups,
        getObjectLevelSecurityForUser,
        getFieldLevelSecurityForUser,
        getApexSecurityForUser
    ];

    beforeEach(() => {
        jest.useFakeTimers();
        ALL_APEX_MOCKS.forEach((mock) => mock.mockResolvedValue(MOCK_APEX_RESPONSE));
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        jest.useRealTimers();
    });

    async function createAndLoad() {
        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });
        document.body.appendChild(element);

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        return element;
    }

    async function switchPermissionTypeAndLoad(element, permissionTypeValue) {
        jest.clearAllMocks();
        ALL_APEX_MOCKS.forEach((mock) => mock.mockResolvedValue(MOCK_APEX_RESPONSE));

        selectPermissionType(element, permissionTypeValue);

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();
    }

    it('renders and loads default permissions', async () => {
        const element = await createAndLoad();

        // Default is Object Permissions for Profiles
        expect(getObjectLevelSecurityForAllProfiles).toHaveBeenCalled();

        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        expect(table).not.toBeNull();
        expect(table.permissionRecords).toEqual(MOCK_RECORDS);
    });

    it('changes permission type and reloads', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'FieldPermissionsProfiles');

        expect(getFieldLevelSecurityForAllProfiles).toHaveBeenCalled();
    });

    it('handles pagination events from paginator', async () => {
        const element = await createAndLoad();

        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        const details = { numDisplayedRecords: 20, currentPage: 1 };
        table.dispatchEvent(new CustomEvent('refreshed', { detail: JSON.stringify(details) }));

        await flushPromises();

        const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
        paginator.dispatchEvent(new CustomEvent('next'));

        await flushPromises();
        await flushPromises();

        expect(table.currentPage).toBe(2);
    });

    it('exports to CSV', async () => {
        const element = await createAndLoad();

        // Mock document.createElement and click
        const mockLink = document.createElement('a');
        const clickSpy = jest.spyOn(mockLink, 'click');
        const createElementSpy = jest.spyOn(document, 'createElement').mockReturnValue(mockLink);

        const exportMenu = getExportMenu(element);
        exportMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 'all' } }));

        await flushPromises();

        expect(createElementSpy).toHaveBeenCalledWith('a');
        expect(clickSpy).toHaveBeenCalled();

        createElementSpy.mockRestore();
    });

    it('handles error during load', async () => {
        getObjectLevelSecurityForAllProfiles.mockRejectedValueOnce(new Error('Apex Error'));

        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });
        document.body.appendChild(element);

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
    });

    // --- Permission type switching tests ---

    it('loads Object Permissions for Permission Sets when selected', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'ObjectPermissionsPermissionSets');

        expect(getObjectLevelSecurityForAllPermissionSets).toHaveBeenCalled();
    });

    it('loads Object Permissions for Permission Set Groups when selected', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'ObjectPermissionsPermissionSetGroups');

        expect(getObjectLevelSecurityForAllPermissionSetGroups).toHaveBeenCalled();
    });

    it('loads Apex Permissions for Profiles when selected', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'ApexPermissionsProfiles');

        expect(getApexSecurityForAllProfiles).toHaveBeenCalled();
    });

    it('loads Apex Permissions for Permission Sets when selected', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'ApexPermissionsPermissionSets');

        expect(getApexSecurityForAllPermissionSets).toHaveBeenCalled();
    });

    it('loads Apex Permissions for Permission Set Groups when selected', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'ApexPermissionsPermissionSetGroups');

        expect(getApexSecurityForAllPermissionSetGroups).toHaveBeenCalled();
    });

    it('loads Field Permissions for Permission Sets when selected', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'FieldPermissionsPermissionSets');

        expect(getFieldLevelSecurityForAllPermissionSets).toHaveBeenCalled();
    });

    it('loads Field Permissions for Permission Set Groups when selected', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'FieldPermissionsPermissionSetGroups');

        expect(getFieldLevelSecurityForAllPermissionSetGroups).toHaveBeenCalled();
    });

    // --- User mode tests ---

    it('shows user picker and disables aggregate button when user mode is selected without a user', async () => {
        const element = await createAndLoad();

        jest.clearAllMocks();
        ALL_APEX_MOCKS.forEach((mock) => mock.mockResolvedValue(MOCK_APEX_RESPONSE));

        selectPermissionType(element, 'ObjectPermissionsUser');

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        // No user selected, so the user-specific Apex should NOT be called
        expect(getObjectLevelSecurityForUser).not.toHaveBeenCalled();

        // User picker should be rendered
        const userPicker = element.shadowRoot.querySelector('lightning-record-picker');
        expect(userPicker).not.toBeNull();

        // Aggregate button should be disabled
        const buttons = element.shadowRoot.querySelectorAll('lightning-button');
        const aggregateBtn = Array.from(buttons).find((btn) => btn.label === 'Aggregate Permissions');
        expect(aggregateBtn).not.toBeNull();
        expect(aggregateBtn.disabled).toBe(true);
    });

    it('loads Object Permissions for User after selecting a user', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'ObjectPermissionsUser');

        jest.clearAllMocks();
        ALL_APEX_MOCKS.forEach((mock) => mock.mockResolvedValue(MOCK_APEX_RESPONSE));

        // Simulate user selection
        const userPicker = element.shadowRoot.querySelector('lightning-record-picker');
        userPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000001XUser' } }));

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        expect(getObjectLevelSecurityForUser).toHaveBeenCalled();

        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        expect(table.permissionRecords).toEqual(MOCK_RECORDS);
    });

    it('loads Field Permissions for User after selecting a user', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'FieldPermissionsUser');

        jest.clearAllMocks();
        ALL_APEX_MOCKS.forEach((mock) => mock.mockResolvedValue(MOCK_FIELD_APEX_RESPONSE));

        const userPicker = element.shadowRoot.querySelector('lightning-record-picker');
        userPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000001XUser' } }));

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        expect(getFieldLevelSecurityForUser).toHaveBeenCalled();
    });

    it('loads Apex Permissions for User after selecting a user', async () => {
        const element = await createAndLoad();

        await switchPermissionTypeAndLoad(element, 'ApexPermissionsUser');

        jest.clearAllMocks();
        ALL_APEX_MOCKS.forEach((mock) => mock.mockResolvedValue(MOCK_APEX_RESPONSE));

        const userPicker = element.shadowRoot.querySelector('lightning-record-picker');
        userPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000001XUser' } }));

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        expect(getApexSecurityForUser).toHaveBeenCalled();
    });

    // --- Multi-page loading test ---

    it('loads multiple pages of records recursively', async () => {
        const page1Response = {
            records: [MOCK_RECORDS[0]],
            totalNumOfRecords: 2,
            nextRecordsUrl: '/services/data/v65.0/query/next',
            nextPosition: 0
        };
        const page2Response = {
            records: [{ ...MOCK_RECORDS[0], SecurityObjectName: 'Sales' }],
            totalNumOfRecords: 2,
            nextRecordsUrl: null,
            nextPosition: 1
        };

        getObjectLevelSecurityForAllProfiles.mockResolvedValueOnce(page1Response).mockResolvedValueOnce(page2Response);

        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });
        document.body.appendChild(element);

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();
        await flushPromises();
        await flushPromises();

        expect(getObjectLevelSecurityForAllProfiles).toHaveBeenCalledTimes(2);

        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        expect(table.permissionRecords).toHaveLength(2);
        expect(table.permissionRecords[0].SecurityObjectName).toBe('Admin');
        expect(table.permissionRecords[1].SecurityObjectName).toBe('Sales');
    });

    // --- Incomplete records warning toast ---

    it('shows warning toast when loaded records are fewer than total', async () => {
        const incompleteResponse = {
            records: [MOCK_RECORDS[0]],
            totalNumOfRecords: 5,
            nextRecordsUrl: null,
            nextPosition: 4
        };

        getObjectLevelSecurityForAllProfiles.mockResolvedValueOnce(incompleteResponse);

        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        document.body.appendChild(element);

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        const toastDetail = toastHandler.mock.calls[0][0].detail;
        expect(toastDetail.title).toBe('Permissions Incomplete');
        expect(toastDetail.variant).toBe('warning');
    });

    // --- Caching test ---

    it('uses cached results when switching back to a previously loaded permission type', async () => {
        const element = await createAndLoad();

        // Initial load should call the Apex method
        expect(getObjectLevelSecurityForAllProfiles).toHaveBeenCalledTimes(1);

        // Switch to a different type
        await switchPermissionTypeAndLoad(element, 'FieldPermissionsProfiles');

        jest.clearAllMocks();
        ALL_APEX_MOCKS.forEach((mock) => mock.mockResolvedValue(MOCK_APEX_RESPONSE));

        // Switch back to original type — should use cache
        selectPermissionType(element, 'ObjectPermissionsProfiles');

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        // Should NOT call Apex again — using cached data
        expect(getObjectLevelSecurityForAllProfiles).not.toHaveBeenCalled();

        // Records should still be present
        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        expect(table.permissionRecords).toEqual(MOCK_RECORDS);
    });

    // --- Page size change test ---

    it('updates page size when settings menu selection changes', async () => {
        const element = await createAndLoad();

        const settingsMenu = getSettingsMenu(element);
        settingsMenu.dispatchEvent(new CustomEvent('select', { detail: { value: '50' } }));

        await flushPromises();

        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        expect(table.pageSize).toBe(50);
    });

    // --- Pagination tests ---

    it('handles first, last, and go-to-page navigation', async () => {
        const element = await createAndLoad();

        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        const paginator = element.shadowRoot.querySelector('c-rflib-paginator');

        // Simulate that the table has 100 displayed records
        table.dispatchEvent(
            new CustomEvent('refreshed', {
                detail: JSON.stringify({ numDisplayedRecords: 100, currentPage: 1 })
            })
        );
        await flushPromises();

        // Navigate to last page (100 records / 10 page size = 10 pages)
        paginator.dispatchEvent(new CustomEvent('last'));
        await flushPromises();
        expect(table.currentPage).toBe(10);

        // Navigate to first page
        paginator.dispatchEvent(new CustomEvent('first'));
        await flushPromises();
        expect(table.currentPage).toBe(1);

        // Navigate to specific page
        paginator.dispatchEvent(new CustomEvent('gotopage', { detail: 5 }));
        await flushPromises();
        expect(table.currentPage).toBe(5);

        // Navigate previous from page 5
        paginator.dispatchEvent(new CustomEvent('previous'));
        await flushPromises();
        expect(table.currentPage).toBe(4);
    });

    // --- Export filter modal tests ---

    it('opens export filter modal, changes filter inputs, and closes via cancel', async () => {
        const element = await createAndLoad();

        // Open the filtered export modal
        const exportMenu = getExportMenu(element);
        exportMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 'filtered' } }));
        await flushPromises();

        // Modal should be visible
        let modal = element.shadowRoot.querySelector('.slds-modal');
        expect(modal).not.toBeNull();

        // Change filter inputs using value property + change event
        const inputs = element.shadowRoot.querySelectorAll('lightning-input');
        const securityInput = inputs[0];
        const objectInput = inputs[1];

        securityInput.value = 'Admin';
        securityInput.dispatchEvent(new CustomEvent('change'));
        objectInput.value = 'Account';
        objectInput.dispatchEvent(new CustomEvent('change'));
        await flushPromises();

        // Click Cancel button
        const cancelBtn = element.shadowRoot.querySelector('.slds-button_neutral');
        cancelBtn.click();
        await flushPromises();

        // Modal should be closed
        modal = element.shadowRoot.querySelector('.slds-modal');
        expect(modal).toBeNull();
    });

    // --- Filtered export for object permissions ---

    it('exports filtered object permissions to CSV', async () => {
        getObjectLevelSecurityForAllProfiles.mockResolvedValueOnce(MOCK_MULTI_OBJECT_APEX_RESPONSE);

        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });
        document.body.appendChild(element);

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        // Open export filter modal
        const exportMenu = getExportMenu(element);
        exportMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 'filtered' } }));
        await flushPromises();

        // Set filter for Admin + Account
        const inputs = element.shadowRoot.querySelectorAll('lightning-input');
        inputs[0].value = 'Admin';
        inputs[0].dispatchEvent(new CustomEvent('change'));
        inputs[1].value = 'Account';
        inputs[1].dispatchEvent(new CustomEvent('change'));
        await flushPromises();

        // Mock the download link
        const mockLink = document.createElement('a');
        const clickSpy = jest.spyOn(mockLink, 'click');
        const createElementSpy = jest.spyOn(document, 'createElement').mockReturnValue(mockLink);

        // Click Export button
        const exportBtn = element.shadowRoot.querySelector('.slds-button_brand');
        exportBtn.click();
        await flushPromises();

        expect(createElementSpy).toHaveBeenCalledWith('a');
        expect(clickSpy).toHaveBeenCalled();

        // Modal should be closed after export
        const modal = element.shadowRoot.querySelector('.slds-modal');
        expect(modal).toBeNull();

        createElementSpy.mockRestore();
    });

    // --- Filtered export for field permissions ---

    it('exports filtered field permissions to CSV with field filter', async () => {
        getFieldLevelSecurityForAllProfiles.mockResolvedValueOnce(MOCK_FIELD_APEX_RESPONSE);

        const element = await createAndLoad();

        // Switch to field permissions
        await switchPermissionTypeAndLoad(element, 'FieldPermissionsProfiles');

        // Open export filter modal
        const exportMenu = getExportMenu(element);
        exportMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 'filtered' } }));
        await flushPromises();

        // Set all 3 filters (field filter input should now be visible)
        const inputs = element.shadowRoot.querySelectorAll('lightning-input');
        expect(inputs.length).toBe(3);

        inputs[0].value = 'Admin';
        inputs[0].dispatchEvent(new CustomEvent('change'));
        inputs[1].value = 'Account';
        inputs[1].dispatchEvent(new CustomEvent('change'));
        inputs[2].value = 'Name';
        inputs[2].dispatchEvent(new CustomEvent('change'));
        await flushPromises();

        // Mock the download link
        const mockLink = document.createElement('a');
        const clickSpy = jest.spyOn(mockLink, 'click');
        const createElementSpy = jest.spyOn(document, 'createElement').mockReturnValue(mockLink);

        // Click Export button
        const exportBtn = element.shadowRoot.querySelector('.slds-button_brand');
        exportBtn.click();
        await flushPromises();

        expect(clickSpy).toHaveBeenCalled();

        createElementSpy.mockRestore();
    });

    // --- Export all for field permissions ---

    it('exports all field permissions to CSV using field permission header format', async () => {
        getFieldLevelSecurityForAllProfiles.mockResolvedValueOnce(MOCK_FIELD_APEX_RESPONSE);

        const element = await createAndLoad();

        // Switch to field permissions
        await switchPermissionTypeAndLoad(element, 'FieldPermissionsProfiles');

        // Mock the download link
        const mockLink = document.createElement('a');
        const clickSpy = jest.spyOn(mockLink, 'click');
        const createElementSpy = jest.spyOn(document, 'createElement').mockReturnValue(mockLink);

        // Export all
        const exportMenu = getExportMenu(element);
        exportMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 'all' } }));
        await flushPromises();

        expect(clickSpy).toHaveBeenCalled();
        // Verify the href contains field permissions CSV header markers
        const hrefValue = mockLink.getAttribute('href');
        expect(hrefValue).toContain('FIELD');
        expect(hrefValue).toContain('csv');

        createElementSpy.mockRestore();
    });

    // --- Aggregation tests ---

    it('aggregates object permissions by SobjectType using OR logic', async () => {
        getObjectLevelSecurityForUser.mockResolvedValueOnce(MOCK_MULTI_OBJECT_APEX_RESPONSE);

        const element = await createAndLoad();

        // Switch to user mode
        await switchPermissionTypeAndLoad(element, 'ObjectPermissionsUser');

        jest.clearAllMocks();
        getObjectLevelSecurityForUser.mockResolvedValueOnce(MOCK_MULTI_OBJECT_APEX_RESPONSE);

        // Select a user
        const userPicker = element.shadowRoot.querySelector('lightning-record-picker');
        userPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000001XUser' } }));

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        // Click Aggregate button
        const buttons = element.shadowRoot.querySelectorAll('lightning-button');
        const aggregateBtn = Array.from(buttons).find((btn) => btn.label === 'Aggregate Permissions');
        aggregateBtn.click();
        await flushPromises();

        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        // 3 records with 2 unique SobjectTypes (Account, Contact) → 2 aggregated records
        expect(table.permissionRecords).toHaveLength(2);

        // Account should have OR'd permissions (Admin has all true, Sales has only Read true)
        const accountRecord = table.permissionRecords.find((r) => r.SobjectType === 'Account');
        expect(accountRecord.PermissionsRead).toBe(true);
        expect(accountRecord.PermissionsEdit).toBe(true);
        expect(accountRecord.PermissionsCreate).toBe(true);
        expect(accountRecord.PermissionsDelete).toBe(true);

        // After aggregation, the button should change to Reset
        await flushPromises();
        const allButtons = element.shadowRoot.querySelectorAll('lightning-button');
        const resetBtn = Array.from(allButtons).find((btn) => btn.label === 'Reset Permissions');
        expect(resetBtn).not.toBeNull();
    });

    it('aggregates field permissions by SobjectType and Field using OR logic', async () => {
        getFieldLevelSecurityForUser.mockResolvedValueOnce(MOCK_FIELD_APEX_RESPONSE);

        const element = await createAndLoad();

        // Switch to field permissions user mode
        await switchPermissionTypeAndLoad(element, 'FieldPermissionsUser');

        jest.clearAllMocks();
        getFieldLevelSecurityForUser.mockResolvedValueOnce(MOCK_FIELD_APEX_RESPONSE);

        // Select a user
        const userPicker = element.shadowRoot.querySelector('lightning-record-picker');
        userPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000001XUser' } }));

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        // Click Aggregate button
        const buttons = element.shadowRoot.querySelectorAll('lightning-button');
        const aggregateBtn = Array.from(buttons).find((btn) => btn.label === 'Aggregate Permissions');
        aggregateBtn.click();
        await flushPromises();

        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        // 3 records: Admin+Account+Name, Admin+Account+Phone, Sales+Account+Name
        // Aggregated by SobjectType+Field: Account|Name (2 records), Account|Phone (1 record) → 2 records
        expect(table.permissionRecords).toHaveLength(2);

        // Account|Name should have PermissionsEdit = true (Admin has true, Sales has false, OR = true)
        const nameRecord = table.permissionRecords.find((r) => r.Field === 'Name');
        expect(nameRecord.PermissionsRead).toBe(true);
        expect(nameRecord.PermissionsEdit).toBe(true);

        // Account|Phone should have PermissionsEdit = false (only Admin has it false)
        const phoneRecord = table.permissionRecords.find((r) => r.Field === 'Phone');
        expect(phoneRecord.PermissionsRead).toBe(true);
        expect(phoneRecord.PermissionsEdit).toBe(false);
    });

    // --- Reset permissions test ---

    it('resets permissions and reloads data after aggregation', async () => {
        getObjectLevelSecurityForUser.mockResolvedValue(MOCK_MULTI_OBJECT_APEX_RESPONSE);

        const element = await createAndLoad();

        // Switch to user mode and select user
        await switchPermissionTypeAndLoad(element, 'ObjectPermissionsUser');

        jest.clearAllMocks();
        getObjectLevelSecurityForUser.mockResolvedValue(MOCK_MULTI_OBJECT_APEX_RESPONSE);

        const userPicker = element.shadowRoot.querySelector('lightning-record-picker');
        userPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000001XUser' } }));

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        // Aggregate first
        let buttons = element.shadowRoot.querySelectorAll('lightning-button');
        let aggregateBtn = Array.from(buttons).find((btn) => btn.label === 'Aggregate Permissions');
        aggregateBtn.click();
        await flushPromises();

        // Verify aggregation happened (2 unique SobjectTypes from 3 records)
        let table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        expect(table.permissionRecords).toHaveLength(2);

        // Now click Reset
        buttons = element.shadowRoot.querySelectorAll('lightning-button');
        const resetBtn = Array.from(buttons).find((btn) => btn.label === 'Reset Permissions');
        expect(resetBtn).not.toBeNull();
        resetBtn.click();

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        // After reset, records should be restored from cache (original 3 records)
        table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        expect(table.permissionRecords).toHaveLength(3);

        // Button should be back to Aggregate
        buttons = element.shadowRoot.querySelectorAll('lightning-button');
        const aggregateBtnAfter = Array.from(buttons).find((btn) => btn.label === 'Aggregate Permissions');
        expect(aggregateBtnAfter).not.toBeNull();
    });

    // --- Error with body message ---

    it('handles error with body message during load', async () => {
        getObjectLevelSecurityForAllProfiles.mockRejectedValueOnce({ body: { message: 'Detailed error message' } });

        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        document.body.appendChild(element);

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        const toastDetail = toastHandler.mock.calls[0][0].detail;
        expect(toastDetail.variant).toBe('error');
        expect(toastDetail.message).toContain('Detailed error message');
    });

    // --- Clearing user ID when switching away from user mode ---

    it('clears selected user when switching from user mode to non-user mode', async () => {
        const element = await createAndLoad();

        // Switch to user mode
        await switchPermissionTypeAndLoad(element, 'ObjectPermissionsUser');

        // Select a user
        jest.clearAllMocks();
        ALL_APEX_MOCKS.forEach((mock) => mock.mockResolvedValue(MOCK_APEX_RESPONSE));

        const userPicker = element.shadowRoot.querySelector('lightning-record-picker');
        userPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: '005xx000001XUser' } }));

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        expect(getObjectLevelSecurityForUser).toHaveBeenCalled();

        // Switch back to non-user mode (id < 10)
        jest.clearAllMocks();
        ALL_APEX_MOCKS.forEach((mock) => mock.mockResolvedValue(MOCK_APEX_RESPONSE));

        selectPermissionType(element, 'ObjectPermissionsProfiles');

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        // User picker should not be shown anymore
        const userPickerAfter = element.shadowRoot.querySelector('lightning-record-picker');
        expect(userPickerAfter).toBeNull();
    });
});
