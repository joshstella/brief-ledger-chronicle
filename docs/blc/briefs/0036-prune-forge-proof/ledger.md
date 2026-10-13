# Ledger — #0036 The query nothing tests and the delete nothing checks

`blc/2 #0036 in-progress a:in-progress(brief/0036-a-checked-deletion) b:pending c:pending`

**Brief:** `docs/blc/briefs/0036-prune-forge-proof/brief.md`
**Status:** in-progress
**Started:** 2026-10-13

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | checked deletion | in-progress | `brief/0036-a-checked-deletion` | — |
| b | forge query tests | pending | — | — |
| c | gitlab query | pending | — | — |

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

## Open decisions

- **Where the CLI fixture lives, and whether it shims `git` as well as the forge CLI.** Blocks
  `b`. Phase `a` needs the same answer, because it has to make `update-ref` and `branch -D`
  fail inside a fixture — so the mechanism is built in `a` and extended in `b` and `c`.

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
