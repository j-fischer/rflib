import { BrowserContext, expect, Page, test } from '@playwright/test';
import { createOpsCenterSession } from '../fixtures';
import { clickDialogButton, datatableRow, pickRecord, waitForToastsToClear } from '../helpers/lightning';
import { pollUntil } from '../helpers/polling';
import { orgInfo } from '../helpers/sf';
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
    const opsCenterList = console_.permissionAssignmentList('User Who Do Have Ops Center Access');
    await expect(opsCenterList).toBeVisible({ timeout: 60_000 });
    await expect(datatableRow(opsCenterList, orgInfo().adminName)).toBeVisible({ timeout: 60_000 });

    const noLoggingList = console_.permissionAssignmentList('Users Who Do Not Have Client Logging Enabled');
    await expect(noLoggingList).toBeVisible();
    await expect(noLoggingList.locator('lightning-datatable')).toBeVisible();
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
            return console_.bigObjectStat.locator('lightning-datatable tbody tr').count();
        },
        (count) => count > 0,
        { timeoutMs: 300_000, intervalMs: 5_000, description: 'big object statistics rows' }
    );
});

test('public group manager adds and removes a member', async () => {
    const manager = console_.publicGroupManager;
    await expect(manager).toBeVisible({ timeout: 60_000 });
    const adminName = orgInfo().adminName;

    // Re-runnability: remove the admin first if a previous run left it behind.
    const existingRow = datatableRow(manager, adminName);
    if (await existingRow.isVisible()) {
        await removeGroupMember(existingRow);
    }

    await pickRecord(manager.locator('lightning-record-picker'), adminName);
    await manager.getByRole('button', { name: 'Add User' }).click();
    await expect(datatableRow(manager, adminName)).toBeVisible({ timeout: 60_000 });
    await waitForToastsToClear(page);

    await removeGroupMember(datatableRow(manager, adminName));
    await expect(datatableRow(manager, adminName)).toBeHidden({ timeout: 60_000 });
});

async function removeGroupMember(row: ReturnType<typeof datatableRow>): Promise<void> {
    const menuButton = row
        .getByRole('button', { name: /show actions/i })
        .or(row.locator('lightning-primitive-cell-actions button'))
        .first();
    await menuButton.click();
    await page.getByRole('menuitem', { name: 'Remove' }).first().click();
    await clickDialogButton(page, 'Remove');
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

    // Cover both delete and assign while restoring the initial assignment
    // state (the assignment may be intentional org setup).
    const initiallyAssigned = await datatableRow(manager, permSetName).isVisible();
    if (initiallyAssigned) {
        // Delete is a bare button-icon on the row, which opens the confirm modal.
        await datatableRow(manager, permSetName).getByRole('button', { name: 'Delete' }).first().click();
        await clickDialogButton(page, 'Delete');
        await expect(datatableRow(manager, permSetName)).toBeHidden({ timeout: 60_000 });
        await waitForToastsToClear(page);
    }

    const combobox = manager.locator('lightning-combobox');
    await combobox.locator('button, input').first().click();
    await combobox.getByRole('option', { name: permSetName }).first().click();

    await manager.getByRole('button', { name: 'Assign', exact: true }).click();
    await clickDialogButton(page, 'Assign');
    const newRow = datatableRow(manager, permSetName);
    await expect(newRow).toBeVisible({ timeout: 60_000 });
    await waitForToastsToClear(page);

    if (!initiallyAssigned) {
        await newRow.getByRole('button', { name: 'Delete' }).first().click();
        await clickDialogButton(page, 'Delete');
        await expect(datatableRow(manager, permSetName)).toBeHidden({ timeout: 60_000 });
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
        await card.locator('lightning-input input').fill('0 0 3 * * ?');
        await card.getByRole('button', { name: 'Schedule Job' }).click();
        await expect(card.getByText('Next Run:')).toBeVisible({ timeout: 60_000 });
        await waitForToastsToClear(page);

        await card.getByRole('button', { name: 'Delete Job' }).click();
        await clickDialogButton(page, 'Delete');
        await expect(card.getByText('No job is currently scheduled')).toBeVisible({ timeout: 60_000 });
        await waitForToastsToClear(page);
    }
});

test('log archive alert appears for recent high-severity logs and links to the Log Monitor', async () => {
    test.setTimeout(420_000);
    // Archive rows are written asynchronously after global setup published the
    // seeded WARN/ERROR/FATAL events; reload until the alert renders.
    await pollUntil(
        async () => {
            await page.reload({ waitUntil: 'domcontentloaded' });
            await expect(console_.banner).toBeVisible({ timeout: 60_000 });
            await page.waitForTimeout(5_000);
            return console_.archiveAlert.isVisible();
        },
        (visible) => visible,
        { timeoutMs: 300_000, intervalMs: 5_000, description: 'log archive alert banner' }
    );

    await console_.archiveAlertLink.click();
    await expect(page.locator('c-rflib-log-event-monitor')).toBeVisible({ timeout: 60_000 });
    await app.gotoTab(TABS.managementConsole);
});
