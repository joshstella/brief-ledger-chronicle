# Ledger — #0025 Stale branches nothing prunes

`blc/2 #0025 in-progress a:done(PR#116) b:done(PR#117) c:in-progress(brief/0025-c-the-skill) d:pending`

**Brief:** `docs/blc/briefs/0025-prune-stale-branches/brief.md`
**Started:** 2026-10-06
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the proof | done (PR#116) | `brief/0025-a-the-proof` |
| b | the deletion | done (PR#117) | `brief/0025-b-the-deletion` |
| c | the skill | in-progress | `brief/0025-c-the-skill` |
| d | orient points at it | pending | — |

**a — the proof.** A new `tools/stale-branches.sh` classifies every local branch and writes
nothing. A branch is proven stale only when one of three tests passes: its tip is an ancestor
of the trunk, its tip equals the head of a pull request that merged into the trunk, or merging
it into the trunk changes the trunk's tree. The script names which test proved each branch, and
for every branch it could not prove it reports the commits that are not in the trunk and says
so plainly. It never prints "merged" for a branch no test proved. Test 2 needs a forge, through
`tools/detect-forge.sh`, and the script says when that test did not run rather than silently
reporting on two tests. Test 3 needs git 2.38 for `merge-tree --write-tree`, and the same rule
applies.

**b — the deletion.** The same script gains `--delete`. It deletes only branches the proof
covers, and refuses every other branch whatever is asked of it. Before each deletion it writes
`refs/blc/pruned/<name>` at the tip, which keeps the objects reachable past `git gc`. This is
the phase that makes decision 1 worth anything: the dangerous verb is in a file the suite can
assert, not in a paragraph an agent reads.

**c — the skill.** `blc-prune-stale-branches` fetches, runs the script, shows the
classification, asks a person, and then calls `--delete`. The skill owns the conversation and
owns no logic. The phase also covers whatever the installer needs to ship a twelfth skill.

**d — orient points at it.** One line in `tools/orient.sh` naming the count of prunable
branches, printed only when the count is not zero. Waits on decision 5, and runs only if that
line can be produced without a forge call and inside the existing budget.

## Dependency structure

`a` then `b` then `c` is a strict chain. `b` deletes what `a` proved, and `c` drives `b`.

`d` is independent of `c` and depends on `a`, because the count it would print comes from the
classifier. It is last because it is the only optional phase, and it is provisional on decision
5.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | **Settled 2026-10-06: the script deletes, behind `--delete`.** The deletion is the step that must not be wrong, and this repository already holds that a script can be asserted by the test suite and an instruction to an agent cannot. Putting the deletion in the skill would place the only irreversible verb in the toolkit in the one artifact nothing checks. The flag adds no risk that is not already present: an agent that can be told to delete can run `git branch -D` directly. It adds a test. | `b`, `c` |
| 3 | **Settled 2026-10-06: `refs/blc/pruned/<name>` at the tip, before each deletion.** One `git update-ref`, and the objects stay reachable past `gc.pruneExpire`. The question in the brief assumed the net catches lost work. It does not: decision 2 offers only proven-stale branches, and the proof is that the work is already in the trunk. The net catches a bug in the prover. That is a weaker thing to buy, and it is worth one line rather than a bundle file somebody has to find and remove. Rejected: no net at all, which is correct if the prover is correct and gives nothing to examine when it is not; and `git bundle`, which keeps the objects in a file outside the repository that nobody will ever clean up. | `b` |
| 4 | **Settled 2026-10-06: local branches only.** A remote deletion reaches every clone and needs the forge for both the proof and the act. The 82-branch cleanup that produced this brief's evidence was remote, so this is the smaller half of the problem by deliberate choice — the prover is the hard part and it is shared. Remote branches get their own brief once the prover has been used. | `a`, `b`, `c` |
| 2 | **Settled 2026-10-06: only proven branches are offered.** The brief's own proposal stands. Every other branch is reported with its commits that are not in the trunk, for a person to read. The output must never say "merged" for a branch that no test proved, because that sentence is what made the 2026-10-05 name match look safe. | `a`, `b` |
| 6 | **Settled 2026-10-06: the skill fetches first, and not for the reason the brief gives.** The brief ties the fetch to `[gone]` freshness, but `[gone]` is not one of the three tests. Tests 1 and 3 compare against the local trunk ref, so a stale trunk under-reports — it proves fewer branches than it should, which is the safe direction but still wrong. The fetch is for the trunk. It belongs to the skill, because a person started that run and a fetch is a network call. | `c` |

## Open decisions

| # | decision | blocks |
|---|---|---|
| 5 | **Whether orient prints a line about prunable branches.** From the brief. It costs tokens in every run of a 700-token budget, and orient must not call a forge, so the line could rest on tests 1 and 3 only — which under-counts against a rule whose strongest test is 2. A count that is quietly partial is the failure mode #0024 just closed. Decide after `a`, when the cost of the two offline tests is known. | `d` |

## Complications

Found while reading the code for this plan. None is in the brief.

- **`tests/test_prune.sh` already exists.** It covers pruning stale skills and commands from the
  install log (#0012c), and every function in it is named `test_prune_*`. The suite filters on
  that prefix, so `bash tests/run.sh test_prune` would run both sets. The new file takes a
  different prefix, `test_stale_*`.
- **The self-host skill links.** ~~Untracked hardlinks.~~ **Corrected in `c`: this was wrong.**
  `.cursor/skills` is itself one tracked symlink to `skills/`, which is why a file under it
  shares an inode with its source and why `git ls-files` reports no path beneath it. The Claude
  side is different: `.claude/skills/<name>` is a tracked relative symlink per skill. So Cursor
  needs nothing for a twelfth skill and Claude needs one committed link. `tools/orient.sh` calls
  these "committed links", which is right — the error was mine. Found by
  `self_host_every_row_a_target_gets_resolves_here` failing in `c`.
- **`PROCESS_SKILLS` is a roster of six, not of all skills.** `install.sh:30` names the six that
  each host is promised, and `install.sh:800` asserts against it. `blc-orient`, `blc-chronicle`,
  `blc-my-briefs`, `blc-installer-builder` and `blc-ste-writing` are not in it. A prune skill is
  not a process skill by that standard, so `c` most likely leaves line 30 alone — which is a
  thing to check rather than assume, because the count at `install.sh:932` is derived from it.
- **Test 3 is useless across a large rename.** The brief records that `merge-tree` failed for all
  five branches it was asked about, because those branches carry paths from before the #0017
  move to `docs/blc/`. Merging any of them adds the old paths back, so the tree differs. Tests 1
  and 2 do the work; test 3 earns its place on recent branches only, and `a` should say so where
  it implements it rather than leave a reader to discover it.

## Branches

`brief/0025-a-the-proof` (phase `a`).
`brief/0025-b-the-deletion` (phase `b`).
`brief/0025-c-the-skill` (phase `c`).

## Decisions added during execution

| # | decision | blocks |
|---|---|---|
| 7 | **Settled 2026-10-06 (`a`): the trunk is whichever of `origin/main` and local `main` is further along, and the program says which.** Not in the brief, and found by running the prover for the first time: an unpushed commit on local `main` made it report a branch as carrying work the trunk already had. Decision 6 says a stale trunk under-reports, which is the safe direction. This is the same mechanism pointing the other way, and the report is what a person acts on. A local trunk wins only when it is a descendant of the remote; diverged trunks keep `origin/main`, because that is the conservative answer and divergence is a different problem. | `a`, `b`, `d` |
| 8 | **Settled 2026-10-06 (`b`): `--delete` takes branch names and nothing else.** A bare `--delete` that removed everything currently proven would make the dangerous reading of this program the shortest one to type, and would act on a classification nobody had read. With no names it exits 2 and deletes nothing. Rejected: one flag with no arguments, which is fewer keystrokes for the skill and gives a person no way to keep one branch out of the set. | `b`, `c` |
| 9 | **Settled 2026-10-06 (`b`): a second prune of the same name keeps both tips.** `refs/blc/pruned/<name>`, then `-2`, `-3` as needed. A name can be pruned twice with a different tip each time, and overwriting would discard the only copy of the earlier one. Rejected: overwrite, which is simpler and loses a tip; and refusing the name, which is safest and permanently blocks re-pruning a recreated branch. | `b` |

## Phase `a`, as executed

`tools/stale-branches.sh` classifies every local branch against the trunk and writes nothing —
not a ref, not a file. Default output is for a person; `--tsv` is for `b` and `d`.

The three tests run in order of strength and the first to pass wins. `ancestor` proves a merge
commit or a fast-forward. `pr` proves a squash merge, which is the merge this toolkit performs
and the only one the other two cannot see. `tree` proves content that reached the trunk by
some other route and needs no forge.

**The `pr` test requires the base, not only the state.** A pull request merged into a release
branch, or into another feature branch, has the state merged while its work is not in the
trunk. The brief's rule read the state alone, which proves that a merge happened somewhere.
The filter is applied in the program rather than in the forge query, so the rule is in the
file the suite can assert.

**A fixture has no forge, so `BLC_MERGED_PRS` names a file to read instead.** `pr` is the only
test that proves the merge this toolkit actually performs, and a prover whose strongest test is
never exercised is the defect this brief was filed about. The override carries the base as well
as the head, so the rule above is exercised rather than bypassed.

**Two rules proven by mutation.** Removing the base filter fails
`stale_rejects_a_pull_request_merged_into_another_base` and nothing else. Forcing the remote
trunk fails all three trunk tests. Both rules came from findings rather than from the brief,
which is why each was mutated rather than trusted.

**The tool did not ship, and the suite passed anyway.** `install.sh` names every tool it
places, and `tools/stale-branches.sh` was written, tested and mutation-proven while absent from
that list. 588 tests passed for a file no target could ever receive. `install.sh` now names it,
and `test_ownership_every_tool_in_the_source_is_declared` compares the source tree against the
ownership map, so the next omission fails rather than passes. This is the shape
`tests/test_source_tree.sh` was written for: the suite watching the copy, on the far side of
the step that produces it. Here there was no copy to watch, because the file was never named.

**A hollow assertion hid a real defect, and the review found it.** The test for the commit
listing asserted the branch name. The name is printed whatever the listing does, so the test
passed while the listing printed nothing at all. Strengthened to assert a commit subject, it
failed immediately. The cause: `IFS=$'\t'` collapses runs of tabs, because tab is IFS
whitespace. A line written as `branch<TAB><TAB>tip` read back as two fields, so the tip landed
in the wrong variable, `git log` ran on an empty range, and `2>/dev/null` swallowed the
complaint. The `--tsv` tip was empty for every unproven branch for the same reason, and the
test there asserted only the status and the name.

Both are now asserted at full width, and the mutation that reproduces the defect is on the
reader rather than the writer — a two-field reader tolerates the extra tab, so mutating the
written line proves nothing. That took two attempts to get right.

The suite is 589, from 574.

## Phase `b`, as executed

`--delete` on the same script. It takes branch names, proves each one again, writes the tip to
`refs/blc/pruned/` and then removes the branch.

**Every named branch is proven again at deletion.** The report and the deletion are two
commands with a person in between, and a branch can gain a commit in that gap. That is the
2026-10-05 case exactly: a tip that no longer matches the merged pull request it was credited
to. A test drives the whole sequence — report, commit, delete — and asserts the refusal.

**Four refusals, each its own exit.** The trunk, the checked-out branch, a name that is not a
branch, and a branch no test proves. A refusal does not stop the other names: each branch is
its own decision, and the run exits non-zero if anything was refused.

**An absent forge does not block deletion.** A test that could not run shrinks what is proven;
it cannot make a proof wrong. So a missing `gh`, or a GitLab target, deletes fewer branches and
never the wrong one. Stated here because the opposite rule looks more careful and is not.

**Five guards, all proven by mutation.** Removing the re-proof fails three tests. Overwriting
the saved tip fails the two-prunes test. Dropping the trunk refusal, the no-names guard, or the
checked-out refusal each fails exactly its own test.

**The checked-out refusal is not redundant with git's.** `git branch -D` refuses the current
branch on its own, so the guard looked like the dead code removed from `install.sh` in #0023.
It is not: the tip is saved before the branch is removed, so letting git do the refusing leaves
a ref behind for a branch that is still there. The mutation showed it, and the reason is now a
comment at the site.

The suite is 599, from 589.

## Phase `c`, as executed

`skills/blc-prune-stale-branches` fetches, runs the script, shows what it proved, asks, and
calls `--delete` with the names a person gave. It owns the conversation and owns no logic.

The skill carries three things a reader cannot derive from the script. It says to fetch first,
because the script makes no network call and a trunk that is behind proves fewer branches than
it should. It says to read the output rather than the exit code, because a refusal makes the
run exit non-zero even when other branches were deleted. And it says where the saved tips go
and that nothing removes them, so a person learns from the run that creates them that the
repository is accumulating something.

It also says not to offer a branch under "Not proven". A person who wants one gone can run
`git branch -D` themselves; that should be their own act rather than the agent's.

**The tests here assert prose, and that is the weakest thing in this brief.** Nothing can show
that an agent follows a skill — which is the reason the classification and the deletion are
both in the script. What these stop is the wiring rotting: a skill that stops naming its tool,
or loses the one instruction only it can carry.

**A complication recorded in `a` was wrong, and `c` found it.** `a` said the self-host skill
links are untracked hardlinks and that a twelfth skill needs no committed link. Adding the
skill failed `self_host_every_row_a_target_gets_resolves_here` for Claude. `.cursor/skills` is
one tracked symlink to `skills/`, which is why a file beneath it shares an inode with its
source; `.claude/skills/<name>` is a tracked symlink per skill. Cursor needed nothing, Claude
needed a link, and the correction is above the original rather than in place of it.

The suite is 605, from 599.
