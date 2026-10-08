---
name: blc-close-brief
description: >-
  Close a brief whose last phase has merged: mark it done, record the date BRIEFS-11 asks for, write what the work taught, and open the closeout PR. Use when the user asks to blc-close-brief, or to close or finish a brief. Continuing to a further phase is blc-next-brief-phase.
---

# blc-close-brief

Close an `in-progress` brief whose final phase has merged. Mark the brief `done`, record
when it closed, write what the record shows that the brief did not predict, and carry all
of that to `main` on `brief/<serial>-closeout`.

Usage: blc-close-brief [brief path-or-name]
If no argument is given, use the most recently updated `in-progress` brief ledger.

**This is the one command that ends a brief.** The close used to be improvised. Sixteen of
the first thirty-two closed ledgers here carry no date at all, and the closing section had
been written six different ways, because a document described the closeout branch and no
command wrote what went on it.

---

## What a close is for

A ledger is what executing the brief cost. The close is the last chance to write down what
the work taught while the person who learned it is still reading, and it is the only part of
the record written after the outcome is known.

**It is not a summary of the diff.** The PRs already hold that. The close answers a different
question: what does the record show now that the brief did not predict?

**`BRIEFS-11` checks one line of this and nothing else.** A ledger with status `done` must
carry a `**Closed:**` date. The sections below are prose, and no gate reads them — say so
rather than letting a green check imply the rest was verified.

---

## Steps

1. **Find the ledger.** If `$ARGUMENTS` names a brief, read `ledger.md` from its directory
   under `docs/blc/briefs/`. With no argument, use the most recently updated `in-progress`
   ledger. If none is `in-progress`, stop and say so.

2. **Refuse to close a brief that is not finished.** Read the phase table and the status
   line. Every phase must be `done`, `skipped` or `deferred`. If one is `pending` or
   `in-progress`, stop and name it — the next step is `blc-next-brief-phase`, not this.
   A `deferred` phase is a legitimate close; a `pending` one is an unfinished brief.

3. **Confirm the last phase actually landed.** Run `bash tools/detect-forge.sh`; on `github`
   use `gh pr view <branch> --json state`, on `gitlab` `glab mr view <branch> -F json --jq
   .state` (a merge request reads `merged`). If the detector exits non-zero, stop and show
   the user what it printed — do not guess which CLI to ask. Closing over an unmerged phase
   writes a record that `main` does not have.

4. **Read the last phase's bug ledger** (`review-<branch>.md`). Open correctness bugs are
   not closed by closing the brief. Either they are fixed first, or they are named in
   **Open after close** with the reason they were left. Silence is the one option that is
   not available.

5. **Update `main` and cut the branch.** `git checkout main && git pull`, then
   `brief/<serial>-closeout`. The name is reserved and is not a phase — see
   `docs/blc/briefs/README.md`, "Reserved, not a phase". The final phase has no successor
   branch to carry its close, which is the whole reason this branch exists.

6. **Write the close into the ledger.**
   - Mark the final phase `done` with the PR that carried it.
   - `**Status:** done`, and a `**Closed:**` line with today's date. This is what
     `BRIEFS-11` reads. Do not derive it from a merge commit: that is the date a branch
     landed, not the date a person closed the brief, and writing it would make the record
     assert something nobody said.
   - Update the `blc/2` status line in the same edit — brief state and every phase state.
     A status line that disagrees with the phase table is `BRIEFS-9`.
   - Then the prose, in this order. Write only the sections you have something true to put
     in; an empty heading is worse than an absent one, because it reads as a checked box.

     **What shipped.** What a reader gets that they did not have before. Name the phases and
     the PRs. Say which settled decisions held and which the work overturned.

     **What the record shows that the brief did not predict.** The section the close exists
     for. A brief is a hypothesis; this is where it is marked. A brief that predicted
     everything is a brief that was written after the work, and saying so is more useful
     than a tidy ledger.

     **Open after close.** What is left: untested residue, deferred phases, bugs carried
     from step 4, questions the work raised and did not answer. This is not a failure to
     report — a close with nothing open is rare and usually means nobody looked.

     **What this cannot prove.** The limits of the evidence. A skill nothing runs, a guard
     that has never met a real record, a fixture written from a report rather than from the
     code. See `docs/blc/orientation.md`, "A skill guard is not a check".

7. **Clear the declaration.** If `docs/blc/state/<your git user.email>.md` claims this
   brief, remove the entry. The brief is closed, so the claim is now derivable from
   `docs/blc/briefs/` and a declaration that repeats the record is the stale second copy
   the convention exists to avoid. Leave the file if it names other work.

8. **Check the record, then commit.** Run `bash tools/validate-briefs.sh`. `BRIEFS-11` must
   not report this brief — if it does, step 6 did not write the date. Then hand the staged
   diff to `blc-commit-push-pr`, which runs the review gate before the commit.

   The PR needs an explicit test exemption. A closeout that touches only `ledger.md` is
   record, and "test-exempt because this commit changes record only" belongs in its
   `## Test plan`, stated rather than left as a silent gap. A closeout that touches anything
   else is not test-exempt, and the exemption is a sentence someone can disagree with.

## Report

Report the serial, the date written, the PR, and each section you wrote.

Name the sections you left out and why. A close with no **Open after close** is a claim that
nothing is left, and it should be made deliberately rather than by omission.

## What this command does not do

- It does not merge the closeout PR. A person does that.
- It does not close a brief with a `pending` or `in-progress` phase. That is
  `blc-next-brief-phase`.
- It does not write a chronicle. That is `blc-chronicle`, and it reads closed briefs.
- It does not judge whether the work was right. It records what it cost.
