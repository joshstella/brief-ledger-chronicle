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
| [v1](v1.md) | the structure of `docs/briefs/` | superseded by v1.1 |
| [v1.1](v1.1.md) | the structure of `docs/briefs/` | superseded by v1.2 |
| [v1.2](v1.2.md) | the structure of `docs/briefs/`, and `ledger.md` consistency | current |

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
`blc-review-pr` skill already reads `[judgment]` out of design documents, and renaming the read
tag would have failed silently there.

### Promotion — when a `[judgment]` becomes a `[defect]`

**Promotion is a change to one field of a published clause: its tag.** The clause text does not
change and what it examines does not change. Three things do change: the finding prints as
`[defect]` rather than `[judgment]`, it is counted in the defect column of the summary rather
than the judgment column, and a violation sets a non-zero exit status.

**Promotion also suppresses a project's own checks on a failing run.** `tools/validate-briefs.sh`
runs `brief-checks/` only when the defect count is zero. A promoted clause that fires therefore
stops an adopter's project checks from running at all, and their output does not appear in the
report. Promoting a clause makes it a precondition for every check a consumer has added
downstream of it — which is the largest consequence of promotion and the least visible, because
what a reader sees is a shorter report rather than a missing one.

Three more things follow, each stated because it is otherwise assumable.

**Promotion is per clause.** Two clauses added in the same version can promote in different
versions. Their preconditions are about the check each one runs, not about when they were
written.

**Promotion bumps the Contract version.** The tag is part of the published clause, so a tag
edited in place would make every citation of the old version silently wrong. The old version
stays published and keeps its tag, which is the same rule superseded versions already follow.

**Promotion is expensive to reverse, and has never been reversed here.** No published clause
has changed its tag in either direction. A planned gate was demoted to a report once, but that
happened before it shipped, so it shows the preference and not the cost of a reversal.
Demotion after people have built continuous integration on a gate costs more than never
promoting, and that asymmetry is the reason the criteria below are strict rather than a
formality.

#### Criteria

A `[judgment]` may be promoted when all three hold. Meeting them makes promotion permissible,
not automatic — a person still decides, and files the work. There is no version number or date
that advances this on its own, because a schedule this project cannot honour is worse than no
schedule.

1. **The check runs under every interpreter this toolkit claims to support, and the claim is
   stated.** A shell or `awk` that behaves differently costs a `[judgment]` one wrong printed
   line. It costs a `[defect]` someone's build.

   The claim is not free to narrow at promotion time. Stating a smaller supported set in order
   to satisfy this criterion is the same move as not testing, and the run must name the
   interpreters it used rather than printing one summary line for any set.

   **The claim is not written here.** It is the candidate list the toolkit's test runner walks,
   and it is read by running the runner **in the toolkit repository**:

   ```bash
   bash tests/run.sh --matrix-plan
   ```

   That prints every `awk` the suite claims, which of them the machine has, which names are
   aliases of an implementation already in the list, and which are absent. A prose copy of the
   list in this file would be a second answer to a question that already has one, and the prose
   copy is the one that goes stale — the defect #0014 spent four phases removing. Deleting a
   name from the list fails a test, so the narrowing this criterion forbids is refused by the
   suite rather than by a reader remembering to check.

   **The paths above are not in an installed copy.** They exist in the toolkit repository.
   `install.sh` ships `docs/`, `tools/` and `templates/`; it does not ship `tests/`.
   That is not an oversight in the installer: these criteria govern promotion of clauses *in
   this Contract*, which happens where the Contract is written. A reader holding an installed
   copy is reading the reasoning behind a published tag, not a procedure to run.

   The claim covers `awk` implementations. It does not cover `bash` versions: everything the
   toolkit ships declares `#!/usr/bin/env bash`, and the oldest bash it is likely to meet is
   the 3.2 that ships with macOS, which nothing has verified. That axis is recorded as
   unverified in the toolkit's own test documentation rather than left to look covered.

2. **Every guard on the check has been mutation-proved, at one mutation per code path the
   guard claims.** Not one mutation per guard. A guard can cover half of what its name says
   when two functions read the same input and each discards what the other reports, and the
   suite stays green either way.

3. **The check has produced findings on records written without it in mind, and someone
   examined those findings and judged them correct.** A check that has only ever fired against
   fixtures built to make it fire has been shown to fire, not to be right. Nothing yet
   measures its false-positive rate on a record nobody wrote for it.

   A clause nobody violates cannot satisfy this, and that is accepted rather than worked
   around. A rule that has never met a real record does not become a gate because time passed.

Criterion 3 is the one that cannot be hurried, and at the time of writing it is unmet for
every `[judgment]` in this repository — not unverifiable, unmet. Installs write their log into
the target rather than back here, so this project learns about a consumer's run only when
someone reports it. Until there is someone to report it, the only records available are this
repository's own, and a clause that reports nothing across all of them has produced no evidence
either way.

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
