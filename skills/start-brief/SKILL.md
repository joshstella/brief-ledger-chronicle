---
name: start-brief
description: >-
  Initiate brief execution: plan phases, write ledger, branch first phase. Use when the user asks to start-brief.
---

Initiate implementation from a feature or refactor brief: read it, plan the full phase sequence **with its dependency structure**, and branch the first phase. To continue an already-initiated brief, use the `next-brief-phase` skill instead.

Usage: /start-brief <path-or-name>
If no argument is given, list candidate brief files (search `docs/briefs/`, `briefs/`, `docs/`) and ask which to use.

---

## Steps

1. **Find the brief.**
   - If `$ARGUMENTS` is a readable file path, read it directly.
   - Otherwise match markdown files whose name or path contains `$ARGUMENTS` under `docs/briefs/`, `briefs/`, `docs/`. One match → use it; several → list and ask; none → say so.
   - No argument → list all `.md` files under those directories and ask.

2. **Check the ledger for prior work — redirect if already in progress.**
   - Primary: look for `ledger.md` in the same directory as the brief file (e.g. `docs/briefs/refactor/ledger.md`). Read it if it exists.
   - - If a ledger exists with status `in-progress`: STOP. Report the branch, completed phases, and remaining phases, and tell the user to run the `next-brief-phase` skill to continue — or to confirm a restart, which re-plans from scratch and overwrites the ledger. Do not silently re-initiate.
   - If none, proceed.

3. **Read the brief in full.** Do not skim. The consumption protocol — settled decisions are fixed, open decisions resolve first, code conventions are binding, the rationale gets preserved as inline comments — is owned by the `feature-brief` skill; apply it rather than restating it here. Note the phase/layer sequence and any PR boundaries the brief defines.

4. **Read codebase context.**
   - Read the repo `AGENTS.md` (root, and any subdirectory governing affected files).
   - For each area the brief touches, read the relevant existing files: what's already there, what the brief adds, what it modifies or replaces.
   - Note anything already built for this brief.

5. **Plan — a phase sequence WITH its dependency structure, not just a list.**
   - Use the brief's own phase/layer sequence if it has one; derive one if not.
   - Each phase gets a **stable id** (e.g. `phase 1 — domain types + ephemeris`), the files it creates/modifies, what it accomplishes, and what it depends on.
   - State the dependency shape explicitly: which phases form a **strict chain** (each needs the prior) versus which are **parallel tracks** (independent, can run on separate branches at once). Do not serialize work that doesn't need it.
   - Flag **open decisions** that block specific phases, naming which phase each blocks.
   - Flag **codebase complications** the brief doesn't address — real ones only, visible from reading the code, not invented.
   - If a phase's job is to *resolve* an open decision that could reorder later phases, say so: the sequence past that phase is **provisional** until it completes, and the `next-brief-phase` skill will re-plan from there.
   - Keep each phase small enough to review in one sitting.

6. **Write the ledger entry — two places.**

   **Primary: `docs/briefs/<name>/ledger.md` in the repo** (same directory as the brief file). This is the source of truth — it travels with the code across machines and branches.
   - Brief path and title; status `initiated`; date.
   - The **full phase list** with stable ids and per-phase status (`pending` / `in-progress` / `done` / `skipped`).
   - The **dependency structure** (chain vs parallel; which phase is provisional pending which decision).
   - Branch(es) created.
   - Open decisions (with the phase each blocks) and any complications found in step 4.
   - Commit this file to `main` immediately — before any feature branch is cut — so it's visible on every machine that pulls.

   The phase ids written here are the labels later commands rely on: the `commit-push-pr` skill cites them in the PR's `## Brief` line, and the `review-pr` skill checks each diff against its phase's scope. Keep them stable.

7. **Branch — phase-aware.**
   - Single-phase brief → ask to create one branch `feature/<kebab>`.
   - Multi-phase brief → present the full sequence, then branch only the **first** phase (or the first parallel set): *"This brief is N phases, <chain/parallel>. Branching for phase 1: `feature/<kebab>-<phase1>`. Later phases branch via the `next-brief-phase` skill as each completes. Proceed?"*
   - Derive `<kebab>` from the brief title plus the phase label. Wait for confirmation before creating any branch or writing code.
