# Someone else's docs tree

**Created:** 2026-09-16T10:59:03Z · **Author:** josh.stella@gmail.com
**Depends on:** #0013

## Ground

An install scatters five directories across the root of a project's `docs/`: `briefs/`,
`contracts/`, `chronicles/`, `state/`, `install-log/`. None of them is marked as belonging to
a tool. A project that already keeps documentation in `docs/` gets five new top-level entries
it did not ask for and cannot tell apart from its own.

This repository cannot feel that. Its `docs/` tree *is* the toolkit's, so the five directories
look like the natural contents of the project rather than the footprint of a dependency. The
cost is paid entirely by adopters, which is why it has gone six weeks without being noticed
here.

#0012 recorded which paths the installer owns in an ownership map. That was the right fix for
the question it answered — what may an upgrade replace — and it does nothing for this one.
Ownership recorded in a map is not ownership visible in a tree.

## The claim

**Everything the installer writes lives under `docs/blc/`.**

```
docs/blc/briefs/  docs/blc/contracts/  docs/blc/chronicles/
docs/blc/state/   docs/blc/install-log/
```

One directory to exclude from a docs build, one to gitignore, one to recognise as not yours.
The four tools change their defaults and keep their positional argument, so a project that
wants the tree elsewhere still puts it elsewhere.

`brief-checks/` does **not** move. It stays at the repository root because it is project-owned,
and #0011 chose that path precisely because the installer has no claim on it. Filing it under
`docs/blc/` would put the one directory an adopter is meant to edit inside the toolkit's own
namespace, which is the confusion this brief exists to remove.

## Evidence

**1. Five top-level entries for one tool.** No other dependency in a typical project claims
five directories in `docs/`, and nothing in the tree says these five are related.

**2. The cost is measured and it grows.** 480 path references across 61 files, counting the
committed toolkit and record and excluding unfiled drafts: `briefs` 276, `contracts` 61,
`chronicles` 55, `state` 51, `install-log` 37. Every brief filed from here adds to it. Doing
this later is strictly more expensive than doing it now, and doing it never charges every
adopter instead.

**3. A docs build picks the tree up as content.** A static site generator pointed at `docs/`
renders briefs, ledgers, chronicles and contributor state files as pages. Excluding five paths
is five rules that rot independently; excluding one is one rule.

**4. The tools already support relocation and nobody can use it.** All four take the briefs
directory as a positional argument, but the four sibling directories are hardcoded —
`orient.sh:20` and `orient.sh:22` name `docs/state` and `docs/install-log` outright. The
flexibility that exists is partial enough to be misleading.

**5. The Contract's scope sentence is already a path.** `v1.1.md:12` reads "Version 1.1 covers
the structure of `docs/briefs/` only." The published promise is phrased in terms of a location,
so relocating the tree is a contract event whether or not it is convenient.

## Change

| Phase | Work |
|---|---|
| `a — the move` | `git mv` the five directories under `docs/blc/`. Update the four tool defaults and the hardcoded siblings in `orient.sh`. Update skills, templates, tests, `README.md`, `Manifesto.md`. Tests for both the new default and the positional override. |
| `b — the record` | Rewrite path references inside existing briefs and ledgers so they resolve. A deliberate exception to a project value — see the settled decisions and the tension it carries. |
| `c — the installer` | `install.sh` writes to the new root, and an upgrade migrates an existing install rather than leaving two trees. Ownership map updated to the new paths. Blocked by open decision 1. |
| `d — the contract` | v1.2: re-scope `BRIEFS-1`–`8` to the new root and publish. v1.1 stays reachable. |

Each phase carries its own tests. Chain is `a → b` and `a → c → d`; `b` is independent of `c`
and `d` and can run in parallel with them.

## Tension

**This rewrites the record, and the record is not supposed to be rewritten.** The values file
says a brief is the hypothesis before the code and a ledger is what executing it cost, and that
neither is rewritten afterwards to look right. Phase `b` does exactly that to thirteen briefs and
twelve ledgers. It is a considered exception, not an oversight: the toolkit is still
bootstrapping, it has one user and six weeks of record, and the rule is worth more holding from the
new root forward than it is worth preserving 124 dead links into a layout that existed
for six weeks. Anyone citing this later as precedent should cite those numbers with it. Once
there is a second adopter, the answer changes.

**The rewrite cannot be complete, which weakens its own rationale.** Merged PR descriptions,
commit messages, and the chronicle's narrated history all cite the old paths and cannot be
edited. So the record ends up half re-pointed: briefs and ledgers resolve, the commits that
produced them do not. If the reason for rewriting is that links should resolve, that reason is
only partly served, and the honest summary is that this buys tidiness in the two artifacts
that are read most often.

**An upgrade moves an adopter's tree under them.** Any branch in flight that touches a brief
conflicts on every path. There is no version of this that is not disruptive once someone other
than the author has installed it — which is an argument for doing it now rather than an
argument against doing it.

**Two supported layouts is a promise that needs proving.** Keeping the positional argument
means the old layout still works, and a claim like that is a lie unless tests cover both. That
doubles the path-related test surface permanently.

**Every path gets one level deeper.** `docs/blc/briefs/0013-slug/ledger.md` is a long path to
type and a long path to read in a diff. Small, constant, and paid forever.

**Nothing here improves the toolkit's behaviour.** No defect is fixed and no capability is
added. This is a change to where files sit, justified entirely by the experience of a person
who has not adopted it yet.

## Settled decisions

Resolved 2026-09-16 during drafting.

- **Everything the installer writes goes under `docs/blc/`.** One root, named for the toolkit.
- **`brief-checks/` stays at the repository root.** Project-owned, per #0011. Moving it would
  contradict the reason it was put there.
- **Existing briefs and ledgers are rewritten to the new path.** Taken knowingly against "the
  record is the work", for the bootstrapping reason stated in the tension above. Recorded here
  rather than done quietly, because a rule broken in silence is a rule that stops binding.
- **The positional argument survives**, and the hardcoded siblings in `orient.sh` gain the same
  treatment. Partial flexibility is worse than either alternative.
- **Contract goes to v1.2 and v1.1 stays published.** Superseded is not deleted.
- **#0013 finishes first.** It edits `open-briefs.sh` and `docs/briefs/README.md`; moving the
  tree beneath an in-flight brief would conflict on every phase for no gain. This brief is not
  started until #0013 is closed.
- **v1.2 is published once.** If the findability clause from `_drafts/the-shape-nothing-prescribes.md`
  also lands, whichever brief finishes second carries the publication and cites both changes.

## Open decisions

1. **Whether an upgrade migrates an existing install or refuses and prints instructions.** A
   silent `git mv` inside someone's repository is the kind of surprise `install.sh` has avoided
   so far; a refusal leaves them to do it by hand and get it wrong. Blocks phase `c`.
2. **What an install does when `docs/blc/` already exists and is not ours.** Unlikely, and the
   toolkit cannot claim a name it did not create. Blocks phase `c`.

## Non-goals

- **Not renaming the five directories.** `briefs/` stays `briefs/`; only the root above it changes.
- **Not changing file contents beyond path references.**
- **Not moving `brief-checks/`.**
- **Not making the location configurable beyond the positional argument that already exists.**
- **Not rewriting git history, commit messages, or PR descriptions.** Impossible, and the
  tension section says what that costs.

## Success criteria

- A fresh install adds exactly one entry to an adopter's `docs/`: `blc/`.
- All four tools default to the new root and still honour a positional override, with tests
  covering both.
- Every path reference inside a brief or ledger resolves.
- An upgrade of an existing install leaves one tree, not two, and says what it moved.
- Contract v1.2 is published with clauses re-scoped; v1.1 is still reachable.
- `brief-checks/` is untouched at the repository root.
- The full suite is green, and `validate-briefs.sh` reports zero defects against the moved tree.
