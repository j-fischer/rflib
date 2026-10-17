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
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { createLogger } from 'c/rflibLogger';
import hideHeaderCSS from '@salesforce/resourceUrl/rflib_HidePageHeader';

import describeConfig from '@salesforce/apex/rflib_BigObjectQueryController.describeConfig';
import queryChunk from '@salesforce/apex/rflib_BigObjectQueryController.queryChunk';

const logger = createLogger('BigObjectExplorer');

const DEFAULT_MAX_RECORDS = 100000;
const DEFAULT_PAGE_SIZE = 10;

// When the first chunk projects a load above this many characters, the load pauses and asks before continuing.
// A desktop tab holds about this much text comfortably; beyond it the page risks becoming slow or crashing.
const PAYLOAD_CONFIRMATION_THRESHOLD = 100 * 1024 * 1024;

const OPERATOR = {
    EQUALS: 'EQUALS',
    RANGE: 'RANGE',
    IN: 'IN'
};

const RANGE_INPUT_TYPES = {
    datetime: 'datetime',
    date: 'date',
    number: 'number'
};

function splitList(value) {
    return (value || '')
        .split(',')
        .map((item) => item.trim())
        .filter((item) => item.length > 0);
}

function parseFieldLabels(value) {
    const labels = {};
    splitList(value).forEach((pair) => {
        const separatorIndex = pair.indexOf('=');
        if (separatorIndex > 0) {
            labels[pair.substring(0, separatorIndex).trim().toLowerCase()] = pair.substring(separatorIndex + 1).trim();
        }
    });
    return labels;
}

function toInteger(value) {
    if (value === undefined || value === null || value === '') {
        return undefined;
    }
    const parsed = parseInt(value, 10);
    return isNaN(parsed) ? undefined : parsed;
}

function reduceError(error) {
    return error?.body?.message || error?.message || JSON.stringify(error);
}

function formatMegabytes(characters) {
    return Math.max(1, Math.round(characters / (1024 * 1024))).toLocaleString();
}

/**
 * Turns one index filter input into a filter term, or null when it is empty. Text inputs accept the same value
 * syntax as the defaultFilter attribute: "a..b" for a range, "a,b" for a list, anything else for an exact value.
 * Range inputs are exact when both bounds hold the same value.
 */
function toIndexFilter(input) {
    if (input.isRange) {
        const fromValue = input.fromValue || null;
        const toValue = input.toValue || null;
        if (!fromValue && !toValue) {
            return null;
        }
        if (fromValue === toValue) {
            return { fieldName: input.fieldName, operator: OPERATOR.EQUALS, value: fromValue };
        }
        return { fieldName: input.fieldName, operator: OPERATOR.RANGE, fromValue, toValue };
    }

    const value = (input.value || '').trim();
    if (!value) {
        return null;
    }
    if (value.includes('..')) {
        const [fromValue, toValue] = value.split('..').map((bound) => bound.trim() || null);
        return { fieldName: input.fieldName, operator: OPERATOR.RANGE, fromValue, toValue };
    }
    if (value.includes(',')) {
        return { fieldName: input.fieldName, operator: OPERATOR.IN, values: splitList(value) };
    }
    return { fieldName: input.fieldName, operator: OPERATOR.EQUALS, value };
}

export default class RflibBigObjectExplorer extends LightningElement {
    @api bigObjectApiName;
    @api indexFields;
    @api indexSortDirection;
    @api displayFields;
    @api detailFields;
    @api fieldLabels;
    @api cardTitle;
    @api chunkSize;
    @api maxRecords;
    @api defaultFilter;
    @api filterableIndexDepth;
    @api pageSize;
    @api allowSystemMode;

    isDescribing = true;
    problems = null;
    description = null;
    fieldInfos = [];
    // Resolved once, so the viewer is not handed a new array on every render of the explorer.
    detailFieldInfos = [];
    indexFilterInputs = [];
    // Whether the user changed an index filter since the defaults were resolved. Untouched defaults are resolved
    // again on every query, so a relative window like LAST_N_DAYS:7 does not go stale in a tab left open overnight.
    isIndexFilterEdited = false;

    records = [];
    isLoading = false;
    progressText = '';
    // Incremented on every load and on cancel, so a chunk that arrives late can tell it is no longer wanted.
    loadToken = 0;
    // The records of the load in progress. A plain field, so appending a chunk does not re-render anything.
    pendingRecords = [];

    page = 1;
    numDisplayedRecords = 0;

    selectedKey = null;
    selectedRecord = null;
    showLeftColumn = true;

    showPayloadConfirmation = false;
    payloadConfirmationMessage = '';
    resolvePayloadConfirmation = null;

    connectedCallback() {
        loadStyle(this, hideHeaderCSS).catch((error) => {
            logger.error('Error loading custom CSS for header hiding: {0}', error.message);
        });

        this.initialize();
    }

    disconnectedCallback() {
        // Stops a load that is still running from requesting further chunks.
        this.loadToken += 1;
    }

    get effectivePageSize() {
        return toInteger(this.pageSize) || DEFAULT_PAGE_SIZE;
    }

    get effectiveMaxRecords() {
        return toInteger(this.maxRecords) || DEFAULT_MAX_RECORDS;
    }

    get title() {
        return this.cardTitle || this.description?.objectLabel || this.bigObjectApiName;
    }

    get hasProblems() {
        return this.problems !== null;
    }

    get isReady() {
        return this.description !== null;
    }

    get isSystemMode() {
        return this.description?.isSystemMode === true;
    }

    get hasDroppedFields() {
        return this.description?.droppedFields?.length > 0;
    }

    get droppedFieldsText() {
        return (this.description?.droppedFields || []).join(', ');
    }

    get recordCountText() {
        return this.records.length.toLocaleString() + ' Records Loaded';
    }

    get showLoadingOverlay() {
        return this.isLoading && !this.showPayloadConfirmation;
    }

    get isQueryDisabled() {
        return this.isLoading;
    }

    get isRecordSelected() {
        return this.selectedRecord !== null;
    }

    get isExpandButtonDisabled() {
        return !this.isRecordSelected;
    }

    get leftColumnClass() {
        return this.showLeftColumn ? 'slds-col slds-size_7-of-12' : 'slds-hide';
    }

    get rightColumnClass() {
        return this.showLeftColumn ? 'slds-col slds-size_5-of-12' : 'slds-col slds-size_1-of-1';
    }

    get tooltipFullscreen() {
        return this.showLeftColumn ? 'Hide the record list' : 'Show the record list';
    }

    get displayFieldNames() {
        return this.description?.displayFields || [];
    }

    get indexFieldNames() {
        return this.description?.indexFields || [];
    }

    get selectedRecordTitle() {
        if (!this.selectedRecord) {
            return null;
        }
        const fieldsByName = this.getFieldsByName();
        const parts = this.displayFieldNames
            .filter((fieldName) => fieldsByName[fieldName].dataType !== 'datetime')
            .map((fieldName) => this.selectedRecord[fieldName])
            .filter((value) => value != null && value !== '')
            .slice(0, 3);
        return parts.length > 0 ? parts.join(' - ') : null;
    }

    /**
     * The index filter inputs, in index order. Each input unlocks only once every input above it holds an exact
     * value; the first input that does not becomes the range, and everything below it is disabled. A form in
     * this shape cannot express a predicate the Big Object index would reject.
     */
    get indexFilterRows() {
        const isExact = (input) => toIndexFilter(input)?.operator === OPERATOR.EQUALS;
        return this.indexFilterInputs.map((input, position) => ({
            ...input,
            disabled: this.isLoading || !this.indexFilterInputs.slice(0, position).every(isExact)
        }));
    }

    async initialize() {
        try {
            const description = await describeConfig({ config: this.createConfig() });

            if (!description.isValid) {
                logger.warn('Invalid Big Object Explorer configuration: {0}', JSON.stringify(description.problems));
                this.problems = description.problems.map((problem, index) => ({ ...problem, key: index }));
                return;
            }

            const labels = parseFieldLabels(this.fieldLabels);
            this.fieldInfos = description.fields.map((field) => ({
                ...field,
                label: labels[field.apiName.toLowerCase()] || field.label
            }));
            const fieldsByName = this.getFieldsByName();
            this.detailFieldInfos = description.detailFields.map((fieldName) => fieldsByName[fieldName]);
            this.description = description;
            this.indexFilterInputs = this.createIndexFilterInputs(description.defaultFilters);

            this.loadRecords();
        } catch (error) {
            logger.error('Failed to describe the Big Object Explorer configuration: {0}', JSON.stringify(error));
            this.problems = [{ key: 0, attribute: null, message: reduceError(error) }];
        } finally {
            this.isDescribing = false;
        }
    }

    createConfig() {
        return {
            bigObjectApiName: this.bigObjectApiName,
            indexFields: splitList(this.indexFields),
            sortDirection: this.indexSortDirection,
            displayFields: splitList(this.displayFields),
            detailFields: splitList(this.detailFields),
            defaultFilter: this.defaultFilter,
            filterableIndexDepth: toInteger(this.filterableIndexDepth),
            chunkSize: toInteger(this.chunkSize),
            allowSystemMode: this.allowSystemMode === true || this.allowSystemMode === 'true'
        };
    }

    getFieldsByName() {
        const fieldsByName = {};
        this.fieldInfos.forEach((field) => {
            fieldsByName[field.apiName] = field;
        });
        return fieldsByName;
    }

    createIndexFilterInputs(defaultFilters) {
        const fieldsByName = this.getFieldsByName();
        const filtersByField = {};
        (defaultFilters || []).forEach((filter) => {
            filtersByField[filter.fieldName] = filter;
        });

        return this.description.indexFields.slice(0, this.description.filterableIndexDepth).map((fieldName) => {
            const field = fieldsByName[fieldName];
            const filter = filtersByField[fieldName];
            const inputType = RANGE_INPUT_TYPES[field.dataType];
            const input = {
                key: fieldName,
                fieldName,
                label: field.label,
                isRange: !!inputType,
                inputType: inputType || 'text',
                value: '',
                fromValue: '',
                toValue: ''
            };

            if (!filter) {
                return input;
            }

            if (filter.operator === OPERATOR.EQUALS) {
                input.value = filter.value;
                input.fromValue = filter.value;
                input.toValue = filter.value;
            } else if (filter.operator === OPERATOR.IN) {
                input.value = filter.values.join(', ');
            } else {
                input.fromValue = filter.fromValue || '';
                input.toValue = filter.toValue || '';
                input.value = (filter.fromValue || '') + '..' + (filter.toValue || '');
            }
            return input;
        });
    }

    createIndexFilters() {
        const filters = [];
        for (const input of this.indexFilterInputs) {
            const filter = toIndexFilter(input);
            if (!filter) {
                break;
            }
            filters.push(filter);
            if (filter.operator !== OPERATOR.EQUALS) {
                break;
            }
        }
        return filters;
    }

    handleIndexFilterChange(event) {
        const fieldName = event.target.dataset.field;
        const part = event.target.dataset.part;
        const value = event.target.value;

        this.indexFilterInputs = this.indexFilterInputs.map((input) =>
            input.fieldName === fieldName ? { ...input, [part]: value } : input
        );
        this.isIndexFilterEdited = true;
    }

    async handleQuery() {
        if (!this.isIndexFilterEdited) {
            try {
                const description = await describeConfig({ config: this.createConfig() });
                this.indexFilterInputs = this.createIndexFilterInputs(description.defaultFilters);
            } catch (error) {
                logger.error('Failed to resolve the default index filters again: {0}', JSON.stringify(error));
            }
        }
        this.loadRecords();
    }

    /**
     * Loads the records matching the index filters, one chunk per round trip. Each chunk is its own Apex
     * transaction, so the load is bounded by maxRecords rather than by a governor limit. It stops when the range
     * is exhausted, maxRecords is reached, the user cancels, or the server reports that the cursor cannot advance.
     */
    async loadRecords() {
        this.loadToken += 1;
        const token = this.loadToken;
        const maxRecords = this.effectiveMaxRecords;
        const config = { ...this.createConfig(), indexFilters: this.createIndexFilters() };

        logger.debug('Starting load {0} with filters {1}', token, JSON.stringify(config.indexFilters));

        this.pendingRecords = [];
        this.records = [];
        this.selectedKey = null;
        this.selectedRecord = null;
        this.page = 1;
        this.isLoading = true;
        this.progressText = 'Loading records';

        let cursor = null;
        let isFirstChunk = true;

        try {
            for (;;) {
                const result = await queryChunk({ config, cursor });
                if (token !== this.loadToken) {
                    logger.debug('Discarding a chunk of the superseded load {0}', token);
                    return;
                }

                const loaded = this.pendingRecords;
                result.records.forEach((record) => loaded.push(record));
                cursor = result.cursor;
                this.progressText = 'Loaded ' + loaded.length.toLocaleString() + ' records';

                // Checked first, because the chunk that crosses the limit may also be the last or a stuck one.
                if (loaded.length > maxRecords || (loaded.length === maxRecords && !result.isComplete)) {
                    loaded.length = maxRecords;
                    this.showToast(
                        'Record limit reached',
                        'Loaded the maximum of ' +
                            maxRecords.toLocaleString() +
                            ' records. Narrow the index filter to see the remaining records.',
                        'warning',
                        'sticky'
                    );
                    break;
                }

                if (result.isStuck) {
                    this.showToast('Load stopped', result.message, 'warning', 'sticky');
                    break;
                }

                if (result.isComplete) {
                    break;
                }

                if (isFirstChunk) {
                    isFirstChunk = false;
                    const shouldContinue = await this.confirmProjectedPayload(result.records, maxRecords);
                    if (token !== this.loadToken) {
                        return;
                    }
                    if (!shouldContinue) {
                        break;
                    }
                }
            }
        } catch (error) {
            if (token !== this.loadToken) {
                return;
            }
            logger.error('Failed to load records: {0}', JSON.stringify(error));
            this.showToast('Failed to load records', reduceError(error), 'error', 'sticky');
        }

        this.finishLoad();
    }

    /**
     * Measures the first chunk and extrapolates it to maxRecords. Payload size, not row count, is what a browser
     * runs out of, and a long text field can be anything from empty to 32 KB per record, so the projection is
     * based on the real data rather than on a guess.
     */
    confirmProjectedPayload(chunkRecords, maxRecords) {
        if (chunkRecords.length === 0) {
            return Promise.resolve(true);
        }

        const chunkCharacters = JSON.stringify(chunkRecords).length;
        const projectedCharacters = (chunkCharacters / chunkRecords.length) * maxRecords;
        logger.debug('First chunk holds {0} characters, projected {1}', chunkCharacters, projectedCharacters);

        if (projectedCharacters <= PAYLOAD_CONFIRMATION_THRESHOLD) {
            return Promise.resolve(true);
        }

        this.payloadConfirmationMessage =
            'The first ' +
            chunkRecords.length.toLocaleString() +
            ' records hold about ' +
            formatMegabytes(chunkCharacters) +
            ' MB of data. Loading up to ' +
            maxRecords.toLocaleString() +
            ' records could need about ' +
            formatMegabytes(projectedCharacters) +
            ' MB of browser memory and make the page slow to respond. Do you want to continue loading?';
        this.showPayloadConfirmation = true;

        return new Promise((resolve) => {
            this.resolvePayloadConfirmation = resolve;
        });
    }

    handlePayloadConfirmation(event) {
        const shouldContinue = event.detail?.status === 'confirm';
        logger.debug('Payload confirmation answered, continue={0}', shouldContinue);

        this.showPayloadConfirmation = false;
        if (this.resolvePayloadConfirmation) {
            this.resolvePayloadConfirmation(shouldContinue);
            this.resolvePayloadConfirmation = null;
        }
    }

    handleCancel() {
        logger.debug('Cancelling load {0}', this.loadToken);
        this.loadToken += 1;
        if (this.resolvePayloadConfirmation) {
            this.showPayloadConfirmation = false;
            this.resolvePayloadConfirmation(false);
            this.resolvePayloadConfirmation = null;
        }
        // The records loaded so far stay available.
        this.finishLoad();
        this.showToast('Load cancelled', this.recordCountText + '.', 'info');
    }

    finishLoad() {
        this.records = this.pendingRecords;
        this.pendingRecords = [];
        this.isLoading = false;
    }

    handleRefreshed(event) {
        const details = JSON.parse(event.detail);
        this.page = details.currentPage;
        this.numDisplayedRecords = details.numDisplayedRecords;
    }

    get totalPages() {
        return Math.max(1, Math.ceil(this.numDisplayedRecords / this.effectivePageSize));
    }

    handlePrevious() {
        if (this.page > 1) {
            this.page = this.page - 1;
        }
    }

    handleNext() {
        if (this.page < this.totalPages) {
            this.page = this.page + 1;
        }
    }

    handleFirst() {
        this.page = 1;
    }

    handleLast() {
        this.page = this.totalPages;
    }

    handleGoToPage(event) {
        // The paginator clamps the page to the valid range but passes what was typed, which is a string.
        this.page = parseInt(event.detail, 10);
    }

    handleRecordSelected(event) {
        logger.debug('Record selected with key={0}', event.detail.key);
        this.selectedKey = event.detail.key;
        this.selectedRecord = event.detail.record;
    }

    handleToggleFullscreen() {
        this.showLeftColumn = !this.showLeftColumn;
    }

    handleCloseViewer() {
        this.selectedKey = null;
        this.selectedRecord = null;
        this.showLeftColumn = true;
    }

    showToast(title, message, variant, mode) {
        if (!import.meta.env.SSR) {
            this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: mode || 'dismissible' }));
        }
    }
}
