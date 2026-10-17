---
name: rflib-quality
description: >
    Use this skill when the user wants to run quality checks, pre-commit
    validation, or full test suite for the rflib repository before committing
    or creating a pull request. It both runs the suite (gulp test + E2E) AND
    verifies the branch's changes actually meet their stated goals (from commit
    messages or the current session). Trigger phrases include: "run quality
    checks", "check before committing", "run tests", "validate my changes",
    "pre-commit check", "rflib quality", "gulp test", or any request to verify
    the branch is ready to commit.
version: 1.2.0
user-invocable: true
disable-model-invocation: false
allowed-tools:
    - Bash(sf org display:*)
    - Bash(sf org list:*)
    - Bash(sf apex run:*)
    - Bash(sf data query:*)
    - Bash(gulp test:*)
    - Bash(gulp test-e2e:*)
    - Bash(gulp create-scratch:*)
    - Bash(npm run:*)
    - Bash(git rev-parse:*)
    - Bash(git branch:*)
    - Bash(git status:*)
    - Bash(git log:*)
    - Bash(git diff:*)
    - Bash(git show:*)
    - Bash(git describe:*)
    - Bash(git tag:*)
    - Read
    - Edit
    - Glob
    - Grep
---

# RFLIB Quality Control Skill

Validates a branch in two complementary ways:

1. **It works correctly** — runs the full test suite (`gulp test`) followed by the
   Playwright end-to-end UI suite (`gulp test-e2e`) against a Salesforce scratch
   org, fixing any deployment errors or test failures before re-running.
2. **It does what it set out to do** — verifies the branch's actual changes
   against their stated goals (from commit messages and the current session), so a
   green suite is never mistaken for "the feature is correct and complete."

If no default scratch org exists, creates one first with `gulp create-scratch`.
Use `gulp` tasks before running CLI commands directly — this ensures all necessary
setup and configuration is applied and provides a consistent interface for
monitoring progress and output. Follow the step-by-step process below to ensure
your branch is fully validated and ready to commit.

> **Note:** `gulp test` does **not** include the E2E suite — E2E runs as a
> separate `gulp test-e2e` invocation (Step 6) only after the main suite is green.

> **Why goal verification matters:** the suite proves nothing _broke_; it does not
> prove the change _delivers what it claims_. Step 0 captures the goals and Step 7
> checks the implementation against them — including edge cases named in commit
> messages that may lack a test.

---

## Step 0 — Establish the Change Set and Goals

Before running any checks, determine **what changed** and **why**, so the run can
verify the implementation against its goals in Step 7 — not just that the suite is
green.

1. Identify the current branch:
    ```bash
    git rev-parse --abbrev-ref HEAD
    ```
2. Determine the change set and its commit messages:
    - **Feature branch** (anything other than `master`): compare against `master`:
        ```bash
        git log --no-merges master..HEAD
        git diff --stat master...HEAD
        ```
    - **On `master`**: compare against the most recent tag:
        ```bash
        git describe --tags --abbrev=0
        git log --no-merges <tag>..HEAD
        git diff --stat <tag>..HEAD
        ```
        If there is no tag (`git describe` fails), fall back to `origin/master..HEAD`
        (or the last few commits) and note the fallback in the final report.
3. Read the **full commit messages** for the change set (`git show <sha>` as
   needed), capturing every stated goal, fix, and behavioral guarantee — including
   specific claims like size limits, edge-case handling, or backward compatibility.
4. Add any goals stated **in the current session** — the user's requests, a plan
   file under `.claude/plans/`, or explicit acceptance criteria discussed. Session
   goals take precedence when they extend or conflict with the commit messages.
5. Produce a concise, numbered **Goals checklist**, each item a single verifiable
   statement (e.g. "App Insights items never exceed the 64 KB cap", "OTel
   forwarding bounds callouts by serialized byte size", "existing HTTP callout
   behavior is unchanged"). This checklist drives Step 7 — keep it for later.

If the change set is empty or cannot be determined, tell the user and ask how to
scope the verification before proceeding.

---

## Step 1 — Detect Default Scratch Org

Run:

```bash
sf org display --json 2>/dev/null
```

Parse the JSON output:

- **Success** (`result.status` is `Active`): extract `result.alias`. Proceed to Step 2 using this alias.
- **No default org / error**: proceed to Step 3 (create scratch org).

If the org exists but `result.status` is not `Active` (e.g., expired), inform
the user:

> The default scratch org (`<alias>`) has expired. A new one will be created.

Then proceed to Step 3.

---

## Step 2 — Run Tests Against Existing Org

Run the full quality suite using the detected alias:

```bash
npx gulp test --alias <alias>
```

`gulp test` performs these steps in order:

1. **Deploy** (`sf project deploy start -o <alias> -c`) — pushes all source
2. **Apex tests** (`sf apex run test -l RunLocalTests -c -r human -o <alias> -w 4 --concise`)
3. **Lint** (`npm run lint`)
4. **Flow scan** (Lightning Flow Scanner on `rflib/main/default/flows`)
5. **LWC tests** (`npm run test:unit:coverage`)

Proceed to Step 4 to monitor output.

---

## Step 3 — Create New Scratch Org

When no valid default org exists, run:

```bash
npx gulp create-scratch --alias rflib
```

**Recommended alias: `rflib`** — this matches the DevHub configuration and is the
default used throughout the project.

`gulp create-scratch` will:

1. Create a 30-day scratch org with the given alias (set as default)
2. Push all source
3. Assign permission sets (`rflib_Ops_Center_Access`, `rflib_Create_Application_Event`)
4. Configure custom settings
5. Create sample log and application events
6. Create a QA user
7. Install the Big Object utility package
8. Run Apex tests and LWC tests

After `create-scratch` completes successfully, the org is ready. Proceed to
Step 2 to run `gulp test` for the final validation pass.

---

## Step 4 — Analyze Output and Fix Errors

After each `gulp test` run, scan the full console output for these failure
categories. Work through them in order:

### Category A — Deployment Errors

Indicators:

- `Error` lines with file paths (e.g., `force-app/main/default/classes/...`)
- `Deployment failed`
- `COMPILE ERROR`
- Lines containing `unexpected token`, `Variable does not exist`, `Method does not exist`

**Fix process:**

1. Identify the file and line number from the error message.
2. Read the file with the Read tool.
3. Diagnose the compile error (type mismatch, missing method, missing import, etc.).
4. Edit the file to fix the error.
5. Do not re-run until all identified compile errors are addressed.

### Category B — Apex Test Failures

Indicators:

- Lines starting with `Fail` or containing `FAILED`
- `Test failures` count > 0 in the summary
- Lines like `<ClassName>.<methodName> FAILED`

**Fix process:**

1. Read the failing test class to understand the assertion.
2. Determine if the production class or the test is wrong:
    - If the production logic is wrong, fix the production class.
    - If the test assertion is overly strict or uses stale data, fix the test.
3. Verify code coverage stays above 90% across all classes.
4. Fix all failures before re-running.

### Category C — LWC / Jest Test Failures

Indicators:

- `FAIL <path>/__tests__/<component>.test.js`
- `● <TestSuite> › <testName>`
- `Expected ... to equal ...` or similar Jest assertion output
- `Tests: X failed` in the Jest summary

**Fix process:**

1. Read the failing `__tests__/*.test.js` file.
2. Read the component's `.js` file to understand the current implementation.
3. Fix either the component or the test depending on which is incorrect.
4. Check for missing mock setup (`@wire` mocks, `jest.mock()` calls) if the error
   is about undefined properties.

### Category D — Lint Errors

Indicators:

- `error` lines from ESLint (e.g., `no-unused-vars`, `no-undef`)
- Exit with `ESLint found too many warnings`

**Fix process:**

1. Read the file identified in the lint error.
2. Apply the minimal change to resolve the lint rule.
3. Do not disable lint rules with `/* eslint-disable */` unless the rule is a
   false positive and the disabling is scoped to the specific line with a comment.

### Category E — Flow Scan Errors

Indicators:

- `Flow scan failed with X errors`
- Error lines referencing specific Flow names

**Fix process:**
Inform the user of the specific flow and error — flow fixes require manual action
in the Salesforce UI. Describe what was found and stop.

### Category F — Playwright E2E Failures

These come from the `gulp test-e2e` run in Step 6, not from `gulp test`.

Indicators:

- `✘` or `failed` lines in the Playwright `list` reporter output
- `<n> failed` in the run summary
- `Error: expect(...)` / `Timeout ... exceeded` / `locator ... not found`
- A spec path like `e2e/specs/<NN>-<name>.spec.ts:<line>`

**Fix process:**

1. Read the failing spec in `e2e/specs/` and the page object it uses in
   `e2e/pages/*.page.ts`; helpers live in `e2e/helpers/`.
2. Determine whether the failure is a **real regression** (the app/component
   changed and the spec correctly caught it) or a **test/timing issue**:
    - Real regression → fix the production code (LWC/Apex) under test.
    - Stale selector or assertion → fix the spec or page object.
3. **Beware flakiness.** The suite runs serially (`workers: 1`) with `retries: 1`
   and depends on shared scratch-org state. Platform-event processing and Big
   Object archive writes can lag minutes in scratch orgs, so a spec may fail on
   a slow poll rather than a real bug. If a failure looks timing-related, re-run
   `gulp test-e2e` once before changing code. Prefer fixing the spec's polling
   (`e2e/helpers/polling.ts`) over adding fixed sleeps.
4. Spec ordering matters — numeric prefixes (`01`–`08`) are intentional because
   later specs (e.g. `05-log-archive`) destroy data earlier specs created. Do
   not reorder or run specs in isolation when diagnosing cross-spec failures.
5. On failure, Playwright writes a trace/screenshot/video; point the user to
   `npm run test:e2e:report` to open the HTML report for visual diagnosis.

If a failure cannot be resolved automatically (org data state, license limits,
async lag that persists across re-runs), describe what was found and what manual
action is required, then stop.

---

## Step 5 — Re-run After Fixes

After fixing all errors from Step 4:

```bash
npx gulp test --alias <alias>
```

Repeat Steps 4–5 until the output shows all stages passing:

```
[<timestamp>] Finished 'shell-force-push' after ...
[<timestamp>] Finished 'shell-force-test' after ...
[<timestamp>] Finished 'shell-lint' after ...
[<timestamp>] Finished 'scan-flow' after ...
[<timestamp>] Finished 'shell-test-lwc' after ...
[<timestamp>] Finished 'test' after ...
```

Once the main suite is fully green, proceed to Step 6 to run the E2E suite.

---

## Step 6 — Run Playwright E2E Tests

The E2E suite is a **separate gulp task** that drives the real Lightning UI of
the scratch org. Run it only after the main `gulp test` suite passes, using the
same alias:

```bash
npx gulp test-e2e --alias <alias>
```

`gulp test-e2e` resolves the org alias and runs the Playwright suite
(`e2e/specs/*.spec.ts`) headless against that org via frontdoor auth, setting
`RFLIB_E2E_TARGET_ORG=<alias>`. The suite expects the org to be configured with
the perm sets, custom settings, sample events, and QA user that
`gulp create-scratch` provisions — if those are missing (e.g. a bare org), the
specs will fail in setup; create or re-provision the scratch org via Step 3.

After the run, analyze output for **Category F — Playwright E2E Failures**
(Step 4) and fix as needed. Re-run `npx gulp test-e2e --alias <alias>` until all
specs pass:

```
<n> passed (<duration>)
```

Once all specs pass, proceed to Step 7 to verify the change against its goals.

---

## Step 7 — Verify Implementation Against Goals

A green suite proves nothing _broke_; it does **not** prove the change does what
it claims. For each item in the **Goals checklist** from Step 0, confirm the
implementation actually delivers it.

For each goal:

1. **Locate the implementation** in the change set and read the relevant code:
    ```bash
    git diff master...HEAD -- <path>      # or <tag>..HEAD on master
    ```
2. **Confirm the behavior** using the strongest evidence available, in this order:
    - A dedicated automated test that asserts the goal — name the test method.
      Prefer this; if a stated goal (especially an edge case named in a commit
      message) has no test, that is itself a gap to fix.
    - A targeted **runtime check** against the scratch org when static inspection
      is insufficient — anonymous Apex that exercises the path plus a query to
      confirm the result:
        ```bash
        sf apex run --file <script>.apex -o <alias>
        sf data query -o <alias> --query "<SOQL>"
        ```
    - Code inspection alone, only when the goal is purely structural.
3. **Hunt for gaps**: claims the code does not actually enforce, edge cases without
   coverage, goals only partially met, or backward-compatibility guarantees that
   the diff silently breaks.

Record a goal-by-goal result:

| #   | Goal (from commit / session) | Evidence                               | Status                       |
| --- | ---------------------------- | -------------------------------------- | ---------------------------- |
| 1   | <goal text>                  | <test name / query result / file:line> | Verified / Partial / Not met |

If any goal is **Partial** or **Not met**, treat it like a test failure: fix the
implementation (or add the missing test), re-run the affected checks (Steps 2–6),
and re-verify. Only continue when every goal is **Verified** or the user has
explicitly accepted a documented gap.

---

## Step 8 — Report Results

When all stages — including E2E and goal verification — pass, summarize:

```
Quality checks passed on org: <alias>

✓ Source deployed
✓ Apex tests passed  (X tests, Y% coverage)
✓ Lint clean
✓ Flow scan clean
✓ LWC tests passed  (X tests)
✓ E2E tests passed  (X specs)
✓ Goals verified    (X/X goals from <N> commits / session)

Goal verification:
  1. <goal> — Verified (<evidence>)
  2. <goal> — Verified (<evidence>)
  ...

Branch is ready to commit.
```

If any stage could not be fixed automatically (e.g., flow scan errors, missing
test data, org configuration issues) or any goal remains **Partial / Not met**,
clearly state what was attempted, what gap remains, and what manual action is
required.

---

## Error Reference

| Output Pattern                        | Category | Likely Cause                                                |
| ------------------------------------- | -------- | ----------------------------------------------------------- |
| `Variable does not exist`             | A        | Missing field or incorrect API name                         |
| `Method does not exist`               | A        | Wrong method signature or missing class                     |
| `COMPILE ERROR`                       | A        | Syntax or type error in Apex                                |
| `<Class>.<method> FAILED`             | B        | Failing Apex test assertion                                 |
| `Insufficient code coverage`          | B        | Test coverage dropped below 75%                             |
| `FAIL __tests__/`                     | C        | Failing Jest test                                           |
| `Cannot read properties of undefined` | C        | Missing wire mock in test                                   |
| `no-unused-vars`                      | D        | Declared but unused JS variable                             |
| `no-undef`                            | D        | Reference to undefined variable                             |
| `Flow scan failed`                    | E        | Flow scan error — requires manual fix                       |
| `✘ ... e2e/specs/...spec.ts`          | F        | Failing Playwright spec — real regression or stale selector |
| `Timeout ... exceeded` (E2E)          | F        | Async lag / slow poll — re-run before changing code         |
| `locator ... not found`               | F        | UI changed or stale page-object selector                    |
| `org expired` / `Unable to find org`  | —        | Re-run Step 3 to create new scratch org                     |
