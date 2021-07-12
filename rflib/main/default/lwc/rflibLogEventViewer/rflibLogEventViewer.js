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
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { createLogger } from 'c/rflibLogger';

import NAME_FIELD from '@salesforce/schema/User.Name';
import PHONE_FIELD from '@salesforce/schema/User.Phone';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import PROFILE_FIELD from '@salesforce/schema/User.Profile.Name';

const FIELDS = [NAME_FIELD, PHONE_FIELD, EMAIL_FIELD, PROFILE_FIELD];

const LOGGER = createLogger('LogEventViewer');

export default class LogEventViewer extends LightningElement {
    @api userId;
    @api logEvent;

    @track user = {};

    @wire(getRecord, { recordId: '$userId', fields: FIELDS })
    wiredRecord({ error, data }) {
        LOGGER.debug('getRecord completed for id={0}', this.userId);
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            LOGGER.debug('Failed to retrieve user data. Details: {0}', message);
        } else if (data) {
            LOGGER.debug('User data: {0}', JSON.stringify(data));

            this.user = data;
        }
    }

    get title() {
        return this.logEvent.Request_ID__c + ' - ' + this.logEvent.Log_Level__c + ' - ' + this.logEvent.Context__c;
    }

    get name() {
        return getFieldValue(this.user, NAME_FIELD);
    }

    get phone() {
        return getFieldValue(this.user, PHONE_FIELD);
    }

    get email() {
        return getFieldValue(this.user, EMAIL_FIELD);
    }

    get profile() {
        return getFieldValue(this.user, PROFILE_FIELD);
    }

    get hasEvent() {
        return !!this.logEvent;
    }

    downloadLog() {
        var element = document.createElement('a');
        element.setAttribute(
            'href',
            'data:text/plain;charset=utf-8,' + encodeURIComponent(this.logEvent.Log_Messages__c)
        );
        element.setAttribute(
            'download',
            this.logEvent.CreatedById +
                '_' +
                this.logEvent.CreatedDate +
                '_' +
                this.logEvent.Request_ID__c +
                '_' +
                this.logEvent.Context__c +
                '.txt'
        );

        element.style.display = 'none';
        document.body.appendChild(element);

        element.click();

        document.body.removeChild(element);
    }
}
