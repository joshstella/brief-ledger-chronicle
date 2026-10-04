# Orient answers confidently, and wrong

**Serial:** #0021 · **Created:** 2026-10-04T09:04:36Z · **Author:** josh.stella@gmail.com · **Depends on:** #0017

## The finding

`tools/orient.sh` is rung 0. Its value is that a reader trusts it instead of reading the
record. Three of its answers are wrong, and none of them look wrong. Each was found by
installing the toolkit into an adopting repository on 2026-10-03 and then checking the output against
the repository.

| # | line | what it prints | what is true |
|---|---|---|---|
| 1 | `tools/orient.sh:134` | 25 paths under **Off-limits** | 8 of them do not exist |
| 2 | `tools/orient.sh:176` | `Deeper: … Manifesto.md …` | the target has no `Manifesto.md` |
| 3 | `tools/orient.sh:44` | `0 behind / 0 ahead` | `main` was 2 commits ahead |

**1. The Off-limits reader uses one section of a log that has several.** Line 134 collects
`### Created` entries from every run in the install log and sorts them unique. Nothing
subtracts `### Removed`. Nothing subtracts `### Moved — old docs/ layout to docs/blc/`. In
the adopting repository the list named six commands that an earlier run had pruned, and it named
`docs/contracts` and `docs/state`, which the #0017 move had just relocated. The reader is
told to keep off paths that are gone.

The comment above the section states the opposite:

> Derived from the install log, not from install.sh. … it cannot drift from the installer
> the way a restatement here would.

The log is the right source. The reader consumes a third of it and presents the result as
the whole state.

**2. The footer names a file the toolkit does not install.** `Manifesto.md` is in this
repository. The ownership map does not copy it to a target. Every installed project
therefore prints a pointer to a file it does not have. In the adopting repository an agent read that
footer, looked for the file, and found nothing.

**3. The freshness line measures the branch against itself.** Line 44 reads
`@{upstream}`. On a feature branch that is `origin/<branch>`, so a branch pushed and not
merged reports `0 behind / 0 ahead` and prints no warning. That answer is true and it is
not the question. The question the section header asks is "how much to trust any of
this", and the record the rest of the output describes lives on `main`.

A branch with no upstream fares worse. Line 51 prints "no upstream — this is a local-only
view" and makes no comparison at all. On 2026-10-03, in this repository, orient ran on
`brief/orient-is-a-process-skill`, a local branch cut from a `main` that was 43 commits
behind `origin/main`. It printed that line. The open briefs it listed had closed upstream
days before, and the agent offered to start a phase that had already merged. A fetch found
the gap. Both cases have one cause: the count never looks at the trunk.

## Why they went unnoticed

**The tests exercise only the happy path.** `tests/test_orient.sh` holds 30 tests. Three
cover Off-limits: `test_orient_derives_off_limits_from_the_install_log`,
`test_orient_does_not_claim_ownership_the_log_does_not_record`, and
`test_orient_collapses_a_child_under_its_logged_parent`. Every one builds a log whose only
section is `### Created`. No test gives the reader a log with a `### Removed` or a
`### Moved` section, so no test can fail on a reader that ignores them. The suite passes
534 tests and says nothing about this.

**Defects 2 and 3 cost nothing in this repository.** The toolkit repo has `Manifesto.md`,
so the footer is correct here and wrong only in a target. The toolkit repo does its work on
`main`, so the freshness line is correct here and wrong only on a feature branch. Both
defects are invisible from the one checkout that always has the script.

## The cost, measured

On 2026-10-03 an agent ran `orient.sh` in the adopting repository on branch `chore/blc-update`, read
`0 behind / 0 ahead`, and reported the checkout as current. `main` was two commits ahead
with two toolkit installs on it. The agent then built a 130-file migration
on that stale base. The result conflicted with `main` across 21 files and had to be reset
to `main` and rebuilt. The whole branch was wasted work.

That is the exact failure the section's own comment predicts:

> Everything below is derived from local refs, so on a stale clone it is confidently
> wrong. #0003 has the concrete case on the record.

#0003 recorded the stale-clone case and the fix counted against the branch's own upstream.
The case above is a fresh clone with a current branch and a stale base, which that count
cannot see.

## What is actually undecided

1. **How far the Off-limits fix goes.** The narrow fix replays all three sections in
   order, so a path created, then removed, is absent, and a path created, then moved,
   appears at its new location. The wider question is whether the reader should also check
   that each surviving path exists on disk. That turns a log replay into a filesystem
   check, and it would hide a path the install wrote and a person then deleted — which is
   arguably the one thing a reader most needs to see.
2. **What the footer should name.** Three options. Print `Manifesto.md` only when the file
   exists, which matches how every other section degrades to a stated absence. Drop it and
   let `docs/blc/orientation.md` be the single authored rung. Or install a short manifesto
   into each target, which is a new toolkit-owned path and a larger decision.
3. **Whether the freshness line is in scope at all.** Counting against the default branch
   as well as the branch's own upstream costs two lines and one more `git rev-list`. It
   also requires naming a default branch, which the script does not currently know and
   cannot always derive offline. A reasonable alternative is to say plainly that the count
   is against the branch's own upstream and not against the trunk, and let the reader draw
   the conclusion.

## Out of scope

**The installer can move a project file onto a path its own `.gitignore` hides.** During
the same install the #0017 move relocated six chronicles into `docs/blc/chronicles/`, where
the shipped rule `docs/blc/chronicles/*` with a single negation for `chronicle.md` made all
six untracked. The files were tracked at their old path, and git does not ignore a tracked
file, so the rule had never bitten before. A commit at that moment would have deleted the
whole chronicle history from the repository. It was caught by hand, not by a test:
`upgrade_moves_each_project_file_under_docs_blc` checks the filesystem, and nothing checks
that git can still see what moved.

That is `install.sh`, not `orient.sh`, and it is more severe than all three defects above.
It needs its own brief, and is filed as #0020. The missing
assertion is one line: after an upgrade, every moved project file is addable.
