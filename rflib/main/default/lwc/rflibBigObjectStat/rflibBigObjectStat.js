import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { createLogger } from 'c/rflibLogger';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getStats from '@salesforce/apex/rflib_BigObjectStatController.getStats';
import refreshStats from '@salesforce/apex/rflib_BigObjectStatController.refreshStats';
import getFieldMetadata from '@salesforce/apex/rflib_BigObjectStatController.getFieldMetadata';

const logger = createLogger('rflibBigObjectStat');
const CDC_CHANNEL = '/event/rflib_Big_Object_Stat_ChangeEvent__chn';

// Lightning tears the Management Console page down and rebuilds it on every tab switch, so a
// per-instance subscription would unsubscribe and resubscribe to the same channel within ~100ms.
// CometD needs a grace period to release a channel: the in-flight unsubscribe fails and the
// immediate resubscribe yields a dead subscription that receives no events. The subscription is
// therefore shared across instances and its teardown is deferred long enough for the replacement
// instance to take it over. Same delay rationale as rflibLogEventMonitor.
const UNSUBSCRIBE_GRACE_PERIOD_MS = 2500;

const ACTIONS = [{ label: 'Refresh', name: 'refresh' }];

const channelState = {
    subscribePromise: null,
    pendingTeardown: null,
    listeners: new Set()
};

const notifyListeners = (event) => {
    channelState.listeners.forEach((listener) => listener(event));
};

const acquireStatSubscription = (listener) => {
    channelState.listeners.add(listener);

    if (channelState.pendingTeardown) {
        logger.debug('Reusing the Big Object Stat CDC subscription that was pending teardown');
        clearTimeout(channelState.pendingTeardown);
        channelState.pendingTeardown = null;
    }

    if (!channelState.subscribePromise) {
        logger.debug('Subscribing to Big Object Stat CDC events');
        channelState.subscribePromise = subscribe(CDC_CHANNEL, -1, notifyListeners).catch((error) => {
            channelState.subscribePromise = null;
            throw error;
        });
    }

    return channelState.subscribePromise;
};

const releaseStatSubscription = (listener) => {
    channelState.listeners.delete(listener);

    if (channelState.listeners.size > 0 || channelState.pendingTeardown || !channelState.subscribePromise) {
        return;
    }

    const subscribePromise = channelState.subscribePromise;
    channelState.pendingTeardown = setTimeout(() => {
        channelState.pendingTeardown = null;
        channelState.subscribePromise = null;

        logger.debug('Unsubscribing from Big Object Stat CDC events');
        subscribePromise
            .then((subscription) => {
                unsubscribe(subscription, (response) => {
                    logger.debug('Unsubscribed from Big Object Stat CDC events: {0}', JSON.stringify(response));
                });
            })
            .catch((error) => {
                logger.warn('Failed to unsubscribe from Big Object Stat CDC events: {0}', JSON.stringify(error));
            });
    }, UNSUBSCRIBE_GRACE_PERIOD_MS);
};

export default class RflibBigObjectStat extends LightningElement {
    @api bigObjectConfigs;
    @api fieldsToDisplay;

    parsedConfigs;
    statEventListener;
    displayFields = [];
    columns = [];

    wiredStatsResult;
    isRefreshing = false;

    get bigObjects() {
        return this.parsedConfigs?.map((config) => config.name).join(',');
    }

    get hasStats() {
        return this.wiredStatsResult?.data?.length > 0;
    }

    @wire(getStats, { bigObjects: '$bigObjects', fields: '$fieldsToDisplay' })
    wiredStats(result) {
        this.wiredStatsResult = result;
        if (result.data) {
            logger.debug('Received stats data: {0}', JSON.stringify(result.data));
        } else if (result.error) {
            logger.error('Failed to retrieve stats: ' + JSON.stringify(result.error));
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
            logger.error('Failed to get field metadata: {0}', JSON.stringify(error));
            this.handleError('Configuration Error', 'Failed to configure columns for display');
        }
    }

    connectedCallback() {
        try {
            this.parsedConfigs = JSON.parse(this.bigObjectConfigs);
            logger.debug('Parsed configurations: {0}', JSON.stringify(this.parsedConfigs));
        } catch (error) {
            logger.error('Failed to parse big object configurations: {0}', error.message);
            this.handleError('Configuration Error', 'Invalid Big Object configuration format. Expected JSON array.');
            this.parsedConfigs = [];
        }

        logger.debug('Initializing component with bigObjects={0}, fields={1}', this.bigObjects, this.fieldsToDisplay);
        this.displayFields = this.fieldsToDisplay.split(',').map((field) => field.trim());
        this.subscribeToStatEvents();
    }

    disconnectedCallback() {
        logger.debug('Disconnecting component and unsubscribing from events');
        this.unsubscribeFromStatEvents();
    }

    getBigObjectConfig(objectName) {
        return this.parsedConfigs?.find((config) => config.name === objectName);
    }

    async refreshBigObject(bigObjectName) {
        try {
            this.isRefreshing = true;
            const config = this.getBigObjectConfig(bigObjectName);

            if (!config) {
                throw new Error(`Configuration not found for ${bigObjectName}`);
            }

            logger.info(
                'Refreshing stats for big object: {0} with index fields: {1}',
                bigObjectName,
                JSON.stringify(config.indexFields)
            );

            await refreshStats({
                bigObjectName: config.name,
                indexFields: config.indexFields,
                orderBy: config.orderBy
            });
        } catch (error) {
            logger.error('Error refreshing big object stats: {0}', error.message);
            this.handleError('Refresh Error', 'Failed to refresh Big Object statistics: ' + error.message);
        } finally {
            this.isRefreshing = false;
        }
    }

    async countAllBigObjects() {
        try {
            if (!this.parsedConfigs?.length) {
                logger.warn('No Big Objects configured');
                this.handleError('Configuration Error', 'No Big Objects configured for monitoring');
                return;
            }

            this.isRefreshing = true;
            logger.info('Refreshing all configured Big Objects');

            for (const config of this.parsedConfigs) {
                logger.debug('Refreshing stats for {0}', JSON.stringify(config));
                refreshStats({
                    bigObjectName: config.name,
                    indexFields: config.indexFields,
                    orderBy: config.orderBy
                });
            }

            if (!import.meta.env.SSR) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Refresh initiated for all Big Objects',
                        variant: 'success'
                    })
                );
            }
        } catch (error) {
            logger.error('Failed to refresh all Big Objects: {0}', error.message);
            this.handleError('Refresh Error', 'Failed to refresh all Big Object statistics');
        } finally {
            this.isRefreshing = false;
        }
    }

    async subscribeToStatEvents() {
        this.statEventListener = (event) => {
            logger.debug('Received CDC event: {0}', JSON.stringify(event));

            refreshApex(this.wiredStatsResult)
                .then(() => {
                    logger.debug('Successfully refreshed data after CDC event');
                })
                .catch((error) => {
                    logger.error('Error refreshing data after CDC event: {0}', JSON.stringify(error));
                });
        };

        try {
            await acquireStatSubscription(this.statEventListener);
            logger.info('Successfully subscribed to Big Object Stat CDC events');
        } catch (error) {
            logger.error('Failed to subscribe to Big Object Stat CDC events: {0}', JSON.stringify(error));
            this.handleError('Subscription Error', 'Failed to subscribe to Big Object stat updates');
        }
    }

    unsubscribeFromStatEvents() {
        if (this.statEventListener) {
            releaseStatSubscription(this.statEventListener);
            this.statEventListener = undefined;
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
        if (!import.meta.env.SSR) {
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
}
