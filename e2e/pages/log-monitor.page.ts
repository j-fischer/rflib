import { expect, Locator, Page } from '@playwright/test';
import { LogEventListComponent, LogEventViewerComponent, PaginatorComponent } from '../components';
import { LightningButtonMenu, LightningDateTimeInput, formatDateUs } from '../components/base';
import { runApex } from '../helpers/sf';

export const CONNECTION_MODES = {
    historicAndNew: 'Historic and New Messages',
    newMessagesOnly: 'New Messages',
    disconnected: 'Not Connected',
    archive: 'Archive'
} as const;

const CONNECTION_MODE_LABELS = /Historic and New Messages|New Messages|Not Connected|Archive/;

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

    // The connection mode menu is the only header menu labelled with a mode.
    get connectionModeMenu(): LightningButtonMenu {
        return new LightningButtonMenu(
            this.header.locator('lightning-button-menu').filter({ hasText: CONNECTION_MODE_LABELS }).first()
        );
    }

    // The archive settings menu ("Clear Archive") is the icon-only menu that shares
    // an action group with the Query Archive button.
    get archiveSettingsMenu(): LightningButtonMenu {
        return new LightningButtonMenu(
            this.header.locator('.action-group').filter({ hasText: 'Query Archive' }).locator('lightning-button-menu')
        );
    }

    // alternative-text="Log visibility settings" is the icon-only menu's accessible
    // name; fall back to the header controls column if a release stops rendering it.
    get fieldVisibilityMenu(): LightningButtonMenu {
        return new LightningButtonMenu(
            this.header
                .getByRole('button', { name: 'Log visibility settings' })
                .or(this.header.locator('.slds-page-header__col-controls lightning-button-menu'))
                .first()
        );
    }

    // The only button-icon in the second header row.
    get fullscreenToggle(): Locator {
        return this.header.locator('.slds-page-header__col-controls lightning-button-icon').first();
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

    get eventList(): LogEventListComponent {
        return LogEventListComponent.within(this.root);
    }

    // Convenience for the many assertions that count or filter rows.
    eventRows(): Locator {
        return this.eventList.rows;
    }

    get viewer(): LogEventViewerComponent {
        return LogEventViewerComponent.within(this.root);
    }

    get paginator(): PaginatorComponent {
        return PaginatorComponent.within(this.root);
    }

    // Placeholders are authored in rflibLogEventMonitor.html; "Enter a end date" is
    // the literal template text. Both branches resolve to the same element, so the
    // positional fallback only takes over if the placeholders stop rendering.
    private archiveDateInput(placeholder: string, index: 0 | 1): LightningDateTimeInput {
        const inputs = this.header.locator('.archive-filter lightning-input');
        return new LightningDateTimeInput(
            inputs
                .filter({ has: this.page.getByPlaceholder(placeholder) })
                .or(inputs.nth(index))
                .first()
        );
    }

    async setArchiveDateRange(start: Date, end: Date): Promise<void> {
        await this.archiveDateInput('Enter a start date', 0).fill(formatDateUs(start), '12:00 AM');
        await this.archiveDateInput('Enter a end date', 1).fill(formatDateUs(end), '11:59 PM');
    }

    // The status label only updates once the EMP (un)subscribe round trip
    // completes; that can stall, so retry the menu selection a few times.
    async setConnectionMode(modeLabel: string): Promise<void> {
        for (let attempt = 1; ; attempt++) {
            await this.connectionModeMenu.select(modeLabel);
            try {
                await expect(this.connectionStatusText).toContainText(modeLabel, { timeout: 20_000 });
                return;
            } catch (error) {
                if (attempt >= 3) {
                    throw error;
                }
                await this.connectionModeMenu.close(); // close a possibly stuck menu
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

    // Connects in "Historic and New Messages" and guarantees at least `min` events are captured.
    // Durable EMP replay (-2) is unreliable in a scratch org, so rather than depend on it we publish
    // fresh events that arrive over the "New" half of the subscription, with one republish as a
    // safety net against a single missed delivery.
    async connectHistoricAndAwaitEvents(min = 1): Promise<void> {
        await this.connectInMode(CONNECTION_MODES.historicAndNew);
        await this.page.waitForTimeout(3_000); // let the CometD handshake finish before publishing
        runApex('scripts/apex/CreateLogEvent.apex');

        const deadline = Date.now() + 90_000;
        let republished = false;
        for (;;) {
            if ((await this.getTotalLogEvents()) >= min) {
                return;
            }
            if (Date.now() > deadline) {
                throw new Error(`Historic mode did not capture ${min} event(s) within 90s.`);
            }
            if (!republished && Date.now() > deadline - 45_000) {
                runApex('scripts/apex/CreateLogEvent.apex');
                republished = true;
            }
            await this.page.waitForTimeout(5_000);
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
}
