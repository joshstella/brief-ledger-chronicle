# Stale branches nothing prunes

**Serial:** #0025 · **Created:** 2026-10-06T03:46:44Z · **Author:** josh.stella@gmail.com · **Depends on:** #0016

## The request

Add a skill, `blc-prune-stale-branches`. It finds stale branches and gives the option to
delete them. It deletes a branch only after a person confirms.

This request started in `orient-believes-the-directory-it-stands-in.md` as a second
change to orient. It is a different problem, so it has its own draft. Orient stays
read-only.

## The evidence

**Local branches, this repository, 2026-10-05.** Three local branches had an upstream that
was gone on `origin`. A fetch showed `[gone]`. Orient has no check for branches. All three
were merged by squash, so `git branch -d` refused each one. Only a patch-equivalence check
(`git cherry main <branch>`) and a manual comparison showed that `main` already had the
work. The patch check matched only one of the three. For the other two, a squash of
several commits is not equal to any one of them, and one branch's files were rewritten in
`main` after the merge. The branches were deleted with `git branch -D`.

**Remote branches, an adopting repository, 2026-10-05.** 82 remote branches were deleted.
The selection used a weak test: "a merged PR has this branch name". See "Evidence for the
rule" below for the audit after the deletion.

## Why orient does not do this

- `blc-orient` says "It does not write". A deletion is a write to the refs.
- Orient reads only local refs and works offline (see the freshness comment in
  `tools/orient.sh`). The strongest test below needs the forge.
- Orient has a budget of about 700 tokens.

Orient can print one line that points at this skill, for example
`3 local branches gone from origin — run /blc-prune-stale-branches`, and print nothing
when the count is 0. See undecided question 5.

## Where the behaviour lives

`blc-orient` puts its behaviour in `tools/orient.sh` on purpose: "a script can be asserted
by the test suite and an instruction to an agent cannot". A skill that runs the tests
below as agent instructions breaks that rule, and the deletion is the step that must not
be untested. So the tests must be in a script, for example `tools/stale-branches.sh`. The
skill runs the script, shows the result, asks the person, and then deletes. See undecided
question 1.

## What "stale" means

Three tests are weak:

- The upstream is gone (`[gone]` in `git branch -vv`). This is cheap and needs a fetch.
  It shows only that a person deleted the remote branch. It does not show that the work is
  in the trunk.
- The branch is an ancestor of the trunk. `git branch -d` accepts these. A squash merge
  never passes this test, and this repository merges by squash.
- Each commit has an equivalent patch in the trunk (`git cherry`). This finds a clean
  squash of one commit. It does not find a squash of several commits, or work that was
  rewritten after the merge. On 2026-10-05 it missed two of the three local branches.

**A proposed rule.** A branch is stale only when one of these three tests passes, in this
order:

1. **The tip is an ancestor of the trunk** (`git merge-base --is-ancestor`). This is proof
   for a merge commit or a fast-forward.
2. **The tip is the head of a PR that merged into the trunk.** The tip SHA is equal to the
   `headRefOid` of a PR whose state is merged **and whose `baseRefName` is the trunk**. This
   is the test that proves a squash merge. Both halves are needed. The PR head must equal the
   tip: a match on the branch name is not sufficient, and a commit pushed after the merge
   makes the SHAs different, which is correct because that commit is not in the trunk. The
   base must be the trunk: a PR merged into a release branch, or into another feature branch,
   has the state merged while its work is not in the trunk at all. A rule that reads the state
   alone proves that a merge happened somewhere, which is not what this skill claims.
3. **A merge into the trunk changes nothing.** `git merge-tree --write-tree <trunk> <tip>`
   gives the trunk's own tree. This test needs no forge and replaces `git cherry`. It can
   fail for a branch that is stale. It cannot pass for a branch that is not stale.

If no test passes, the branch is not proven stale. Show its commits beyond the merged PR
head, and let a person decide. The output must not say "merged" when no test proves it.

**Evidence for the rule.** The audit of the 82 remote branches with the rule above gave
these results:

- 77 tips were equal to a merged PR head (test 2).
- 2 had a closed or no PR. A person had examined them before the deletion. One was
  re-landed as three different PRs. One had a commit message that said "deferred", and a
  later brief replaced it.
- 3 passed the name match but failed test 2. Each had one ledger commit that was pushed
  after its PR merged, and the trunk did not get that commit. A person examined each one
  after the deletion. Two had ledger lines that were already in the trunk from another
  commit. In one, the trunk had a newer status than the lost line. No work was lost. But
  the name-match test passed three branches that it had not proved stale, and the deletion
  came before the examination.

**Test 3 has a limit after a rename.** Test 3 failed for all five branches that were not
proven by test 2, including the two whose content was fully in the trunk. The old branches
had their paths under `docs/briefs/`. After the #0017 move to `docs/blc/`, a merge of any
old branch adds those old paths back, so the trunk's tree changes. Test 3 is useful for
recent branches. It is not useful for branches older than a large rename. Tests 1 and 2
must do most of the work.

**Test 3 needs git 2.38.** `git merge-tree --write-tree` was added in that release. This
repository tests four awk interpreters, so a script that silently does nothing on an older git
is out of character. Test 3 needs a version check and a stated fallback, or it must be dropped.

**Test 2 needs the forge.** It needs `gh` or `glab`, through `tools/detect-forge.sh`
(#0016). Without a forge, the script can run tests 1 and 3 only, and must say that test 2
did not run.

## A deletion is harder to undo than it looks

When a local branch is deleted, its own reflog is deleted with it. Its commits stay
reachable only from the `HEAD` reflog, and only if they were checked out on this machine.
Those entries expire `gc.reflogExpireUnreachable` after the entry's date (default 30 days),
not after the deletion. After that, `git gc` can remove the objects
(`gc.pruneExpire`, default 2 weeks). On 2026-10-05 the three local tips were in the `HEAD`
reflog, but the entries were 45 days old, so the next `git gc` can remove them.

A file of branch names and tip SHAs does not keep the objects. After `git gc` removes
them, the SHA restores nothing. For a remote branch with a PR, GitHub keeps
`refs/pull/<n>/head`, so the PR head can be restored. A commit pushed after the merge, or
a branch with no PR, has no such copy. See undecided question 3.

## What is undecided

1. **The split between script and skill.** The proposal above: the script finds and
   classifies, and never deletes; the skill asks and deletes. The other choice is a script
   with a `--delete` flag that the skill calls after the person confirms. Then the
   deletion is also under test.
2. **Which branches the skill offers to delete.** The proposed answer: offer only the
   branches that pass test 1, 2 or 3, with a confirmation. Report each other branch with
   its commits beyond the merged PR head, for the person to examine.
3. **How a deleted branch can be restored.** A list of names and SHAs is necessary but not
   sufficient (see above). Options: keep a ref such as `refs/blc/pruned/<name>` until a
   person removes it, or write a `git bundle` of the deleted tips. Both keep the objects.
   Both cost something that a person must clean up later.
4. **Remote branches.** They are the same problem with a larger cost: a deletion affects
   every clone. The question is whether this brief includes them, or does local branches
   only.
5. **Whether orient points at the skill.** One line in orient, from tests 1 and 3 only,
   with no forge call. It costs tokens in every orient run that has stale branches.
6. **Whether the fetch comes first.** `[gone]` is only as fresh as the last fetch. Orient
   does not fetch. The skill can fetch first, because a person started it.

## The test

A fixture with one branch whose upstream is gone and one branch that is current. Assert
that the script counts one branch. Assert that the script deletes no branch. Add one branch
that was merged by squash and then got one more commit. Assert that no test proves it
stale. That is the 2026-10-05 case that the name match passed in error.

## Non-goals

- Do not make orient write, or call the forge.
- Do not delete a branch without a person's confirmation.
