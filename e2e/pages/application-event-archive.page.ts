import { Page } from '@playwright/test';
import { BigObjectExplorerComponent } from '../components';

// Placement values of rflib_Application_Event_Archive_Explorer.flexipage-meta.xml the spec depends on.
export const ARCHIVE_FIELDS = {
    occurredOn: 'Occurred_On__c',
    eventName: 'Event_Name__c',
    relatedRecord: 'Related_Record_ID__c',
    createdBy: 'Created_By_ID__c',
    details: 'Additional_Details__c'
} as const;

/** The Application Event Archive tab: a single Big Object Explorer configured for the archive. */
export class ApplicationEventArchivePage {
    readonly explorer: BigObjectExplorerComponent;

    constructor(readonly page: Page) {
        this.explorer = new BigObjectExplorerComponent(page.locator('c-rflib-big-object-explorer').first());
    }
}
