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
 * 3. Neither the name of mosquitto nor the names of its
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
import { subscribe, onError } from 'lightning/empApi';

const CHANNEL = '/event/rflib_Log_Event__e';
const DEFAULT_PAGE_SIZE = 10;

const logger = createLogger('LogEventMonitor');

export default class LogEventMonitor extends LightningElement {
    @track page = 1;
    @track pageSize = DEFAULT_PAGE_SIZE;
    @track numDisplayedRecords;
    @track numTotalRecords;

    @track connected = false;
    @track capturedEvents = [];
    @track selectedLogEvent = null;

    subscription = {};

    get hasLogEvent() {
        return this.selectedLogEvent != null;
    }

    connectedCallback() {
        let _this = this;
        const messageCallback = function(msg) {
            logger.debug('New message received: ' + JSON.stringify(msg));
            _this.capturedEvents = [msg.data.payload, ..._this.capturedEvents];
            _this.numTotalRecords = _this.capturedEvents.length;
        };

        subscribe(CHANNEL, -2, messageCallback).then(response => {
            logger.debug('Successfully subscribed to: ' + response.channel);
            this.subscription = response;
            this.connected = true;
        });
    }

    clearLogs() {
        logger.debug('Clearing logs');
        this.capturedEvents = [];
        this.numTotalRecords = 0;
        this.selectedLogEvent = null;
    }

    registerErrorListener() {
        logger.debug('Registering Error Listener');
        onError(error => {
            logger.debug('Received error from server: {0}', JSON.stringify(error));
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
        if (this.page < this.totalPages) this.page = this.page + 1;
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
        logger.debug('Records loaded,  count={0}', event.detail);
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
