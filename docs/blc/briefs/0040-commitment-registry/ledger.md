# Ledger — #0040 The meta-brief layer - commitments and schedule

`blc/2 #0040 deferred a:pending b:pending c:pending d:pending`

**Brief:** `docs/blc/briefs/0040-commitment-registry/brief.md`
**Status:** deferred
**Started:** 2026-10-15

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | the translation, by hand | pending | — | — |
| b | the registry and its gate | pending | — | — |
| c | the delta report | pending | — | — |
| d | cohorts | pending | — | — |

**a — the translation, by hand.** The brief says writing a probe is the specification step and
that nobody knows yet how much of an outcome is checkable. This phase answers that with one
real document and no tooling at all. It takes an existing outcome document, writes its
deliverables out as numbered criteria, and writes a probe for each one by hand. The output is
the criteria themselves and three counts: how many have a probe that tests behaviour, how many
have a probe that would pass while the deliverable is missing, and how many need a person.
Those counts decide whether the rest of this brief is a tool or a skill. It writes no code and
defines no format beyond what writing the criteria down requires.

**b — the registry and its gate.** Provisional. It turns the shape `a` arrived at into a
format, and gives the registry a check on its own well-formedness: ids that are stable, a
citation on every criterion, and `unjudged` reachable only through a demo event. The mechanics
are the Contract's, borrowed rather than invented.

**c — the delta report.** Provisional. It runs the probes and reports the three populations by
age — never met, met but never demoed, demoed but unjudged. It gates nothing. The brief says
this report meets the same wall #0039 found, so where it is delivered is part of the phase and
not an afterthought.

**d — cohorts.** Provisional, and may not be reached. Analysis against a codebase, cohort
cutting with serials claimed in one act, and overlap between in-flight branches reported rather
than gated.

## Dependency structure

A strict chain. Every phase after `a` is **provisional**: `a` can end this brief. If almost
nothing in a real outcome document carries a behavioural probe, the registry is a skill that
helps a person form a delta, not a tool that computes one, and `b` through `d` are the wrong
work. Re-planning from `a`'s result is the expected path.

## Settled before `a` began, 2026-10-15

- **The fixture is the BLIC design proposal of 2026-10-13.** A real outcome document with
  defined deliverables, which exists today, and against which a real delta can be measured
  because some of its deliverables shipped and others did not. The alternative was to wait for
  a detailed document that does not exist yet, or to invent one — and an invented outcome
  repeats the weakness that limited #0039, where a synthetic fixture proved a path nobody could
  judge.
- **Criteria are stated with no product knowledge.** The source proposal draws its evidence
  from a product repository. The project rules keep product names, paths and internals out of
  this repository's files. Every criterion is a property, the way #0039's brief restated the
  same source.
- **`a` writes no code.** The temptation is to build the format first, because the format is
  the fun part and the translation is the slow part. The brief's whole claim is that writing
  probes teaches you about the deliverables. A phase that builds a format learns nothing about
  that.
- **The brief is not edited to carry this plan.** The fixture choice was made at filing time,
  after the draft was written. It belongs here.

## Open decisions

- **Declared or derived ordering**, from the brief. Blocks `d`, not `a`.
- **Where the delta report is delivered.** Blocks `c`.
- **Whether a criterion's probe may be a command that does not exist yet.** `a` will meet this
  immediately: a behavioural probe for an unbuilt deliverable cannot run. Writing it as a
  failing command is honest and makes the delta computable; writing it as prose is cheaper and
  leaves nothing to run. `a` decides it by doing it.

## Complications found while planning

- **The fixture belongs to another agent's live work.** #0039 is in flight against the same
  design proposal, and its phase `c` is open. Criteria written here will describe deliverables
  that #0039 is building now, so the delta moves under this brief while `a` runs. That is
  realistic rather than unfortunate — a registry that cannot cope with the outcome changing
  during the work is not worth building — but the two briefs must not edit each other's files.
- **The proposal is a design document, not a client's statement of work.** It argues for
  something rather than specifying it. Some paragraphs will yield no criterion at all, and the
  count of paragraphs that yield nothing is a finding in its own right.
- **This repository has no customer and no demo.** The acceptance half of the brief — verdicts,
  `unjudged`, demo events — has no real data here, exactly as #0039 had no real peer events.
  `a` can test the translation and the probes. It cannot test acceptance, and must say so
  rather than simulate it.

## Parked, 2026-10-21

The brief is deferred. Every phase is pending.

`a` is not `deferred`. `deferred` on a phase means code parked on a branch, and `a` has none.
`brief/0040-a-the-translation` was cut and holds no commit of its own. No criterion was
written. The branch is left in place.

The reason is a choice, not a blocker. The translation is set aside before it started. The
brief stays filed, and the fixture decision recorded above stays with it.

Resume is a ledger edit, not a command. `blc-start-brief` stops because this ledger exists.
`blc-next-brief-phase` requires a phase that is `in-progress`, and none is. A person sets the
brief back to `in-progress`, sets `a` to `in-progress`, and cuts the branch again.

## Branches

`brief/0040-a-the-translation`, cut from `main` at `9da0deb`.
