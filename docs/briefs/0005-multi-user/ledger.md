# Ledger — #0005 Closing the single-writer holes
`blc/1 #0005 in-progress 1:in-progress(brief/0005-phase-1-state-assumptions,PR#26) 2:in-progress(brief/0005-phase-1-state-assumptions,PR#26) 3:in-progress(brief/0005-phase-1-state-assumptions,PR#26) 4:skipped`

**Brief:** `docs/briefs/0005-multi-user/brief.md`
**Status:** in-progress (`brief/0005-phase-1-state-assumptions`, PR#26)
**Date:** 2026-08-25

## Phase sequence

| id | status | what it does |
|---|---|---|
| `phase 1 — state the assumptions` | in-progress (`brief/0005-phase-1-state-assumptions`, PR#26) | Write each of the three single-writer assumptions where a reader meets them: ledger write-ownership and the clobber hole in `docs/briefs/README.md` (Known limitations), and a sharpening of the Contract's concurrent-filing entry to say what the local collision guard does and does not cover. Prose only — no clause, no check. |
| `phase 2 — the clobber guard` | in-progress (`brief/0005-phase-1-state-assumptions`, PR#26) | Make `start-brief` refuse to overwrite any ledger it did not just create, not only an `in-progress` one. Instruction only: open decision 4 resolved as "label it so." |
| `phase 3 — ledger write-ownership` | in-progress (`brief/0005-phase-1-state-assumptions`, PR#26) | State in `docs/briefs/README.md`: one owner per serial, one ledger file, commit-before-branch for that owner's other machines. Not a Contract clause. Open decisions 1 and 2 resolved. |
| `phase 4 — remote-aware allocation` | skipped | Leave the race. Second merge renumbers. Fetch-then-allocate does not close TOCTOU. A lock at filing is a coordination step this brief rejected. Open decision 3. |

## Dependency structure

- **Phase 1 comes first by the repo's ordering rule, not by technical dependency.** This
  project runs prose, then clause, then check, one direction. Phase 1 is the prose. Phases 2
  to 4 do not need it to have landed to be buildable, but landing them first would invert the
  ordering #0003 established and this brief inherits.
- **Parallel tracks after phase 1: phases 2, 3, and 4.** The brief states they can land in
  any order once phase 1 is in. No strict chain between them.
- **Provisional past open decisions.** Phase 2 landed as skill prose plus an honest
  remaining-hole in the README: the stop is an instruction, not a check. Phase 3 is README
  prose: one owner per serial, one file. Not Contract v2. Phase 4 is skipped. See Big
  decisions.

Phase 2 is stacked on this branch at the user's request, before phase 1 merged. That
inverts `next-brief-phase`'s "confirm the previous phase landed" step on purpose.

## Open decisions

Carried from the brief, with what each blocks.

| # | decision | blocks |
|---|---|---|
| 1 | ~~Does the ledger stay one file per brief?~~ | **resolved** — one file. See Big decisions |
| 2 | ~~Does write-ownership earn a clause?~~ | **resolved** — not while it is a team convention. See Big decisions |
| 3 | ~~What does phase 4 consult?~~ | **resolved** — nothing extra; renumber on collision. See Big decisions |
| 4 | ~~How is a guard inside a skill verified at all?~~ | **resolved** — it is not. See Big decisions |
| 5 | ~~Does phase 2's guard need an escape hatch (`--force`)?~~ | **resolved** — confirmation, not a flag. See Big decisions |

## Complications found in the code, not addressed by the brief

1. **`start-brief` guarded only `in-progress`.** Complication 8 from #0004. **Addressed in
   phase 2 as an instruction**, not as a check. A `pending` ledger now trips the same stop.
   The remaining hole is that nothing verifies the agent followed it.

2. **Every check in this repo applies to shell, not skills.** `tests/test_hosts.sh:8` and
   `tests/test_machine_mode.sh:23` assert `start-brief` is installed, not that it behaves.
   The same gap applies to `create-brief`. Phase 4 will not add a remote-aware allocator,
   so that skill stays an instruction too. **Not closed.**

3. **`docs/briefs/README.md` had no stated ownership rule.** Phase 1 named the hole.
   **Phase 3 states the convention** under Ledger status: one owner per serial, one file,
   commit-before-branch. Remaining: nothing checks it, and it is not a Contract clause.

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
   one owner per serial, and neither becomes a work queue. `open-briefs.sh` still does not
   walk `Depends on`. That gap is a status problem, not an assignment problem, and it is not
   closed here.

## Branches

| branch | phase | state |
|---|---|---|
| `brief/0005-phase-1-state-assumptions` | phases 1, 2, and 3 | open, PR #26 |

## Big decisions

- **A skill guard is not a check.** Open decision 4. The honest options were: move the
  stop into a program, declare skills advisory, or land the instruction and label it.
  Phase 2 takes the third. `start-brief` now stops on any existing ledger. The README
  Known limitation no longer says the fix is unbuilt. It says the remaining hole is that
  nothing exercises the stop. Claiming this "closes" the clobber would be the same
  overclaim this brief just walked back.

- **Confirmation is the hatch, not `--force`.** Open decision 5. A skill has no flags.
  `--force` would name a switch nobody can pass, and would hand the clobber back to
  anyone who typed it. Restart still requires the user to confirm, which is the path
  `in-progress` already had.

- **One person owns a serial.** Starting place, 2026-08-25. Humans scope each brief to
  one team member. That person runs `start-brief` and the later phases. `Author` stays
  who filed. Those can differ. Two people on two phases of one brief is out of scope
  until this is relaxed. Open decision 1 follows: the ledger stays one file. Splitting
  files was a cost paid for concurrent phase writers this team is not using.

- **Ownership is not a Contract clause.** Open decision 2. A clause is a promise to
  people who were told they can rely on it. A team convention is README prose. Phase 3
  stated the convention under Ledger status. It did not open v2.

- **Leave the serial race. Renumber the loser.** Open decision 3. Fetch-then-allocate
  reads `origin/main` and still loses if both filers read before either folder is on the
  remote. A real close is a reservation push at filing, which is a gate at the moment of
  action. Recovery: first onto `main` keeps the number. The other branch renames the
  folder, the identity line, inbound `Depends on`, the ledger status line, and the PR
  title before it merges. Cost is real. Frequency should be low. Phase 4 is skipped.
