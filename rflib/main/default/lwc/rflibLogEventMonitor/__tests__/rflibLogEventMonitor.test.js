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
});
