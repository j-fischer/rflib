import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import FIRSTNAME_FIELD from '@salesforce/schema/User.Firstname';
import LASTNAME_FIELD from '@salesforce/schema/User.Lastname';
import PHONE_FIELD from '@salesforce/schema/User.Phone';
import EMAIL_FIELD from '@salesforce/schema/User.Email';

const FIELDS = [FIRSTNAME_FIELD, LASTNAME_FIELD, PHONE_FIELD, EMAIL_FIELD];
export default class LogEventViewer extends LightningElement {
    @api
    logEvent;

    @wire(getRecord, { recordId: '$userId', fields: FIELDS })
    user;

    get name() {
        return getFieldValue(this.user.data, FIRSTNAME_FIELD) + ' ' + getFieldValue(this.user.data, LASTNAME_FIELD);
    }

    get phone() {
        return getFieldValue(this.user.data, PHONE_FIELD);
    }

    get email() {
        return getFieldValue(this.user.data, EMAIL_FIELD);
    }

    get hasEvent() {
        return !!this.logEvent;
    }
}
