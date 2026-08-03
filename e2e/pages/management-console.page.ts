import { Locator, Page } from '@playwright/test';
import { LogArchiveAlertComponent } from '../components';
import { LightningCombobox, LightningDatatable, LightningRecordPicker } from '../components/base';

export class ManagementConsolePage {
    constructor(readonly page: Page) {}

    get banner(): Locator {
        return this.page
            .locator('.slds-rich-text-editor__output, flexipage-component2')
            .filter({ hasText: 'RFLIB Wiki' })
            .first();
    }

    get archiveAlert(): LogArchiveAlertComponent {
        return LogArchiveAlertComponent.on(this.page);
    }

    permissionAssignmentList(title: string): Locator {
        return this.page.locator('c-rflib-user-permission-assignment-list').filter({ hasText: title }).first();
    }

    permissionAssignmentTable(title: string): LightningDatatable {
        return LightningDatatable.within(this.permissionAssignmentList(title));
    }

    get publicGroupManager(): Locator {
        return this.page.locator('c-rflib-public-group-member-manager').first();
    }

    get publicGroupMembers(): LightningDatatable {
        return LightningDatatable.within(this.publicGroupManager);
    }

    get publicGroupUserPicker(): LightningRecordPicker {
        return LightningRecordPicker.within(this.publicGroupManager);
    }

    get permissionSetManager(): Locator {
        return this.page.locator('c-rflib-user-permission-set-manager').first();
    }

    get permissionSets(): LightningDatatable {
        return LightningDatatable.within(this.permissionSetManager);
    }

    get permissionSetSelector(): LightningCombobox {
        return LightningCombobox.within(this.permissionSetManager);
    }

    orgLimitCard(title: string): Locator {
        return this.page.locator('c-rflib-org-limit-stat').filter({ hasText: title }).first();
    }

    get bigObjectStat(): Locator {
        return this.page.locator('c-rflib-big-object-stat').first();
    }

    get bigObjectStats(): LightningDatatable {
        return LightningDatatable.within(this.bigObjectStat);
    }

    // Job scheduler cards are titled "Job Status for: <jobName>".
    jobScheduler(jobName: string): Locator {
        return this.page
            .locator('c-rflib-apex-job-scheduler')
            .filter({ hasText: `Job Status for: ${jobName}` })
            .first();
    }

    // The card renders a single lightning-input, holding the CRON expression.
    jobSchedulerCronInput(jobName: string): Locator {
        return this.jobScheduler(jobName).locator('lightning-input input');
    }
}
