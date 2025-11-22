/*
 * Copyright (c) 2022 Johannes Fischer <fischer.jh@gmail.com>
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
import { api, LightningElement } from 'lwc';
import { createLogger } from 'c/rflibLogger';
import getUserPermissionAssignments from '@salesforce/apex/rflib_UserPermAssignmentController.getUserPermissionAssignments';

const DEFAULT_PAGE_SIZE = 25;

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

    userPermissionAssignments = [];
    data = [];
    columns = columns;

    page = 1;
    pageSize = DEFAULT_PAGE_SIZE;
    totalPages;
    numTotalRecords;
    numDisplayedRecords;
    async connectedCallback() {
        logger.debug('Initializing component, DEFAULT_PAGE_SIZE={0}', DEFAULT_PAGE_SIZE);

        const args = {
            permSetApiName: this.permissionSetName,
            shouldBeAssigned: this.isAssigned
        };

        logger.debug('Retrieving user info: ' + JSON.stringify(args));

        const _this = this;
        getUserPermissionAssignments(args)
            .then((result) => {
                logger.debug('Users identified={0}', JSON.stringify(result));
                _this.userPermissionAssignments = result;
                _this.numTotalRecords = result.length;
                _this.totalPages = Math.ceil(_this.numTotalRecords / DEFAULT_PAGE_SIZE);
                _this.handlePageChanged();
            })
            .catch((ex) => logger.error('Failed to retrieve user permission information', ex));
    }

    handlePageChanged() {
        logger.debug('Navigate to previous page, current page={0}', this.page);

        let startIndex = (this.page - 1) * DEFAULT_PAGE_SIZE;
        this.data = this.userPermissionAssignments.slice(startIndex, startIndex + DEFAULT_PAGE_SIZE);
        this.numDisplayedRecords = this.data.length;
    }

    handlePrevious() {
        logger.debug('Navigate to previous page, current page={0}', this.page);
        if (this.page > 1) {
            this.page = this.page - 1;
            this.handlePageChanged();
        }
    }
    handleNext() {
        logger.debug('Navigate to next page, current page={0}', this.page);
        if (this.page < this.totalPages) {
            this.page = this.page + 1;
            this.handlePageChanged();
        }
    }

    handleFirst() {
        logger.debug('Navigate to first page, current page={0}', this.page);
        this.page = 1;
        this.handlePageChanged();
    }

    handleLast() {
        logger.debug('Navigate to last page, current page={0}', this.page);
        this.page = this.totalPages;
        this.handlePageChanged();
    }

    handleGoToPage(evt) {
        logger.debug('Navigate to page, current page={0}', evt.detail);
        this.page = evt.detail;
        this.handlePageChanged();
    }

    handlePageChange(event) {
        logger.debug('Page changed, current page={0}', event.detail);
        this.page = event.detail;
        this.handlePageChanged();
    }
}
