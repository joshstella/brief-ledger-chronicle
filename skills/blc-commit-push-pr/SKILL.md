---
name: blc-commit-push-pr
description: >-
  Stage, review, commit, push, and open a PR (a merge request on GitLab). Use when the user asks to blc-commit-push-pr or to commit and open a pull or merge request.
---

# blc-commit-push-pr

Stage changed files, review them **before anything leaves the machine**, and only commit + push + open a PR if the review passes.
The review is a gate, not a formality: a `Request changes` verdict stops the chain before the commit. Nothing reaches the remote unreviewed.
Steps:
0. **Preflight — stop here if either check fails:**
   - From the repository root, run `bash tools/detect-forge.sh`. It prints `github` or `gitlab`, and it exits 0 only when exactly one of `gh` and `glab` is logged in to the remote's host. If it exits non-zero, stop: show the user the reason it printed, and tell them to install and log in to the CLI for their forge (`gh auth login` or `glab auth login`). Do not choose a forge yourself — a CLI that answers for the wrong host opens nothing, or opens it in the wrong place. If `tools/detect-forge.sh` does not exist, the toolkit is not installed in this repository: stop and say so.
   - Use that forge's commands from the table below for every step that talks to the forge. On GitLab a PR is a merge request (MR), numbered `!N`.
   - Run `git branch --show-current`. If it is `main` or `master`, stop and tell the user a PR cannot be created from the default branch — they should create a feature branch first (`git checkout -b <name>`).

   | Step | `github` | `gitlab` |
   |---|---|---|
   | Open (7) | `gh pr create --title "<t>" --body "<body>"` | `glab mr create --title "<t>" --description "<body>" --yes` |
   | Checks (9) | `gh pr checks <n>` | `glab ci get --merge-request <n> -F json --jq .status` |
   | Merge (9) | `gh pr merge <n> <method-flag>` | `glab mr merge <n> <method-flag> --auto-merge=false --yes` |
   | Merge methods (9) | `gh repo view --json viewerDefaultMergeMethod,squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed` | `glab repo view -F json --jq '{merge_method, squash_option}'` |
   | Failed jobs (9) | `gh run view <run-id> --log-failed` | `glab ci get --merge-request <n> --status failed --with-job-details`, then `glab ci trace <job-id>` |

   On GitLab, ask about the merge request's pipeline, not the branch's: a project that runs pipelines only for merge requests has none on the branch. `glab mr merge` sets auto-merge by default when a pipeline is running, so `--auto-merge=false` makes it merge now or fail.

1. Run `git status` and `git diff` to understand what changed.
2. Run `git log -5 --oneline` to match the repo's commit message style.
3. Stage the relevant files (prefer specific file names over `git add -A` — exclude anything that looks like secrets, generated output, or build artefacts).
4. **Review gate — before commit, before push.** Invoke `blc-review-pr --staged` explicitly by name on the staged diff. Wait for its verdict.
   - **Request changes** → STOP. Do not commit. Do not push. Surface the findings to the user and end the chain. The files stay staged; the user fixes, re-stages, and re-runs this command. (If the user prefers, they can ask you to fix the findings and re-run the gate — but do not auto-fix and self-clear without being asked; that defeats the gate.)
   - **Approve** or **Approve with suggestions** → continue. Carry any suggestions into the final response so the user sees them even though they didn't block.
5. Write a commit message that captures the *why*, not just the what. One concise subject line; add a short body if the change needs context. Run the subject and body through the `blc-ste-writing` skill (STE-flavored mode) before committing. Then commit.
   - **Attribute yourself, and only if your host has not already done it.** Hosts differ: some add a `Co-authored-by` line of their own and some add nothing. Check what the commit will carry. If no agent is credited, add one line naming the agent you actually are. Never write a fixed agent name into this file — it ships to every host unchanged, so a name written here credits the wrong agent everywhere else, and lands beside the host's own line where there is one (#0026).
6. Push to the current branch (with `-u origin <branch>` if the branch has no upstream yet).
7. Create the PR with the forge's open command. Pass the body via HEREDOC so formatting is preserved.
   - **Title** under 70 characters. If this work executes a brief, prefix the title with the brief's serial in brackets: `[#NNNN] <summary>`. Derive `NNNN` from the active brief — the branch name if it leads with a four-digit serial, otherwise the `docs/blc/briefs/NNNN-slug/` folder being executed. For ad-hoc work not tied to a brief, omit the prefix and title as usual. (The title reaches `main` whatever the trunk's merge method is — as the commit subject where the merge squashes, inside the merge commit's message where it does not — so `[#NNNN]` lands in the permanent history and the work traces back to the brief that specified it. Anything reading those serials back out has to read the whole message, not the subject.)
   The body must include:
   - `## Summary` — 2–4 bullets.
   - `## Test plan` — how it was/should be verified, naming the tests added. If the change is genuinely test-exempt (pure config, generated boilerplate), write "test-exempt because…" here instead. This line is the record `blc-review-pr` checks — a silent absence of tests reads as a missing-tests block.
   - `## Brief` — the governing brief and phase this work came from, as serial + path: `#NNNN — docs/blc/briefs/NNNN-slug/brief.md — phase <N>`. Write `none` if this change isn't from a brief. This line is what lets `blc-review-pr` find the intent to check against later.
   Run the Summary and Test plan bullets through the `blc-ste-writing` skill (STE-flavored mode) before opening the PR — the Brief line and title stay as specified above (identifiers, not prose).
8. Return the PR URL, plus the review verdict and any carried-forward suggestions, in the same response.
9. **If asked to wait for CI and merge once green** (now, or in a later message on the same PR): don't poll manually with repeated sleeps or re-invocations. Use the Monitor tool to run a background poll loop against the forge's checks command that emits a line on each check's status change and exits once every check reports a terminal (non-pending) status.
   When the run lands:
   - **All required checks passed** → run the forge's merge-methods command, read `<method-flag>` from its answer, then merge. **Never write a merge method into this file.** A repository merges the way its own settings say, and a flag written here ships to every repository unchanged — where it does not merely fail, it is accepted and quietly reshapes a history that was not yours to reshape (#0030).

     | forge | read | `<method-flag>` |
     |---|---|---|
     | `github` | `viewerDefaultMergeMethod` | `SQUASH` → `--squash`; `MERGE` → `--merge`; `REBASE` → `--rebase` |
     | `gitlab` | `squash_option` is `always` or `default_on` | `--squash` |
     | `gitlab` | otherwise, `merge_method` is `rebase_merge` or `ff` | `--rebase` |
     | `gitlab` | otherwise | nothing — a merge commit is GitLab's default |

     On GitHub the `*Allowed` fields say what is permitted, not what to use: a repository can allow all three. `viewerDefaultMergeMethod` is the one that answers the question. If it names a method the matching `*Allowed` field denies, stop and ask — the two disagreeing is a repository setting a person should look at, not something to work around.

     On GitLab, `default_off` means squash is *permitted and unticked*, so passing `--squash` there is accepted and squashes. That is why the method is read rather than assumed.
   - **Failed** → fetch the failed jobs' logs with the forge's failed-jobs command and get the actual list of failing test/job names. If a known pre-existing baseline of acceptable failures has already been established earlier in this conversation (e.g. confirmed against main's own CI), compare the new failure set against it by name — only treat it as "the known flake" if the set is identical. Never assume a failure is pre-existing/flaky without checking; a new failure needs real diagnosis, not dismissal.
   If the outcome is something the user would want to know even if they've stepped away, follow up with PushNotification (under 200 chars, lead with the actionable fact — e.g. "PR #122 merged" or "PR #122: 2 new test failures, not the known flake") rather than leaving it sitting silently in chat.
Do not amend existing commits. If the pre-commit hook fails, fix the issue and create a new commit.
