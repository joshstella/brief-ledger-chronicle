# Keep the Art and Play in Programming

This toolkit records reasoning while the work happens. It is not a substitute for thinking,
and it is not a ceremony to perform for an auditor.

## The problem

Decades of institutional "software engineering" produced process that slows programming
down without making it better: tickets, sign-offs, standups, and documentation written for
compliance rather than for the next person who has to change the code.

The old excuse was that there was never time to keep a real record. Working with AI
removes that excuse. The bet here is that a small set of rules, used at AI speed, beats
both heavy process and no process.

Computing was built by people who treated it as a medium for thought. A REPL, a live
image, a program you can hold in your head: you try something, see what happens, then
write down what you now know. Spec-first process inverts that order.

## Play, then spec

Spec-driven development has a waterfall shape inside it. Write the specification, agree
it, implement against it, then treat whatever diverged as an error. The order is the
problem: it asks you to know the most at the moment you know the least.

This is not an argument against specs. Specs are necessary. It is an argument about when
they earn their authority — after iteration, not before.

John Gall put the same observation on the architecture side in 1975:

> A complex system that works is invariably found to have evolved from a simple system
> that worked. A complex system designed from scratch never works and cannot be patched up
> to make it work. You have to start over with a working simple system.
>
> — John Gall, *Systemantics*

Gall's Law does not license never planning. A system that grew from a simple working one
still grew one understood step at a time. The law says the complex thing cannot be
specified into being up front. It does not say nobody should think ahead.

**Briefs and ledgers are not the spec. They are how the work gets recorded.**

- A **brief** is the claim you enter with: what you currently believe, why, and what you
  think is true about the code. It is filed before the work because it is the opening
  move, not because it is a contract you have agreed to deliver against.
- A **ledger** is the notebook: what the work taught, including where the brief was wrong.
  A brief with no ledger was planned and never executed. A ledger that only confirms its
  brief usually means nothing was at risk.
- A **chronicle** is written from the briefs, the ledgers, and git afterwards. That is
  only possible if the record was kept while the work happened.

A brief has to be capable of being wrong to be worth filing. It is a claim put where
reality can hit it.

The rest of the shape follows:

- **`_drafts/` lets an idea sit unnumbered.** Drafts are committed to git so they survive
  across machines. What they lack is a serial — filing, not committing, is the decision
  to do the work.
- **Branches are cheap.** A spike you intend to delete owes nothing to anyone.
- **Continuing a multi-phase brief re-plans** the remaining sequence from what the
  finished phases taught, rather than driving the original order after a finding should
  have changed it.

Then, if the work needs a specification, write it from that record. At that point it
describes something that exists.

Waterfall's failure was never that it wrote things down. It was that it wrote them down
first, and treated reality's disagreement as an error. Here the writing runs alongside
the work, and disagreement is the most useful thing in the file.

## Rules that hold, and rules that do not

If play is the point, why are there invariants, a Contract, and a review gate?

A game without rules is not an unconstrained game. It is not a game. Ceremony is a rule
that does not hold: a step performed for an audience that is not there. A rule that holds
is one you can check, or one whose failure is visible.

The test for any rule here: **it earns its place by making the work better to do.** A rule
that makes the work less worth doing has failed on its own terms, however defensible it
looks written down. Inside the process, adopted rules hold. That is the point. The same
test is how a rule gets adopted, kept, or dropped.

Not every rule is the same kind.

**Some rules are constitutional.** They define what the system is. An exception is a
crisis, not a judgment call. The mechanical test is external: a rule is constitutional
once someone has been told they can rely on it. Not once it feels settled. Breaking one
is a crisis because somebody downstream is depending on it. Constitutional status is a
consequence of publishing a promise, not a property to assess before publishing one.

**Other rules are common law.** A brief is the case. A ledger's big decisions are the
holding: the reasoned part that later work can cite instead of re-arguing. A chronicle is
the history of those holdings. A process whose only response to divergence is to correct
back into the original plan has no way for "the plan was wrong, and here is why the
resolution should stand" to become citable.

## The present tense

Brief, ledger, and chronicle all describe how a system came to be. None of them says what
it currently **is**.

A brief is future tense. A ledger is past tense. A chronicle is past tense and derived.
To learn what a system guarantees today, a reader would otherwise reconstruct it from
every case ever decided.

A **Contract** states, in the present tense, what a system's consumers may rely on for a
given version. It is written from the briefs and ledgers rather than ahead of them. That
is what makes it a specification that earned its authority. The trigger is external:
**someone has to build against it.** Not "does this feel finished." A Contract is where a
rule goes to become constitutional. Publishing it is the act that makes breaking it a
crisis.

Versioned, because a promise holds for a time. A later version supersedes an earlier one
without making it retroactively false.

A Contract is the only artifact that is both derived from the record and committed to the
repository. A chronicle is generated and read. A Contract cannot work that way, because
others depend on it. So it can rot. **A contract that has drifted is worse than no
contract, because it is believed.** The tie to the code has to be structural. Discipline
will fail the way hand-synced documents have always failed.

This one was unbuilt until a consumer existed. The installer puts the briefs convention
into other people's projects — which is the act of telling someone they can count on it.
Version 1 states that convention as eight clauses with stable ids, extracted from
conventions already in force.

The structural tie is `tools/validate-briefs.sh`. Every clause in version 1 names it. It
runs in CI against this repository's own briefs. It ships into the projects the Contract
binds, so a consumer can check the promise rather than take it on trust.

Everything else here remains uncontracted: the installer's behaviour, the skills, the
shape of a ledger, `open-briefs.sh`. No promise has been made about them, so none is
owed. Publishing one before that would be the specification-first move this document
argues against.

Two further limits are worth stating because they are easy to overclaim:

- **Skills are prompts, not programs.** `start-brief`, `create-brief`, and the rest
  instruct an agent. The test suite checks that they get installed. It does not check
  that the agent follows them. A sentence in a skill is not a guarantee.
- **`open-briefs.sh` reports. It does not run itself.** A ledger can sit unfinished
  indefinitely and still satisfy Contract v1. The query exists so that stall is visible
  when someone asks. Until something invokes it on a cadence, asking is still manual.

## Why codebases are full of surprises

A survey of roughly three dozen filed briefs in a working project found this: the
discoveries that mattered — a "dead" tab proving load-bearing, two unrelated fields
colliding on the same name, a rename exposing a pre-existing race — all came from briefs
that made a **specific, falsifiable claim about the current state of the code that turned
out to be wrong**.

The largest-blast-radius briefs were filed with an accurate model of what they would
touch. Foreknown scale, not corrected belief.

One brief did both at once, which is evidence these are not two phenomena. A codebase has
more real structure than any single mental model captures. That shows up differently
depending on how accurate the starting model was.

This is Gall's Law from the inside. A working system got that way by growing from simpler
working ones, and **the surprises are the seams** — places where an earlier system's
assumptions are still load-bearing under something built later that never knew about
them. They are not planning failures.

**So write briefs that can be wrong.** A brief that commits to a checkable claim about the
code is how the code gets to correct you.

## Against calcification

Any teaching can be turned into dogma. That cannot be prevented from outside.

What is controllable:

- **Keep the provided surface small.** Few mandatory fields.
- **Use is permissive.** Write what is worth writing. Skip what is not.
- **Some tools report, some tools gate, and the difference is named.** `chronicle` and
  `open-briefs.sh` observe. `review-pr` and `validate-briefs.sh` gate. A gate earns its
  place the same way any other rule does: it makes the work better, or it goes.
- **Treat everything external as optional.** If a team already has an issue tracker,
  carry a correlation ID. No integration is load-bearing. None requires the other tool
  to exist.

## Held to the same standard

Work here should be judged by whether it stayed worth doing, not by roadmap velocity or
adoption counts. The tools are free and self-hosted. There is no control plane, no tenant
model, and nothing to sell.

**Show a more useful way of making things. Do not argue people out of the old one.**
