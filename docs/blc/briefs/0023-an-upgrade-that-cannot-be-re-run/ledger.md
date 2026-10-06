# Ledger — #0023 An upgrade that cannot be re-run, and a version nobody can name

`blc/2 #0023 done a:done(PR#111) b:done(PR#112) c:skipped`

**Brief:** `docs/blc/briefs/0023-an-upgrade-that-cannot-be-re-run/brief.md`
**Started:** 2026-10-05
**Status:** done

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the log moves first | done (PR#111) | `brief/0023-a-the-log-moves-first` |
| b | what a version is | done (PR#112) | `brief/0023-b-what-a-version-is` |
| c | a target that is behind | skipped | — |

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

Decision 1 overturned the tag. The plan above stands as written, and "Phase `b`, as executed"
says what replaced it.

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
| 1 | **Settled 2026-10-06: the version is derived, not chosen.** `git rev-list --count HEAD` and a short hash, as `<count>+<sha>`. It identifies a build and promises nothing; the Contract carries every promise this toolkit makes. The question in the brief — semantic versioning against what promise? — has no answer, because no promise is written down to version against. A number chosen by hand would be a declared second copy of what git already knows, and would invite the compatibility reading the Contract has not earned. Rejected: tags, which need a release step nobody runs and would read as that promise; and a CI-stamped number, which needs a network call the installer has never made. | `b`, `c` |
| 2 | **Settled 2026-10-05: `a` detects and resumes.** From the brief. A target half-moved by the current installer is not fixed by changing the order, because its log is still at the old path. The signature is unambiguous — a populated `docs/blc/` with no log in it, while `docs/install-log/install-log.md` exists — so detection is not a guess. Rejected: a documented hand recovery, which asks an adopter to undo a move the installer made, from a run that wrote no record of what it moved. | `a` |
| 3 | **Settled 2026-10-06: it waits, and `c` is skipped.** An adopter asks what they have, and today the answer is given by hand — there are few adopters, and the owner tells them. A reporter built before anyone has asked would guess at the question. A package manager may take this job later, and that would replace the reporter rather than use it. | `c` |

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

`brief/0023-a-the-log-moves-first` (phase `a`).
`brief/0023-b-what-a-version-is` (phase `b`).

## Phase `a`, as executed

Two changes, and the second is what makes the first reach a target that is already stuck.

The install log moves before every other old-layout path, instead of fourth where sort order
put it. The reorder sits after the array is built, so everything that decides whether a move
may run is unchanged. Only what survives a move that dies halfway is different.

The ownership guard gains one exception. A populated `docs/blc/` with no log in it, while
`docs/install-log/install-log.md` still exists, is an interrupted move and not a project tree.
Resuming is safe because every path is checked again: a file that already moved is no longer at
its old path, so it is neither moved twice nor counted as a clash.

**The third test was unproven, and a mutation fixed that.** `still_refuses_a_docs_blc_with_no_old_log`
passed with and without the change, because it guards the narrowing rather than the fix. The
first mutation written for it was wrong and proved nothing: it made the guard fire always, which
is the behaviour before this phase, so it failed the resume test instead. The second made the
exception apply always. That failed both refusal tests, which is the result the guard is for.

**The resume is said out loud, from the review.** The exception used to fire silently, so an
adopter whose first run died would see what looked like an ordinary install the second time.
The run that left that state wrote no log, so this message is the only account they get of why
a half-moved tree was accepted where a project's own is refused. Asserted by the resume test.

The suite is 567, from 564.

## Phase `b`, as executed

`install.sh` built its version from `git describe --tags --always`, which in a repository with
no tags is a bare hash. A hash says which build without saying which is newer, so `c` had
nothing to subtract.

The version is now `<count>+<sha>`: the count orders and the hash identifies. Neither is
chosen by a person, which is the point. `main` takes one commit per merge under squash merge,
so the count rises by one each time and two targets can be ordered by subtraction alone. No
tag to fetch, no release step, no network call.

**A shallow source reports no version at all.** A shallow clone counts only what it fetched,
so a count read from one is wrong and nothing downstream can tell. `--depth` is how CI checks
out by default, which is the likeliest way this is hit, so it stamps `unknown (shallow clone)`
instead. Tested by creating `.git/shallow`, which is exactly what git itself tests for and is
cheaper than a clone.

**Two guards were written and removed, both by the same test.** The first checked
`rev-parse --git-dir` before anything else. The second checked that the count and the hash
were non-empty. The suite passed with and without each, because `rev-list` already fails into
the same `unknown` in a source that is not a repository, and it cannot succeed while printing
nothing. Both are gone, and one line at the site says why, so they are not written again. The
second was caught in review, after the first had already been removed for the same reason.

Three tests, two of which fail without the change. The third — a non-git source stamps
`unknown` — passes either way; it guards behaviour the old line already had, and is kept
because this rewrite could have lost it.

The suite is 570, from 567.

## Constraint for `c`

**A branch install stamps a count above `main`'s for the same work.** A feature branch carries
its own commits on top of the merge base, so a target installed from one is numbered ahead of a
target installed from `main` at the same content. Subtraction answers "am I behind" only
between installs from `main`. `c` must say so, or detect it, rather than report a target as
ahead when it is not.

## Closeout, 2026-10-06

An old-layout upgrade can be re-run after it dies partway, and a target's install log now
records a version that can be ordered.

`a` (PR#111) moved the install log ahead of every other old-layout path, so an interrupted move
always leaves the log where the ownership guard expects it. The same phase made the fix
retroactive: a populated `docs/blc/` with no log in it, while the old log still exists, is an
interrupted move, and the installer says so and resumes. `b` (PR#112) replaced
`git describe --tags --always` with `<count>+<sha>`. The suite went 564 to 570, and each phase's
tests were seen to fail without its fix.

The brief planned three phases and asked three questions. All three are answered, and two of the
three moved work rather than confirming the plan:

- **Decision 1 was answered by refusing the question.** The brief asked what a version number
  should mean here — semantic versioning against what promise? There is no written promise to
  version against, so no honest answer exists. The version is derived instead: it identifies a
  build and promises nothing, and the Contract carries every promise this toolkit makes.
  Rejected: tags, which need a release step nobody runs and would read as that promise, and a
  CI-stamped number, which needs a network call the installer has never made.
- **Decision 2 settled as detect-and-resume**, which is what made `a` reach a target that was
  already stuck. Order alone fixes the next run, not the one that already failed.
- **Decision 3 settled as "it waits"**, which skips `c`.

**`c` is skipped, and nothing replaces it.** `tools/orient.sh` does not report whether a target
is behind. The version `b` produced makes the comparison a subtraction with no network call, so
`c` is cheap — and that is the reason to leave it. Nobody has asked. The adopters are few and
the owner tells them directly, so a reporter would answer a question in a form nobody has
stated. A package manager may take this job later, and it would replace a reporter rather than
use one. Skipped rather than deferred: there is no code on a branch.

**Two dead guards were removed in `b`, and the second was the lesson.** A `rev-parse --git-dir`
check and a non-empty check on the count and hash each passed the whole suite when mutated away.
The first was found while writing the tests. The second was written anyway, in the same
function, and was caught only in review. Writing an unprovable guard is not a slip that
knowing about prevents.

**One non-goal and one success criterion assumed a tag, and decision 1 removed it.** The brief
said "a tag is the whole of `b`", and asked that a target's install log name a version that
exists in this repository's tags. No tag was cut, so that criterion is not met and will not be.
What replaced it is stricter in the way that matters: the version is derived, so it cannot drift
from the build it names, and no release step has to run for a target to record one. The other
three criteria are met. A half-moved target re-runs to completion and ends in a clean upgrade's
tree, a test fails for that case against the installer before `a`, and what the version promises
is written down — it promises nothing, which is no more than the Contract.

Open after close. Neither is tested:

- **A branch install is numbered ahead of `main`.** A feature branch carries its own commits on
  top of the merge base, so a target installed from one stamps a count above a target installed
  from `main` at the same content. Subtraction orders installs from `main` and nothing else.
  `c` would have had to say this; with `c` skipped, only this paragraph does.
- **The shallow case is arranged, not reproduced.** The test creates `.git/shallow`, which is
  what git itself tests for, so `rev-parse --is-shallow-repository` cannot tell the difference.
  A real `--depth 1` CI checkout is not exercised end to end.
