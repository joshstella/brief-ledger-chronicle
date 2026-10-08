# Ledger — #0034 Check the status of the repo for serials not on main yet

`blc/2 #0034 pending a:pending b:pending`

**Brief:** `docs/blc/briefs/0034-claim-the-serial/brief.md`
**Status:** pending
**Started:** 2026-10-08

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | remote serial scan | pending | — | — |
| b | contract v1.5 recovery rule | pending | — | — |

**a — remote serial scan.** Adds `tools/next-serial.sh`, which reports the next free brief
serial after reading serials claimed on the remote as well as in the local directory. It
fetches, then lists `docs/blc/briefs/` on every `origin` branch with `git ls-tree` and
parses the `NNNN-` prefixes. `blc-create-brief` calls it at step 1 instead of listing the
local directory alone. The tool degrades rather than fails when there is no remote or the
fetch does not work: it reports what it could not read and returns the local answer. Ships
a test file and an entry in the two hand-written tool lists in `install.sh`.

**b — contract v1.5 recovery rule.** Cuts `docs/blc/contracts/v1.5.md` from v1.4 and
rewrites "Known limitation — concurrent filing". The recovery rule stops turning on which
brief reaches `main` first and turns on the `**Created:**` stamp in the identity line. The
`#0018` collision goes in as the worked example, with the earlier `Created` keeping the
serial. The section also records that phase `a` is now built and that it narrows the window
without closing the race. Moves every pointer to the current version.

## Dependency structure

A strict chain. Phase `b` states in the Contract what phase `a` built, including the
sentence "that is not built", which is only false once `a` lands. Running them in parallel
would make `b` describe a tool that might still change shape.

## Decisions settled before planning

- **One brief, two changes.** The remote read and the recovery rule ship together because
  the incident is one finding, not two.
- **The fix is a tool, not skill prose.** This project holds that a skill guard is not a
  check. A rule stated only in a skill cannot be tested and cannot be mutated, so a run
  that skipped it looks the same afterwards as a run that followed it.
- **The scan reads trees, not branch names.** Branch names would be one cheap call and
  `brief/NNNN-a-slug` already carries the serial, but a serial is filed before any phase
  branch exists. In the incident that window was seventeen minutes. Listing
  `docs/blc/briefs/` on each branch sees the folder itself and costs one call per branch.
- **Report as narrowing, not closing.** Two checkouts can fetch the same `origin` and still
  pick the same number, because nothing publishes the claim. v1.4 already says so and v1.5
  keeps saying it.
- **Mark keeps `#0018`.** He filed first and followed the skill. The written rule penalised
  him for lacking push access.

## Open decisions

- **Phase `a`: what the tool does when a branch is unreadable.** Skipping it silently makes
  the tool claim knowledge it does not have. Resolve before `a` is written, not during.
- **Phase `b`: whether the recovery rule names a tiebreak for equal or absent `Created`
  stamps.** Old briefs filed before `blc-create-draft` stamped provenance have no `Created`
  to compare. Blocks `b` only.

## Complications found while reading the code

- `install.sh` hand-lists the tools it ships, at line 438 and again in an echo at line 962.
  A new tool is absent from the install until both are edited, and nothing fails if only
  one is. This is the same shape as `#0032`'s process-skill list. Out of scope here;
  phase `a` adds its entries by hand and records that it had to.
- `tests/run.sh` discovers test files by glob, so a new test file needs no registration.
- The `**Created:**` stamp this brief makes load-bearing is self-reported. A wrong clock or
  a hand-edited draft produces a wrong winner. The Contract states that limit rather than
  hiding it; it is still better than a rule that tests who can push.
- Four citations of the superseded `v1.3.md` are still in the tree, and
  `tests/test_contract_ship.sh` hand-lists versions up to v1.3 and never asserts v1.4
  ships. Found while filing this brief. Out of scope by decision — parked as
  `_drafts/contract-citation-drift.md`, which depends on this brief because phase `b` moves
  the target again.

## Observed while filing

A declaration was written to `docs/blc/state/` before `blc-create-brief` ran, and cleared by
the same command minutes later. It was never pushed, so no other checkout could have seen
it. That is the incident's mechanism reproduced in this repository: the only claim BLC
publishes needs a push to `main`, and a claim that is not pushed protects nobody.
