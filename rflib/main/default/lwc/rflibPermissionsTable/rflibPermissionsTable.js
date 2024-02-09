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
 *
 * This component was inspired by:
 * https://salesforcelightningwebcomponents.blogspot.com/2019/04/pagination-with-search-step-by-step.html
 */
import { LightningElement, api } from 'lwc';
import { createLogger } from 'c/rflibLogger';

const logger = createLogger('FieldPermissionsTable');

export default class RflibFieldPermissionsTable extends LightningElement {
    _pageSize;

    @api permissionType;
    @api isProfilePermissions;
    @api isUserMode;

    @api
    get currentPage() {
        return this.currentPageIndex + 1;
    }
    set currentPage(value) {
        const newPageIndex = value - 1;
        if (this.currentPageIndex !== newPageIndex) {
            logger.debug('Changing current page {0}', newPageIndex);
            this.currentPageIndex = newPageIndex;
            this.refreshEventList();
        }
    }

    @api
    get permissionRecords() {
        return this.allRecords;
    }
    set permissionRecords(value) {
        this.allRecords = value;
        this.refreshEventList();
    }

    @api
    get pageSize() {
        return this._pageSize;
    }
    set pageSize(value) {
        this._pageSize = value;
        this.currentPageIndex = 0;
        this.refreshEventList();
    }

    filteredRecordCount;
    recordsToDisplay = [];

    securityObjectNameSearch;
    objectSearch;
    fieldSearch;

    @api
    get title() {
        return this.filteredRecordCount + ' Displayed Permissions';
    }

    get isObjectPermissions() {
        return this.permissionType === 'OLS';
    }

    get isFieldPermissions() {
        return this.permissionType === 'FLS';
    }

    get isApexPermissions() {
        return this.permissionType === 'APX';
    }

    get isNotApexPermissions() {
        return this.permissionType !== 'APX';
    }

    totalPages = 1;
    currentPageIndex = 0;
    displayedPageIndex;

    allRecords;
    filteredRecords = [];

    connectedCallback() {
        logger.debug('Initializing');
        this.refreshEventList();
    }

    refreshEventList() {
        this.displayedPageIndex = this.currentPageIndex;
        logger.debug(
            'Display page with index {0} (permissionType={1}, isFieldPermission={2}, isObjectPermissions={3}, isApexPermissions={4}, isUserMode={5})',
            this.currentPageIndex,
            this.permissionType,
            this.isFieldPermissions,
            this.isObjectPermissions,
            this.isApexPermissions,
            this.isUserMode
        );

        if (!this.isFieldPermissions) {
            this.fieldSearch = null;
        }

        const filteredRecords =
            this.securityObjectNameSearch || this.objectSearch || this.fieldSearch
                ? this.allRecords.filter(
                      (rec) =>
                          (!this.securityObjectNameSearch ||
                              rec.SecurityObjectName.indexOf(this.securityObjectNameSearch) > -1) &&
                          (!this.objectSearch || rec.SobjectType.indexOf(this.objectSearch) > -1) &&
                          (!this.fieldSearch || rec.Field.indexOf(this.fieldSearch) > -1)
                  )
                : this.allRecords;

        this.filteredRecords = filteredRecords.map(function (rec, index) {
            const modifiedRec = { ...rec };
            modifiedRec.id = index;
            return modifiedRec;
        });
        this.filteredRecordCount = this.filteredRecords.length;

        logger.debug('Filtered records count {0}', this.filteredRecordCount);

        if (this.filteredRecordCount > 0) {
            this.totalPages = Math.ceil(this.filteredRecordCount / this._pageSize);

            const startIndex = this.currentPageIndex * this._pageSize;
            this.recordsToDisplay = this.filteredRecords.slice(startIndex, startIndex + this._pageSize);
        } else {
            this.recordsToDisplay = [];
            this.totalPages = 1;
        }

        const event = new CustomEvent('refreshed', {
            detail: JSON.stringify({
                numDisplayedRecords: this.filteredRecordCount,
                currentPage: this.currentPageIndex + 1
            })
        });
        this.dispatchEvent(event);
    }

    executeSearch() {
        logger.debug(
            'Executing search for profile/permission set={0}, object={1}, field={2}',
            this.securityObjectNameSearch,
            this.objectSearch,
            this.fieldSearch
        );
        this.currentPageIndex = 0;
        this.refreshEventList();
    }

    handleSecurityObjectNameKeyPress(event) {
        if (event.which === 13) {
            this.executeSearch();
        }
    }

    handleSecurityObjectNameChanged(event) {
        if (this.securityObjectNameSearch !== event.target.value) {
            logger.debug('Setting security object search target={0}', event.target.value);
            this.securityObjectNameSearch = event.target.value;
        }
    }

    handleObjectSearchKeyPress(event) {
        if (event.which === 13) {
            this.executeSearch();
        }
    }

    handleObjectSearchKeyChange(event) {
        if (this.objectSearch !== event.target.value) {
            logger.debug('Setting object search target={0}', event.target.value);
            this.objectSearch = event.target.value;
        }
    }

    handleFieldSearchKeyPress(event) {
        if (event.which === 13) {
            this.executeSearch();
        }
    }

    handleFieldSearchKeyChange(event) {
        if (this.fieldSearch !== event.target.value) {
            logger.debug('Setting field search target={0}', event.target.value);
            this.fieldSearch = event.target.value;
        }
    }

    handleProfileSelected(event) {
        logger.debug('Profile selected, name={0}', event.detail);
        const profileName = event.detail;

        this.securityObjectNameSearch = profileName;
        this.executeSearch();
    }
}
