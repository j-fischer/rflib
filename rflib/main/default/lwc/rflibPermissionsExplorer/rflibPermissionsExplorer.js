/*
 * Copyright (c) 2021 Johannes Fischer <fischer.jh@gmail.com>
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
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createLogger } from 'c/rflibLogger';
import getFieldLevelSecurityForAllProfiles from '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllProfiles';
import getFieldLevelSecurityForAllPermissionSets from '@salesforce/apex/rflib_PermissionsExplorerController.getFieldLevelSecurityForAllPermissionSets';
import getObjectLevelSecurityForAllProfiles from '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllProfiles';
import getObjectLevelSecurityForAllPermissionSets from '@salesforce/apex/rflib_PermissionsExplorerController.getObjectLevelSecurityForAllPermissionSets';

const DEFAULT_PAGE_SIZE = 10;
const PERMISSION_TYPES = {
    OBJECT_PERMISSIONS_PROFILES: {
        id: '1',
        value: 'ObjectPermissionsProfiles',
        label: 'Object Permission For Profiles'
    },
    OBJECT_PERMISSIONS_PERMISSION_SETS: {
        id: '2',
        value: 'ObjectPermissionsPermissionSets',
        label: 'Object Permission For Permission Sets'
    },
    FIELD_PERMISSIONS_PROFILES: {
        id: '3',
        value: 'FieldPermissionsProfiles',
        label: 'Field Permissions for Profiles'
    },
    FIELD_PERMISSIONS_PERMISSION_SETS: {
        id: '4',
        value: 'FieldPermissionsPermissionSets',
        label: 'Field Permissions for Permission Sets'
    }
};

const OBJECT_PERMISSIONS_CSV_HEADER =
    '"PROFILE/PERMISSION SET","OBJECT","READ ACCESS","CREATE ACCESS","EDIT ACCESS","DELETE ACCESS","VIEW ALL","MODIFY ALL"\r\n';
const FIELD_PERMISSIONS_CSV_HEADER = '"PROFILE/PERMISSION SET","OBJECT","FIELD","READ ACCESS","EDIT ACCESS"\r\n';

const logger = createLogger('PermissionsExplorer');

export default class PermissionsExplorer extends LightningElement {
    page = 1;
    pageSize = DEFAULT_PAGE_SIZE;
    numDisplayedRecords;
    numTotalRecords;

    currentPermissionType = PERMISSION_TYPES.OBJECT_PERMISSIONS_PROFILES;
    permissionRecords = [];
    isLoadingRecords = false;
    progressText = 'Loading Permissions';

    cache = {};

    connectedCallback() {
        this.loadPermissions();
    }

    get isFieldPermissions() {
        return (
            this.currentPermissionType === PERMISSION_TYPES.FIELD_PERMISSIONS_PROFILES ||
            this.currentPermissionType === PERMISSION_TYPES.FIELD_PERMISSIONS_PERMISSION_SETS
        );
    }

    get isProfilePermissions() {
        return (
            this.currentPermissionType === PERMISSION_TYPES.OBJECT_PERMISSIONS_PROFILES ||
            this.currentPermissionType === PERMISSION_TYPES.FIELD_PERMISSIONS_PROFILES
        );
    }

    get permissionTypes() {
        const permissionTypes = JSON.parse(
            JSON.stringify([
                PERMISSION_TYPES.OBJECT_PERMISSIONS_PROFILES,
                PERMISSION_TYPES.OBJECT_PERMISSIONS_PERMISSION_SETS,
                PERMISSION_TYPES.FIELD_PERMISSIONS_PROFILES,
                PERMISSION_TYPES.FIELD_PERMISSIONS_PERMISSION_SETS
            ])
        );

        let i,
            len = permissionTypes.length;
        for (i = 0; i < len; i++) {
            const mode = permissionTypes[i];
            mode.disabled = this.currentPermissionType !== null && mode.value === this.currentPermissionType.value;
        }

        return permissionTypes;
    }

    get hasRecords() {
        return this.numTotalRecords > 0;
    }

    changePermissionType(event) {
        const newPermissionType = event.detail.value;
        logger.debug(
            'Permission Type changed: newPermissionType={0}, currentPermissionType={1}',
            newPermissionType,
            this.currentPermissionType.value
        );

        this.currentPermissionType = Object.keys(PERMISSION_TYPES)
            .map((key) => PERMISSION_TYPES[key])
            .find((permType) => permType.value === newPermissionType);

        this.loadPermissions();
    }

    loadPermissions() {
        logger.debug('Loading permissions for type: ' + this.currentPermissionType.value);

        let remoteAction = null;
        switch (this.currentPermissionType.value) {
            case PERMISSION_TYPES.OBJECT_PERMISSIONS_PROFILES.value:
                remoteAction = getObjectLevelSecurityForAllProfiles;
                break;

            case PERMISSION_TYPES.OBJECT_PERMISSIONS_PERMISSION_SETS.value:
                remoteAction = getObjectLevelSecurityForAllPermissionSets;
                break;

            case PERMISSION_TYPES.FIELD_PERMISSIONS_PROFILES.value:
                remoteAction = getFieldLevelSecurityForAllProfiles;
                break;

            case PERMISSION_TYPES.FIELD_PERMISSIONS_PERMISSION_SETS.value:
                remoteAction = getFieldLevelSecurityForAllPermissionSets;
                break;

            default:
                logger.error('Unknown permission type: ' + this.currentPermissionType.value);
        }

        this.permissionRecords = [];
        this.numTotalRecords = 0;

        const loadingPermissionsLabel = 'Loading Permissions';
        this.progressText = loadingPermissionsLabel;

        const retrievePermissionsCallback = (result) => {
            logger.debug('Received field permission records: nextRecordsUrl={0}', result.nextRecordsUrl);
            this.permissionRecords = this.permissionRecords.concat(result.records);
            this.numTotalRecords = this.permissionRecords.length;

            this.progressText =
                loadingPermissionsLabel + ' (' + this.numTotalRecords + ' / ' + result.totalNumOfRecords + ')';

            if (result.nextRecordsUrl) {
                return remoteAction({ servicePath: result.nextRecordsUrl }).then(retrievePermissionsCallback);
            }

            this.isLoadingRecords = false;

            if (this.numTotalRecords < result.totalNumOfRecords) {
                const evt = new ShowToastEvent({
                    title: 'Permissions Incomplete',
                    message:
                        'Only ' +
                        this.numTotalRecords +
                        ' of ' +
                        result.totalNumOfRecords +
                        ' permission records were retrieved. To load all records, please enable the REST API functionality.',
                    variant: 'warning',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
            }

            this.page = 1;

            return Promise.resolve();
        };

        this.isLoadingRecords = true;

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            // The cached responses for a permission type instead of making the HTTP requests.
            // Using timeout to guarantee rendering of spinner widget, which may not happen if the browser accesses

            const cachedRecords = this.cache[this.currentPermissionType.value];
            if (cachedRecords) {
                logger.debug('Using cached value');
                this.permissionRecords = cachedRecords;
                this.numTotalRecords = cachedRecords.length;
                this.isLoadingRecords = false;
                this.page = 1;
                return;
            }

            remoteAction()
                .then(retrievePermissionsCallback)
                .then(() => {
                    logger.debug('Caching result');
                    this.cache[this.currentPermissionType.value] = this.permissionRecords;
                })
                .catch((error) => {
                    logger.error(
                        'Failed to retrieve all field permissions for all profiles. Error={0}',
                        JSON.stringify(error)
                    );
                    this.isLoadingRecords = false;

                    const evt = new ShowToastEvent({
                        title: 'Failed to retrieve permissions',
                        message: 'An error occurred: ' + (error instanceof String ? error : JSON.stringify(error)),
                        variant: 'error'
                    });
                    this.dispatchEvent(evt);
                });
        }, 0);
    }

    exportToCsv() {
        logger.debug('Export to CSV: type={0}, numRecords={1}', this.currentPermissionType.value, this.numTotalRecords);
        let csvContent = '';

        if (this.isFieldPermissions) {
            csvContent += FIELD_PERMISSIONS_CSV_HEADER;

            let i;
            for (i = 0; i < this.numTotalRecords; i++) {
                let permission = this.permissionRecords[i];
                csvContent +=
                    '"' +
                    permission.SecurityObjectName +
                    '","' +
                    permission.SobjectType +
                    '","' +
                    permission.Field +
                    '","' +
                    permission.PermissionsRead +
                    '","' +
                    permission.PermissionsEdit +
                    '"\r\n';
            }
        } else {
            csvContent += OBJECT_PERMISSIONS_CSV_HEADER;

            let i;
            for (i = 0; i < this.numTotalRecords; i++) {
                let permission = this.permissionRecords[i];
                csvContent +=
                    '"' +
                    permission.SecurityObjectName +
                    '","' +
                    permission.SobjectType +
                    '","' +
                    permission.PermissionsRead +
                    '","' +
                    permission.PermissionsCreate +
                    '","' +
                    permission.PermissionsEdit +
                    '","' +
                    permission.PermissionsDelete +
                    '","' +
                    permission.PermissionsViewAllRecords +
                    '","' +
                    permission.PermissionsModifyAllRecords +
                    '"\r\n';
            }
        }

        let element = document.createElement('a');
        element.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent));
        element.setAttribute('download', this.currentPermissionType.value + '_' + new Date().toISOString() + '.csv');

        element.style.display = 'none';
        
        let downloadContainer = this.template.querySelector('.download-container');
        downloadContainer.appendChild(element);

        element.click();

        downloadContainer.removeChild(element);
    }

    handlePrevious() {
        logger.debug('Navigate to previous page, current page={0}', this.page);
        if (this.page > 1) {
            this.page = this.page - 1;
        }
    }
    handleNext() {
        logger.debug('Navigate to next page, current page={0}', this.page);
        if (this.page < this.totalPages) {
            this.page = this.page + 1;
        }
    }

    handleFirst() {
        logger.debug('Navigate to first page, current page={0}', this.page);
        this.page = 1;
    }

    handleLast() {
        logger.debug('Navigate to last page, current page={0}', this.page);
        this.page = this.totalPages;
    }

    handleGoToPage(evt) {
        logger.debug('Navigate to page, current page={0}', evt.detail);
        this.page = evt.detail;
    }

    handleRefreshed(event) {
        logger.debug('Records loaded, details={0}', event.detail);
        const eventDetails = JSON.parse(event.detail);

        this.page = eventDetails.currentPage;
        this.numDisplayedRecords = eventDetails.numDisplayedRecords;
        this.totalPages = Math.ceil(this.numDisplayedRecords / this.pageSize);
    }

    handlePageChange(event) {
        logger.debug('Page changed, current page={0}', event.detail);
        this.page = event.detail;
    }
}
