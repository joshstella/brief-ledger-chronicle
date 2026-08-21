---
name: review-pr
description: >-
  Review a staged diff or PR against the governing brief and project rules. Use when the user asks for review-pr or a pre-merge review.
---

# review-pr

Review a change for correctness, intent, and fitness against my cross-project preferences **before it merges**. This review can BLOCK: a `Request changes` verdict means do not commit / do not push / do not merge.

Usage: review-pr [PR number | --staged]
- **PR number** → review that PR's diff.
- **--staged** (or no argument when staged changes exist) → review the staged, not-yet-committed diff. This is the mid-chain mode called by `commit-push-pr`.
- **no argument, nothing staged** → review the current branch's open PR; if there is none, review the current branch against the default branch.

---

## What this review can and can't do — read first

This review certifies a **mechanical floor**, not that a change is *right*. Keep three states visibly separate in the output and never collapse them into a single verdict:

- **Verified** — what was actually checked and stands: tests ran and passed, types hold, no injection vectors, the diff stayed in the brief's scope. This is what `Approve` covers — and *only* this.
- **Couldn't verify** — what's visible but can't be vouched for. The canonical case: tests that pass without it being confirmable that they assert the behavior the change introduces. A green suite is not evidence of coverage. Naming these is **required output**, not a failure of the review — a review claiming it verified everything is itself suspect.
- **Your call** — what can't be adjudicated here because it needs context this review doesn't have: does the change match what the ticket/brief actually wanted, should a team-binding change apply broadly, is this the right architecture. Raise these precisely; do **not** answer them.

Discipline that keeps this useful: every **Couldn't verify** and **Your call** item must point at a specific file and line and state, concretely, what couldn't be confirmed and why. A generic disclaimer ("can't be sure of runtime behavior") is banned — it's noise that trains skimming. Scarce, located, specific flags stay credible; vague ones destroy the signal.

---

## My preferences (cross-project)
<!-- Add, remove, or edit entries here at any time. These apply to EVERY project. -->
<!-- Project-specific architecture rules do NOT go here — they live in each repo's AGENTS.md or CLAUDE.md (read in step 3), so this command stays reusable across projects. -->

**Types**
- Strongly typed at every boundary. No `any`. Explicit named exported interfaces — never inferred or implicit return types on public functions.
- Generate types from schemas (JSON Schema, DB schema) rather than hand-writing parallel interfaces that can drift.

**Modules**
- Real TypeScript modules with exported types. No logic buried in `<script>` tags or inline scripts.
- Server-side and client-side code clearly separated. Don't mix concerns across that boundary.

**Comments**
- Comment the *why*, not the *what*. A non-obvious constraint, invariant, or workaround is worth a comment. What the code does is already in the code.
- No multi-paragraph docstrings. No task-reference comments ("added for issue #123") — those belong in the commit message.

**Scope**
- No speculative abstractions. Three similar lines is fine; a premature helper is not.
- No error handling or validation for scenarios that can't happen. Trust internal guarantees; validate only at system boundaries.
- Bug fixes don't need surrounding cleanup. Stay in scope.

**Tests**
- Merge-bound code needs tests — unit for logic, integration across boundaries — that run and pass. Missing tests on code headed for `main` is a blocking finding (see the verdict rule in step 6), not a nitpick.
- Passing is not covering. A test that runs green without exercising the changed behavior is a **Couldn't verify**, not a pass — see the test-adequacy check in step 4.
- The only pass without tests is an explicit, stated exemption — pure config, generated boilerplate, or a throwaway branch that won't merge. The exemption must be declared ("test-exempt because…" in the PR's `## Test plan`, or stated aloud when the gate runs mid-chain), never a silent gap.
- Don't author the missing tests yourself and then pass the diff — the same rule as not fix-and-self-clearing your own bug findings. The gate is for the human to clear.

**Security**
- No command injection, SQL injection, or XSS vectors.
- No secrets, tokens, or credentials in code or committed files.

---

## Steps

1. **Resolve the review target** per Usage above and fetch the diff:
   - PR: `gh pr diff <number>`, and `gh pr view <number>` for title/description.
   - staged: `git diff --staged`.
   - branch: `git diff <default-branch>...HEAD`.

2. **Read the governing brief — this is what gives the review teeth on judgment, not just defects.**
   - Find it: from the PR body's `## Brief` line if reviewing a PR; otherwise match the feature/branch name against `docs/briefs/`, `briefs/`, `docs/`.
   - If found, read its **settled** decisions, its **open** decisions, and which phase this change belongs to.
   - If none is found, note "no governing brief" and review on preferences + AGENTS.md/CLAUDE.md alone — but say so, and treat intent as a **Your call** item, since it can't be checked.

3. **Read the repo `AGENTS.md` or `CLAUDE.md`** (whichever exists; root, and any subdirectory governing the touched files) for project-specific architecture rules. These are the project's own gates; apply them on top of the cross-project preferences above.

4. **If the diff touches visual surfaces, read the design doc.**
   Visual surfaces: any `.css` file, `src/theme/`, files with inline `style=` strings, `src/ui/` components, or any HTML shell.
   - Read `docs/design/visual-language.md` — focus on **§9 (the Invariant Index)**, which is the complete machine-checkable ruleset.
   - `[defect]` rules are a **hard gate**: a violation blocks the same as a type error or missing test.
   - `[judgment]` rules surface as **Your call** items — never block on their own, always named.
   - If the diff edits `docs/design/visual-language.md` itself, flag it explicitly as a **policy-class change** (per CLAUDE.md: every theme and future surface inherits from it) — this requires explicit human acknowledgment in the review, not just an Approve.
   - If no visual surface is touched, skip this step entirely.

5. **Review the diff against these axes, in order — and tag each finding with its epistemic state (verified / couldn't-verify / your-call):**
   - **Correctness** — real bugs. This is what self-review is strongest at; spend the most here.
   - **Test adequacy — not just presence.** Confirm tests exist and pass, then go further: do they actually assert the behavior *this diff* changes? Flag passing-but-hollow tests at the line — tautological assertions, the changed logic mocked away, snapshot tests that merely re-baseline, missing the edge/boundary cases the change introduces. If you cannot determine whether coverage is adequate, record it as a **Couldn't verify** item at the test file — do not let green stand as proof.
   - **Intent (from the brief)** — did it honor the **settled** decisions rather than re-litigating them? Did it resolve the **open** decisions it claimed to, or leave them properly open? Did it stay inside this phase's scope, or bleed into a later phase's work? Anything that turns on what the ticket/brief *meant* and can't be settled from the diff is a **Your call** item.
   - **Design invariants (if step 4 ran)** — check each `[defect]` rule in §9 against the diff. A `[defect]` violation is a blocking finding; a `[judgment]` item goes in Your call. If no design doc was found, note it and skip this axis.
   - **Cross-project preferences** — types, modules, comments, scope, tests, security.
   - **Project architecture** — the rules from `AGENTS.md` or `CLAUDE.md`.

6. **Report in three separate buckets, in this order — do not merge them.** Run each bucket's prose through the `ste-writing` skill (STE-flavored mode) before presenting it — file/line locators and code excerpts stay as-is, only the surrounding sentences get the pass.
   - **Couldn't verify — look here:** located blind spots, each naming what wasn't confirmable and why. Often the most valuable section — it directs the human's interrogation to where automation can't vouch for itself.
   - **Your call:** judgment-laden questions only the reviewer can settle (intent-vs-ticket, team-binding changes, architecture), each located and specific.
   - **Findings:** the ordinary located defects — file, line, problem, what to do instead. Skip matters of taste with no clear better option.
   If a bucket is empty, say so in one line. An empty **Couldn't verify** is a strong claim — only make it when it's true.

7. **Verdict** (one line), scoped explicitly to the mechanical floor: **Approve**, **Approve with suggestions**, or **Request changes** — and why. State plainly that the verdict covers what was *verified*, and that any **Your call** and **Couldn't verify** items remain open regardless of it — a human must close them. "Mechanically clean" is not "this is the right change."
   - **Missing tests on merge-bound code → Request changes**, unless an explicit "test-exempt because…" is declared (in the PR's `## Test plan`, or stated when the gate runs mid-chain). A hard gate, not a suggestion: untested code does not reach `main`.
   - **`[defect]` design invariant violation → Request changes**, same force as a type error.
   - When called mid-chain by `commit-push-pr`: **Request changes** halts the chain before the commit; **Approve with suggestions** passes, and its suggestions plus any open **Your call** / **Couldn't verify** items are carried forward into the PR handoff so the downstream human reviewer inherits them.

8. **Bug ledger.** Save confirmed **correctness** bugs (not preference/convention findings) to a `project` memory file keyed by branch: `review-<branch>.md`. Each entry: file, line, summary, status (`open`/`fixed`). On re-review of the same branch, flip previously-open bugs to `fixed` if the new diff resolves them — update in place, don't duplicate. Record the PR number in the file once it exists. Add/update the entry in MEMORY.md.

9. **Big decisions → the brief's ledger.** Distinct from the bug ledger above and routed elsewhere on purpose: when a **Your call** item (or any ambiguity surfaced in this review) is resolved through the interaction with reasoning **not already in the brief**, append a **Big decisions** entry to the governing brief's `ledger.md` (format and rules in `docs/briefs/README.md`). This is the durable, narrative record; the bug ledger is transient branch tracking. Record **only information-bearing resolutions** — never a clean approval, never a bug fix. If nothing was genuinely decided, write nothing; the section is sparse by design, and that sparseness is the whole point.
