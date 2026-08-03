import { Locator } from '@playwright/test';
import { LightningButtonMenu } from './base';

export const VIEWER_TABS = {
    logEvent: 'Log Event',
    platformInfo: 'Platform Info',
    stacktrace: 'Stacktrace'
} as const;

/** Wraps `c-rflib-log-event-viewer`. */
export class LogEventViewerComponent {
    constructor(readonly root: Locator) {}

    static within(scope: Locator): LogEventViewerComponent {
        return new LogEventViewerComponent(scope.locator('c-rflib-log-event-viewer'));
    }

    tab(label: string): Locator {
        return this.root.getByRole('tab', { name: label });
    }

    async openTab(label: string): Promise<void> {
        await this.tab(label).click();
    }

    get platformInfoTable(): Locator {
        return this.root.locator('table[aria-label="Platform Info"]');
    }

    // The stacktrace pane carries an authored class in rflibLogEventViewer.html.
    get stacktrace(): Locator {
        return this.root.locator('.stacktrace pre');
    }

    // Two button menus render inside the viewer: this download menu in the card
    // actions, and the tabset's own overflow menu. alternative-text="Download" names
    // this one; the tabset menu is labelled "More".
    get downloadMenu(): LightningButtonMenu {
        return new LightningButtonMenu(this.root.locator('lightning-button-menu').filter({ hasText: 'Download' }));
    }
}
