import { Browser, BrowserContext, Page } from '@playwright/test';
import { OpsCenterApp } from './pages/ops-center-app.page';
import { STORAGE_STATE_PATH } from './helpers/sf';

export interface OpsCenterSession {
    context: BrowserContext;
    page: Page;
    app: OpsCenterApp;
}

// Creates a shared page for a spec file (used from beforeAll, so the App Launcher
// flow runs once per file). Contexts created in beforeAll do not inherit the
// config "use" options, so storageState and viewport are passed explicitly.
export async function createOpsCenterSession(browser: Browser, tabLabel?: string): Promise<OpsCenterSession> {
    const context = await browser.newContext({
        storageState: STORAGE_STATE_PATH,
        viewport: { width: 1600, height: 900 }
    });
    const page = await context.newPage();
    const app = new OpsCenterApp(page);
    await app.openViaAppLauncher();
    if (tabLabel) {
        await app.gotoTab(tabLabel);
    }
    return { context, page, app };
}
