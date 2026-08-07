#!/usr/bin/env node
/**
 * Documentation screenshot capture for the RFLIB Ops Center.
 *
 * Drives a real scratch org with Playwright and writes PNGs into screenshots/ that
 * match the convention the wiki already uses: the Ops Center app chrome (global
 * header + nav bar) on top, the feature underneath, viewport-sized.
 *
 * It reuses the E2E suite's storage state (e2e/.auth/), so authentication is
 * whatever "node e2e/tools/inspect.mjs auth" last wrote. This tool never logs in.
 *
 * Usage:
 *   node e2e/tools/capture.mjs tab "Permissions Explorer" --out screenshots/X.png
 *   node e2e/tools/capture.mjs url "lightning/n/rflib_Log_Monitor" --out screenshots/X.png
 *   node e2e/tools/capture.mjs recipe e2e/tools/recipes/X.mjs
 *
 * Flags (tab | url):
 *   --out <png>      Destination. Default: screenshots/capture.png
 *   --recipe <file>  ESM module driving the UI into the state worth shooting (see below).
 *   --scope <css>    Clip the shot to this element instead of the viewport.
 *   --settle <ms>    Wait after load before shooting (default 6000).
 *   --size <WxH>     Viewport (default 1440x900).
 *   --full           Full-page shot instead of viewport.
 *   --headed         Show the browser.
 *
 * A recipe is an ESM module whose default export receives the live page:
 *
 *   export const target = { tab: 'Permissions Explorer' };   // or { url: 'lightning/n/x' }
 *   export default async function ({ page, root, shoot, settle }) {
 *       await root.getByRole('button', { name: 'Object Permission For Profiles' }).click();
 *       await settle(2000);
 *       await shoot('screenshots/Permission_Explorer_Menu.png');
 *   }
 *
 * `root` is the largest visible c-rflib-* component (Playwright locators pierce the
 * shadow roots that RFLIB components live in; raw DOM APIs do not). If the recipe
 * never calls shoot(), one shot is taken at the end into --out.
 */
import { chromium } from '@playwright/test';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const E2E_DIR = path.join(HERE, '..');
const REPO_ROOT = path.join(E2E_DIR, '..');
const AUTH_DIR = path.join(E2E_DIR, '.auth');
const ORG_INFO_PATH = path.join(AUTH_DIR, 'org.json');
const STORAGE_STATE_PATH = path.join(AUTH_DIR, 'storageState.json');

const APP_NAME = 'RFLIB Ops Center';
const AUTH_HINT = 'Run: node e2e/tools/inspect.mjs auth';

function orgInfo() {
    if (!fs.existsSync(ORG_INFO_PATH) || !fs.existsSync(STORAGE_STATE_PATH)) {
        throw new Error(`Missing e2e/.auth session files. ${AUTH_HINT}`);
    }
    return JSON.parse(fs.readFileSync(ORG_INFO_PATH, 'utf8'));
}

// ---------------------------------------------------------------- navigation

async function openViaAppLauncher(page, info) {
    await page.goto(`${info.instanceUrl}/lightning/page/home`, { waitUntil: 'domcontentloaded' });
    await page
        .getByRole('button', { name: 'App Launcher' })
        .or(page.locator('button div.slds-icon-waffle'))
        .first()
        .click();
    const search = page.getByPlaceholder('Search apps and items...').first();
    await search.waitFor({ state: 'visible', timeout: 60_000 });
    await search.fill('Ops Center');
    await page
        .locator(`one-app-launcher-menu-item a[data-label="${APP_NAME}"], a[data-label="${APP_NAME}"]`)
        .or(page.getByRole('option', { name: APP_NAME }))
        .first()
        .click();
    await page
        .locator('.slds-context-bar__label-action span.slds-truncate, .appName span')
        .filter({ hasText: APP_NAME })
        .first()
        .waitFor({ state: 'visible', timeout: 60_000 });
}

async function gotoTab(page, label) {
    await page
        .locator(`one-appnav a[title="${label}"]`)
        .or(page.getByRole('navigation').getByRole('link', { name: label, exact: true }))
        .first()
        .click();
    await page.waitForLoadState('domcontentloaded');
}

/** Largest visible c-rflib-* element - the tab's root component. */
async function detectRoot(page) {
    return page.evaluate(() => {
        const found = [];
        (function walk(node) {
            if (node.tagName && node.tagName.toLowerCase().startsWith('c-rflib-')) {
                const r = node.getBoundingClientRect();
                if (r.height > 0) found.push({ tag: node.tagName.toLowerCase(), area: r.width * r.height });
            }
            if (node.shadowRoot) for (const c of node.shadowRoot.children) walk(c);
            for (const c of node.children) walk(c);
        })(document.body);
        found.sort((a, b) => b.area - a.area);
        return found.length > 0 ? found[0].tag : null;
    });
}

// ---------------------------------------------------------------- capture

async function settleFor(page, ms) {
    // Lightning renders progressively and RFLIB components fetch on connect; there
    // is no single observable "done" signal, hence a settle wait plus a spinner check.
    await page.waitForTimeout(ms);
    await page
        .locator('lightning-spinner')
        .first()
        .waitFor({ state: 'hidden', timeout: 180_000 })
        .catch(() => {});
}

// Scratch-org-only chrome that no published screenshot should show: the LWC debug
// mode banner, the DevOps Center org bar, and the EPT/ART/storage perf badges debug
// mode adds to the global header. Hidden with CSS rather than by changing org
// settings, so a capture run leaves the org exactly as it found it.
const NOISE_CSS = `
    .oneSystemMessage,
    .slds-notify_alert.system-message,
    devops_center-base-component,
    .perf-tools { display: none !important; }
`;

function shooter(page, opts) {
    const taken = [];
    return {
        taken,
        async shoot(out, shotOpts = {}) {
            const dest = path.isAbsolute(out) ? out : path.join(REPO_ROOT, out);
            fs.mkdirSync(path.dirname(dest), { recursive: true });
            // Re-injected per shot: a recipe may have navigated since the last one.
            await page.addStyleTag({ content: NOISE_CSS }).catch(() => {});
            // The cursor sits wherever the last click left it, and SLDS tooltips
            // follow it - park it out of the way unless the shot wants the hover.
            if (!shotOpts.keepHover) {
                await page.mouse.move(0, 0);
                await page.waitForTimeout(500);
            }
            const scope = shotOpts.scope ?? opts.scope;
            if (scope) {
                const locator = typeof scope === 'string' ? page.locator(scope).first() : scope;
                if ((await locator.count()) === 0) {
                    throw new Error(`Scope "${scope}" matched nothing on the page.`);
                }
                await locator.screenshot({ path: dest });
            } else {
                await page.screenshot({ path: dest, fullPage: shotOpts.full ?? opts.full ?? false });
            }
            const b = fs.readFileSync(dest);
            const dims = `${b.readUInt32BE(16)}x${b.readUInt32BE(20)}`;
            console.log(`Screenshot: ${path.relative(REPO_ROOT, dest)}  ${dims}  ${Math.round(b.length / 1024)}KB`);
            taken.push(dest);
        }
    };
}

// ---------------------------------------------------------------- main

function parseArgs(argv) {
    const opts = { settle: 6000, size: '1440x900' };
    const rest = [];
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (a === '--out') opts.out = argv[++i];
        else if (a === '--recipe') opts.recipe = argv[++i];
        else if (a === '--scope') opts.scope = argv[++i];
        else if (a === '--settle') opts.settle = Number(argv[++i]);
        else if (a === '--size') opts.size = argv[++i];
        else if (a === '--full') opts.full = true;
        else if (a === '--headed') opts.headed = true;
        else rest.push(a);
    }
    const [width, height] = opts.size.split('x').map(Number);
    opts.viewport = { width, height };
    return { opts, rest };
}

async function main() {
    const [command, ...argv] = process.argv.slice(2);
    if (!command || command === 'help' || command === '--help') {
        console.log(fs.readFileSync(fileURLToPath(import.meta.url), 'utf8').split('*/')[0]);
        return;
    }
    if (!['tab', 'url', 'recipe'].includes(command)) {
        throw new Error(`Unknown command "${command}". Expected: tab | url | recipe`);
    }

    const { opts, rest } = parseArgs(argv);
    let target = rest[0];
    let recipeFn = null;

    if (command === 'recipe') {
        opts.recipe = target;
    }
    if (opts.recipe) {
        const recipePath = path.isAbsolute(opts.recipe) ? opts.recipe : path.join(REPO_ROOT, opts.recipe);
        if (!fs.existsSync(recipePath)) {
            throw new Error(`Recipe not found: ${recipePath}`);
        }
        const mod = await import(pathToFileURL(recipePath).href);
        recipeFn = mod.default;
        if (typeof recipeFn !== 'function') {
            throw new Error(`Recipe ${opts.recipe} must default-export an async function.`);
        }
        if (command === 'recipe') {
            const t = mod.target ?? {};
            if (!t.tab && !t.url) {
                throw new Error(`Recipe ${opts.recipe} must export "target" with { tab } or { url }.`);
            }
            target = t.tab ?? t.url;
            opts.mode = t.tab ? 'tab' : 'url';
            if (t.scope) opts.scope = t.scope;
            if (t.settle) opts.settle = t.settle;
        }
    }
    opts.mode = opts.mode ?? command;
    if (!target) {
        throw new Error(opts.mode === 'tab' ? 'Missing tab label.' : 'Missing URL path.');
    }

    const info = orgInfo();
    const browser = await chromium.launch({ headless: !opts.headed });
    const context = await browser.newContext({ storageState: STORAGE_STATE_PATH, viewport: opts.viewport });
    const page = await context.newPage();
    try {
        if (opts.mode === 'tab') {
            await openViaAppLauncher(page, info);
            await gotoTab(page, target);
        } else {
            // Git Bash rewrites a leading "/" argument into a Windows path, so the
            // documented form omits it; normalize either way.
            await page.goto(`${info.instanceUrl}${target.startsWith('/') ? target : `/${target}`}`, {
                waitUntil: 'domcontentloaded'
            });
        }
        await settleFor(page, opts.settle);

        const rootTag = await detectRoot(page);
        const root = rootTag ? page.locator(rootTag).first() : page.locator('body');
        console.log(`Root component: ${rootTag ?? '(none - using body)'}`);

        const { shoot, taken } = shooter(page, opts);
        if (recipeFn) {
            await recipeFn({
                page,
                root,
                shoot,
                settle: (ms = opts.settle) => settleFor(page, ms),
                out: opts.out
            });
        }
        if (taken.length === 0) {
            await shoot(opts.out ?? 'screenshots/capture.png');
        }
    } catch (err) {
        // A failed run is nearly always "the UI was not in the state I assumed", so
        // leave evidence behind rather than only a stack trace.
        await page.screenshot({ path: path.join(AUTH_DIR, 'capture-failure.png') }).catch(() => {});
        console.error(`Failure shot: e2e/.auth/capture-failure.png`);
        throw err;
    } finally {
        await context.close();
        await browser.close();
    }
}

main().catch((err) => {
    console.error(err.message || err);
    process.exit(1);
});
