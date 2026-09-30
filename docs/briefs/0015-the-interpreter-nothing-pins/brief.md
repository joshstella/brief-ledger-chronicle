# The interpreter nothing pins

**Serial:** #0015 · **Created:** 2026-09-29T14:20:00Z · **Author:** josh.stella@gmail.com · **Depends on:** #0014

> **Amended 2026-09-29, before execution.** The draft this brief was filed from asserted a live
> defect, a second interpreter axis, and a cause for the original bug. Measuring all three
> before writing the ledger falsified all three. The amendment is recorded rather than applied
> silently, and the "What was wrong in the draft" section below keeps the original claims
> visible: a brief that quietly becomes correct teaches nothing about how it was incorrect.

## Ground

#0014 shipped `BRIEFS-9` and `BRIEFS-10`, and `BRIEFS-10` is decided by an awk program in
`tools/lib/status-line.sh`. Its phase `d` wrote the criteria for promoting a `[judgment]` to a
`[defect]`, and criterion 1 is that the check runs under every interpreter this toolkit claims
to support, with the claim stated. No such claim exists, and no test names an interpreter. So
`BRIEFS-9` and `BRIEFS-10` cannot be promoted until this brief is done, which is the reason it
exists and the reason it is small.

## The claim

**The suite states which interpreters it ran under, runs under every one present, and names
the ones it did not find.**

There is no defect to fix. The value is a guard where there is currently a comment, and a
stated claim where there is currently an assumption.

- `tests/run.sh` runs the suite once per available `awk`, and prints which.
- An absent interpreter is reported by name, never skipped in silence.
- The supported set is written down, so criterion 1 can be met by testing rather than by
  narrowing the claim at promotion time.

## Evidence

**1. The suite has been running under gawk, not the `mawk` the record discusses.** `awk` on the
development machine resolves to GNU Awk 5.2.1. `mawk 1.3.4` is installed alongside it and has
never run the suite. "One implementation" was true; which one was unexamined.

**2. There is no live defect.** Forcing `awk` to `mawk` for a whole run gives **336 passed, 0
failed**. Both awks return identical results from `blc_status_line` on a real ledger. The
shipped fence pattern `` ````* `` is correct under both.

**3. The recorded cause of the original bug is wrong, and the real one is worse.**
`tests/README.md` says `mawk` "has no interval expressions and reads `{3,}` literally". mawk
1.3.4 supports interval expressions. It matches them **minimally** where gawk matches
maximally:

| pattern | input | gawk `RLENGTH` | mawk `RLENGTH` |
|---|---|---|---|
| `a{2,3}` | `aaaa` | 3 | 2 |
| `` `{3,} `` | six backticks | 6 | 3 |
| `` ```` `* `` | six backticks | 6 | 6 |

A fence tracker that computed its delimiter length with `{3,}` would read a six-backtick fence
as three under mawk, and then close it on any later run of three — silently, with no error.
"Reads it literally" would have produced no match at all, which is loud. The misdiagnosis made
the failure sound louder than it is.

That this sits in `tests/README.md` — the file #0014 wrote its lessons into — is the point.
#0014 was filed because a written instruction and a mechanism drifted apart while the suite
stayed green. Its own lesson file records a cause that does not match the mechanism.

**4. There is no `sh` surface.** Every script in `tools/` and `install.sh` declares
`#!/usr/bin/env bash`. `tools/lib/*.sh` is sourced by those bash scripts and never executed. No
part of this toolkit runs under `dash`, `busybox sh`, `ksh`, or `zsh`, so a shell-family matrix
would test a configuration that cannot occur.

**5. The untested shell axis is bash *version*, not bash *family*.** macOS ships bash 3.2, and
this toolkit installs into repositories on macOS. No bash 4+ construct appears anywhere —
no `declare -A`, no `mapfile`/`readarray`, no `${var,,}`. That makes 3.2 likely fine and
unverified, which is the state this brief exists to end, but it is a different axis from awk
and is not required by criterion 1.

## Change

| Phase | Work |
|---|---|
| `a — the awk matrix` | `tests/run.sh` discovers every `awk` on `PATH` — `awk`, `gawk`, `mawk`, `busybox awk`, `original-awk` — runs the suite under each, and prints the list with versions. An interpreter that is not installed is named as not found. Correct `tests/README.md`'s misdiagnosis in the same phase: the section is about this exact failure and is currently wrong about it. |
| `b — the stated claim` | Write the supported-interpreter claim where a reader and a promoter both meet it, and make CI install the matrix so the gate is not vacuous. Record bash 3.2 as a known-unverified axis rather than implying it is covered. |

Strict chain. `b` states a claim that `a` is what makes true.

## Tension

**A matrix makes every future awk program slower to write and easier to get right.** Running
the suite four times costs four times the wall clock, on a suite that already takes ~40
seconds. The honest trade is that this is a toolkit whose output is a gate in someone else's
repository, and a gate that misfires on their awk is worse than a slow suite here. If the cost
becomes real, the answer is a faster suite, not a narrower claim.

**Testing what is present rewards a rich machine.** A contributor with one awk gets one run and
a list of what was not tested; CI gets the full matrix. That gap is acceptable only because the
local run *says* what it skipped. The moment it prints the same summary either way, this brief
has rebuilt the defect it was written to prevent.

## Open decisions

1. ~~**Where the supported-interpreter claim is written.**~~ **Settled in `b`: nowhere.** All
   three candidates were rejected. The set is `BLC_AWK_CANDIDATES` in `tests/run.sh`, guarded
   by a test; both documents state the rule and point at `bash tests/run.sh --matrix-plan`
   rather than copying the list. Reasoning in the ledger.

## Non-goals

**Not a rewrite of the awk programs to a lowest common subset.** That trades a testable
property for an untestable style rule, and the `` ````* `` spelling was already the portable
one. The goal is to know, not to avoid knowing by writing less.

**Not a promise that every interpreter is supported.** A matrix that runs three awks and names
the third as failing is a better artifact than one claiming four and testing one.

**Not bash 3.2 verification.** Recorded in evidence 5, and it needs a 3.2 binary this project
does not have. It is a candidate for its own brief, not a phase here.

## What was wrong in the draft

Kept because the corrections are the useful part of the record.

- *"Only one implementation has ever run the suite"* — true, but the draft assumed it was
  `mawk`. It was gawk, and mawk was installed the whole time and never used.
- *"The test suite cannot see the defect its own README documents"* — there is no defect. The
  suite passes under both awks. What is missing is a guard, not a fix.
- *"that build had no interval expressions and read `{3,}` as three literal characters"* —
  false, and inherited from `tests/README.md`. mawk supports intervals and matches them
  minimally.
- *The whole `sh` section, and a shell matrix over `busybox sh`, `ksh`, `mksh`, `zsh`* — there
  is no `sh` surface. Every script declares bash. The #0014 phase `c` review's "could not
  verify under busybox sh" is moot for the same reason.
