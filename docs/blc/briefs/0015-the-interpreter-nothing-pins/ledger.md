# Ledger — #0015 The interpreter nothing pins

`blc/2 #0015 done a:done(PR#66) b:done(PR#67)`

**Brief:** `docs/blc/briefs/0015-the-interpreter-nothing-pins/brief.md`
**Started:** 2026-09-29
**Status:** done
**Closed:** 2026-09-30

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the awk matrix | done | PR#66 |
| b | the stated claim | done | PR#67 |

**a — the awk matrix.** `tests/run.sh` discovers every `awk` on `PATH`, runs the suite under
each, and prints which ones it used with their versions. An absent interpreter is named as not
found rather than skipped in silence. Corrects the misdiagnosis in `tests/README.md` in the
same phase, because that section is about this exact failure and is currently wrong about its
cause.

**b — the stated claim.** Writes the supported-interpreter claim where both a contributor and a
promoter meet it, and makes CI install the matrix so criterion 1 is satisfied by testing rather
than by a claim narrowed to what already passes. Records bash 3.2 as known-unverified rather
than letting silence imply coverage.

## Phase b — what it does

**Open decision 1 is settled: the claim is not written in prose anywhere.** The brief offered
three places to write the list — `tests/README.md`, `docs/blc/contracts/README.md`, or both with
one citing the other. All three were rejected for the same reason. The supported set already
exists as `BLC_AWK_CANDIDATES` in `tests/run.sh`, where a test fails if a name is removed. A
prose copy would be a second answer to a question that already has one, and the second answer
is the one that goes stale while the first keeps working. That is the defect #0014 spent four
phases removing, and criterion 1 does not ask for a sentence — it asks that the claim be
stated and not narrowed.

So both documents state the *rule* and point at the runner: `bash tests/run.sh --matrix-plan`
prints every candidate, which are present, which two names are one implementation, and which
are absent. A reader gets the list by asking the thing that owns it.

**That moves the risk rather than removing it, so both halves of the new risk are tested.** A
pointer is better than a copy only while there is no copy and while the pointer still points.
`the_claim_documents_point_at_the_runner` fails if either document stops citing the command.
`no_claim_document_enumerates_the_set` fails if either document names four or more
interpreters on one line — a list, as opposed to the two-name comparisons these files
legitimately make. Both were proved by mutating the documents: removing the citation, and
adding a prose list to the Contract README.

**CI installs `original-awk` and prints the plan before running.** ubuntu-latest already
carries gawk, mawk and busybox; the one true awk is the only candidate that needed installing.
Phase a's CI run reported three interpreters and `not found: original-awk`, which was honest
and was not coverage.

The plan step does not gate. A missing candidate is already named by the run, and a runner
image that drops an awk is a fact to see rather than a build to stop. The comment saying so was
written twice: the first version claimed the step fails when a candidate is missing, which
`--matrix-plan` does not do. A comment describing a gate that does not exist is the same defect
class as a test named for a property it cannot detect, in the file that configures the gate.

**What that choice leaves behind, stated rather than implied.** Criterion 1 has two halves: the
claim must be stated, and the check must run under every interpreter the claim names. The first
half is now held by tests. The second is held by the GitHub runner image. If a future image
drops busybox, CI prints `not found: busybox`, passes, and covers less than the claim says —
and the sentence this phase used to justify installing `original-awk`, that a narrower run "was
honest and was not coverage", applies word for word to that outcome.

The decision was to accept it. A gate on candidate presence turns a runner-image change into a
red build on work unrelated to it, and the run already names what it missed, which is the
property the brief's Tension section says must never be lost. But the gap is real, it is the
half of criterion 1 that nothing checks, and a promoter leaning on this phase should know that
the coverage half rests on an environment rather than on a test.

**bash 3.2 is recorded as unverified, in the section that says what the suite does not claim.**
No bash 4 construct appears anywhere — no `declare -A`, no `mapfile`, no `${var,,}` — which
makes 3.2 likely fine. Likely fine is not a claim, so it is not made.

**Review found the pointer dangling in the one place it mattered most.** `install.sh` copies
`docs/blc/contracts/README.md` into every target, and ships `docs/`, `tools/` and `templates/` —
never `tests/`. A consumer reading criterion 1 was told to run a command in a directory their
repository does not have. This project had already met that failure once and written a test
for it: the shipped briefs README points at the Contract with a relative link that resolves
here because here is where it was written. The two existing path tests scan the version files
for one citation form, and the new pointer was in neither a version file nor that form.

The fix is not to strip the reference. These criteria govern promotion of clauses in this
Contract, which happens where the Contract is written, so the reasoning is worth shipping and
the procedure is not. The paragraph now says the paths are not in an installed copy, and
`ship_the_contract_readme_marks_paths_it_does_not_ship` installs into a target, finds every
path the README names that the target lacks, and fails unless the file says so. It carries a
positive control: if the README ever stops naming an unshipped path, the test fails asking to
be deleted rather than passing over a question nobody is asking.

**The first version of the claim guards could not fail, and the reason is worth keeping.** The
helper walked the documents with `printf ... | while read`, which puts the loop body in a
subshell. `fail` marked a test the harness in the parent never heard about. Three mutations —
deleting the entire claim section from `tests/README.md`, removing the citation from the
Contract, and adding a five-name bullet list — all reported green. The loop reads from a
heredoc now. A guard that cannot report its own failure is worse than no guard, because it
also reports success.

Two more from the same round. The pointer test was satisfied by a usage line that shipped in
phase a, so the whole phase-b passage could be deleted while the test passed on an unrelated
string: it works on a *region* of each document now, bounded by its opening and closing lines,
and a missing region is a failure rather than a silence. And the enumeration guard counted
names per line, which a bullet list, a table, or two sentences all walk past; it counts across
the region.

**The region boundaries were half guarded, and review found the half that was not.** A claim
region is bounded by its opening and closing lines. A missing opener failed; a missing closer
did not, so rewording an unrelated heading ran the region to end of file and both guards stayed
green over a scope nobody chose. Both ends are checked now, and the two failures say different
things — a region that never opens is a deleted section, and a region that never closes is a
renamed heading somewhere below it.

Three smaller ones from the same round. The ship test's marker rule was stated as local and
enforced file-wide, so one marker anywhere licensed every unshipped path in the document; it
now reads the paragraph naming the path and the ones on either side, which is why the marker
sentence sits against the code fence it excuses. `the_cited_command_runs` used the relative
path it cites — correctly, since a citation a reader pastes must be relative — and was the only
test in the suite that would fail when run from a subdirectory. And `in_claim_region` carries a
note saying why it returns a status instead of calling `fail`: it runs inside a command
substitution, which is the subshell that hid three mutations one function over.

**The cited command is now run, not grepped.** Renaming `--matrix-plan` in the runner left
three citations of a flag that no longer existed and a green suite. `the_cited_command_runs`
executes it and checks it prints a matrix, so a dead pointer is a red test.

## Phase a — what it does

`tests/run.sh` gained a discovery step, a plan step, and an outer driver. It discovers each of
`awk`, `gawk`, `mawk`, `original-awk` and `busybox awk` on `PATH`, collapses names that report
one version into one run with the alias reported, runs the whole suite once per remaining
implementation with `PATH` shimmed so the tools resolve `awk` to that binary, and prints which
ran and which were not found. On this machine that is gawk (as `awk`, with `gawk` an alias)
and mawk: **354 passed, 0 failed under both.**

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

**A second review round found two more tests that could not fail, and one of them let the bug
above back in.** Indexing the driver's announcement off the display list — the #0014 desync,
restored by one word — printed `run 2/3: gawk (alias)` with the suite fully green. The inner
shim check could not see it: that check compares versions, and on a desynced line the version
is still right. The name is the part that lies. The other was the guard on the candidate list
itself, which matched each name as a substring of the whole report; `gawk`, `mawk` and
`original-awk` all contain `awk`, so deleting `awk` from the list left the guard green. A test
written to catch a silent narrowing was narrowable in silence.

Both are fixed by anchoring on structure rather than on text. Discovery lines are matched on the
newline before the name and the tab after it, and the announcement is checked against the run
list it must equal, position by position. The driver fixture now stubs every candidate —
including a busybox with no awk applet — so the plan is the one the test built rather than
partly a fact about the machine, and the alias sits *before* a run entry, which is the only
arrangement where the two lists disagree at an index a run uses.

That round also found two real bugs, neither of which a passing suite would ever have shown.
An awk that prints nothing for `--version` was announced as `(version unknown)` and then
compared against an empty string, so it failed the entire matrix with a message blaming the
shim — which had done its job. And `blc_awk_version` ran `--version` with inherited stdin: an
awk that does not know the option reads a program instead, and the suite hangs with no output
and no failure. The busybox probe three lines below already carried `</dev/null` and a comment
explaining why. One of two adjacent calls was guarded, which is the ordinary way a hazard gets
recognised and then not applied.

Eighteen mutations, eighteen dead tests: dropping a candidate (now genuinely, not by
substring), skipping an absent interpreter silently, passing over an empty matrix (both entry
points), dropping the dedupe, indexing the plan label off the display list, indexing the
*driver's* announcement off it, dropping an expected announcement from the fixture, dropping the
version from discovery, ignoring a failing interpreter, running the wrong binary behind the
shim, withholding the announced version from the inner run, removing the unknown-version
fallback, removing the busybox applet probe, dropping the applet at discovery, dropping it from
the shim, removing the stdin guard, and deleting the exemption that keeps two awks with no
version from collapsing into one run.

Two lines in this phase are held by a comment rather than by a test, and naming them is the
point of this paragraph. The first is the `</dev/null` on the inner check's own
`awk --version`. It guards the same hazard as the one in `blc_awk_version`, which *is* tested,
but reaching it needs a driver fixture whose stub reads stdin, and that fixture would hang the
suite when it worked.

The second is the `FILTER` assignment in `tests/run.sh`. Losing it does not turn the suite
red — it makes every inner run a full run and the driver tests fork until the machine runs out
of processes. A test for it
would have to be a test that deliberately forks a bomb and survives, and that is a worse thing
to own than the comment. It is recorded here so the next person does not mistake the comment
for an oversight.

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
   contributor meets it; `docs/blc/contracts/README.md` beside promotion criterion 1 is where a
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

## Close — 2026-09-30

**The brief was wrong about why it existed, and right that it should.** It was filed claiming a
live defect under mawk, a second interpreter axis over `sh`, and a cause for the original fence
bug. Measuring took four minutes and falsified all three: the suite was already green under
mawk, there is no `sh` surface because every script declares bash, and mawk does support
interval expressions — it matches them minimally, which is a quieter failure than the "reads
them literally" the record claimed. The brief was amended before execution rather than
rewritten afterwards, and the original claims are kept in it.

What survived the amendment was the real work: there was no guard, and no stated claim. Both
now exist.

**The suite has run under the one true awk for the first time.** CI reports four interpreters
and nothing not found — gawk 5.2.1, mawk 1.3.4, original-awk 20231127, and busybox — at 358
tests each. Before this brief, one implementation had ever run the suite, and which one was
unexamined.

**Twenty-six mutations across two phases, all killed.** Eighteen in `a`, eight in `b`. The
count matters less than what produced it: on four separate occasions a guard written in this
brief could not fail for the property it was named for, and every time it was the mutation that
found it rather than the reading. The driver had tests only for its planner. The claim guards
ran their loop body in a subshell, where `fail` marks a test the harness never hears about. The
candidate-list guard matched names as substrings, so `gawk` satisfied a lookup for `awk`. The
region guards checked the opening boundary and not the closing one.

**The recurring shape is a test satisfied by the wrong evidence.** #0014 found seven; this
brief found four more, written by someone who had just finished writing #0014's lessons down. A
lesson does not transfer by having been recorded. What catches these is mutation, every time,
and the cost of skipping it is not a missing test — it is a green report for a run that did not
happen.

**Two lines ship held by a comment rather than a test**, both named above with the reason: the
inner check's `</dev/null`, and the `FILTER` assignment whose test would have to be a fork bomb
that survives itself. **One half of criterion 1 ships held by an environment** — CI covers the
claimed set because the runner image happens to carry it, and a gate on that was considered and
declined.

**`BRIEFS-9` and `BRIEFS-10` can now meet criterion 1.** They cannot be promoted: criterion 2
wants a per-code-path mutation inventory neither has, and criterion 3 wants findings on records
written without them in mind, which nothing has produced. That is the state this brief set out
to reach — the blocker is no longer the absence of a claim.
