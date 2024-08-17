import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import getAssignedPermissionSets from '@salesforce/apex/rflib_UserPermSetManagerController.getAssignedPermissionSets';
import getAllPermissionSets from '@salesforce/apex/rflib_UserPermSetManagerController.getAllPermissionSets';
import assignPermissionSet from '@salesforce/apex/rflib_UserPermSetManagerController.assignPermissionSet';
import deletePermissionSetAssignment from '@salesforce/apex/rflib_UserPermSetManagerController.deletePermissionSetAssignment';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { createLogger } from 'c/rflibLogger';

const logger = createLogger('UserPermissionSetManager');

export default class RflibUserPermissionSetManager extends LightningElement {
    _wireUserPermissionResult;

    @api userAlias;
    @api title;

    @track userPermissionSets = [];
    @track permissionSetOptions = [];
    @track selectedPermissionSet = '';
    @track isDeleteModalOpen = false;
    @track isAssignModalOpen = false;
    @track selectedRecordId;
    @track isAssignButtonDisabled = true;

    columns = [
        { label: 'Label', fieldName: 'Label' },
        { label: 'Name', fieldName: 'Name' },
        {
            type: 'button-icon',
            typeAttributes: {
                iconName: 'utility:delete',
                title: 'Delete',
                variant: 'bare',
                alternativeText: 'Delete'
            }
        }
    ];

    @wire(getAssignedPermissionSets, { alias: '$userAlias' })
    wiredUserPermissionSets(wireResult) {
        this._wireUserPermissionResult = wireResult;
        const { data, error } = wireResult;
        if (data) {
            logger.info('Loaded user permission set for alias "{0}": {1}', this.userAlias, JSON.stringify(data));
            this.userPermissionSets = data;
        } else if (error) {
            logger.error('Failed to load user permission set: ' + JSON.stringify(error));
            this.showToast('Error', 'Failed to load permission sets', 'error');
        }
    }

    @wire(getAllPermissionSets)
    wiredAllPermissionSets({ error, data }) {
        if (data) {
            logger.info('Loaded all permission sets: ' + JSON.stringify(data));
            this.permissionSetOptions = data.map((ps) => ({ label: ps.Label + ' (' + ps.Name + ')', value: ps.Id }));
        } else if (error) {
            logger.error('Failed to load all permission sets: ' + JSON.stringify(error));
            this.showToast('Error', 'Failed to load all permission sets', 'error');
        }
    }

    handleRowAction(event) {
        this.selectedRecordId = event.detail.row.Id;
        this.isDeleteModalOpen = true;
    }

    handlePermissionSetChange(event) {
        this.selectedPermissionSet = event.detail.value;
        this.isAssignButtonDisabled = !this.selectedPermissionSet;
    }

    handleAssignClick() {
        this.isAssignModalOpen = true;
    }

    confirmDelete() {
        deletePermissionSetAssignment({ permissionSetAssignmentId: this.selectedRecordId })
            .then(() => {
                this.showToast('Success', 'Permission Set Assignment deleted', 'success');
                this.refreshData();
            })
            .catch((error) => {
                logger.error('Failed to delete Permission Set Assignment: ' + JSON.stringify(error));
                this.showToast('Error', 'Failed to delete Permission Set Assignment', 'error');
            });
        this.closeDeleteModal();
    }

    confirmAssign() {
        assignPermissionSet({ permissionSetId: this.selectedPermissionSet, alias: this.userAlias })
            .then(() => {
                this.showToast('Success', 'Permission Set Assigned', 'success');
                this.selectedPermissionSet = '';
                this.isAssignButtonDisabled = true;
                this.refreshData();
            })
            .catch((error) => {
                logger.error('Failed to add Permission Set Assignment: ' + JSON.stringify(error));
                this.showToast('Error', 'Failed to assign Permission Set', 'error');
            });
        this.closeAssignModal();
    }

    closeDeleteModal() {
        this.isDeleteModalOpen = false;
    }

    closeAssignModal() {
        this.isAssignModalOpen = false;
    }

    refreshData() {
        return refreshApex(this._wireUserPermissionResult);
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }
}
