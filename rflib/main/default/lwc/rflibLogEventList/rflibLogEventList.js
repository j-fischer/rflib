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
 *
 * This component was inspired by:
 * https://salesforcelightningwebcomponents.blogspot.com/2019/04/pagination-with-search-step-by-step.html
 */
import { LightningElement, api } from 'lwc';
import { createLogger } from 'c/rflibLogger';

const logger = createLogger('LogEventList');

export default class LogEventList extends LightningElement {
    @api pageSize;

    @api
    get currentPage() {
        return this.currentPageIndex + 1;
    }
    set currentPage(value) {
        this.currentPageIndex = value - 1;
        this.refreshEventList();
    }

    @api
    get logEvents() {
        return this.allEvents;
    }
    set logEvents(value) {
        this.allEvents = value || [];
        this.refreshEventList();
    }

    filteredRecordCount;
    eventsToDisplay = [];

    levelSearch;
    contextSearch;
    createdBySearch;
    logMessageSearch;

    @api
    get title() {
        return this.filteredRecordCount + ' Displayed Log Events';
    }

    totalPages = 1;
    currentPageIndex = 0;
    displayedPageIndex;
    selectedRow;

    allEvents = [];
    filteredEvents = [];

    connectedCallback() {
        logger.debug('Initializing');
        this.refreshEventList();
    }

    refreshEventList() {
        if (this.selectedRow) {
            this.selectedRow.classList.remove('selected');
        }

        this.displayedPageIndex = this.currentPageIndex;
        logger.debug('Display page with index {0}', this.currentPageIndex);

        const filteredEvents =
            this.contextSearch || this.levelSearch || this.createdBySearch || this.logMessageSearch
                ? this.allEvents.filter(
                      (evt) =>
                          (!this.createdBySearch ||
                              (evt.CreatedById || evt.CreatedById__c).indexOf(this.createdBySearch) > -1) &&
                          (!this.levelSearch || evt.Log_Level__c.indexOf(this.levelSearch) > -1) &&
                          (!this.contextSearch || evt.Context__c.indexOf(this.contextSearch) > -1) &&
                          (!this.logMessageSearch || evt.Log_Messages__c.indexOf(this.logMessageSearch) > -1)
                  )
                : this.allEvents;

        this.filteredEvents = filteredEvents.map(function (evt, index) {
            const modifiedEvt = { ...evt };
            modifiedEvt.Id = index;
            return modifiedEvt;
        });
        this.filteredRecordCount = this.filteredEvents.length;

        logger.debug('Total records count {0}', this.filteredRecordCount);

        if (this.filteredRecordCount > 0) {
            this.totalPages = Math.ceil(this.filteredRecordCount / this.pageSize);

            const startIndex = this.currentPageIndex * this.pageSize;
            this.eventsToDisplay = this.filteredEvents.slice(startIndex, startIndex + this.pageSize);
        } else {
            this.eventsToDisplay = [];
            this.totalPages = 1;
        }

        const event = new CustomEvent('refreshed', {
            detail: JSON.stringify({
                numDisplayedRecords: this.filteredRecordCount,
                currentPage: this.currentPageIndex + 1
            })
        });
        this.dispatchEvent(event);
    }

    handleCreatedByChanged(event) {
        if (this.createdBySearch !== event.target.value) {
            logger.debug('Created by search target={0}', event.target.value);
            this.createdBySearch = event.target.value;
            this.currentPageIndex = 0;
            this.refreshEventList();
        }
    }

    handleLevelKeyChange(event) {
        if (this.levelSearch !== event.target.value) {
            logger.debug('Level search target={0}', event.target.value);
            this.levelSearch = event.target.value;
            this.currentPageIndex = 0;
            this.refreshEventList();
        }
    }

    handleContextKeyChange(event) {
        if (this.contextSearch !== event.target.value) {
            logger.debug('Context search target={0}', event.target.value);
            this.contextSearch = event.target.value;
            this.currentPageIndex = 0;
            this.refreshEventList();
        }
    }

    handleLogMessageKeyChange(event) {
        if (this.logMessageSearch !== event.target.value) {
            logger.debug('Log message search target={0}', event.target.value);
            this.logMessageSearch = event.target.value;
            this.currentPageIndex = 0;
            this.refreshEventList();
        }
    }

    handleLogSelected(event) {
        const currentTarget = event.currentTarget;

        const logId = currentTarget.dataset.logId;
        logger.debug('Log seleceted with Id={0}', logId);

        currentTarget.classList.add('selected');

        if (this.selectedRow) {
            this.selectedRow.classList.remove('selected');
        }
        this.selectedRow = currentTarget;

        const evtInfo = this.eventsToDisplay.find((evt) => evt.Id === parseInt(logId, 10));
        const logSelectedEvent = new CustomEvent('logselected', {
            detail: JSON.stringify(evtInfo)
        });
        this.dispatchEvent(logSelectedEvent);
    }
}
