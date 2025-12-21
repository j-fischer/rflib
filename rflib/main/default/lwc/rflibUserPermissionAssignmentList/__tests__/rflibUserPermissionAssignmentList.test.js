import { createElement } from 'lwc';
import RflibUserPermissionAssignmentList from 'c/rflibUserPermissionAssignmentList';
import getUserPermissionAssignments from '@salesforce/apex/rflib_UserPermAssignmentController.getUserPermissionAssignments';

// Mock Apex
jest.mock(
    '@salesforce/apex/rflib_UserPermAssignmentController.getUserPermissionAssignments',
    () => {
        return {
            default: jest.fn()
        };
    },
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

const MOCK_DATA = Array.from({ length: 30 }, (_, i) => ({
    id: `user${i}`,
    name: `User ${i}`,
    email: `user${i}@test.com`,
    phone: '555-555-5555',
    profile: 'Standard User'
}));

async function flushPromises() {
    return Promise.resolve();
}

describe('c-rflib-user-permission-assignment-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('initializes and loads data correctly', async () => {
        getUserPermissionAssignments.mockResolvedValue(MOCK_DATA);

        const element = createElement('c-rflib-user-permission-assignment-list', {
            is: RflibUserPermissionAssignmentList
        });
        element.permissionSetName = 'TestPermSet';
        element.isAssigned = true;
        element.title = 'Test Title';
        document.body.appendChild(element);

        // Verify title
        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card.title).toBe('Test Title');

        // Wait for asynchronous data loading
        await flushPromises();
        await flushPromises();

        // Verify Apex call
        expect(getUserPermissionAssignments).toHaveBeenCalledWith({
            permSetApiName: 'TestPermSet',
            shouldBeAssigned: true
        });

        // Verify Datatable
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data.length).toBe(25); // Default page size is 25

        // Verify Paginator
        const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
        expect(paginator).not.toBeNull();
        expect(paginator.currentPage).toBe(1);
        expect(paginator.totalRecords).toBe(30);
    });

    it('handles pagination events correctly', async () => {
        getUserPermissionAssignments.mockResolvedValue(MOCK_DATA);

        const element = createElement('c-rflib-user-permission-assignment-list', {
            is: RflibUserPermissionAssignmentList
        });
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
        const datatable = element.shadowRoot.querySelector('lightning-datatable');

        // Initial state
        expect(datatable.data[0].id).toBe('user0');

        // Next Page
        paginator.dispatchEvent(new CustomEvent('next'));
        await flushPromises();
        expect(datatable.data.length).toBe(5); // 30 - 25 = 5
        expect(datatable.data[0].id).toBe('user25');

        // Previous Page
        paginator.dispatchEvent(new CustomEvent('previous'));
        await flushPromises();
        expect(datatable.data.length).toBe(25);
        expect(datatable.data[0].id).toBe('user0');

        // Go to last
        paginator.dispatchEvent(new CustomEvent('last'));
        await flushPromises();
        expect(datatable.data[0].id).toBe('user25');

        // Go to first
        paginator.dispatchEvent(new CustomEvent('first'));
        await flushPromises();
        expect(datatable.data[0].id).toBe('user0');

        // Go to page
        paginator.dispatchEvent(new CustomEvent('gotopage', { detail: 2 }));
        await flushPromises();
        expect(datatable.data[0].id).toBe('user25');
    });

    it('handles pagination bounds correctly', async () => {
        getUserPermissionAssignments.mockResolvedValue(MOCK_DATA);

        const element = createElement('c-rflib-user-permission-assignment-list', {
            is: RflibUserPermissionAssignmentList
        });
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
        const datatable = element.shadowRoot.querySelector('lightning-datatable');

        // Try going previous from page 1 (should stay on page 1)
        paginator.dispatchEvent(new CustomEvent('previous'));
        await flushPromises();
        expect(datatable.data[0].id).toBe('user0');

        // Go to last page (page 2)
        paginator.dispatchEvent(new CustomEvent('last'));
        await flushPromises();

        // Try going next from last page (should stay on page 2)
        paginator.dispatchEvent(new CustomEvent('next'));
        await flushPromises();
        expect(datatable.data[0].id).toBe('user25');
    });

    it('handles error when loading data', async () => {
        const consoleErrorMock = jest.spyOn(console, 'error').mockImplementation(() => {});
        const error = { body: { message: 'An error occurred' } };
        getUserPermissionAssignments.mockRejectedValue(error);

        const element = createElement('c-rflib-user-permission-assignment-list', {
            is: RflibUserPermissionAssignmentList
        });
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable.data).toEqual([]);

        consoleErrorMock.mockRestore();
    });
});
