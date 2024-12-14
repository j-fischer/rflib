// File: rflibApexJobScheduler.js
import { LightningElement, api, track, wire } from 'lwc';
import getJobDetails from '@salesforce/apex/rflib_ApexJobScheduler.getJobDetails';
import scheduleJob from '@salesforce/apex/rflib_ApexJobScheduler.scheduleJob';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const CRON_EXPRESSION_DEFAULT = '0 0 3 ? * 0#2';

export default class RflibApexJobScheduler extends LightningElement {
    @api className;
    @api jobName;

    @track jobDetails;
    @track isScheduled = false;
    @track status;
    @track nextRunTime;
    @track cronExpressionInput;
    @track isLoading = true;

    wiredJobResult;

    @wire(getJobDetails, { jobName: '$jobName' })
    wiredJob(result) {
        this.wiredJobResult = result;
        if (result.data) {
            this.jobDetails = result.data;
            this.isScheduled = result.data.isScheduled;
            if (this.isScheduled) {
                this.status = result.data.status;
                this.nextRunTime = result.data.nextRunTime;
                this.cronExpressionInput = result.data.cronExpression;
            } else {
                this.cronExpressionInput = CRON_EXPRESSION_DEFAULT; // Set default CRON when not scheduled
            }
        } else if (result.error) {
            this.showToast('Error', result.error.body.message, 'error');
        }
        this.isLoading = false;
    }

    handleCronChange(event) {
        this.cronExpressionInput = event.target.value;
    }

    handleSchedule() {
        if (!this.cronExpressionInput) {
            this.showToast('Validation Error', 'CRON expression is required.', 'error');
            return;
        }

        // Add CRON expression format validation here
        const cronRegex =
            /^(\*|[0-5]?\d)\s+(\*|[0-5]?\d)\s+(\*|[01]?\d|2[0-3])\s+(\*|\?|\d+)\s+(\*|[1-9]|1[0-2]|\bJAN\b|\bFEB\b|\bMAR\b|\bAPR\b|\bMAY\b|\bJUN\b|\bJUL\b|\bAUG\b|\bSEP\b|\bOCT\b|\bNOV\b|\bDEC\b)\s+(\*|[0-7](?:#[1-5])?)$/i;
        if (!cronRegex.test(this.cronExpressionInput)) {
            this.showToast('Validation Error', 'Invalid CRON expression format.', 'error');
            return;
        }

        this.isLoading = true;
        scheduleJob({ jobName: this.jobName, className: this.className, cronExpression: this.cronExpressionInput })
            .then((result) => {
                this.showToast('Success', result, 'success');
                return refreshApex(this.wiredJobResult);
            })
            .catch((error) => {
                if (error.body && error.body.message) {
                    this.showToast('Error', error.body.message, 'error');
                } else {
                    this.showToast('Error', 'An unknown error occurred.', 'error');
                }
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
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
