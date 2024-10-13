import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createLogger } from 'c/rflibLogger';

import getCustomSettingLabel from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettingLabel';
import getCustomSettings from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettings';
import canUserModifyLoggerSettings from '@salesforce/apex/rflib_CustomSettingsEditorController.canUserModifyLoggerSettings';
import deleteCustomSettingRecord from '@salesforce/apex/rflib_CustomSettingsEditorController.deleteCustomSettingRecord';

const logger = createLogger('Rflib_CustomSettingsEditor');

export default class Rflib_CustomSettingsEditor extends LightningElement {
    @api customSettingsApiName;
    @api fieldsToDisplay;

    customSettingsData = [];
    columns = [];
    draftValues = [];
    showModal = false;
    modalHeader = '';
    recordId;
    title;
    fields = [];
    canModifySettings = false;
    isLoading = false;

    connectedCallback() {
        logger.info('Connected callback invoked. Checking user permissions and loading custom settings.');
        this.checkUserPermissions();
        this.loadCustomSettings();
        this.setTitle();
    }

    setTitle() {
        getCustomSettingLabel({ customSettingsApiName: this.customSettingsApiName })
            .then((label) => {
                this.title = `${label} Editor`;
                logger.info('Title set to: {0}', this.title);
            })
            .catch((error) => {
                this.title = 'Custom Settings Editor';
                logger.error('Failed to get custom setting label', error);
                this.showToast('Error', 'Failed to load custom setting label', 'error');
            });
    }

    checkUserPermissions() {
        logger.info('Checking if the user can modify custom settings.');
        canUserModifyLoggerSettings({ customSettingsApiName: this.customSettingsApiName })
            .then((result) => {
                this.canModifySettings = result;
                logger.info('User permission check result: {0}', result);
            })
            .catch((error) => {
                logger.error('Error occurred while checking user permissions: ' + JSON.stringify(error));
                this.showToast('Error', error.body.message, 'error');
            });
    }

    loadCustomSettings() {
        this.isLoading = true;
        logger.info('Loading custom settings for API name: {0}', this.customSettingsApiName);
        getCustomSettings({ customSettingsApiName: this.customSettingsApiName })
            .then((result) => {
                // Ensure data is formatted correctly for LWC datatable
                this.customSettingsData = result.map((setting) => {
                    let row = {
                        id: setting.id,
                        setupOwnerType:
                            setting.setupOwnerType === 'Name' ? 'Default Organization Values' : setting.setupOwnerType,
                        setupOwnerName:
                            setting.setupOwnerType === 'Organization' ? 'Organization' : setting.setupOwnerName
                    };
                    // Flatten the fields map to be direct properties of the row object
                    const fieldKeys = Object.keys(setting.fields);
                    fieldKeys.forEach((key) => {
                        row[key] = setting.fields[key];
                    });

                    return row;
                });

                // Set up columns with correct labels
                this.columns = this.createColumns(result[0]?.fields || [], result[0]?.fieldLabels || {});

                this.isLoading = false;
                logger.info('Custom settings loaded successfully: {0}', JSON.stringify(result));
            })
            .catch((error) => {
                logger.error('Failed to load custom settings', error);
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    createColumns(fields, fieldLabels) {
        logger.info('Creating columns for datatable. Fields to display: {0}', this.fieldsToDisplay);
        let columns = [
            { label: 'Setup Owner Type', fieldName: 'setupOwnerType', type: 'text' },
            { label: 'Setup Owner Name', fieldName: 'setupOwnerName', type: 'text' }
        ];

        // Add fields specified in fieldsToDisplay property, using labels
        if (this.fieldsToDisplay) {
            const fieldNames = this.fieldsToDisplay.split(',').map((field) => field.trim());
            fieldNames.forEach((fieldName) => {
                const fieldLabel = fieldLabels[fieldName] || fieldName;
                columns.push({ label: fieldLabel, fieldName: fieldName, type: 'text' });
            });
        }

        if (this.canModifySettings) {
            columns.push({
                type: 'action',
                typeAttributes: {
                    rowActions: this.getRowActions
                }
            });
        }

        logger.info('Columns created: {0}', JSON.stringify(columns));
        return columns;
    }

    getRowActions(row, doneCallback) {
        logger.info('Getting row actions for row: {0}', JSON.stringify(row));
        const actions = [];
        actions.push({ label: 'Edit', name: 'edit' });
        if (row.setupOwnerType !== 'Organization') {
            actions.push({ label: 'Delete', name: 'delete' });
        }
        doneCallback(actions);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.recordId = row.id;
        logger.info('Handling row action. Action: {0}, Record ID: {1}', actionName, this.recordId);
        switch (actionName) {
            case 'edit':
                this.handleEditRecord();
                break;
            case 'delete':
                this.handleDeleteRecord();
                break;
            default:
                logger.error('Invalid row action provided: ' + actionName);
        }
    }

    handleNewRecord() {
        logger.info('Handling new record creation.');
        this.modalHeader = 'New Custom Setting';
        this.showModal = true;
        this.recordId = null;
    }

    handleEditRecord() {
        logger.info('Handling edit record. Record ID: {0}', this.recordId);
        this.modalHeader = 'Edit Custom Setting';
        this.showModal = true;
    }

    closeModal() {
        logger.info('Closing modal dialog.');
        this.showModal = false;
    }

    handleModalSave() {
        logger.info('Saving custom setting.');
        const form = this.template.querySelector('lightning-record-edit-form');
        if (form) {
            form.submit();
        }
    }

    handleModalSubmit(event) {
        event.preventDefault(); // Prevent default submission
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleModalSaveSuccess() {
        logger.info('Custom setting saved successfully.');
        this.showToast('Success', 'Record saved successfully.', 'success');
        this.loadCustomSettings();
        this.showModal = false;
    }

    handleDeleteRecord() {
        logger.info('Handling delete record. Record ID: {0}', this.recordId);
        deleteCustomSettingRecord({
            customSettingsApiName: this.customSettingsApiName,
            recordId: this.recordId
        })
            .then(() => {
                logger.info('Record deleted successfully. Record ID: {0}', this.recordId);
                this.showToast('Success', 'Record deleted successfully.', 'success');
                this.loadCustomSettings();
            })
            .catch((error) => {
                logger.error('Failed to delete record: ' + JSON.stringify(error));
                this.showToast('Error', 'Failed to delete record', 'error');
            });
    }

    handleRefresh() {
        logger.info('Handling refresh action.');
        this.loadCustomSettings();
    }

    showToast(title, message, variant) {
        logger.info('Showing toast message. Title: {0}, Message: {1}, Variant: {2}', title, message, variant);
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}
