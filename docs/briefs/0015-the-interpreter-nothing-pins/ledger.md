# Ledger — #0015 The interpreter nothing pins

`blc/2 #0015 pending a:pending b:pending`

**Brief:** `docs/briefs/0015-the-interpreter-nothing-pins/brief.md`
**Started:** 2026-09-29
**Status:** pending

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the awk matrix | pending | — |
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
