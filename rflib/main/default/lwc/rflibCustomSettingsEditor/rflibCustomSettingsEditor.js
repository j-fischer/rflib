import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createLogger } from 'c/rflibLogger';

import getCustomSettingLabel from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettingLabel';
import getCustomSettings from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettings';
import getCustomSettingFields from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettingFields';
import canUserModifyLoggerSettings from '@salesforce/apex/rflib_CustomSettingsEditorController.canUserModifyLoggerSettings';
import deleteCustomSettingRecord from '@salesforce/apex/rflib_CustomSettingsEditorController.deleteCustomSettingRecord';
import saveCustomSetting from '@salesforce/apex/rflib_CustomSettingsEditorController.saveCustomSetting';

const logger = createLogger('RflibCustomSettingsEditor');

export default class RflibCustomSettingsEditor extends LightningElement {
    @api customSettingsApiName;
    @api fieldsToDisplay;

    customSettingsData = [];
    columns = [];
    draftValues = [];
    showModal = false;
    isNewModal = false;
    modalHeader = '';
    selectedType = 'UserType';

    recordId;
    title;
    canModifySettings = false;
    isLoading = false;

    // Confirmation Dialog Properties
    showDeleteConfirmation = false;
    deleteDialogTitle = 'Confirm Deletion';
    deleteDialogMessage = 'Are you sure you want to delete this record?';
    deleteDialogConfirmLabel = 'Delete';
    deleteDialogCancelLabel = 'Cancel';

    // Field Metadata and Record Values
    fieldInfos = [];
    @track recordValues = {};

    ownerFilter = {
        criteria: [
            {
                fieldPath: 'IsActive',
                operator: 'eq',
                value: true
            }
        ]
    };
    ownerMatchingInfo = {
        primaryField: { fieldPath: 'Name' }
    };

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
                // Map the data for the datatable
                this.customSettingsData = result.map((setting) => {
                    let row = {
                        id: setting.id,
                        setupOwnerId: setting.setupOwnerId,
                        setupOwnerType: setting.setupOwnerType,
                        setupOwnerName: setting.setupOwnerName
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
                logger.info('Custom settings loaded successfully.');
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
        actions.push({ label: 'Delete', name: 'delete' });
        doneCallback(actions);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.recordId = row.id;
        logger.info('Handling row action. Action: {0}, Record ID: {1}', actionName, this.recordId);
        switch (actionName) {
            case 'edit':
                this.handleEditRecord(row);
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
        this.isNewModal = true;
        this.modalHeader = 'New Custom Setting';
        this.recordId = null;
        this.recordValues = {}; // Initialize recordValues

        this.loadFieldInfos()
            .then(() => {
                this.showModal = true;
            })
            .catch((error) => {
                logger.error('Failed to load field infos', error);
                this.showToast('Error', 'Failed to load field information', 'error');
            });
    }

    handleEditRecord(row) {
        logger.info('Handling edit record. Record ID: {0}', row.id);
        this.isNewModal = false;
        this.modalHeader = 'Edit Custom Setting';
        // Set recordValues based on the row data
        this.recordValues = { ...row };
        this.setupOwnerId = row.setupOwnerId;
        this.setupOwnerType = row.setupOwnerType;
        this.recordId = row.id;
        this.loadFieldInfos()
            .then(() => {
                this.showModal = true;
            })
            .catch((error) => {
                logger.error('Failed to load field infos', error);
                this.showToast('Error', 'Failed to load field information', 'error');
            });
    }

    loadFieldInfos() {
        return getCustomSettingFields({ customSettingsApiName: this.customSettingsApiName })
            .then((fields) => {
                // Enhance each fieldInfo object with field type flags and value
                this.fieldInfos = fields.map((fieldInfo) => {
                    const dataType = fieldInfo.dataType;
                    let value = '';

                    if (this.isNewModal) {
                        value = fieldInfo.defaultValue;
                    } else {
                        value = this.recordValues[fieldInfo.apiName] || '';
                    }

                    return {
                        ...fieldInfo,
                        isTextField:
                            dataType === 'STRING' || dataType === 'EMAIL' || dataType === 'PHONE' || dataType === 'URL',
                        isNumberField: dataType === 'DOUBLE' || dataType === 'INTEGER' || dataType === 'CURRENCY',
                        isBooleanField: dataType === 'BOOLEAN',
                        value: value
                    };
                });
                logger.info('Field infos loaded: ' + JSON.stringify(this.fieldInfos));
            })
            .catch((error) => {
                logger.error('Failed to get custom setting fields', error);
                throw error;
            });
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.fieldName;
        let value;
        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        } else {
            value = event.target.value;
        }
        logger.info('Field changed: {0} = {1}', fieldName, value);
        this.recordValues[fieldName] = value;
        // Update the value in fieldInfos
        const fieldInfo = this.fieldInfos.find((field) => field.apiName === fieldName);
        if (fieldInfo) {
            fieldInfo.value = value;
        }
    }

    handleOwnerIdChanged(event) {
        let newOwnerId = event.detail.recordId;
        if (this.setupOwnerId !== newOwnerId) {
            logger.debug('Setting owner ID={0}', newOwnerId);
            this.setupOwnerId = newOwnerId;
        }
    }

    closeModal() {
        logger.info('Closing modal dialog.');
        this.showModal = false;
    }

    handleModalSave() {
        logger.info('Saving custom setting.');
        // Create an object with the custom setting fields
        const customSettingRecord = {
            sobjectType: this.customSettingsApiName
        };
        if (this.recordId) {
            // Existing record - set Id but do not set SetupOwnerId
            customSettingRecord.Id = this.recordId;
        } else {
            // New record - set SetupOwnerId
            customSettingRecord.SetupOwnerId = this.setupOwnerId;
        }
        this.fieldInfos.forEach((fieldInfo) => {
            if (fieldInfo.isCreateable || fieldInfo.isUpdateable) {
                customSettingRecord[fieldInfo.apiName] = fieldInfo.value;
            }
        });
        logger.info('Custom setting record to save: {0}', JSON.stringify(customSettingRecord));

        saveCustomSetting({ customSettingRecord })
            .then(() => {
                logger.info('Custom setting saved successfully.');
                this.showToast('Success', 'Record saved successfully.', 'success');
                this.loadCustomSettings();
                this.showModal = false;
            })
            .catch((error) => {
                logger.error('Failed to save custom setting', error);
                this.showToast('Error', 'Failed to save record', 'error');
            });
    }

    handleDeleteRecord() {
        logger.info('Preparing to delete record. Record ID: {0}', this.recordId);
        // Set up the confirmation dialog properties
        this.showDeleteConfirmation = true;
    }

    handleModalAction(event) {
        const status = event.detail.status;
        this.showDeleteConfirmation = false;
        if (status === 'confirm') {
            logger.info('User confirmed deletion.');
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
        } else {
            logger.info('User cancelled deletion.');
        }
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

    getPicklistOptions(fieldInfo) {
        return fieldInfo.picklistValues.map((entry) => ({
            label: entry.value,
            value: entry.value
        }));
    }

    get typeOptions() {
        return [
            { label: 'User', value: 'UserType' },
            { label: 'Profile', value: 'ProfileType' }
        ];
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
    }

    get isUserType() {
        return this.selectedType === 'UserType';
    }

    get isProfileType() {
        return this.selectedType === 'ProfileType';
    }
}
