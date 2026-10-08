# Ledger — #0033 The close nothing writes

`blc/2 #0033 done a:done(PR#142) b:done(PR#143)`

**Brief:** `docs/blc/briefs/0033-close-brief/brief.md`
**Started:** 2026-10-08
**Status:** done
**Closed:** 2026-10-08

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the clause that defines a close | done | PR#142 |
| b | the skill that writes one | done | PR#143 |

**a — the clause that defines a close.** Add `BRIEFS-11` as a `[judgment]`: a ledger whose
status is `done` carries a `**Closed:**` date. Ship it as Contract v1.4, mark v1.3
superseded, and implement the check in `tools/validate-briefs.sh`. The clause and its check
land together because a Contract clause that can be checked by a program names that check by
path — a clause shipped without one is prose claiming to be a rule. The test comes first and
must fail: a fixture ledger with `**Status:** done` and no `**Closed:**` line, asserting that
`validate-briefs` reports a judgment against it.

**b — the skill that writes one.** Ship `skills/blc-close-brief/`, its tracked symlink under
`.claude/commands/`, and the name in `PROCESS_SKILLS` and the three test lists that copy it.
The skill marks the last phase `done` with its PR, sets the status and the `Closed:` date,
updates the `blc/2` status line, clears any declaration in `docs/blc/state/`, and opens the
closeout PR from `brief/<serial>-closeout`. It writes what `a` made checkable.

## Dependency structure

Strict chain. `b` follows `a` so the skill has a specification to satisfy rather than one to
invent. That ordering is the whole reason the brief has two phases: a skill written first
would define the close by example, which is how the convention came to live in four ledgers
and nobody's file.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | a clause and a skill, clause first | a, b |
| 2 | the 16 non-conforming ledgers are reported, not gated | a |
| 3 | `BRIEFS-11` requires the `Closed:` date and nothing else | a |
| 4 | `blc-close-brief` joins `PROCESS_SKILLS` | b |

**Decision 2 needs no mechanism, which was not obvious when it was taken.** The choice was
between grandfathering by serial, backfilling the dates from git, and reporting. The Contract
already defines `[judgment]` as "surfaced for a human to decide, never blocks". A `[judgment]`
clause reports the 16 and gates nothing, so the decision is enacted by the tag rather than by
a rule about which serials it binds. Backfilling was rejected on the same ground the record is
never rewritten: a date derived from a merge commit is not the date a person closed the brief,
and writing it would make the record say something nobody asserted.

**Decision 3 is narrower than the evidence would support.** The survey found the closing
*sections* improvised six different ways, which is the larger inconsistency. The clause does
not touch them. A section is prose, and a check that can only read headings would pass a
heading with nothing under it — the "A skill guard is not a check" problem relocated into the
gate, where it would look like enforcement. The `Closed:` date is the one fact a program can
hold, and it is missing from half the record.

## Complications found in the code, not addressed by the brief

**`tools/validate-briefs.sh` hardcodes `10 clauses decided`, in two separate printf lines.**
`BRIEFS-11` makes both wrong. This is the defect #0032 phase `b` removed from the installer,
present in the gate. Phase `a` has to touch it and will derive it rather than bump it, on the
precedent #0032 set.

**Eight places outside the record name `v1.3`, and one is a path.** `tools/orient.sh:37` sets
`CONTRACT="$BLC_ROOT/contracts/v1.3.md"`. A bump that misses that line leaves `orient` reading
a superseded contract and reporting it as current. The others are prose in `README.md`,
`install.sh`, the contracts and briefs READMEs, and two assertions in
`tests/test_contract_ship.sh`.

**`tests/README.md` already drifted.** It describes `test_briefs.sh` as covering "Contract
clauses BRIEFS-1..8 (currently v1.3)". `BRIEFS-9` and `BRIEFS-10` exist. The document went
stale two clauses ago and nothing reported it, which is the same failure this brief is about,
one layer out.

## Settled while building `a`

**The clause reads the status line, and that had to be chosen rather than assumed.** A ledger
states whether it is closed twice — in the `**Status:**` field and in the `blc/2` status line.
The status line won because every other tool here already parses it through one shared reader,
and all 32 closed ledgers carry one. A clause reading the prose field would have made the gate
the only reader in the repository answering "is this closed?" from a different place, which is
the drift `BRIEFS-9` and `BRIEFS-10` were written to end. The clause says which one it asks,
so the choice is in the published text and not only in the code.

**The brief-state reader moved, and that move was not optional.** `list-briefs.sh` held a
careful extraction of the state token, with a comment warning that a positional read cuts
`done(commit 92a7168)` in half. `validate-briefs.sh` needed the same answer. Its own header
forbids the obvious shortcut: a validator with a private copy is "a reader free to disagree",
which is the defect #0014 spent four phases removing. So it became `blc_status_state` in
`tools/lib/status-line.sh`, with a test that fails if any tool re-derives it.

**The clause count must not be derived, and working out why took longer than the fix.** The
hand-written `10 clauses decided` looked like the same defect #0032 had just removed from the
installer, and the first instinct was to count the clause headings in the Contract. The
comment above it says why that is wrong: the number is how many clauses *this script decides*,
not how many the Contract contains, and counting the document would make the report agree with
it by construction — a clause published and never implemented would raise the number. The real
defect was that the literal was written twice, in two branches of the same report, so
`BRIEFS-11` made two lines wrong and a reader fixing one could leave the other. It is declared
once now. Not every copied number is the same defect, and "derive it" was the wrong lesson to
carry over.

**The installer would not have shipped the new Contract.** `install.sh` named the versions one
per line up to `v1.3`. A target would have kept the superseded version while the briefs README
it also ships linked to a `v1.4.md` that was not there. This was not found by reading the
installer: a test in `test_contract_ship.sh` had the same hand-written list, and changing that
test to walk the directory failed immediately. The fix is a glob in both places.

**`BRIEFS-11` is the first clause in this repository to meet promotion criterion 3, and that
settled nothing about promoting it.** Criterion 3 asks that a check has produced findings on
records written without it in mind, examined and judged correct. The clause reports sixteen
ledgers written long before it existed, and all sixteen were read: the date is genuinely
absent and nothing was a false positive. The Contract README said criterion 3 was "unmet for
every `[judgment]` in this repository", and that sentence stopped being true in the same run
that made it so. It now names the three clauses it is still unmet for and records why
`BRIEFS-11` stays a judgment anyway: the records it reports are record, they will not be
corrected, and promoting the clause would gate this repository's build forever on a past
nobody intends to change. Criterion 3 was always necessary and never sufficient. This is the
first case that shows the difference.

**A guard caught its own prose going stale in the run that staled it.**
`test_clauses_the_promotion_criteria_still_describe_this_repository` asserted that no ledger
here produces a judgment. It failed the moment the clause worked. It now reads *which* clauses
fire rather than how many findings they make, so the next brief does not have to edit a count
for a reason that has nothing to do with it, and a new clause firing still trips it.

**The first version of the check could be fooled by a ledger that documented itself.** It
matched `**Closed:**` anywhere in the file, so a fenced example of the field satisfied the
clause — a brief with no recorded close passing silently. Caught by the review gate before
the commit, with a fixture that demonstrated it rather than an argument that it could happen.
The repository already knew this fault: `status-line.sh` carries a paragraph about a fenced
example being returned instead of a ledger's own status, found the same way, before any
ledger here did it. The fix extends that same scan with a `closed` field instead of adding a
second reader, so fences are skipped once for every clause that reads a ledger.

**A mutation test produced a false result and was redone.** Restoring the mutated file with
`git checkout --` restored it from the *index*, which still held the version staged before
the fence fix. The run afterwards therefore measured the old code and reported the guards
working. The second attempt restored from a file copy and ran a baseline on both sides of
the mutation. A mutation test is only worth the restore step being right, and nothing about
the first run's output showed that it was not.

**The decision to keep sixteen judgment lines was taken with the output in hand.** The
alternative was one collapsed line naming all sixteen. Per-brief lines were kept: they match
every other clause, and the judgment count stays honest at sixteen instead of dropping to one.
The noise is the real cost of a record this project chose not to rewrite, and hiding the cost
would misreport the decision.

## Settled while building `b`

**The guard from #0032 caught its first real mistake.** `blc-close-brief` was added to
`PROCESS_SKILLS` and the three test lists, and the only failure was
`test_skill_names_this_repo_links_its_process_skills_as_commands`, reporting that
`.claude/commands/blc-close-brief.md` was not tracked. That guard exists because #0032 phase
`a` made exactly this mistake and nothing noticed. One brief later it is the thing that
notices.

**The derived count needed no edit.** `tests/test_project_mode.sh` reads the number of
process skills out of `install.sh` rather than holding a literal, so an eighth name changed
nothing there. #0032 phase `b` derived it after finding `assert_count 6` broken by a seventh.
That is the second addition it has absorbed in silence, which is what the change was for.

**The skill's contract with `BRIEFS-11` is asserted from both ends.** The clause reads a
`**Closed:**` line and the skill is what writes one. Either half could move alone without
looking wrong: the clause would stop finding the field while the skill went on writing it,
and the gate would report every closed brief while every closed brief looked correct. The
test reads the skill and the scan, and both ends were mutated.

**The two documents that described the closeout now name its writer.** That is the brief's
actual subject. `blc-next-brief-phase` step 8 and `docs/blc/briefs/README.md` each said the
closeout branch carries the close and neither said what writes it, which is how a step ends
up with no writer for thirty-two briefs.

## Open decisions

None. Both decisions the brief opened were settled before execution.

## What shipped

Two phases, two PRs. Contract **v1.4** adds `BRIEFS-11`: a ledger whose status line says the
brief is `done` carries a `**Closed:**` line, read outside fences and frontmatter by the scan
that already finds the status line. `skills/blc-close-brief/` writes one, and joins
`PROCESS_SKILLS` so Claude Code installs it as a slash-command. `blc-next-brief-phase` and
`docs/blc/briefs/README.md` now name the writer they described and left anonymous.

All four settled decisions held. None was re-opened. Decision 3 — the clause asks for the
date and nothing else — was the one most open to drifting wider during execution, and it did
not.

This ledger is the first close written by `blc-close-brief`, against the clause the same
brief published. The sections below are the ones the skill prescribes, in the order it gives.

## What the record shows that the brief did not predict

**The brief was filed against a step with no writer, and the work found the same shape three
more times.** The process-skill list was copied in five places. The Contract version was
named in eight, one of them a *path* in `tools/orient.sh` that would have left `orient`
reading a superseded contract. `install.sh` listed the Contract versions by hand, so v1.4
would not have installed at all — a target keeping v1.3 while the briefs README it also ships
linked to a file that was not there. None of these was the close. All of them were a fact
stated in more places than anything reconciles.

**Not every copied number is the same defect, and that took working out.** The gate's
`10 clauses decided` looked exactly like the count #0032 had just derived out of the
installer. Deriving it from the Contract would have been wrong: the number says how many
clauses *this script decides*, so counting the document would make the report agree by
construction and a clause published but never implemented would raise it. The real fault was
that the literal appeared twice in two branches of one report. The lesson #0032 taught was
"a count is a copy", not "derive every count", and the two are easy to confuse.

**`BRIEFS-11` is the first clause here to meet promotion criterion 3, and that settled
nothing about promoting it.** The criterion asks for findings on records written without the
check in mind, examined and judged correct. Sixteen ledgers qualify and all sixteen were
read. The clause stays `[judgment]` anyway, because those ledgers are record and will not be
corrected, so promoting it would gate this repository's build forever on a past nobody
intends to change. Criterion 3 was always necessary and never sufficient. The Contract README
had claimed it was unmet for every judgment here, and that sentence stopped being true in the
run that made it so — caught by a guard written to notice exactly that.

**The review gate paid for itself twice.** In `a` it caught a check that a ledger could
satisfy with a fenced example of the field — a brief with no recorded close passing silently.
In the same phase a mutation run was found invalid: restoring the mutated file with
`git checkout --` restored it from the index, which still held the pre-fix version, so the
run measured the old code and reported the guards working. Both are in the record rather than
quietly fixed.

**#0032's guards caught their first real mistakes here, one brief after being written.** The
command-link guard reported the missing `.claude/commands/blc-close-brief.md` — the exact
mistake #0032 phase `a` made while nothing was watching. The derived process-skill count
absorbed an eighth name with no edit. A guard that has only ever passed is unproven; these
two stopped being unproven in this brief.

## Open after close

**The clause checks one line and the convention it was filed against is wider.** The closing
*sections* are still improvised — six spellings across thirty-two ledgers. `BRIEFS-11` does
not touch them, deliberately, because a check that reads headings would pass a heading with
nothing under it. The skill prescribes four sections and nothing enforces them.

**Sixteen judgment lines now print on every gate run, permanently.** That was chosen with the
output in hand rather than described. The alternative was one collapsed line, rejected
because it would drop the judgment count from sixteen to one and misreport the cost of a
record this project will not rewrite.

**The four hand-written copies of the process-skill names remain.** #0032 deferred them and
this brief added an eighth name to each by hand. No test asserts the four agree. A ninth
process skill will need the same four edits, and the drift stays undetected until an install
places the wrong set.

**`BLC_UTILITY` in `tests/test_skill_names.sh` is still defined and never read.** Carried
from #0032's close unchanged. Nothing acts on it.

**Nothing re-closes the sixteen.** They are reported for as long as the clause exists. No
work is planned on them and none should be read into this ledger.

## What this cannot prove

A skill is prose and nothing runs it. The tests pin what `blc-close-brief` *says* — that it
names the reserved branch, writes the field the clause reads, refuses a derived date, and
refuses an unfinished brief. Whether an agent follows those steps is not measured, and the
same ceiling covers every skill here. It is named because phase `a` exists precisely to put
one checkable line under prose that is otherwise unenforced, and a reader should not take the
clause as evidence for the rest.

The clause cannot prove the record improves either. It reports a missing date; it cannot tell
a date written because the work closed from a date written to quiet the gate. The sixteen
existing findings were judged correct by one person reading them, which is evidence and not
measurement.
