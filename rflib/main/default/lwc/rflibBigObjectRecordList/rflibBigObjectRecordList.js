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
import { LightningElement, api } from 'lwc';
import { createLogger } from 'c/rflibLogger';

const logger = createLogger('BigObjectRecordList');

// Filtering is linear in the loaded set. Big Object rows can be a thousand times wider than a permission row,
// so the blocking spinner starts far earlier than the 30,000 rows used by the Permissions Explorer.
const SEARCH_SPINNER_THRESHOLD = 5000;

const KEY_SEPARATOR = '||';

/**
 * Builds the key of a record from its index tuple. The index is the primary key of a Big Object record, so the
 * key is stable across filters and loads, unlike a position in the filtered list.
 */
function createRecordKey(record, indexFields) {
    return indexFields.map((fieldName) => (record[fieldName] == null ? '' : record[fieldName])).join(KEY_SEPARATOR);
}

function toEpochTime(day, isEndOfDay) {
    return new Date(day + (isEndOfDay ? 'T23:59:59.999' : 'T00:00:00')).getTime();
}

function createRangePredicate(column, filterValue) {
    const fieldName = column.fieldName;

    if (column.isNumber) {
        const from =
            filterValue.fromValue === '' || filterValue.fromValue == null ? NaN : Number(filterValue.fromValue);
        const to = filterValue.toValue === '' || filterValue.toValue == null ? NaN : Number(filterValue.toValue);
        if (isNaN(from) && isNaN(to)) {
            return null;
        }
        return (rec) => {
            const value = rec[fieldName];
            return value != null && (isNaN(from) || value >= from) && (isNaN(to) || value <= to);
        };
    }

    const from = filterValue.fromValue || null;
    const to = filterValue.toValue || null;
    if (!from && !to) {
        return null;
    }

    if (column.dataType === 'date') {
        // Both sides are yyyy-MM-dd, which orders correctly as a string.
        return (rec) => {
            const value = rec[fieldName];
            return value != null && (!from || value >= from) && (!to || value <= to);
        };
    }

    const fromTime = from ? toEpochTime(from, false) : null;
    const toTime = to ? toEpochTime(to, true) : null;
    return (rec) => {
        const value = rec[fieldName];
        if (value == null) {
            return false;
        }
        const time = Date.parse(value);
        return (fromTime === null || time >= fromTime) && (toTime === null || time <= toTime);
    };
}

/**
 * Builds the predicates for the current search, cheapest first: number and date ranges, then the text columns,
 * and the scan over every queried field last, so the expensive pass over wide payloads only runs on the records
 * that survived everything else. Matching is case-sensitive through indexOf, as in the other RFLIB tables, which
 * compares without copying the stored strings. Fields that are null are absent from a serialized record, so every
 * predicate tolerates a missing value.
 */
function createPredicates(columns, columnFilters, globalSearch, searchFields) {
    const rangePredicates = [];
    const textPredicates = [];

    columns.forEach((column) => {
        const filterValue = columnFilters[column.fieldName];
        if (!filterValue) {
            return;
        }

        if (column.isRange) {
            const predicate = createRangePredicate(column, filterValue);
            if (predicate) {
                rangePredicates.push(predicate);
            }
        } else if (filterValue.value) {
            const fieldName = column.fieldName;
            const term = filterValue.value;
            textPredicates.push((rec) => rec[fieldName] != null && String(rec[fieldName]).indexOf(term) > -1);
        }
    });

    const predicates = rangePredicates.concat(textPredicates);

    if (globalSearch) {
        predicates.push((rec) => {
            for (let i = 0; i < searchFields.length; i++) {
                const value = rec[searchFields[i]];
                if (value != null && String(value).indexOf(globalSearch) > -1) {
                    return true;
                }
            }
            return false;
        });
    }

    return predicates;
}

function filterRecords(records, predicates) {
    if (predicates.length === 0) {
        return records;
    }
    return records.filter((rec) => {
        for (let i = 0; i < predicates.length; i++) {
            if (!predicates[i](rec)) {
                return false;
            }
        }
        return true;
    });
}

export default class RflibBigObjectRecordList extends LightningElement {
    _pageSize = 10;
    _fields = [];
    _displayFields = [];
    _selectedKey = null;

    // The full set is a plain field, never tracked: proxying tens of thousands of wide records on every search
    // is what would make the page feel broken. Only the rows of the visible page are reactive.
    allRecords = [];
    filteredRecords = [];
    rows = [];

    columns = [];
    columnFilters = {};
    globalSearch = '';

    filteredRecordCount = 0;
    currentPageIndex = 0;
    isSearching = false;

    @api indexFields = [];

    @api
    get fields() {
        return this._fields;
    }
    set fields(value) {
        this._fields = value || [];
        this.buildColumns();
    }

    @api
    get displayFields() {
        return this._displayFields;
    }
    set displayFields(value) {
        this._displayFields = value || [];
        this.buildColumns();
    }

    @api
    get records() {
        return this.allRecords;
    }
    set records(value) {
        this.allRecords = value || [];
        this.currentPageIndex = 0;
        this.refresh();
    }

    @api
    get pageSize() {
        return this._pageSize;
    }
    set pageSize(value) {
        this._pageSize = value;
        this.currentPageIndex = 0;
        this.refresh();
    }

    @api
    get currentPage() {
        return this.currentPageIndex + 1;
    }
    set currentPage(value) {
        const newPageIndex = value - 1;
        if (this.currentPageIndex !== newPageIndex) {
            this.currentPageIndex = newPageIndex;
            // Paging cannot change the filtered set, so only the visible rows are rebuilt.
            this.renderPage();
        }
    }

    @api
    get selectedKey() {
        return this._selectedKey;
    }
    set selectedKey(value) {
        this._selectedKey = value;
        this.renderPage();
    }

    get title() {
        return this.filteredRecordCount.toLocaleString() + ' Displayed Records';
    }

    get searchFields() {
        return this._fields.map((field) => field.apiName);
    }

    buildColumns() {
        const fieldsByName = {};
        this._fields.forEach((field) => {
            fieldsByName[field.apiName] = field;
        });

        this.columns = this._displayFields
            .filter((fieldName) => fieldsByName[fieldName])
            .map((fieldName) => {
                const field = fieldsByName[fieldName];
                const isDate = field.dataType === 'datetime' || field.dataType === 'date';
                const isNumber = field.dataType === 'number';
                return {
                    fieldName,
                    label: field.label,
                    dataType: field.dataType,
                    isDate,
                    isNumber,
                    isRange: isDate || isNumber,
                    rangeInputType: isNumber ? 'number' : 'date',
                    placeholder: field.label + '...'
                };
            });
        this.renderPage();
    }

    refresh() {
        this.applyFilter();
        this.renderPage();
    }

    /**
     * Narrows the loaded records down to the current search. It runs only when the records or the search change,
     * never when the user pages, and keeps references to the original records rather than copies.
     */
    applyFilter() {
        const predicates = createPredicates(this.columns, this.columnFilters, this.globalSearch, this.searchFields);
        this.filteredRecords = filterRecords(this.allRecords, predicates);
        this.filteredRecordCount = this.filteredRecords.length;
        logger.debug('Filtered records count {0}', this.filteredRecordCount);
    }

    // Builds the rows of the current page only, so the cost is bounded by the page size.
    renderPage() {
        const startIndex = this.currentPageIndex * this._pageSize;
        const indexFields = this.indexFields || [];

        this.rows = this.filteredRecords.slice(startIndex, startIndex + this._pageSize).map((rec) => {
            const key = createRecordKey(rec, indexFields);
            return {
                key,
                record: rec,
                isSelected: key === this._selectedKey,
                cells: this.columns.map((column) => ({
                    key: column.fieldName,
                    value: rec[column.fieldName],
                    isDatetime: column.dataType === 'datetime',
                    isDate: column.dataType === 'date',
                    isNumber: column.isNumber
                }))
            };
        });

        if (!import.meta.env.SSR) {
            this.dispatchEvent(
                new CustomEvent('refreshed', {
                    detail: JSON.stringify({
                        numDisplayedRecords: this.filteredRecordCount,
                        currentPage: this.currentPageIndex + 1
                    })
                })
            );
        }
    }

    executeSearch() {
        logger.debug(
            'Executing search, columnFilters={0}, globalSearch={1}',
            JSON.stringify(this.columnFilters),
            this.globalSearch
        );
        this.currentPageIndex = 0;

        if (this.allRecords.length < SEARCH_SPINNER_THRESHOLD) {
            this.refresh();
            return;
        }

        this.isSearching = true;
        // The filter runs on the thread that paints, so it has to yield once for the spinner to reach the screen.
        setTimeout(() => {
            try {
                this.refresh();
            } finally {
                this.isSearching = false;
            }
        }, 0);
    }

    handleColumnFilterChange(event) {
        const fieldName = event.target.dataset.field;
        const part = event.target.dataset.part;
        this.columnFilters = {
            ...this.columnFilters,
            [fieldName]: { ...this.columnFilters[fieldName], [part]: event.target.value }
        };
    }

    handleGlobalSearchChange(event) {
        this.globalSearch = event.target.value;
    }

    handleSearchKeyUp(event) {
        if (event.key === 'Enter') {
            this.executeSearch();
        }
    }

    handleRowClick(event) {
        const key = event.currentTarget.dataset.key;
        const row = this.rows.find((candidate) => candidate.key === key);
        logger.debug('Record selected with key={0}', key);

        if (row && !import.meta.env.SSR) {
            this.dispatchEvent(new CustomEvent('recordselected', { detail: { key, record: row.record } }));
        }
    }
}
