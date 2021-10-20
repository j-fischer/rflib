import { api, LightningElement } from 'lwc';

export default class RflibLogEventListRow extends LightningElement {
    @api evt;

    get createdBy() {
        return this.evt.CreatedById || this.evt.CreatedById__c;
    }

    get createdDate() {
        return this.evt.CreatedDate || this.evt.CreatedDate__c;
    }
}
