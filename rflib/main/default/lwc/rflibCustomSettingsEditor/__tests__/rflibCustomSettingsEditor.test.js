import { createElement } from 'lwc';
import RflibCustomSettingsEditor from 'c/rflibCustomSettingsEditor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import canUserModifyCustomSettings from '@salesforce/apex/rflib_CustomSettingsEditorController.canUserModifyCustomSettings';
import deleteCustomSettingRecord from '@salesforce/apex/rflib_CustomSettingsEditorController.deleteCustomSettingRecord';
import getCustomSettingFields from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettingFields';
import getCustomSettingLabel from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettingLabel';
import getCustomSettings from '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettings';
import saveCustomSetting from '@salesforce/apex/rflib_CustomSettingsEditorController.saveCustomSetting';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/rflib_CustomSettingsEditorController.canUserModifyCustomSettings',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_CustomSettingsEditorController.deleteCustomSettingRecord',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettingFields',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettingLabel',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_CustomSettingsEditorController.getCustomSettings',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_CustomSettingsEditorController.saveCustomSetting',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

// Mock rflibLogger
jest.mock(
    'c/rflibLogger',
    () => {
        return {
            createLogger: () => ({
                debug: jest.fn(),
                error: jest.fn(),
                info: jest.fn(),
                warn: jest.fn()
            })
        };
    },
    { virtual: true }
);

// Sample Data
const MOCK_SETTINGS_DATA = [
    {
        id: '1',
        setupOwnerId: 'owner1',
        setupOwnerName: 'User A',
        setupOwnerType: 'User',
        fields: {
            Field1__c: 'Value1',
            Field2__c: 123
        },
        fieldLabels: {
            Field1__c: 'Field 1',
            Field2__c: 'Field 2'
        }
    }
];

const MOCK_FIELD_INFOS = [
    {
        apiName: 'Field1__c',
        label: 'Field 1',
        dataType: 'STRING',
        isCreateable: true,
        isUpdateable: true,
        length: 255
    },
    {
        apiName: 'Field2__c',
        label: 'Field 2',
        dataType: 'DOUBLE',
        isCreateable: true,
        isUpdateable: true
    },
    {
        apiName: 'IsActive__c',
        label: 'Is Active',
        dataType: 'BOOLEAN',
        isCreateable: true,
        isUpdateable: true,
        defaultValue: false
    }
];

// The mock for ShowToastEvent in this repo uses 'lightning__ShowToastEvent'
const SHOW_TOAST_EVENT_NAME = 'lightning__ShowToastEvent';

describe('c-rflib-custom-settings-editor', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    async function flushPromises() {
        return new Promise(resolve => setTimeout(resolve, 0));
    }

    it('initializes correctly with data and permissions', async () => {
        getCustomSettingLabel.mockResolvedValue('My Custom Setting');
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockResolvedValue(MOCK_SETTINGS_DATA);

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        element.fieldsToDisplay = 'Field1__c, Field2__c';
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        expect(getCustomSettingLabel).toHaveBeenCalledWith({ customSettingsApiName: 'My_Setting__c' });
        expect(canUserModifyCustomSettings).toHaveBeenCalledWith({ customSettingsApiName: 'My_Setting__c' });
        expect(getCustomSettings).toHaveBeenCalledWith({ customSettingsApiName: 'My_Setting__c' });

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toHaveLength(1);
        expect(datatable.data[0].Field1__c).toBe('Value1');

        expect(datatable.columns).toHaveLength(5);
    });

    it('handles initialization error for label', async () => {
        getCustomSettingLabel.mockRejectedValue({ body: { message: 'Label Error' } });
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockResolvedValue([]);

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        const toastHandler = jest.fn();
        element.addEventListener(SHOW_TOAST_EVENT_NAME, toastHandler);

        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
        expect(toastHandler.mock.calls[0][0].detail.message).toContain('Label Error');
    });

    it('handles initialization error for permissions', async () => {
        getCustomSettingLabel.mockResolvedValue('Label');
        canUserModifyCustomSettings.mockRejectedValue({ body: { message: 'Perm Error' } });
        getCustomSettings.mockResolvedValue([]);

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        const toastHandler = jest.fn();
        element.addEventListener(SHOW_TOAST_EVENT_NAME, toastHandler);

        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.message).toContain('Perm Error');
    });

    it('handles initialization error for settings data', async () => {
        getCustomSettingLabel.mockResolvedValue('Label');
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockRejectedValue({ body: { message: 'Data Error' } });

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        const toastHandler = jest.fn();
        element.addEventListener(SHOW_TOAST_EVENT_NAME, toastHandler);

        await flushPromises();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.message).toContain('Data Error');
    });

    it('opens new record modal and saves successfully', async () => {
        getCustomSettingLabel.mockResolvedValue('Label');
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockResolvedValue([]);
        getCustomSettingFields.mockResolvedValue(MOCK_FIELD_INFOS);
        saveCustomSetting.mockResolvedValue();

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        const actionButtons = element.shadowRoot.querySelectorAll('div[slot="actions"] lightning-button');
        const newButton = actionButtons[1];
        expect(newButton).not.toBeUndefined();
        newButton.click();

        await flushPromises();
        await flushPromises();

        expect(element.shadowRoot.querySelector('section.slds-modal')).not.toBeNull();
        expect(getCustomSettingFields).toHaveBeenCalledWith({ customSettingsApiName: 'My_Setting__c' });

        const typeCombobox = element.shadowRoot.querySelector('lightning-combobox');
        expect(typeCombobox).not.toBeNull();
        typeCombobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'UserType' } }));

        await flushPromises();

        const recordPicker = element.shadowRoot.querySelector('lightning-record-picker');
        expect(recordPicker).not.toBeNull();
        recordPicker.dispatchEvent(new CustomEvent('change', { detail: { recordId: 'newOwnerId' } }));

        const inputs = element.shadowRoot.querySelectorAll('input');
        inputs.forEach(input => {
            if (input.dataset.fieldName === 'Field1__c') {
                input.value = 'New Value';
                input.dispatchEvent(new Event('change'));
            }
        });

        const footerButtons = element.shadowRoot.querySelectorAll('footer.slds-modal__footer lightning-button');
        const saveButton = footerButtons[1];
        saveButton.click();

        await flushPromises();

        expect(saveCustomSetting).toHaveBeenCalled();
        const saveCall = saveCustomSetting.mock.calls[0][0];
        expect(saveCall.customSettingRecord.sobjectType).toBe('My_Setting__c');
        expect(saveCall.customSettingRecord.SetupOwnerId).toBe('newOwnerId');
        expect(saveCall.customSettingRecord.Field1__c).toBe('New Value');

        expect(getCustomSettings).toHaveBeenCalledTimes(2);
    });

    it('opens edit modal and saves successfully', async () => {
        getCustomSettingLabel.mockResolvedValue('Label');
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockResolvedValue(MOCK_SETTINGS_DATA);
        getCustomSettingFields.mockResolvedValue(MOCK_FIELD_INFOS);
        saveCustomSetting.mockResolvedValue();

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(new CustomEvent('rowaction', {
            detail: {
                action: { name: 'edit' },
                row: MOCK_SETTINGS_DATA[0]
            }
        }));

        await flushPromises();

        expect(element.shadowRoot.querySelector('section.slds-modal')).not.toBeNull();

        const inputs = element.shadowRoot.querySelectorAll('input');
        inputs.forEach(input => {
            if (input.dataset.fieldName === 'Field1__c') {
                input.value = 'Updated Value';
                input.dispatchEvent(new Event('change'));
            }
        });

        const footerButtons = element.shadowRoot.querySelectorAll('footer.slds-modal__footer lightning-button');
        const saveButton = footerButtons[1];
        saveButton.click();

        await flushPromises();

        expect(saveCustomSetting).toHaveBeenCalled();
        const saveCall = saveCustomSetting.mock.calls[0][0];
        expect(saveCall.customSettingRecord.Id).toBe('1');
        expect(saveCall.customSettingRecord.Field1__c).toBe('Updated Value');
    });

    it('handles delete action', async () => {
        getCustomSettingLabel.mockResolvedValue('Label');
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockResolvedValue(MOCK_SETTINGS_DATA);
        deleteCustomSettingRecord.mockResolvedValue();

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(new CustomEvent('rowaction', {
            detail: {
                action: { name: 'delete' },
                row: MOCK_SETTINGS_DATA[0]
            }
        }));

        await flushPromises();

        const confirmDialog = element.shadowRoot.querySelector('c-rflib-confirmation-dialog');
        expect(confirmDialog).not.toBeNull();
        expect(confirmDialog.visible).toBe(true);

        confirmDialog.dispatchEvent(new CustomEvent('modalaction', {
            detail: { status: 'confirm' }
        }));

        await flushPromises();

        expect(deleteCustomSettingRecord).toHaveBeenCalledWith({
            customSettingsApiName: 'My_Setting__c',
            recordId: '1'
        });
        expect(getCustomSettings).toHaveBeenCalledTimes(2);
    });

    it('cancels delete action', async () => {
        getCustomSettingLabel.mockResolvedValue('Label');
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockResolvedValue(MOCK_SETTINGS_DATA);

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(new CustomEvent('rowaction', {
            detail: {
                action: { name: 'delete' },
                row: MOCK_SETTINGS_DATA[0]
            }
        }));

        await flushPromises();

        const confirmDialog = element.shadowRoot.querySelector('c-rflib-confirmation-dialog');
        confirmDialog.dispatchEvent(new CustomEvent('modalaction', {
            detail: { status: 'cancel' }
        }));

        await flushPromises();
        expect(deleteCustomSettingRecord).not.toHaveBeenCalled();
    });

    it('handles save error', async () => {
        getCustomSettingLabel.mockResolvedValue('Label');
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockResolvedValue([]);
        getCustomSettingFields.mockResolvedValue(MOCK_FIELD_INFOS);
        saveCustomSetting.mockRejectedValue({ body: { message: 'Save Failed' } });

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        const actionButtons = element.shadowRoot.querySelectorAll('div[slot="actions"] lightning-button');
        const newButton = actionButtons[1];
        newButton.click();
        await flushPromises();

        const footerButtons = element.shadowRoot.querySelectorAll('footer.slds-modal__footer lightning-button');
        const saveButton = footerButtons[1];

        const toastHandler = jest.fn();
        element.addEventListener(SHOW_TOAST_EVENT_NAME, toastHandler);

        saveButton.click();
        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
        expect(toastHandler.mock.calls[0][0].detail.message).toContain('Save Failed');
    });

    it('refresh button reloads settings', async () => {
        getCustomSettingLabel.mockResolvedValue('Label');
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockResolvedValue([]);

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        expect(getCustomSettings).toHaveBeenCalledTimes(1);

        const actionButtons = element.shadowRoot.querySelectorAll('div[slot="actions"] lightning-button');
        const refreshButton = actionButtons[0];
        expect(refreshButton).not.toBeUndefined();
        refreshButton.click();

        await flushPromises();
        expect(getCustomSettings).toHaveBeenCalledTimes(2);
    });

    it('handles checkbox field change', async () => {
        getCustomSettingLabel.mockResolvedValue('Label');
        canUserModifyCustomSettings.mockResolvedValue(true);
        getCustomSettings.mockResolvedValue([]);
        getCustomSettingFields.mockResolvedValue(MOCK_FIELD_INFOS);
        saveCustomSetting.mockResolvedValue();

        const element = createElement('c-rflib-custom-settings-editor', {
            is: RflibCustomSettingsEditor
        });
        element.customSettingsApiName = 'My_Setting__c';
        document.body.appendChild(element);

        await flushPromises();
        await flushPromises();

        const actionButtons = element.shadowRoot.querySelectorAll('div[slot="actions"] lightning-button');
        const newButton = actionButtons[1];
        newButton.click();
        await flushPromises();
        await flushPromises();

        const checkbox = element.shadowRoot.querySelector('lightning-input[data-field-name="IsActive__c"]');
        expect(checkbox).not.toBeNull();

        checkbox.checked = true;
        checkbox.dispatchEvent(new CustomEvent('change'));

        const footerButtons = element.shadowRoot.querySelectorAll('footer.slds-modal__footer lightning-button');
        const saveButton = footerButtons[1];
        saveButton.click();
        await flushPromises();

        const saveCall = saveCustomSetting.mock.calls[0][0];
        expect(saveCall.customSettingRecord.IsActive__c).toBe(true);
    });
});
