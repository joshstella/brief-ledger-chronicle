# Keep the Art in Programming

*Install it into your project and be creative — the tools will document what happened.
Have fun.*

## The ceremony outlived the art

Decades of "Software Engineering" as an institutional discipline produced a great deal of
process whose actual effect was to slow programming down without making it better.
Tickets. Sign-offs. Ritual standups. Documentation written for an auditor rather than for
the next person who has to think about the code.

Real programming — in Knuth's sense, *The Art of Computer Programming* — treats
explaining your reasoning clearly, as you do the work, as part of the craft itself. Not
overhead bolted onto it. Much of what passes for engineering process lost exactly that:
it kept the ceremony and dropped the art.

The old excuse for the ceremony was that there was never time to do the real thing.
Working with AI removes that excuse. What follows is a bet that a lightweight, human-first
way of working, done at AI speed, is both more enjoyable *and* more effective than either
the old ceremony-heavy discipline or no discipline at all.

## A lineage, not an invention

Alan Kay, John McCarthy, and Edsger Dijkstra agreed on almost nothing. They shared one
thing that enterprise software development has since dehydrated out of the field.

Kay's Smalltalk was a live, moldable system you explore and reshape as you think — not a
pipeline you feed specifications into. McCarthy's LISP gave us the REPL, and with it the
idea that you *talk to* a program while building it rather than submitting it for later
judgment. Dijkstra is usually claimed by the rigor-and-proof camp, which sounds like the
opposite of joy; but his actual motivation was that a program should be clear enough to
hold whole in your head — an aesthetic and intellectual pleasure in its own right, just a
quieter one than Kay's playfulness.

Three temperaments, one claim: **computing was invented by people who found it a source of
delight and discovery.** A great deal of institutional process is what remains after that
gets systematically wrung out in the name of predictability.

AI is the best technology for putting play and art back into programming since Smalltalk.
That is the animating idea here — not process discipline for its own sake, but restoring
programming as a medium for play and thought.

## It feels like jamming

Working with AI on code doesn't feel like that dehydration. It feels like **jamming**:
skilled and improvisational at once, building live off what the other player just did.

That is a genuinely different feel from both rigid ceremony and undisciplined hacking, and
it is the experience these tools exist to preserve — not to argue for abstractly.

In that frame, a Brief, a Ledger, and a Chronicle are not a score to be played exactly,
and not silence either. They are closer to **lead sheets and changes**: enough structure to
jam *on*, with a record of the session kept afterward because it was worth remembering —
not because someone made you file it.

## Play, then spec

Spec-driven development has a waterfall shape hiding inside it. Write the specification,
agree it, implement against it, then reconcile whatever diverged. The order is the problem:
it asks you to know the most at the moment you know the least.

**This is not an argument against specs.** Specs are necessary. It is an argument about when
they earn their authority — *after* iteration and experimentation, not before.

This is much older than any current argument about tooling. In 1975 John Gall — a
paediatrician, not a software person — put it as a law:

> A complex system that works is invariably found to have evolved from a simple system
> that worked. A complex system designed from scratch never works and cannot be patched up
> to make it work. You have to start over with a working simple system.
>
> — John Gall, *Systemantics*

Gall's Law is the same observation from the architecture side. You cannot specify a complex
system into existence; it has to grow from something simple that already worked. The
failure mode is identical to the waterfall one above — both are attempts to know the most
at the moment you know the least.

It is worth saying what Gall's Law does *not* license, because it gets quoted that way. It
is not an argument for never planning. A system that grew from a simple working one still
grew *deliberately*, one understood step at a time. The law says the complex thing cannot
be specified into being up front; it does not say nobody should think ahead.

The lineage was already doing this. A REPL is play-then-spec. A live Smalltalk image is
play-then-spec. You jam first; the chart gets written from what worked.

**Briefs and Ledgers are not the spec. They are how the play gets recorded.**

That distinction is the whole point, and it is easy to miss because both involve writing
things down before you are finished.

A **Brief** is the hypothesis you enter the play with: what you currently believe, why, and
what you think is true about the code right now. It is filed before the work because it is
the opening move — not because it is a contract you have agreed to deliver against. A
**Ledger** is the lab notebook: what the play actually taught, including, and especially,
where the brief turned out to be wrong. A brief with no ledger was planned and never
played. A ledger that merely confirms its brief usually means nothing was risked.

This is why a brief has to be capable of being wrong to be worth filing. It is not a
promise; it is a claim put where reality can hit it.

The rest of the shape follows from that:

- **`_drafts/` lets an idea sit unnumbered** for as long as it needs to. Being uncommitted
  is exactly what makes it a safe place to be wrong.
- **Branches are free.** A spike you intend to delete owes nothing to anyone.
- **Continuing a multi-phase brief re-plans the remaining sequence** from what the finished
  phases actually taught, rather than barrelling through the original order after a finding
  should have changed it.
- **A Chronicle is written from the record afterwards**, which is only possible because the
  record was kept while the playing happened rather than reconstructed later.

Then, if the work genuinely needs a specification, it gets written from all of that — by
which point it is describing something that exists and has been understood, rather than
predicting something nobody has touched yet.

Waterfall's failure was never that it wrote things down. It was that it wrote them down
first, and then treated reality's disagreement as an error to be corrected. Here the
writing runs *alongside* the playing, and reality's disagreement is the most valuable thing
in the file.

## Rules come in two kinds

Not every rule belongs to the same category, and knowing which kind you are writing is
itself a design decision worth naming.

**Some rules are constitutional.** They define what the system fundamentally *is*, and an
exception isn't a judgment call — it's a crisis. A public API's contract. A design
document whose invariants are tagged as either hard violations that block a change with no
argument entertained, or judgment calls surfaced for a human to decide. Projects build this
split on their own, long before anyone hands them the vocabulary for it, which is good
evidence that it is a real pattern rather than a theory imposed from outside.

**Other rules are common law.** A **Brief** is the case brought for resolution against
standing rules and against whatever has already been decided. A **Ledger**'s big decisions
aren't merely how one case came out — they are the *holding*: the reasoned part that
becomes citable afterward, so a later brief can treat an earlier one's design choice as
settled precedent instead of re-litigating it from scratch. A **Chronicle** is the
doctrinal history: how the accumulated body of resolved cases actually shaped the system's
character over time, which is a different and additional thing from what the specification
says on its own.

The bet is that **a body of well-reasoned cases is its own kind of authority** — not just
raw material to be folded back into rewriting the specification every time.

A process whose only response to divergence is to correct back into conformity has no
case-law layer at all. Every departure from the plan is, by construction, an error. There
is no way for *"this situation revealed the plan was wrong, and here is why the resolution
should stand"* to become citable material. That is the thing worth building that such
processes structurally cannot hold.

What deserves constitutional status in a project without an obvious existing example is
itself a judgment call. Naming it as one is more honest than inventing a mechanical test
that doesn't exist.

## Why codebases are full of surprises

A survey of roughly three dozen filed briefs in a working project, run specifically to
test this, found something worth stating plainly.

Codebases accumulate a series of goals, each layering new intent onto whatever earlier
goals left behind. The serendipitous discoveries — a "dead" tab proving load-bearing, two
unrelated fields colliding on the same name, a storage-key rename exposing a pre-existing
race condition — all came from briefs that made a **specific, falsifiable claim about the
current state of the code that turned out to be wrong**. The equivalent of a case revealing
that the statute didn't say what everyone assumed.

The largest-blast-radius briefs, by contrast, were filed with an accurate and often
explicitly enumerated model of what they would touch. Foreknown scale, not corrected
belief.

One brief did both at once — a structural change whose call-site count was badly
underestimated — which is the clearest evidence that these are not two phenomena but one:
a codebase has more real structure than any single mental model captures, and that shows up
differently depending on how accurate the starting model happened to be.

This is Gall's Law observed from the inside, after the fact. A working system got that way
by growing from simpler working ones, and **the surprises are the seams** — the places
where an earlier system's assumptions are still load-bearing under something built later
that never knew about them. No amount of care at specification time removes them, because
they are not planning failures. They are what accumulated structure feels like from within.

**So write briefs that can be wrong.** A brief that commits to a checkable claim about the
code is how the code gets to correct you.

## Against calcification

Any teaching, including an anti-dogmatic one, can be turned into dogma by whoever adopts
it. That cannot be prevented from outside, so there is no enforcement mechanism here — none
would work anyway.

What is actually controllable is narrower and real:

- **Keep the provided surface small.** Few mandatory fields. No required ceremony.
- **Frame use as permissive and creative, rather than procedural.**
- **Documentation follows from doing the work, not the reverse.** The tools observe and
  narrate. They do not gate and they do not require.
- **Treat everything external as an optional artifact to piggyback on.** If a team already
  has an issue tracker or a specification format, work with what is there — carry a
  correlation ID, narrate an existing history. No integration is load-bearing. None
  requires the other tool to exist.

Write what is worth writing, skip what isn't, and let the record accumulate as a side
effect of doing the work.

## Held to the same standard

Everything most worth having in this field was made because it was fun, not to carve out a
position. The spirit this project wants to restore to programming should govern how the
project itself gets built — not only what it produces for others.

Concretely: work here should be judged by whether it stayed worth doing, not by roadmap
velocity or adoption counts. The tools are free and self-hosted. There is no control plane,
no tenant model, and nothing to sell.

**The ethos, stated plainly: inspire people by showing a more joyful way of making things,
not by arguing them out of the old one.**
