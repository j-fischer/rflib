import { BrowserContext, expect, Page, test } from '@playwright/test';
import { ConfirmationDialogComponent } from '../components';
import { clickDialogButton, waitForToastsToClear } from '../components/base';
import { createOpsCenterSession } from '../fixtures';
import { pollUntil } from '../helpers/polling';
import { orgInfo } from '../helpers/sf';
import { LogMonitorPage } from '../pages/log-monitor.page';
import { ManagementConsolePage } from '../pages/management-console.page';
import { OpsCenterApp, TABS } from '../pages/ops-center-app.page';

test.describe.configure({ mode: 'serial' });

const ORG_LIMIT_CARDS = [
    'Hourly Published Platform Events',
    'Daily Streaming API Events',
    'Streaming API Concurrent Clients',
    'Daily API Requests',
    'Single Emails',
    'Mass Emails'
];

const JOB_SCHEDULERS = [
    'RFLIB Application Event Archiver',
    'RFLIB Log Archive Cleanup',
    'RFLIB Application Event Archive Cleanup'
];

let context: BrowserContext;
let page: Page;
let app: OpsCenterApp;
let console_: ManagementConsolePage;

test.beforeAll(async ({ browser }) => {
    ({ context, page, app } = await createOpsCenterSession(browser, TABS.managementConsole));
    console_ = new ManagementConsolePage(page);
});

test.afterAll(async () => {
    await context?.close();
});

test('shows the info banner with documentation links', async () => {
    await expect(console_.banner).toBeVisible({ timeout: 60_000 });
    await expect(console_.banner.getByRole('link', { name: 'RFLIB Wiki' })).toBeVisible();
    await expect(console_.banner.getByRole('link', { name: 'RFLIB SFDX Plugin' })).toBeVisible();
    await expect(console_.banner.getByRole('link', { name: 'Issue on Github' })).toBeVisible();
});

test('org limit cards show usage values and can refresh', async () => {
    for (const title of ORG_LIMIT_CARDS) {
        const card = console_.orgLimitCard(title);
        await expect(card).toBeVisible({ timeout: 60_000 });
        await expect(card).toContainText(/Using \d+ out of \d+/, { timeout: 60_000 });
    }
    const firstCard = console_.orgLimitCard(ORG_LIMIT_CARDS[0]);
    await firstCard.getByRole('button', { name: 'Refresh' }).click();
    await expect(firstCard).toContainText(/Using \d+ out of \d+/, { timeout: 60_000 });
});

test('lists users with Ops Center access and users without client logging', async () => {
    const opsCenterAccess = 'User Who Do Have Ops Center Access';
    await expect(console_.permissionAssignmentList(opsCenterAccess)).toBeVisible({ timeout: 60_000 });
    await expect(console_.permissionAssignmentTable(opsCenterAccess).row(orgInfo().adminName)).toBeVisible({
        timeout: 60_000
    });

    const noClientLogging = 'Users Who Do Not Have Client Logging Enabled';
    await expect(console_.permissionAssignmentList(noClientLogging)).toBeVisible();
    await expect(console_.permissionAssignmentTable(noClientLogging).root).toBeVisible();
});

test('Big Object statistics can count all big objects', async () => {
    test.setTimeout(420_000);
    const stat = console_.bigObjectStat;
    await expect(stat).toBeVisible({ timeout: 60_000 });
    await stat.getByRole('button', { name: 'Count All' }).click();

    // Counting runs async batch jobs; reload until the stats table shows rows.
    // The wire needs a moment to render after each reload before counting.
    await pollUntil(
        async () => {
            await page.reload({ waitUntil: 'domcontentloaded' });
            await expect(console_.bigObjectStat).toBeVisible({ timeout: 60_000 });
            await page.waitForTimeout(5_000);
            return console_.bigObjectStats.rowCount();
        },
        (count) => count > 0,
        { timeoutMs: 300_000, intervalMs: 5_000, description: 'big object statistics rows' }
    );
});

test('public group manager adds and removes a member', async () => {
    const manager = console_.publicGroupManager;
    await expect(manager).toBeVisible({ timeout: 60_000 });
    const adminName = orgInfo().adminName;
    const members = console_.publicGroupMembers;

    // Re-runnability: remove the admin first if a previous run left it behind.
    if (await members.row(adminName).isVisible()) {
        await removeGroupMember(adminName);
    }

    await console_.publicGroupUserPicker.pick(adminName);
    await manager.getByRole('button', { name: 'Add User' }).click();
    await expect(members.row(adminName)).toBeVisible({ timeout: 60_000 });
    await waitForToastsToClear(page);

    await removeGroupMember(adminName);
    await expect(members.row(adminName)).toBeHidden({ timeout: 60_000 });
});

async function removeGroupMember(memberName: string): Promise<void> {
    await console_.publicGroupMembers.rowAction(memberName, 'Remove');
    await ConfirmationDialogComponent.visibleIn(page).confirm();
    await waitForToastsToClear(page);
}

test('permission set manager assigns and removes a permission set for autoproc', async () => {
    const manager = console_.permissionSetManager;
    await expect(manager).toBeVisible({ timeout: 60_000 });
    // The datatable shows Label and Name in separate cells; the combobox shows
    // "Label (Name)". Use the RFLIB permission set intended for autoproc -
    // others (e.g. Ops Center Access) grant ApiEnabled, which the Automated
    // Process user license rejects.
    const permSetName = 'rflib_Archive_Application_Events';
    const permissionSets = console_.permissionSets;

    // Cover both delete and assign while restoring the initial assignment
    // state (the assignment may be intentional org setup).
    const initiallyAssigned = await permissionSets.row(permSetName).isVisible();
    if (initiallyAssigned) {
        // Delete is a bare button-icon on the row, which opens the confirm modal.
        await permissionSets.row(permSetName).getByRole('button', { name: 'Delete' }).first().click();
        await clickDialogButton(page, 'Delete');
        await expect(permissionSets.row(permSetName)).toBeHidden({ timeout: 60_000 });
        await waitForToastsToClear(page);
    }

    await console_.permissionSetSelector.select(permSetName);

    await manager.getByRole('button', { name: 'Assign', exact: true }).click();
    await clickDialogButton(page, 'Assign');
    const newRow = permissionSets.row(permSetName);
    await expect(newRow).toBeVisible({ timeout: 60_000 });
    await waitForToastsToClear(page);

    if (!initiallyAssigned) {
        await newRow.getByRole('button', { name: 'Delete' }).first().click();
        await clickDialogButton(page, 'Delete');
        await expect(permissionSets.row(permSetName)).toBeHidden({ timeout: 60_000 });
    }
});

test('apex job schedulers can schedule, refresh, and delete jobs', async () => {
    for (const jobName of JOB_SCHEDULERS) {
        const card = console_.jobScheduler(jobName);
        await expect(card).toBeVisible({ timeout: 60_000 });

        const isScheduled = await card.getByText('Next Run:').isVisible();
        if (isScheduled) {
            // Pre-existing schedule (e.g. created by org setup) - verify status only.
            await expect(card.getByText('Status:')).toBeVisible();
            await card.getByRole('button', { name: 'Refresh' }).click();
            await expect(card.getByText('Next Run:')).toBeVisible({ timeout: 60_000 });
            continue;
        }

        await expect(card.getByText('No job is currently scheduled')).toBeVisible();
        await console_.jobSchedulerCronInput(jobName).fill('0 0 3 * * ?');
        await card.getByRole('button', { name: 'Schedule Job' }).click();
        await expect(card.getByText('Next Run:')).toBeVisible({ timeout: 60_000 });
        await waitForToastsToClear(page);

        await card.getByRole('button', { name: 'Delete Job' }).click();
        await ConfirmationDialogComponent.visibleIn(page).confirm();
        await expect(card.getByText('No job is currently scheduled')).toBeVisible({ timeout: 60_000 });
        await waitForToastsToClear(page);
    }
});

test('log archive alert appears for recent high-severity logs and links to the Log Monitor', async () => {
    // Global setup seeds recent WARN/ERROR/FATAL rows straight into the Big Object, so the alert is
    // deterministic. The summary is @wire-fetched on component load, so reload to re-fire the wire and
    // wait for the banner each round rather than blind-sleeping; with seeded data this resolves quickly.
    await pollUntil(
        async () => {
            await page.reload({ waitUntil: 'domcontentloaded' });
            await expect(console_.banner).toBeVisible({ timeout: 60_000 });
            return console_.archiveAlert.banner
                .waitFor({ state: 'visible', timeout: 10_000 })
                .then(() => true)
                .catch(() => false);
        },
        (visible) => visible,
        { timeoutMs: 120_000, intervalMs: 2_000, description: 'log archive alert banner' }
    );

    await console_.archiveAlert.investigateLink.click();
    await expect(new LogMonitorPage(page).root).toBeVisible({ timeout: 60_000 });
    await app.gotoTab(TABS.managementConsole);
});
