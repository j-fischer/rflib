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

    get isArchiveMode() {
        return this.currentConnectionMode === CONNECTION_MODE.ARCHIVE;
    }

    get hasLogEvent() {
        return this.selectedLogEvent != null;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__debug) {
            logger.debug('Enabling EMP API debug mode');
            this.debugEnabled = true;
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

        this.registerErrorListener();

        const messageCallback = function (msg) {
            logger.debug('New message received: ' + JSON.stringify(msg));
            _this.capturedEvents = [msg.data.payload, ..._this.capturedEvents];
            _this.numTotalRecords = _this.capturedEvents.length;
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
                    _this.dispatchEvent(evt);
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
                _this.dispatchEvent(evt);
            });
    }

    disconnectedCallback() {
        const _this = this;
        if (_this.subscription) {
            logger.debug('disconnecting current connection: ' + _this.currentConnectionMode.value);
            return unsubscribe(_this.subscription, (response) => {
                logger.debug('unsubscribe() response: {0}', JSON.stringify(response));
                _this.subscription = null;
            });
        }
        return Promise.resolve();
    }

    changeConnectionMode(event) {
        const _this = this;
        const newConnectionMode = event.detail.value;
        logger.debug(
            'Connection Mode changed: newConnectionMode={0}, currentConnectionMode={1}',
            newConnectionMode,
            _this.currentConnectionMode.value
        );

        if (newConnectionMode > 0) {
            _this.disconnectedCallback();

            _this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Disconnected from event channel',
                    message: 'You are no longer receiving any log events.',
                    variant: 'warn'
                })
            );

            const args = {
                startDate: this.startDate,
                endDate: this.endDate
            };
            getArchivedRecords(args)
                .then((result) => {
                    _this.capturedEvents = result.records;
                    _this.numTotalRecords = result.records.length;
                    _this.currentConnectionMode = CONNECTION_MODE.ARCHIVE;

                    if (result.queryLimit === _this.numTotalRecords) {
                        const evt = new ShowToastEvent({
                            title: 'Query Limit Reached',
                            message:
                                'The number of records retrieved reached the configured query limit of ' +
                                result.queryLimit +
                                ' records. Please change the search criteria to retrieve all records.',
                            variant: 'warning'
                        });
                        this.dispatchEvent(evt);
                    }
                })
                .catch((ex) => {
                    logger.debug('Failed to retrieve archived records: ' + JSON.stringify(ex));
                    const evt = new ShowToastEvent({
                        title: 'Failed to retrieve archived records',
                        message: 'An error occurred: ' + (ex instanceof String ? ex : JSON.stringify(ex)),
                        variant: 'error'
                    });
                    this.dispatchEvent(evt);
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
                    _this.dispatchEvent(evt);
                });
            } else {
                logger.debug('Connection deactivated');
                _this.currentConnectionMode = CONNECTION_MODE.DISCONNECTED;
                const evt = new ShowToastEvent({
                    title: 'Disconnected from event channel',
                    message: 'You are no longer receiving any log events.',
                    variant: 'warn'
                });
                _this.dispatchEvent(evt);
            }
        };

        if (this.subscription) {
            logger.debug('Unsubscribing from current subscription');
            this.disconnectedCallback().then(() => {
                connectToServer();
            });
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

                clearArchive()
                    .then(() => {
                        logger.debug('Archive cleared');
                    })
                    .catch((ex) => {
                        logger.debug('Failed to clear archive: ' + JSON.stringify(ex));
                        const evt = new ShowToastEvent({
                            title: 'Failed to clear archived records',
                            message: 'An error occurred: ' + (ex instanceof String ? ex : JSON.stringify(ex)),
                            variant: 'error'
                        });
                        this.dispatchEvent(evt);
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

                if (result.queryLimit === _this.numTotalRecords) {
                    const evt = new ShowToastEvent({
                        title: 'Query Limit Reached',
                        message:
                            'The number of records retrieved reached the configured query limit of ' +
                            result.queryLimit +
                            ' records. Please change the search criteria to retrieve all records.',
                        variant: 'warning'
                    });
                    this.dispatchEvent(evt);
                }
            })
            .catch((ex) => {
                logger.debug('Failed to retrieve archived records: ' + JSON.stringify(ex));
                const evt = new ShowToastEvent({
                    title: 'Failed to retrieve archived records',
                    message: 'An error occurred: ' + (ex instanceof String ? ex : JSON.stringify(ex)),
                    variant: 'error'
                });
                this.dispatchEvent(evt);
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
}
