# Ledger — #0023 An upgrade that cannot be re-run, and a version nobody can name

`blc/2 #0023 pending a:pending b:pending c:pending`

**Brief:** `docs/blc/briefs/0023-an-upgrade-that-cannot-be-re-run/brief.md`
**Started:** 2026-10-05
**Status:** pending

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the log moves first | pending | — |
| b | what a version is | pending | — |
| c | a target that is behind | pending | — |

The brief's three phases stand. `a` is a defect and `b` and `c` are gaps, so `a` goes first.

**a — the log moves first.** The install log moves before any other old-layout path, rather
than fourth in sort order. A move that fails partway then always leaves
`docs/blc/install-log/install-log.md` in place, so the ownership guard passes on a re-run and
the existing clash logic finishes the work. The same phase makes the fix retroactive: a target
half-moved by the current installer is recognised by its signature, which is a populated
`docs/blc/` with no log in it while `docs/install-log/install-log.md` still exists at the old
path. That pair can only come from an interrupted move, because a project's own `docs/blc/`
does not arrive with an old-layout install log beside it. Tests: a half-moved target re-runs to
completion, the tree it ends in equals a clean upgrade's, and a `docs/blc/` with no old log is
still refused.

**b — what a version is.** This repository has no tags, so `git describe --tags --always` in
`install.sh` falls through to a commit hash, and every target's install log records that. The
phase tags a version and writes down what the number promises. It promises no more than the
Contract does, which today binds the briefs directory only. Tests: a tagged checkout stamps the
tag rather than a hash, and an untagged one still installs. Waits on decision 1.

**c — a target that is behind.** `tools/orient.sh` reports the installed version and whether
the source is newer. Runs only if `b` shows the comparison is cheap and needs no network call.
Waits on decisions 1 and 3.

## Dependency structure

`a` is independent of everything. It touches the old-layout move and nothing else.

`b` then `c` is a chain: `c` compares versions, which needs `b` to have settled what a version
is. `b` and `c` share no code with `a`, so `a` could run beside them. It runs first anyway,
because it is the only defect here and the rest are gaps.

`c` is provisional. If `b` settles that a version comparison needs anything a target cannot do
offline, `c` does not run.

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | **What a version number means here.** From the brief. Semantic versioning against what promise? The Contract is versioned separately and binds the briefs directory only. The installer's ownership rules are what an adopter relies on, and they are uncontracted. A version that implies more than the Contract says would be the specification-first move the Manifesto argues against. | `b`, `c` |
| 2 | **Settled 2026-10-05: `a` detects and resumes.** From the brief. A target half-moved by the current installer is not fixed by changing the order, because its log is still at the old path. The signature is unambiguous — a populated `docs/blc/` with no log in it, while `docs/install-log/install-log.md` exists — so detection is not a guess. Rejected: a documented hand recovery, which asks an adopter to undo a move the installer made, from a run that wrote no record of what it moved. | `a` |
| 3 | **Whether `c` belongs in this brief** or waits until an adopter asks what they have. From the brief. | `c` |

## Complications

Found while reading the code for the brief. None is in the brief itself.

- **The aborted run wrote no record.** `install.sh:1198` writes the install log at the end of a
  run. So a failed move leaves no list of what moved, which is why `a` resumes from the tree
  rather than from a log.
- **`docs/blc/ignore-revs` holds the `#0017` move commit.** `tools/lib/touch-log.sh` drops those
  commits when it dates a brief. If `a` produces a second move commit of the same kind, the same
  question arises for it.
- **`tests/README.md` has never listed `tests/test_upgrade.sh`.** Recorded under #0020 as a gap
  from #0017, and `a` is the next change to that file.

## Branches

None yet.
