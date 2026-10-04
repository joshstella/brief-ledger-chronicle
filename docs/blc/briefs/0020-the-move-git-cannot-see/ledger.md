# Ledger — #0020 The move git cannot see

`blc/2 #0020 in-progress a:in-progress(brief/0020-a-the-tracked-move)`

**Brief:** `docs/blc/briefs/0020-the-move-git-cannot-see/brief.md`
**Started:** 2026-10-04
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the tracked move | in-progress | `brief/0020-a-the-tracked-move` |

**a — the tracked move.** When an upgrade moves a project file from the old `docs/` layout
under `docs/blc/`, and the target is a git repository and the file is tracked, the installer
moves it with `git mv`. Git then keeps tracking the file at its new path, even when an ignore
rule matches that path, and records the move as a rename. Untracked files, and targets that are
not git repositories, keep `mv`. The change is in Step 3a of `install.sh`. Tests use a target
that is a git repository, which no upgrade test did before: a tracked chronicle that the
toolkit's own rule ignores at its new path, a tracked file that the target's own `.gitignore`
ignores at its new path, an untracked file, and a target that is not a repository. The test for
the tracked chronicle is seen to fail before the fix.

## Dependency structure

One phase. No chain.

## Settled decisions

All three resolved 2026-10-04 by the owner, before planning.

| # | decision | reason |
|---|---|---|
| 1 | **A tracked file moves with `git mv`.** Rejected: refuse before the move, and warn after it. | It is the only option that needs no action from the person, and a warning that is skimmed still loses the file. Verified 2026-10-04: `git mv` onto a path that `.gitignore` matches exits 0, and the file stays tracked as a rename. The cost is accepted: the installer now stages renames in the target's index, which it did not do before. |
| 2 | **The chronicles ignore rule stays.** Rejected: drop it, and decide it in a later phase. | The rule states the toolkit's intent, one committed rendering. Decision 1 protects files that were tracked before the move. A project that wants more chronicles tracked edits its own `.gitignore`. |
| 3 | **Nothing is done for projects already upgraded.** Rejected: a warning on the next install, and a note in the docs. | Out of scope. The owners check by hand. |

## Complications

- **The index may already hold the person's staged work.** `git mv` adds a rename to whatever is
  staged. The installer does not commit, so the person sees both together in `git status`. The
  site comment must say this is deliberate (decision 1).
- **"Tracked" is a question for git, per file.** `git ls-files --error-unmatch` answers it. A
  file that is staged and not yet committed counts as tracked, and `git mv` moves it correctly.
- **The target may be a subdirectory of a repository, or a worktree.** `git -C "$TARGET_DIR"`
  covers both. The test covers the plain case only.
- **The install log moves by a different path.** `join_install_logs` (`install.sh:890`) uses
  `mv`, or joins and removes. No ignore rule matches `docs/blc/install-log/`, so git sees a
  delete and a new file, and `git add -A` pairs them. It is not in this defect, and `a` leaves
  it alone.
- **The rule is appended after the moves** (`install.sh:989`, after Step 3a at `:918`). With
  `git mv` that does not matter, because git does not ignore a tracked file. It would have
  mattered for a check before the move, which decision 1 rejected.

## Branches

`brief/0020-a-the-tracked-move` (phase `a`).
