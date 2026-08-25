import { chromium } from '@playwright/test';
import { runApex, saveOrgInfo, savePipelineMarker, sfJson, soql, STORAGE_STATE_PATH } from './helpers/sf';

// Context of the log event published to verify the subscriber pipeline. Deliberately distinct from the
// 'TestContext' that CreateLogEvent.apex and SeedLogArchive.apex share, so 09-log-event-pipeline.spec.ts
// cannot mistake a directly seeded row for one that traveled the pipeline.
const PIPELINE_CONTEXT = 'E2ELogPipeline';

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
    // Seed the Big Object archive directly so archive-dependent specs (Management Console alert,
    // Log Monitor Archive mode) have deterministic, recent rows instead of racing the async
    // platform-event archival pipeline, which can lag minutes in a fresh scratch org.
    runApex('scripts/apex/SeedLogArchive.apex');

    // Published here rather than inside the spec because the platform event -> Flow -> Big Object hop
    // can take several minutes, which exceeds a single test's timeout. Publishing during setup lets the
    // rest of the suite absorb the lag, leaving the spec a short poll.
    const publishedAt = new Date();
    runApex('scripts/apex/CreatePipelineLogEvent.apex');
    savePipelineMarker({ context: PIPELINE_CONTEXT, publishedAt: publishedAt.toISOString() });

    console.log('Global setup complete.');
}
