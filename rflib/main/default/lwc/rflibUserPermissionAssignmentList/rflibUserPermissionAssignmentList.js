import { api, LightningElement } from 'lwc';
import { createLogger } from 'c/rflibLogger';
import getUserPermissionAssignments from '@salesforce/apex/rflib_UserPermAssignmentController.getUserPermissionAssignments';

const logger = createLogger('UserPermissionAssignmentList');

const columns = [
    { label: 'Name', fieldName: 'name', sortable: true },
    { label: 'Email', fieldName: 'email', type: 'email', sortable: true },
    { label: 'Phone', fieldName: 'phone', type: 'phone', sortable: true },
    { label: 'Profile', fieldName: 'profile', sortable: true }
];

export default class RflibUserPermissionAssignmentList extends LightningElement {
    @api permissionSetName;
    @api isAssigned;
    @api title;

    data = [];
    columns = columns;

    // eslint-disable-next-line @lwc/lwc/no-async-await
    async connectedCallback() {
        logger.debug('Initializing component');

        const args = {
            permSetApiName: this.permissionSetName,
            shouldBeAssigned: this.isAssigned
        };

        logger.debug('Retrieving user info: ' + JSON.stringify(args));

        const _this = this;
        getUserPermissionAssignments(args)
            .then((result) => {
                logger.debug('Users identified={0}', JSON.stringify(result));
                _this.data = result;
            })
            .catch((ex) => logger.error('Failed to retrieve user permission information', ex));
    }
}
