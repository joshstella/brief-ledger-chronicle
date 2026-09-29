# The interpreter nothing pins

**Created:** 2026-09-29T14:20:00Z · **Author:** josh.stella@gmail.com
**Depends on:** #0014

## The finding

This toolkit's tools are POSIX shell and awk. Every test runs them under exactly one shell and
one awk — whichever the machine happens to have — and no test says which. A portability defect
is therefore invisible until it reaches a machine that differs, which for a toolkit whose whole
purpose is to install into other people's repositories is the wrong place to find it.

This is not hypothetical. `tests/README.md` carries a section titled "The interpreter you do
not have is the one that breaks", written because a fence-tracking awk program in #0014 phase
`b` returned a decoy value under `mawk`: that build had no interval expressions and read `{3,}`
as three literal characters. The fix was to spell the pattern as `` ````* ``. The fix is held by
a comment. During #0014 phase `c` review, reverting `` ````* `` to `{3,}` left all 335 tests
green, because that machine's `mawk 1.3.4 20240123` does support interval expressions. The
test suite cannot see the defect its own README documents.

## Why it matters more after #0014

Before #0014, that awk program served two reporting tools. Now it decides `BRIEFS-10`, a
published Contract clause. The escalation is stated in #0014's own terms:

| tier | what a misfiring interpreter costs |
|---|---|
| a reporting tool | one wrong line a reader can ignore |
| a `[judgment]` clause | one wrong line in a Contract-citing gate |
| a `[defect]` clause | someone else's build, for a ledger that is legal |

#0014 phase `d` decides when `BRIEFS-9` and `BRIEFS-10` become `[defect]`. "The interpreters
are tested" is a precondition for that promotion, which is why this draft exists rather than
the work being folded into `d`. The matrix is not #0014's subject — #0014 is about one reader
per format — and inflating a brief about shared readers into a brief about portability
infrastructure would make both harder to review.

## What is unknown

Two gaps, both recorded in #0014's ledger as unverified rather than verified:

**awk.** Only one implementation has ever run the suite. `mawk`, `gawk`, `busybox awk`, and
`onetrue awk` differ on interval expressions, on `length()` of an array, on `RS` as a regex,
on locale collation inside bracket expressions, and on how `printf` handles `%c`. The programs
in `tools/lib/status-line.sh` use bracket expressions, `match()` with `RSTART`/`RLENGTH`,
`substr`, `gsub`, and a multi-rule `END`. Which of those are safe here is currently a belief.

**sh.** `tools/lib/phase-row.sh` uses `case` bracket expressions built from a variable —
`["$BLC_LOWER"]` — plus `set -f`, `${#1}`, and `${token%%:*}`. #0014 phase `c` review confirmed
bash and dash agree across thirteen inputs. `busybox sh`, `ksh`, `mksh`, and `zsh` were not
installed and could not be installed, so they are unknown. The installer's own scripts are
`#!/usr/bin/env bash` and need no matrix; the `tools/` scripts and `tools/lib/` are
`#!/bin/sh`-shaped and ship into unknown environments, so they do.

## Shape of the work

The likely answer is a loop in `tests/run.sh` over each interpreter present on the machine,
skipping absent ones by name rather than silently. Two design questions are real and should be
decided in the brief, not here:

**A skipped interpreter must not read as a tested one.** The repository's position is that
collapsing "no check exists" into "the check passed" is the defect class the Contract was
extracted to prevent. A matrix that quietly tests one awk on a developer's laptop and four in
CI, reporting the same summary line for both, rebuilds exactly that. The run needs to say which
interpreters it used.

**Which interpreters are required, and where.** Requiring four awks locally would make the
suite unrunnable for a contributor and get routed around, which this repository's values
section already predicts. Requiring them only in CI means the local run proves less than it
appears to. The plausible split is: local runs test what is present and name the gaps; CI
installs the matrix and is the gate. That is a decision with a cost either way.

## What this is not

Not a rewrite of the awk programs to a lowest common subset. That trades a testable property
for an untestable style rule, and the #0014 fix that started this — `` ````* `` for `{3,}` —
was already the portable spelling. The goal is to know, not to avoid knowing by writing less.

Not a promise that every interpreter is supported. A matrix that runs three awks and names the
third as failing is a better artifact than one that claims four and tests one.
