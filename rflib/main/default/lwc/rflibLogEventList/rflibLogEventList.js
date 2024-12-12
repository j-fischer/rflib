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
import { LightningElement, api, track } from 'lwc';
import { createLogger } from 'c/rflibLogger';

const logger = createLogger('LogEventList');

const SEARCH_FIELDS = {
    CREATED_BY: 'createdBy',
    LEVEL: 'level',
    CONTEXT: 'context',
    REQUEST_ID: 'requestId',
    LOG_MESSAGE: 'logMessage'
};

export default class RflibLogEventList extends LightningElement {
    @api pageSize;
    @track _currentPage = 1; // Changed to internal tracked property
    @api permissionRecords;

    @track allRecords = [];
    @track filteredRecordCount;
    @track recordsToDisplay = [];
    @track selectedRow;

    @track createdBySearch;
    @track levelSearch;
    @track contextSearch;
    @track requestIdSearch;
    @track logMessageSearch;
    @track focusedSearchField = null;

    totalPages = 1;
    currentPageIndex = 0;
    displayedPageIndex;

    @api
    get title() {
        return this.filteredRecordCount + ' Displayed Log Events';
    }

    // Computed fields for CSS classes
    get baseSearchFieldClass() {
        return 'slds-col search-field';
    }

    get expandedSearchFieldClass() {
        return `${this.baseSearchFieldClass} slds-size_1-of-2 search-field-expanded`;
    }

    get collapsedSearchFieldClass() {
        return `${this.baseSearchFieldClass} slds-size_1-of-12 search-field-collapsed`;
    }

    get defaultSearchFieldClass() {
        return `${this.baseSearchFieldClass} slds-size_1-of-6`;
    }

    get createdByFieldClass() {
        return this.getFieldClass(SEARCH_FIELDS.CREATED_BY);
    }

    get levelFieldClass() {
        return this.getFieldClass(SEARCH_FIELDS.LEVEL);
    }

    get contextFieldClass() {
        return this.getFieldClass(SEARCH_FIELDS.CONTEXT);
    }

    get requestIdFieldClass() {
        return this.getFieldClass(SEARCH_FIELDS.REQUEST_ID);
    }

    get logMessageFieldClass() {
        return this.getFieldClass(SEARCH_FIELDS.LOG_MESSAGE);
    }

    getFieldClass(fieldName) {
        if (this.focusedSearchField === null) {
            return this.defaultSearchFieldClass;
        }
        return this.focusedSearchField === fieldName ? this.expandedSearchFieldClass : this.collapsedSearchFieldClass;
    }

    // Focus handlers for each field
    handleCreatedByFocus() {
        this.focusedSearchField = SEARCH_FIELDS.CREATED_BY;
    }

    handleLevelFocus() {
        this.focusedSearchField = SEARCH_FIELDS.LEVEL;
    }

    handleContextFocus() {
        this.focusedSearchField = SEARCH_FIELDS.CONTEXT;
    }

    handleRequestIdFocus() {
        this.focusedSearchField = SEARCH_FIELDS.REQUEST_ID;
    }

    handleLogMessageFocus() {
        this.focusedSearchField = SEARCH_FIELDS.LOG_MESSAGE;
    }

    handleSearchFieldBlur() {
        // Small delay to handle focus changes between fields
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const focusedElement = this.template.activeElement;
            if (!focusedElement || !focusedElement.dataset.field) {
                this.focusedSearchField = null;
            }
        }, 100);
    }

    handleCreatedByKeyPress(event) {
        if (event.which === 13) {
            this.executeSearch();
        }
    }

    handleLevelKeyPress(event) {
        if (event.which === 13) {
            this.executeSearch();
        }
    }

    handleContextKeyPress(event) {
        if (event.which === 13) {
            this.executeSearch();
        }
    }

    handleRequestIdKeyPress(event) {
        if (event.which === 13) {
            this.executeSearch();
        }
    }

    handleLogMessageKeyPress(event) {
        if (event.which === 13) {
            this.executeSearch();
        }
    }

    handleCreatedByChanged(event) {
        if (this.createdBySearch !== event.target.value) {
            this.createdBySearch = event.target.value;
        }
    }

    handleLevelKeyChange(event) {
        if (this.levelSearch !== event.target.value) {
            this.levelSearch = event.target.value;
        }
    }

    handleContextKeyChange(event) {
        if (this.contextSearch !== event.target.value) {
            this.contextSearch = event.target.value;
        }
    }

    handleRequestIdChange(event) {
        if (this.requestIdSearch !== event.target.value) {
            this.requestIdSearch = event.target.value;
        }
    }

    handleLogMessageKeyChange(event) {
        if (this.logMessageSearch !== event.target.value) {
            this.logMessageSearch = event.target.value;
        }
    }

    executeSearch() {
        logger.debug(
            'Executing search for createdBy={0}, level={1}, context={2}, requestId={3}, logMessage={4}',
            this.createdBySearch,
            this.levelSearch,
            this.contextSearch,
            this.requestIdSearch,
            this.logMessageSearch
        );
        this.currentPageIndex = 0;
        this.refreshEventList();
    }

    refreshEventList() {
        this.displayedPageIndex = this.currentPageIndex;
        logger.debug('Display page with index {0}', this.currentPageIndex);

        const filteredRecords =
            this.createdBySearch ||
            this.levelSearch ||
            this.contextSearch ||
            this.requestIdSearch ||
            this.logMessageSearch
                ? this.allRecords.filter(
                      (rec) =>
                          (!this.createdBySearch ||
                              (rec.CreatedById || rec.CreatedById__c).indexOf(this.createdBySearch) > -1) &&
                          (!this.levelSearch || rec.Log_Level__c.indexOf(this.levelSearch) > -1) &&
                          (!this.contextSearch || rec.Context__c.indexOf(this.contextSearch) > -1) &&
                          (!this.requestIdSearch || rec.Request_ID__c.indexOf(this.requestIdSearch) > -1) &&
                          (!this.logMessageSearch || rec.Log_Messages__c.indexOf(this.logMessageSearch) > -1)
                  )
                : this.allRecords;

        this.filteredRecords = filteredRecords.map((evt, index) => {
            const modifiedEvt = { ...evt };
            modifiedEvt.id = index;
            return modifiedEvt;
        });

        this.filteredRecordCount = this.filteredRecords.length;

        if (this.filteredRecordCount > 0) {
            this.totalPages = Math.ceil(this.filteredRecordCount / this.pageSize);
            const startIndex = this.currentPageIndex * this.pageSize;
            this.recordsToDisplay = this.filteredRecords.slice(startIndex, startIndex + this.pageSize);
        } else {
            this.recordsToDisplay = [];
            this.totalPages = 1;
        }

        logger.debug('recordsToDisplay={0}', JSON.stringify(this.recordsToDisplay));

        const event = new CustomEvent('refreshed', {
            detail: JSON.stringify({
                numDisplayedRecords: this.filteredRecordCount,
                currentPage: this.currentPageIndex + 1
            })
        });
        this.dispatchEvent(event);
    }

    connectedCallback() {
        logger.debug('Initializing');
        this.refreshEventList();
    }

    @api
    set logEvents(value) {
        this.allRecords = value || [];
        this.refreshEventList();
    }
    get logEvents() {
        return this.allRecords;
    }

    @api
    get currentPage() {
        return this._currentPage;
    }
    set currentPage(value) {
        this._currentPage = value;
        this.currentPageIndex = value - 1;
        if (this.isConnected) {
            // Only refresh if component is connected
            this.refreshEventList();
        }
    }

    handleLogSelected(event) {
        const currentTarget = event.currentTarget;

        const logId = currentTarget.dataset.logId;
        logger.debug('Log selected with Id={0}', logId);

        currentTarget.classList.add('selected');

        if (this.selectedRow) {
            this.selectedRow.classList.remove('selected');
        }
        this.selectedRow = currentTarget;

        const evtInfo = this.recordsToDisplay.find((evt) => evt.id === parseInt(logId, 10));
        const logSelectedEvent = new CustomEvent('logselected', {
            detail: JSON.stringify(evtInfo)
        });
        this.dispatchEvent(logSelectedEvent);
    }
}
