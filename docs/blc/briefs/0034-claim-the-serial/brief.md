# Check the status of the repo for serials not on main yet

**Serial:** #0034 · **Created:** 2026-10-08T16:06:54Z · **Author:** josh.stella@gmail.com · **Depends on:** —

Two contributors in a target repository filed two different briefs as `#0018` on the same
day, eight hours apart. Both reached `main`. `BRIEFS-3` fired after the merge, not before.

This is the first field instance of the limitation Contract v1.4 records under "Known
limitation — concurrent filing". The mechanism it describes is the mechanism that ran.

## What happened, as mechanism

Both filings started from the same `main`. The first contributor filed, wrote the ledger and
pushed — to a *branch*, because `main` in that project needs an access level they do not
have. `blc-start-brief` step 6 says to commit and push the ledger to `main` before cutting a
branch, so every other machine sees the serial as taken. Branch protection sent it elsewhere.
Their claim existed only on that branch, and the commit title still said "on main".

An hour later the second contributor filed the next serial. `blc-create-brief` reads the
highest `NNNN-` folder in the local `docs/blc/briefs/`, then checks `docs/blc/state/` for a
claim. On `main` the directory ended at `0017` and the first contributor's draft was still in
`_drafts/`, because the branch was what moved it. So `#0018` looked free. The branch and its
merge request had been on the server for an hour and the skill reads neither.

Neither contributor declared the work in `docs/blc/state/`. That step is the only mechanism
BLC has for the window between picking work up and filing it, and nothing enforces it.

Nothing checked at merge time. The two folders have different names, so the merge was clean.

## The finding the incident makes, which the brief did not start with

**Every mechanism BLC has for claiming a serial requires pushing to `main`.** The ledger
write at filing does. The `docs/blc/state/` declaration does. A contributor without that
access cannot publish a claim by any route the toolkit offers, so the declaration step was
not available to the person who needed it. The gap is not that they forgot.

**The published recovery rule rewards the wrong person.** v1.4 says the first brief to land
on `main` keeps the serial. Here the contributor who filed first, and followed the skill,
lost it — because they could not push. The one who could push kept it. The rule reads as a
neutral tiebreak and is really a test of access level.

## Settled before filing

1. Two changes, one brief: `blc-create-brief` reads serials claimed on branches, and the
   recovery rule stops turning on push access.
2. The remote read **narrows the window and does not close the race**, and must be reported
   that way. v1.4 already says so: two checkouts fetching the same `origin/main` still pick
   the same number. Closing it needs a reservation published at filing time, which needs the
   access the incident shows people do not have.
3. The tiebreak is the `**Created:**` stamp in the identity line. It is already in the
   record, `blc-create-draft` writes it at draft-write time, and it does not ask who can
   push. It is self-reported and that limit is stated rather than hidden.
4. In the incident, the earlier `Created` keeps `#0018`.

## Out of scope, recorded

The two project-owned fixes belong to the target repository, not here: letting filings reach
`main` promptly, and running `tools/validate-briefs.sh` in its pipeline. The gate already
detects the end state — two folders on one serial report `BRIEFS-3 [defect]` and exit 1 —
so that fix needs no change from this toolkit, only a pipeline that calls it. Verified
against a fixture rather than assumed.
