# The meta-brief layer - commitments and schedule

**Created:** 2026-10-14T22:50:39Z · **Author:** josh.stella@gmail.com
**Depends on:** —

A project with defined deliverables needs a step above a brief: read the outcome, measure the
current state, find the delta, and cut the delta into briefs small enough to finish instead of
one sweeping change. The shape will move during implementation. This is the starting point,
not the plan.

The one new concept is the **probe**. Everything else is a shape this toolkit already has.

## What a probe is

A probe is this project's form of requirement definition. A commitment is written as a check
that would prove it. The check may be a test. It may be a named person's verdict. Both are
probes; they differ in who runs them.

A probe tests behaviour, not existence. "The file is present" passes while the deliverable is
missing. A criterion whose probe cannot be written is not a tooling gap — it is a deliverable
nobody has specified yet, and finding that out before anybody implements it is worth more than
the delta report will ever be.

**Writing the probe is the specification step.** A behavioural probe for a thing that does not
exist is an acceptance test written first. That is where the cost is, and where the value is.
Expect it to feel like stalling at the point where it is teaching the most.

### The probe is not new; its lifecycle is

The Contract already states a rule and names the check that proves it. The mechanics are
borrowed, including the `[defect]` / `[judgment]` split, which already says "this one is
checkable" and "this one is a person's call".

What differs is how the two die. A Contract clause is permanent, and zero violations forever
is success. **A criterion exists to be extinguished.** One report should always read zero; the
other is a burn-down that reaches zero once, after which the document is finished. The same
code could serve both. Reading them as one report would make a healthy burn-down look like a
failing gate.

## Two documents

- **The outcome document** is the prose as given. It is not edited here. A new version is
  received, not negotiated into the record.
- **The commitment registry** is derived from it. Each criterion cites the paragraph it came
  from.

That citation is not bookkeeping. When the outcome document is revised, the criteria whose
source paragraph changed are computable, and that set is exactly the commitments the revision
put at risk — including any already accepted, which would otherwise surface at the next demo.

"Amend visibly" belongs to the registry, which is ours. A criterion is never silently reworded
or deleted. It gains a dated status with the reason and the brief that caused it, and the old
text stays under the new one.

Criterion ids carry the discipline serials carry: stable, never reused, never re-pointed at a
different meaning. If what is wanted changes, that is a new id and the old one is superseded by
it. Otherwise a brief that cited a criterion last month now cites something else, and its
ledger is quietly false.

## Met and accepted are two facts

They are never collapsed.

- **met** — the probe passes. What we believe.
- **accepted** — the commitment is discharged. What they agree.

The population that is met and not accepted is the most useful number the registry produces,
because it leads rework and is invisible everywhere else today. One column called "done"
destroys it.

### Every verdict carries provenance

Person, date, revision, and optionally the basis. The revision is mechanical, not pedantic: a
demo is a demo of a build, and without the pin a later disagreement cannot be told apart from a
regression. Those two call for opposite responses.

The basis is optional and costs nothing blank: "per the client meeting on the 9th" and "my read
of what they want" are both legitimate from a person who owns the relationship, and they age
very differently. The second is the one you want to find when a disagreement happens.

### Unjudged, and only this

Acceptance happens per demo, not per criterion. A demo is one event — a date, a build, a judge,
a few sentences — and decomposing it onto criteria is a separate act performed afterwards.

That act is the kind of after-the-fact record step that reliably does not happen. This
repository is the evidence: sixteen of thirty-nine briefs carry no `**Closed:**` date, and the
gate has printed that on every run since each one closed.

So **silence after a demo is never acceptance.** The demo is recorded as an event; criteria
stay `unjudged` until someone names them. `unjudged` is reachable only through a demo event —
not-yet-demoed is a different state, and sharing a label would turn the list into a dumping
ground inside a month. That invariant is checkable on the registry itself.

The list is reported by **age**, not count. A number says there is a backlog. An age says which
commitment has been drifting toward assumed-accepted since a demo three weeks ago. Ageing is
what replaces a lapse rule: a timer hides the decision, an ageing line forces someone to look
at it.

### A rejection is prose, not a status flip

The probe passed and the human rejected. Two cases that look identical on the day and mean
opposite things:

- **The commitment was right and the check was wrong.** Same criterion, same id, a revised
  probe, the old one left visible.
- **The commitment was wrong.** A new criterion with a new id; the old one is superseded.

The first says we are bad at writing checks. The second says we are bad at eliciting
requirements. A registry that does not force the distinction makes a year of rejections tell
you nothing.

What was believed, what they said, what it taught — the same shape as a brief's close, for the
same reason. The delta between the probe and the acceptance is the knowledge; the status change
is bookkeeping around it.

### Probes graduate

A criterion is met when a test in the real suite covers it. At that moment the probe stops
living in the registry and the registry records which test now owns it.

Without graduation there are two assertions of the same property in two places, and the usual
drift. With it, the delta tool only runs probes for things not yet built — which is also the
only set small enough to run on a whim.

## Briefs, criteria and cohorts

Each brief names the criteria it claims to close. The registry names no briefs. "Which briefs
chase this criterion" is derived by reading the briefs, so there is no second list.

Analysis against the codebase cuts **cohorts**: briefs that are unblocked now, worked in
parallel, whose completion removes the blockers for the next cohort.

- **Only the first cohort is trustworthy.** Every later one is computed against a codebase that
  does not exist yet. Compute the whole graph for depth; file only the current cohort as
  briefs. Everything past it stays a criterion. Re-derive after the cohort lands — cheap,
  because the probes are re-runnable.
- **Unblocked is necessary; disjoint is what makes it a cohort.** Two ready briefs touching the
  same files are a merge conflict with extra steps, which is the one-writer value stated
  differently.
- **Disjointness will be wrong, and it validates itself.** Two in-flight branches in the same
  cohort whose diffs overlap is a cohort error, derivable from git with nobody reporting it.
  Report the overlap. Do not gate on it.
- **A cohort is a serial race.** Filing several briefs at once is the window the project rules
  call invisible to every ledger. The cohort claims its serials in one act, before anyone
  starts, or the mechanism manufactures the collision it exists to prevent.
- **Disjoint files are not independent work.** The first branch to land can invalidate an
  assumption the other three were built on. That is the argument for small cohorts rather than
  maximally parallel ones.
- **Count what a cohort spawned.** Briefs born inside a cohort say so at birth. Over three or
  four cohorts that number is the first honest measure of how wrong the analysis is, and it
  says whether to cut smaller cohorts or spend more on the analysis.

### Ordering, and what it costs to write down

Schedule here means ordering only. No dates, no lateness.

The open question is whether a criterion declares what it depends on, or whether the order falls
out of the briefs that chase them. Declared order is a second copy that goes stale the moment a
brief re-plans its phases. Derived order can only see work already filed, which is exactly the
set you do not have when you are planning. This is the same tension this repository already
carries between its ledgers and its branches.

## Why this is a new record, and what it borrows

The criteria document is Contract-shaped. The verdict history on a criterion is ledger-shaped.
What does not fit is underneath both: **this toolkit has no concept of someone outside the work
having an opinion that matters.** Brief, ledger, declaration, chronicle and Contract all record
what the team did and decided. A commitment registry records what another party agreed to. It is
the first record here whose truth is not the team's to determine.

Three mismatches follow, and they are why this does not bend into a brief:

- A brief is one person's hypothesis. A criterion is two parties' commitment and its judge is
  not its author, so one-writer-per-file breaks at once.
- A brief closes and stays closed. A criterion can be accepted and then regress — the probe
  passes in March and fails in June. A closed brief that reopens is a defect; a criterion that
  reopens is the normal case.
- Lifespans do not nest. A criterion outlives the briefs that chase it, and several briefs over
  months may chase one. A per-brief ledger cannot hold its verdict history without scattering
  it.

Briefs and ledgers are unchanged. They gain one field: the criteria a brief claims to close.

## What it is for, said plainly

This is an AI-centric bridge to waterfall and board-shaped composition. It is the layer people
are used to believing. The team's real record stays the briefs and the ledgers, and the craft
those hold is not diluted to make the bridge easier.

A layer built only for other people to believe will rot. Nobody maintains a document they regard
as theatre, and a stale one is worse than none because the staleness is invisible to exactly the
audience that trusts it. So: **every field in the registry has an internal consumer.** Criteria
drive cohort cutting. Source citations say what a revision put at risk. Probes become tests.
Verdict provenance settles an argument six months out. A field that exists only because a
stakeholder expects to see it is the field that goes wrong first and loudest, and it should be
cut.

The honest version of this is not a hand-wavy layer. It is a **narrow** one — entirely true, and
structurally unable to imply more than it knows:

- **No percentages.** A count of open criteria is a fact. "68% complete" is a forecast wearing a
  fact's clothes.
- **No dates.** Ordering only.
- **Depth without sequence** past the current cohort, because everything past it is admittedly
  unplanned.
- **The uncomfortable number in the same view**, not a footnote: the last cohort spawned four
  briefs it did not predict. A reader who wants to believe the plan sees the plan and the
  measured amount by which plans here have been wrong, together. That is what lets the document
  be handed over without a warning attached — it carries its own, quietly, as a number.

## Report, do not gate

Nothing here blocks anything. An unaccepted criterion does not stop a brief closing.

The cost of that choice is known and should be designed for rather than discovered. A report's
whole influence is in being read, and this project's own evidence says reports are not read:
`tools/orient.sh` is good and nobody runs it, and sixteen undated closes have been reported on
every gate run since each brief closed. #0039 found the value was delivery, not derivation.
**This registry meets the same wall harder**, because its report is about other people's
commitments rather than the reader's own work.

## What this cannot prove

- **Whether an acceptance was sound.** The registry records that a verdict was given, by whom,
  when, and on what basis. Whether it was right is assured by a relationship, outside the record
  entirely. The registry will look like it is measuring that. It is not.
- **That the cohort analysis was correct.** A claimed dependency is an agent's reading of code.
  Each one should cite its evidence — this criterion needs that module, which does not exist,
  here is where it would go — or the cohort plan is an opinion in the shape of a computation.

## Open

- **How much is machine-checkable?** Unknown, and it decides whether this is a tool that reports
  a delta or a skill that helps a person form one. The cheapest test needs no tooling: hand-write
  five criteria with real probes for something already understood, and see whether writing them
  is hard and whether it teaches anything about the deliverable.
- **Declared or derived ordering.** Stated above.
- **Where the report is delivered** so that it is read at all.
- **Probe cost.** Behavioural probes are slow. Sixty of them standing up a stack is a report
  nobody runs. Tiers, and a default cheap enough to run on a whim.

## Out of scope

- **The Jira export.** `blc-export-to-jira` exists and renders the record to a board. Criteria
  would give it the epic layer it lacks. That is a consequence of this idea, not part of it.
