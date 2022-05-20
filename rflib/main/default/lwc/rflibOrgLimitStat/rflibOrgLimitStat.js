import { api, LightningElement } from 'lwc';
import { createLogger } from 'c/rflibLogger';
import getOrgLimits from '@salesforce/apex/rflib_OrgLimitsController.getOrgLimits';

const logger = createLogger('LogEventMonitor');

export default class rflibOrgLimitStat extends LightningElement {
    @api title;
    @api limitName;

    limitProgression = 0;
    orgLimits = {};

    get currentValue() {
        return this.orgLimits[this.limitName] ? this.orgLimits[this.limitName].currentValue : 0;
    }

    get totalLimit() {
        return this.orgLimits[this.limitName] ? this.orgLimits[this.limitName].totalLimit : 0;
    }

    refresh() {
        logger.debug('Refreshing stat: ' + this.limitName);
        let _this = this;
        getOrgLimits().then((results) => {
            logger.debug('Org Limits Result: ' + JSON.stringify(results));
            _this.orgLimits = results;
        });
    }

    connectedCallback() {
        this.refresh();
    }
}
