---
name: rflib-pr
description: >
    Use this skill to create or update a pull request for the rflib repository with a
    description complete enough to approve the PR from the description alone: a feature
    overview, then a bottom-up walkthrough (data model → security → Apex services →
    integration → front end), critical code snippets with permalinks, and the review
    hotspots that need a look at the code. Trigger phrases include: "create a PR",
    "open a pull request", "write the PR description", "update the PR description",
    "rflib pr", "ready for review", or any request to put the current branch up for review.
version: 1.0.0
user-invocable: true
disable-model-invocation: false
allowed-tools:
    - Bash(node .claude/skills/rflib-pr/inventory.mjs:*)
    - Bash(node .claude/skills/rflib-pr/preview.mjs:*)
    - Bash(git fetch:*)
    - Bash(git rev-parse:*)
    - Bash(git branch:*)
    - Bash(git status:*)
    - Bash(git log:*)
    - Bash(git diff:*)
    - Bash(git show:*)
    - Bash(gh pr view:*)
    - Bash(gh pr list:*)
    - Bash(sed -n:*)
    - Read
    - Write
    - Glob
    - Grep
---

# RFLIB Pull Request Skill

Writes the PR description for the current branch so the maintainer can **approve from
the description alone**, then opens (or updates) the PR. The description starts with an
overview of the feature and then walks **bottom-up** through the solution — data model,
security & access, Apex services, integration, front end — showing the code that carries
each decision and pointing at the pieces that need a closer review in the code.

Two scripts do the mechanical parts; you do the understanding and the writing:

- `.claude/skills/rflib-pr/inventory.mjs` — read-only. Groups the branch's changes into
  the walkthrough's layers, flags review hotspots with GitHub permalinks, maps source to
  tests, and reports branch state (unpushed, behind, inherited commits, existing PR).
- `.claude/skills/rflib-pr/preview.mjs` — renders the draft through GitHub's own
  markdown API (the renderer PR bodies use) with GitHub's stylesheet and Mermaid, and
  serves it on `http://localhost:4799/` via the `rflib-pr-preview` launch configuration,
  re-rendered on every reload — so you can look at the PR exactly as reviewers will
  before anything is published.

The draft lives at **`.claude/skills/rflib-pr/out/pr-body.md`** — gitignored (all of
`.claude/` is), inside the repo so the user can open it in the editor, and the default
path both scripts and the launch configuration use.

All paths are relative to the repo root. Invoking this skill is the instruction to run
the read-only git commands below; **pushing and creating the PR still wait for the
user's go-ahead on the draft** (Step 6).

> **Order of skills:** `/rflib-cr` (best practices) → `/rflib-quality` (suite + goal
> verification) → `/rflib-pr`. The Testing section quotes `rflib-quality`'s results; if
> it has not run in this session, ask whether to run it first (~10+ min, may create a
> scratch org) or to open the PR with Testing stating plainly that it did not run.

---

## Step 0 — Inventory the branch

```bash
git fetch origin
node .claude/skills/rflib-pr/inventory.mjs
```

The default base is `origin/master` — what GitHub diffs the PR against. Pass
`--base <ref>` only for a PR that targets another branch.

Act on **Branch state** before writing anything:

| Inventory says                             | Do                                                                                                                                        |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Working tree **dirty**                     | Those paths will not be in the PR. Ask: commit them first, or leave them out.                                                             |
| **Inherited from unpushed local `master`** | Those commits ship in this PR. Ask the user: push `master` first (then re-run the inventory), or describe them in the PR too.             |
| **Behind** origin/master                   | Rebase (`git rebase origin/master`) — never merge master into the branch; the history stays linear. Ask before rewriting a pushed branch. |
| **Existing PR** open                       | Update its body in Step 6 instead of creating a new PR.                                                                                   |
| On `master`                                | Stop — there is nothing to open a PR from.                                                                                                |

Keep the inventory output; its layer tables, wiring, hotspots, and test map drive Steps 2–4.

## Step 1 — Understand the feature before describing it

1. **Read the commit messages in full** — the bodies in this repo are long and explain
   intent, trade-offs and limitations; they are your primary source:
    ```bash
    git log --no-merges --format='%h %s%n%n%b%n----' origin/master..HEAD
    ```
2. Read the `CHANGELOG.md` and `README.md` additions — the customer-facing framing the
   overview should agree with:
    ```bash
    git diff origin/master...HEAD -- CHANGELOG.md README.md
    ```
3. Pull in what this session already knows: the user's stated goals, decisions made
   during implementation, `rflib-quality`'s goal-verification table and suite numbers.

Answer for yourself, in one sentence each: what problem does this solve, for whom, what
can they do now that they could not before, and what is the one thing most likely to be
wrong.

## Step 2 — Read the change bottom-up

Walk the inventory's layers **in order**, reading each layer's diff before the next:

```bash
git diff origin/master...HEAD -- '*/objects/*' '*/customMetadata/*'
git diff origin/master...HEAD -- '*/permissionsets/*' '*/customPermissions/*'
git diff origin/master...HEAD -- '*/classes/*.cls' ':!*Test.cls'
git diff origin/master...HEAD -- '*/flows/*' '*/platformEventChannels/*'
git diff origin/master...HEAD -- '*/lwc/*' '*/aura/*' ':!*/__tests__/*' '*/flexipages/*' '*/tabs/*' '*/applications/*'
```

For new files over a few hundred lines, `Read` the whole file instead of the diff. For
every **hotspot** the inventory listed, open the file at that line and decide whether it
is real — the patterns are signals, not findings (a `SYSTEM_MODE` hit can be a log
label). Also note what the patterns cannot see: pagination/cursor math, ordering,
governor-limit arithmetic, caching (`cacheable=true`), race conditions in LWC state,
error paths that swallow exceptions.

For each snippet you will quote, record its **exact line range in HEAD** (`Read` the file
or `grep -n`); permalinks are `<Permalink base from the inventory><path>#L<start>-L<end>`.

## Step 3 — Write the description

Write the body with the **Write tool** to `.claude/skills/rflib-pr/out/pr-body.md` —
never inline in a shell `--body` argument. **Write each paragraph as one line**: PR
bodies render every newline as a line break (see Gotchas), so the hard-wrapped style of
this file would show up as ragged lines. Use this structure; **drop any layer section
the branch does not touch** (no "N/A" headings):

```markdown
## Overview

<2–4 sentences: the problem, who has it, what they can do now. Outcome first, mechanism
later. A reviewer who stops here must know what they are approving.>

- **Packages:** <RFLIB 11.4.0 — from the inventory; note any sfdx-project.json change>
- **Breaking changes:** <none | what breaks and for whom>
- **Admin action on upgrade:** <none | permission sets to assign, settings to create, …>

## How it fits together

<Only when 3+ layers are involved: a Mermaid diagram of the end-to-end path (who calls
whom, where data is read/written, where access is decided). Short participant labels
("Explorer LWC", "Controller") with the class names mapped in the prose below — full
class names shrink a 5-participant diagram to unreadable text. Follow it with 2–3
sentences narrating one request.>

## Walkthrough

### 1. Data model

<New/changed objects, fields, Big Objects, CMDT, Platform Events. For Big Objects state
the index and why — it cannot change after deploy. Field types, defaults, required.>

### 2. Security & access

<Permission sets, custom permissions, what each grants and who should get it. How the
code decides access (USER_MODE vs SYSTEM_MODE, sharing keyword, permission checks).>

### 3. Services & backend

<Apex classes by responsibility, not by file order. For each: its job, the public
surface (@AuraEnabled / @InvocableMethod / global), and the one or two decisions that
shaped it. Quote the code that carries those decisions.>

### 4. Integration & automation

<Flows, Platform Events, callouts, named credentials — and the front end → Apex wiring
from the inventory (which component calls which method, with what contract).>

### 5. Front end

<Components and their composition (parent → child, events up / properties down), App
Builder configuration (targetConfigs), tabs, flexipages, app navigation. What the user
sees and does, step by step.>

## Review hotspots

<The 3–7 places that deserve a reviewer's eyes in the code, ranked by risk. A numbered
list, not a table — a three-column table squeezes the explanation into a narrow column.
Each item: what the code does and what could be wrong, so the reviewer knows what to
look for before opening the file.>

1. **<Short name>:** [File.cls#L120-L168](permalink)
   <What the code does, one sentence.>
   **Look for:** <the specific risk, assumption, or question for the reviewer.>

## Decisions & trade-offs

<Alternatives that were considered and rejected, constraints the platform forced. Bold
lead-in per decision, as in the existing PRs.>

## Compatibility & upgrade

<Behaviour changes for installed orgs, metadata deletions, CHANGELOG entry it adds.>

## Testing

<Suite results from rflib-quality (Apex count, pass rate, org-wide and per-class
coverage, LWC test count, E2E specs, lint/flow scan), the source → test map, and what a
key test proves. Anything not run is stated as not run.>

## Known limitations

<What it deliberately does not do, and gaps that remain.>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Snippet rules**

- A snippet earns its place by carrying a decision a reviewer must agree with: an access
  check, a query shape, a state transition, a contract between layers. Not boilerplate,
  not DTOs, not tests.
- 5–25 lines, trimmed with `// ...`, fenced with the right language (`apex`, `js`,
  `html`, `xml` — GitHub highlights all four). Precede each with its permalink:
  `[rflib_X.cls#L40-L62](…)`.
- Two to five snippets for a typical feature. If the PR needs more, the walkthrough is
  narrating code instead of explaining it.

**Writing rules**

- Explain _why_ and _how it behaves_; the diff already says _what lines changed_.
- Use the project's terms (Ops Center, Log Archive, Global Setting, Application Event).
- Never list internal refactoring as a feature; describe it under the layer it touches.
- Title: the inventory's suggested conventional-commit title, rewritten if the branch
  does more than its lead commit says. Label: `enhancement` for `feat`, `bug` for
  `fix`, none otherwise.

## Step 4 — Check the permalinks

Spot-check every permalink range against HEAD — a range that drifted by a few lines
points the reviewer at the wrong code:

```bash
sed -n '<start>,<end>p' <path>
```

## Step 5 — Preview it as GitHub renders it

First the numbers — body length against GitHub's **65,536-character** limit, tables and
Mermaid diagrams rendered, and any raw `|` rows left from a broken table:

```bash
node .claude/skills/rflib-pr/preview.mjs
```

Then look at it. Start the `rflib-pr-preview` server with the browser pane's
`preview_start` tool (name `rflib-pr-preview`, defined in `.claude/launch.json`); it
opens `http://localhost:4799/`, and every reload re-renders the current draft, so edit
→ reload is the loop. Check that Mermaid rendered, then screenshot each section and
**look at it**:

```js
// javascript_tool on the preview tab — wait for Mermaid, then count what rendered
await new Promise((r) => setTimeout(r, 3000));
({
    mermaid: document.body.dataset.mermaid,
    diagrams: document.querySelectorAll('pre.mermaid svg').length,
    tables: document.querySelectorAll('table').length,
    apex: document.querySelectorAll('.highlight-source-apex').length
});
```

`mermaid` is `ok` or `error: <parser message>`. Scroll a heading into view before each
screenshot (`[...document.querySelectorAll('h2')].find((h) => h.textContent.includes('Review hotspots')).scrollIntoView()`).
Stop the server with `preview_stop` when done.

## Step 6 — Show the draft, then publish

Show the user the title, label, and the rendered preview (or the body), and ask for the
go-ahead. Only on a clear yes:

```bash
git push -u origin <branch>
gh pr create --repo j-fischer/rflib --base master --head <branch> --title "<title>" --label enhancement --body-file .claude/skills/rflib-pr/out/pr-body.md
```

For an existing PR, update instead:

```bash
gh pr edit <number> --repo j-fischer/rflib --body-file .claude/skills/rflib-pr/out/pr-body.md
```

Report the PR URL. Permalinks only resolve once the commit is pushed — open one after
pushing to confirm.

---

## Gotchas

- **`.claude/` is gitignored.** This skill, its scripts, the launch configuration and
  the draft exist only on this machine.
- **PR bodies render every newline as `<br>`.** `gh api markdown -f mode=gfm` (the PR
  renderer) turns `line one\nline two` into `line one<br>line two`; plain `markdown`
  mode does not. Write each paragraph on one line; inside a list item, a newline is a
  deliberate line break (the hotspot format relies on it).
- **Mermaid parse traps** (checked against mermaid 10.9.1, the version the preview
  loads — GitHub's own version may differ, so the preview is strong evidence, not
  proof): a `;` inside a sequence-diagram message ends the statement and breaks the
  whole diagram — write `#59;` or rephrase; flowchart node labels with parentheses
  must be quoted (`A["queryChunk(config)"]`). Parentheses in a `participant … as`
  alias are fine.
- **The browser pane cannot screenshot `file://` pages** (it shows them as a static
  snapshot that page tools refuse), which is why the preview is served on localhost.
- **Someone else may be editing the working tree.** Re-run the inventory right before
  publishing: if it reports a dirty tree you did not cause, ask whether those changes
  belong in the PR — committing them changes the HEAD SHA every permalink embeds.
- **Local `master` can be ahead of `origin/master`.** A branch cut from an unpushed
  local master carries those commits into the PR. That is why the base is
  `origin/master`, and why the inventory lists _inherited_ commits separately and leaves
  them out of the suggested title.
- **Renames show as deleted + added** (`--no-renames`) on purpose: in Salesforce a
  renamed metadata file deletes the old component in installed orgs.
- **`rflib_SOQL` switches access mode with `.systemMode()`**, not a `SYSTEM_MODE`
  literal — the inventory catches both. A change to `rflib_SOQL.cls` itself is the
  vendored SOQL library being upgraded; it is flagged once, not line by line.
- **`@AuraEnabled` is flagged on methods only** — the annotation also decorates every
  DTO property, which would drown the hotspot list.
- **Permalinks embed the HEAD SHA.** Any amend or rebase after drafting changes it:
  re-run the inventory and regenerate the links before publishing.
- **Never pass the body through a shell string.** Snippets contain `` ` ``, `$` and
  `\n`, which PowerShell and Bash heredocs rewrite (a heredoc here turned `'\n'` into a
  real line break). Write the file with the Write tool and use `--body-file`.
- **Screenshots:** if the branch commits PNGs under `screenshots/` (via `/rflib-docs`),
  they can be embedded with `<Permalink base>screenshots/<file>.png?raw=true`. Not yet
  exercised — check the image renders after pushing.
