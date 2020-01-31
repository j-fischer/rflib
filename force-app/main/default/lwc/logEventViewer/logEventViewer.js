import { LightningElement, api } from 'lwc';

export default class LogEventViewer extends LightningElement {
    @api
    logEvent;

    get hasEvent() {
        return !!this.logEvent;
    }
}
