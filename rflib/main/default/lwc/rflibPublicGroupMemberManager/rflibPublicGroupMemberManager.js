/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name "RFLIB", the name of the copyright holder, nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

import { LightningElement, api } from 'lwc';

import canUserModifyGroupMemberships from '@salesforce/apex/rflib_PublicGroupMemberManagerController.canUserModifyGroupMemberships';
import getGroupMembers from '@salesforce/apex/rflib_PublicGroupMemberManagerController.getGroupMembers';
import addUserToGroup from '@salesforce/apex/rflib_PublicGroupMemberManagerController.addUserToGroup';
import removeUserFromGroup from '@salesforce/apex/rflib_PublicGroupMemberManagerController.removeUserFromGroup';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createLogger } from 'c/rflibLogger';

const logger = createLogger('rflibPublicGroupMemberManager');

export default class RflibPublicGroupMemberManager extends LightningElement {
    @api title;
    @api groupApiName;

    isLoading = false;
    canModifyGroups = false;
    groupMembers = [];
    selectedUserId;
    isAddButtonDisabled = true;
    showDeleteConfirmation = false;
    userToRemoveId;
    deleteDialogTitle = 'Confirm Removal';
    deleteDialogMessage = 'Are you sure you want to remove this user from the group?';

    columns = [];

    connectedCallback() {
        logger.debug('Component initialized with groupApiName: {0}', this.groupApiName);
        this.checkUserPermissions().finally(this.loadGroupMembers());
    }

    checkUserPermissions() {
        logger.debug('Checking if the user can modify custom settings.');
        return canUserModifyGroupMemberships()
            .then((result) => {
                this.canModifyGroups = result;
                this.columns = this.createColumns();
                logger.debug('User permission check result: {0}', result);
            })
            .catch((error) => {
                logger.error('Error occurred while checking user permissions: {0}', JSON.stringify(error));
                this.showToast('Error', error.body.message, 'error');
            });
    }

    loadGroupMembers() {
        logger.debug('Loading group members for groupApiName: {0}', this.groupApiName);
        getGroupMembers({ groupApiName: this.groupApiName })
            .then((data) => {
                logger.debug('Group members retrieved successfully: {0}', JSON.stringify(data));
                this.groupMembers = data;
            })
            .catch((error) => {
                logger.error('Error loading group members: {0}', JSON.stringify(error));
                this.showToast('Error', 'Failed to load group members.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    createColumns() {
        logger.debug('addColumnActionsIfApplicable() invoked: canModifyGroups=' + this.canModifyGroups);
        const cols = [
            {
                label: 'Name',
                fieldName: 'Name',
                type: 'text'
            },
            {
                label: 'Email',
                fieldName: 'Email',
                type: 'email'
            }
        ];

        if (this.canModifyGroups) {
            cols.push({
                type: 'action',
                typeAttributes: {
                    rowActions: [{ label: 'Remove', name: 'remove' }],
                    menuAlignment: 'right'
                }
            });
        }
        return cols;
    }

    handleUserSelect(event) {
        this.selectedUserId = event.detail.recordId;
        if (this.selectedUserId) {
            this.isAddButtonDisabled = false;
            logger.debug('User selected for addition: {0}', this.selectedUserId);
        } else {
            this.isAddButtonDisabled = true;
            logger.debug('No user selected.');
        }
    }

    handleAddUser() {
        logger.debug('Adding user to group:', this.selectedUserId);
        addUserToGroup({ groupApiName: this.groupApiName, userId: this.selectedUserId })
            .then(() => {
                logger.debug('User added to group successfully: {0}', this.selectedUserId);
                this.showToast('Success', 'User added to the group.', 'success');
                this.selectedUserId = null;
                this.isAddButtonDisabled = true;
                this.loadGroupMembers();
            })
            .catch((error) => {
                logger.error('Error adding user to group: {0}', JSON.stringify(error));
                this.showToast('Error', error.body.message || 'Failed to add user to the group.', 'error');
            });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        logger.debug("Row action '{0}' triggered for user: {1}", actionName, row.Id);
        if (actionName === 'remove') {
            this.userToRemoveId = row.Id;
            this.showDeleteConfirmation = true;
        }
    }

    handleModalAction(event) {
        const action = event.detail.status;
        logger.debug(`Modal action received: ${action}`);
        if (action === 'confirm') {
            this.confirmDelete();
        }
        this.showDeleteConfirmation = false;
        this.userToRemoveId = null;
    }

    confirmDelete() {
        logger.debug('Removing user from group: {0}', this.userToRemoveId);
        removeUserFromGroup({ groupApiName: this.groupApiName, userId: this.userToRemoveId })
            .then(() => {
                logger.debug('User removed from group successfully: {0}', this.userToRemoveId);
                this.showToast('Success', 'User removed from the group.', 'success');
                this.loadGroupMembers();
            })
            .catch((error) => {
                logger.error('Error removing user from group: {0}', JSON.stringify(error));
                this.showToast('Error', error.body.message || 'Failed to remove user from the group.', 'error');
            });
    }

    showToast(title, message, variant) {
        logger.debug(`Showing toast - Title: ${title}, Message: ${message}, Variant: ${variant}`);
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
        }
    }
}
