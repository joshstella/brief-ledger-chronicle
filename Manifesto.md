# Keep the Art and Play in Programming

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
predicting something nobody has touched yet. That specification is an artifact in its own
right, and it is the subject of a later section.

Waterfall's failure was never that it wrote things down. It was that it wrote them down
first, and then treated reality's disagreement as an error to be corrected. Here the
writing runs *alongside* the playing, and reality's disagreement is the most valuable thing
in the file.

## Homo Ludens

The argument so far is that the play comes first and the specification is written from what
the play taught. That invites an obvious objection: if play is the point, what are all these
rules doing here — the invariants, the Contract, the review gate?

In 1938 the Dutch historian Johan Huizinga published *Homo Ludens*, a study of the
play-element in culture. His claim was not that people need recreation. It was that play is
older than culture and that culture grows out of it — law, poetry, war, and philosophy each
begin in a play-form and keep that shape long afterwards. *Homo Ludens*, man the player,
set beside *Homo Faber*, man the maker.

What he found at the centre of play was not freedom. It was order:

> Inside the play-ground an absolute and peculiar order reigns. [...] It creates order, is
> order. Into an imperfect world and into the confusion of life it brings a temporary, a
> limited perfection.
>
> — Johan Huizinga, *Homo Ludens*

Every game is a bounded space with rules that hold inside it. Huizinga's examples run from
the tennis court to the temple to the court of justice — all of them grounds marked off
beforehand, where for a while different rules apply. Remove the boundary and the play does
not get freer. It stops. A game without rules is not an unconstrained game; it is not a
game.

He drew one further distinction worth keeping. The cheat breaks the rules while still
pretending they hold, and so leaves the game standing. The spoil-sport denies the rules
altogether, and in walking off the court destroys the world the other players were in. Of
the two, the spoil-sport does the greater damage.

**So: play requires rules, and these are the rules.**

A brief that is capable of being wrong. A ledger that records what the play actually taught.
A serial assigned in exactly one place. A Contract that states what a consumer may rely on,
versioned, written afterwards. A short list of invariants with a checker standing behind
them. That is the court, marked off beforehand — and it is why this document can argue
against ceremony at length and then hand you a validator without contradicting itself.
Ceremony is rules that do not hold: steps performed for an audience that is not there. Rules
that hold are what make the playing possible.

The test for any rule here follows from that, and it is the same test the rest of this
document keeps arriving at from other directions: **a rule earns its place by making the
game better to play.** One that makes the work less worth doing has failed on its own terms,
however defensible it looks written down. This is not licence to ignore the rules — inside
the court they hold absolutely, which is the whole point — but it is the standard by which a
rule gets adopted, kept, or dropped.

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

What deserves constitutional status looked for a long time like a judgment call with no
mechanical test behind it. There is one, and it is external rather than a matter of taste:
**a rule is constitutional once someone has been told they can rely on it.** Not once it
feels settled, or mature, or important — once a promise has been made and somebody is
building against it.

That is also why breaking one is a crisis rather than a judgment call. Not because the rule
carries some intrinsic weight, but because somebody downstream is depending on it.
Constitutional status is a *consequence* of publishing a promise, not a property to be
assessed before publishing one. Which is what makes it checkable: "is this baked yet?" has
no answer, but "did we tell anyone they could count on this?" does.

## The present tense is missing

Brief, Ledger, and Chronicle all describe how a system came to be. None of them says what
it currently **is**.

A Brief is future tense — the hypothesis going in. A Ledger is past tense — what the play
taught. A Chronicle is past tense and derived — the doctrinal history. To learn what a
system guarantees *today*, a reader has to reconstruct it from every case ever decided.
That is a legal system with no statute layer — all holdings, no codification — and it is
the exact mirror of the process described above that has no case-law layer at all. Neither
is better than the other.

So there is a fourth artifact, and it is not a record. A **Contract** states, in the present
tense, what a system's consumers may rely on for a given version. It is written from the
briefs and ledgers rather than ahead of them — which is precisely what makes it a
specification that earned its authority instead of one that assumed it. This is where the
spec from "play, then spec" goes.

The trigger for writing one is deliberately external. Not *does this feel finished* — that
question has no answer, and inviting it is how projects end up codifying things nobody
needed codified. The trigger is: **someone has to build against it.** Which is the same
test that decides constitutional status, arriving from the other direction. A Contract is
where a rule goes to *become* constitutional; publishing it is the act that makes breaking
it a crisis.

Versioned, because a promise holds for a time. A later version supersedes an earlier one
without making it retroactively false — the difference between a Contract and a
specification that has to be continuously rewritten in order to stay true.

One hazard is worth stating plainly, because it is what makes this harder than the other
three. A Contract is the only artifact that is both derived from the record *and* has to be
committed to the repository. A Chronicle escapes the drift problem entirely by never being
a source of truth: it is generated on demand and read once. A Contract cannot do that,
because others depend on it. So it can rot. **A contract that has drifted is worse than no
contract, because it is believed.** Whatever ties it to the code therefore has to be
structural. Anything resting on discipline will fail the way hand-synced documents have
always failed.

This one was unbuilt for a long time, and that was the rule working rather than an omission:
nobody depended on the repository, so no Contract was owed. It is built now, and the trigger
fired exactly where the rule said it would. The installer puts the briefs convention into
other people's projects — which is the act of telling someone they can count on it. Version 1
states that convention as eight clauses with stable ids. It was extracted from conventions
already in force and already recorded, not invented ahead of them.

The structural tie that the paragraph above demands is `tools/validate-briefs.sh`. Every
clause in version 1 names it. It runs in CI against this repository's own briefs on every
change, so the Contract cannot drift from the thing it describes without the build going red.
And it travels with the Contract into the projects the Contract binds, so a consumer can
check the promise rather than take it on trust.

Everything else here remains uncontracted: the installer's behaviour, the skills, the shape
of a ledger. No promise has been made about them, so none is owed, and publishing one before
that would be the specification-first move this whole document argues against.

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
