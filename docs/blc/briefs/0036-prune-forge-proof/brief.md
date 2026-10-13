# The query nothing tests and the delete nothing checks

**Serial:** #0036 · **Created:** 2026-10-13T18:03:31Z · **Author:** josh.stella@gmail.com · **Depends on:** —

`tools/stale-branches.sh` is the only thing in this toolkit that deletes. Its report is what a
person reads before authorising that deletion, and its `--delete` run is what performs it.
Three links in that chain are unverified.

## 1. The forge query has never been tested

The `pr` test asks the forge which merge requests landed on the trunk, at
`tools/stale-branches.sh:131`:

    gh pr list --state merged --limit 500 --json headRefOid,baseRefName \
      --jq '.[] | "\(.headRefOid)\t\(.baseRefName)"'

Every test in `tests/test_stale_branches.sh` sets `BLC_MERGED_PRS`, which reads that
two-column table from a file instead of asking anything. The separation is deliberate and it
is right — a fixture has no forge, and #0025 wrote it so the strongest test could be exercised
at all. The consequence is that **the query itself, and the `--jq` filter that shapes it, have
never run under test.** The part the suite proves starts one line later, at the awk that filters
by trunk.

## 2. GitLab cannot be asked at all

Line 137:

    *) PR_TEST="the forge is $forge, which this program cannot query yet" ;;

`detect-forge.sh` is already called on line 128, so the plumbing is there and only the case is
missing. `pr` is the only test that proves a squash merge. On a GitLab trunk that squashes, a
person therefore decides with two tests instead of three, and the one that would do the work is
absent. The program reports this. An absence that is only reported is still an absence, and
`blc-commit-push-pr` already routes every forge call through a `gh` / `glab` table, so the
asymmetry is in this tool alone.

## 3. The deletion says it worked without checking

Lines 206 to 238. `git update-ref` is unchecked. `git branch -D` is unchecked. `status` is
never touched. Then:

    echo "deleted $name ($proof), tip kept at $ref"

prints unconditionally. The line asserts two things the program never verified.

A field report on 2026-10-09 caught the first half of this. A run deleted 21 branches inside an
agent sandbox that blocks writes to `.git/config`. `git branch -D` removed each ref and then
failed to remove the config section; stderr carried `could not write config file .git/config`
21 times; every line of the program's own output said `deleted`; the exit status was 0. Ten of
the 21 config sections survived and a person removed them by hand. The skill tells the reader to
read the output rather than the exit code. Here the output was not wholly true.

Nothing was lost in that run, because the sandbox blocked `.git/config` and not `.git/refs`.
The saved tip is the stated insurance for this tool, and writing it is the first unchecked
command in the loop.

## Why these are one brief

Adding the GitLab query increases what qualifies for deletion. On a GitLab trunk that squashes,
branches that `ancestor` and `tree` cannot prove become provable, and each one is a branch the
program will now offer and then delete. More deletions through a loop that does not check what
it did. The failure that was harmless in October becomes a way to lose a `tree`-proven tip,
which — unlike an `ancestor`-proven one — is not reachable from the trunk.

## Claim

Make the `pr` test work on GitLab. Test the forge query on both forges. Make the delete loop
verify what it did before it reports it.

## Settled while scoping, 2026-10-13

- **The GitLab query produces the same two-column table the GitHub branch produces**: the
  source head at merge time, and the target branch. GitLab's `sha` — **not**
  `merge_commit_sha` or `squash_commit_sha`. The test matches a local branch tip against the
  source head; the other two are commits on the trunk and would prove nothing about the branch
  in hand.
- **Pagination is not optional.** The GitLab API caps a page at 100 where `gh` takes
  `--limit 500`.
- **The proof is a `gh` / `glab` shim on `PATH` returning canned JSON.** It exercises command
  construction and the `--jq` filter with no network, and it covers the GitHub path that is
  untested today. A live project in CI was considered and rejected: it needs a token, and it
  would prove the network rather than the program.

## Out of scope

- **Remote branches.** The skill states the boundary: "A remote branch is the same problem with
  a larger cost, because the deletion reaches every clone." A separate brief.
- Expiring the refs under `refs/blc/pruned/`, and `git fetch --prune` in the skill's step 1.
  Both were raised in the same field report and neither is on this chain.

## Open

- Should a failed `update-ref` abort the deletion, or only report it? For an `ancestor`-proven
  branch there is nothing to recover and the tip is a formality. For a `tree`-proven one it is
  real insurance.
- Where the CLI shim lives, and whether it is per-test or a shared fixture helper.
- Whether `glab` version differences matter for paginated `api` calls. Local is 1.113.0; the
  field report's installation is unknown.
- Whether a residual `branch.<name>.*` config section should be reported, removed, or repaired
  by a separate mode.

## Noted while scoping, not part of this work

The `tree` test already exists — `stale-branches.sh:157`, shipped in #0025 phase a — gated by a
probe for `git merge-tree --write-tree`, which needs git 2.38. Line 262 prints that it did not
run when the probe fails. A field report proposed adding this test, which suggests its author
read a run where that line had already said the test was unavailable. Do not add it again.
