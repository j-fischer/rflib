import { Locator, Page } from '@playwright/test';

export class ManagementConsolePage {
    constructor(readonly page: Page) {}

    get banner(): Locator {
        return this.page
            .locator('.slds-rich-text-editor__output, flexipage-component2')
            .filter({ hasText: 'RFLIB Wiki' })
            .first();
    }

    get archiveAlert(): Locator {
        return this.page.locator('c-rflib-log-archive-alert div[role="alert"]');
    }

    get archiveAlertLink(): Locator {
        return this.archiveAlert.getByRole('link', { name: 'Investigate in the Log Monitor' });
    }

    permissionAssignmentList(title: string): Locator {
        return this.page.locator('c-rflib-user-permission-assignment-list').filter({ hasText: title }).first();
    }

    get publicGroupManager(): Locator {
        return this.page.locator('c-rflib-public-group-member-manager').first();
    }

    get permissionSetManager(): Locator {
        return this.page.locator('c-rflib-user-permission-set-manager').first();
    }

    orgLimitCard(title: string): Locator {
        return this.page.locator('c-rflib-org-limit-stat').filter({ hasText: title }).first();
    }

    get bigObjectStat(): Locator {
        return this.page.locator('c-rflib-big-object-stat').first();
    }

    // Job scheduler cards are titled "Job Status for: <jobName>".
    jobScheduler(jobName: string): Locator {
        return this.page
            .locator('c-rflib-apex-job-scheduler')
            .filter({ hasText: `Job Status for: ${jobName}` })
            .first();
    }
}
