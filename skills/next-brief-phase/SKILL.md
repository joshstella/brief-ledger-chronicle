---
name: next-brief-phase
description: >-
  Continue a multi-phase brief after a phase completes. Use when the user asks for next-brief-phase.
---

# next-brief-phase

Continue an in-progress brief: fold in what the completed phases actually taught, **re-plan the remaining sequence**, and branch the next phase. The companion to `start-brief` — this is the step that keeps a plan from barrelling through its original order after a finding should have changed it.

Usage: next-brief-phase [brief path-or-name]
If no argument is given, use the most recently updated `in-progress` brief ledger.

---

## Steps

1. **Find the ledger.**
   - Primary: if `$ARGUMENTS` names a brief (or no argument given), find the brief's directory under `docs/briefs/` and read `ledger.md` from that directory. This is the source of truth.
   - Fallback: if no repo ledger found, read MEMORY.md and locate the `brief-<kebab>` entry — either by `$ARGUMENTS` or the most recently updated one with status `in-progress`.
   - If none is in progress, say so and point to `start-brief`.

2. **Read the ledger and the brief.** Surface: completed phases and what each recorded as learned or changed; the remaining phase list; recorded open decisions and any resolutions; complications.

3. **Confirm the previous phase actually landed.** Check that its PR is merged (`gh pr view` on the phase branch). If it isn't, say so — a chained next phase depends on it, and planning on top of unmerged work is how branches diverge. Also read the previous phase's bug ledger (`review-<branch>.md`): if it has `open` correctness bugs, they come before new work.

4. **RE-PLAN the remaining phases — this is the point of the command.**
   - Re-read the remaining sequence against what the completed phases *found*, not against the original plan. Did a completed phase resolve an open decision in a way that reorders, splits, merges, or removes a later phase? (The canonical case: a phase that was provisional-pending-a-decision in `start-brief` — its downstream sequence is now either confirmed or rewritten.)
   - If the remaining sequence still holds, say so explicitly. If it changed, present the revised remainder and *why* it changed.

5. **Refresh codebase context.** Re-read the repo `CLAUDE.md` and the files the next phase will touch — the codebase has moved since the brief was initiated.

6. **Present the next phase:** its stable id, the files it creates/modifies, what it accomplishes, and any open decision that must resolve before it can start (block it if unresolved).

7. **Branch the next phase.** `feature/<kebab>-<phaseN>`, derived from the phase's stable id. For parallel tracks, note which can branch independently right now. Wait for confirmation before creating the branch or writing code.

8. **Update the ledger — both places.**
   - Mark the just-finished phase `done`; record what it taught and any sequence change it caused.
   - Set the next phase `in-progress`; record its branch.
   - Status stays `in-progress`, or becomes `completed` if this was the last phase.
   - Write the updated ledger to `docs/briefs/<name>/ledger.md` in the repo (the primary source of truth) and commit it to the current branch.
   - Update the memory file and MEMORY.md in place (secondary, for fast in-session lookup).
