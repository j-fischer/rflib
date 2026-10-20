# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RFLIB (Reliability Force) is a Salesforce open-source library providing logging, feature switches, and a trigger framework. It is published as 4 modular unlocked packages with their own versioning and dependency chains.

## Commands

### LWC / JavaScript Tests

```bash
npm run test:unit                # Run all LWC Jest tests
npm run test:unit:coverage       # Run with coverage report
npm run test:unit:watch          # Watch mode
npm run lint                     # Lint LWC, Aura, and Node.js code
npm run lint:lwc                 # Lint LWC components only
npm run prettier                 # Auto-format all supported files
npm run cspell                   # Spell check all source files
```

### Apex Tests (requires authenticated Salesforce org)

```bash
sf apex run test -o <org-alias> --code-coverage                # Run all Apex tests
sf apex run test -o <org-alias> -n <TestClassName>             # Run a single test class
sf project deploy start -o <org-alias> -w 25                   # Deploy source to scratch org
gulp test                                                      # Run full end-to-end test suite for front and backend
```

### Package Management (Gulp)

Package management will be done manually. Do not automate that step.

### Code Review (Skill)

At the **end of an implementation, before running `rflib-quality`**, review the
changes with the `rflib-cr` skill (`.claude/skills/rflib-cr/SKILL.md`). Invoke it
with `/rflib-cr`. It reviews the **uncommitted working-tree changes** (staged +
unstaged) against RFLIB's curated best-practice checklists (generic, then Apex,
then JavaScript) and auto-fixes the violations it finds, flagging anything that
needs a decision rather than guessing. It is a best-practice review only — it runs
no tests; that is `rflib-quality`'s job. Run `rflib-cr` first to clean the code,
then `rflib-quality` to validate it.

### Quality Validation (Skill)

Before committing or opening a pull request, validate the branch with the
`rflib-quality` skill (`.claude/skills/rflib-quality/SKILL.md`). Invoke it with
`/rflib-quality`. It runs the full `gulp test` suite (deploy → Apex tests → lint →
flow scan → LWC tests) plus the Playwright E2E suite against a scratch org,
creating one if none exists, and auto-fixes failures it finds. It then verifies
the branch's changes against their stated goals (from commit messages, or changes
since the last tag when on `master`, plus goals raised in the session) — not just
that the suite is green. Claude may invoke it as part of a plan, but be mindful:
each run can create a scratch org (DevHub daily limit) and takes ~10+ minutes, so
prefer running it when changes are ready to validate rather than repeatedly.

### Pull Requests (Skill)

Open or update a pull request with the `rflib-pr` skill
(`.claude/skills/rflib-pr/SKILL.md`), invoked with `/rflib-pr`, after `rflib-quality`.
It writes a description the PR can be approved from alone: a feature overview, then a
bottom-up walkthrough (data model → security → Apex services → integration → front
end) with the critical code snippets and the review hotspots, all linked to the code by
permalink. Its `inventory.mjs` sorts the branch's changes into those layers and flags
risky code; `preview.mjs` renders the draft the way GitHub will. It pushes and creates
the PR only after the user approves the draft.

## Architecture

### Package Structure and Dependencies

The repo contains 4 unlocked Salesforce packages, each in its own top-level directory:

| Package      | Directory       | Description                               | Depends On      |
| ------------ | --------------- | ----------------------------------------- | --------------- |
| RFLIB        | `rflib/`        | Core logging framework (default package)  | —               |
| RFLIB-FS     | `rflib-fs/`     | Feature Switches via Custom Metadata      | RFLIB           |
| RFLIB-TF     | `rflib-tf/`     | Trigger Framework + Retryable Actions     | RFLIB, RFLIB-FS |
| RFLIB-PHAROS | `rflib-pharos/` | Pharos AI integration via Platform Events | RFLIB           |

Each package directory follows the standard SFDX layout: `<package>/main/default/` for source and `<package>/test/default/` for test classes.

Agent-driven debugging (reading log archives, application events, and logger settings, and tuning logger settings) is not a package in this repo. It is provided by the `sf rflib debug` commands of the RFLIB CLI plugin ([j-fischer/rflib-plugin](https://github.com/j-fischer/rflib-plugin)).

### Core Logging Framework (`rflib/`)

The logging system uses a **buffer-and-publish pattern**:

- Log statements are buffered in-memory per transaction
- When a threshold log level is reached, all buffered logs are published as a `rflib_Log_Event__e` Platform Event
- Subscribers archive logs to `rflib_Logs_Archive__b` (Big Object) for long-term storage
- Configuration is driven by `rflib_Logger_Settings__c` Custom Settings (hierarchical: org-wide, profile, user)

Key Apex classes:

- `rflib_Logger` — interface; `rflib_DefaultLogger` — implementation
- `rflib_LoggerFactory` / `rflib_DefaultLoggerFactory` — factory for creating logger instances
- `rflib_ApplicationEventService` — logs named application events to `rflib_Application_Event__c`
- `rflib_LogEventHandler` — Platform Event subscriber that archives logs
- `rflib_BigObjectDatabaseExecutor` — abstraction over Big Object DML
- `rflib_BigObjectQueryController` / `rflib_DefaultBigObjectQueryService` — validate a Big Object Explorer configuration and read a Big Object in chunks, always in user mode

Key LWC components:

- `rflibLogger` — client-side logger for LWC; mirrors Apex API
- `rflibLogEventMonitor` — real-time log event viewer
- `rflibPermissionsExplorer` — dashboard for object/field/Apex permissions
- `rflibBigObjectExplorer` — configurable explorer for any Big Object; backs the Application Event Archive tab
- `rflibPaginator` — shared pagination controls (page number box, rows per page) used by the Ops Center lists

### Feature Switches (`rflib-fs/`)

Feature flags stored as `rflib_Feature_Switch__mdt` Custom Metadata records. Supports hierarchical overrides (org → profile → user) via `rflib_FeatureSwitchService`. Accessible from Apex, LWC (`rflibFeatureSwitches`), and Flow.

### Trigger Framework (`rflib-tf/`)

- `rflib_TriggerManager` reads `rflib_Trigger_Config__mdt` records to dynamically instantiate and order `rflib_TriggerHandler` implementations
- `rflib_RetryableActionManager` / `rflib_RetryableActionHandler` — asynchronous retry pattern using Platform Events
- `rflib_SingleRunOnlyTriggerHandler` — utility base class for preventing trigger recursion

## Naming Conventions

- **Apex classes**: `rflib_<Feature><Type>.cls` — e.g., `rflib_ApplicationEventService`, `rflib_BigObjectStatController`, `rflib_LogEventHandler`
- **Test classes**: `<ClassName>Test.cls` — must mirror the class under test exactly
- **LWC components**: camelCase starting with `rflib` — e.g., `rflibLogger`, `rflibLogEventMonitor`
- **Custom objects/fields**: `rflib_<Name>__c` / `rflib_<Name>__b` (Big Objects) / `rflib_<Name>__mdt` (CMDT) / `rflib_<Name>__e` (Platform Events)

## Key Development Notes

- **Do not use git commands** unless explicitly instructed.
- **Code coverage must stay above 90%** for all Apex classes.
- **LWC Jest tests** live in `__tests__/` subdirectories alongside component files.
- **Source API version**: 65.0 (defined in `sfdx-project.json`).
- **@TestVisible**: Annotation can only be used on private members (static included), not ever on any methods.
- **Ops Center controllers enforce the caller's permissions on the server.** Hiding a control in the LWC is not access control: any holder of `rflib_Ops_Center_Access` can call the Aura methods directly. Check object access with a describe call and write with `AccessLevel.USER_MODE`; where the platform has no permission to check (e.g. scheduling Apex), restrict to an allow-list such as the `Ops_Center_Schedulable_Classes` Global Setting.
- Pre-commit hooks run Prettier, ESLint, and CSpell via Husky + lint-staged — run `npm run prettier` before committing if formatting issues appear.
- RFLIB-PHAROS intentionally has **no direct package dependency** on RFLIB; the integration is event-driven through `rflib_Log_Event__e`.

## Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
