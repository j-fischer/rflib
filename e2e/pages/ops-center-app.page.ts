import { expect, Locator, Page } from '@playwright/test';
import { orgInfo } from '../helpers/sf';

export const APP_NAME = 'RFLIB Ops Center';

export const TABS = {
    managementConsole: 'Management Console',
    loggerSettings: 'Logger Settings',
    logMonitor: 'Log Monitor',
    permissionsExplorer: 'Permissions Explorer',
    appEventsDashboard: 'Application Events Dashboard',
    applicationEvents: 'Application Events'
} as const;

// Root custom elements the Ops Center tabs mount. The navigation smoke test asserts
// on these tags directly - that a tab mounts its component at all is the assertion.
// Add an entry here when a new tab is introduced.
export const ROOT_COMPONENT_TAGS = {
    orgLimitStat: 'c-rflib-org-limit-stat',
    bigObjectStat: 'c-rflib-big-object-stat',
    customSettingsEditor: 'c-rflib-custom-settings-editor',
    logEventMonitor: 'c-rflib-log-event-monitor',
    permissionsExplorer: 'c-rflib-permissions-explorer'
} as const;

export type RootComponentTag = (typeof ROOT_COMPONENT_TAGS)[keyof typeof ROOT_COMPONENT_TAGS];

export class OpsCenterApp {
    constructor(readonly page: Page) {}

    // Opens the app through the App Launcher search. The app may not be on the
    // shortlist, so always search instead of clicking a shortlisted item.
    async openViaAppLauncher(): Promise<void> {
        await this.page.goto(`${orgInfo().instanceUrl}/lightning/page/home`, { waitUntil: 'domcontentloaded' });
        const waffle = this.page
            .getByRole('button', { name: 'App Launcher' })
            .or(this.page.locator('button div.slds-icon-waffle'))
            .first();
        await waffle.click();
        const search = this.page.getByPlaceholder('Search apps and items...').first();
        await search.waitFor({ state: 'visible' });
        await search.fill('Ops Center');
        const appLink = this.page
            .locator(`one-app-launcher-menu-item a[data-label="${APP_NAME}"], a[data-label="${APP_NAME}"]`)
            .or(this.page.getByRole('option', { name: APP_NAME }))
            .first();
        await appLink.click();
        await this.expectAppHeader();
    }

    async expectAppHeader(): Promise<void> {
        const appName = this.page
            .locator('.slds-context-bar__label-action span.slds-truncate, .appName span')
            .filter({ hasText: APP_NAME })
            .first();
        await expect(appName).toBeVisible({ timeout: 60_000 });
    }

    async gotoTab(label: string): Promise<void> {
        const navLink = this.page
            .locator(`one-appnav a[title="${label}"]`)
            .or(this.page.getByRole('navigation').getByRole('link', { name: label, exact: true }))
            .first();
        await navLink.click();
        await this.page.waitForLoadState('domcontentloaded');
    }

    tabLink(label: string): Locator {
        return this.page
            .locator(`one-appnav a[title="${label}"]`)
            .or(this.page.getByRole('navigation').getByRole('link', { name: label, exact: true }))
            .first();
    }

    rootComponent(tag: RootComponentTag): Locator {
        return this.page.locator(tag);
    }
}
