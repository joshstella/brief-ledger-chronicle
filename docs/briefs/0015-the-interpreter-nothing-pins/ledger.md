# Ledger — #0015 The interpreter nothing pins

`blc/2 #0015 in-progress a:in-progress(brief/0015-a-the-awk-matrix) b:pending`

**Brief:** `docs/briefs/0015-the-interpreter-nothing-pins/brief.md`
**Started:** 2026-09-29
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the awk matrix | in-progress | `brief/0015-a-the-awk-matrix` |
| b | the stated claim | pending | — |

**a — the awk matrix.** `tests/run.sh` discovers every `awk` on `PATH`, runs the suite under
each, and prints which ones it used with their versions. An absent interpreter is named as not
found rather than skipped in silence. Corrects the misdiagnosis in `tests/README.md` in the
same phase, because that section is about this exact failure and is currently wrong about its
cause.

**b — the stated claim.** Writes the supported-interpreter claim where both a contributor and a
promoter meet it, and makes CI install the matrix so criterion 1 is satisfied by testing rather
than by a claim narrowed to what already passes. Records bash 3.2 as known-unverified rather
than letting silence imply coverage.

## Phase a — what it does

`tests/run.sh` gained a discovery step, a plan step, and an outer driver. It discovers each of
`awk`, `gawk`, `mawk`, `original-awk` and `busybox awk` on `PATH`, collapses names that report
one version into one run with the alias reported, runs the whole suite once per remaining
implementation with `PATH` shimmed so the tools resolve `awk` to that binary, and prints which
ran and which were not found. On this machine that is gawk (as `awk`, with `gawk` an alias)
and mawk: **343 passed, 0 failed under both.**

Shimming `PATH` rather than passing a variable is the deliberate part. The tools call `awk`
unqualified, so a variable would test a code path they take only under test.

Three decisions worth keeping.

**The candidate list is fixed and not overridable.** An environment variable that could shorten
it would be the same move as not testing, which is what Contract promotion criterion 1
forbids in as many words. The list is guarded by a test that fails if a name is removed.

**Discovery and planning use shell builtins only** — no `sed`, `grep`, `cut`, `tr`, or even
`dirname`, which meant replacing the `REPO_ROOT` line that had used it since the first commit.
This is not minimalism. It is what lets a test set `PATH` to a directory of stub awks and get
an answer about that directory. Without it the only testable question would be "what does this
laptop have", and every assertion would be a fact about the machine.

**Aliases are keyed on the version string, not the resolved path.** `/usr/bin/awk` and
`/usr/bin/gawk` are two paths and one implementation; separating them ran gawk twice and
called it a two-interpreter matrix. Resolving the link would need `readlink`, which is the
external binary the previous paragraph rules out.

**Two bugs were found by building it, both in the reporting rather than the running.** The
first counted `awk` and `gawk` as two interpreters, so the matrix claimed twice the coverage it
had. The second is the one worth remembering: alias markers and run entries shared one array,
the indices desynced, and run 2 printed `gawk` while executing mawk. Every test passed. A green
report naming an interpreter that did not run is worse than a red one, because it is evidence
of something that did not happen — and it is the same shape as the misdiagnosis this phase also
corrects. Both are now pinned by tests, and both mutations were confirmed to kill them.

**Review found the driver had no tests at all, only the planner.** Three one-line mutations to
the part that runs left a fully green matrix: ignoring a failing interpreter, deleting the
refusal on an empty matrix, and pointing every shim at the first entry — that last one ran gawk
twice while printing `run 2/2: mawk`. The planner was tested because it is easy to test. The
driver was not tested because testing it needs a controlled `PATH`, and the gap was the exact
shape of the thing this phase exists to prevent.

Closing it needed three changes beyond the tests. The inner run now receives the version the
driver announced and checks the awk it actually got against it, because no outer assertion can
see which binary a shim executed. The plan-report-refuse prelude was written twice, once per
entry point, so a mutation deleting the refusal from one left the other printing it — the guard
had two code paths and the suite proved neither; it is now one function. And `tests/run.sh` had
lost its `FILTER` assignment, which made the selection pattern `**`: every inner run became a
full run, and the new driver tests spawned matrices of matrices until the machine ran out of
processes. Nothing failed. The suite was green all the way down.

Ten mutations, ten dead tests: dropping a candidate, skipping an absent interpreter silently,
passing over an empty matrix (both entry points), dropping the dedupe, indexing the label off
the display list, dropping the version from discovery, ignoring a failing interpreter, running
the wrong binary behind the shim, and withholding the announced version from the inner run.

**`tests/README.md`'s cause was wrong and is corrected.** It said `mawk` has no interval
expressions and reads `{3,}` literally. `mawk` 1.3.4 has them and matches them minimally where
`gawk` matches maximally — `a{2,3}` on `aaaa` gives `RLENGTH` 2 against 3. A literal reading
would match nothing, which is loud; a minimal match returns a shorter answer, which for a
fence-length computation is silent and wrong. The correction matters in the direction that was
under-weighting the risk.

CI is untouched. It will now run the matrix against whatever `ubuntu-latest` provides and
report the rest as not found, which is the honest state until phase `b` installs them.

## Dependency structure

Strict chain: `a → b`. `b` states a claim that only `a` makes true. Writing the claim first
would publish a sentence nothing holds, which is the failure mode #0014 closed and this brief
inherits.

## Open decisions

1. **Where the supported-interpreter claim is written.** `tests/README.md` is where a
   contributor meets it; `docs/contracts/README.md` beside promotion criterion 1 is where a
   promoter meets it. Both, with one citing the other, is the third option and costs a second
   place to drift. Blocks `b`. Does not block `a`.

## Complications

1. **The brief was falsified by planning it.** Three claims in the filed draft — a live defect,
   an `sh` portability surface, and a cause for the #0014 phase `b` bug — were each measured
   before the ledger was written, and each was wrong. The brief carries an amendment note and a
   "What was wrong in the draft" section rather than a quiet rewrite. Recorded here because the
   measurement took about four minutes and would have been three phases of work if taken on
   trust, which is an argument for measuring at plan time rather than at phase-`a` time.

2. **`tests/README.md` currently misstates the cause of the bug it exists to teach.** It says
   `mawk` has no interval expressions and reads `{3,}` literally. `mawk 1.3.4` supports them
   and matches them minimally: `a{2,3}` on `aaaa` gives `RLENGTH` 2 under mawk and 3 under
   gawk. The distinction matters in the direction that makes it worse — a literal reading
   produces no match, which is loud, while a minimal match produces a *shorter* match, which
   for a fence-length computation is silent and wrong. Owned by phase `a`.

3. **The matrix multiplies suite runtime by the number of awks found.** The suite takes about
   40 seconds. Three awks is two minutes. No answer is planned in this brief beyond accepting
   it; if it becomes a real cost the response is a faster suite, not a narrower claim. Named so
   that a later slowdown is recognised as this decision rather than a regression.

4. **A matrix that tests what is present rewards a rich machine.** A contributor with one awk
   gets one run. That is acceptable only while the run says what it skipped. The moment the
   summary reads the same whether one or four interpreters ran, this brief has rebuilt the
   defect it was written to prevent — the same collapse the Contract README names under
   promotion criterion 1.

## What this unblocks

`BRIEFS-9` and `BRIEFS-10` are published `[judgment]` clauses that cannot be promoted until
promotion criterion 1 is met, and criterion 1 is what phase `b` writes down and phase `a` makes
true. Criteria 2 and 3 stay unmet after this brief: no per-code-path mutation inventory exists,
and neither clause has produced a finding on a record written without it in mind.
