/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
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
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getJobDetails from '@salesforce/apex/rflib_ApexJobSchedulerController.getJobDetails';
import scheduleJob from '@salesforce/apex/rflib_ApexJobSchedulerController.scheduleJob';
import deleteScheduledJob from '@salesforce/apex/rflib_ApexJobSchedulerController.deleteScheduledJob';
import { refreshApex } from '@salesforce/apex';
import { createLogger } from 'c/rflibLogger';

const logger = createLogger('rflibApexJobScheduler');

export default class RflibApexJobScheduler extends LightningElement {
    @api className;
    @api jobName;

    @track jobDetails;
    @track isScheduled = false;
    @track status;
    @track nextRunTime;
    @track cronExpressionInput;
    @track isLoading = true;
    @track showDeleteConfirmation = false;

    wiredJobResult;

    @wire(getJobDetails, { jobName: '$jobName' })
    wiredJob(result) {
        logger.debug('wiredJob() invoked', JSON.stringify(result));
        this.wiredJobResult = result;
        if (result.data) {
            logger.debug('Job details fetched successfully: {0}', JSON.stringify(result.data));
            this.jobDetails = result.data;
            this.isScheduled = result.data.isScheduled;
            if (this.isScheduled) {
                this.status = result.data.status;
                this.nextRunTime = result.data.nextRunTime;
                this.cronExpressionInput = result.data.cronExpression;
            } else {
                this.cronExpressionInput = '0 0 2 ? * SAT'; // Runs every Saturday at 2 AM
            }
        } else if (result.error) {
            logger.error('Error fetching job details: {0}', JSON.stringify(result.error));
            this.showToast('Error', result.error.body.message, 'error');
        }
        this.isLoading = false;
    }

    handleCronChange(event) {
        this.cronExpressionInput = event.target.value;
    }

    handleSchedule() {
        if (!this.cronExpressionInput) {
            logger.warn('CRON expression validation failed - empty input');
            this.showToast('Validation Error', 'CRON expression is required.', 'error');
            return;
        }

        const salesforceCronRegex =
            /^(\*|[0-5]?\d)\s+(\*|[0-5]?\d)\s+(\*|[01]?\d|2[0-3])\s+(\*|\?|L|W|[1-9]|[12]\d|3[01])\s+(\*|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s+(\*|\?|L|[1-7]|SUN|MON|TUE|WED|THU|FRI|SAT)(\s+(\*|[12]\d{3}))?$/i;

        if (!salesforceCronRegex.test(this.cronExpressionInput)) {
            logger.warn('CRON expression validation failed - invalid format: {0}', this.cronExpressionInput);
            this.showToast('Validation Error', 'Invalid CRON expression format.', 'error');
            return;
        }

        this.isLoading = true;
        logger.debug(
            'Scheduling job with details: {0}',
            JSON.stringify({
                jobName: this.jobName,
                className: this.className,
                cronExpression: this.cronExpressionInput
            })
        );

        scheduleJob({ jobName: this.jobName, className: this.className, cronExpression: this.cronExpressionInput })
            .then((result) => {
                logger.debug('Job scheduled successfully: {0}', JSON.stringify(result));
                this.showToast('Job scheduled successfully', result, 'success');
                return refreshApex(this.wiredJobResult);
            })
            .catch((error) => {
                logger.error('Error scheduling job: {0}', JSON.stringify(error));
                this.showToast('Error scheduling job', error.body?.message || 'An unknown error occurred.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleDeleteClick() {
        this.showDeleteConfirmation = true;
    }

    handleRefresh() {
        return refreshApex(this.wiredJobResult)
            .then(() => {
                logger.debug('Data refreshed successfully.');
                this.showToast('Data refreshed successfully', null, 'success');
            })
            .catch((error) => {
                logger.error('Error refreshing data: ', error);
                this.showToast(
                    'Error refreshing data',
                    error.body?.message || 'An unknown error occurred while deleting the job.',
                    'error'
                );
            });
    }

    get deleteConfirmationMessage() {
        return `Are you sure you want to delete the scheduled job "${this.jobName}"? This action cannot be undone.`;
    }

    handleDeleteConfirmation(event) {
        if (event.detail.status === 'confirm') {
            this.isLoading = true;
            logger.debug('Deleting job: {0}', this.jobName);

            deleteScheduledJob({ jobName: this.jobName })
                .then(() => {
                    logger.debug('Job deleted successfully: {0}', this.jobName);
                    this.showToast('Success', 'Job deleted successfully', 'success');
                    return refreshApex(this.wiredJobResult);
                })
                .catch((error) => {
                    logger.error('Error deleting job: {0}', JSON.stringify(error));
                    this.showToast(
                        'Error deleting job',
                        error.body?.message || 'An unknown error occurred while deleting the job.',
                        'error'
                    );
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
        this.showDeleteConfirmation = false;
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        if (!import.meta.env.SSR) {
            this.dispatchEvent(evt);
        }
    }

    get formattedNextRunTime() {
        if (this.nextRunTime) {
            return new Date(this.nextRunTime).toLocaleString();
        }
        return '';
    }

    get title() {
        return 'Job Status for: ' + this.jobName;
    }
}
