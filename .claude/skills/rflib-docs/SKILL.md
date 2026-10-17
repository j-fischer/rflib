---
name: rflib-docs
description: >
    Use this skill to document a finished RFLIB feature: capture the screenshots it
    needs from a live scratch org, commit them to the local branch, and submit a
    request to update the rflib-wiki articles that describe the change. Works from
    the current branch or from an already merged pull request. Trigger phrases
    include: "document this feature", "update the wiki", "capture screenshots",
    "take screenshots for the wiki", "wiki update request", "rflib docs".
version: 1.0.0
user-invocable: true
disable-model-invocation: true
allowed-tools:
    - Bash(node e2e/tools/capture.mjs:*)
    - Bash(node e2e/tools/inspect.mjs:*)
    - Bash(sf org display:*)
    - Bash(sf org list:*)
    - Bash(sf project deploy:*)
    - Bash(git log:*)
    - Bash(git diff:*)
    - Bash(git show:*)
    - Bash(git status:*)
    - Bash(git branch:*)
    - Bash(git rev-parse:*)
    - Bash(git add:*)
    - Bash(git commit:*)
    - Bash(gh pr view:*)
    - Bash(gh pr list:*)
    - Read
    - Write
    - Edit
    - Glob
    - Grep
    - mcp__ccd_session__spawn_task
---

# RFLIB Feature Documentation

Turns a finished change into published documentation. Two deliverables:

1. **Screenshots** of the feature, captured from a live scratch org by
   `e2e/tools/capture.mjs` and committed to the local branch.
2. **A wiki update request** — a self-contained brief handed to a separate session
   working in `../rflib-wiki`, written as if the screenshots are already on `master`.

The wiki lives in its own repository (`j-fischer/rflib.wiki`, cloned at
`../rflib-wiki`). This skill never edits it directly; it submits the request.

All paths are relative to the repo root. Screenshots must show the branch's code,
so the scratch org has to have that code deployed — Step 2 is not optional.

---

## Step 0 — Scope the change

**From the current branch** (the usual case, pre-merge):

```bash
git log master..HEAD --oneline
```

```bash
git diff master...HEAD --stat
```

The commit bodies in this repo are long and explain intent — read them; they are the
best source for the brief. Also read the branch's `CHANGELOG.md` diff, which is
already written for a customer audience:

```bash
git diff master...HEAD -- CHANGELOG.md
```

**From a merged PR** (post-merge):

```bash
gh pr view 144 --json number,title,body,mergeCommit,files --jq '{number,title,merge:.mergeCommit.oid,files:[.files[].path][:5],body:(.body|.[0:300])}'
```

Then read the full change with `git show <mergeCommit>`. In this mode you are on
`master`, so create a branch before committing screenshots (Step 5).

Confirm with the user what the feature is called and which wiki articles it touches
before spending 10 minutes on screenshots.

---

## Step 1 — Decide whether screenshots are needed

Capture only what a reader cannot picture from prose.

| Change                                      | Screenshot?                                                         |
| ------------------------------------------- | ------------------------------------------------------------------- |
| New or changed control in an Ops Center LWC | **Yes** — the control, plus the state it produces                   |
| New Ops Center tab or dashboard             | **Yes** — one overview shot                                         |
| New Global Setting / Custom Setting field   | No — it becomes a table row in `Global-Config-Settings.md`          |
| Apex API, trigger framework, Flow action    | No — code samples, unless the Setup UI configuration is non-obvious |
| Bug fix with no visual change               | No                                                                  |

Existing screenshots in `screenshots/` are the naming convention: `Feature_Area_Detail.png`,
one PascalCase segment per word (`Permission_Explorer_Fields_Without_FLS_Menu.png`). Match
the prefix of the sibling shots for the same tab — the wiki groups them that way.

---

## Step 2 — Point the org at the branch's code

The capture driver reads the E2E suite's session files; it never logs in itself.

```bash
sf org display --json
```

`result.status` must be `Active`. If there is none, create one through the
`rflib-quality` skill (`npx gulp create-scratch --alias rflib`).

Verify the org runs the branch's code — an empty deploy means it is current:

```bash
sf project deploy preview
```

```
No conflicts found.
No files will be deleted.
No files will be deployed.
```

If files are listed, deploy them (~3-5 min):

```bash
sf project deploy start -w 25
```

Then refresh the browser session (~30s, writes `e2e/.auth/`):

```bash
node e2e/tools/inspect.mjs auth
```

---

## Step 3 — Capture (agent path)

The driver is `e2e/tools/capture.mjs`, alongside `inspect.mjs` — the other tool that
drives the Ops Center in a scratch org outside the Playwright suite. It opens the app
through the App Launcher so the shot carries the chrome the wiki screenshots all have,
hides scratch-org-only noise (LWC debug banner, DevOps Center bar, EPT/ART badges), and
writes viewport PNGs at 1440x900 into `screenshots/`.

One-off shot of a tab as it loads:

```bash
node e2e/tools/capture.mjs tab "Permissions Explorer" --settle 20000 --out screenshots/Permission_Explorer_Overview.png
```

Anything that needs interaction — a menu open, a filter applied, a mode switched — goes
in a **recipe** under `e2e/tools/recipes/`, named after the screenshot it produces. That
directory is tracked, so a recipe is committed with its screenshots and the shot can be
regenerated after a UI change.
`e2e/tools/recipes/Permission_Explorer_Fields_Without_FLS.mjs` is the worked example; the
shape is:

```js
export const target = { tab: 'Permissions Explorer', settle: 20000 };

export default async function ({ page, root, shoot, settle }) {
    await root.getByRole('button', { name: 'Object Permission For Profiles' }).click();
    await page.getByRole('menuitem', { name: 'Field Permissions for Profiles' }).click();
    await settle(45000);
    await shoot('screenshots/Permission_Explorer_Fields_Without_FLS_Menu.png');
}
```

`root` is the tab's root `c-rflib-*` component as a Playwright locator (RFLIB components
sit in shadow roots — locators pierce them, `document.querySelector` does not). `shoot()`
may be called repeatedly for several screenshots in one run. `target` accepts
`{ url: 'lightning/n/rflib_Log_Monitor' }` instead of `{ tab }` — about a minute faster,
but it lands in whatever app the stored session last used, so the nav bar is not
guaranteed to say Ops Center. Use `{ tab }` when the chrome is part of the shot.

```bash
node e2e/tools/capture.mjs recipe e2e/tools/recipes/Permission_Explorer_Fields_Without_FLS.mjs
```

```
Root component: c-rflib-permissions-explorer
Screenshot: screenshots\Permission_Explorer_Fields_Without_FLS_Menu.png  1440x900  88KB
Screenshot: screenshots\Permission_Explorer_Fields_Without_FLS.png  1440x900  99KB
```

Other flags: `--scope <css>` (clip to an element instead of the viewport), `--full`
(full page), `--size 1440x900`, `--headed`, `--settle <ms>`.

Selectors are the hard part, and the fastest source of truth is the component's own
template — the label a `getByRole` needs is written there literally:

```bash
grep -n "label=\|placeholder=\|data-id=" rflib/main/default/lwc/rflibPermissionsExplorer/rflibPermissionsExplorer.html
```

Option labels that come from JS constants (menu items, permission types) live in the
`.js` file instead. `e2e/tools/inspect.mjs` (see the `rflib-e2e` skill) can probe a
candidate against the live DOM, but it currently throws
`el.attributes is not iterable` on the Permissions Explorer, so the template is the
reliable path for that tab.

---

## Step 4 — Look at every PNG

Non-negotiable: `Read` each file the run produced. The driver cannot tell a correct shot
from one showing a spinner, a login page, an empty table, or a tooltip over the control.
Check that the feature is actually _visible_ — a count that changed in the header is not
a screenshot of a feature. Filter, search, or paginate the UI into the state that shows
it, then re-run.

---

## Step 5 — Commit the screenshots to the local branch

The screenshots plus the recipe that produced them. Never bundle source changes into this
commit — the branch's feature commits are already written.

```bash
git add screenshots/Permission_Explorer_Fields_Without_FLS.png screenshots/Permission_Explorer_Fields_Without_FLS_Menu.png e2e/tools/recipes/Permission_Explorer_Fields_Without_FLS.mjs
```

```bash
git status --short
```

Re-running a recipe whose screenshots are already committed usually leaves `git status`
clean — the capture is deterministic as long as the org data has not changed. That is the
pass condition for a verification run, not a missed commit. When only some PNGs come back
modified, open them: an intentional UI change is a commit, identical-looking noise is
`git checkout -- screenshots/`.

Commit with the repo's convention (`docs(rflib): ...`, body explaining what each shot
shows, `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>` last). In post-merge mode,
branch first — do not commit to `master`.

Do not push. The wiki request assumes the screenshots reach `master`; getting them there
is the user's call.

---

## Step 6 — Submit the wiki update request

Write the brief to the session scratchpad first so the user can read it, then submit it.
The brief must stand alone — the wiki session has no access to this conversation or to
the rflib working tree.

The brief covers:

- **Source** — repo, branch or PR, commit SHAs, and the line "Assume the branch is merged
  into `master` — the screenshots below are committed there."
- **What shipped** — customer-facing behaviour, in the CHANGELOG's voice. Include the
  _why_ from the commit bodies; the wiki explains, the changelog announces.
- **Articles to update** — exact file names in `../rflib-wiki`, and where in each file.
  Check the headings first (`grep -n '^#' ../rflib-wiki/<Article>.md`). Common landing
  spots: `Ops-Center-*.md` for dashboard behaviour, `Global-Config-Settings.md` for a new
  Global Setting (one table row, kept alphabetical, `Since Version` = the release), and
  `Logger-Settings.md` for a Custom Setting field.
- **Screenshots** — file names plus the markdown to paste, in the URL form the wiki
  already uses (this is why the screenshots must be on `master` for the images to render):

    ```markdown
    ![Fields Without FLS menu](https://github.com/j-fischer/rflib/blob/master/screenshots/Permission_Explorer_Fields_Without_FLS_Menu.png 'Fields Without FLS menu')
    ```

- **Conventions** — flat markdown pages at the wiki repo root, file name = page title with
  dashes, cross-page links by bare page name (`[Global Config Settings](Global-Config-Settings)`),
  admin voice, no changelog phrasing, `_Sidebar.md` only when a new page is added, and:
  **commit locally, do not push** — pushing publishes the wiki.

Submit it with `spawn_task`, `cwd` set to the wiki clone:

```
mcp__ccd_session__spawn_task(
    cwd: "C:\\Users\\fisch\\Projects\\Salesforce\\rflib-wiki",
    title: "Document Fields Without FLS in the wiki",
    tldr: "<one or two sentences, no file paths>",
    prompt: "<the full brief>"
)
```

The user gets a chip that opens a session in the wiki repo with the brief as its first
message. Tell them the chip is waiting — it does not run on its own. If `spawn_task` is
unavailable, hand the user the brief file path and the one-liner to open it themselves.

Submit **once per change**. A second run over the same branch — a verification pass, a
re-capture — must not spawn a second chip: check whether one is already pending for this
feature, and if the brief has since changed, `dismiss_task` the old one and explain why
rather than leaving two.

---

## Gotchas

- **The driver never authenticates.** It consumes `e2e/.auth/org.json` +
  `storageState.json` written by `node e2e/tools/inspect.mjs auth`. A shot of a login page
  means that state expired — re-run `auth`, do not debug the recipe.
- **Debug mode decorates the org.** A scratch org created by `gulp create-scratch` has LWC
  debug mode on, which adds a blue banner and EPT/ART/storage badges to the header, and the
  DevOps Center adds a "Scratch Org" bar above it. The driver hides all three with injected
  CSS (`NOISE_CSS` in `capture.mjs`) rather than changing org settings — nothing to undo,
  but add to that list if a new banner appears.
- **SLDS tooltips follow the cursor into the screenshot.** After clicking a button with a
  `tooltip` attribute the tip stays up and lands in the shot. `shoot()` parks the mouse at
  0,0 first; pass `{ keepHover: true }` when a hover state is the point of the shot.
- **A record count is not a screenshot.** Enabling Fields Without FLS took the Permissions
  Explorer from 26,376 to 73,056 records, but page 1 was still Account's alphabetical FLS
  rows — the recipe has to search `CreatedById` before the synthesized rows are on screen
  at all. Whatever the feature adds, drive the UI until it is visible.
- **Field permission views are slow.** Switching permission type pages through tens of
  thousands of records; `settle(45000)` is realistic. The worked recipe runs in ~100s;
  budget ~5 minutes for a full pass including the deploy check and the auth refresh.
  `--settle` too low yields a shot of a spinner.
- **`.claude/` is gitignored** (`.gitignore:51`), so this `SKILL.md` is local-only, exactly
  like `rflib-cr`, `rflib-e2e` and `rflib-quality`. The driver and the recipes live under
  `e2e/tools/` precisely because that path is tracked — a screenshot nobody else can
  regenerate is worse than no screenshot.
- **`git status` is dirty after a capture run.** `e2e/.auth/*.png` (including
  `capture-failure.png`, written whenever a recipe throws) is untracked debris. `git add`
  the screenshots by path — never `git add -A`.
- **The wiki has no PR flow.** `rflib.wiki` is a git wiki: the only way in is a commit on
  `master`. That is why the request stops at a local commit and leaves the push to the user.
- **Some existing wiki images point at `blob/main`** even though the default branch is
  `master`. Do not copy that form for new images.

---

## Troubleshooting

| Symptom                                                              | Cause / fix                                                                                                                                                                                                                    |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Missing e2e/.auth session files`                                    | Run `node e2e/tools/inspect.mjs auth`.                                                                                                                                                                                         |
| `Recipe ... must export "target" with { tab } or { url }`            | The recipe was run with the `recipe` command but has no `target` export; add it, or pass `--recipe` with `tab`/`url` on the command line.                                                                                      |
| `Root component: (none - using body)` on an Ops Center tab           | The tab did not finish rendering — raise `--settle`. Expected on `lightning/page/home`.                                                                                                                                        |
| Recipe throws mid-run                                                | Read `e2e/.auth/capture-failure.png` — the driver writes it on every failure, and it usually shows the UI was in a different state than the recipe assumed.                                                                    |
| `locator.click: Timeout` on a menu item                              | The label changed, or the control does not render in this mode (the Fields Without FLS menu only exists in field permission views). Grep the component's `.html` for the literal label, and its `.js` for menu-item constants. |
| Nav bar shows the wrong app                                          | `{ url }` renders the tab inside whatever app the stored session last used — it happens to be the Ops Center only because an earlier run opened it. Use `{ tab }` whenever the chrome is part of the shot.                     |
| `No files will be deployed` but the feature is missing from the shot | Source tracking is current for the _default_ org and you are pointed at the wrong one. Re-check `sf org display --json`.                                                                                                       |
