/*
 * Copyright (c) 2019 Johannes Fischer <fischer.jh@gmail.com>
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
 * https://www.sfdcpoint.com/salesforce/modal-popup-lightning-web-component-lwc/
 */
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getUserByUserId from '@salesforce/apex/rflib_UserProfileResolverController.getUserByUserId';

import { createLogger } from 'c/rflibLogger';

const logger = createLogger('RflibUserProfileResolver');

export default class RflibUserProfileResolver extends LightningElement {
    userId = '';
    isModalOpen = false;

    user = {};

    userFilter = {
        criteria: [
            {
                fieldPath: 'IsActive',
                operator: 'eq',
                value: true
            }
        ]
    };
    userMatchingInfo = {
        primaryField: { fieldPath: 'Name' }
    };

    openModal() {
        logger.debug('Opening dialog');
        this.isModalOpen = true;
    }

    closeModal() {
        logger.debug('Closing dialog');
        this.isModalOpen = false;
    }

    handleUserIdChanged(event) {
        let newUserId = event.detail.recordId;
        if (this.userId !== newUserId) {
            logger.debug('Setting user ID={0}', newUserId);
            this.userId = newUserId;
        }
    }

    insertProfile() {
        logger.debug('Inserting profile');

        getUserByUserId({ userId: this.userId })
            .then((result) => {
                logger.debug('Received user details: {0}', JSON.stringify(result));

                const profileSelectedEvent = new CustomEvent('profileselected', { detail: result.Profile.Name });

                this.dispatchEvent(profileSelectedEvent);
                this.closeModal();
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
            })
            .finally(() => {
                this.isModalOpen = false;
            });
    }
}
