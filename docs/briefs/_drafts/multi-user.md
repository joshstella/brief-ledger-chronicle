# Where this toolkit assumes one writer

**Created:** 2026-08-24T12:56:13Z · **Author:** josh.stella@gmail.com
**Depends on:** #0003

> Draft note: unnumbered by design. `create-brief` assigns the serial at filing.

## Ground

This toolkit has exactly one artifact built for other people. The Contract exists because
its trigger is external dependence — a version is published when another programmer needs
to build against it — and #0003's ledger records why it is the only artifact whose cost
scales like n(n-1)/2 rather than n. Briefs, ledgers and chronicles serve the author and the
successors who read the history. The Contract serves the people who will not.

Everything else was designed, exercised and proved by one author. That is not a criticism
of the design. It is the condition under which every mechanism here was tested, and it is
about to stop being true: #0003's ledger records that a small team is being introduced
shortly, and that the author is deliberately working across multiple machines without
committing conveniently in order to meet the failure modes first.

This brief does not add a category. Per the category-boundary rule in #0003, that means it
should be short, and it is deliberately shorter than #0003 was.

## The claim

**Single-writer assumptions are load-bearing in three places, and only one of them is
written down.** The work is to find them, state them, and decide which deserve a clause.
Not to build the fixes.

## Evidence

Three items are verifiable in this repository. The fourth is supplied and marked.

**1. Serial allocation races, and this is already recorded.** `docs/contracts/v1.md:87`
states it plainly: `create-brief` reads the maximum serial and then writes the folder, and
the gap between is a race. "Solo, this never fires. At multi-author scale it will." The fix
is named — allocation against the pushed remote rather than the local checkout — and
deliberately not built. This one is in good shape and is included as the model for how the
other two should end up.

**2. The ledger is one file with one writer, and nothing says so.** A ledger is
`NNNN-slug/ledger.md`, a single document that every phase of a brief appends to.
`skills/start-brief/SKILL.md:53` carries the only multi-user mechanism in the whole
toolkit: commit the ledger to `main` immediately, before any feature branch is cut, "so
it's visible on every machine that pulls." That is a convention. Nothing enforces it,
nothing checks it, and it appears in exactly one step of one skill.

Two people executing two phases of one brief edit the same file on two branches. This is
not speculative: during #0003's own execution, a brief was found already initiated with an
unmerged remote branch that had also modified its ledger, and re-running `start-brief`
would have overwritten it. That was caught by a human noticing, not by a mechanism.

**3. Work is already invisible across machines, with one author.** `_drafts/wip-visibility.md:15`
records three merged pull requests and two deleted branches that a second machine could not
see until `git fetch --prune` ran. That is the benign half — the record existed and had not
been pulled. The malign half is work that is in no record at all. That draft narrows the
response correctly: poll only when a claim is expensive to unwind. It is a dependency of
this brief and must not be re-derived here.

**4. Supplied, not verifiable here: the review gate has never had a second party.**
Reported from a session on 2026-08-21. Author and reviewer were the same agent throughout,
and the loop stayed honest only because a human sat in it and because `commit-push-pr`'s
rule against auto-fixing and self-clearing forced a stop at each finding. The same session
reports the gate catching five factual errors in roughly 120 lines of brief and ledger
prose that careful authoring had missed. Recorded as supplied evidence. The underlying
question — whether `review-pr` is a real gate or a self-check wearing gate clothes — is
answerable only with a second person, which is precisely what is arriving.

## Change

State each single-writer assumption where a reader will meet it, in the document that owns
that surface. Then decide, separately, which ones earn a Contract clause.

Nothing here builds remote-aware allocation, splits the ledger, or adds a check. This repo
runs prose, then clause, then check, in that order and one direction. Landing a rule beside
the prose that motivates it inverts that ordering, and the ordering is the point.

## Settled decisions

- **The Contract is already the multi-user artifact.** No new artifact is needed. This
  brief is about the three record artifacts, which were built for one writer.
- **Recording a boundary is a legitimate answer.** The concurrent-filing entry is the model:
  name the failure, name the fix, state that it is not built, and say why not yet. A known
  boundary is not debt.
- **Optimistic concurrency stays the default.** #0003 settled this and it is not reopened.
  Small bites, frequent commits, and a rebase when someone lands first. Any proposal here
  that imposes coordination cost at the moment of action is wrong by that standard.
- **Prose only.** Per the chain above.

## Open decisions

1. **Does the ledger stay one file per brief?** A file per phase would remove the concurrent
   edit, and would also scatter the narrative that makes a ledger worth reading. The
   alternative is to keep one file and state the ownership rule — one executor per phase,
   ledger committed to `main` before the branch is cut — as a rule rather than a step buried
   in `start-brief`.
2. **Does any of this earn a clause, and in which version?** v1's stated scope is the
   structure of `docs/briefs/` only. A rule about who may write a ledger is a different
   namespace, which means Contract v2 and the first real exercise of the supersession
   design. That may be too much machinery for three sentences of prose.
3. **What changes about `review-pr` when the reviewer is a different person?** The
   do-not-self-clear rule exists because author and reviewer were the same agent. With two
   people it may be redundant, or it may be the only reason the gate ever worked. Not
   answerable before the team arrives; worth deciding whether to answer it deliberately or
   let it be discovered.

## Non-goals

- Not building remote-aware serial allocation. It is recorded, it has a named fix, and it
  has not fired.
- Not a permissions or ownership model. Git has one.
- Not a re-derivation of `wip-visibility`. That draft owns the polling question.
- Not a coordination gate. See the settled decision on optimistic concurrency.

## Success criteria

- A reader can tell which parts of this toolkit assume a single writer, without reading its
  history.
- Each assumption names its failure, its fix, and whether the fix is built.
- The first thing that will break when the team arrives is written down before it breaks.

## A note on the dependency line

This brief depends on `_drafts/wip-visibility.md`, which has no serial, so `Depends on:`
cannot express the relation and names `#0003` alone. The field takes `#NNNN` or nothing,
and an unfiled draft has no `#NNNN`. Recorded here rather than worked around: the same
field also cannot express a dependency on *part* of a brief, which is what a split-out
phase always is. Whether that is an accepted boundary or a gap to close is not this brief's
question, but this brief is an instance of it.
