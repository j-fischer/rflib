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
import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createLogger } from 'c/rflibLogger';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { CurrentPageReference } from 'lightning/navigation';

import getArchivedRecords from '@salesforce/apex/rflib_LogArchiveController.getArchivedRecords';
import clearArchive from '@salesforce/apex/rflib_LogArchiveController.clearArchive';

import { loadStyle } from 'lightning/platformResourceLoader';
import hideHeaderCSS from '@salesforce/resourceUrl/rflib_HidePageHeader';

const FIELD_VISIBILITY_KEY = 'rflib_log_viewer_field_visibility';

const CHANNEL = '/event/rflib_Log_Event__e';
const DEFAULT_PAGE_SIZE = 10;
const CONNECTION_MODE = {
    HISTORIC_AND_NEW_MESSAGES: {
        id: '1',
        value: -2,
        label: 'Historic and New Messages'
    },
    NEW_MESSAGES_ONLY: {
        id: '2',
        value: -1,
        label: 'New Messages'
    },
    DISCONNECTED: {
        id: '3',
        value: 0,
        label: 'Not Connected'
    },
    ARCHIVE: {
        id: '4',
        value: 1,
        label: 'Archive'
    }
};

const logger = createLogger('LogEventMonitor');

export default class LogEventMonitor extends LightningElement {
    page = 1;
    pageSize = DEFAULT_PAGE_SIZE;
    numDisplayedRecords = 0;
    numTotalRecords = 0;

    debugEnabled = false;
    isClearArchiveDialogVisible = false;
    currentConnectionMode = CONNECTION_MODE.NEW_MESSAGES_ONLY;
    capturedEvents = [];
    selectedLogEvent = null;
    selectedLogEventCreatedById = null;
    startDate = null;
    endDate = null;

    subscription = null;
    showLeftColumn = true;
    isExporting = false;

    fieldVisibility = {
        showDate: true,
        showLogLevel: true,
        showCreatedBy: true,
        showRequestId: true,
        showContext: true
    };

    get isArchiveMode() {
        return this.currentConnectionMode === CONNECTION_MODE.ARCHIVE;
    }

    get isLogEventSelected() {
        return this.selectedLogEvent != null;
    }

    get isExpandButtonDisabled() {
        return !this.isLogEventSelected;
    }

    get leftColumnClass() {
        return this.showLeftColumn ? 'slds-col slds-size_7-of-12 left-column' : 'slds-hide';
    }

    get rightColumnClass() {
        return this.showLeftColumn
            ? 'slds-col slds-size_5-of-12 container right-column'
            : 'slds-col slds-size_1-of-1 container right-column full-width';
    }

    exportToCsv() {
        logger.debug('Exporting to CSV');
        this.isExporting = true;

        setTimeout(() => {
            try {
                const logEventList = this.template.querySelector('c-rflib-log-event-list');
                if (!logEventList) {
                    logger.error('Log event list component not found');
                    this.isExporting = false;
                    return;
                }

                const records = logEventList.getFilteredRecords();
                logger.debug('Retrieved {0} records for export', records.length);

                if (records.length === 0) {
                    const evt = new ShowToastEvent({
                        title: 'No records to export',
                        message: 'There are no log events to export.',
                        variant: 'info'
                    });
                    if (!import.meta.env.SSR) {
                        this.dispatchEvent(evt);
                    }
                    this.isExporting = false;
                    return;
                }

                const csvHeader = '"Date","Created By","Request ID","Level","Context","Log Messages"\r\n';
                let csvContent = csvHeader;

                records.forEach((rec) => {
                    const date = rec.CreatedDate || rec.CreatedDate__c || '';
                    const createdBy = rec.CreatedById || rec.CreatedById__c || '';
                    const requestId = rec.Request_ID__c || '';
                    const level = rec.Log_Level__c || '';
                    const context = rec.Context__c || '';

                    let rawMessages = rec.Log_Messages__c || '';
                    if (rawMessages.length > 32000) {
                        rawMessages = '[TRUNCATED] ...' + rawMessages.substring(rawMessages.length - 32000);
                    }
                    const messages = rawMessages.replace(/"/g, '""'); // Escape double quotes

                    csvContent += `"${date}","${createdBy}","${requestId}","${level}","${context}","${messages}"\r\n`;
                });

                const element = document.createElement('a');
                element.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent));

                const modeLabel = this.currentConnectionMode.label.replace(/\s+/g, '_');
                const fileName = `Log_Events_${modeLabel}_${new Date().toISOString()}.csv`;

                element.setAttribute('download', fileName);
                element.style.display = 'none';

                const downloadContainer = this.template.querySelector('.download-container');
                downloadContainer.appendChild(element);

                element.click();
                downloadContainer.removeChild(element);
            } catch (error) {
                logger.error('Failed to export to CSV: {0}', error.message);
                const evt = new ShowToastEvent({
                    title: 'Export Failed',
                    message: 'An error occurred while exporting to CSV: ' + error.message,
                    variant: 'error'
                });
                if (!import.meta.env.SSR) {
                    this.dispatchEvent(evt);
                }
            } finally {
                this.isExporting = false;
            }
        }, 0);
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__debug) {
            logger.debug('Enabling EMP API debug mode');
            this.debugEnabled = true;
        } else {
            logger.debug('EMP API debug mode not enabled');
        }
    }

    get connectionModes() {
        const connectionModes = JSON.parse(
            JSON.stringify([
                CONNECTION_MODE.NEW_MESSAGES_ONLY,
                CONNECTION_MODE.HISTORIC_AND_NEW_MESSAGES,
                CONNECTION_MODE.DISCONNECTED,
                CONNECTION_MODE.ARCHIVE
            ])
        );

        let i,
            len = connectionModes.length;
        for (i = 0; i < len; i++) {
            const mode = connectionModes[i];
            mode.disabled = mode.value === this.currentConnectionMode.value;
        }

        return connectionModes;
    }

    connectedCallback() {
        let _this = this;

        logger.debug('Initializing LogEventMonitor component');
        this.registerErrorListener();

        const messageCallback = function (msg) {
            logger.debug('New message received: ' + JSON.stringify(msg));
            _this.capturedEvents = [msg.data.payload, ..._this.capturedEvents];
            _this.numTotalRecords = _this.capturedEvents.length;
            logger.debug('Updated total records count to {0}', _this.numTotalRecords);
        };

        if (_this.debugEnabled) {
            setDebugFlag(true).then((result) => {
                logger.debug('setDebugFlag() successful: ' + result);
            });
        }

        isEmpEnabled()
            .then((result) => {
                logger.debug('isEmpEnabled? ' + result);
                if (result === false) {
                    const evt = new ShowToastEvent({
                        title: 'EMP API not enabled',
                        message: 'Log Monitor will not work without EMP API enabled.',
                        variant: 'error'
                    });
                    if (!import.meta.env.SSR) {
                        _this.dispatchEvent(evt);
                    }
                }

                return subscribe(CHANNEL, _this.currentConnectionMode.value, messageCallback);
            })
            .then((response) => {
                logger.debug('Successfully subscribed to: ' + response.channel);
                _this.subscription = response;
                const evt = new ShowToastEvent({
                    title: 'Connection Mode Changed',
                    message: 'You are now connected to receive ' + _this.currentConnectionMode.label,
                    variant: 'success'
                });
                if (!import.meta.env.SSR) {
                    _this.dispatchEvent(evt);
                }
            });

        loadStyle(this, hideHeaderCSS).catch((error) => {
            logger.error('Error loading custom CSS for header hiding: {0}', error.message);
        });

        this.loadFieldVisibilitySettings();
    }

    disconnectedCallback() {
        logger.debug('Disconnecting LogEventMonitor component');
        this.unsubscribeConnection();
    }

    unsubscribeConnection() {
        const _this = this;

        return new Promise((resolve) => {
            if (_this.subscription) {
                logger.debug('Unsubscribing current connection: ' + _this.currentConnectionMode.value);
                unsubscribe(_this.subscription, (response) => {
                    logger.debug('unsubscribe() response: {0}', JSON.stringify(response));
                    _this.subscription = null;
                    resolve();
                });
            } else {
                logger.debug('No current subscription');
                resolve();
            }
        });
    }

    changeConnectionMode(event) {
        const _this = this;
        const newConnectionMode = event.detail.value;
        logger.debug(
            'Connection Mode changed: newConnectionMode={0}, currentConnectionMode={1}',
            newConnectionMode,
            _this.currentConnectionMode.value
        );

        if (newConnectionMode >= 0) {
            _this.unsubscribeConnection();

            if (!import.meta.env.SSR) {
                _this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Disconnected from event channel',
                        message: 'You are no longer receiving any log events.',
                        variant: 'warn'
                    })
                );
            }

            if (newConnectionMode === CONNECTION_MODE.DISCONNECTED.value) {
                logger.debug('Disconnecting from event channel; no further action required');
                _this.currentConnectionMode = CONNECTION_MODE.DISCONNECTED;
                return;
            }

            const args = {
                startDate: this.startDate,
                endDate: this.endDate
            };
            getArchivedRecords(args)
                .then((result) => {
                    _this.capturedEvents = result.records;
                    _this.numTotalRecords = result.records.length;
                    _this.currentConnectionMode = CONNECTION_MODE.ARCHIVE;
                    logger.debug('Archive query successful: retrieved {0} records', result.records.length);

                    if (result.queryLimit === _this.numTotalRecords) {
                        const evt = new ShowToastEvent({
                            title: 'Query Limit Reached',
                            message:
                                'The number of records retrieved reached the configured query limit of ' +
                                result.queryLimit +
                                ' records. Please change the search criteria to retrieve all records.',
                            variant: 'warning'
                        });
                        if (!import.meta.env.SSR) {
                            this.dispatchEvent(evt);
                        }
                    }
                })
                .catch((ex) => {
                    logger.debug('Failed to retrieve archived records: ' + JSON.stringify(ex));
                    const evt = new ShowToastEvent({
                        title: 'Failed to retrieve archived records',
                        message: 'An error occurred: ' + (ex instanceof String ? ex : JSON.stringify(ex)),
                        variant: 'error'
                    });
                    if (!import.meta.env.SSR) {
                        this.dispatchEvent(evt);
                    }
                });

            return;
        }

        const connectToServer = function () {
            logger.debug('connectToServer()');
            if (newConnectionMode) {
                _this.currentConnectionMode =
                    newConnectionMode === CONNECTION_MODE.NEW_MESSAGES_ONLY.value
                        ? CONNECTION_MODE.NEW_MESSAGES_ONLY
                        : CONNECTION_MODE.HISTORIC_AND_NEW_MESSAGES;

                if (_this.currentConnectionMode.value === CONNECTION_MODE.HISTORIC_AND_NEW_MESSAGES.value) {
                    _this.clearLogs();
                }

                const messageCallback = function (msg) {
                    logger.debug('New message received: ' + JSON.stringify(msg));
                    _this.capturedEvents = [msg.data.payload, ..._this.capturedEvents];
                    _this.numTotalRecords = _this.capturedEvents.length;
                    logger.debug('Updated total records count to {0}', _this.numTotalRecords);
                };

                logger.debug('this.currentConnectionMode: ' + JSON.stringify(_this.currentConnectionMode));
                subscribe(CHANNEL, _this.currentConnectionMode.value, messageCallback).then((response) => {
                    logger.debug('Successfully subscribed to: ' + response.channel);
                    _this.subscription = response;

                    const evt = new ShowToastEvent({
                        title: 'Connection Mode Changed',
                        message: 'You are now connected to receive ' + _this.currentConnectionMode.label,
                        variant: 'success'
                    });
                    if (!import.meta.env.SSR) {
                        _this.dispatchEvent(evt);
                    }
                });
            } else {
                logger.debug('Connection deactivated');
                _this.currentConnectionMode = CONNECTION_MODE.DISCONNECTED;
                const evt = new ShowToastEvent({
                    title: 'Disconnected from event channel',
                    message: 'You are no longer receiving any log events.',
                    variant: 'warn'
                });
                if (!import.meta.env.SSR) {
                    _this.dispatchEvent(evt);
                }
            }
        };

        if (this.subscription) {
            logger.debug('Unsubscribing from current subscription');
            this.unsubscribeConnection().then(connectToServer);
        } else {
            logger.debug('No current subscription');
            connectToServer();
        }
    }

    clearLogs() {
        logger.debug('Clearing logs');
        this.capturedEvents = [];
        this.numTotalRecords = 0;
        this.selectedLogEvent = null;
        this.selectedLogEventCreatedById = null;
        logger.debug('Cleared all log data and selections');
    }

    clearArchive() {
        logger.debug('Clearing archive');
        this.isClearArchiveDialogVisible = true;
    }

    handleClearArchiveConfirmation(event) {
        logger.debug('handleClearArchiveConfirmation: ' + event.detail);
        if (event.detail !== 1) {
            if (event.detail.status === 'confirm') {
                this.capturedEvents = [];
                this.numTotalRecords = 0;
                this.selectedLogEvent = null;
                this.selectedLogEventCreatedById = null;
                logger.debug('Reset UI state before clearing archive');

                clearArchive()
                    .then((result) => {
                        logger.debug('Archive cleared, count = ' + result);
                        const evt = new ShowToastEvent({
                            title: 'Request successful',
                            message: 'Cleared ' + result + ' archived records.',
                            variant: 'info'
                        });
                        if (!import.meta.env.SSR) {
                            this.dispatchEvent(evt);
                        }
                    })
                    .catch((ex) => {
                        logger.debug('Failed to clear archive: ' + JSON.stringify(ex));
                        const evt = new ShowToastEvent({
                            title: 'Failed to clear archived records',
                            message: 'An error occurred: ' + (ex instanceof String ? ex : JSON.stringify(ex)),
                            variant: 'error'
                        });
                        if (!import.meta.env.SSR) {
                            this.dispatchEvent(evt);
                        }
                    });
            } else if (event.detail.status === 'cancel') {
                logger.debug('Cancelled clearing of archive');
            }
        } else {
            logger.debug('Closed dialog');
        }

        this.isClearArchiveDialogVisible = false;
    }

    queryArchive() {
        const _this = this;
        const args = {
            startDate: this.startDate,
            endDate: this.endDate
        };
        getArchivedRecords(args)
            .then((result) => {
                _this.capturedEvents = result.records;
                _this.numTotalRecords = result.records.length;
                _this.currentConnectionMode = CONNECTION_MODE.ARCHIVE;
                logger.debug('Manual archive query successful: retrieved {0} records', result.records.length);

                if (result.queryLimit === _this.numTotalRecords) {
                    const evt = new ShowToastEvent({
                        title: 'Query Limit Reached',
                        message:
                            'The number of records retrieved reached the configured query limit of ' +
                            result.queryLimit +
                            ' records. Please change the search criteria to retrieve all records.',
                        variant: 'warning'
                    });
                    if (!import.meta.env.SSR) {
                        this.dispatchEvent(evt);
                    }
                }
            })
            .catch((ex) => {
                logger.debug('Failed to retrieve archived records: ' + JSON.stringify(ex));
                const evt = new ShowToastEvent({
                    title: 'Failed to retrieve archived records',
                    message: 'An error occurred: ' + (ex instanceof String ? ex : JSON.stringify(ex)),
                    variant: 'error'
                });
                if (!import.meta.env.SSR) {
                    this.dispatchEvent(evt);
                }
            });
    }

    registerErrorListener() {
        logger.debug('Registering Error Listener');
        onError((error) => {
            logger.debug('Received error from server: {0}', JSON.stringify(error));
            this.currentConnectionMode = CONNECTION_MODE.DISCONNECTED;
        });
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
        logger.debug('Records loaded, count={0}', event.detail);
        const eventDetails = JSON.parse(event.detail);

        this.page = eventDetails.currentPage;
        this.numDisplayedRecords = eventDetails.numDisplayedRecords;
        this.totalPages = Math.ceil(this.numDisplayedRecords / this.pageSize);
        logger.debug(
            'Updated pagination: page={0}, displayedRecords={1}, totalPages={2}',
            this.page,
            this.numDisplayedRecords,
            this.totalPages
        );
    }

    handlePageChange(event) {
        logger.debug('Page changed, current page={0}', event.detail);
        this.page = event.detail;
    }

    handleLogSelected(event) {
        const logEvent = JSON.parse(event.detail);
        logger.debug('Log selected with id={0}', logEvent.Id);

        this.selectedLogEventCreatedById = logEvent.CreatedById || logEvent.CreatedById__c;
        this.selectedLogEvent = logEvent;
        logger.debug(
            'Selected log event details: createdById={0}, logLevel={1}',
            this.selectedLogEventCreatedById,
            logEvent.Log_Level__c
        );
    }

    handleStartDateChanged(event) {
        if (this.startDate !== event.target.value) {
            logger.debug('Start date changed={0}', event.target.value);
            this.startDate = event.target.value;
        }
    }

    handleEndDateChanged(event) {
        if (this.endDate !== event.target.value) {
            logger.debug('End date changed={0}', event.target.value);
            this.endDate = event.target.value;
        }
    }

    handleToggleFullscreen() {
        logger.debug('Toggling left column visibility for fullscreen, current state={0}', this.showLeftColumn);
        this.showLeftColumn = !this.showLeftColumn;
    }

    get tooltipFullscreen() {
        return this.showLeftColumn ? 'Hide left panel' : 'Show right list of log events';
    }

    handleCloseViewer() {
        logger.debug('Closing log viewer');
        this.selectedLogEvent = null;
        this.selectedLogEventCreatedById = null;
        this.showLeftColumn = true;
    }

    handleFieldVisibilityMenuSelect(event) {
        const fieldName = event.detail.value;
        const currentValue = this.fieldVisibility[fieldName];

        logger.debug('Field visibility changed: {0}={1}', fieldName, !currentValue);

        this.fieldVisibility = {
            ...this.fieldVisibility,
            [fieldName]: !currentValue
        };

        this.saveFieldVisibilitySettings();
    }

    saveFieldVisibilitySettings() {
        try {
            sessionStorage.setItem(FIELD_VISIBILITY_KEY, JSON.stringify(this.fieldVisibility));
            logger.debug(
                'Saved field visibility settings to session storage: {0}',
                JSON.stringify(this.fieldVisibility)
            );
        } catch (error) {
            logger.error('Failed to save field visibility settings to session storage: {0}', error.message);
        }
    }

    loadFieldVisibilitySettings() {
        try {
            const stored = sessionStorage.getItem(FIELD_VISIBILITY_KEY);
            if (stored) {
                const parsedSettings = JSON.parse(stored);
                this.fieldVisibility = {
                    ...this.fieldVisibility,
                    ...parsedSettings
                };
                logger.debug(
                    'Loaded field visibility settings from session storage: {0}',
                    JSON.stringify(this.fieldVisibility)
                );
            } else {
                logger.debug('No stored field visibility settings found, using defaults');
            }
        } catch (error) {
            logger.error('Failed to load field visibility settings from session storage: {0}', error.message);
        }
    }
}
