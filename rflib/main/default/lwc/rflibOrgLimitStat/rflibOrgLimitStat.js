import { api, LightningElement } from 'lwc';
import { createLogger } from 'c/rflibLogger';
import getOrgLimits from '@salesforce/apex/rflib_OrgLimitsController.getOrgLimits';

const logger = createLogger('LogEventMonitor');

export default class rflibOrgLimitStat extends LightningElement {
    @api title;
    @api limitName;

    _limitProgression = 0;
    _currentValue = 0;
    _totalLimit = 0;

    setOrgLimits(newOrgLimits) {
        this._currentValue = newOrgLimits[this.limitName] ? newOrgLimits[this.limitName].currentValue : 0;
        this._totalLimit = newOrgLimits[this.limitName] ? newOrgLimits[this.limitName].totalLimit : 0;

        this._limitProgression = this._totalLimit > 0 ? (this._currentValue / this._totalLimit) * 100 : 0;
    }

    get currentValue() {
        return this._currentValue;
    }

    get totalLimit() {
        return this._totalLimit;
    }

    get limitProgression() {
        return this._limitProgression;
    }

    refresh() {
        logger.debug('Refreshing stat: ' + this.limitName);

        let _this = this;
        getOrgLimits().then((results) => {
            logger.debug('Org Limits Result: ' + JSON.stringify(results));
            _this.setOrgLimits(results);
        });
    }

    connectedCallback() {
        this.refresh();
    }
}
