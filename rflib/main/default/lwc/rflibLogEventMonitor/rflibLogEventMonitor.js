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
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

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
    }
};

const logger = createLogger('LogEventMonitor');

export default class LogEventMonitor extends LightningElement {
    @track page = 1;
    @track pageSize = DEFAULT_PAGE_SIZE;
    @track numDisplayedRecords;
    @track numTotalRecords;

    @track currentConnectionMode = CONNECTION_MODE.NEW_MESSAGES_ONLY;
    @track capturedEvents = [];
    @track selectedLogEvent = null;

    subscription = {};

    messageCallback = null;

    get hasLogEvent() {
        return this.selectedLogEvent != null;
    }

    get connectionModes() {
        const connectionModes = JSON.parse(
            JSON.stringify([
                CONNECTION_MODE.NEW_MESSAGES_ONLY,
                CONNECTION_MODE.HISTORIC_AND_NEW_MESSAGES,
                CONNECTION_MODE.DISCONNECTED
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

        this.messageCallback = function (msg) {
            logger.debug('New message received: ' + JSON.stringify(msg));
            _this.capturedEvents = [msg.data.payload, ..._this.capturedEvents];
            _this.numTotalRecords = _this.capturedEvents.length;
        };

        subscribe(CHANNEL, this.currentConnectionMode.value, this.messageCallback).then(
            this.createSubscriptionResponseHandler(this)
        );
    }

    changeConnectionMode(event) {
        const newConnectionMode = event.detail.value;
        logger.debug(
            'Connection Mode changed: newConnectionMode={0}, currentConnectionMode={1}',
            newConnectionMode,
            this.currentConnectionMode.value
        );

        const _this = this;
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

                logger.debug('this.currentConnectionMode: ' + JSON.stringify(_this.currentConnectionMode));
                subscribe(CHANNEL, _this.currentConnectionMode.value, _this.messageCallback).then(
                    _this.createSubscriptionResponseHandler(_this)
                );
            }
        };

        if (this.currentConnectionMode.value !== CONNECTION_MODE.DISCONNECTED.value) {
            unsubscribe(this.subscription, (response) => {
                logger.debug('unsubscribe() response: ', JSON.stringify(response));
                this.currentConnectionMode = CONNECTION_MODE.DISCONNECTED;
                this.subscription = null;

                connectToServer();
            });
        } else {
            connectToServer();
        }
    }

    clearLogs() {
        logger.debug('Clearing logs');
        this.capturedEvents = [];
        this.numTotalRecords = 0;
        this.selectedLogEvent = null;
    }

    createSubscriptionResponseHandler(component) {
        return function (response) {
            logger.debug('Successfully subscribed to: ' + response.channel);
            component.subscription = response;
        };
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
        this.numDisplayedRecords = event.detail;
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
