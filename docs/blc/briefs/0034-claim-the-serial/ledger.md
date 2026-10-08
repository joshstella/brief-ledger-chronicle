# Ledger — #0034 Check the status of the repo for serials not on main yet

`blc/2 #0034 done a:done(PR#145) b:done(PR#146)`

**Brief:** `docs/blc/briefs/0034-claim-the-serial/brief.md`
**Status:** done
**Started:** 2026-10-08
**Closed:** 2026-10-08

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | remote serial scan | done | `brief/0034-a-remote-serial-scan` | [#145](https://github.com/joshstella/brief-ledger-chronicle/pull/145) |
| b | contract v1.5 recovery rule | done | `brief/0034-b-contract-v15` | [#146](https://github.com/joshstella/brief-ledger-chronicle/pull/146) |

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
  stamps.** *Resolved before `b` was written.* The contributors decide between them and record
  the decision in both ledgers. A same-second tie is vanishingly rare, and an invented
  fallback — lowest email, fewest inbound links, least work to move — would look objective
  while settling a question it has no standing to settle.
- **Phase `b`: whether the worked example names the contributors.** *Raised and resolved
  during `b`.* It does not. `install.sh` ships `docs/blc/contracts/*.md` into every target
  repository, so names in a Contract travel to projects that have no idea who they are. The
  example describes the two filings by their times and by what each contributor could do. The
  mechanism teaches the rule; the names do not.

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

## Settled while building `b`

**v1.5 adds no clause.** It changes the recovery rule for concurrent filing and nothing else.
That still needs a version, because the rule is normative text people follow and editing it
inside v1.4 would make every citation of v1.4 silently wrong. Superseded is not deleted.

**`orient` could point at a Contract that is not there, and the whole suite stayed green.**
Measured, not assumed: with `CONTRACT=` moved to a nonexistent `v1.9.md`, all 684 tests
passed. `#0033` listed the cost of a version bump and the list was incomplete, which is the
same defect one version later. Phase `b` moved that pointer, so phase `b` carries the guard.

Two guards, both reading two ends so neither can drift alone. The first takes the path out of
`orient.sh` and requires that the file exists **and** that it is the version the table marks
`current` — a superseded version is as wrong as a missing one, and quieter. The second
requires the version `orient` prints to equal the version it reads, because those are two
literals in one file and a bump can move one. Neither pins a version number, so neither needs
editing at the next bump, which is the hand-maintenance that caused the drift.

Mutations: `CONTRACT=` to a nonexistent version fails both guards. Printing v1.4 while reading
v1.5 fails the second. Leaving the table marking v1.4 `current` fails the first. A first
attempt to mutate the table with `perl` failed to compile and proved nothing; it was redone in
`python3` rather than counted as a passing result.

**A version cut by copying carries the old version's self-references.** Reading the new file
found two: "Every clause in version 1.4 is checked by `tools/validate-briefs.sh`" and "Every
clause in version 1.4 is scope `both`". Both are claims about the version they sit in, so both
were false the moment the file was saved as v1.5. Neither is a link, so nothing resolved wrong
and nothing could have caught them. The other mentions of 1.4, 1.3 and 1.1 in the same file
are history and are correct to leave — which is why a blanket rule against naming an older
version would be the wrong guard. Recorded for `_drafts/contract-citation-drift.md`: the hard
part of that brief is telling a self-reference from a citation, and this is a worked case.

**What `b` does not guard.** The recovery rule is prose, and no test can say whether it is the
right rule. The two guards prove the version pointers resolve, not that v1.5 reads correctly.
The two self-references above were found by reading, and the next pair would be too.

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

## What shipped

`tools/next-serial.sh` (`a`, [#145](https://github.com/joshstella/brief-ledger-chronicle/pull/145)),
which answers the next free serial after reading `docs/blc/briefs/` on every `origin` branch
as well as locally. `blc-create-brief` asks it instead of listing the directory itself. Against
the incident's own shape — a serial that exists only on a remote branch — it answers `0003`
where the old rule answered `0002`.

Contract v1.5 (`b`, [#146](https://github.com/joshstella/brief-ledger-chronicle/pull/146)).
The recovery rule for a serial collision turns on the `**Created:**` stamp, not on which brief
reaches `main` first. Equal or absent stamps are a decision the contributors make and record.
The both-already-merged case is covered, which v1.4 had no step for. The section states that
every mechanism this toolkit has for claiming a serial requires pushing to `main`.

Three guards that did not exist: the installer ships every tool in the tree, `orient` reads a
Contract that exists and is the one marked current, and `orient` prints the version it reads.

Every settled decision held. Two planned positions were overturned by measurement: the
install-list drift was planned as out of scope and taken into scope, and the missing-directory
case was written to report and now refuses.

## What the record shows that the brief did not predict

**The brief was filed as a prevention brief. The more consequential half was the rule.** The
remote read narrows a window. The recovery rule decides who loses a serial, and v1.4's version
of it measured push access while reading as a neutral tiebreak. The brief listed the rule
second.

**The published recovery procedure had no step for the state the incident was in.** v1.4
described renumbering on a branch before it merged; both colliding briefs had already merged.
This was not found by planning or by review. It surfaced when the person who filed the brief
asked whether any of this helped clean up the live collision — a question about the present,
not about the design.

**The suite was blind in three places, and each was measured rather than suspected.** A tool
absent from the installer's list installs nowhere, and both mutations of the new entry left
673 tests green. `orient` pointed at a nonexistent `v1.9.md` and 684 tests passed. `#0033`
had enumerated the cost of a version bump one version earlier, and its list was incomplete.

**Filing this brief reproduced the incident inside this repository.** A declaration was
written to `docs/blc/state/` before `blc-create-brief` ran, and the same command cleared it
minutes later, exactly as its step 5 says. It was never pushed, so no other checkout could
have seen it. The only claim this toolkit publishes needs a push to `main`, and that is the
access the first contributor did not have.

**A version cut by copying carries the previous version's claims about itself.** Two sentences
in the new file said "every clause in version 1.4" while describing version 1.5. Neither is a
link, so nothing resolved wrong and no test could have caught them.

**Two tests passed for the wrong reason before they were trusted.** One asserted "not `0002`",
which is also true of no answer at all, and passed while the tool did not exist. The ship-list
guard passed before the new tool was staged, when `git ls-files` had nothing to show it. Both
were found by asking why a green result was green.

## Open after close

- **The race is not closed, and this brief does not claim to close it.** Nothing publishes a
  reservation at filing time. Two checkouts can fetch the same `origin` seconds apart and both
  pick the same number. Closing it needs a push at filing time, which needs the access the
  incident was about.
- **Nothing proves an agent calls the tool.** `blc-create-brief` is prose. A run that counted
  the local directory by hand looks the same afterwards as a run that asked.
- **The fetch is unbounded and barely exercised.** Every test points `origin` at a directory on
  disk. A remote that accepts the connection and hangs stalls filing with no timeout, and
  there is no portable fix.
- **The live `#0018` collision is unrepaired.** A renumber checklist was written for whoever
  acts in that repository. It was not applied, and this repository was never read.
- **`_drafts/contract-citation-drift.md` is parked and now has a worked case.** Four citations
  of the superseded v1.3 are still in the tree, and `tests/test_contract_ship.sh` hand-lists
  versions to v1.3 and never asserts a newer one ships. The hard part of that brief is telling
  a self-reference from a citation, and `b` produced an example of each.
- Neither phase branch had a bug ledger, so no open correctness bugs were carried.

## What this cannot prove

- **The fixtures were written from a report, not from the colliding repository.** That
  repository was never opened. The timings, the branch names and the access levels are as they
  were described. A fixture built from a description can only reproduce the mechanism its
  author understood.
- **That the recovery rule is right.** It is prose. The two new guards prove the version
  pointers resolve; no test reads what v1.5 says.
- **That `Created` is true.** It is self-reported, written by whichever machine wrote the
  draft. A wrong clock or an edited line produces a wrong winner. v1.5 states that limit
  rather than hiding it, and it is still better than a rule that tests who can push.
