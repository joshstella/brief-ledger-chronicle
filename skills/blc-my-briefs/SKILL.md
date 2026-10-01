---
name: blc-my-briefs
description: >-
  List the open briefs assigned to me (or to an email): their Owner, or their Author when they
  have no Owner. Fetches first, then runs the query. Use when the user asks to blc-my-briefs,
  or asks "what is mine", "what am I on", or "what is assigned to me".
---

# blc-my-briefs

Fetch, bring the checkout up to date where that is safe, then run
`bash tools/list-briefs.sh --owner <email>` from the repository root and show what it prints.

The filter lives in the script, so the test suite can check it. The script does not fetch,
because a report that changes the repository is a surprise. The fetch is this skill's job,
and it is an instruction, not a check.

Usage: `blc-my-briefs [email]`. With no email, use `git config user.email`.

## Steps

1. **Resolve the email.** The argument, or `git config user.email`. If neither gives one,
   stop and ask which email to use. Do not guess one from commit history.
2. **Fetch.** `git fetch --quiet origin`. If it fails, say so. Then go on, and say the list
   may be stale.
3. **Bring the checkout up to date where that is safe.** The script reads the files in the
   working tree, so a fetch alone changes nothing it sees.
   - Find the default branch: `git symbolic-ref --short refs/remotes/origin/HEAD`, without
     the `origin/` prefix. If that fails, use `main`, or `master` if `main` does not exist.
   - **On the default branch:** run `git pull --ff-only`. If it fails, do not merge or
     rebase. Say that the checkout has diverged, and go on with the list as it is.
   - **On any other branch:** do not switch and do not pull. Count
     `git rev-list --count HEAD..origin/<default>`. Show the list, and say first that it
     comes from this checkout, which is that many commits behind `origin/<default>`.
4. **Run it.** `bash tools/list-briefs.sh --owner <email>`.
   - If the script is missing, this project has the skill without the toolkit's tools. Say
     so and stop. Do not build the list by reading the briefs yourself.
5. **Show the table as printed, and every line it wrote to stderr.** A line such as
   `#0012: Owner '…' is not an email` means that brief is assigned to no one until its
   identity line is fixed. Say which brief, and that the person who filed it can fix it.
   A dash row means nothing open is assigned to this email.

## What it does not do

- **It is not a queue.** It shows what is already assigned to this email. Never offer a
  brief with no owner, or someone else's brief, as work to take.
- **It does not write.** It changes no brief, ledger or tracker. The pull in step 3 is the
  only change it makes, and only on the default branch, by fast-forward.
- **It does not read a tracker.** `Owner` comes from the identity line in git.
