---
name: commit-push-pr
description: >-
  Stage, review, commit, push, and open a PR. Use when the user asks to commit-push-pr or to commit and open a pull request.
---

# commit-push-pr

Stage changed files, review them **before anything leaves the machine**, and only commit + push + open a PR if the review passes.
The review is a gate, not a formality: a `Request changes` verdict stops the chain before the commit. Nothing reaches the remote unreviewed.
Steps:
0. **Preflight — stop here if either check fails:**
   - Run `gh auth status` to confirm gh is installed and authenticated. If it fails or shows no active account, stop and tell the user to run `brew install gh && gh auth login` before continuing.
   - Run `git branch --show-current`. If it is `main` or `master`, stop and tell the user a PR cannot be created from the default branch — they should create a feature branch first (`git checkout -b <name>`).
1. Run `git status` and `git diff` to understand what changed.
2. Run `git log -5 --oneline` to match the repo's commit message style.
3. Stage the relevant files (prefer specific file names over `git add -A` — exclude anything that looks like secrets, generated output, or build artefacts).
4. **Review gate — before commit, before push.** Invoke `review-pr --staged` explicitly by name on the staged diff. Wait for its verdict.
   - **Request changes** → STOP. Do not commit. Do not push. Surface the findings to the user and end the chain. The files stay staged; the user fixes, re-stages, and re-runs this command. (If the user prefers, they can ask you to fix the findings and re-run the gate — but do not auto-fix and self-clear without being asked; that defeats the gate.)
   - **Approve** or **Approve with suggestions** → continue. Carry any suggestions into the final response so the user sees them even though they didn't block.
5. Write a commit message that captures the *why*, not just the what. One concise subject line; add a short body if the change needs context. Run the subject and body through the `ste-writing` skill (STE-flavored mode) before committing. End with:
   `Co-Authored-By: Claude <noreply@anthropic.com>`
   Then commit.
6. Push to the current branch (with `-u origin <branch>` if the branch has no upstream yet).
7. Create a PR with `gh pr create`. Pass the body via HEREDOC so formatting is preserved.
   - **Title** under 70 characters. If this work executes a brief, prefix the title with the brief's serial in brackets: `[#NNNN] <summary>`. Derive `NNNN` from the active brief — the branch name if it leads with a four-digit serial, otherwise the `docs/briefs/NNNN-slug/` folder being executed. For ad-hoc work not tied to a brief, omit the prefix and title as usual. (Because main is squash-merged, the title becomes the commit subject on main, so `[#NNNN]` lands in the permanent history and any commit traces back to the brief that specified it.)
   The body must include:
   - `## Summary` — 2–4 bullets.
   - `## Test plan` — how it was/should be verified, naming the tests added. If the change is genuinely test-exempt (pure config, generated boilerplate), write "test-exempt because…" here instead. This line is the record `review-pr` checks — a silent absence of tests reads as a missing-tests block.
   - `## Brief` — the governing brief and phase this work came from, as serial + path: `#NNNN — docs/briefs/NNNN-slug/brief.md — phase <N>`. Write `none` if this change isn't from a brief. This line is what lets `review-pr` find the intent to check against later.
   Run the Summary and Test plan bullets through the `ste-writing` skill (STE-flavored mode) before opening the PR — the Brief line and title stay as specified above (identifiers, not prose).
8. Return the PR URL, plus the review verdict and any carried-forward suggestions, in the same response.
9. **If asked to wait for CI and merge once green** (now, or in a later message on the same PR): don't poll manually with repeated sleeps or re-invocations. Use the Monitor tool to run a background poll loop against `gh pr checks <number>` that emits a line on each check's status change and exits once every check reports a terminal (non-pending) status.
   When the run lands:
   - **All required checks passed** → merge with `gh pr merge <number> --squash` (confirm this repo's actual default merge method first if unclear — check via `gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`).
   - **Failed** → fetch `gh run view <run-id> --log-failed` and get the actual list of failing test/job names. If a known pre-existing baseline of acceptable failures has already been established earlier in this conversation (e.g. confirmed against main's own CI), compare the new failure set against it by name — only treat it as "the known flake" if the set is identical. Never assume a failure is pre-existing/flaky without checking; a new failure needs real diagnosis, not dismissal.
   If the outcome is something the user would want to know even if they've stepped away, follow up with PushNotification (under 200 chars, lead with the actionable fact — e.g. "PR #122 merged" or "PR #122: 2 new test failures, not the known flake") rather than leaving it sitting silently in chat.
Do not amend existing commits. If the pre-commit hook fails, fix the issue and create a new commit.
