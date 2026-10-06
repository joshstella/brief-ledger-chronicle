---
name: blc-prune-stale-branches
description: >-
  Find local branches whose work the trunk already has, and delete the ones a person confirms.
  Use when the user asks to blc-prune-stale-branches, or to clean up, prune or tidy branches.
---

# blc-prune-stale-branches

Run `tools/stale-branches.sh`, show what it proved, ask, and then let the script delete.

The classification and the deletion both live in the script, deliberately — a script can be
asserted by the test suite and an instruction to an agent cannot. This is the only irreversible
thing the toolkit does, so none of it is written here as a rule for you to follow. This file
owns the conversation and owns no logic.

## Steps

1. **Fetch first.** `git fetch` (or `git fetch origin`). Two of the three tests compare against
   the trunk, so a trunk that is behind proves fewer branches than it should. The script does
   not fetch: it makes no network call, and this run has a person behind it.
2. **Run it.** `bash tools/stale-branches.sh`.
   - If the script is missing, this project has the skill without the toolkit's tools. Say so
     and stop. Do not work out which branches are stale by reading git history — that is the
     judgement this exists to replace.
3. **Show the output as it stands.** Do not summarise it and do not re-word it. In particular
   do not call an unproven branch "merged": a weaker rule once passed three branches it had not
   proved, and the deletion came before anybody looked.
4. **Say which tests did not run, before asking.** The script prints this. The `pr` test needs
   a forge and is the only one that can prove a squash merge, which is how this toolkit merges.
   Without it a person is deciding on two tests, and they should know that when they decide.
5. **Ask which branches to delete.** Offer the proven ones. Never offer a branch under "Not
   proven" — if the person wants one gone anyway, they can run `git branch -D` themselves, and
   that should be their own act rather than yours.
6. **Delete what they named.** `bash tools/stale-branches.sh --delete <branch>...`
   - The script proves each branch again before removing it, because a branch can gain a commit
     between the report and this command.
   - **Read the output, not the exit code.** A refusal makes the run exit non-zero even when
     other branches were deleted, so the exit status cannot tell "nothing happened" from "three
     deleted, one refused". Every line says which.
7. **Report what happened**, including each refusal and the reason the script gave for it.

## What the saved tips are, and are not

Each deleted tip is kept at `refs/blc/pruned/<name>`, so the commits stay reachable past
`git gc`. This is insurance against a bug in the prover, not against lost work: a proven-stale
branch is in the trunk by definition, so there is nothing to recover.

Nothing removes those refs. `git for-each-ref refs/blc/pruned/` lists them, and
`git update-ref -d <ref>` removes one. Say this when you report, so the person knows the
repository is accumulating something.

## Scope

Local branches only. A remote branch is the same problem with a larger cost, because the
deletion reaches every clone, and it is not in this skill.
