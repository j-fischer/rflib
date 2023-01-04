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
