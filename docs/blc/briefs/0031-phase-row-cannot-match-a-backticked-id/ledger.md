# Ledger — #0031 phase-row.sh cannot match a backticked phase id

`blc/2 #0031 in-progress a:in-progress(brief/0031-a-read-the-id-without-its-backticks)`

**Brief:** `docs/blc/briefs/0031-phase-row-cannot-match-a-backticked-id/brief.md`
**Started:** 2026-10-07
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | read the id without its backticks | in-progress | `brief/0031-a-read-the-id-without-its-backticks` |

**a — read the id without its backticks.** Make `blc_phase_row_pattern` find the row for phase
`a` whether the ledger writes the id bare, backticked, struck, or struck and backticked. The
test comes first and must fail: a ledger whose phase table writes `` | `a` | label | ``,
asserting `BRIEFS-9` reports no missing phase.

## Dependency structure

One phase. The change is a few lines in one function, and splitting the test from the fix would
put a commit on `main` that only fails.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | the backticks are removed before matching, not accepted by the pattern | a |
| 2 | a struck and backticked id matches, and a test says so | a |
| 3 | one phase | a |

**Decision 1 follows a reader this repository already has.** `tools/lib/status-line.sh` removes
every backtick on the line before matching and states why: no status line carries one anywhere
else, so saying that is safer than trusting the enclosing pair. Reading the phase id the same
way makes the two readers agree. `phase-row.sh` already strips backticks out of the cells it
returns, at lines 75 and 101, so the file is inconsistent with itself today.

Accepting a closing backtick was the alternative. It repairs the one reported row and leaves
`` | ``a`` | `` and anything else failing, which is the same defect with a narrower mouth.

**Decision 2 is a shape nobody reported.** The pattern allows a leading `~` for a struck phase.
A struck *and* backticked id is legal Markdown and nothing says which way it goes, so the fix
has to choose. It matches: striking a phase marks it dropped, and a dropped phase still has
that row.

## What the survey settled before this started

The brief carries it: `phase-row.sh:42` is the only pattern in `tools/` with the asymmetry.
Every other backtick there is either a strip, which is right, or a character class in
`identity-line.sh`, which is a different job. This is one site, not a class, which is why it is
one phase.

## Settled while building `a`

**The gap was known, pinned, and left.** Two characterization tests already held these shapes
as unmatched. `test_phase_row.sh` said so of the matcher and named #0014 phase `b` as where the
gap closes, adding that the test flipping is how that would be visible. Phase `b` did not close
it, and the test went on guarding the gap rather than reporting that it was still open. A test
that pins a defect needs something that expires; this one had only a sentence.

**It is a policy reversal, not only a repair.** `test_clauses.sh` held that `BRIEFS-9` *reports*
these three rows, and that was right while they were unmatched: a row no reader can find is a
row that may as well not be there. #0014 phase `c` added the clause to report the shapes rather
than support them. So the gate telling the reporter their phases were missing was the behaviour
somebody chose. This brief changes the choice — the readers find the rows, so there is nothing
left to report — and both tests are inverted rather than deleted, because the rows they pin are
the same rows.

**Three shapes, not one.** The brief was filed on `` | `a` | ``. `| ~~a~~ |` fails for the same
reason in the other decoration: `~*` took a leading `~~` and made no provision for the trailing
one. One class on both sides of the id closes all three, and `` | ``a`` | `` with it.

**The fingerprint guard fired, which is the guard working.** `tests/test_phase_row.sh` keeps a
literal fragment of the pattern to catch anyone re-deriving the matcher outside the library.
Changing the pattern broke it, exactly as intended, and it was updated with the reason. Its own
comment records that an earlier version of it matched nothing at all, so it is a guard that has
failed twice now and been corrected both times.

**The boundary is what the change risked, and a test holds it.** Allowing decoration either
side of the id could have let `` | `ab` | `` read as phase `a`. Relaxing the boundary to `.*`
fails `phase_row_still_refuses_a_longer_id` and nothing else, which is the mutation that says
the guard is real.

## What this cannot prove

The defect was found by a person installing into a real project, twice, and that project
rewrote its ledgers to the shape the gate accepted. This repository writes its own phase tables
bare, so no test here would ever have failed. The fixture is written from the report rather
than from anything this repository does, and a shape neither the reporter nor this brief
thought of stays unreported for the same reason.
