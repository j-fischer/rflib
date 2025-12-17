import { createElement } from 'lwc';
import RflibPermissionsExplorer from 'c/rflibPermissionsExplorer';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

// Import the Apex methods (which will be mocked)
import getObjectLevelSecurityForAllProfiles from '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles';
import getFieldLevelSecurityForAllProfiles from '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles';

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

// Mock all Apex methods explicitly with inline jest.fn()
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSets', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSetGroups', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSets', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSetGroups', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForAllProfiles', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForAllPermissionSets', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForAllPermissionSetGroups', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForUser', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForUser', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/rflib_PermissionsExplorerController.getApexSecurityForUser', () => ({ default: jest.fn() }), { virtual: true });

async function flushPromises() {
    return Promise.resolve();
}

describe('c-rflib-permissions-explorer', () => {
    beforeEach(() => {
        jest.useFakeTimers();
        getObjectLevelSecurityForAllProfiles.mockResolvedValue(MOCK_APEX_RESPONSE);
        getFieldLevelSecurityForAllProfiles.mockResolvedValue(MOCK_APEX_RESPONSE);
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        jest.useRealTimers();
    });

    it('renders and loads default permissions', async () => {
        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });
        document.body.appendChild(element);

        jest.runAllTimers();
        // Wait for multiple ticks for promise chain resolution and re-render
        await flushPromises();
        await flushPromises();

        // Default is Object Permissions for Profiles
        expect(getObjectLevelSecurityForAllProfiles).toHaveBeenCalled();

        const table = element.shadowRoot.querySelector('c-rflib-permissions-table');
        expect(table).not.toBeNull();
        expect(table.permissionRecords).toEqual(MOCK_RECORDS);
    });

    it('changes permission type and reloads', async () => {
        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });
        document.body.appendChild(element);

        jest.runAllTimers();
        await flushPromises();

        // Clear previous calls
        getObjectLevelSecurityForAllProfiles.mockClear();

        const menu = element.shadowRoot.querySelector('lightning-button-menu');
        // Switch to Field Permissions for Profiles
        menu.dispatchEvent(new CustomEvent('select', { detail: { value: 'FieldPermissionsProfiles' } }));

        jest.runAllTimers();
        await flushPromises();
        await flushPromises();

        expect(getFieldLevelSecurityForAllProfiles).toHaveBeenCalled();
    });

    it('handles pagination events from paginator', async () => {
        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });
        document.body.appendChild(element);

        jest.runAllTimers();
        await flushPromises();

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
        const element = createElement('c-rflib-permissions-explorer', {
            is: RflibPermissionsExplorer
        });
        document.body.appendChild(element);

        jest.runAllTimers();
        await flushPromises();

        // Mock document.createElement and click
        const mockLink = document.createElement('a');
        const clickSpy = jest.spyOn(mockLink, 'click');
        const createElementSpy = jest.spyOn(document, 'createElement').mockReturnValue(mockLink);

        const menus = element.shadowRoot.querySelectorAll('lightning-button-menu');
        // 2nd menu is Export
        const exportMenu = menus[1];
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
});
