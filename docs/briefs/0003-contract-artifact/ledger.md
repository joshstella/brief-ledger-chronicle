# Ledger — #0003 A fourth artifact: the Contract

**Brief:** `docs/briefs/0003-contract-artifact/brief.md`
**Status:** initiated
**Date:** 2026-08-21

## Phase sequence

| id | status | what it does |
|---|---|---|
| `phase 1 — extract the contract` | pending | Create the Contract at the decided path, carrying the eight invariants as clauses with stable ids. Resolve open decisions 1 and 3. Point `docs/briefs/README.md` at it instead of restating. Add the checked-set sentence (which at this point honestly reads *nothing here is checked yet*) and the hand-stamped review date for unchecked clauses. |
| `phase 2 — validator` | pending | `tests/test_briefs.sh` implementing clauses 1–8, each check citing its clause id. Update the Contract's checked-set sentence to name the path. |
| `phase 3 — clause/check linkage` | pending | The meta-check, both directions: every `[defect]` clause has ≥1 check citing its id, and every check cites a live clause id. This is what stops rule N+1 from being published unchecked. |
| `phase 4 — de-duplicate the readmes` | pending | End the hand-sync between `docs/briefs/README.md` and `templates/docs/briefs/README.md` (93 vs 112 lines, already diverged). Must not break `install.sh:391`. |
| `phase 5 — reconcile review-pr tags` | pending | Apply phase 1's tag decision to `skills/review-pr/SKILL.md`. Small diff, consumer-facing blast radius — kept separate so it is reviewed on its own merits. |

## Dependency structure

- **Strict chain:** `phase 1 → phase 2 → phase 3`. Phase 2 needs clause ids to cite; phase 3 needs checks to link.
- **Parallel tracks after phase 1:** `phase 4` and `phase 5` are independent of the chain and of each other.
- **Provisional past phase 1.** Phase 1 chooses the Contract's path *and its clause-id scheme*. The id scheme cannot be retrofitted — phase 3's meta-check keys on it — so phase 1 must be designed with phase 3 in mind, or phase 3 forces a rewrite of the Contract. `/next-brief-phase` re-plans from phase 1's actual outcome.

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | Where the Contract lives; one file superseded in place vs `v1.md`/`v2.md` side by side | `phase 1` — nothing can reference it until the path exists |
| 2 | What stops a *future* rule from being published without a check | `phase 3` to implement, but constrains `phase 1`'s clause-id design |
| 3 | Which tag name survives, `[advisory]` or `[judgment]` | `phase 1` (the Contract carries tags) and `phase 5` |
| 4 | Whether it gets a skill | nothing — deferred past v1 by the brief |

## Complications found in the code, not addressed by the brief

1. **The extraction is consumer-facing whether or not we want it to be.** `install.sh:391` symlinks `templates/docs/briefs/README.md` into every target project, and machine mode links it at `:337`/`:361`. Moving the invariants out of that README changes what installed projects receive. The brief's non-goal ("not a general Contract format for all projects") is in tension with the fact that the shipped README is general by construction. Resolve in phase 1 or phase 4 — do not let it be discovered in phase 4.
2. **`review-pr`'s tags are read from *other* projects' documents.** It gates on `[defect]`/`[judgment]` in a target project's `docs/design/visual-language.md` §9. A hard rename breaks any project whose design doc uses the old tag. Phase 5 likely needs accept-both with a deprecation, not a rename.
3. **`templates/process-rules.md` stays unchecked.** The brief names it as the fourth location of present-tense rules but the Change section does not cover it. Its clauses are mostly undecidable ("commit-push-pr is the only path to main"), so this may be a deliberate scope choice — but it is currently a silent one.
4. **Good news, recorded so nobody re-solves it:** `tests/run.sh` globs `test_*.sh` and CI runs `bash tests/run.sh` on every PR. Phase 2 needs no CI wiring.

## Branches

None cut yet. Brief, ledger, Manifesto edits and the `wip-visibility` draft land first as one
PR off `docs/contract-artifact` via `commit-push-pr`; `phase 1` branches from the updated
`main` as `feature/contract-artifact-extract`.

`start-brief` step 6 says commit the ledger straight to `main`; `templates/process-rules.md`
says `commit-push-pr` is the only path to `main`. Resolved in favour of `process-rules.md` —
filing a brief about unenforced rules by bypassing one of them would be the wrong opening
move. Recorded because the two documents still contradict each other, and that is a real
finding for this brief rather than a nuisance.

## Notes

- The brief's own parked tension (Manifesto says the Contract is *unowed*; the evidence suggests *unbuilt*) is deliberately not resolved here. Revisit after phase 3, when we know what the extraction actually taught.
