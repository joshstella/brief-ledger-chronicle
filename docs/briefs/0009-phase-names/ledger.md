# Ledger — #0009 One name for a phase, used everywhere
`blc/2 #0009 in-progress a:done(PR#34) b:done(PR#35) c:in-progress(brief/0009-c-the-check)`

**Brief:** `docs/briefs/0009-phase-names/brief.md`
**Status:** in-progress
**Date:** 2026-09-08

## Phase sequence

| id | status | what it does |
|---|---|---|
| `a — the readers` | done (PR#34) | Make both parsers dual-read before any writer emits the new format. `gather.sh` hardcodes the version twice — `grep -m1 'blc/1'` at line 36 and the `^blc\/1` anchor in the status `sed` at line 45; both become `blc/[0-9]+`. `open-briefs.sh` already matches `blc/*`, but its drift check finds the phase-table row with `grep "^\|.*phase $idx "` at line 192, which matches neither a letter index nor a row written as `` `a — the convention` ``. Left alone it fails silent, reporting no drift rather than erroring. No skill and no prose changes here. |
| `b — the convention` | done (PR#35) | Write the id shape (letter + label), the branch derivation `brief/<serial>-<letter>-<kebab>`, the reserved `closeout` suffix, the Jira summary shape, and the 26-phase ceiling into `docs/briefs/README.md`. Document the numeric-to-letter seam so a reader hitting `1:done` in #0004 and `a:done` later finds a reason, not a defect. Point `start-brief` and `next-brief-phase` at it; they write `blc/2` and letter indexes. Reword Contract v1.1 line 107 from "ledger `blc/1` line" to "ledger status line". Convert this ledger to `blc/2` with letter indexes — its own record is the first thing written in the new convention. |
| `c — the check` | in-progress (brief/0009-c-the-check) | Tests that both parsers read `blc/1` with numeric indexes and `blc/2` with letters, and that the drift check still fires on a letter-indexed ledger whose phase table disagrees. That last one is the regression `a` would otherwise ship silently. |

## Dependency structure

- **Strict chain: `a` → `b` → `c`.** Nothing here is parallel.
- `a` must land before `b`, because `b` is what makes the skills *write* `blc/2`. A reader
  that cannot yet parse it turns a new ledger invisible.
- `c` tests both alphabets, so it needs both the widened parsers and a ledger that actually
  uses letters — which `b` produces by converting this file.

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
| `a — the readers` | `b — the readers` |
| `b — the convention` | `a — the convention` |
| `c — the check` | `c — the check` |

Phases 1–3 above were written `phase 1`/`phase 2`/`phase 3` with a `blc/1` line at
initiation, because nothing could read letters until `a` landed. Phase `b` converted both
the status line and the table rows together. PR #34 was opened while the ledger still said
`phase 1 — the readers`; it is the same phase as `a — the readers` here.

Nothing in the brief's Settled decisions is re-litigated by this. The order lives in the
Change section, not in a settled decision.

## Open decisions

1. **Jira summary format.** The brief takes `#0007/b — the publisher`. It binds #0007 and
   blocks no phase here. Not resolved at initiation, and does not need to be.

## Complications found in the code, not addressed by the brief

1. **This ledger cannot use the convention it establishes, yet.** Its phases are letters in
   the brief, but nothing could read letters until `a` landed, and this file had to exist
   before any phase ran. It was written `blc/1` with numeric indexes and numeric table rows,
   which parsed correctly and kept the drift check live — `grep "^|.*phase 1 "` matched
   `phase 1 — the readers`. `b` converted the status line and the rows together.
   This is not the forward-only rule being broken: #0009 is the brief introducing the
   convention, not history being rewritten.

2. **`review-pr` also says `feature/`.** Line 71: "match the feature/branch name against
   `docs/briefs/`". The brief's phase `a` names only `start-brief` and `next-brief-phase`.
   Phase 2 should catch this third one or the repo keeps contradicting itself.

3. **The drift check's silence is the dangerous failure, not a loud one.** `open-briefs.sh`
   line 192 guards on `[ -n "$row" ]`, so a row it cannot match produces no finding rather
   than an error. A letter-indexed ledger whose phase table disagrees would therefore report
   clean. `c`'s test for this is the only thing that proves `a` fixed it.

4. **`gather.sh` line 27–28 comments name `blc/1` in prose.** Not parsing, but they will be
   wrong the moment a `blc/2` ledger exists. Phase 1 should fix the comments it is already
   editing around.

5. **`gather.sh` had three alphabet dependencies, not the two the brief counted.** The brief
   named the `grep -m1 'blc/1'` and the `^blc\/1` anchor. The third is in the same `sed`: the
   trailing strip was `s/[[:space:]]+[0-9]+:.*$//`, which removes the phase fields so the
   overall status is what is left. Against `blc/2 #NNNN in-progress a:done b:pending` it
   matches nothing, so every phase field survives into the table cell and the chronicle prints
   the whole tail as the status. Widening the version anchor alone would have produced a
   parser that finds the line and then misreads it — quieter than the failure the brief
   described, and worse. Fixed in `a` as `[0-9a-z]+:`.

6. **The drift scan needed a second shape for letters — but the reason recorded in `a` was
   wrong, and is corrected here.** `a` claimed anchoring the phase id to the first cell would
   break #0002–#0004, which "hold the branch in the first cell and `phase 1` in the second".
   That is false. Those ledgers carry two tables: a phase table with the id in the first cell
   like every other ledger, and a separate branches table further down. The scan takes
   `head -1`, so it lands on the phase table. Checked against all four ledgers in `c`: every
   phase id in this repository is in the first cell, and anchoring would have broken nothing.

   The conditional `a` shipped is still right, for a smaller reason: `phase N` is a
   distinctive string and can be found anywhere in a row, while a bare letter cannot and has
   to be anchored. The numeric scan stays unanchored because it already was and tightening a
   working scan buys nothing — not because any ledger here depends on it. The code comment on
   `main` asserted the false version; `c` rewrites it, and pins the latitude with a test so a
   later tidy-up cannot remove it silently.

   Recorded rather than quietly fixed: PR #34's description carries the wrong reason too, and
   a merged PR body cannot be corrected. This is where a reader finds out.

7. **`b`'s surface was wider than the brief listed.** The brief named `docs/briefs/README.md`,
   the two execution skills, and Contract v1.1. Three more sites name the schema or the branch
   shape: `skills/chronicle/SKILL.md` said status comes from "the `blc/1` overall token",
   `skills/review-pr/SKILL.md` said to match "the feature/branch name", and the README's own
   status-line section used a `blc/1` line as *the* example while asserting "`blc/1` is the
   schema version". Left alone, the toolkit would have documented one convention and
   instructed another.

8. **A rule written in `b` nearly forbade `b`'s own work.** The first draft of the
   `next-brief-phase` note said a `blc/1` ledger is never converted, because merged PRs cite
   the phase ids they were opened against. That is a real hazard — PR #34 says
   `phase 1 — the readers` and this ledger now says `a — the readers` — but as written it also
   banned the conversion this phase was assigned to perform. The rule became: convert only when
   it is a phase's stated job, and record the mapping. The mapping is in the re-plan section.

## Branches

- `brief/0009-a-the-readers` — phase `a`. Cut from `main` at 962a300. Merged as PR #34.
- `brief/0009-b-the-convention` — phase `b`. Cut from `main` at f661f7e. Merged as PR #35.
- `brief/0009-c-the-check` — phase `c`. Cut from `main` at b77b5e3.

The phase `a` branch carried the letter before anything else did. At the time the table row
above still read `phase 1`, because parsers could not read letters until that phase landed.
Nothing parses a branch name — `open-briefs.sh` resolves whatever string the ledger stored —
so the branch was free to be the first thing in the repository written in the new
convention. `b` converted the rest of the file to match it.
