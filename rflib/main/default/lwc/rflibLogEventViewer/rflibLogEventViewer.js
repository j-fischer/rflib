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
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApexLogsForRequestId from '@salesforce/apex/rflib_LogEventViewerController.getApexLogsForRequestId';

import NAME_FIELD from '@salesforce/schema/User.Name';
import PHONE_FIELD from '@salesforce/schema/User.Phone';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import PROFILE_FIELD from '@salesforce/schema/User.Profile.Name';

const FIELDS = [NAME_FIELD, PHONE_FIELD, EMAIL_FIELD, PROFILE_FIELD];

const APEX_LOG_DOWNLOAD_URL = '/servlet/servlet.FileDownload';

const LOGGER = createLogger('rflibLogEventViewer');

export default class RflibLogEventViewer extends LightningElement {
    @api userId;

    _logEvent;
    apexLogs = [];
    isLoadingLogs = false;

    @track user = {};
    showFieldSettings = false;
    fieldVisibility = {
        showDate: true,
        showCreatedBy: true,
        showLogLevel: true,
        showRequestId: true,
        showContext: true
    };

    @track processedLogMessages = [];

    @api
    get logEvent() {
        return this._logEvent;
    }
    set logEvent(value) {
        this._logEvent = value;
        if (this._logEvent?.Request_ID__c) {
            this.loadApexLogs();
        } else {
            this.apexLogs = [];
        }
        this.processLogMessages();
    }

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

    connectedCallback() {
        if (this.logEvent?.Request_ID__c) {
            this.loadApexLogs();
        }
    }

    loadApexLogs() {
        const requestId = this.logEvent.Request_ID__c;
        LOGGER.debug('loadApexLogs completed for id={0}', requestId);

        this.isLoadingLogs = true;
        getApexLogsForRequestId({ requestId: requestId })
            .then((result) => {
                LOGGER.debug('Retrieved Apex logs: ' + JSON.stringify(result));
                this.apexLogs = result;
            })
            .catch((error) => {
                LOGGER.error('Failed to retrieve Apex logs: ' + JSON.stringify(error));
                // Guard dispatchEvent for SSR compatibility
                if (!import.meta.env.SSR) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Loading Debug Logs',
                            message: error.body?.message || 'Unknown error occurred while loading debug logs',
                            variant: 'error'
                        })
                    );
                }
            })
            .finally(() => {
                this.isLoadingLogs = false;
            });
    }

    get hasApexLogs() {
        const result = this.apexLogs && this.apexLogs.length > 0;
        LOGGER.debug('hasApexLogs result={0}', result);
        return result;
    }

    handleDownloadMenuSelect(event) {
        const selectedValue = event.detail.value;

        if (selectedValue === 'rflib-log') {
            this.downloadRflibLog();
        } else if (selectedValue !== 'no-logs') {
            // selectedValue contains the log Id for individual Apex logs
            this.downloadApexLog(selectedValue);
        }
    }

    downloadRflibLog() {
        LOGGER.debug('Downloading RFLIB log file');

        const rflibLogFilename =
            this.createdBy +
            '_' +
            this.createdDate +
            '_' +
            this.logEvent.Request_ID__c +
            '_' +
            this.logEvent.Context__c +
            '.log';
        const rflibLogText =
            this.logEvent.Log_Messages__c +
            '\n\n>>> Platform Info:\n' +
            JSON.stringify(JSON.parse(this.logEvent.Platform_Info__c), null, 2);

        this.simulateDownload(rflibLogFilename, rflibLogText);
    }

    downloadApexLog(logId) {
        LOGGER.debug('Downloading Apex log: ' + logId);

        // Fetch is not supported in op_mini all, IE Mobile 11, IE 11, bb 10,
        fetch(`${APEX_LOG_DOWNLOAD_URL}?file=${logId}`)
            .then((response) => response?.text())
            .then((apexLogText) => {
                const apexLogFilename = `apex-${logId}.log`;
                this.simulateDownload(apexLogFilename, apexLogText);
            })
            .catch((error) => {
                LOGGER.error('There was a problem retrieving the ApexLog file contents:', error);
            });
    }

    simulateDownload(outputFilename, outputText) {
        const downloadLogLink = window.document.createElement('a');
        downloadLogLink.download = outputFilename;
        downloadLogLink.href = 'data:text/plain;charset=utf-8,' + encodeURIComponent(outputText);

        const downloadLogLinkContainer = this.template.querySelector('.download-container');
        downloadLogLinkContainer.appendChild(downloadLogLink);
        downloadLogLink.click();
        downloadLogLinkContainer.removeChild(downloadLogLink);
    }

    get createdBy() {
        return this.logEvent.CreatedById || this.logEvent.CreatedById__c;
    }

    get createdDate() {
        return this.logEvent.CreatedDate || this.logEvent.CreatedDate__c;
    }

    get title() {
        const parts = [];

        if (this.fieldVisibility.showRequestId && this.logEvent.Request_ID__c) {
            parts.push(this.logEvent.Request_ID__c);
        }

        if (this.fieldVisibility.showLogLevel && this.logEvent.Log_Level__c) {
            parts.push(this.logEvent.Log_Level__c);
        }

        if (this.fieldVisibility.showContext && this.logEvent.Context__c) {
            parts.push(this.logEvent.Context__c);
        }

        return parts.length > 0 ? parts.join(' - ') : 'Log Event';
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

    get isUserInfoNotAvailable() {
        return !this.user.id;
    }

    get platformInfo() {
        const platformInfo = JSON.parse(this.logEvent.Platform_Info__c) || {};
        const result = Object.keys(platformInfo).map((key, index) => {
            let value = platformInfo[key];
            if (typeof value === 'object') {
                value = JSON.stringify(value, null, 2);
            }

            return { key: key, value: value, index: index };
        });
        LOGGER.debug('platformInfo: ' + JSON.stringify(result));
        return result;
    }

    get apexLogCount() {
        return this.apexLogs ? this.apexLogs.length : 0;
    }

    get downloadButtonLabel() {
        return this.apexLogs?.length > 0 ? `(${this.apexLogs.length})` : '';
    }

    toggleFieldSettings() {
        LOGGER.debug('Toggling field settings visibility');
        this.showFieldSettings = !this.showFieldSettings;
    }

    handleFieldVisibilityChange(event) {
        const fieldName = event.target.name;
        const isChecked = event.target.checked;

        LOGGER.debug('Field visibility changed: {0}={1}', fieldName, isChecked);

        this.fieldVisibility = {
            ...this.fieldVisibility,
            [fieldName]: isChecked
        };
    }

    processLogMessages() {
        if (!this._logEvent?.Log_Messages__c) {
            this.processedLogMessages = [];
            return;
        }

        const logText = this._logEvent.Log_Messages__c;
        const messages = [];
        let messageId = 0;

        // Split by newlines and process each line
        const lines = logText.split('\n');

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            if (line.trim() === '') {
                continue;
            }

            // Check for embedded JSON in the line
            const processedLine = this.processLineWithEmbeddedJson(line, messageId);
            messages.push(...processedLine.messages);
            messageId = processedLine.nextId;
        }

        this.processedLogMessages = messages;
    }

    processLineWithEmbeddedJson(line, startId) {
        const messages = [];
        let currentId = startId;

        // Look for JSON patterns in the line
        const jsonRegex = /\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}|\[[^\[\]]*(?:\[[^\[\]]*\][^\[\]]*)*\]/g;
        let lastIndex = 0;
        let match;

        while ((match = jsonRegex.exec(line)) !== null) {
            const jsonCandidate = match[0];

            // Add any text before the JSON
            if (match.index > lastIndex) {
                const preText = line.substring(lastIndex, match.index).trim();
                if (preText) {
                    messages.push(this.createMessageObject(preText, currentId++, false));
                }
            }

            // Check if this is valid JSON
            if (this.isValidJson(jsonCandidate)) {
                messages.push(this.createMessageObject(jsonCandidate, currentId++, true));
            } else {
                // If not valid JSON, treat as text
                messages.push(this.createMessageObject(jsonCandidate, currentId++, false));
            }

            lastIndex = match.index + match[0].length;
        }

        // Add any remaining text after the last JSON
        if (lastIndex < line.length) {
            const remainingText = line.substring(lastIndex).trim();
            if (remainingText) {
                messages.push(this.createMessageObject(remainingText, currentId++, false));
            }
        }

        // If no JSON found, treat the entire line as text
        if (messages.length === 0) {
            messages.push(this.createMessageObject(line, currentId++, false));
        }

        return {
            messages: messages,
            nextId: currentId
        };
    }

    createMessageObject(content, id, forceJson = null) {
        const isJson = forceJson !== null ? forceJson : this.isValidJson(content.trim());

        if (isJson) {
            try {
                const parsedJson = JSON.parse(content.trim());
                const formattedJson = JSON.stringify(parsedJson, null, 2);
                const preview = this.createJsonPreview(parsedJson);

                return {
                    id: id,
                    content: content,
                    isJson: true,
                    isText: false,
                    isExpanded: false,
                    isCollapsed: true,
                    formattedJson: formattedJson,
                    preview: preview,
                    expandIcon: 'utility:chevronright',
                    expandLabel: 'Expand JSON'
                };
            } catch (e) {
                // If parsing fails, treat as text
            }
        }

        return {
            id: id,
            content: content,
            isJson: false,
            isText: true,
            isExpanded: false,
            isCollapsed: false
        };
    }

    isCompleteJson(text) {
        try {
            JSON.parse(text);
            return true;
        } catch (e) {
            return false;
        }
    }

    isValidJson(text) {
        if (!text || typeof text !== 'string') return false;

        const trimmed = text.trim();
        if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return false;

        try {
            const parsed = JSON.parse(trimmed);
            return typeof parsed === 'object';
        } catch (e) {
            return false;
        }
    }

    createJsonPreview(jsonObj) {
        if (Array.isArray(jsonObj)) {
            return `Array [${jsonObj.length} items]`;
        }

        if (typeof jsonObj === 'object' && jsonObj !== null) {
            const keys = Object.keys(jsonObj);
            const keyPreview = keys.slice(0, 3).join(', ');
            const remaining = keys.length > 3 ? `, +${keys.length - 3} more` : '';
            return `Object {${keyPreview}${remaining}}`;
        }

        return 'JSON Data';
    }

    toggleJsonExpansion(event) {
        const messageId = parseInt(event.currentTarget.dataset.messageId, 10);
        const messageIndex = this.processedLogMessages.findIndex((msg) => msg.id === messageId);

        if (messageIndex !== -1) {
            const messages = [...this.processedLogMessages];
            const message = { ...messages[messageIndex] };

            message.isExpanded = !message.isExpanded;
            message.isCollapsed = !message.isExpanded;
            message.expandIcon = message.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
            message.expandLabel = message.isExpanded ? 'Collapse JSON' : 'Expand JSON';

            messages[messageIndex] = message;
            this.processedLogMessages = messages;
        }
    }
}
