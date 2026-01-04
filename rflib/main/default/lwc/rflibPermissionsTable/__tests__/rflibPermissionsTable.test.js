import { createElement } from 'lwc';
import RflibPermissionsTable from 'c/rflibPermissionsTable';

// Mock rflibLogger
jest.mock(
    'c/rflibLogger',
    () => {
        return require('../../../../../test/jest-mocks/c/rflibLogger');
    },
    { virtual: true }
);

const MOCK_DATA = [
    {
        SecurityObjectName: 'Admin',
        SobjectType: 'Account',
        Field: 'Name',
        PermissionsRead: true,
        PermissionsEdit: true
    },
    {
        SecurityObjectName: 'Standard User',
        SobjectType: 'Contact',
        Field: 'Email',
        PermissionsRead: true,
        PermissionsEdit: false
    },
    {
        SecurityObjectName: 'Custom Profile',
        SobjectType: 'Opportunity',
        Field: 'Amount',
        PermissionsRead: false,
        PermissionsEdit: false
    }
];

describe('c-rflib-permissions-table', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders with correct number of records and title', async () => {
        const element = createElement('c-rflib-permissions-table', {
            is: RflibPermissionsTable
        });
        element.permissionRecords = MOCK_DATA;
        element.pageSize = 2; // Should display 2 records on first page
        element.permissionType = 'FLS';
        document.body.appendChild(element);

        // Wait for any asynchronous DOM updates
        await Promise.resolve();

        const title = element.shadowRoot.querySelector('lightning-card').title;
        expect(title).toBe('3 Displayed Permissions');

        const rows = element.shadowRoot.querySelectorAll('tbody tr');
        expect(rows.length).toBe(2);
    });

    it('handles pagination correctly', async () => {
        const element = createElement('c-rflib-permissions-table', {
            is: RflibPermissionsTable
        });
        element.permissionRecords = MOCK_DATA;
        element.pageSize = 1;
        element.permissionType = 'FLS';
        document.body.appendChild(element);

        await Promise.resolve();

        let rows = element.shadowRoot.querySelectorAll('tbody tr');
        expect(rows.length).toBe(1);
        expect(rows[0].textContent).toContain('Account');

        // Change page
        element.currentPage = 2;
        await Promise.resolve();

        rows = element.shadowRoot.querySelectorAll('tbody tr');
        expect(rows.length).toBe(1);
        expect(rows[0].textContent).toContain('Contact');
    });

    it('filters records by security object name', async () => {
        const element = createElement('c-rflib-permissions-table', {
            is: RflibPermissionsTable
        });
        element.permissionRecords = MOCK_DATA;
        element.pageSize = 10;
        element.permissionType = 'FLS';
        document.body.appendChild(element);

        await Promise.resolve();

        const inputs = element.shadowRoot.querySelectorAll('lightning-input');
        // 1st input is security object search
        const searchInput = inputs[0];
        searchInput.value = 'Admin';
        searchInput.dispatchEvent(new CustomEvent('change'));

        // Simulate enter key press
        searchInput.parentElement.dispatchEvent(new KeyboardEvent('keypress', { which: 13 }));

        await Promise.resolve();

        const rows = element.shadowRoot.querySelectorAll('tbody tr');
        expect(rows.length).toBe(1);
        expect(rows[0].textContent).toContain('Admin');
    });

    it('filters records by object search', async () => {
        const element = createElement('c-rflib-permissions-table', {
            is: RflibPermissionsTable
        });
        element.permissionRecords = MOCK_DATA;
        element.pageSize = 10;
        element.permissionType = 'FLS';
        document.body.appendChild(element);

        await Promise.resolve();

        const inputs = element.shadowRoot.querySelectorAll('lightning-input');
        // 2nd input is object search
        const searchInput = inputs[1];
        searchInput.value = 'Contact';
        searchInput.dispatchEvent(new CustomEvent('change'));

        // Simulate enter key press on parent div wrapper
        searchInput.parentElement.dispatchEvent(new KeyboardEvent('keypress', { which: 13 }));

        await Promise.resolve();

        const rows = element.shadowRoot.querySelectorAll('tbody tr');
        expect(rows.length).toBe(1);
        expect(rows[0].textContent).toContain('Contact');
    });

    it('filters records by field search (FLS only)', async () => {
        const element = createElement('c-rflib-permissions-table', {
            is: RflibPermissionsTable
        });
        element.permissionRecords = MOCK_DATA;
        element.pageSize = 10;
        element.permissionType = 'FLS';
        document.body.appendChild(element);

        await Promise.resolve();

        const inputs = element.shadowRoot.querySelectorAll('lightning-input');
        // 3rd input is field search (only visible if FLS)
        const searchInput = inputs[2];
        searchInput.value = 'Email';
        searchInput.dispatchEvent(new CustomEvent('change'));

        // Simulate enter key press on parent div
        searchInput.parentElement.dispatchEvent(new KeyboardEvent('keypress', { which: 13 }));

        await Promise.resolve();

        const rows = element.shadowRoot.querySelectorAll('tbody tr');
        expect(rows.length).toBe(1);
        expect(rows[0].textContent).toContain('Email');
    });

    it('dispatches refreshed event on load', async () => {
        const handler = jest.fn();
        const element = createElement('c-rflib-permissions-table', {
            is: RflibPermissionsTable
        });
        element.addEventListener('refreshed', handler);
        element.permissionRecords = MOCK_DATA;
        element.pageSize = 10;
        element.permissionType = 'FLS';
        document.body.appendChild(element);

        await Promise.resolve();

        expect(handler).toHaveBeenCalled();
        const detail = JSON.parse(handler.mock.calls[0][0].detail);
        expect(detail.numDisplayedRecords).toBe(3);
        expect(detail.currentPage).toBe(1);
    });

    it('handles profile selection event from resolver', async () => {
        const element = createElement('c-rflib-permissions-table', {
            is: RflibPermissionsTable
        });
        element.permissionRecords = MOCK_DATA;
        element.pageSize = 10;
        // isProfilePermissions prop needs to be true for the resolver to render?
        // JS getter `isProfilePermissions` relies on `permissionType`?
        // No, `isProfilePermissions` is an @api property in the JS file!
        element.isProfilePermissions = true;
        element.permissionType = 'OLS'; // Just to not be FLS, though `isProfilePermissions` overrides rendering of resolver

        document.body.appendChild(element);

        await Promise.resolve();

        const resolver = element.shadowRoot.querySelector('c-rflib-user-profile-resolver');
        expect(resolver).not.toBeNull();

        resolver.dispatchEvent(new CustomEvent('profileselected', { detail: 'Admin' }));

        await Promise.resolve();

        // This should trigger a search for 'Admin'
        const rows = element.shadowRoot.querySelectorAll('tbody tr');
        expect(rows.length).toBe(1);
        expect(rows[0].textContent).toContain('Admin');
    });
});
