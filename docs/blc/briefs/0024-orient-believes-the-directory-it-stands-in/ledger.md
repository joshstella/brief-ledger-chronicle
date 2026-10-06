# Ledger — #0024 Orient believes the directory it stands in

`blc/2 #0024 done a:done(PR#114)`

**Brief:** `docs/blc/briefs/0024-orient-believes-the-directory-it-stands-in/brief.md`
**Started:** 2026-10-06
**Status:** done

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | orient reads from the root | done (PR#114) | `brief/0024-a-orient-reads-from-the-root` |

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

`brief/0024-a-orient-reads-from-the-root` (phase `a`).
`brief/0024-closeout`.

## Phase `a`, as executed

Two lines of behaviour, in the order they have to happen.

An explicit briefs path is made absolute against the caller's directory, and the default is
left alone. That asymmetry is the whole of decision 2 and is easy to lose: absolutising both
would anchor the default to the caller too, which is the defect under a new name.

Then `cd "$ROOT"`, after the root is known and before anything is read. One `cd` corrects the
three record paths, the self-host check at line 228 and the `Manifesto.md` footer at line 270,
because all of them were relative and none of them was wrong for any other reason.

**The symlink complication did not bite.** The existing test that enters through `$TMP/linked`
passes unchanged. Its assertion is against `$ROOT`, which the `cd` does not move.

**Four tests, three of them proven by a failing run.** The identity test and the
finds-the-filed-record test both fail against the unfixed script. The two argument tests pass
either way, because caller-relative resolution is what orient already did — so they were
mutated instead: removing the absolutising block fails
`orient_resolves_an_explicit_path_against_the_caller`, which is decision 2 being enforced
rather than assumed. The fourth, an absolute path from a subdirectory, passes under every
mutation tried and is kept as a plain regression guard.

The identity test on its own would pass if orient reported everything absent from both
directories, so a second test names the three sections that were wrong. A byte-identity
assertion is only as strong as the fixture it compares.

The suite is 574, from 570.

## Closeout, 2026-10-06

`tools/orient.sh` reads the record from the repository root, whatever directory it was called
from. `a` (PR#114) is the whole brief. The suite went 570 to 574.

The brief asked three questions and every answer removed work. That is why this is one phase
and not three: the siblings are not touched, the argument rule needed two lines rather than a
convention, and the note that would have explained the behaviour was the one thing the test
forbids. A brief that asks good questions can get smaller when they are answered.

- **Decision 1 — orient only.** The four siblings take the same relative default and fail
  loudly from a subdirectory, so none of them answers wrongly. Orient was the only one that
  could not fail, because #0021 made it turn a missing input into a stated absence. Rejected:
  one rule across all five, which is tidier and would have carried four files of unrelated
  change into a defect fix.
- **Decision 2 — the argument is the caller's.** An explicit path is made absolute before the
  `cd`; the default is left alone. Absolutising both would have anchored the default to the
  caller, which is this defect under a new name, and that is the trap in this phase.
- **Decision 3 — orient says nothing about where it ran.** The note and the byte-identity
  assertion cannot both exist. The assertion is worth more.

**The complication about symlinks did not bite.** The existing test that enters through a
symlinked checkout passes unchanged, because its assertion is against `$ROOT` and the `cd` does
not move that. It was checked rather than assumed, which is why it was written down.

**One stale comment was found by the review, not by a test.** The script's header said "Run
from the repository root" — true as advice and false as a requirement, once the `cd` existed.
No test reads a comment. This is the second phase in a row where the review caught something
the suite could not, and both were statements rather than behaviour.

Open after close. Neither is tested:

- **No installed target is corrected until it is reinstalled.** `tools/orient.sh` is
  toolkit-owned, so the fix reaches a target on its next install and not before. Every project
  installed at `177+2f6aa89` or earlier still answers wrongly from a subdirectory. Nothing here
  exercises the reinstall path, and nothing tells an adopter they are affected.
- **The identity test is only as strong as its fixture.** It compares two runs over one brief,
  a six-line install log and a three-line orientation file. A section that reads wrong from
  both directories in a richer repository passes both new tests. The second test names the
  three sections that were wrong, which is what stops the pair from passing vacuously.

**The skills were left alone, as the brief required.** `skills/blc-orient/SKILL.md` still says
to run from the repository root. That instruction is now unnecessary rather than wrong, and a
reader cannot tell from the skill which tools still need it. The non-goal is correct — the
script must be right whether or not a caller obeys — but the wording is now a second question,
and it is not this brief's.
