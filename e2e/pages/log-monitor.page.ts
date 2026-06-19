import { expect, Locator, Page } from '@playwright/test';
import { fillDateTime, formatDateUs, selectMenuItem } from '../helpers/lightning';

export const CONNECTION_MODES = {
    historicAndNew: 'Historic and New Messages',
    newMessagesOnly: 'New Messages',
    disconnected: 'Not Connected',
    archive: 'Archive'
} as const;

export class LogMonitorPage {
    constructor(readonly page: Page) {}

    get root(): Locator {
        return this.page.locator('c-rflib-log-event-monitor').first();
    }

    get header(): Locator {
        return this.root.locator('.slds-page-header').first();
    }

    get totalLogEventsText(): Locator {
        return this.header.locator('p').filter({ hasText: 'Total Log Events' });
    }

    get connectionStatusText(): Locator {
        return this.header.locator('p').filter({ hasText: 'Connection Status' });
    }

    get connectionModeMenu(): Locator {
        // The connection mode menu is the lightning-button-menu with the mode label.
        return this.header
            .locator('lightning-button-menu')
            .filter({
                hasText: /Historic and New Messages|New Messages|Not Connected|Archive/
            })
            .first();
    }

    // The status label only updates once the EMP (un)subscribe round trip
    // completes; that can stall, so retry the menu selection a few times.
    async setConnectionMode(modeLabel: string): Promise<void> {
        for (let attempt = 1; ; attempt++) {
            await selectMenuItem(this.connectionModeMenu, modeLabel);
            try {
                await expect(this.connectionStatusText).toContainText(modeLabel, { timeout: 20_000 });
                return;
            } catch (error) {
                if (attempt >= 3) {
                    throw error;
                }
                await this.page.keyboard.press('Escape'); // close a possibly stuck menu
            }
        }
    }

    // EMP/CometD can stall its first subscribe in a fresh scratch org, leaving the connection status
    // stuck on "Not Connected". A full page reload re-establishes the subscription far more reliably
    // than re-selecting the menu, so reload and retry the whole mode switch before giving up.
    async connectInMode(modeLabel: string, attempts = 4): Promise<void> {
        for (let attempt = 1; ; attempt++) {
            try {
                await this.setConnectionMode(modeLabel);
                return;
            } catch (error) {
                if (attempt >= attempts) {
                    throw error;
                }
                await this.page.reload({ waitUntil: 'domcontentloaded' });
                await expect(this.root).toBeVisible({ timeout: 60_000 });
            }
        }
    }

    // Waits for the monitor to report the given connection mode without changing it, reloading to
    // re-establish a stalled EMP subscription. Use for the default ("New Messages") connection.
    async waitForConnectionMode(modeLabel: string, attempts = 4): Promise<void> {
        for (let attempt = 1; ; attempt++) {
            try {
                await expect(this.connectionStatusText).toContainText(modeLabel, { timeout: 30_000 });
                return;
            } catch (error) {
                if (attempt >= attempts) {
                    throw error;
                }
                await this.page.reload({ waitUntil: 'domcontentloaded' });
                await expect(this.root).toBeVisible({ timeout: 60_000 });
            }
        }
    }

    async getTotalLogEvents(): Promise<number> {
        const text = (await this.totalLogEventsText.textContent()) ?? '0';
        return parseInt(text.trim().split(' ')[0], 10);
    }

    get eventList(): Locator {
        return this.root.locator('c-rflib-log-event-list');
    }

    eventRows(): Locator {
        return this.eventList.locator('c-rflib-log-event-list-row');
    }

    searchField(placeholder: string): Locator {
        return this.eventList.getByPlaceholder(placeholder);
    }

    get searchButton(): Locator {
        return this.eventList.getByRole('button', { name: 'Search' });
    }

    get viewer(): Locator {
        return this.root.locator('c-rflib-log-event-viewer');
    }

    get exportButton(): Locator {
        return this.header.getByRole('button', { name: 'Export to CSV' });
    }

    get clearLogsButton(): Locator {
        return this.header.getByRole('button', { name: 'Clear Logs' });
    }

    get queryArchiveButton(): Locator {
        return this.header.getByRole('button', { name: 'Query Archive' });
    }

    // The archive header renders start date, end date inputs in order.
    archiveDateInput(index: 0 | 1): Locator {
        return this.header.locator('li:has(lightning-input) lightning-input').nth(index);
    }

    async setArchiveDateRange(start: Date, end: Date): Promise<void> {
        await fillDateTime(this.archiveDateInput(0), formatDateUs(start), '12:00 AM');
        await fillDateTime(this.archiveDateInput(1), formatDateUs(end), '11:59 PM');
    }

    // Settings menu in archive mode (contains "Clear Archive"). It precedes the
    // connection mode menu in the actions button group.
    get archiveSettingsMenu(): Locator {
        return this.header.locator('.slds-page-header__col-actions lightning-button-menu').first();
    }

    // Field visibility menu lives in the second header row's controls area.
    get fieldVisibilityMenu(): Locator {
        return this.header.locator('.slds-page-header__col-controls lightning-button-menu').first();
    }

    get fullscreenToggle(): Locator {
        return this.header.locator('.slds-page-header__col-controls lightning-button-icon').first();
    }
}
