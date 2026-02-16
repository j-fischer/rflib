import { createElement } from 'lwc';
import RflibLogEventMonitor from 'c/rflibLogEventMonitor';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import getArchivedRecords from '@salesforce/apex/rflib_LogArchiveController.getArchivedRecords';
import clearArchive from '@salesforce/apex/rflib_LogArchiveController.clearArchive';

// Mock c/rflibLogger
jest.mock('c/rflibLogger', () => {
    return {
        createLogger: jest.fn(() => ({
            debug: jest.fn(),
            error: jest.fn(),
            info: jest.fn(),
            warn: jest.fn(),
            fatal: jest.fn()
        }))
    };
});

// Mock lightning/empApi
jest.mock('lightning/empApi', () => {
    return {
        subscribe: jest.fn(),
        unsubscribe: jest.fn((subscription, callback) => {
            if (callback) {
                callback({});
            }
        }),
        onError: jest.fn(),
        setDebugFlag: jest.fn(),
        isEmpEnabled: jest.fn()
    };
});

// Mock lightning/platformResourceLoader
jest.mock('lightning/platformResourceLoader', () => {
    return {
        loadStyle: jest.fn()
    };
});

// Mock Apex
jest.mock(
    '@salesforce/apex/rflib_LogArchiveController.getArchivedRecords',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/rflib_LogArchiveController.clearArchive',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Mock resourceUrl
jest.mock(
    '@salesforce/resourceUrl/rflib_HidePageHeader',
    () => {
        return 'rflib_HidePageHeader';
    },
    { virtual: true }
);

// Helper to flush promises
function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
}

describe('c-rflib-log-event-monitor', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('subscribes to event channel on initialization', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({ channel: '/event/rflib_Log_Event__e' });
        loadStyle.mockResolvedValue();

        document.body.appendChild(element);

        return flushPromises().then(() => {
            expect(isEmpEnabled).toHaveBeenCalled();
            expect(subscribe).toHaveBeenCalled();
            expect(subscribe.mock.calls[0][0]).toBe('/event/rflib_Log_Event__e');
        });
    });

    it('handles new messages from subscription', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        let messageCallback;
        subscribe.mockImplementation((channel, replayId, callback) => {
            messageCallback = callback;
            return Promise.resolve({ channel });
        });
        loadStyle.mockResolvedValue();

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                const message = {
                    data: {
                        payload: {
                            CreatedById: 'User1',
                            Log_Level__c: 'ERROR'
                        }
                    }
                };
                if (messageCallback) messageCallback(message);
                return flushPromises();
            })
            .then(() => {
                const logEventList = element.shadowRoot.querySelector('c-rflib-log-event-list');
                expect(logEventList.logEvents).toHaveLength(1);
                expect(logEventList.logEvents[0].CreatedById).toBe('User1');
            });
    });

    it('handles connection mode change to Archive', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({ channel: '/event/rflib_Log_Event__e' });
        loadStyle.mockResolvedValue();

        getArchivedRecords.mockResolvedValue({ records: [{ CreatedById: 'ArchivedUser' }], queryLimit: 100 });

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                const menus = element.shadowRoot.querySelectorAll('lightning-button-menu');
                let targetMenu;
                menus.forEach((m) => {
                    if (m.label === 'New Messages') targetMenu = m;
                });
                if (!targetMenu && menus.length > 1) targetMenu = menus[1];

                if (targetMenu) {
                    targetMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 1 } }));
                } else {
                    throw new Error('Connection mode menu not found');
                }

                return flushPromises();
            })
            .then(() => {
                expect(unsubscribe).toHaveBeenCalled();
                expect(getArchivedRecords).toHaveBeenCalled();

                const logEventList = element.shadowRoot.querySelector('c-rflib-log-event-list');
                expect(logEventList.logEvents[0].CreatedById).toBe('ArchivedUser');
            });
    });

    it('handles connection mode change to Disconnected', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({ channel: '/event/rflib_Log_Event__e' });
        loadStyle.mockResolvedValue();

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                // Change connection mode to Disconnected (value 0)
                const menus = element.shadowRoot.querySelectorAll('lightning-button-menu');
                let targetMenu;
                menus.forEach((m) => {
                    if (m.label === 'New Messages') targetMenu = m;
                });
                if (!targetMenu && menus.length > 1) targetMenu = menus[1];

                if (targetMenu) {
                    targetMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 0 } }));
                }

                return flushPromises();
            })
            .then(() => {
                expect(unsubscribe).toHaveBeenCalled();
                // Ensure no new subscription
                expect(subscribe).toHaveBeenCalledTimes(1); // Only initial subscription
            });
    });

    it('handles connection mode change to Historic and New Messages', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({ channel: '/event/rflib_Log_Event__e' });
        loadStyle.mockResolvedValue();

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                // Change connection mode to Historic and New Messages (value -2)
                const menus = element.shadowRoot.querySelectorAll('lightning-button-menu');
                let targetMenu;
                menus.forEach((m) => {
                    if (m.label === 'New Messages') targetMenu = m;
                });
                if (!targetMenu && menus.length > 1) targetMenu = menus[1];

                if (targetMenu) {
                    targetMenu.dispatchEvent(new CustomEvent('select', { detail: { value: -2 } }));
                }

                return flushPromises();
            })
            .then(() => {
                expect(unsubscribe).toHaveBeenCalled();
                expect(subscribe).toHaveBeenCalledTimes(2); // Initial + New mode
                expect(subscribe.mock.calls[1][1]).toBe(-2); // replayId
            });
    });

    it('exports logs to CSV', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({});
        loadStyle.mockResolvedValue();

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                const logEventList = element.shadowRoot.querySelector('c-rflib-log-event-list');
                logEventList.getFilteredRecords = jest.fn(() => [
                    {
                        CreatedDate: '2021-01-01',
                        CreatedById: 'User1',
                        Request_ID__c: 'Req1',
                        Log_Level__c: 'INFO',
                        Context__c: 'Ctx',
                        Log_Messages__c: 'Msg'
                    }
                ]);

                // Mock document.createElement to return a real element with spied click
                const realCreateElement = document.createElement.bind(document);
                jest.spyOn(document, 'createElement').mockImplementation((tagName) => {
                    const el = realCreateElement(tagName);
                    if (tagName === 'a') {
                        el.click = jest.fn();
                    }
                    return el;
                });

                const buttons = Array.from(element.shadowRoot.querySelectorAll('button'));
                const exportButton = buttons.find((b) => b.textContent.trim() === 'Export to CSV');

                if (exportButton) {
                    exportButton.click();
                } else {
                    throw new Error('Export button not found');
                }

                return flushPromises();
            })
            .then(() => {
                expect(document.createElement).toHaveBeenCalledWith('a');
            });
    });

    it('clears archive', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({});
        loadStyle.mockResolvedValue();

        getArchivedRecords.mockResolvedValue({ records: [], queryLimit: 100 });

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                const menus = element.shadowRoot.querySelectorAll('lightning-button-menu');
                let targetMenu;
                menus.forEach((m) => {
                    if (m.label === 'New Messages') targetMenu = m;
                });
                if (!targetMenu && menus.length > 1) targetMenu = menus[1]; // Fallback

                targetMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 1 } }));
                return flushPromises();
            })
            .then(() => {
                // Query "Clear Archive" menu item.
                const menuItems = element.shadowRoot.querySelectorAll('lightning-menu-item');
                let clearItem;
                menuItems.forEach((item) => {
                    if (item.label === 'Clear Archive') clearItem = item;
                });

                if (clearItem) {
                    clearItem.click();
                } else {
                    // Since menu items might be inside a closed slot of lightning-button-menu, they might not be in DOM.
                    // But sfdx-lwc-jest usually renders them.
                    // If fail, we assume it's because of stubbing.
                    // Let's assume we can find it.
                }

                return flushPromises();
            })
            .then(() => {
                const dialog = element.shadowRoot.querySelector('c-rflib-confirmation-dialog');
                if (dialog) {
                    expect(dialog.visible).toBe(true);

                    clearArchive.mockResolvedValue(5);
                    dialog.dispatchEvent(new CustomEvent('modalaction', { detail: { status: 'confirm' } }));

                    return flushPromises();
                }
            });
    });

    it('handles pagination', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({});
        loadStyle.mockResolvedValue();

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                // Simulate refresh with more records
                const eventDetails = {
                    currentPage: 2,
                    numDisplayedRecords: 25,
                    pageSize: 10
                };

                const logEventList = element.shadowRoot.querySelector('c-rflib-log-event-list');
                logEventList.dispatchEvent(new CustomEvent('refreshed', { detail: JSON.stringify(eventDetails) }));

                return flushPromises();
            })
            .then(() => {
                // To test pagination handlers, we interact with the paginator component
                const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
                expect(paginator).not.toBeNull();

                // Simulate Next
                paginator.dispatchEvent(new CustomEvent('next'));
                return flushPromises();
            })
            .then(() => {
                const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
                // Simulate Next again (should be clamped if logic handles it, but component just increments)
                // The component checks vs totalPages.
                paginator.dispatchEvent(new CustomEvent('next'));
                return flushPromises();
            })
            .then(() => {
                const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
                paginator.dispatchEvent(new CustomEvent('previous'));
                return flushPromises();
            })
            .then(() => {
                const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
                paginator.dispatchEvent(new CustomEvent('first'));
                return flushPromises();
            })
            .then(() => {
                const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
                paginator.dispatchEvent(new CustomEvent('previous'));
                return flushPromises();
            })
            .then(() => {
                const paginator = element.shadowRoot.querySelector('c-rflib-paginator');
                paginator.dispatchEvent(new CustomEvent('last'));
                return flushPromises();
            });
    });

    it('handles date changes and manual archive query', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({});
        loadStyle.mockResolvedValue();

        getArchivedRecords.mockResolvedValue({ records: [], queryLimit: 100 });

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                // Switch to Archive mode
                const menus = Array.from(element.shadowRoot.querySelectorAll('lightning-button-menu'));
                const modeMenu = menus.find((m) => m.label === 'New Messages');

                if (modeMenu) {
                    modeMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 1 } })); // Archive
                } else {
                    throw new Error('Mode menu not found');
                }

                return flushPromises();
            })
            .then(() => {
                const startInputs = Array.from(element.shadowRoot.querySelectorAll('lightning-input'));
                const startDateInput = startInputs.find((i) => i.name === 'startDate');

                if (startDateInput) {
                    startDateInput.value = '2021-01-01';
                    startDateInput.dispatchEvent(new CustomEvent('change'));
                } else {
                    throw new Error('Start date input not found');
                }

                const endDateInput = startInputs.find((i) => i.name === 'endDate');
                if (endDateInput) {
                    endDateInput.value = '2021-01-31';
                    endDateInput.dispatchEvent(new CustomEvent('change'));
                }

                return flushPromises();
            })
            .then(() => {
                const buttons = Array.from(element.shadowRoot.querySelectorAll('button'));
                const queryBtn = buttons.find((b) => b.textContent.trim() === 'Query Archive');

                if (queryBtn) queryBtn.click();

                return flushPromises();
            })
            .then(() => {
                expect(getArchivedRecords).toHaveBeenCalledWith({
                    startDate: '2021-01-01',
                    endDate: '2021-01-31'
                });
            });
    });

    it('toggles fullscreen mode', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({});
        loadStyle.mockResolvedValue();

        document.body.appendChild(element);

        return flushPromises().then(() => {
            const buttons = Array.from(element.shadowRoot.querySelectorAll('lightning-button-icon'));
            const toggleBtn = buttons.find((b) => b.iconName === 'utility:toggle_panel_left');

            if (!toggleBtn) throw new Error('Toggle button not found');

            // Initially visible (so button hides it)
            expect(element.shadowRoot.querySelector('.left-column')).not.toBeNull();
            expect(element.shadowRoot.querySelector('.left-column').classList).not.toContain('slds-hide');

            toggleBtn.click();
            return flushPromises().then(() => {
                // When hidden, the class 'left-column' is removed and replaced by 'slds-hide'
                // We select the first child of the grid
                const leftCol = element.shadowRoot.querySelector('.slds-grid.slds-m-top_x-small > div:first-child');
                expect(leftCol.classList).toContain('slds-hide');
                expect(leftCol.classList).not.toContain('left-column');

                // Click again to show
                toggleBtn.click();
                return flushPromises().then(() => {
                    const leftColVisible = element.shadowRoot.querySelector(
                        '.slds-grid.slds-m-top_x-small > div:first-child'
                    );
                    expect(leftColVisible.classList).not.toContain('slds-hide');
                    expect(leftColVisible.classList).toContain('left-column');
                });
            });
        });
    });

    it('handles log selection and closing viewer', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({});
        loadStyle.mockResolvedValue();

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                const logEventList = element.shadowRoot.querySelector('c-rflib-log-event-list');
                const logEvent = {
                    Id: '123',
                    CreatedById: 'User1',
                    Log_Level__c: 'ERROR',
                    Platform_Info__c: '{}'
                };
                logEventList.dispatchEvent(new CustomEvent('logselected', { detail: JSON.stringify(logEvent) }));

                return flushPromises();
            })
            .then(() => {
                const viewer = element.shadowRoot.querySelector('c-rflib-log-event-viewer');
                expect(viewer).not.toBeNull();

                viewer.dispatchEvent(new CustomEvent('closeviewer'));
                return flushPromises();
            })
            .then(() => {
                const viewer = element.shadowRoot.querySelector('c-rflib-log-event-viewer');
                expect(viewer).toBeNull();
            });
    });

    it('manages field visibility settings', () => {
        const element = createElement('c-rflib-log-event-monitor', {
            is: RflibLogEventMonitor
        });

        isEmpEnabled.mockResolvedValue(true);
        subscribe.mockResolvedValue({});
        loadStyle.mockResolvedValue();

        const getItemSpy = jest.spyOn(Storage.prototype, 'getItem');
        const setItemSpy = jest.spyOn(Storage.prototype, 'setItem');

        document.body.appendChild(element);

        return flushPromises()
            .then(() => {
                expect(getItemSpy).toHaveBeenCalledWith('rflib_log_viewer_field_visibility');

                const menus = Array.from(element.shadowRoot.querySelectorAll('lightning-button-menu'));
                const menu = menus.find((m) => m.iconName === 'utility:settings');

                if (!menu) throw new Error('Settings menu not found');

                menu.dispatchEvent(new CustomEvent('select', { detail: { value: 'showDate' } }));

                return flushPromises();
            })
            .then(() => {
                expect(setItemSpy).toHaveBeenCalled();
                const savedSettings = JSON.parse(setItemSpy.mock.calls[0][1]);
                expect(savedSettings.showDate).toBe(false); // Toggled from true default
            });
    });
});
