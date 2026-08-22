# Ledger — #0003 A fourth artifact: the Contract

**Brief:** `docs/briefs/0003-contract-artifact/brief.md`
**Status:** in-progress
**Date:** 2026-08-21

## Phase sequence

| id | status | what it does |
|---|---|---|
| `phase 1 — extract the contract` | complete (PR #9) | Create the Contract at the decided path, carrying the eight invariants as clauses with stable ids. Resolve open decisions 1 and 3. Point `docs/briefs/README.md` at it instead of restating. Add the checked-set sentence (which at this point honestly reads *nothing here is checked yet*) and the hand-stamped review date for unchecked clauses. |
| `phase 2 — validator` | complete (PR #10) | `tools/validate-briefs.sh` implementing clauses 1–8, each finding citing its clause id, driven by `tests/test_briefs.sh`. Contract's checked-set sentence now names the path. Standalone script rather than test-only — see Big decisions. |
| ~~`phase 3 — report unchecked clauses`~~ | **folded into phase 2** — the report has nothing to report. Every v1 clause names a check, and `briefs_every_named_check_path_resolves` already fails on a check that does not exist. A report over the empty set does not earn a review. It returns when v1 grows a clause without one. | **Demoted from a gate to a report.** Phase 2 landed the link half: `briefs_every_named_check_path_resolves` fails if the Contract names a check that does not exist. What remains is the report over clauses *without* checks, which is currently empty and will stay empty until v1 grows a clause. | The Contract lists which clauses have checks and which do not. It never requires one. Originally specified as a meta-check blocking any clause without a test; that is a cost at the moment of action and would stop you adding a rule until you had written its test. |
| `phase 4 — de-duplicate the readmes` | in-progress — `feature/contract-readme-dedupe` | End the hand-sync between `docs/briefs/README.md` and `templates/docs/briefs/README.md`. Resolved by deleting the template copy and shipping this repository's own docs, which required shipping the Contract and its validator — see Big decisions. |
| ~~`phase 5 — reconcile review-pr tags`~~ | **dropped** | Removed once open decision 3 resolved in favour of `[judgment]`. `review-pr` already uses the surviving name, so there is nothing to reconcile. See Big decisions. |

## Dependency structure

- **Strict chain:** `phase 1 → phase 2 → phase 3`. Phase 2 needs clause ids to cite; phase 3 reports on what phase 2 built. Phase 3 is small now that it only reports — fold it into phase 2 if it does not earn its own review.
- **Parallel track after phase 1:** `phase 4` only, independent of the chain. (`phase 5` dropped — see Big decisions.)
- **Provisional past phase 1.** Phase 1 chooses the Contract's path *and its clause-id scheme*. The id scheme cannot be retrofitted — phase 3's meta-check keys on it — so phase 1 must be designed with phase 3 in mind, or phase 3 forces a rewrite of the Contract. `/next-brief-phase` re-plans from phase 1's actual outcome.

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | ~~Where the Contract lives~~ | **resolved** — `docs/contracts/v1.md` beside an unversioned `docs/contracts/README.md`. See Big decisions. |
| 2 | ~~What stops a future rule from being published without a check~~ | **resolved** — nothing does, by design. The Contract reports; it never requires. See Big decisions. |
| 3 | ~~Which tag name survives~~ | **resolved** — `[judgment]`. See Big decisions. |
| 4 | ~~Whether it gets a skill~~ | **resolved** — not until writing one by hand hurts. |

## Complications found in the code, not addressed by the brief

1. **The extraction is consumer-facing whether or not we want it to be.** Project mode
   *copies* `templates/docs/briefs/README.md` into every target (`install.sh:551`, via
   `place_file`); machine mode *symlinks* it to `$CLAUDE_HOME/briefs/README.template.md`
   (`install.sh:391`), which is what `init-briefs` reads. Moving the invariants out of that
   README changes what installed projects receive. The brief's non-goal ("not a general
   Contract format for all projects") is in tension with the fact that the shipped README is
   general by construction. Resolve in phase 1 or phase 4 — do not let it be discovered in
   phase 4.

   **Corrected 2026-08-21.** First recorded as project mode symlinking the README into every
   target, with `:337`/`:361` as the machine-mode links. Both halves were wrong: `:391` *is*
   the machine-mode link, while `:337` is its source preflight and `:361` an `echo`
   describing it. The correction changes the blast radius, which is why it is worth the
   space. A symlink would propagate to every installed project on `git pull`; a copy is
   forward-only, so existing projects keep what they were onboarded with until someone
   re-runs with `--force`. The copy-not-link pinning rule is intact. The retroactive surface
   is one symlink per *machine*, not one per project — smaller than recorded, and it lands on
   `init-briefs` rather than on installed repos.
2. **`review-pr`'s tags are read from *other* projects' documents.** It gates on `[defect]`/`[judgment]` in a target project's `docs/design/visual-language.md` §9. A hard rename breaks any project whose design doc uses the old tag. Phase 5 likely needs accept-both with a deprecation, not a rename.
3. **`templates/process-rules.md` stays unchecked.** The brief names it as the fourth location of present-tense rules but the Change section does not cover it. Its clauses are mostly undecidable ("commit-push-pr is the only path to main"), so this may be a deliberate scope choice — but it is currently a silent one.
4. **A dangling citation, found while resolving open decision 3.** `skills/review-pr/SKILL.md:106`
   says the Big decisions "format and rules" live in `docs/briefs/README.md`. They do not. That
   README names `ledger.md` only as "execution record (added on execution)" and never defines the
   section. The definition is instead spread across `skills/init-briefs/SKILL.md:25`,
   `skills/chronicle/SKILL.md:28,82,117`, and `docs/slides-process-overview.md:112`. This is a
   fifth instance of the brief's thesis and a new *class* of it: invariant 6 forbids dangling
   `Depends on:` references between briefs, but nothing forbids a skill citing a document for a
   format that document does not carry. Candidate clause for the Contract.
5. **The toolkit's process rules govern every project except this one.** `templates/process-rules.md`
   is a template, installed elsewhere and never applied here. That scope is stated nowhere: the
   file reads as governance, sits in a directory that makes it a template, and nothing marks which
   it is. It was misread as binding during this brief's own execution, by a reader who had already
   read the file twice. This is the sharpest instance of the thesis found so far, and it points at
   a Contract clause the brief does not yet have: **the scope of a rule is part of the rule** —
   every clause must say whether it binds this repo, ships to consumers, or both.
6. **Good news, recorded so nobody re-solves it:** `tests/run.sh` globs `test_*.sh` and CI runs `bash tests/run.sh` on every PR. Phase 2 needs no CI wiring.
7. **Complication 1 fired during phase 1, and phase 1 made it worse before improving it.**
   Extracting the invariants out of `docs/briefs/README.md` left
   `templates/docs/briefs/README.md` — the copy that ships — still restating all eight, and
   still using `[advisory]`, the tag retired by open decision 3. For a moment this repository
   read its rules from a Contract while every installed project read a hand-maintained
   restatement with dead vocabulary. Phase 1 took the minimal fix: retire `[advisory]` in the
   shipped copy so the vocabulary is single everywhere. **The restatement itself is left
   standing for phase 4**, which is the phase that ends the hand-sync. Recorded here so
   phase 4 inherits a known state rather than a discovery: consumers do not receive the
   Contract, and whether they should is phase 4's decision, not a detail.

   **Resolved in phase 4.** Consumers receive the Contract and the validator. The template
   copy is deleted, so the restatement that carried the dead tag no longer exists. See Big
   decisions for why linking alone could not work.

## Branches

None cut yet. Brief, ledger, Manifesto edits and the `wip-visibility` draft land first as one
PR off `docs/contract-artifact` via `commit-push-pr`; `phase 1` branches from the updated
`main` as `feature/contract-artifact-extract`.

`start-brief` step 6 says commit the ledger straight to `main`. This was first recorded as a
conflict with `templates/process-rules.md`, which says `commit-push-pr` is the only path to
`main`. **That framing was wrong and is corrected here.** `process-rules.md` is a template: it
ships to other projects via `install.sh` and has never bound this repo. This repo carries no
root `CLAUDE.md`, no root `AGENTS.md` and no `.claude/rules/`; its only self-applied rule is
`.cursor/rules/no-cq-leak.mdc`. At the initial commit the same text lived in
`templates/AGENTS.md` — also a template.

So there was no conflict. Only `start-brief` applied. The work still landed via `commit-push-pr`,
because the author's machine-level working agreement expects review before `main`, and that
remains the right call. Only the stated reason changes.

Consequence for the audit: `383ed5b [#0002] File brief and add MIT license.` went direct to
`main` with real content, not just coordination metadata. Recorded as history, **not** as a
violation — no rule bound this repo at the time, and none binds it now.

## Notes

- The brief's own parked tension (Manifesto says the Contract is *unowed*; the evidence suggests *unbuilt*) is deliberately not resolved here. Revisit after phase 3, when we know what the extraction actually taught.

## Big decisions

**Phase 4 — the copy could not end without shipping the Contract.** 2026-08-21.

The plan was to cut the template README's restatement down to the same Contract link this
repository uses, which would have made the two files identical and the copy removable. That
does not work, and finding out why changed the phase.

The link is relative. `install.sh` placed no `docs/contracts/`, so the link resolved here and
dangled in every target. Worse, `v1.md` carried sentences that are false outside this
repository: that the rules were extracted from `docs/briefs/README.md`, and that
`tests/test_briefs.sh` runs them on every push. Shipping that file verbatim would ship a
document making claims about a tree it is not in. That is the overclaim this brief names as
the defect class, committed by the artifact built to prevent it.

So the fork was real: ship the Contract properly, or narrow scope from `both` to `repo` and
tell consumers to write their own. We ship. `install.sh` now places `docs/contracts/` and
`tools/validate-briefs.sh` in every target, and the template copy is deleted — a target
receives the files this repository lives by, not copies of them.

**Scope `both` is now true in both halves.** Phase 2 recorded that the rules ship and the
enforcement does not. That sentence is retired rather than restated: the check ships with the
rules, so a `checked:` path resolves in the target. `ship_the_installed_contract_names_a_check_that_exists`
is the consumer-side mirror of the test that guards this repository.

**Making the prose true anywhere cost three sentences.** The extraction-provenance paragraph
left `v1.md` — it is a fact about this repository's history, and it already lives in this
ledger and the brief. Two anecdotes in `docs/contracts/README.md` named paths that do not
exist in a target (`templates/process-rules.md`, `skills/review-pr/SKILL.md`); both now state
the lesson without the local path. A document that ships has to be readable from where it
lands, which is a constraint the phase-1 version never had to meet.

**A second instance of the same hand-sync, found while doing this.** The two `_drafts`
READMEs were byte-identical, and the two briefs READMEs shared 68 byte-identical lines. The
ledger recorded one copy; there were two. Both are gone by the same mechanism.

**A gap this phase did not close, recorded rather than discovered later.** Machine mode links
only the briefs README into `$CLAUDE_HOME`, and `init-briefs` copies that file into a repo
adopting the convention. That README now links the Contract. A repository set up by
`init-briefs` alone, with no project-mode install, therefore gets a briefs README whose
Contract link resolves to nothing. Project mode is unaffected. The fix is either to link
`docs/contracts/` at machine level and teach `init-briefs` to copy it, or to accept that
`init-briefs` is only ever run inside a project the installer has already touched. Not
decided here.

**A check may not be a prompt.** 2026-08-21. Asked directly during phase 2 whether the
validator could be a `validate-contract` skill.

It could be written. It must not be cited. The Contract's `checked: <path>` field means a
program decides the clause, which is the whole reason the brief asks for the path to be
named. Point that path at a skill and the strongest claim the document makes reduces to *a
language model read the briefs and thought they looked fine* — non-deterministic,
unauditable, and a different answer on a different day. That is overclaiming a validator's
coverage, which the brief names as the defect class the Contract exists to prevent, committed
by the artifact built to prevent it.

Open decision 4 already said no skill until writing one by hand hurts. This is the sharper
form of the same answer and it is not about earliness: **no amount of pain makes a prompt a
check.** A skill could still be useful for *authoring* a Contract. It can never appear after
`checked:`.

The question did surface a real generic validator, recorded so it is not lost. Checking a
Contract's own hygiene — every clause carries an id, a tag, a scope and a checking state; ids
are unique and never reused; every named check resolves — is fully mechanical and needs no
model. That is phase 3's territory and the piece that would generalise to a second Contract.
Phase 2 built the last of those three because phase 2 is what created the first named path.

**A validator run only against a compliant tree proves nothing.** 2026-08-21.

`tools/validate-briefs.sh` goes green against `docs/briefs/` and would go green identically
with every check replaced by `return 0`. So the self-check is not the test. Each clause has a
fixture that violates it, and the suite was verified by neutering the `defect` reporter,
which failed eleven tests. Recorded because this is the failure `review-pr` calls
passing-but-hollow, and a validator is the one place where shipping it would be worst: the
document would then name a check that exists and does nothing, which is more misleading than
naming no check at all.

**The validator is a standalone script, not a test function.** 2026-08-21. The ledger planned
`tests/test_briefs.sh` alone; the brief separately called for a portable script with CI as a
thin trigger. The brief won, for a reason the plan could not see: v1 labels every clause scope
`both`, and a check that cannot leave this repository makes that label harder to defend. As a
script taking a briefs directory, shipping it in phase 4 is an `install.sh` line rather than a
rewrite.

**What phase 2 could not honestly claim.** The check does not ship. `install.sh` places no
validator, so consumers hold the rules and not the enforcement. Rather than leave that
inferable, `v1.md` states it: the clauses are scope `both`, the enforcement is `repo` only.
This is the third time this brief has found the same shape — a rule whose reach is wider than
its mechanism — and the second time the fix was to say so in the document rather than to
narrow the rule.

**Open decision 1 — where the Contract lives — resolved by drafting it first.** 2026-08-21.

`docs/contracts/v1.md` for the clauses, beside an unversioned `docs/contracts/README.md` for
the legend. Neither of the two options the brief posed survived contact with the artifact.

The brief framed this as side-by-side versions against in-place superseding, and the argument
looked like a trade between answering "what could I rely on in v1" without archaeology and
keeping one obvious current answer. Drafting changed the shape of the question. The clauses
came to roughly 45 lines and the material around them — what a Contract does not do, the tag
legend, the scope legend, the three checking states, what a Contract never contains — to
roughly 80. None of that second part changes when a clause changes.

So self-contained versions would have copied 80 lines of version-independent prose into
`v2.md` and left it hand-synced. That is this brief's own thesis, reproduced by the artifact
built to end it, at the moment of its second version. In-place superseding avoids the copy
but gives up the property the brief wanted.

Splitting the legend out gets both. It is a third option, and it was not visible until there
was a document to measure. Recorded because it is the clearest instance so far of the
Manifesto's claim that the spec gets written from the record rather than ahead of it — the
decision the brief deferred was correctly deferred, and deferring it produced a better answer
than either option on the table.

**Three checking states, not two.** The brief asks the Contract to state which clauses are
checked and which are not. Two states are not enough. A clause nobody has written a check for
and a clause no check can decide are different facts, and reporting them as one claims more
coverage than exists. The document carries `checked: <path>`, `unchecked, reviewed <date>`,
and `not mechanically decidable`. This is what the ledger anticipated when it said phase 3's
meta-report cannot apply uniformly to `[judgment]` clauses. It is carried as a field rather
than in the clause id, because the id must never encode a fact that changes.

**Scope is uniform in v1, and the document says so.** Every clause is `both`. The field
therefore discriminates nothing in this version. It is stated per clause anyway and the
uniformity is stated once, because a field introduced in v2 would read as a change in meaning
rather than a change in coverage — and because leaving a uniform field uncommented invites a
reader to infer a distinction that is not there. Overclaiming, one scale smaller.

**Open decision 3 — which tag name survives — resolved in favour of `[judgment]`.** 2026-08-21.

The brief called this "low stakes." It is not; it is **asymmetric**. Nothing reads either tag
programmatically, so both are consumed by agents and humans. But the consumer counts differ
sharply. `[judgment]` is read by `review-pr` against *other projects'* `docs/design/visual-language.md`
§9 — documents outside this repo, written by other people. `[advisory]` is read by nothing at
all; it appears twice per briefs README, once defining itself and once on invariant 8, and the
validator that would act on it does not exist.

So the fork was which direction to rename. Renaming `[judgment]` to `[advisory]` would pair more
tidily with `[defect]` as two severities, but it would **fail silently**: any design doc still
using `[judgment]` would stop surfacing those rules, and the review would keep printing "Approve"
with a category quietly missing. Drift inside the tool whose job is catching drift.

We went the other way: rename `[advisory]` to `[judgment]`. Change the name nobody reads, not the
one something reads — the Contract's own external-dependence trigger applied to a naming choice.
`[judgment]` also matches the Manifesto's existing vocabulary and names the action required rather
than a severity tier. The cost accepted is that `[defect]`/`[judgment]` is a less parallel pair.

**Consequence for the plan:** `phase 5` is dropped entirely; `review-pr` needs no change.

**Consequence for `phase 3`, caught here rather than late:** the two tags occupy the same slot by
definition, but their instances differ. Invariant 8 (contiguity) is machine-decidable and merely
non-blocking; a design-doc judgment rule may not be checkable at all. So phase 3's meta-check
— every clause has a check citing its id — **cannot apply uniformly to `[judgment]` clauses**.
Some warrant a non-blocking check; others warrant none, because none can exist. Phase 1's
clause-id scheme has to carry that distinction or phase 3 forces a rewrite.

**The path-to-`main` question, resolved differently than first recorded.** 2026-08-21.

First recorded as a precedence decision: two rule documents contradict, `process-rules.md` wins.
That was an error. `process-rules.md` is a template and does not govern this repo, so the two
documents never contradicted — only one of them ever applied.

The real finding is the one underneath: a rule's **scope** is unstated everywhere in this repo.
`templates/process-rules.md` reads as governance and is not; `docs/briefs/README.md` reads as
this repo's own documentation and is *also* shipped as a template, symlinked into targets by
`install.sh:391`. Neither says which it is. That ambiguity is what produced the misreading.

Consequence for `phase 1`: every Contract clause carries its scope — binds this repo, ships to
consumers, or both. This is not an extra field for tidiness. It is the distinction whose absence
caused a careful reader to enforce a rule that did not exist.

Consequence for scope, still open: the path-to-`main` rule is machine-checkable, since a
squash-merge subject carries `(#N)`. The check is a heuristic — a merge commit or a hand-typed
`(#9)` would defeat it — which makes it a good first test of stating *how well* a clause is
checked, not just whether. Whether v1 covers any process rule at all, or only the eight briefs
invariants, is deferred to `phase 1`.

**What the Contract is for, and what it must never do.** 2026-08-21.

A working session on incentives, not mechanism. It changed the shape of the artifact more than
any technical finding so far, so it is recorded in full rather than summarised.

The brief had been treating a Contract as something a system *should* acquire once its rules
settle. That reading is wrong and is the one that turns the artifact into ceremony. **A Contract
is a claim someone stakes, not a stage a system reaches.** Its absence on a surface is play, not
debt. People decide for themselves where they are still imagining and where they are staking a
claim, and when.

Three consequences, all subtractive:

1. **Mechanical hygiene only.** The eight invariants measure slugs, serials and identity lines.
   None of them measures whether the process is working — a repo could pass all eight with a
   hundred briefs that were never wrong about anything. That is *correct*, and the reason is
   Goodhart: trivial rules are safe to check because nobody games a slug regex, while a clause
   reading "every brief must make a falsifiable claim" would produce fake falsifiable claims
   immediately. What the Manifesto actually values gets surfaced and counted, never checked.
2. **Free at the moment of action.** `phase 3` was specified as a gate — no clause without a
   test — and is demoted to a report. Evidence that cost-at-the-moment-of-action loses: three of
   seven commits on `main` bypassed the ceremony, including a brief-filing commit carrying a
   LICENSE. Not carelessness. It was the fast path and nothing stopped it.
3. **Small bites and frequent commits — a preference, at least daily.** This bounds the cost of
   moving fast rather than being discipline for its own sake. Commit quickly; if someone lands
   first you rebase, and a day is a cheap rebase where a fortnight is not. Held as a preference
   and sometimes broken by the person who holds it, which is why it is not written as a rule —
   that would be the overclaim above at a smaller scale. Its known exception: coordination cost
   rises with project size, so a refactor or a release sometimes warrants idling part of the
   team, and there serialising beats optimistic concurrency.

Underneath all of it, one principle: **overclaiming is the defect class.** A clause with unstated
scope, a validator implying coverage it lacks, a document written as if complete — the same error
at three scales. Which also settles how the Manifesto tension gets fixed later: soften the claim,
do not resolve it precisely. Completeness is an abstraction, and all specs are squishy unless you
are willing to pay for proofs, which is almost never the right trade.

**Net effect on the plan:** five phases to three, four open decisions to one.

**Why this brief earned depth no other brief has, and what changes now.** 2026-08-21.

Roughly a hundred briefs across many projects preceded this one, and none went this deep. That
ratio is data, not an apology, and it gets a rule so the next hundred do not inherit this as a
template.

**The category-boundary rule.** Depth like this belongs at *category* boundaries — introducing a
new kind of artifact — not at feature boundaries. A brief that adds behaviour to an existing
category should be short. A brief that adds a category is arguing about what the categories are,
and that argument is cheap now and expensive to reverse later. Candidate for
`docs/briefs/README.md`, where a new team member would look for it.

**Why the economics justify it here.** Brooks's essential-versus-accidental split is the reason.
AI collapses accidental cost — typing, searching, checking citations, auditing history — and
barely touches essential complexity. Coordination is essential. So as the accidental share falls,
coordination grows as a *fraction* of the total: Brooks gets more relevant, not less. Brief,
Ledger and Chronicle serve the author and successors who read the history. The Contract is the
only one written for people who will not, which makes it the only artifact whose cost scales like
n(n-1)/2 rather than n. Getting it wrong is paid by every consumer, silently, forever.

**A premise is about to change.** The brief and the Manifesto both rest on "nobody depends on this
repository yet." A small team is being introduced to the toolkit shortly, and the author is
deliberately dogfooding the conditions that break it: working across multiple machines and *not*
committing conveniently, to observe the real failure modes before other people meet them. That is
a designed experiment, recorded as one.

Two consequences. The Contract's external-dependence trigger is about to fire for real, which
moves the parked *unowed*-versus-*unbuilt* tension from theoretical to live. And
`_drafts/wip-visibility.md` gets more relevant than its narrowing implied: multi-machine work with
deliberately inconvenient commits is precisely the invisible-WIP case. Its narrowed trigger still
holds — poll only for expensive-to-unwind claims — but the git-visible half is worth having sooner.
