# RFLIB End-to-End Tests

Playwright suite that drives the **RFLIB Ops Center** against a real scratch org.

```bash
npx gulp test-e2e --alias <org-alias>
```

Add `--chrome` to watch it run. `npx playwright test <spec>` works too once a default
org is set (`sf config set target-org <alias>`).

## Layering

Four layers, each only allowed to know about the one below it:

| Layer                | Location           | Knows about                                         |
| -------------------- | ------------------ | --------------------------------------------------- |
| **Spec**             | `specs/`           | Behaviour and assertions. **No CSS selectors.**     |
| **Page object**      | `pages/`           | One Ops Center tab: its root, header, and layout    |
| **Component object** | `components/`      | One RFLIB LWC (`c-rflib-*`) and its internal markup |
| **Base component**   | `components/base/` | Salesforce base components (`lightning-*`) and SLDS |

Component objects are rooted on a `Locator`, not a `Page`, so the same object works
wherever the component is mounted. Compose them with the `within(scope)` factory:

```ts
get eventList(): LogEventListComponent {
    return LogEventListComponent.within(this.root);
}
```

`helpers/` holds the non-UI plumbing: `sf.ts` (sf CLI bridge, org info, storage state
paths) and `polling.ts` (`pollUntil` for org-side async work that needs a reload
between attempts).

### Adding a tab

1. A component object per new RFLIB LWC in `components/`.
2. A page object in `pages/` exposing those components.
3. A numbered spec in `specs/`.
4. Add the tab label to `TABS` and its root element to `ROOT_COMPONENT_TAGS`, both in
   `pages/ops-center-app.page.ts`, so the navigation smoke test picks it up.

**Spec ordering is load-bearing.** `workers: 1` and `fullyParallel: false` mean the
numeric prefixes are the execution order, and `05-log-archive.spec.ts` is destructive:
it wipes `rflib_Logs_Archive__b` and must stay after specs 02 and 04.

## Selector priority ladder

Work down this list and stop at the first option that applies:

1. **An existing `data-*` hook in the template** - `data-field` on the log event list
   search inputs, `data-field-name` in the settings editor, `data-id` in the
   confirmation dialog, `data-log-id` on rows.
2. **Role plus accessible name** - `getByRole('button', { name: 'Export to CSV' })`.
   For icon-only `lightning-button-menu`, the `alternative-text` attribute _is_ the
   accessible name.
3. **A unique placeholder** - the permissions table's three search inputs.
4. **A class authored by the component** - `.archive-filter`, `.action-group`,
   `.logMessages`, `.page-selector`.
5. **A structural relationship** - "the action group that contains the Query Archive
   button" beats "the first menu in the header".
6. **SLDS structural classes** - `.slds-page-header__col-actions`.
7. **Positional `.nth()`** - last resort, and only with a comment saying why the order
   is safe to depend on.

Where a higher rung is not certain to render, chain it with `.or()` and put the old
locator in the fallback branch:

```ts
this.header
    .getByRole('button', { name: 'Log visibility settings' })
    .or(this.header.locator('.slds-page-header__col-controls lightning-button-menu'))
    .first();
```

### LWC caveat: properties are not attributes

LWC sets a custom element's public props as **JS properties, not DOM attributes**. So
even though `rflibLogEventMonitor.html` writes `<lightning-input name="startDate">`,
`lightning-input[name="startDate"]` will not match anything in the browser.

What _does_ reach the DOM:

- `data-*` authored in the template (the component reads them back via `dataset`)
- `class`
- `placeholder`, forwarded to the inner `<input>`
- `label` on `lightning-button-menu`, as the trigger's visible text
- `alternative-text`, as an `.slds-assistive-text` span - the accessible name
- variant, as an SLDS modifier class (`variant="brand"` -> `.slds-button_brand`)

`id` is unreliable too: LWC rewrites ids to keep them unique across component
instances, which is why the paginator is addressed by `input.page-selector` rather
than `#pageNum`.

### Verifying a selector change

Selectors assert what the browser renders, so confirm a change against a live org
before relying on it - `npx playwright test <spec> --headed`, or `--ui` to inspect.
If you cannot confirm it, keep the previous locator as an `.or()` fallback rather
than guessing.

`tools/inspect.mjs` does the same check without a browser window: it opens a tab in
the default org using this suite's storage state and prints the ladder rungs it finds,
plus the match count for any candidate selector.

```bash
node e2e/tools/inspect.mjs auth                       # refresh .auth/ (once per session)
node e2e/tools/inspect.mjs url "lightning/n/rflib_Log_Monitor" \
    --scope "c-rflib-log-event-list" \
    --probe 'lightning-input[data-field="context"] input'
```

`node e2e/tools/inspect.mjs help` lists the rest (`tab <label>`, `--shot`, `--settle`,
`--json`, `--headed`).

### Accepted exceptions

- `01-app-navigation.spec.ts` asserts on root custom element tags via
  `app.rootComponent(...)`. That a tab mounts its component at all _is_ the assertion.
- `08-app-events-dashboard.spec.ts` locates a bare `iframe`. The flexipage embeds a
  standard analytics dashboard whose hardcoded ID does not exist in a scratch org, so
  the test only proves the shell renders.

## Waiting

In order of preference:

1. Web-first assertions with a generous explicit timeout.
2. `expect.poll(...)` when a value converges in place.
3. `pollUntil(...)` from `helpers/polling.ts` when the retry needs a page reload -
   Big Object archiving, platform event consumers.
4. `waitForSpinners(scope)` as a load gate.
5. `page.waitForTimeout(...)` only where nothing observable exists to wait on (the
   CometD handshake), and always with a comment explaining why.

EMP/CometD is the main source of flake in a fresh scratch org: the first subscribe can
stall silently. `LogMonitorPage.connectInMode()` handles this by reloading and
retrying the whole mode switch; prefer it over asserting on the connection status
directly.

## Why Playwright and not UTAM

[UTAM](https://developer.salesforce.com/docs/platform/utam/guide/get-started-utam.html)
is Salesforce's UI Test Automation Model: page objects declared in JSON, compiled to
Java or JavaScript, with a prebuilt catalogue (`salesforce-pageobjects`) covering
standard Lightning Experience UI.

It was evaluated for this suite and not adopted, because:

- **The JS runtime binds to WebdriverIO.** `@utam/core` ships a WebdriverIO adapter
  (`wdio-utam-service`) and no Playwright binding, so adopting UTAM means replacing
  Playwright outright - including the EMP retry logic, the scratch-org global setup,
  and Playwright's traces, video, and UI mode.
- **Its prebuilt page objects cover standard Salesforce UI**, which this suite barely
  touches. The Ops Center is almost entirely RFLIB's own `c-rflib-*` components, for
  which no prebuilt objects exist.

What was adopted is UTAM's design, not its tooling: component-level page objects
composed into pages, a base-component layer standing in for `salesforce-pageobjects`,
and a selector policy that keeps the DOM out of the tests.

Worth re-evaluating if a supported Playwright binding appears, or if the suite grows
into standard Setup or record pages where the prebuilt catalogue would carry real
weight. `components/base/` is the seam a swap would go through.
