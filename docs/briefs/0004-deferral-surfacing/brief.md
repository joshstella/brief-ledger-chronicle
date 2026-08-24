# The ledger is an archive and a bad inbox

**Serial:** #0004 · **Created:** 2026-08-24T12:59:40Z · **Author:** josh.stella@gmail.com · **Depends on:** #0003

## Ground

This toolkit records deferrals faithfully and surfaces them never. A ledger captures the
decision to park work, the reason, and the way back — and then nothing brings that record
forward again. The record is correct and inert.

That is a different failure from the ones this project has fixed so far. Every prior
finding was a rule stated in the wrong place, or stated and unchecked. This one is a rule
followed exactly, producing a record that satisfies every clause and still costs the
project the work it describes.

Not a category boundary, so this is short by the rule #0003 set.

## Evidence

**Supplied, not verifiable here.** Observed in a consuming project on 2026-08-21. Brief
#0001 was filed on 2026-06-23. Phases 1, 2, 3 and 5 shipped. Phase 4 was deferred on
2026-06-25.

**The deferral was recorded correctly, and that is the point.** No rule was broken. The
ledger named the branch, said "pushed, no PR", gave the rationale, listed three open issues
blocking a merge, and specified the resume path. The process did exactly what it is
designed to do.

Fifty-seven days passed. The brief sat at `Status: in-progress` throughout and satisfied
every structural invariant the whole time. It surfaced only because a human asked, in an
unrelated session, which briefs were open.

The cost, measured the same day: the branch was 248 commits behind `main`; a dry-run merge
conflicted in all three code files it touches; upstream had added roughly 770 lines to the
two source files the branch also edits. Work that was mergeable on 2026-06-25 now needs its
integration rewritten.

**Verifiable here: no clause can see any of this.** Contract v1 does not contain the word
`ledger`. Clauses `BRIEFS-1` to `BRIEFS-8` govern folder shape, slug and serial form,
serial uniqueness, the presence of `brief.md`, the identity line, dependency resolution,
draft naming, and contiguity. `BRIEFS-4` requires a `brief.md` and says nothing about the
`ledger.md` beside it. A brief can sit in-progress forever and stay fully compliant.

The nearest thing to a staleness cue points the wrong way. `Created` is documented in
`docs/briefs/README.md:46` as the cue to re-ground a brief before executing it — a signal
about drafts and unstarted work. There is no equivalent for a brief already in flight.
`BRIEFS-8` flags a gap in the serial sequence. Nothing flags a gap in time.

**The sharpest part is structural.** A deferred phase parks code on a branch, and
`docs/briefs/` has no concept of branches at all. The ledger names one in prose. Nothing
resolves it, nothing notices it decaying, and deleting the branch leaves the ledger reading
"code on branch" while pointing at nothing.

## A distinction the evidence conflates, found while checking this repo

A second report describes the same hole recurring at phase level: ledgers closed at the top
that went stale inside — a `PR #TBD` never backfilled, a phase row left `in-progress`, a
second `Status: in-progress` buried below a top-level `complete`.

Checking this repository's three ledgers found none of that, and found something that
matters more for any future rule. #0003's ledger has a `Dependency structure` section that
still describes a strict chain through a phase 3 that was later folded into phase 2. The
top-level status is `complete`.

**That is not rot. It is accurate history.** A ledger is past tense — what the work taught
— so a plan that was recorded and later superseded is the record doing its job, and the
Big decisions section explains the supersession. An unfilled `PR #TBD` is different in
kind: a placeholder that was always meant to be replaced.

Any rule here has to tell those apart, or it will demand that ledgers be rewritten to hide
what was actually planned, which destroys the artifact to tidy it.

## Change

Add a third entry to the Known limitations section of `docs/briefs/README.md`, written as
an incident report with the dated case, matching the two entries already there.

The entry states the hole. It does not propose the mechanism: per the settled sequence, the
first buildable thing is a query that answers "which briefs are open?", and everything in
open decision 1 sits on top of that.

Note for whoever executes this: that section now holds **one** entry, not two. Concurrent
filing moved into `docs/contracts/v1.md` beside `BRIEFS-3` during #0003, and the README
links to it. "Writers outside the pipeline" is the shape to match.

**Then reconcile ledger status, and build the query.** Amended 2026-08-24; the original
Change section stopped at the entry above. Reasoning is in the ledger.

- Give the declared phase states one home and reconcile them with practice. The set is
  `pending`, `in-progress`, `deferred`, `done`, `skipped`.

  | state | means | carries |
  |---|---|---|
  | `pending` | a place in the sequence, no real progress | — |
  | `in-progress` | a branch exists | branch always, PR when there is one: `in-progress (feature/x, PR#14)` |
  | `deferred` | parked on purpose; a reason was given | branch and PR as above, plus a reason sentence |
  | `done` | done | `(PR#14)`, or `(commit abc1234)` where no forge is in use |
  | `skipped` | not being done | a reason sentence |

  `done` points at a PR or commit rather than a branch, because the branch is usually deleted
  by then. Allowing a commit keeps the vocabulary usable with no forge, per this project's
  rule that external tools are optional artifacts to piggyback on.

  `proposed` is not a state: a phase nobody has committed to belongs in a draft.
- Add a compressed status line directly under the ledger title, so a scan costs one line
  instead of a phase table. Visible, backticked, schema-versioned:

  ```
  `blc/1 #0003 done 1:done(PR#9) 2:done(PR#10) 3:skipped 4:done(PR#11)`
  ```

  It restates what the phase table already says. The redundancy is deliberate and its risk is
  named below.
- Then build the query that answers "which briefs are open?", per the settled sequence. It
  also reports any ledger whose status line disagrees with its phase table.

**A stale status line is worse than no status line.** A cheap scan trusts it and stops
looking, so a ledger whose table says `deferred` and whose line says `done` hides precisely
the incident this brief exists for. That is why the query checks the two against each other.
It reports; it does not gate, so the prose-then-clause-then-check ordering is intact.

**`in-progress` and `deferred` answer different questions, which is what keeps them apart.**
`in-progress` is a fact about artifacts: a branch exists. `deferred` is a fact about intent:
someone looked at it and chose to park it, and said why. Both fit a parked branch, so the
tie is broken by rule rather than judgment: **if a reason was given, it is `deferred`.**

**Naming the branch is what makes either state interrogable.** Whether the branch still
exists, whether a PR was ever opened, how far `main` has moved since — all answerable from the
repository. That is staleness derived rather than declared, and it is the stronger instrument,
because the incident's failure was that nobody raised anything, not that nobody wrote anything
down.

**Decay is measured for `deferred` exactly as for `in-progress`.** Acknowledgement buys a
quieter default at the start; it does not buy exemption, and past a threshold a deferred
branch is raised like any other. The evidence above is the argument: that deferral was
recorded correctly, with rationale, blocking issues and a resume path, and it still cost 248
commits of divergence. Nothing about a good rationale makes a branch rot more slowly. **An
acknowledgement has a shelf life.** Were it otherwise, correct recording would purchase
silence, which is this brief's finding inverted.

## Settled decisions

- **Recorded correctly, not violated.** Any wording that reads as a process failure is
  wrong. The process worked and the outcome was still bad, which is the whole finding.
- **Prose first, and still no clause and no check.** **Amended 2026-08-24 — this read
  "prose only" when filed.** This repo runs prose, then clause, then check, one direction,
  and that ordering is intact: the limitation entry lands first, the status vocabulary is
  prose, and the query reports without gating anything. What is still forbidden here is a
  Contract clause or an enforcing check landing beside the prose that motivates it.
- **A known boundary is a legitimate resting place**, per the concurrent-filing entry.
- **The query comes first, the prompt second.** Something must be able to answer "which
  briefs are open?" before anything can raise the question. The query is useful with no
  prompt; a prompt with no query is worthless. The incident is the proof: it surfaced
  because a human asked that question by hand, so the query alone would have caught it
  fifty-seven days earlier, with no threshold and no stored state. Any reminder mechanism
  is an optimisation on top of a query that already works.

## Candidate fixes — recorded, deliberately not built

1. A `[judgment]` clause on a ledger left `in-progress` past some age. It must never block:
   a long deferral is often correct, and the point is to surface it, not to forbid it.
2. ~~Deferred-phase records that pin a commit rather than naming a branch in prose, so the
   artifact survives branch deletion.~~ **Absorbed into the Change section on 2026-08-24.**
   The durable pointer on `deferred` does this, and it arrived as a side effect of deciding
   the vocabulary rather than as work of its own.

Both need the distinction above before either can be specified, and both are Contract v2
work: v1's stated scope is the structure of `docs/briefs/`, and a rule about ledger status
is a different namespace.

## Open decisions

1. **Where surfacing happens — leading candidate recorded.** A clause reports; it does not
   ask. Something has to *run* for a stalled brief to reach a human, and the only moments
   this toolkit reliably runs are `create-brief`, `start-brief`, `next-brief-phase`,
   `commit-push-pr` and `chronicle`.

   The candidate: **commits landed on `main` since a ledger last changed.** Git is the
   store, so nothing new is written, nothing conflicts on merge, and the signal travels
   across machines and people without becoming shared mutable state. **Gated on a non-empty
   result** — with nothing open, nothing is asked, so the mechanism is silent while there is
   nothing to say. That is the same shape the Contract already requires of a `[defect]`
   check.

   The property to preserve, whatever is built: **activity is what rots a branch, not the
   calendar.** The deferred branch was expensive because 248 commits landed on top of it,
   not because 57 days passed. A commit count keeps that. A wall-clock interval throws it
   away.

   The signal is also a property of the stalled thing rather than of you. It fires when a
   specific ledger is actually going stale, not on a rota.

   Still open: whether to show the list every time it is non-empty, or only past a
   threshold. #0004 is blunt that a cost at the moment of action gets routed around by the
   person it was built for, and a prompt answered "no" repeatedly teaches dismissal without
   reading.

2. **Where the cadence signal comes from, and which cost it pays.** Decisions 2 and 3 were
   first written as separate questions. They are one question seen from two sides.

   A counter of invocations avoids a threshold and pays with stored state. A time interval
   avoids stored state and pays with a threshold. Neither escapes both. Recorded because
   listing them separately made each look solvable on its own, which is why the trade went
   unnoticed while both were open.

   The homes considered and rejected. In-repo: a file changing on every command, making git
   noise, conflicting on merge, and shared across people so one author's activity prompts
   another about work they were not doing. Machine-local: does not travel, so one person on
   two machines carries two counters, which is exactly the invisibility `wip-visibility`
   documents. Wall-clock hour modulus: genuinely stateless, but it fires on the clock rather
   than on you — every invocation inside a qualifying hour prompts, and some working hours
   never qualify at all, so the mechanism silently never fires for those schedules and gives
   no signal that it is not firing.

   Git-derived is chosen because it makes an existing store do the work. What remains open is
   the threshold, in commits, which is the cost this route accepts.

## Resolved since filing

Reasoning is in the ledger's Big decisions; recorded here so they are not re-litigated.

- **Reliability inside a prompt document — best effort is enough.** These commands are
  markdown read by an agent, not programs, so the cadence cannot be guaranteed. It does not
  need to be. Surfacing a stalled brief most of the time is a large improvement over never,
  and going git-derived means a skipped run costs one missed prompt rather than a corrupted
  cadence forever.

  The condition attached: **it must be described as best effort wherever it is documented.**
  A mechanism sold as dependable and delivered as occasional is overclaiming, which is the
  defect class this project treats as primary. Saying "this may miss" costs nothing and is
  the difference between a limitation and a lie.

- **Ledger states are declared, not derived.** A reader should be able to see a status, not
  reconstruct it. See the ledger for what this turned up.

## Non-goals

- Not building either candidate fix.
- Not a clause and not a check in this change.
- Not a gate. Nothing here may block work at the moment of action.
- Not a re-derivation of the multi-user draft. A stalled invisible branch is worse with a
  team, but that draft owns the single-writer question and this one owns time.

## Success criteria

- A reader learns, from the README alone, that this toolkit does not surface what it
  records.
- The entry reads as an incident report with a real dated case, not as an abstraction.
- The two candidate fixes are recorded as known boundaries, so neither is a surprise later.
