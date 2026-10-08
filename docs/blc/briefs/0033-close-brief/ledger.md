# Ledger — #0033 The close nothing writes

`blc/2 #0033 pending a:pending b:pending`

**Brief:** `docs/blc/briefs/0033-close-brief/brief.md`
**Started:** 2026-10-08
**Status:** pending

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the clause that defines a close | pending | — |
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

## Open decisions

None. Both decisions the brief opened were settled before execution.
