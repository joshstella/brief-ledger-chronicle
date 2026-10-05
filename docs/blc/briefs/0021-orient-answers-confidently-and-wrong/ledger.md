# Ledger — #0021 Orient answers confidently, and wrong

`blc/2 #0021 in-progress a:done(PR#97) b:in-progress(brief/0021-b-the-log-replay,PR#99) c:pending`

**Brief:** `docs/blc/briefs/0021-orient-answers-confidently-and-wrong/brief.md`
**Started:** 2026-10-04
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the trunk count | done (PR#97) | — |
| b | the log replay | in-progress (PR#99) | `brief/0021-b-the-log-replay` |
| c | the footer | pending | — |

The brief numbers the defects 1 Off-limits, 2 footer, 3 freshness. The phases run in a different
order, by cost on record: the freshness defect wasted a whole branch in an adopting repository
and misled an agent in this one, so it goes first.

**a — the trunk count.** `tools/orient.sh`'s freshness line also counts the checkout against the
default branch, not only against the branch's own upstream. The default branch is read offline
from `origin/HEAD`, which a clone sets. A pushed branch whose base is stale, and a branch with no
upstream, both get a count and a warning when the trunk is ahead. When `origin/HEAD` is unset,
the line says the trunk is unknown and gives the command that sets it. Tests in
`tests/test_orient.sh` with fixture repositories: a pushed branch on a stale base, a branch with
no upstream on a stale base, a current branch, and a clone with no `origin/HEAD`.

**b — the log replay.** Off-limits replays every run in the install log, in order, instead of
collecting only `### Created`. A path that a later run removed (`### Removed`) or dropped
(`### Moved`, "old copy of a toolkit file") is gone. A path that a later run moved
(`old → new`) appears at its new path. The disk is never read. Tests feed logs with `### Removed`
and `### Moved` sections, which no test did before, and one that names a path deleted by hand,
which still shows.

**c — the footer.** The footer names `Manifesto.md` only when that file exists, the way every
other section reports a stated absence. Tests: a target without it, and this repository with it.

## Dependency structure

The three phases touch different sections of `tools/orient.sh` and are independent in the code.
They run one after another because each phase branch writes this ledger's status line.

## Settled decisions

All three resolved 2026-10-04 by the owner, before planning.

| # | decision | reason |
|---|---|---|
| 1 | **Off-limits replays the log and never reads the disk.** Rejected: replay and mark missing paths, and replay and hide them. | A path the install wrote and a person then deleted is the one a reader most needs to see. The brief argues this, and the owner kept it. |
| 2 | **The footer names `Manifesto.md` only when it exists.** Rejected: drop it, and ship a manifesto to every target. | It matches how every other section degrades. Shipping one runs into the question #0019 decision 2 still holds open. |
| 3 | **The freshness line also counts against the trunk.** Rejected: reword only. | Rewording leaves a branch with no upstream with no comparison, which is the case that misled an agent in this repository on 2026-10-03. |

## Complications

- **A `### Moved` section holds two kinds of entry.** `old → new` is a project file that moved.
  `x (old copy of a toolkit file — dropped)` is a toolkit file that was deleted. `b` must read
  both, and must not take the parenthesis as part of a path. **Settled in `b`:** a trailing
  ` (...)` is stripped from both sides of a move and from a dropped entry. A move's destination
  can carry one too: the joined install log is written `… (joined, old entries first)`.
- **Old runs list directories, and the upgrade drops only files.** An old `### Created` names
  `docs/contracts` and `docs/state`. The upgrade logs each file it drops, then deletes the empty
  directories without logging them (`install.sh:950`). Replaying file entries alone would leave
  the old directories on the list. **Settled in `b`:** a move or a drop in a run takes the
  whole old tree off the list. The old layout put each tree directly under `docs/`, so the tree
  is the path's first two segments, and the upgrade deletes every tree it moves from
  (`test_upgrade_leaves_one_tree_not_two`). A path that was on the list and moved comes back at
  its new place. Rejected: drop a directory entry once no listed path is left under it. An old
  run can list a tree with no file under it, such as `docs/state`, and that rule never drops it.
- **`### Created` entries can carry a label.** For example `.gitignore (appended chronicles
  ignore)`. The current reader prints these as they are, and `b` must not mistake one for a path
  that moved.
- **`origin/HEAD` is a clone's default, not a promise.** A repository made with `git init` and a
  remote added later has none until `git remote set-head origin --auto`. GitHub Actions'
  `actions/checkout` is not assumed to set it. Tests build their own fixtures and do not depend
  on the CI checkout.
- **The trunk count reads local refs.** Like the upstream count, it is only as fresh as the last
  fetch. The line must keep saying so, and must not claim more.

## Branches

`brief/0021-a-the-trunk-count` (phase `a`, merged as PR#97, deleted).
`brief/0021-b-the-log-replay` (phase `b`).
