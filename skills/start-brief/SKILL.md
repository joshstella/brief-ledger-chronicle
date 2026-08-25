---
name: start-brief
description: >-
  Initiate brief execution: plan phases, write ledger, branch first phase. Use when the user asks to start-brief.
---

# start-brief

Initiate implementation from a feature or refactor brief: read it, plan the full phase sequence **with its dependency structure**, and branch the first phase. To continue an already-initiated brief, use `next-brief-phase` instead.

Usage: start-brief <path-or-name>
If no argument is given, list candidate brief files (search `docs/briefs/`, `briefs/`, `docs/`) and ask which to use.

---

## Steps

1. **Find the brief.**
   - If `$ARGUMENTS` is a readable file path, read it directly.
   - Otherwise match markdown files whose name or path contains `$ARGUMENTS` under `docs/briefs/`, `briefs/`, `docs/`. One match → use it; several → list and ask; none → say so.
   - No argument → list all `.md` files under those directories and ask.

2. **Check the ledger for prior work — do not overwrite one this run did not just create.**
   - Primary: look for `ledger.md` in the same directory as the brief file (e.g. `docs/briefs/refactor/ledger.md`). Read it if it exists.
   - Fallback: read MEMORY.md for a `brief-<kebab>` pointer if the repo ledger wasn't found.
   - If a ledger file exists, **STOP**. Report its status, branch, completed phases, and remaining phases. Do not silently re-initiate and do not overwrite it.
     - Status `in-progress`: tell the user to run `next-brief-phase` to continue.
     - Any other status (`pending`, `deferred`, `done`, `skipped`): the plan is already in the ledger. Continue from it, or wait.
   - Overwrite only if the user **explicitly confirms a restart**. That re-plans from scratch and replaces the file. Confirmation is the escape hatch. There is no `--force` flag: this is a prompt, not a program, and a flag would give the clobber back to anyone who reaches for it.
   - If none, proceed.
   - This stop is an instruction to the agent. Nothing in the test suite exercises it. A run that skips this step is indistinguishable from a run that followed it, except by reading the ledger afterwards.

3. **Read the brief in full.** Do not skim. Apply the consumption protocol, which is stated here because this is where it is used: settled decisions are fixed and are not re-litigated; open decisions resolve before the phase each one blocks; the brief's code conventions bind; and the rationale survives as an inline comment at the site that implements it, so the reasoning outlives the brief. Note the phase/layer sequence and any PR boundaries the brief defines.

4. **Read codebase context.**
   - Read the repo `AGENTS.md` or `CLAUDE.md` (whichever exists; root, and any subdirectory governing affected files).
   - For each area the brief touches, read the relevant existing files: what's already there, what the brief adds, what it modifies or replaces.
   - Note anything already built for this brief.

5. **Plan — a phase sequence WITH its dependency structure, not just a list.**
   - Use the brief's own phase/layer sequence if it has one; derive one if not.
   - Each phase gets a **stable id** (e.g. `phase 1 — domain types + ephemeris`), the files it creates/modifies, what it accomplishes, and what it depends on.
   - State the dependency shape explicitly: which phases form a **strict chain** (each needs the prior) versus which are **parallel tracks** (independent, can run on separate branches at once). Do not serialize work that doesn't need it.
   - Flag **open decisions** that block specific phases, naming which phase each blocks.
   - Flag **codebase complications** the brief doesn't address — real ones only, visible from reading the code, not invented.
   - If a phase's job is to *resolve* an open decision that could reorder later phases, say so: the sequence past that phase is **provisional** until it completes, and `next-brief-phase` will re-plan from there.
   - Keep each phase small enough to review in one sitting.

6. **Write the ledger entry — two places.**

   **Primary: `docs/briefs/<name>/ledger.md` in the repo** (same directory as the brief file). This is the source of truth — it travels with the code across machines and branches.
   - Brief path and title; status `pending`; date.
   - The **status line** directly under the title — `blc/1 #NNNN <status> 1:<status> 2:<status> …` — per `docs/briefs/README.md`, "Ledger status". Update it in the same edit as any status change, never separately.
   - The **full phase list** with stable ids and per-phase status. The vocabulary is `pending` / `in-progress` / `deferred` / `done` / `skipped`, defined once in `docs/briefs/README.md` and used at both levels. `in-progress` and `deferred` name their branch, and their PR once one exists.
   - The **dependency structure** (chain vs parallel; which phase is provisional pending which decision).
   - Branch(es) created.
   - Open decisions (with the phase each blocks) and any complications found in step 4.
   - Commit this file to `main` immediately — before any feature branch is cut — so it's visible on every machine that pulls.

   **Secondary: `project` memory file `brief-<kebab>.md`** in the memory directory. Same content. Keeps MEMORY.md pointing at it for fast in-session lookup. Add/update the entry in MEMORY.md — update in place if it already existed, don't duplicate.

The phase ids written here are the labels later commands rely on: `commit-push-pr` cites them in the PR's `## Brief` line, and `review-pr` checks each diff against its phase's scope. Keep them stable.

7. **Branch — phase-aware.**
   - Single-phase brief → ask to create one branch `feature/<kebab>`.
   - Multi-phase brief → present the full sequence, then branch only the **first** phase (or the first parallel set): *"This brief is N phases, <chain/parallel>. Branching for phase 1: `feature/<kebab>-<phase1>`. Later phases branch via `next-brief-phase` as each completes. Proceed?"*
   - Derive `<kebab>` from the brief title plus the phase label. Wait for confirmation before creating any branch or writing code.
