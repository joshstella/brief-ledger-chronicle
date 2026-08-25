# Ledger — #0005 Closing the single-writer holes
`blc/1 #0005 pending 1:pending 2:pending 3:pending 4:pending`

**Brief:** `docs/briefs/0005-multi-user/brief.md`
**Status:** pending
**Date:** 2026-08-25

## Phase sequence

| id | status | what it does |
|---|---|---|
| `phase 1 — state the assumptions` | pending | Write each of the three single-writer assumptions where a reader meets them: ledger write-ownership and the clobber hole in `docs/briefs/README.md` (Known limitations), and a sharpening of the Contract's concurrent-filing entry to say what the local collision guard does and does not cover. Prose only — no clause, no check. |
| `phase 2 — the clobber guard` | pending | Make `start-brief` refuse to overwrite any ledger it did not just create, not only an `in-progress` one. Shape depends on open decision 4 — a markdown prompt may not be able to "close" anything. |
| `phase 3 — ledger write-ownership` | pending | Promote the commit-before-branch convention from one step in `start-brief` to a stated rule with an owner: one executor per phase. Decide whether it earns a Contract clause. Blocked by open decisions 1 and 2. |
| `phase 4 — remote-aware allocation` | pending | Allocate the serial against the pushed remote — the fix the Contract has named since v1. Blocked by open decision 3. |

## Dependency structure

- **Phase 1 comes first by the repo's ordering rule, not by technical dependency.** This
  project runs prose, then clause, then check, one direction. Phase 1 is the prose. Phases 2
  to 4 do not need it to have landed to be buildable, but landing them first would invert the
  ordering #0003 established and this brief inherits.
- **Parallel tracks after phase 1: phases 2, 3, and 4.** The brief states they can land in
  any order once phase 1 is in. No strict chain between them.
- **Provisional past open decisions.** Phase 2's deliverable may be prose-only if open
  decision 4 concludes a skill guard cannot be verified. Phase 3's deliverable may stop at
  README prose if open decisions 1–2 conclude Contract v2 is too much machinery. Phase 4's
  shape follows open decision 3's fetch/degrade answer. `/next-brief-phase` re-plans any
  phase whose open decisions resolve differently than assumed here.

Suggested default order after phase 1: phase 2 first (already nearly fired), then phase 3,
then phase 4 — but that is convenience, not a dependency.

## Open decisions

Carried from the brief, with what each blocks.

| # | decision | blocks |
|---|---|---|
| 1 | Does the ledger stay one file per brief? | phase 3 |
| 2 | Does write-ownership earn a clause, and in which version? | phase 3 |
| 3 | What does phase 4 consult, and what does it cost? | phase 4 |
| 4 | How is a guard inside a skill verified at all? | phase 2 — may reshape it entirely |
| 5 | Does phase 2's guard need an escape hatch (`--force`)? | phase 2 implementation detail |

## Complications found in the code, not addressed by the brief

1. **`start-brief:26` guards only `in-progress`.** This is complication 8 from #0004's
   ledger, now the subject of phase 2. A ledger at `pending` is unguarded today.

2. **Every check in this repo applies to shell, not skills.** `tests/test_hosts.sh:8` and
   `tests/test_machine_mode.sh:23` assert `start-brief` is installed, not that it behaves.
   The same gap applies to `create-brief`, which phase 4 would modify. Open decision 4 is
   therefore load-bearing for phases 2 and 4, not only phase 2.

3. **`docs/briefs/README.md` has no Known limitation for single-writer ledger assumptions.**
   It has entries for writers outside the pipeline and for the archive/inbox hole (#0004).
   Phase 1 adds a third entry (or extends an existing one — decision at execution time).

4. **The Contract's concurrent-filing paragraph does not mention the local collision guard.**
   `docs/contracts/v1.md:87-93` describes the cross-machine race only. Phase 1 sharpens it
   per the brief; the mechanism lives at `skills/create-brief/SKILL.md:35`.

5. **Brief #0005 was filed but not yet on `main` when this ledger was written.** The filing
   commit and this ledger commit are paired deliberately — a ledger for a brief that does not
   exist on the trunk would be invisible to the same machines this brief is about to serve.

6. **Assignment will be specific, not a pile.** Found in use after filing. A consuming
   project is splitting work with a Child Briefs table on the parent and `Depends on` on the
   child. Serials stay flat. File reserves, start claims. `Author` is the filer. The
   executor is whoever runs `start-brief`. Human diligence is accepted. This does not add a
   phase. It constrains phases 2 and 3: the clobber guard is the claim, write-ownership is
   one executor per phase, and neither becomes a work queue. `open-briefs.sh` still does not
   walk `Depends on`. That gap is a status problem, not an assignment problem, and it is not
   closed here.

## Branches

None yet. Phase 1 awaits confirmation: `brief/0005-phase-1-state-assumptions`.
