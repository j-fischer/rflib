import { api, LightningElement } from 'lwc';
import { createLogger } from 'c/rflibLogger';

const logger = createLogger('UserPermissionAssignmentList');

const columns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Email', fieldName: 'email', type: 'email' },
    { label: 'Phone', fieldName: 'phone', type: 'phone' },
    { label: 'Profile', fieldName: 'profile' }
];

export default class RflibUserPermissionAssignmentList extends LightningElement {
    @api permissionSetName;
    @api isAssigned;

    data = [];
    columns = columns;

    // eslint-disable-next-line @lwc/lwc/no-async-await
    async connectedCallback() {
        logger.debug('Initializing component');
        const data = {
            name: 'Johannes Fischer',
            email: 'fischer.jh@gmail.com',
            phone: '4037143138',
            profile: 'System Administrator'
        };
        this.data = data;
    }
}
