# brief-ledger-chronicle

This repo uses the brief-ledger-chronicle workflow. Installed skills are the gates;
bypassing them is the defect.

## Process

- Start with `bash tools/orient.sh` in a repo you have not read today. It answers what is
  in flight, what an install wrote, and what this project values in ~700 tokens, and it
  says when your checkout is behind. Reading the record instead costs tens of thousands.
- `blc-commit-push-pr` is the only path to `main`. Do not use raw `git commit && git push`
  for work headed to `main`.
- `blc-review-pr` is the review gate. A Request changes verdict blocks the commit.
- A brief is the hypothesis you start with, not a spec you deliver against. File it
  before non-trivial work begins (`blc-create-brief`, then `blc-start-brief` /
  `blc-next-brief-phase`). Expect the ledger to correct it. Do not retrofit one after the
  work shipped.
- Declare work you have picked up but not yet filed in `docs/state/<your git email>.md`,
  and clear it when it lands. That window is invisible to every ledger, and it is where two
  people pick the same serial.
- `blc-chronicle` renders the record. `blc-orient` reads it cheaply. `blc-init-briefs` is
  one-time setup.

## Writing

Default prose uses the `blc-ste-writing` skill in STE-flavored mode. Apply it to briefs,
ledgers, chronicles, commit messages, PR bodies, reviews, comments, and docs. Do not
apply it to code, identifiers, command syntax, or the user's own words.

## Tests

Tests gate `main`. Merges to `main` need tests covering the change, run and passing.
An untestable merge gets an explicit "test-exempt because…" in the PR, not a silent gap.

## Toolkit-owned vs project-owned

Every install replaces toolkit-owned paths: `blc-*` skills, `tools/*.sh`, this rules
file, and the shipped brief docs. Local edits to them do not survive the next install.
Stale skills and commands named in `docs/install-log/install-log.md` are removed.

Project-owned paths are never written after creation: `AGENTS.md` / `CLAUDE.md`, numbered
brief folders, ledgers, declarations, and chronicles.

To customize without fighting the installer:
- **`AGENTS.md` / `CLAUDE.md`** — project architecture, stack, and rules for agents.
- **`brief-checks/`** — shell scripts the gate runs; project-enforced rules about the
  record (see `docs/briefs/` for the brief when filed).

Do not edit installed skills or tools in place expecting the change to stick. Change the
toolkit upstream, or use the project-owned paths above.
