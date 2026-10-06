# An upgrade that cannot be re-run, and a version nobody can name

**Serial:** #0023 · **Created:** 2026-10-06T01:30:00Z · **Author:** josh.stella@gmail.com · **Depends on:** #0020

## The finding

Two things stop this toolkit from being installed into other people's projects. Both are
about the adopter, not the internals.

**An upgrade that fails partway cannot be re-run.** #0020 recorded this as untested and
expected to be benign: "A re-run is expected to finish, because a moved file is no longer at
its old path and so is not a clash." That reasoning is right about the clash check, and the
clash check never runs. A different guard refuses first.

**A target cannot say which version it has.** `install.sh` stamps a version into every
install log. There are no tags in this repository, so the value is a bare commit hash.

## The claim

**An adopter must be able to re-run a failed upgrade, and must be able to name what they
have.** Neither is true today, and the first is a reproducible defect rather than a gap.

## Evidence

**1. The refusal is reproducible.** An old-layout target, with `docs/briefs/` moved to
`docs/blc/briefs/` to stand for a `git mv` that died partway, then a re-run:

```
error: .../docs/blc/ holds files this toolkit did not install.
  The toolkit keeps everything it uses under docs/blc/, and it has no install log there,
  so these files belong to the project. Nothing was written to the target.
  Move them out of docs/blc/, or empty it, and re-run.
```

The installer exits and writes nothing. Every later run reaches the same refusal.

**2. The cause is the order of the moves.** `install.sh:880` builds `OLD_MOVES` in
`LC_ALL=C sort` order, so the moves run `briefs`, `chronicles`, `contracts`, `install-log`,
`orientation.md`, `state`. The install log moves fourth. `install.sh:846` refuses any
`docs/blc/` that holds files and has no `docs/blc/install-log/install-log.md`, on the correct
reasoning that such a tree belongs to the project. A failure before the log's turn leaves
exactly that state. `briefs` is both first and usually the largest tree.

**3. The recovery advice is wrong for this case, and the record it needs does not exist.**
The message says to move the files out of `docs/blc/`, which asks the adopter to undo a move
the installer made. `install.sh:1198` writes the install log at the end of the run, so an
aborted run leaves no list of what moved.

**4. The version is a commit hash.** `install.sh:1201` is
`git describe --tags --always`, and `git tag` prints nothing. So every target's install log
reads `**Installer version:** <sha>`. Nothing tells an adopter what changed between two
installs, and `tools/orient.sh` has nothing better to report.

**5. The machinery is already right.** The clash check, the symlink refusal, the
toolkit-file drop, and `--print-ownership` all work. The version is already computed,
stamped, and printed. What is missing in both cases is small.

## Change

| Phase | Work |
|---|---|
| `a — the log moves first` | The install log moves before any other old-layout path. A partial move then always leaves `docs/blc/install-log/install-log.md`, so the ownership guard passes on re-run and the existing clash logic finishes the job. Tests: a half-moved target re-runs to completion, and the resulting tree equals a clean upgrade's. |
| `b — what a version is` | Tag a version, and decide what the number means when the Contract carries its own. `install.sh` reports it, and a target's install log records it. Tests: a tagged checkout stamps the tag, not a hash. |
| `c — a target that is behind` | `tools/orient.sh` says the installed version and whether the source is newer. Only if `b` settles that the comparison is cheap and does not need a network call. |

`a` is independent of `b` and `c` and goes first, because it is a defect and they are gaps.
`c` depends on `b`.

## Tension

Moving the install log first breaks the sorted order that makes the moves easy to read and
easy to log. One special case, early, is the cost of a re-runnable upgrade.

A version number invites the expectation that a minor version is compatible. The Contract
already promises that for the briefs directory, and nothing else here is promised at all. A
version that implies more than the Contract says would be the specification-first move this
project argues against.

## Settled decisions

- **The ownership guard stays.** It is right: a `docs/blc/` with no install log is the
  project's. The defect is the order of the moves, not the guard.
- **The installer does not repair what it half-moved.** Re-runnable is the goal. A repair
  path would need the record that an aborted run never wrote.

## Open decisions

1. **What a version number means here.** Semantic versioning against what promise? The
   Contract is separately versioned and binds only the briefs directory. The installer's
   ownership rules are what adopters rely on and are uncontracted. Blocks `b`.
2. **A target already half-moved by the current installer.** Is there one, and does it get a
   documented hand recovery, or does `a` also detect and finish the move? Blocks `a`.
3. **Whether `c` belongs here** or waits until an adopter asks what they have. Blocks `c`.

## Non-goals

- **Not making the moves atomic.** `git mv` can fail and the installer cannot prevent it.
  Re-runnable is the goal, not transactional.
- **Not a Contract v2.** What the installer promises is a separate question from whether an
  upgrade can be re-run.
- **Not a release process**, package, or distribution channel. A tag is the whole of `b`.

## Success criteria

- A target half-moved by a failed upgrade re-runs to completion with no hand editing, and
  ends in the same tree a clean upgrade produces.
- A test fails against the current installer for that case.
- A target's install log names a version that exists in this repository's tags.
- What the version number promises is written down, and it does not promise more than the
  Contract does.
