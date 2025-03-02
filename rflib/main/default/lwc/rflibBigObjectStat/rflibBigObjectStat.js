import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { createLogger } from 'c/rflibLogger';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getStats from '@salesforce/apex/rflib_BigObjectStatController.getStats';
import refreshStats from '@salesforce/apex/rflib_BigObjectStatController.refreshStats';
import getFieldMetadata from '@salesforce/apex/rflib_BigObjectStatController.getFieldMetadata';

const logger = createLogger('rflibBigObjectStat');

const ACTIONS = [{ label: 'Refresh', name: 'refresh' }];

export default class RflibBigObjectStat extends LightningElement {
    @api bigObjects;
    @api fieldsToDisplay;

    subscription = {};
    wiredStatsResult;
    error;
    displayFields = [];
    isRefreshing = false;
    columns = [];

    get hasStats() {
        return this.wiredStatsResult?.data?.length > 0;
    }

    @wire(getStats, { bigObjects: '$bigObjects', fields: '$fieldsToDisplay' })
    wiredStats(result) {
        this.wiredStatsResult = result;
        if (result.data) {
            logger.debug('Received stats data: {0}', JSON.stringify(result.data));
            this.error = undefined;
        } else if (result.error) {
            logger.error('Failed to retrieve stats: ' + result.error);
            this.handleError('Error Loading Stats', 'Failed to retrieve Big Object statistics');
        }
    }

    @wire(getFieldMetadata, { fields: '$fieldsToDisplay' })
    wiredFieldMetadata({ error, data }) {
        if (data) {
            logger.debug('Received field metadata: {0}', JSON.stringify(data));
            this.columns = [
                ...data.map((field) => ({
                    label: field.label,
                    fieldName: field.fieldName,
                    type: field.type,
                    cellAttributes: { alignment: 'left' },
                    ...(field.type === 'date' && {
                        typeAttributes: {
                            year: 'numeric',
                            month: 'numeric',
                            day: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit',
                            timeZoneName: 'short'
                        }
                    })
                })),
                {
                    type: 'action',
                    typeAttributes: { rowActions: ACTIONS }
                }
            ];
        } else if (error) {
            logger.error('Failed to get field metadata', error);
            this.handleError('Configuration Error', 'Failed to configure columns for display');
        }
    }

    connectedCallback() {
        logger.debug('Initializing component with bigObjects={0}, fields={1}', this.bigObjects, this.fieldsToDisplay);
        this.displayFields = this.fieldsToDisplay.split(',').map((field) => field.trim());
        this.subscribeToStatEvents();
    }

    disconnectedCallback() {
        logger.debug('Disconnecting component and unsubscribing from events');
        this.unsubscribeFromStatEvents();
    }

    async refreshBigObject(bigObjectName) {
        try {
            this.isRefreshing = true;
            logger.info('Refreshing stats for big object: {0}', bigObjectName);
            await refreshStats({ bigObjectName });
        } catch (error) {
            logger.error('Error refreshing big object stats', error);
            this.handleError('Refresh Error', 'Failed to refresh Big Object statistics');
        } finally {
            this.isRefreshing = false;
        }
    }

    async refreshAllBigObjects() {
        try {
            if (!this.bigObjects) {
                logger.warn('No Big Objects configured');
                this.handleError('Configuration Error', 'No Big Objects configured for monitoring');
                return;
            }

            this.isRefreshing = true;
            logger.info('Refreshing all configured Big Objects');

            const bigObjectList = this.bigObjects.split(',').map((obj) => obj.trim());

            for (const bigObject of bigObjectList) {
                logger.debug('Refreshing stats for {0}', bigObject);
                refreshStats({ bigObjectName: bigObject });
            }

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Refresh initiated for all Big Objects',
                    variant: 'success'
                })
            );
        } catch (error) {
            logger.error('Failed to refresh all Big Objects', error);
            this.handleError('Refresh Error', 'Failed to refresh all Big Object statistics');
        } finally {
            this.isRefreshing = false;
        }
    }

    async subscribeToStatEvents() {
        try {
            logger.debug('Subscribing to Big Object Stat Updated events');
            this.subscription = await subscribe('/event/rflib_Big_Object_Stat_Updated__e', -1, (event) => {
                logger.debug('Received stat update event: {0}', JSON.stringify(event));
                refreshApex(this.wiredStatsResult);
            });
            logger.info('Successfully subscribed to Big Object Stat events');
        } catch (error) {
            logger.error('Failed to subscribe to Big Object Stat events', error);
            this.handleError('Subscription Error', 'Failed to subscribe to Big Object stat updates');
        }
    }

    async unsubscribeFromStatEvents() {
        try {
            logger.debug('Unsubscribing from Big Object Stat Updated events');
            await unsubscribe(this.subscription);
            logger.info('Successfully unsubscribed from Big Object Stat events');
        } catch (error) {
            logger.error('Failed to unsubscribe from Big Object Stat events', error);
            this.handleError('Unsubscribe Error', 'Failed to unsubscribe from Big Object stat updates');
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'refresh':
                this.refreshBigObject(row.Name);
                break;
            default:
                logger.warn('Unknown action: {0}', actionName);
        }
    }

    handleError(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant: 'error',
                mode: 'sticky'
            })
        );
    }
}
