import { LightningElement, api, track } from 'lwc';
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
        this.allEvents = value;
        this.refreshEventList();
    }

    @track filteredRecordCount;
    @track eventsToDisplay = [];

    @track searchKey;

    @api
    get title() {
        return this.filteredRecordCount + ' Log Events';
    }

    totalPages = 1;
    currentPageIndex = 0;
    displayedPageIndex;

    allEvents;
    filteredEvents = [];

    connectedCallback() {
        logger.debug('Initializing');
        this.refreshEventList();
    }

    refreshEventList() {
        this.displayedPageIndex = this.currentPageIndex;

        logger.debug('Display page with index {0}', this.currentPageIndex);

        const filteredEvents = this.searchKey
            ? this.allEvents.filter(evt => evt.Log_Messages__c.indexOf(this.searchKey) > -1)
            : this.allEvents;

        this.filteredEvents = filteredEvents.map(function(evt, index) {
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
            detail: this.filteredRecordCount
        });
        this.dispatchEvent(event);
    }

    handleKeyChange(event) {
        if (this.searchKey !== event.target.value) {
            logger.debug('Search target={0}', event.target.value);
            this.searchKey = event.target.value;
            this.currentpage = 1;
            this.refreshEventList();
        }
    }

    handleLogSelected(event) {
        const logId = event.currentTarget.dataset.logId;
        logger.debug('Log seleceted with Id={0}', logId);

        const evtInfo = this.eventsToDisplay.find(evt => evt.Id === logId);
        const logSelectedEvent = new CustomEvent('logselected', {
            detail: evtInfo
        });
        this.dispatchEvent(logSelectedEvent);
    }
}
