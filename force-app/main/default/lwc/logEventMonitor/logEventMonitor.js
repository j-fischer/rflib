import { LightningElement, track } from 'lwc';
import { createLogger } from 'c/rflibLogger';
import { subscribe, onError } from 'lightning/empApi';
//import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

const CHANNEL = '/event/rflib_Log_Event__e';
const DEFAULT_PAGE_SIZE = 10;

export default class LogEventMonitor extends LightningElement {
    @track page = 1;
    @track pageSize = DEFAULT_PAGE_SIZE;
    @track totalRecords;

    @track connected = false;
    @track capturedEvents = [];

    logger = createLogger('LogEventMonitor');
    subscription = {};

    connectedCallback() {
        let _this = this;
        const messageCallback = function(msg) {
            _this.logger.debug('New message received: ' + JSON.stringify(msg));
            _this.capturedEvents = [..._this.capturedEvents, msg.data.payload];
        };

        subscribe(CHANNEL, -2, messageCallback).then(response => {
            this.logger.debug('Successfully subscribed to: ' + response.channel);
            this.subscription = response;
            this.connected = true;

            this.logger.fatal('Show me this event.'); //FIXME: remove
        });
    }

    registerErrorListener() {
        onError(error => {
            this.logger.debug('Received error from server: ', JSON.stringify(error));
        });
    }

    handlePrevious() {
        if (this.page > 1) {
            this.page = this.page - 1;
        }
    }
    handleNext() {
        if (this.page < this.totalPages) this.page = this.page + 1;
    }

    handleFirst() {
        this.page = 1;
    }

    handleLast() {
        this.page = this.totalPages;
    }

    handleRefreshed(event) {
        this.logger.debug('Records loaded, count={0}', event.detail);
        this.totalRecords = event.detail;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
    }

    handlePageChange(event) {
        this.logger.debug('Page change, page={0}', event.detail);
        this.page = event.detail;
    }
}
