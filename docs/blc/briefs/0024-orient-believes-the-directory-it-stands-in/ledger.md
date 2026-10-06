# Ledger — #0024 Orient believes the directory it stands in

`blc/2 #0024 pending a:pending`

**Brief:** `docs/blc/briefs/0024-orient-believes-the-directory-it-stands-in/brief.md`
**Started:** 2026-10-06
**Status:** pending

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | orient reads from the root | pending | — |

**a — orient reads from the root.** `tools/orient.sh` finds the repository root and then reads
every data path from the current directory instead. Run from a subdirectory it reports the
briefs, the install log and the orientation file as absent, and exits 0. This phase makes the
script change into the root before it reads anything, after it makes an explicit briefs-path
argument absolute. One `cd` corrects all three outputs, the self-host check and the footer. The
test asserts that the output from a subdirectory is byte-identical to the output from the root.

## Dependency structure

One phase. The brief named three questions and all three are settled below, and each answer
removed work rather than adding it. Nothing here is provisional.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | **Settled 2026-10-06: orient only.** The four sibling tools take the same relative default and are not changed. They fail loudly from a subdirectory — `validate-briefs.sh` and `open-briefs.sh` print `error: not a directory`, `list-briefs.sh` and `jira-csv.sh` say to run from the repo root — so none of them gives a wrong answer. Orient is the only one that answers confidently and wrong. Making the siblings work from a subdirectory is a feature, and this brief fixes a defect. Rejected: one rule in all five, which is tidier and would carry four files of unrelated change into a defect fix. | `a` |
| 2 | **Settled 2026-10-06: the argument is relative to the caller.** An explicit briefs path is made absolute before the `cd`, so `bash ../tools/orient.sh ../docs/blc/briefs` means what a shell user expects. The mechanism is `case "$BRIEFS_DIR" in /*) ;; *) BRIEFS_DIR="$PWD/$BRIEFS_DIR" ;; esac`, which needs no `realpath` — that command is not dependable on macOS — and does not canonicalise, which nothing here needs. Rejected: documenting the argument as relative to the root, which is two lines shorter and surprises every caller who has used any other shell tool. | `a` |
| 3 | **Settled 2026-10-06: orient says nothing about where it ran.** A note such as `(ran from src/, read from the root)` would make the output differ by the directory it was called from, and that difference is exactly what the test asserts must not exist. The note and the strongest available assertion cannot both be had. After the fix the output is identical from anywhere, which is the honest report. | `a` |

## Complications

Found while reading the code for this plan. None is in the brief.

- **Orient calls `list-briefs.sh` with an explicit path.** `tools/orient.sh:85` passes
  `$BRIEFS_DIR` through. Under decision 2 that value is absolute by then, so the child gets an
  absolute path. Were it left relative it would still work, because the child inherits the
  root as its directory. The call is safe either way, and the absolute form is safe for a
  reason that does not depend on inheritance.
- **The test helper always starts at a root.** `tests/test_orient.sh:13-16` defines `ORIENT()`
  and every caller wraps it in a `cd` to a fixture root. The new test needs a subdirectory
  inside the fixture, so it is the first in that file to run from anywhere else.
- **One existing test enters through a symlink.** `tests/test_orient.sh:280-287` runs orient
  from `$TMP/linked`, and its comment records that `--show-toplevel` resolves the link while
  `$PWD` keeps it. The `cd` moves that caller into the resolved tree. The assertion is against
  `$ROOT`, so it should still hold, and it must be seen to hold rather than assumed.

## Branches

To be cut for phase `a`.
