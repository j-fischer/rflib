/*
 * Copyright (c) 2019 Johannes Fischer <fischer.jh@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name "RFLIB", the name of the copyright holder, nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { createLogger } from 'c/rflibLogger';
import getRecentLogSummary from '@salesforce/apex/rflib_LogArchiveController.getRecentLogSummary';

const LOG_MONITOR_TAB = 'rflib_Log_Monitor';

const logger = createLogger('LogArchiveAlert');

export default class RflibLogArchiveAlert extends NavigationMixin(LightningElement) {
    @api lookbackHours = 24;
    @api logLevels = 'WARN,ERROR,FATAL';

    _summary;

    @wire(getRecentLogSummary, { lookbackHours: '$lookbackHours', logLevels: '$logLevels' })
    wiredSummary({ error, data }) {
        if (data) {
            logger.debug('Received log archive summary: {0}', JSON.stringify(data));
            this._summary = data;
        } else if (error) {
            // Render nothing on failure - the dashboard should not surface a scary banner
            // just because the archive query failed on load.
            logger.error('Failed to retrieve log archive summary', error);
            this._summary = undefined;
        }
    }

    get hasMatches() {
        return !!this._summary && this._summary.totalCount > 0;
    }

    get summaryText() {
        if (!this.hasMatches) {
            return '';
        }

        const parts = this._summary.levelCounts.map((levelCount) => `${levelCount.count} ${levelCount.level}`);
        return `${parts.join(', ')} in the last ${this._summary.lookbackHours} hours`;
    }

    get bannerClass() {
        const hasSevere =
            this.hasMatches &&
            this._summary.levelCounts.some(
                (levelCount) => levelCount.level === 'ERROR' || levelCount.level === 'FATAL'
            );
        const theme = hasSevere ? 'slds-theme_error' : 'slds-theme_warning';
        return `slds-notify slds-notify_alert slds-m-bottom_x-small ${theme}`;
    }

    navigateToLogMonitor(event) {
        if (event) {
            event.preventDefault();
        }

        logger.debug('Navigating to the Log Monitor tab');
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: LOG_MONITOR_TAB
            }
        });
    }
}
