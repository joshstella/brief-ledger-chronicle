# Ledger — #0033 The close nothing writes

`blc/2 #0033 in-progress a:in-progress(brief/0033-a-the-clause-that-defines-a-close) b:pending`

**Brief:** `docs/blc/briefs/0033-close-brief/brief.md`
**Started:** 2026-10-08
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the clause that defines a close | in-progress | `brief/0033-a-the-clause-that-defines-a-close` |
| b | the skill that writes one | pending | — |

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

## Open decisions

None. Both decisions the brief opened were settled before execution.
