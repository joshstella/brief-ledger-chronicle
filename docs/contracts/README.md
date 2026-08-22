# Contracts

A Contract states what this repository currently guarantees. It is the present-tense layer:
briefs are the hypothesis entered with, ledgers are what the work taught, chronicles narrate
both, and none of the three tells a reader what the rule is today without reconstructing it
from every case ever decided.

This file holds what does not change between versions — how to read a clause, and what a
Contract will and will not do. Each version links here rather than restating it, so the
legend cannot drift against itself.

## Versions

| version | covers | status |
|---|---|---|
| [v1](v1.md) | the structure of `docs/briefs/` | current |

A version states what holds for that version. A later version supersedes it without making
it retroactively false.

## What a Contract does not do

A Contract does not make itself true. Where a clause can be checked by a program, it is, and
the clause names the check by path. Where it cannot, the clause is exactly as reliable as the
people following it. Writing a rule down changes where you look it up, not whether it holds.

No clause blocks work at the moment of action. A `[defect]` check stays silent while you
comply and speaks only when you break it. A mechanism that costs something at the moment of
action gets routed around by the person it was built for.

Nothing here is owed. A surface with no Contract is a surface nobody has been asked to depend
on, which usually means someone is still playing on it. That is a productive state, not a
debt.

## How to read a clause

Each clause carries an id, a tag, a scope, and its checking state.

### Id

`NAMESPACE-n`, for example `BRIEFS-3`. Permanent. Allocated once and never reused or
renumbered, the same way a retired brief keeps its serial. The namespace names the surface
governed, not the file the clause lives in, so the file can move without invalidating a
citation.

### Tag — what happens when the clause is broken

| tag | meaning |
|---|---|
| `[defect]` | A hard violation. |
| `[judgment]` | Surfaced for a human to decide. Never blocks. |

`[judgment]` was called `[advisory]` in earlier prose. One name survives because the
`review-pr` skill already reads `[judgment]` out of design documents, and renaming the read
tag would have failed silently there.

### Scope — who the clause binds

| scope | meaning |
|---|---|
| `repo` | Binds this repository only. |
| `consumers` | Ships to installed projects only. |
| `both` | Binds here and ships. |

Scope is part of the clause, not a filing detail. A rule whose scope is unstated claims more
than it means. The lesson came from a process-rules file that read as governance, governed
nothing where it sat, and was enforced anyway by a reader who had already studied it twice.

### Checking — three states, kept distinct

| state | meaning |
|---|---|
| `checked: <path>` | A program decides this clause. The path is named so the sentence goes stale if the link breaks. |
| `unchecked, reviewed <date>` | A check could exist. Nobody has written it. The date is hand-stamped, because a hand stamp is the only signal available. |
| `not mechanically decidable` | No check can exist. |

The last two are reported separately on purpose. Collapsing them would claim more coverage
than exists, which is the defect class this artifact was built to prevent.

Checked clauses carry no review date. Continuous integration is a better date, refreshed
every run.

## What a Contract never contains

Clauses are mechanical hygiene — slug shapes, unique serials, a well-formed identity line.
None of them measures whether the process is working. A repository can satisfy every clause
with a hundred briefs that were never wrong about anything.

That is correct rather than a gap. Trivial rules are safe to check because nobody games a
slug regex. A clause reading "every brief makes a falsifiable claim" would produce
falsifiable-looking claims the day it shipped, and the measure would kill the thing it
measured. What this toolkit values — a brief that could be wrong, a ledger that records
surprise — is surfaced and counted, never checked.
