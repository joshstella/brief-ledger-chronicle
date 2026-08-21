---
name: init-briefs
description: >-
  One-time idempotent setup of docs/briefs/ structure. Use when the user asks to init-briefs.
---

# init-briefs

Set up a repository for the brief workflow. A **one-time, idempotent** act — run it once
when adopting the brief methodology in a repo; safe to re-run (it creates only what's
missing and never overwrites). This is the command that onboards a new repo (a fresh
project, a consulting engagement) to the convention.

## What it creates

- `docs/briefs/` — the briefs root, if absent.
- `docs/briefs/_drafts/` — the **committed** holding area for unnumbered drafts, with a
  short `README.md` stating its semantics: drafts are unnumbered and unordered, committed
  so they're available from any workstation, and filing via `create-brief` is the
  one-way door that assigns a serial and moves a draft into a numbered folder.
- `docs/briefs/README.md` — the convention reference. Copy it from
  `~/.claude/briefs/README.template.md` (installed with this workflow) so there's a single
  source of truth; if that template isn't present, write an equivalent from the conventions
  described here: serial-numbered `NNNN-slug/` folders each holding `brief.md` (and
  `ledger.md` on execution, whose final **Big decisions** section logs review-time judgment
  calls); the `_drafts/` holding area; the identity line
  (`**Serial:** · **Created:** · **Author:** · **Depends on:**`); serials assigned at
  filing by `create-brief`, next = max + 1.

## Rules

- **Idempotent.** Create only what's missing; never overwrite an existing file. If
  everything already exists, report "already initialized" and exit cleanly.
- **Structure only.** Does not touch `AGENTS.md` / `CLAUDE.md` or other tooling — wiring the convention
  pointer into a project's architecture file is a separate, project-specific step.
- **Commits nothing.** Leave staging and commit to the user / `commit-push-pr`.

## Relationship to create-brief

`create-brief` assumes this structure exists. If `docs/briefs/` or `docs/briefs/_drafts/`
is missing, `create-brief` stops and points here — it does **not** silently scaffold the
structure itself. Setup is deliberate and lives here; filing is the hot path and stays
single-purpose.
