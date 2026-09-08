# Ledger — #0009 One name for a phase, used everywhere
`blc/1 #0009 pending 1:pending 2:pending 3:pending`

**Brief:** `docs/briefs/0009-phase-names/brief.md`
**Status:** pending
**Date:** 2026-09-08

## Phase sequence

| id | status | what it does |
|---|---|---|
| `phase 1 — the readers` | pending | Make both parsers dual-read before any writer emits the new format. `gather.sh` hardcodes the version twice — `grep -m1 'blc/1'` at line 36 and the `^blc\/1` anchor in the status `sed` at line 45; both become `blc/[0-9]+`. `open-briefs.sh` already matches `blc/*`, but its drift check finds the phase-table row with `grep "^\|.*phase $idx "` at line 192, which matches neither a letter index nor a row written as `` `a — the convention` ``. Left alone it fails silent, reporting no drift rather than erroring. No skill and no prose changes here. |
| `phase 2 — the convention` | pending | Write the id shape (letter + label), the branch derivation `brief/<serial>-<letter>-<kebab>`, the reserved `closeout` suffix, the Jira summary shape, and the 26-phase ceiling into `docs/briefs/README.md`. Document the numeric-to-letter seam so a reader hitting `1:done` in #0004 and `a:done` later finds a reason, not a defect. Point `start-brief` and `next-brief-phase` at it; they write `blc/2` and letter indexes. Reword Contract v1.1 line 107 from "ledger `blc/1` line" to "ledger status line". Convert this ledger to `blc/2` with letter indexes — its own record is the first thing written in the new convention. |
| `phase 3 — the check` | pending | Tests that both parsers read `blc/1` with numeric indexes and `blc/2` with letters, and that the drift check still fires on a letter-indexed ledger whose phase table disagrees. That last one is the regression phase 1 would otherwise ship silently. |

## Dependency structure

- **Strict chain: phase 1 → phase 2 → phase 3.** Nothing here is parallel.
- Phase 1 must land before phase 2 because phase 2 is what makes the skills *write*
  `blc/2`. A reader that cannot yet parse it turns a new ledger invisible.
- Phase 3 tests both alphabets, so it needs both the widened parsers and a ledger that
  actually uses letters — which phase 2 produces by converting this file.

## Re-plan against the brief, at initiation

**The brief's phase order is reversed here, and the letters move with it.**

The brief files three phases as `a — the convention`, `b — the readers`, `c — the check`,
and says they are "split so the convention can land before the parsers move." That is an
authoring preference. It is not safe in this order.

Phase `a` as filed updates `start-brief` and `next-brief-phase` to write `blc/2` with
letter indexes. Phase `b` as filed is what teaches the parsers to read that. They land as
separate PRs. Between those two merges, any brief started by the updated skills gets a
`blc/2` ledger that `gather.sh` cannot see at all — line 36 is `grep -m1 'blc/1'`, which
simply misses it, so the brief reports `no-line` and drops out of the chronicle table
with no error anywhere.

Running the readers first closes the window and costs nothing: widening `blc/1` to
`blc/[0-9]+` is a no-op against every ledger that exists today.

The letters follow the order rather than the filing, because this brief defines phases as
`a`–`z` **in order**. Executing `b` before `a` would break the convention the brief exists
to establish, on the brief's own first execution.

| this ledger | brief's table |
|---|---|
| `phase 1 — the readers` | `b — the readers` |
| `phase 2 — the convention` | `a — the convention` |
| `phase 3 — the check` | `c — the check` |

Nothing in the brief's Settled decisions is re-litigated by this. The order lives in the
Change section, not in a settled decision.

## Open decisions

1. **Jira summary format.** The brief takes `#0007/b — the publisher`. It binds #0007 and
   blocks no phase here. Not resolved at initiation, and does not need to be.

## Complications found in the code, not addressed by the brief

1. **This ledger cannot use the convention it establishes, yet.** Its phases are letters in
   the brief, but nothing can read letters until phase 1 lands, and this file has to exist
   before any phase runs. It is written `blc/1` with numeric indexes and numeric table rows,
   which parses correctly today and keeps the drift check live — `grep "^|.*phase 1 "` does
   match `phase 1 — the readers`. Phase 2 converts the status line and the rows together.
   This is not the forward-only rule being broken: #0009 is the brief introducing the
   convention, not history being rewritten.

2. **`review-pr` also says `feature/`.** Line 71: "match the feature/branch name against
   `docs/briefs/`". The brief's phase `a` names only `start-brief` and `next-brief-phase`.
   Phase 2 should catch this third one or the repo keeps contradicting itself.

3. **The drift check's silence is the dangerous failure, not a loud one.** `open-briefs.sh`
   line 192 guards on `[ -n "$row" ]`, so a row it cannot match produces no finding rather
   than an error. A letter-indexed ledger whose phase table disagrees would therefore report
   clean. Phase 3's test for this is the only thing that proves phase 1 fixed it.

4. **`gather.sh` line 27–28 comments name `blc/1` in prose.** Not parsing, but they will be
   wrong the moment a `blc/2` ledger exists. Phase 1 should fix the comments it is already
   editing around.

## Branches

None yet. Phase 1 branches on confirmation as `brief/0009-a-the-readers`.

The branch carries the letter while the table row above still says `phase 1`. That is
deliberate: the letter is the phase's real id, and the numeric row is a temporary
accommodation for parsers that cannot read letters until this phase lands. Nothing parses
a branch name — `open-briefs.sh` resolves whatever string the ledger stored — so the
branch is free to be the first thing in the repository written in the new convention.
