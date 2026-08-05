#!/usr/bin/env node
/**
 * DOM inspector for authoring RFLIB E2E page/component objects.
 *
 * Opens the Ops Center in the default (or RFLIB_E2E_TARGET_ORG) scratch org using the
 * same storage state the Playwright suite uses, then dumps the selector candidates the
 * suite's selector ladder cares about: data-* hooks, accessible names, placeholders,
 * authored classes and custom element tags. Nothing here runs as part of the suite; it
 * exists so a selector can be confirmed against a live org without --headed/--ui.
 *
 * Usage:
 *   node e2e/tools/inspect.mjs auth
 *   node e2e/tools/inspect.mjs tab "Log Monitor" [--scope <css>] [--probe <css>] [--shot <png>]
 *   node e2e/tools/inspect.mjs url "lightning/n/rflib_Log_Monitor" [...same flags]
 *
 * Flags:
 *   --scope <css>   Restrict the inventory to this element (default: the tab's root
 *                   c-rflib-* component, or <body> if none is found).
 *   --probe <css>   Report count/visibility/text for a candidate selector. Repeatable.
 *                   Prefix with "role=" to probe by role, e.g. --probe "role=button|Export to CSV".
 *   --shot <path>   Screenshot destination (default: e2e/.auth/inspect.png).
 *   --settle <ms>   Extra wait after load before inspecting (default 5000).
 *   --headed        Show the browser.
 *   --json          Emit the inventory as JSON instead of the text report.
 */
import { chromium } from '@playwright/test';
import { execFileSync } from 'node:child_process';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const E2E_DIR = path.join(HERE, '..');
const REPO_ROOT = path.join(E2E_DIR, '..');
const AUTH_DIR = path.join(E2E_DIR, '.auth');
const ORG_INFO_PATH = path.join(AUTH_DIR, 'org.json');
const STORAGE_STATE_PATH = path.join(AUTH_DIR, 'storageState.json');
const IS_WINDOWS = process.platform === 'win32';

const APP_NAME = 'RFLIB Ops Center';

// ---------------------------------------------------------------- sf CLI bridge

// Mirrors e2e/helpers/sf.ts: Node >= 20 refuses to spawn .cmd shims without a shell,
// and local sf wrappers print banner noise before the JSON payload.
function sfJson(args) {
    const targetOrg = process.env.RFLIB_E2E_TARGET_ORG;
    const full = targetOrg ? [...args, '--target-org', targetOrg, '--json'] : [...args, '--json'];
    const quoted = IS_WINDOWS ? full.map((a) => (/\s/.test(a) ? `"${a}"` : a)) : full;
    const out = execFileSync(IS_WINDOWS ? 'sf.cmd' : 'sf', quoted, {
        encoding: 'utf8',
        shell: IS_WINDOWS,
        cwd: REPO_ROOT,
        maxBuffer: 64 * 1024 * 1024
        // eslint-disable-next-line no-control-regex
    }).replace(/\x1b\[[0-9;]*[A-Za-z]/g, '');
    const start = out.indexOf('{');
    const end = out.lastIndexOf('}');
    if (start < 0 || end <= start) {
        throw new Error(`No parseable JSON in sf output: ${out.substring(0, 400)}`);
    }
    return JSON.parse(out.substring(start, end + 1));
}

function orgInfo() {
    if (!fs.existsSync(ORG_INFO_PATH)) {
        throw new Error(`${ORG_INFO_PATH} is missing. Run: node e2e/tools/inspect.mjs auth`);
    }
    return JSON.parse(fs.readFileSync(ORG_INFO_PATH, 'utf8'));
}

/** Refreshes org.json + storageState.json. Same handshake as e2e/global-setup.ts. */
async function auth() {
    const display = sfJson(['org', 'display']);
    if (display.status !== 0) {
        throw new Error(`No default org. Set one with "sf config set target-org <alias>".`);
    }
    const username = display.result.username;
    const instanceUrl = display.result.instanceUrl.replace(/\/$/, '');
    const users = sfJson(['data', 'query', '--query', `SELECT Name FROM User WHERE Username = '${username}'`]);
    fs.mkdirSync(AUTH_DIR, { recursive: true });
    fs.writeFileSync(
        ORG_INFO_PATH,
        JSON.stringify({ username, instanceUrl, adminName: users.result.records[0].Name }, null, 4)
    );

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
    console.log(`Authenticated ${username} at ${instanceUrl}`);
    console.log(`Wrote ${ORG_INFO_PATH} and ${STORAGE_STATE_PATH}`);
}

// ---------------------------------------------------------------- inventory

// Runs in the page against an element handle. Collects only what the selector ladder
// in e2e/README.md can use.
//
// The walk descends into shadow roots: RFLIB's components sit inside native shadow
// roots in Lightning Experience, so a plain querySelectorAll('*') from document never
// reaches them (Playwright locators pierce, raw DOM APIs do not).
/* eslint-disable */
const COLLECT = (root) => {
    if (!root) {
        return { error: 'scope matched nothing' };
    }
    const els = [];
    (function walk(node) {
        els.push(node);
        if (node.shadowRoot) {
            for (const child of node.shadowRoot.children) walk(child);
        }
        for (const child of node.children) walk(child);
    })(root);
    const bump = (map, key) => key && map.set(key, (map.get(key) || 0) + 1);
    const tags = new Map();
    const dataHooks = new Map();
    const placeholders = new Map();
    const names = new Map();
    const classes = new Map();
    const texts = [];

    const visible = (el) => {
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
    };

    for (const el of els) {
        const tag = el.tagName.toLowerCase();
        if (tag.startsWith('c-') || tag.startsWith('lightning-') || tag.startsWith('one-')) {
            bump(tags, tag);
        }
        for (const attr of el.attributes) {
            if (attr.name.startsWith('data-') && attr.name !== 'data-rendered-callback') {
                bump(dataHooks, `${tag}[${attr.name}="${attr.value}"]`);
            }
        }
        // getAttribute, not el.placeholder: LWC exposes public props as JS properties
        // on the custom element too, and getByPlaceholder only matches the attribute.
        const placeholder = el.getAttribute('placeholder');
        if (placeholder) {
            bump(placeholders, `${tag} :: ${placeholder}`);
        }
        const role = el.getAttribute('role');
        const interactive = ['button', 'a', 'input', 'select', 'textarea'].includes(tag) || role;
        if (interactive && visible(el)) {
            const label =
                el.getAttribute('aria-label') ||
                el.getAttribute('title') ||
                (el.innerText || el.textContent || '').trim().split('\n')[0];
            if (label) {
                bump(names, `${role || tag} :: ${label.substring(0, 80)}`);
            }
        }
        for (const c of el.classList) {
            // slds-* is the framework's own vocabulary; authored classes are the
            // interesting ones because they come from the RFLIB template.
            if (!c.startsWith('slds-') && !/^[a-z]+-\d/.test(c)) {
                bump(classes, `.${c}`);
            }
        }
        if (['h1', 'h2', 'h3', 'p', 'legend'].includes(tag) && visible(el)) {
            const t = (el.innerText || '').trim();
            if (t && t.length < 160) {
                texts.push(`${tag}: ${t}`);
            }
        }
    }
    const top = (map, n) =>
        [...map.entries()]
            .sort((a, b) => b[1] - a[1])
            .slice(0, n)
            .map(([k, v]) => (v > 1 ? `${k}  (x${v})` : k));
    return {
        elementCount: els.length,
        customElements: top(tags, 40),
        dataHooks: top(dataHooks, 40),
        placeholders: top(placeholders, 20),
        accessibleNames: top(names, 60),
        authoredClasses: top(classes, 40),
        headings: [...new Set(texts)].slice(0, 25)
    };
};
/* eslint-enable */

// ---------------------------------------------------------------- navigation

async function openViaAppLauncher(page, info) {
    await page.goto(`${info.instanceUrl}/lightning/page/home`, { waitUntil: 'domcontentloaded' });
    const waffle = page
        .getByRole('button', { name: 'App Launcher' })
        .or(page.locator('button div.slds-icon-waffle'))
        .first();
    await waffle.click();
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

/** Best-effort guess of the tab's root component when --scope is not given. */
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
        // The tab's root is the largest visible c-rflib-* element on the page.
        found.sort((a, b) => b.area - a.area);
        return found.length > 0 ? found[0].tag : null;
    });
}

// ---------------------------------------------------------------- probes

async function probe(page, spec) {
    const locator = spec.startsWith('role=')
        ? (() => {
              const [role, name] = spec.slice('role='.length).split('|');
              return name ? page.getByRole(role, { name }) : page.getByRole(role);
          })()
        : page.locator(spec);
    const count = await locator.count();
    if (count === 0) {
        return `  ✗ ${spec}\n      0 matches`;
    }
    const first = locator.first();
    const [isVisible, text] = await Promise.all([
        first.isVisible().catch(() => false),
        first
            .innerText()
            .catch(() => '')
            .then((t) => (t || '').trim().replace(/\s+/g, ' ').substring(0, 120))
    ]);
    return `  ✓ ${spec}\n      ${count} match(es), first visible=${isVisible}${text ? `, text="${text}"` : ''}`;
}

// ---------------------------------------------------------------- main

function parseArgs(argv) {
    const opts = { probes: [], settle: 5000 };
    const rest = [];
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (a === '--scope') opts.scope = argv[++i];
        else if (a === '--probe') opts.probes.push(argv[++i]);
        else if (a === '--shot') opts.shot = argv[++i];
        else if (a === '--settle') opts.settle = Number(argv[++i]);
        else if (a === '--headed') opts.headed = true;
        else if (a === '--json') opts.json = true;
        else rest.push(a);
    }
    return { opts, rest };
}

function report(inv) {
    const section = (title, lines) => {
        if (!lines || lines.length === 0) return;
        console.log(`\n${title}`);
        lines.forEach((l) => console.log(`  ${l}`));
    };
    console.log(`\n=== Inventory for scope: ${inv.scope} (${inv.elementCount} elements) ===`);
    section('1. data-* hooks (top of the selector ladder)', inv.dataHooks);
    section('2. Accessible names (role + name)', inv.accessibleNames);
    section('3. Placeholders', inv.placeholders);
    section('4. Authored classes (non-SLDS)', inv.authoredClasses);
    section('Custom elements', inv.customElements);
    section('Visible headings/text', inv.headings);
}

async function main() {
    const [command, ...argv] = process.argv.slice(2);
    if (!command || command === 'help' || command === '--help') {
        console.log(fs.readFileSync(fileURLToPath(import.meta.url), 'utf8').split('*/')[0]);
        return;
    }
    if (command === 'auth') {
        await auth();
        return;
    }
    if (command !== 'tab' && command !== 'url') {
        throw new Error(`Unknown command "${command}". Expected: auth | tab | url`);
    }

    const { opts, rest } = parseArgs(argv);
    const target = rest[0];
    if (!target) {
        throw new Error(command === 'tab' ? 'Missing tab label.' : 'Missing URL path.');
    }
    const info = orgInfo();
    if (!fs.existsSync(STORAGE_STATE_PATH)) {
        throw new Error(`${STORAGE_STATE_PATH} is missing. Run: node e2e/tools/inspect.mjs auth`);
    }

    const browser = await chromium.launch({ headless: !opts.headed });
    const context = await browser.newContext({
        storageState: STORAGE_STATE_PATH,
        viewport: { width: 1600, height: 900 }
    });
    const page = await context.newPage();
    try {
        if (command === 'tab') {
            await openViaAppLauncher(page, info);
            await gotoTab(page, target);
        } else {
            // Git Bash rewrites a leading "/" argument into a Windows path, so the
            // documented form omits it; normalize either way.
            const relative = target.startsWith('/') ? target : `/${target}`;
            await page.goto(`${info.instanceUrl}${relative}`, { waitUntil: 'domcontentloaded' });
        }
        // Lightning renders progressively and RFLIB components fetch on connect;
        // there is no single observable "done" signal, hence a settle wait.
        await page.waitForTimeout(opts.settle);
        await page
            .locator('lightning-spinner')
            .first()
            .waitFor({ state: 'hidden', timeout: 120_000 })
            .catch(() => {});

        const scope = opts.scope ?? (command === 'tab' ? await detectRoot(page) : null);
        if (!opts.scope && scope) {
            console.log(`Detected root component: ${scope}  (override with --scope)`);
        }
        // Resolve the scope through a Playwright locator: it pierces shadow roots,
        // document.querySelector does not.
        const scopeLocator = scope ? page.locator(scope).first() : page.locator('body');
        if ((await scopeLocator.count()) === 0) {
            throw new Error(`Scope "${scope}" matched nothing on the page.`);
        }
        const inv = await scopeLocator.evaluate(COLLECT);
        inv.scope = scope ?? 'body';
        if (inv.error) {
            console.log(`Inventory error: ${inv.error}`);
        } else if (opts.json) {
            console.log(JSON.stringify(inv, null, 2));
        } else {
            report(inv);
        }

        if (opts.probes.length > 0) {
            console.log('\n=== Probes ===');
            for (const p of opts.probes) {
                console.log(await probe(page, p));
            }
        }

        const shot = opts.shot ?? path.join(AUTH_DIR, 'inspect.png');
        fs.mkdirSync(path.dirname(shot), { recursive: true });
        await page.screenshot({ path: shot, fullPage: false });
        console.log(`\nScreenshot: ${shot}`);
    } finally {
        await context.close();
        await browser.close();
    }
}

main().catch((err) => {
    console.error(err.message || err);
    process.exit(1);
});
