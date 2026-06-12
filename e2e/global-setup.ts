import { chromium } from '@playwright/test';
import { runApex, saveOrgInfo, sfJson, soql, STORAGE_STATE_PATH } from './helpers/sf';

export default async function globalSetup(): Promise<void> {
    console.log('Resolving default org via sf CLI...');
    const display = sfJson(['org', 'display']);
    if (display.status !== 0) {
        throw new Error(
            `No default org found. Set one with "sf config set target-org <alias>". ${JSON.stringify(display)}`
        );
    }
    const username: string = display.result.username;
    const instanceUrl: string = display.result.instanceUrl.replace(/\/$/, '');
    const users = soql(`SELECT Name FROM User WHERE Username = '${username}'`);
    saveOrgInfo({ username, instanceUrl, adminName: users[0].Name });
    console.log(`Using org ${username} at ${instanceUrl}`);

    console.log('Establishing browser session via frontdoor URL...');
    const open = sfJson(['org', 'open', '--url-only']);
    const browser = await chromium.launch();
    try {
        const page = await browser.newPage();
        await page.goto(open.result.url, { waitUntil: 'domcontentloaded' });
        await page.waitForURL(/\/lightning\//, { timeout: 90_000 });
        await page
            .locator('one-appnav, header.slds-global-header_container')
            .first()
            .waitFor({ state: 'visible', timeout: 90_000 });
        await page.context().storageState({ path: STORAGE_STATE_PATH });
    } finally {
        await browser.close();
    }

    console.log('Seeding test data (settings must be configured before log events publish)...');
    runApex('scripts/apex/ConfigureCustomSettings.apex');
    runApex('scripts/apex/CreateLogEvent.apex');
    runApex('scripts/apex/CreateApplicationEvent.apex');
    console.log('Global setup complete.');
}
