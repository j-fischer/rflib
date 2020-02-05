import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { createLogger } from 'c/rflibLogger';

import NAME_FIELD from '@salesforce/schema/User.Name';
import PHONE_FIELD from '@salesforce/schema/User.Phone';
import EMAIL_FIELD from '@salesforce/schema/User.Email';

const FIELDS = [NAME_FIELD, PHONE_FIELD, EMAIL_FIELD];

const LOGGER = createLogger('LogEventViewer');

export default class LogEventViewer extends LightningElement {
    @api userId;
    @api logEvent;

    @track user = {};

    @wire(getRecord, { recordId: '$userId', fields: FIELDS })
    wiredRecord({ error, data }) {
        LOGGER.debug('getRecord completed for id={0}', this.userId);
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            LOGGER.debug('Failed to retrieve user data. Details: {0}', message);
        } else if (data) {
            LOGGER.debug('User data: {0}', JSON.stringify(data));

            this.user = data;
        }
    }

    get name() {
        return getFieldValue(this.user, NAME_FIELD);
    }

    get phone() {
        return getFieldValue(this.user, PHONE_FIELD);
    }

    get email() {
        return getFieldValue(this.user, EMAIL_FIELD);
    }

    get hasEvent() {
        return !!this.logEvent;
    }
}
