# A fourth artifact: the Contract

**Serial:** #0003 · **Created:** 2026-08-21T17:20:00Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## Ground

Brief, Ledger, and Chronicle record how a system came to be. None of them states what it
**is**.

- A **Brief** is the hypothesis entered with — future tense.
- A **Ledger** is what the playing taught — past tense, in flight.
- A **Chronicle** is the narrative of the briefs and ledgers — past tense, derived, and
  deliberately never committed as a source of truth.

Nothing is in the present tense. To learn the current rule, a reader has to reconstruct it
from every case ever decided. The Manifesto now names this directly in *The present tense
is missing*: a legal system with no statute layer, all holdings and no codification.

**The artifact is not hypothetical, and it is not elsewhere. It is already in this repo,
degraded.** `docs/briefs/README.md` §"Structural invariants (checkable)" publishes eight
present-tense rules, each tagged `[defect]` (hard violation) or `[advisory]` (flag for a
human). That is a Contract. It was written by hand, it was never named, and it lives buried
inside a narrative README that is mostly explanation.

The same pattern appears in `skills/review-pr/SKILL.md`, which hard-gates on the `[defect]`
rules of a design document's invariant index — an instance of the artifact in a different
project, cited by this one.

## The evidence that this is the right work now

The draft that preceded this one described the drift hazard as a lesson learned three times.
Checking the repo, all three failures are **live, in this tree, today**:

1. **Published rules with no enforcement.** The README says these are invariants "a
   validator can enforce" — conditional tense. No validator exists. `tests/` covers
   `install.sh` only (args, force, hosts, install log, machine and project mode). Eight rules are
   published, believed, and checked by nothing.
2. **The rules exist in three places, in two forms, and two of them have already
   diverged.** They are asserted in `docs/briefs/README.md` (93 lines), asserted again in
   `templates/docs/briefs/README.md` (112 lines), and *enacted as procedure* in
   `skills/create-brief/SKILL.md`, whose steps re-implement invariants 2, 3 and 5 — the slug
   regex, the collision guard, the identity-line shape — rather than citing them. None of
   the three is marked as the source. The two READMEs have already drifted: the templates
   copy carries the duplicate-serial post-mortem and the two-checkouts analysis, and the
   other does not. Knowledge loss in one direction, silently.
3. **The tag vocabulary is split.** `[defect]` is consistent across all three files that use
   it. The soft tag is `[advisory]` in the two briefs READMEs and `[judgment]` in
   `review-pr`. Two names for one category, inside one repo, with nothing to notice.
4. **A fourth location arrived while this draft was being written.** `templates/process-rules.md`
   (added by #4) states process rules in the present tense — what gates `main`, which skills
   are mandatory, that tests are required. It is a Contract in everything but name, and like
   the other three it carries no tags and no checks.

This is what a missing statute layer costs, observed from the inside rather than argued for.

## What "baked" means (settled)

**Baked means another programmer can count on it for a time — a version.**

The trigger is *external* rather than a judgment about maturity. You do not codify because
the work feels finished. You codify because someone else needs to build against it. That is
observable; "is this settled yet?" is not.

Two consequences:

1. **Versioned, not amended in perpetuity.** A version states what holds for that version. A
   later version supersedes it without retroactively making the earlier one false.
2. **It supplies the Manifesto's test for constitutional status** — now written into *Rules
   come in two kinds*: a rule is constitutional once someone has been told they can rely on
   it. Breaking it is a crisis because somebody depends on it, not because the rule has
   intrinsic weight. A Contract is where a rule goes to acquire that status.

## The central hazard

This is the only artifact that is both **derived from the record** and **must be
committed**.

A Chronicle escapes the drift problem by never being a source of truth — generated on
demand, read once. A Contract cannot, because others depend on it. So it can rot.

**A contract that has drifted is worse than no contract, because it is believed.**

Per the evidence above, this is not a risk to guard against in future. It is the current
state of `docs/briefs/README.md`. Any design here resting on discipline will fail exactly
the way the two README copies already failed. The mechanism must be structural.

## Half the mechanism already exists here

The same change (#4) that added the fourth location also fixed one of the two drift problems
for it. Being precise about *which* one matters, because the other is the hard one.

`templates/CLAUDE.md` and `templates/AGENTS.md` used to state the process rules twice, by
hand, for two hosts. #4 deleted both (−134 lines) in favour of one `templates/process-rules.md`
(+26), and `install.sh:198–223` renders that single body to both destinations, prepending YAML
frontmatter for Cursor. One source, generated outputs, hand-sync made structurally impossible.

**That solves duplication, not verification.** Nothing in `tests/` or `install.sh` checks a
single claim `process-rules.md` makes. #4 gave the process rules one home; it did not make
them true. The two halves are independent, and only the first one is done.

The first half is still worth having, and it is exactly the fix the two diverged briefs
READMEs need — already built and working in the same repo, so this brief reuses it rather than
inventing a second one. It is worth noting how it arrived: working from a different machine,
on a different ruleset, the same conclusion was reached independently — pull the present-tense
rules out of the narrative documents and give them one home. This brief does not have to argue
for that pattern. It has to finish applying it, and then do the half that is left.

## Change

Consolidate the present-tense rules this repo already publishes into a real Contract, and
make them enforceable. Concretely:

- Extract the eight structural invariants out of `docs/briefs/README.md` into a Contract as
  the single source, leaving the README to explain and link rather than restate, and leaving
  `create-brief` to cite the clauses it enacts rather than paraphrase them.
- Write the validator the README has been promising, so `[defect]` rules are checked rather
  than believed.
- Resolve the `[advisory]` / `[judgment]` split into one tag name.
- Remove the hand-sync between the two README copies by reusing the generation pattern
  `install.sh` already applies to `process-rules.md`, so the drift already present cannot
  recur — the same mechanism, not a second one invented for this case.
- State, in the Contract itself, which clauses are checked and which are not — naming the
  check by path, so the sentence goes stale if the link breaks and has to be maintained.
- Carry a hand-stamped review date for the *unchecked* clauses only. The checked ones need no
  date: CI is their date, refreshed every run. The unchecked ones have nothing else to signal
  whether a human has looked lately.

The format is learned from doing this, not specified ahead of it. That is the point: there
is a hand-written instance to spec from, so the spec gets written from the record — which is
what the Manifesto claims should happen and has not yet been demonstrated by this toolkit on
itself.

## Settled decisions

- **It is called a Contract.** The trigger and the name agree exactly: a Contract is what
  another programmer may rely on. `Codex` completes the legal metaphor more neatly but
  collides with a product name in this exact domain. `Spec` would reclaim the word, but
  would also make the toolkit's own vocabulary argue against the Manifesto's thesis to
  anyone skimming. The asymmetry with three record-nouns is deliberate — a Contract is a
  different category from a record, and the name should say so.
- **The repo name does not change.** `brief-ledger-chronicle` names the *process*; the
  Contract is its *output*.
- **Present tense, versioned, superseding.** Not a changelog and not a roadmap.
- **Committed to the repo.** Consumers depend on it, so it cannot be generate-on-demand like
  a Chronicle.
- **Written from the record, not ahead of it.** The record here is the existing invariants
  section plus the briefs and ledgers that produced it.
- **The trigger is external dependence**, per "what baked means" above.
- **A Contract does not make itself true, and says so.** Where a rule can be checked by a
  program it is, and the document names which ones and by what. Where it cannot, the rule is
  as reliable as the people following it. Writing it down changes where you look it up, not
  whether it holds. The generic form of this belongs in the Manifesto, stated once; the
  specific checked-set sentence belongs in each Contract, where the believing happens.
- **Staleness is timestamped on the unchecked clauses only.** A machine-written "last
  verified" stamp is rejected deliberately: it would rewrite the file on every CI run and
  produce a diff nobody reads. Hand-stamped human review, plus CI status for the rest.
- **This repo's first Contract is an extraction, not an invention.** The rules already exist
  and are already relied upon by the skills; the work is consolidation and enforcement.

## Open decisions

1. **Where it lives and how versions are kept.** One file superseded in place with history
   in git, or `docs/contracts/v1.md`, `v2.md` side by side? Side-by-side makes "what could I
   rely on in v1" answerable without archaeology; in-place keeps one obvious current answer.
   Decide against the extraction in hand rather than in the abstract.
2. **What stops a *future* rule from being published without a check.** Duplication is
   handled — the `process-rules.md` generation pattern settles it. The eight existing rules
   are machine-decidable, so the validator itself is tractable. The open part is narrower: a
   test asserting that every `[defect]` clause has a corresponding check, or something
   weaker. Without it the drift returns one rule at a time, which is how it arrived.
3. **Which tag name survives**, `[advisory]` or `[judgment]`. `[judgment]` pairs better with
   "judgment call" as the Manifesto uses it; `[advisory]` pairs better with `[defect]` as a
   severity. Low stakes, but it must be decided once and enforced, since having both is the
   bug.
4. **Whether it gets a skill.** `chronicle` renders the record on demand; the equivalent here
   would draft a version from the briefs and ledgers since the last one. Better judged after
   v1 exists than guessed at now.

## A tension to resolve after implementation

The Manifesto's new section closes by saying no Contract is owed yet, because nobody depends
on this repository. The evidence above puts pressure on that. The eight invariants are
already published in present tense; `README.md` points readers at them as "the convention";
and `create-brief` was *built to them*, re-implementing three as its own procedure. A rule
that a skill has been coded against is a rule something depends on, whoever wrote the skill.

If that reading holds, the Manifesto line is wrong in a specific and fixable way — the
Contract is *unbuilt*, not *unowed*. Deliberately not resolved here. Implement first, then
revisit the Manifesto against what the extraction actually taught.

## Success criteria

- A reader can learn what this repo currently guarantees without reading its history.
- Every `[defect]` rule is checked by something that runs, not asserted in prose.
- The two README copies can no longer silently diverge.
- One tag vocabulary, used everywhere.
- A new brief can cite the Contract as standing rule rather than re-deriving it.
- Superseding a version does not require rewriting or invalidating earlier ones.

## Non-goals

- Not a changelog, a roadmap, or release notes.
- Not a replacement for briefs or ledgers; it consumes them.
- Not a gate on exploratory work. Play does not owe a Contract anything until someone is
  asked to depend on the result.
- Not a general Contract format for all projects using this toolkit. One instance, written
  by hand, before anything is generalized.
