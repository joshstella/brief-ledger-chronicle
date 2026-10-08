# Ledger — #0034 Check the status of the repo for serials not on main yet

`blc/2 #0034 in-progress a:in-progress(brief/0034-a-remote-serial-scan) b:pending`

**Brief:** `docs/blc/briefs/0034-claim-the-serial/brief.md`
**Status:** in-progress
**Started:** 2026-10-08

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | remote serial scan | in-progress | `brief/0034-a-remote-serial-scan` | — |
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

- **Phase `a`: what the tool does when a branch is unreadable.** *Resolved before `a` was
  written.* It returns the local answer, exits 0, and names every source it could not read on
  stderr. Refusing to answer would stop a contributor filing offline, and this project reports
  rather than gates. A clean run prints nothing, because a warning printed every time is one
  nobody reads when it matters.
- **Phase `b`: whether the recovery rule names a tiebreak for equal or absent `Created`
  stamps.** Old briefs filed before `blc-create-draft` stamped provenance have no `Created`
  to compare. Blocks `b` only.

## Complications found while reading the code

- `install.sh` hand-lists the tools it ships, at line 438 and again in an echo at line 962.
  Planned as out of scope, with phase `a` adding its entries by hand. **Taken into scope
  after measuring it.** The existing coverage names tools one at a time — `assert_file
  "$TARGET/tools/open-briefs.sh"` and four more — so it proves those and says nothing about a
  fifth. Both mutations of the new entry, dropping it from the ship list and naming it only
  in the echo, left the entire suite green. The tool phase `a` adds would have installed
  nowhere, and no test would have said so. That is phase `a`'s own artifact going unproven,
  not general drift, so phase `a` carries the proof.
- `tests/run.sh` discovers test files by glob, so a new test file needs no registration.
- The `**Created:**` stamp this brief makes load-bearing is self-reported. A wrong clock or
  a hand-edited draft produces a wrong winner. The Contract states that limit rather than
  hiding it; it is still better than a rule that tests who can push.
- Four citations of the superseded `v1.3.md` are still in the tree, and
  `tests/test_contract_ship.sh` hand-lists versions up to v1.3 and never asserts v1.4
  ships. Found while filing this brief. Out of scope by decision — parked as
  `_drafts/contract-citation-drift.md`, which depends on this brief because phase `b` moves
  the target again.

## Settled while building `a`

**The test that proves the fix had to fail for the right reason first.** The first version of
`next_serial_local_only_answer_would_have_been_wrong` asserted the answer was not `0002`. That
was true while `tools/next-serial.sh` did not exist, because no answer is also not `0002`. It
passed against nothing. It now checks there is an answer before checking which one.

**The new ship-list guard passed before it could see anything.** `tools/next-serial.sh` was
not staged, so `git ls-files` did not list it and the scan had nothing to find. Both
mutations were run again after staging. Reading the index rather than the filesystem is
deliberate and matches the mode check beside it: the index is what a fresh clone gets.

**Two test failures were the fixture, not the program.** The empty-registry test deleted
`0001` locally and did not push, so `origin/main` still carried the serial and `0002` was the
correct answer. The stderr test asserted a word the program does not use. Both were fixed in
the test, and the program was left alone.

**The review gate found two defects in the program it was reviewing.** A stray `0033-notes.md`
beside the brief folders counted as a filed serial, because the scan matched entry names and
not entry types. The unit of a brief is a folder, so both halves of the scan now read
directories only. And `raise` ends with an explicit `return 0` that carried no comment; it is
there because the loop's last statement is an AND-list returning 1 whenever the final serial
is not a new maximum, which under `set -e` would end the scan partway on the ordinary input
where the highest serial is not the last one read.

**The missing-directory case refuses instead of answering.** It was written to warn and answer
`0001`, consistent with reporting rather than gating. That is wrong here, and the mutation
shows why: with the refusal removed, the program answers `0001` for a briefs directory that is
not there. A tree whose briefs live somewhere else — the pre-`#0017` `docs/briefs/` layout, or
a caller run from the wrong directory — is indistinguishable from a tree with no briefs, and
`0001` would collide with every brief already filed. The program would cause the collision it
was written to prevent. A warning does not help a caller reading stdout.
`tools/validate-briefs.sh` refuses the same input for the same reason. Every other unread
source costs accuracy; this one costs correctness, and that is the line.

**Filing now makes a network call, and it has no timeout.** `git fetch` against a remote that
accepts the connection and then hangs will stall `blc-create-brief` with no bound. There is no
portable fix: `timeout` is absent from a stock macOS. Recorded as a known cost of reading the
remote rather than papered over.

**Mutation results.** Removing the branch scan fails
`next_serial_sees_a_serial_that_exists_only_on_a_remote_branch` and
`next_serial_local_only_answer_would_have_been_wrong`. Silencing the fetch warning fails
`next_serial_says_on_stderr_what_it_could_not_read`. Dropping either half of the folder-only
rule, `-type d` locally or `-d` on the branch scan, fails
`next_serial_does_not_count_a_four_digit_file_as_a_brief`. Turning the missing-directory
refusal back into a warning fails `next_serial_refuses_a_briefs_directory_that_is_not_there`,
with the answer `0001`. Dropping any tool from the ship list,
new or old, fails `source_tree_every_tool_is_in_the_installer_ship_list`. Every restore was a
file copy, not `git checkout`, which during `#0033` restored from an index that still held the
pre-fix version and made a mutation result meaningless.

## Not proven by `a`

- **That an agent calls the tool.** `blc-create-brief` is prose. The tool is tested and its
  invocation is not, so a run that counted the local directory by hand looks the same
  afterwards as a run that asked. This project already names that: a skill guard is not a
  check.
- **The fetch against anything but a local path.** Every test points `origin` at a directory
  on disk, which exercises a real fetch and no network. Authentication failure, a slow link,
  and a remote that hangs are unexercised.

## Observed while filing

A declaration was written to `docs/blc/state/` before `blc-create-brief` ran, and cleared by
the same command minutes later. It was never pushed, so no other checkout could have seen
it. That is the incident's mechanism reproduced in this repository: the only claim BLC
publishes needs a push to `main`, and a claim that is not pushed protects nobody.
