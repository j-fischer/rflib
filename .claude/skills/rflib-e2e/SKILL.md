---
name: rflib-e2e
description: >
    Use this skill to create, extend, debug, or maintain the Playwright end-to-end
    tests under e2e/ — adding a spec, page object, or component object for an RFLIB
    LWC, confirming or repairing a selector against a live scratch org, and running
    one spec instead of the whole suite. Trigger phrases include: "add an e2e test",
    "write a Playwright spec", "e2e page object", "component object", "fix the e2e
    selector", "the e2e test is failing", "run one e2e spec", "inspect the Ops
    Center DOM", "rflib e2e".
version: 1.0.0
user-invocable: true
disable-model-invocation: false
allowed-tools:
    - Bash(node e2e/tools/inspect.mjs:*)
    - Bash(npx playwright test:*)
    - Bash(npx playwright show-report:*)
    - Bash(npx tsc:*)
    - Bash(npx gulp test-e2e:*)
    - Bash(sf org display:*)
    - Bash(sf apex run:*)
    - Bash(sf data query:*)
    - Read
    - Edit
    - Write
    - Glob
    - Grep
---

# RFLIB E2E Test Authoring

The suite in `e2e/` drives the **RFLIB Ops Center** in a real scratch org with
Playwright. Authoring a test here is 90% selector work, and a selector is only true if
the browser agrees — so the primary tool is **`e2e/tools/inspect.mjs`**, a DOM
inspector that opens the live org with the suite's own storage state and dumps the
selector candidates the suite's ladder cares about. Use it before writing a locator,
not after a spec fails.

All paths are relative to the repo root. `e2e/README.md` is the canonical reference
for the selector ladder and the layering rules; this skill is the executable path.

---

## Step 0 — Confirm the org and refresh auth

Every command below needs an active scratch org set as the default target:

```bash
sf org display --json
```

If `result.status` is not `Active`, stop and create one via the `rflib-quality`
skill (`npx gulp create-scratch --alias "${RFLIB_SCRATCH_ALIAS:-rflib}"`) — the suite depends on the perm sets,
custom settings, and seeded events that task provisions.

Then refresh the browser session the inspector and the suite share:

```bash
node e2e/tools/inspect.mjs auth
```

This writes `e2e/.auth/org.json` and `e2e/.auth/storageState.json` using the same
frontdoor handshake as `e2e/global-setup.ts`. Re-run it if the inspector lands on a
login page. Takes ~30s.

---

## Step 1 — Inspect the live DOM (agent path)

Two entry points. Prefer `url` — it is roughly a minute faster than `tab`, which walks
the App Launcher the way the suite does.

```bash
node e2e/tools/inspect.mjs url "lightning/n/rflib_Log_Monitor" --scope "c-rflib-log-event-list"
```

```bash
node e2e/tools/inspect.mjs tab "Permissions Explorer"
```

With no `--scope`, the inspector picks the largest visible `c-rflib-*` element as the
root and says so. Tab URL paths come from `rflib/main/default/tabs/*.tab-meta.xml`
(e.g. `rflib_Log_Monitor`, `rflib_Permissions_Explorer`).

Real output, trimmed — the numbered sections are the selector ladder in priority
order:

```
Detected root component: c-rflib-permissions-explorer  (override with --scope)

=== Inventory for scope: c-rflib-permissions-explorer (376 elements) ===

1. data-* hooks (top of the selector ladder)
  lightning-input[data-field="context"]
  svg[data-key="search"]  (x2)

2. Accessible names (role + name)
  button :: Export to CSV
  button :: Select page size

3. Placeholders
  input :: Search Object/Class/Page...

4. Authored classes (non-SLDS)
  .permissions-container
  .page-selector

Custom elements
  c-rflib-permissions-table
  c-rflib-paginator
```

### Probe a candidate before committing to it

`--probe` reports match count, visibility, and first-match text. Repeat it. Prefix with
`role=` to probe by role (`role=<role>|<name>`). This is the check that replaces
`--headed`:

```bash
node e2e/tools/inspect.mjs url "lightning/n/rflib_Log_Monitor" --scope "c-rflib-log-event-list" --probe 'lightning-input[data-field="context"] input' --probe 'lightning-input[name="context"]'
```

```
=== Probes ===
  ✓ lightning-input[data-field="context"] input
      1 match(es), first visible=true
  ✗ lightning-input[name="context"]
      0 matches
```

Other flags: `--shot <path>` (screenshot, defaults to `e2e/.auth/inspect.png`),
`--settle <ms>` (extra wait before inspecting, default 5000 — raise it for the
Permissions Explorer, which pages through thousands of records), `--json`,
`--headed`.

---

## Step 2 — Put the code in the right layer

Four layers, each only allowed to know about the one below it:

| Layer     | Location               | Owns                                     | Never contains       |
| --------- | ---------------------- | ---------------------------------------- | -------------------- |
| Spec      | `e2e/specs/`           | Behaviour, assertions                    | CSS selectors        |
| Page      | `e2e/pages/`           | One Ops Center tab: root, header, layout | `lightning-*` markup |
| Component | `e2e/components/`      | One `c-rflib-*` LWC and its inner markup | Page/tab knowledge   |
| Base      | `e2e/components/base/` | `lightning-*` and SLDS                   | RFLIB knowledge      |

Component objects are rooted on a `Locator`, never a `Page`, and expose a
`static within(scope: Locator)` factory so they compose wherever the component is
mounted — copy `e2e/components/log-event-list.component.ts` as the template. Export
new component objects from `e2e/components/index.ts`; base wrappers from
`e2e/components/base/index.ts`.

Selector priority (full version with rationale in `e2e/README.md`):
`data-*` hook → role + accessible name → unique placeholder → authored class →
structural relationship → SLDS structural class → `.nth()` with a comment. When a
higher rung might not render, chain `.or()` with the lower one as the fallback branch.

### Adding a whole new tab

1. A component object per new `c-rflib-*` LWC in `e2e/components/` (+ barrel export).
2. A page object in `e2e/pages/` composing them.
3. A numbered spec in `e2e/specs/`.
4. Add the tab label to `TABS` **and** its root element to `ROOT_COMPONENT_TAGS`, both
   in `e2e/pages/ops-center-app.page.ts`, so `01-app-navigation.spec.ts` covers it.

### Spec conventions

Numeric prefixes are the execution order (`workers: 1`, `fullyParallel: false`) and
they are load-bearing: `05-log-archive.spec.ts` wipes `rflib_Logs_Archive__b` and must
stay after 02 and 04. Specs open one shared session per file:

```ts
test.describe.configure({ mode: 'serial' });
test.beforeAll(async ({ browser }) => {
    ({ context, page } = await createOpsCenterSession(browser, TABS.permissionsExplorer));
});
test.afterAll(async () => {
    await context?.close();
});
```

Waiting, in order of preference: web-first assertions with a generous timeout →
`expect.poll` → `pollUntil` from `e2e/helpers/polling.ts` (when the retry needs a page
reload: Big Object archiving, platform-event consumers) → `waitForSpinners(scope)` →
`page.waitForTimeout` only with a comment saying why nothing observable exists.

---

## Step 3 — Verify

Type-check first; it is seconds and catches most page-object mistakes:

```bash
npx tsc --noEmit -p e2e/tsconfig.json
```

Confirm the runner discovers the new spec (this skips global setup, so it is fast):

```bash
npx playwright test --list
```

Run just the spec, or just one test in it:

```bash
npx playwright test e2e/specs/06-permissions-explorer.spec.ts --grep "loads object permissions"
```

Global setup (frontdoor auth + Apex seeding) runs on **every** `playwright test`
invocation, so even a single grep'd test costs ~2 minutes before the test starts:

```
Seeding test data (settings must be configured before log events publish)...
Global setup complete.

Running 1 test using 1 worker
  ok 1 [chromium] › 06-permissions-explorer.spec.ts:23:5 › loads object permissions for profiles by default (3.1s)
  1 passed (2.3m)
```

On failure, Playwright writes trace/screenshot/video into `test-results/` and an HTML
report into `playwright-report/`; open it with `npx playwright show-report`.

The whole suite against a named org is `npx gulp test-e2e --alias <alias>` — leave that
to the `rflib-quality` skill, which owns the full-branch validation pass.

---

## Gotchas

- **RFLIB components live inside shadow roots.** `document.querySelector('c-rflib-…')`
  from `page.evaluate` returns `null`; Playwright locators pierce shadow DOM, raw DOM
  APIs do not. This is why the inspector resolves `--scope` through a locator and walks
  `shadowRoot` explicitly. Any `evaluate`-based helper you add must do the same.
- **LWC public props are JS properties, not DOM attributes.** `rflibLogEventList.html`
  writes `<lightning-input name="context">`, but `lightning-input[name="context"]`
  matches nothing (probe output above proves it). What reaches the DOM: `data-*`
  authored in the template, `class`, `placeholder` (forwarded to the inner `<input>`
  only), `label` on `lightning-button-menu`, `alternative-text` as assistive-text span,
  and variant as an SLDS modifier class. `id` is rewritten by LWC and unusable.
- **`placeholder` sits on the inner `<input>`, not the `lightning-input`.** Address it
  as `lightning-input[data-field="x"] input` or `getByPlaceholder(...)`, and `fill()`
  the inner input. (The inspector deliberately reports the attribute, not the JS
  property, so its list matches what `getByPlaceholder` will actually find.)
- **Placeholders that only render in one mode won't show up.** The Permissions Explorer
  field-search input is absent from the inventory until you switch to a field
  permission type. Inspect in the state the test will be in.
- **Git Bash rewrites a leading `/` argument** into a Windows path
  (`/lightning/n/X` → `C:/Program Files/Git/lightning/n/X`). Pass URL paths without the
  leading slash; the inspector adds it back.
- **The `sf` CLI prints banner noise before its JSON** (plugin warnings, update
  notices). Anything shelling out to `sf --json` must scan for the first parseable `{`,
  as `e2e/helpers/sf.ts` and the inspector both do.
- **EMP/CometD is the main flake source.** The first subscribe in a fresh scratch org
  can stall silently; use `LogMonitorPage.connectInMode()` rather than asserting on the
  connection status directly.
- **`retries: 1` hides intermittent failures.** A spec that only passes on retry is a
  bug in the spec, not a pass — check the report before moving on.

---

## Troubleshooting

| Symptom                                                                 | Cause / fix                                                                                                                                                         |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `e2e/.auth/storageState.json is missing`                                | Run `node e2e/tools/inspect.mjs auth`.                                                                                                                              |
| Inspector screenshot shows a login page                                 | Storage state expired — re-run `auth`.                                                                                                                              |
| `Scope "<x>" matched nothing on the page`                               | The component did not render in this state, or the tag is wrong. Drop `--scope` and read the detected root + `Custom elements` list.                                |
| Inventory shows `splashPage-*` classes and no `c-rflib-*`               | Page hadn't finished rendering — raise `--settle`.                                                                                                                  |
| `No default org found. Set one with "sf config set target-org <alias>"` | Global setup / inspector cannot resolve the org.                                                                                                                    |
| `strict mode violation: locator resolved to N elements`                 | Ladder rung is not unique — add `.first()` only if the order is justified, otherwise narrow with a `data-*` hook or `.filter({ hasText })`.                         |
| Spec passes alone, fails in the suite                                   | Cross-spec data dependency; check the numeric ordering and what `05-log-archive` destroys.                                                                          |
| `Timeout … exceeded` on a poll                                          | Scratch-org async lag (Big Object archiving, platform events). Re-run once before changing code; fix polling in `e2e/helpers/polling.ts`, never with a fixed sleep. |
