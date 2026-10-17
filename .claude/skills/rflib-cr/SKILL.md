---
name: rflib-cr
description: >
    Use this skill to review the code of an in-progress implementation against
    RFLIB's curated best practices, right before running rflib-quality. It reviews
    the uncommitted working-tree changes (staged + unstaged), checks them against
    generic, Apex, and JavaScript best-practice checklists, and auto-fixes the
    violations it finds. Trigger phrases include: "review the code", "code review",
    "rflib cr", "review my changes", "check best practices", or any request to
    review an implementation before committing or running quality checks.
version: 1.0.0
user-invocable: true
disable-model-invocation: false
allowed-tools:
    - Bash(git rev-parse:*)
    - Bash(git branch:*)
    - Bash(git status:*)
    - Bash(git diff:*)
    - Bash(git log:*)
    - Bash(git show:*)
    - Read
    - Edit
    - Glob
    - Grep
---

# RFLIB Code Review Skill

Reviews the **uncommitted changes** in the working tree against RFLIB's curated
best practices and **auto-fixes** the violations it finds. Run this at the **end
of an implementation, before `rflib-quality`** — it catches best-practice issues
while the code is still uncommitted, so the quality suite runs against
already-cleaned code.

> **Relationship to other skills:** This skill is a _best-practice_ review against
> the checklists below — it is not the test suite. `rflib-quality` (run _after_
> this) deploys, runs Apex/LWC/E2E tests, and verifies goals. The generic
> `/code-review` skill hunts for correctness bugs in the diff; `rflib-cr` instead
> enforces RFLIB's specific conventions and auto-fixes them.

> **Scope:** Review only the **uncommitted working-tree changes** (staged +
> unstaged). Do not review code outside the diff except as needed to understand a
> changed line (e.g. reading a caller to confirm a convention).

---

## Step 1 — Establish the Change Set

Determine exactly which lines are under review. Only these are in scope.

1. Confirm there are uncommitted changes:
    ```bash
    git status --short
    ```
2. Capture the full working-tree diff (staged and unstaged):
    ```bash
    git diff HEAD
    ```
3. Build the list of changed files and, for each, the changed line ranges. Group
   them by type so the right checklist applies:
    - **Apex** — `*.cls`, `*.trigger`
    - **JavaScript / LWC** — `*.js` (component logic and `__tests__/*.test.js`)
    - **Everything else** — metadata, flows, markdown, config (generic checklist
      only)

If there are **no uncommitted changes**, tell the user there is nothing to review
and stop (suggest they may have meant to review a committed branch — outside this
skill's scope).

---

## Step 2 — Review Against Best Practices

For each changed file, read the surrounding context as needed and evaluate the
changed lines against the applicable checklists below. Record each violation as a
finding: `file:line`, the best practice it breaks, and the concrete fix.

Apply the checklists in this order: **Generic** to everything, then **Apex** to
Apex files, then **JavaScript** to JS/LWC files.

When unsure, ask the user for guidance.

### Generic Best Practices

> Follow clean code best practices of abstractions, keeping methods small, avoiding duplication, and adhering to the repo's style.
> Be mindful of indentation, naming conventions, and consistency with existing code. Look for any anti-patterns or common pitfalls in the changed code, such as hardcoded values, lack of error handling, or inefficient algorithms.
> Make the code as immutable as possible. Avoid reassigning variables; instead, create new ones when transformations are needed. This leads to clearer and more predictable code.

### Apex Best Practices

> Only use `@TestVisible` annotations on private members (including static), never on methods.
> Unit tests should be testing behavior, not implementation details. Avoid overusing `@TestVisible` to expose private state; instead, test through public methods.
> Inheritance is ok when there is a lot of internal reusable functions and clear polymorphism, but avoid it when it's just to share a few lines of code. In those cases, prefer composition or utility classes.
> It's good practice to extract reusable code into private methods, but if it's only called once, it's often clearer to keep it inline. Use judgment to balance readability and reusability.
> It's good practice to extract services and use dependency injection, though in Apex it makes sense to assign external dependencies to a private static member variable and reference that throughout the class, rather than passing them through constructors or multiple layers of method parameters.
> Keep method parameters to a reasonable number (ideally 3 or fewer) to maintain readability. If you find yourself needing to pass many parameters, consider if some of them can be grouped into a class or if the method is doing too much.
> Ensure test classes mirror the class under test exactly in naming and structure.  
> Follow RFLIB's specific naming conventions for classes, triggers, custom objects, fields, and CMDT.

### JavaScript Best Practices

> Prefer `const` and `let` over `var` for variable declarations to ensure block scope and prevent hoisting issues.
> Use Promises and async/await for asynchronous operations to improve readability and error handling.
> In Aura, use promises instead of callbacks to handle asynchronous operations, and ensure proper cleanup of event listeners to prevent memory leaks. In LWC, leverage the reactive nature of properties and use lifecycle hooks appropriately.
> Follow RFLIB's specific naming conventions for LWC components and tests.

---

## Step 3 — Auto-Fix the Findings

For every finding from Step 2, apply the fix directly with the Edit tool:

1. Make the **minimal, surgical** change that resolves the violation — touch only
   the lines tied to the finding. Do not refactor adjacent code, restyle, or fix
   pre-existing issues outside the change set (see the repo's Surgical Changes
   guideline).
2. Match the existing style of the file.
3. If a finding **cannot** be auto-fixed safely (ambiguous intent, would change
   behavior, needs a decision), do **not** guess — leave it and flag it for the
   user in Step 4.
4. Re-read each edited region to confirm the fix is correct and self-consistent
   (e.g. an extracted constant is referenced everywhere, an added null check
   compiles).

---

## Step 4 — Report

Summarize the review:

```
RFLIB code review complete — <N> files reviewed

Auto-fixed (<X>):
  • <file:line> — <best practice> — <what was changed>
  ...

Needs your decision (<Y>):
  • <file:line> — <best practice> — <why it wasn't auto-fixed / options>
  ...

No issues found in: <files with no findings>
```

If everything was clean, say so plainly. End by recommending the next step:

> Changes look clean against the best-practice checklists. Run `/rflib-quality`
> to validate with the full test suite.

If any findings were left for the user (Step 3.3), do **not** recommend proceeding
to `rflib-quality` until they are resolved.
