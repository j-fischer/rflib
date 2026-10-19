/*
 * Copyright (c) 2026 Johannes Fischer <fischer.jh@gmail.com>
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
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecords } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createLogger } from 'c/rflibLogger';

const logger = createLogger('BigObjectRecordViewer');

const ID_PATTERN = /^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/;
const ID_CHECKSUM_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345';
const USER_KEY_PREFIX = '005';

/**
 * Detects a Salesforce record id by its shape, so any field holding one becomes a link, not only fields named
 * after ids. An 18 character id must also carry a valid case-safe checksum, and a 15 character id must contain a
 * digit, which keeps ordinary words of that length from being mistaken for ids.
 */
function isSalesforceId(value) {
    if (typeof value !== 'string' || !ID_PATTERN.test(value)) {
        return false;
    }
    if (value.length === 15) {
        return /\d/.test(value);
    }

    let checksum = '';
    for (let block = 0; block < 3; block++) {
        let bits = 0;
        for (let i = 0; i < 5; i++) {
            const character = value.charAt(block * 5 + i);
            if (character >= 'A' && character <= 'Z') {
                bits += 1 << i;
            }
        }
        checksum += ID_CHECKSUM_CHARACTERS.charAt(bits);
    }
    return checksum === value.substring(15);
}

function formatJson(value) {
    const trimmed = value.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
        return null;
    }
    try {
        return JSON.stringify(JSON.parse(trimmed), null, 2);
    } catch (e) {
        return null;
    }
}

export default class RflibBigObjectRecordViewer extends NavigationMixin(LightningElement) {
    @api title;

    _record;
    _fields = [];

    items = [];
    userNames = {};
    userRecordsParameter;

    // Per-field display state of the long text blocks, kept across records so a choice sticks while browsing.
    collapsedFields = {};
    rawFields = {};

    @api
    get record() {
        return this._record;
    }
    set record(value) {
        this._record = value;
        this.updateUserRecordsParameter();
        this.buildItems();
    }

    @api
    get fields() {
        return this._fields;
    }
    set fields(value) {
        this._fields = value || [];
        this.updateUserRecordsParameter();
        this.buildItems();
    }

    get hasRecord() {
        return !!this._record;
    }

    get cardTitle() {
        return this.title || 'Record Details';
    }

    @wire(getRecords, { records: '$userRecordsParameter' })
    wiredUsers({ error, data }) {
        if (data) {
            const userNames = {};
            data.results.forEach((result) => {
                if (result.statusCode === 200 && result.result) {
                    userNames[result.result.id] = result.result.fields.Name.value;
                }
            });
            this.userNames = userNames;
            this.buildItems();
        } else if (error) {
            logger.debug('Failed to resolve user names: {0}', JSON.stringify(error));
        }
    }

    updateUserRecordsParameter() {
        const userIds = new Set();
        this._fields.forEach((field) => {
            const value = this._record && this._record[field.apiName];
            if (isSalesforceId(value) && value.startsWith(USER_KEY_PREFIX)) {
                userIds.add(value);
            }
        });

        const recordIds = Array.from(userIds);
        if (recordIds.join(',') === (this.userRecordsParameter?.[0].recordIds || []).join(',')) {
            return;
        }

        // An undefined parameter keeps the wire from firing when the record references no user.
        this.userRecordsParameter = recordIds.length > 0 ? [{ recordIds, fields: ['User.Name'] }] : undefined;
    }

    buildItems() {
        if (!this._record) {
            this.items = [];
            return;
        }

        this.items = this._fields.map((field) => {
            const value = this._record[field.apiName];
            const isEmpty = value == null || value === '';
            const item = {
                key: field.apiName,
                label: field.label,
                value,
                isEmpty,
                isDatetime: !isEmpty && field.dataType === 'datetime',
                isDate: !isEmpty && field.dataType === 'date',
                isNumber: !isEmpty && field.dataType === 'number',
                isLongText: !isEmpty && field.dataType === 'longtext',
                isId: false,
                isText: false
            };

            if (item.isLongText) {
                const formatted = formatJson(value);
                const showRaw = !formatted || this.rawFields[field.apiName] === true;
                item.isJson = !!formatted;
                item.isExpanded = this.collapsedFields[field.apiName] !== true;
                item.displayValue = showRaw ? value : formatted;
                item.formatLabel = showRaw ? 'Show Formatted' : 'Show Raw';
                item.expandLabel = item.isExpanded ? 'Collapse' : 'Expand';
            } else if (!isEmpty && field.dataType === 'text' && isSalesforceId(value)) {
                item.isId = true;
                item.userName = this.userNames[value];
            } else if (!item.isDatetime && !item.isDate && !item.isNumber) {
                item.isText = true;
            }
            return item;
        });
    }

    handleToggleExpanded(event) {
        const fieldName = event.target.dataset.field;
        this.collapsedFields = { ...this.collapsedFields, [fieldName]: !(this.collapsedFields[fieldName] === true) };
        this.buildItems();
    }

    handleToggleFormat(event) {
        const fieldName = event.target.dataset.field;
        this.rawFields = { ...this.rawFields, [fieldName]: !(this.rawFields[fieldName] === true) };
        this.buildItems();
    }

    handleNavigateToRecord(event) {
        const recordId = event.target.dataset.id;
        logger.debug('Navigating to record {0}', recordId);
        // The id may belong to a deleted or inaccessible record. Checking every id up front would cost a query per
        // value, so the record page is left to report that.
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId, actionName: 'view' }
            });
        } catch (error) {
            logger.error('Failed to navigate to record {0}: {1}', recordId, error.message);
            this.showToast('Navigation failed', 'The record ' + recordId + ' could not be opened.', 'error');
        }
    }

    handleCopyId(event) {
        this.copyToClipboard(event.target.dataset.id, 'Record ID copied');
    }

    handleCopyRecord() {
        // A Big Object record has no Id and cannot be linked to, so copying it whole is how it gets into a ticket.
        this.copyToClipboard(JSON.stringify(this._record, null, 2), 'Record copied as JSON');
    }

    handleToggleFullscreen() {
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new CustomEvent('togglefullscreen'));
        }
    }

    handleClose() {
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new CustomEvent('closeviewer'));
        }
    }

    async copyToClipboard(text, successTitle) {
        try {
            await navigator.clipboard.writeText(text);
            this.showToast(successTitle, null, 'success');
        } catch (error) {
            logger.error('Failed to copy to the clipboard: {0}', error.message);
            this.showToast('Copy failed', 'The browser did not allow access to the clipboard.', 'error');
        }
    }

    showToast(title, message, variant) {
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
        }
    }
}
