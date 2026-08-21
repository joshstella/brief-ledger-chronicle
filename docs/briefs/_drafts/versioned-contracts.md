# A fourth artifact: versioned contracts

**Created:** 2026-08-21T17:20:00Z · **Author:** josh.stella@gmail.com
**Depends on:** —

> Draft note: unnumbered by design. `create-brief` assigns the serial at filing.

## Ground

Brief, Ledger, and Chronicle record how a system came to be. None of them state what it
**is**.

- A **Brief** is the hypothesis entered with — future tense.
- A **Ledger** is what the playing taught — past tense, in flight.
- A **Chronicle** is the narrative of the briefs and ledgers — past tense, derived, and
  deliberately never committed as a source of truth.

Nothing is in the present tense. To learn the current rule, a reader has to reconstruct it
from every case ever decided.

The Manifesto names spec-driven development as *"a legal system with no case-law layer."*
This is the symmetric failure: **a legal system with no statute layer.** All holdings, no
codification.

The artifact is not hypothetical. It already exists, built by hand and unnamed, as a design
document carrying an invariant index whose rules are tagged either as hard violations that
block a change or as judgment calls surfaced for a human. That document is exactly this
artifact. The Manifesto cites it as an example of constitutional rules without noticing
that the *document itself* is the missing category.

The Manifesto also ends "Play, then spec" with "if the work genuinely needs a
specification, it gets written from all of that" — and then provides nowhere to put it.

## What "baked" means (settled)

**Baked means another programmer can count on it for a time — a version.**

This is load-bearing and worth stating precisely, because it makes the trigger *external*
rather than a judgment about maturity. You do not codify because the work feels finished.
You codify because someone else needs to build against it. That is observable; "is this
settled yet?" is not.

Two consequences follow:

1. **Versioned, not amended in perpetuity.** A version states what holds for that version.
   A later version supersedes it without retroactively making the earlier one false.
2. **It closes an open question in the Manifesto.** The constitutional/common-law section
   currently concedes there is no mechanical test for what deserves constitutional status.
   There is one: *a rule is constitutional when a version of it has been published and
   someone has been told they can count on it.* Breaking it is a crisis rather than a
   judgment call precisely because somebody depends on it — a consequence of publishing,
   not a separate property to assess.

So this artifact is not only a missing output. It is the mechanism by which a rule *becomes*
constitutional. The Manifesto has the category and no way to enter it.

## The central hazard

This is the only artifact that is both **derived from the record** and **must be
committed**.

Chronicle avoided the drift problem by never being a source of truth — it is generated on
demand and read by a human. A contract cannot do that. Others depend on it, so it has to
be in the repo, which means it can drift from the code it describes.

**A contract that has drifted is worse than no contract, because it is believed.**

This is the same failure this toolchain has now hit three times: an installed artifact
whose source moved on; a duplicate serial that no validator checked for; two hand-synced
copies of the same document that diverged silently. Any design here that relies on
discipline to stay accurate will fail the same way. The mechanism must be structural.

## Change

A fourth artifact holding the present-tense, versioned statement of what a system's
consumers may rely on. Written from the brief/ledger record rather than in advance of it.
New briefs are argued against the current version, the way a case is argued against
standing statute.

## Settled decisions

- **Present tense, versioned, superseding.** Not a changelog and not a roadmap.
- **Committed to the repo.** Consumers depend on it, so it cannot be generate-on-demand
  like a Chronicle.
- **Written from the record, not ahead of it.** Consistent with play-then-spec: it
  describes something that exists and has been understood.
- **The trigger is external dependence**, per "what baked means" above.

## Open decisions

1. **What it is called.** Three candidates, each with a real argument:
   - **Contract** — plainest, and closest to how the need was first described. Says exactly
     what it is: a promise another programmer may rely on.
   - **Codex** — completes the legal metaphor precisely; a codex *is* codified case law.
     Pairs with Chronicle. Risks preciousness.
   - **Spec** — the Manifesto already concedes specs are necessary and argues only about
     *when*. Using the word reclaims it rather than ceding it to spec-first tooling. Risks
     being read as the thing the Manifesto argues against.
2. **Whether the repo name has to change.** `brief-ledger-chronicle` was settled recently
   and renaming again has a cost. The alternative reading: the three remain the *process*
   and this is its *output*, in which case the name survives unchanged. Decide this
   deliberately rather than letting the naming choice force it.
3. **Where it lives and how versions are kept.** One file superseded in place with history
   in git, or `docs/contracts/v1.md`, `v2.md` side by side? Side-by-side makes "what could I
   rely on in v1" answerable without archaeology; in-place keeps one obvious current
   answer.
4. **How drift is detected.** Given the hazard above, what structurally ties the contract to
   the code — tests asserting the stated invariants, a check that every published rule has a
   test, or something else? A contract nobody verifies is the drift problem again.
5. **Whether it gets a skill.** `chronicle` renders the record on demand; the equivalent
   here would draft a version from the briefs and ledgers since the last one. Possibly the
   natural follow-on, but better designed against a hand-written first version than guessed
   at now.

## Success criteria

- A reader can learn what a system currently guarantees without reading its history.
- A new brief can cite the current version as standing rule rather than re-deriving it.
- A published rule that the code no longer honours is detected, not discovered later.
- Superseding a version does not require rewriting or invalidating earlier ones.

## Non-goals

- Not a changelog, a roadmap, or release notes.
- Not a replacement for briefs or ledgers; it consumes them.
- Not a gate on exploratory work. Play does not owe a contract anything until someone is
  asked to depend on the result.
