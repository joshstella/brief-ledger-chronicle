# Ledger — #0036 The query nothing tests and the delete nothing checks

`blc/2 #0036 done a:done b:done c:done`

**Brief:** `docs/blc/briefs/0036-prune-forge-proof/brief.md`
**Status:** done
**Started:** 2026-10-13
**Closed:** 2026-10-14

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | checked deletion | done | `brief/0036-a-checked-deletion` | #150 |
| b | forge query tests | done | `brief/0036-b-forge-query-tests` | #151 |
| c | gitlab query | done | `brief/0036-c-gitlab-query` | #152 |

**a — checked deletion.** The delete loop in `tools/stale-branches.sh` runs `git update-ref`
to save the branch tip and `git branch -D` to remove the branch, then prints
`deleted <name> (<proof>), tip kept at <ref>` without examining either exit status. The line
asserts two things the program never verified, and the run exits 0 whether or not they
happened. This phase makes each command's result decide what that line says, sets the exit
status when either fails, and reports a `branch.<name>.*` configuration section that survived
the deletion. The tests drive those failures rather than describing them, which needs a way to
make a git command fail inside a fixture. Adds a line to the skill about what a reader sees
when an agent sandbox blocks writes to `.git/config`: the refs are gone and the configuration
is not.

**b — forge query tests.** Nothing exercises the command that asks the forge which merge
requests landed on the trunk. Every existing test sets `BLC_MERGED_PRS`, which is read before
the forge branch and short-circuits it, so `gh pr list --json … --jq …` and the filter that
shapes its output have never run under test. This phase builds a fixture that puts a fake
forge CLI on `PATH` and satisfies `detect-forge.sh`, then asserts the GitHub path end to end:
the command the program builds, and the two-column table it produces. It adds no behaviour to
the tool. It is what makes the next phase provable.

**c — gitlab query.** `tools/stale-branches.sh` will not ask GitLab. The switch on the
detected forge has a GitHub case and a default that reports the forge cannot be queried yet.
The `pr` test is the only one that proves a squash merge, so a GitLab trunk that squashes is
pruned on two tests instead of three, and the one that would do the work is absent. This phase
adds the GitLab case, producing the same two-column table from merged merge requests — the
source head at merge time and the target branch, not the merge or squash commit — with
pagination, because the GitLab API caps a page at 100 where `gh` takes `--limit 500`. Proven
by the fixture from phase `b`.

## Dependency structure

`a` and `b` are **parallel tracks**. They touch different parts of the tool and meet only in
the test file, so they can run on separate branches at once.

`c` is a **strict successor of `b`**: the fixture is how the GitLab query is proven, and
without it the new case would ship as untested as the GitHub one is today.

`c` must also land after `a`, and that constraint is policy rather than code. Phase `c`
increases what qualifies for deletion on a squashing GitLab trunk — branches that `ancestor`
and `tree` cannot prove become provable, and each is one the program will offer and then
delete. The brief's argument for making these one piece of work is that those extra deletions
should not run through a loop that does not check what it did.

## Settled before `a` began, 2026-10-13

- **A failed `update-ref` aborts that branch's deletion.** The branch is left alone, the
  failure is reported on its line, and the run exits non-zero. Not deleting a branch costs a
  second run; deleting one whose tip was never saved is the loss the saved tip exists to
  prevent. The rule is uniform across proofs rather than conditional on which test proved the
  branch: a `tree`-proven tip is genuinely unreachable from the trunk, and a rule that reads
  the proof before deciding how careful to be is one more thing to get wrong in the only
  irreversible path this toolkit has.
- **A surviving `branch.<name>.*` section is reported, not removed.** It goes on that
  branch's line and the run exits non-zero. The refs are gone by then, so this is a report
  about a deletion that already happened, and the smallest honest thing the program can do is
  stop claiming the deletion was clean. Removing it is a second write in the same loop that
  just failed to write.

## Settled while writing `a`, 2026-10-14

- **No `git` shim. Every failure is produced with plain git.** Measured on git 2.43 before any
  code was written:
  - `update-ref` fails on a directory/file ref conflict. Pruning `feature` leaves
    `refs/blc/pruned/feature`. Pruning `feature/x` later builds `refs/blc/pruned/feature/x`,
    which the existence loop does not catch because it does not resolve, and git exits 128.
    A case the toolkit will meet, not only a way to fail on purpose.
  - `branch -D` fails while `update-ref` succeeds when the `.git` top directory alone is
    read-only. `update-ref` locks under `.git/refs/blc/pruned/`, a subdirectory that stays
    writable. `branch -D` needs `.git/packed-refs.lock` in the top directory and exits 1.
    That is the selective failure the abort rule exists for, with nothing between the tool
    and git. It is a no-op for root, so this test calls `skip`.
  - A `branch.<name>.*` section survives a successful deletion when it lives in a file reached
    through `[include] path = …`. The branch goes, the run exits 0, and the value still reads.

  The decision below is therefore closed for `a`, and narrowed to the forge CLI for `b`.

- **A configuration section does not survive because a sandbox blocked a write.** The decision
  above stands; the reason given for it was wrong, and the skill must not repeat it. A
  read-only `.git/config` is rewritten anyway, because git writes a temp file and renames it
  and the containing directory is writable. A read-only `.git` directory fails the deletion
  itself, so the refs are not gone either. "Refs gone, configuration not" could not be
  produced with permissions at all. An included file produces it, and it is the stronger
  argument for reporting rather than removing: **the toolkit may not own the file the value
  lives in.**

- **"Surviving" means the local file and what it includes, not every scope.** Found by the
  review gate, after a stray `[branch …]` section in a global file made a clean prune report a
  survivor and exit non-zero. `--local` is the wrong correction: it reads one file and drops
  the included value, which is the only case this check exists for. The reading is
  `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null git config --list`, which keeps
  includes and drops the two outer files. The rule behind it: **a section the deletion was
  never going to remove is not a residue of the deletion.** A person's per-branch defaults in
  `~/.gitconfig` belong to the person.

## What `a` taught, 2026-10-14 (PR #150)

- **The sequence is unchanged. `c` lost one constraint.** `c` had to land after `a` because it
  makes more branches qualify for deletion and those deletions should not run through an
  unchecked loop. The loop is checked, so `c` now waits only on `b`.
- **`a` built no fixture, so it answered nothing for `b`.** Every failure `a` had to drive came
  out of plain git, so the shim question never arose. The precedent does not carry: there is no
  real forge to reach, so `b` has to fake one. It narrows what may be faked — the forge CLI,
  never `git`.
- **Two open items left `a` and are now on `main`**, recorded in PR #150 rather than fixed:
  the read-only `.git` test calls `skip` for root, so the abort path does not run on a root CI
  container; and `GIT_CONFIG_GLOBAL` needs git 2.32 with nothing probing for it, which the tool
  and its test both assume, so neither catches its absence.

## Settled for `b`, 2026-10-14

- **The fixture gets its own directory, not the suite's shared `$STUB_BIN`.** `tests/run.sh:231`
  fills that directory with an inert `gh` that exits 0 for every invocation. A test built on it
  would pass without proving anything: `gh auth status` succeeds, so `detect-forge.sh` answers
  `github`, and `gh pr list` then exits 0 with no output, so `PR_RAW` is empty and `PR_TEST`
  still reads `ran`. That is the same shape of defect this brief was filed about. The fixture
  needs a recording `gh` of its own.
- **The same directory holds a `glab` that rejects.** `detect-forge.sh:85` probes both CLIs on
  every call. Without a local `glab`, a machine that has the real one makes a live
  `glab auth status` round trip to a hostname that does not exist, on every run of the suite.

## What `b` taught, 2026-10-14 (PR #151)

- **The fixture extends to `c` unchanged.** `c` adds a recording `glab` that accepts and a `gh`
  that rejects, so `detect-forge.sh` answers `gitlab`. Nothing else about `b` needs revision.
- **Three items left `b` and are now on `main`**, recorded in PR #151 rather than fixed: the
  fake `gh` records `"$*"`, so the query is pinned by text and not by argv shape; the
  base-column test stays green when the forge is never asked, so it means something only beside
  the query test; and `run_stale_forge` carries a guard for a state only `c` can reach.

## Settled for `c`, 2026-10-14

Measured against the live GitLab REST API before any code was written, because `glab` is
installed here with no valid token and cannot be asked.

- **The query is `glab api`, not `glab mr list`.** `glab api` takes a `:fullpath` placeholder
  and returns the REST response, so the field names are the API's own. `glab mr list -F json`
  returns whatever shape `glab` chose to marshal, which cannot be checked here. A fake CLI
  proves the program builds the command it was told to build; it cannot prove the command is
  right for the real CLI, so the less this depends on, the more `c` is worth.
- **The fields are `sha` and `target_branch`.** Confirmed on a real merged merge request. The
  same object also carries `merge_commit_sha` and `squash_commit_sha`, and all three differ, so
  the brief's insistence on the source head rather than the merge commit is a real distinction.
  The `pr` test matches a branch tip, and only `sha` is that tip.
- **Five pages of 100, and stop.** Confirmed: `per_page=200` returns 100 items with
  `x-per-page: 100` and `x-next-page: 2`, so paging is not optional. `glab api --paginate`
  would walk every page to the end, which on a large project is hundreds of round trips the
  GitHub side never makes. 500 is what `gh pr list --limit 500` already fetches, so both forges
  prove the same amount of history and neither can hang.

## Open decisions

None.

## Complications found while planning

- **The fixture has to satisfy `detect-forge.sh`, not just `gh`.** Line 128 calls it, and it
  probes both CLIs against the remote host. A test that wants the GitHub branch has to make
  that probe answer `github`. This is the main unknown in `b`.
- **`BLC_MERGED_PRS` is read before the forge branch**, which is why no existing test reaches
  it. Any test of the query must leave that variable unset, so the fixture cannot reuse
  `run_stale` as it is written today.
- **This repository has no `AGENTS.md` or `CLAUDE.md`.** Step 4 of `blc-start-brief` expects
  one; `.cursor/rules/brief-ledger-chronicle.mdc` holds the equivalent rules here.
- **The `tree` test is gated on git 2.38.** Whether `tree`-related assertions run at all
  depends on the git in CI, and a fixture that assumes the test ran will pass or fail by
  accident on a different runner.

## Branches

`brief/0036-a-checked-deletion`, cut from `main` at `1e434f6`.
`brief/0036-b-forge-query-tests`, cut from `main` at `51f74ba`.
`brief/0036-c-gitlab-query`, cut from `main` at `c80936f`.
`brief/0036-closeout`, cut from `main` at `1a887ce`.

## Close, 2026-10-14

### What shipped

`tools/stale-branches.sh` now reads what it did before it says what it did, and can ask either
forge which work landed.

- **`a` (#150)** — the delete loop ran `git update-ref` and `git branch -D` and then printed a
  line asserting both had worked, reading neither exit status. Each result now decides what the
  line says, and any failure sets a non-zero exit.
- **`b` (#151)** — every test of the `pr` proof handed the program a file through
  `BLC_MERGED_PRS`, which is read first and short-circuits the forge branch. The command that
  asks the forge had never run under test. It does now.
- **`c` (#152)** — the switch on the detected forge had a GitHub case and a default saying the
  forge could not be queried. GitLab can be asked, five pages of 100, matching what
  `gh pr list --limit 500` already fetches.

Both settled decisions held. A failed `update-ref` aborts that branch's deletion, uniformly
across proofs. A surviving `branch.<name>.*` section is reported and not removed.

### What the record shows that the brief did not predict

- **The brief expected a `git` shim and was wrong about where the hard part was.** It planned
  for `a` and `b` to share a mechanism for making commands fail inside a fixture. `a` needed
  none: a directory/file ref conflict fails `update-ref`, and a read-only `.git` top directory
  fails `branch -D` while `update-ref` still succeeds, because it locks in a subdirectory that
  stays writable. The one place a fake was unavoidable is the forge, which the brief treated as
  a detail of `b`.
- **The brief's stated cause for a surviving configuration section was false.** It said an
  agent sandbox blocking writes to `.git/config` leaves the refs gone and the configuration
  behind. Measured: a read-only `.git/config` is rewritten anyway, because git writes a temp
  file and renames it into a writable directory, and a read-only `.git` fails the deletion
  itself. That state could not be produced with permissions at all. An included file produces
  it, and it is the better argument for the decision the brief had already settled: **the
  toolkit may not own the file the value lives in.**
- **The check needed a scope, and nothing in the plan said so.** `surviving_config` first read
  every config scope, so a `[branch "x"]` section in `~/.gitconfig` counted as outliving a
  deletion it was never part of, and a clean prune exited non-zero. Found by the review gate
  rather than by the plan. `--local` is the wrong correction — it drops the included value,
  which is the only case the check exists for.
- **The brief said pagination was not optional and did not say how far to page.** The answer
  was already in the file: `gh pr list --limit 500`. Stopping at five pages of 100 makes both
  forges prove the same amount of history.
- **A tripwire nobody wrote for this caught a real edit.** `tests/test_skill_names.sh` pins how
  often "squash" appears in each shipped file. Phase `c` moved the count and the test said to
  read the lines before re-pinning.

### Open after close

- **The root skip.** `stale_does_not_claim_a_deletion_the_branch_survived` calls `skip` when
  the user is root, because a read-only `.git` is not read-only for root. On a root CI
  container the abort path for a failed `branch -D` never runs and the suite still reports
  clean. That is the machine most likely to run this.
- **A version floor nothing probes.** `GIT_CONFIG_GLOBAL` arrived in git 2.32. On older git the
  variable is ignored, and the tool and its test share the same assumption, so neither catches
  its absence.
- **The GitLab query has never run against a real GitLab.** Field names, the 100-item page cap
  and the `x-next-page` header were verified against the live REST API, and the CLI flags
  against `glab api --help`. `glab api` returning that body unmodified through `--jq` is not
  verified.
- **Both fake CLIs record `"$*"`**, which flattens argument boundaries, so each query is pinned
  by text rather than by argv shape. A quoting regression would pass.
- **`run_stale_forge` carries a guard** for a fixture-less state that nothing now reaches. It
  exists because `TMP` is per-test and a stale `FORGE_BIN` would send the suite to a real CLI.
- No bug ledger (`review-<branch>.md`) was written for any phase. There were no surviving
  correctness bugs, but step 4 of the close had nothing to read.

### What this cannot prove

- **Every review on this brief was written by the author of the code.** `blc-review-pr` ran on
  each phase and returned Approve with suggestions three times. One independent pass — Bugbot,
  on `c` only — found no bugs. No person read any of the three diffs before they merged.
- **The mutation checks were designed by the same person who wrote the code.** Eleven mutations
  across the three phases each failed exactly one test, which shows the tests are coupled to the
  behaviour. It does not show they cover the breaks nobody thought of.
- **A fixture shows the program builds the command it was told to build.** It cannot show the
  command is right. This is stated about GitLab because that query is new, but it is equally
  true of the GitHub query `b` tested, which was presumed working because it had shipped.
- **`blc-review-pr` is a skill, not a check.** Nothing enforced it on any phase. The only
  evidence it ran is the prose in the pull request bodies, which the same agent wrote.
