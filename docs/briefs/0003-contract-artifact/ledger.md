# Ledger — #0003 A fourth artifact: the Contract

**Brief:** `docs/briefs/0003-contract-artifact/brief.md`
**Status:** initiated
**Date:** 2026-08-21

## Phase sequence

| id | status | what it does |
|---|---|---|
| `phase 1 — extract the contract` | pending | Create the Contract at the decided path, carrying the eight invariants as clauses with stable ids. Resolve open decisions 1 and 3. Point `docs/briefs/README.md` at it instead of restating. Add the checked-set sentence (which at this point honestly reads *nothing here is checked yet*) and the hand-stamped review date for unchecked clauses. |
| `phase 2 — validator` | pending | `tests/test_briefs.sh` implementing clauses 1–8, each check citing its clause id. Update the Contract's checked-set sentence to name the path. |
| `phase 3 — report unchecked clauses` | pending | **Demoted from a gate to a report.** The Contract lists which clauses have checks and which do not. It never requires one. Originally specified as a meta-check blocking any clause without a test; that is a cost at the moment of action and would stop you adding a rule until you had written its test. |
| `phase 4 — de-duplicate the readmes` | pending | End the hand-sync between `docs/briefs/README.md` and `templates/docs/briefs/README.md` (93 vs 112 lines, already diverged). Must not break `install.sh:391`. |
| ~~`phase 5 — reconcile review-pr tags`~~ | **dropped** | Removed once open decision 3 resolved in favour of `[judgment]`. `review-pr` already uses the surviving name, so there is nothing to reconcile. See Big decisions. |

## Dependency structure

- **Strict chain:** `phase 1 → phase 2 → phase 3`. Phase 2 needs clause ids to cite; phase 3 reports on what phase 2 built. Phase 3 is small now that it only reports — fold it into phase 2 if it does not earn its own review.
- **Parallel track after phase 1:** `phase 4` only, independent of the chain. (`phase 5` dropped — see Big decisions.)
- **Provisional past phase 1.** Phase 1 chooses the Contract's path *and its clause-id scheme*. The id scheme cannot be retrofitted — phase 3's meta-check keys on it — so phase 1 must be designed with phase 3 in mind, or phase 3 forces a rewrite of the Contract. `/next-brief-phase` re-plans from phase 1's actual outcome.

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | Where the Contract lives; one file superseded in place vs `v1.md`/`v2.md` side by side | `phase 1` — nothing can reference it until the path exists |
| 2 | ~~What stops a future rule from being published without a check~~ | **resolved** — nothing does, by design. The Contract reports; it never requires. See Big decisions. |
| 3 | ~~Which tag name survives~~ | **resolved** — `[judgment]`. See Big decisions. |
| 4 | ~~Whether it gets a skill~~ | **resolved** — not until writing one by hand hurts. |

## Complications found in the code, not addressed by the brief

1. **The extraction is consumer-facing whether or not we want it to be.** `install.sh:391` symlinks `templates/docs/briefs/README.md` into every target project, and machine mode links it at `:337`/`:361`. Moving the invariants out of that README changes what installed projects receive. The brief's non-goal ("not a general Contract format for all projects") is in tension with the fact that the shipped README is general by construction. Resolve in phase 1 or phase 4 — do not let it be discovered in phase 4.
2. **`review-pr`'s tags are read from *other* projects' documents.** It gates on `[defect]`/`[judgment]` in a target project's `docs/design/visual-language.md` §9. A hard rename breaks any project whose design doc uses the old tag. Phase 5 likely needs accept-both with a deprecation, not a rename.
3. **`templates/process-rules.md` stays unchecked.** The brief names it as the fourth location of present-tense rules but the Change section does not cover it. Its clauses are mostly undecidable ("commit-push-pr is the only path to main"), so this may be a deliberate scope choice — but it is currently a silent one.
5. **A dangling citation, found while resolving open decision 3.** `skills/review-pr/SKILL.md:106`
   says the Big decisions "format and rules" live in `docs/briefs/README.md`. They do not. That
   README names `ledger.md` only as "execution record (added on execution)" and never defines the
   section. The definition is instead spread across `skills/init-briefs/SKILL.md:25`,
   `skills/chronicle/SKILL.md:28,82,117`, and `docs/slides-process-overview.md:112`. This is a
   fifth instance of the brief's thesis and a new *class* of it: invariant 6 forbids dangling
   `Depends on:` references between briefs, but nothing forbids a skill citing a document for a
   format that document does not carry. Candidate clause for the Contract.
6. **The toolkit's process rules govern every project except this one.** `templates/process-rules.md`
   is a template, installed elsewhere and never applied here. That scope is stated nowhere: the
   file reads as governance, sits in a directory that makes it a template, and nothing marks which
   it is. It was misread as binding during this brief's own execution, by a reader who had already
   read the file twice. This is the sharpest instance of the thesis found so far, and it points at
   a Contract clause the brief does not yet have: **the scope of a rule is part of the rule** —
   every clause must say whether it binds this repo, ships to consumers, or both.
7. **Good news, recorded so nobody re-solves it:** `tests/run.sh` globs `test_*.sh` and CI runs `bash tests/run.sh` on every PR. Phase 2 needs no CI wiring.

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
3. **Small bites and frequent commits, at least daily.** This is what bounds the cost of moving
   fast rather than discipline for its own sake. Commit quickly; if someone lands first you
   rebase, and a day is a cheap rebase where a fortnight is not. Encouraged and surfaced, never
   gated — counting commits would only produce empty ones.

Underneath all of it, one principle: **overclaiming is the defect class.** A clause with unstated
scope, a validator implying coverage it lacks, a document written as if complete — the same error
at three scales. Which also settles how the Manifesto tension gets fixed later: soften the claim,
do not resolve it precisely. Completeness is an abstraction, and all specs are squishy unless you
are willing to pay for proofs, which is almost never the right trade.

**Net effect on the plan:** five phases to three, four open decisions to one.
