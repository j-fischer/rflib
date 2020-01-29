import { LightningElement, api, track } from 'lwc';
import { createLogger } from 'c/rflibLogger';

export default class LogEventList extends LightningElement {
    @api currentPage;
    @api pageSize;

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

    logger = createLogger('LogEventList');

    allEvents;
    totalPages = 1;
    filteredEvents = [];
    displayedPage;

    connectedCallback() {
        this.logger.debug('Initializing');
        this.refreshEventList();
    }

    refreshEventList() {
        this.displayedPage = this.currentPage;

        this.logger.debug('Display page {0}', this.currentPage);

        let filteredEvents = this.searchKey
            ? this.allEvents.filter(evt => evt.Log_Messages__c.indexOf(this.searchKey) > -1)
            : this.allEvents;

        this.filteredEvents = filteredEvents.map(function(evt, index) {
            let modifiedEvt = { ...evt };
            modifiedEvt.Id = index;
            return modifiedEvt;
        });
        this.filteredRecordCount = this.filteredEvents.length;

        this.logger.debug('Total records count {0}', this.filteredRecordCount);

        if (this.filteredRecordCount > 0) {
            this.totalPages = Math.ceil(this.filteredRecordCount / this.pageSize);

            this.eventsToDisplay = this.filteredEvents.slice((this.currentPage - 1) * this.pageSize, this.pageSize);
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
            this.logger.debug('Search target={0}', event.target.value);
            if (event.target.value > 2) {
                this.searchKey = event.target.value;
                this.currentpage = 1;
                this.refreshEventList();
            } else if (this.searchKey) {
                this.searchKey = '';
                this.currentpage = 1;
                this.refreshEventList();
            }
        }
    }
}
