import { LightningElement, track } from 'lwc';
import { createLogger } from 'c/rflibLogger';
import { subscribe, onError } from 'lightning/empApi';
//import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

const CHANNEL = '/event/rflib_Log_Event__e';

export default class LogEventMonitor extends LightningElement {
    @track connected = false;
    @track capturedEvents = [];

    logger = createLogger('LogEventMonitor');
    subscription = {};

    connectedCallback() {
        let _this = this;
        const messageCallback = function(msg) {
            _this.logger.debug('New message received: ' + JSON.stringify(msg));
            _this.capturedEvents.push(msg.data.payload);
        };

        subscribe(CHANNEL, -1, messageCallback).then(response => {
            this.logger.debug('Successfully subscribed to: ' + response.channel);
            this.subscription = response;
            this.connected = true;
            this.logger.fatal('Show me this event.');
        });
    }

    registerErrorListener() {
        onError(error => {
            this.logger.debug('Received error from server: ', JSON.stringify(error));
        });
    }
}
