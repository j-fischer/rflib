import { defineConfig } from '@playwright/test';
import * as fs from 'node:fs';
import * as path from 'node:path';

// The instance URL is only known after global setup resolves the default org.
// baseURL is a convenience; all navigation builds absolute URLs from orgInfo().
const ORG_INFO_PATH = path.join(__dirname, 'e2e', '.auth', 'org.json');
const baseURL = fs.existsSync(ORG_INFO_PATH)
    ? JSON.parse(fs.readFileSync(ORG_INFO_PATH, 'utf8')).instanceUrl
    : undefined;

export default defineConfig({
    testDir: './e2e/specs',
    globalSetup: './e2e/global-setup.ts',
    // Specs share one scratch org and EMP subscriptions; spec 05 destroys data
    // that 02/04 depend on, so ordering (numeric prefixes) must be preserved.
    fullyParallel: false,
    workers: 1,
    retries: 1,
    timeout: 180_000,
    expect: { timeout: 30_000 },
    reporter: [['list'], ['html', { open: 'never' }]],
    use: {
        baseURL,
        storageState: path.join(__dirname, 'e2e', '.auth', 'storageState.json'),
        viewport: { width: 1600, height: 900 },
        actionTimeout: 30_000,
        navigationTimeout: 60_000,
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
        video: 'retain-on-failure'
    },
    projects: [{ name: 'chromium', use: { browserName: 'chromium' } }]
});
