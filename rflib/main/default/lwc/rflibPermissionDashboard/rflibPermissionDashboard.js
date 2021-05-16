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
import { LightningElement, track } from 'lwc';
import { createLogger } from 'c/rflibLogger';
import getFieldLevelSecurityForAllProfiles from '@salesforce/apex/rflib_PermissionDashboardController.getFieldLevelSecurityForAllProfiles';
//import getFieldLevelSecurityForAllPermissionSets from '@salesforce/apex/rflib_PermissionDashboardController.getFieldLevelSecurityForAllPermissionSets';

const DEFAULT_PAGE_SIZE = 10;
const PERMISSION_TYPES = {
    OBJECT_PERMISSIONS: {
        id: '1',
        value: 'ObjectPermissions',
        label: 'Object Permission'
    },
    FIELD_PERMISSIONS: {
        id: '2',
        value: 'FieldPermissions',
        label: 'Field Permissions'
    }
};

const logger = createLogger('PermissionDashboard');

export default class LogEventMonitor extends LightningElement {
    @track page = 1;
    @track pageSize = DEFAULT_PAGE_SIZE;
    @track numDisplayedRecords;
    @track numTotalRecords;

    @track currentPermissionType = PERMISSION_TYPES.FIELD_PERMISSIONS;
    @track permissionRecords = [];

    connectedCallback() {
        getFieldLevelSecurityForAllProfiles()
            .then((result) => {
                logger.debug('Received field permissions for all profiles, size={0}', result.length);
                this.permissionRecords = result;
                this.numTotalRecords = result.length;
            })
            .catch((error) => {
                logger.debug('Failed to retrieve field permissions for all profiles', error);
            });
    }

    get isFieldPermissions() {
        return this.currentPermissionType === PERMISSION_TYPES.FIELD_PERMISSIONS;
    }

    get permissionTypes() {
        const permissionTypes = JSON.parse(
            JSON.stringify([PERMISSION_TYPES.OBJECT_PERMISSIONS, PERMISSION_TYPES.FIELD_PERMISSIONS])
        );

        let i,
            len = permissionTypes.length;
        for (i = 0; i < len; i++) {
            const mode = permissionTypes[i];
            mode.disabled = this.currentPermissionType !== null && mode.value === this.currentPermissionType.value;
        }

        return permissionTypes;
    }

    changePermissionType(event) {
        const newPermissionType = event.detail.value;
        logger.debug(
            'Permission Type changed: newPermissionType={0}, currentPermissionType={1}',
            newPermissionType,
            this.currentPermissionType.value
        );

        //const _this = this;
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

    handleLogSelected(event) {
        const logEvent = JSON.parse(event.detail);
        logger.debug('Log selected with id={0}', logEvent.Id);

        this.selectedLogEvent = logEvent;
    }
}
