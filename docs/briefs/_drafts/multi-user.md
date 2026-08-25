# Closing the single-writer holes before the second writer arrives

**Created:** 2026-08-25T12:40:16Z · **Author:** josh.stella@gmail.com
**Depends on:** #0003, #0004

> Draft note: unnumbered by design. `create-brief` assigns the serial at filing.

## Ground

This toolkit has exactly one artifact built for other people. The Contract exists because its
trigger is external dependence — a version is published when another programmer needs to build
against it — and #0003's ledger records why it is the only artifact whose cost scales like
n(n-1)/2 rather than n. Briefs, ledgers and chronicles serve the author and the successors who
read the history. The Contract serves the people who will not.

Everything else was designed, exercised and proved by one author. That is not a criticism of
the design. It is the condition under which every mechanism here was tested, and it is about to
stop being true.

**This draft replaces an earlier one on the same subject.** That version stopped at stating the
assumptions and ruled out building anything, on the grounds that this repo runs prose, then
clause, then check, in one direction. The scope has changed: the fixes are now in. The ordering
rule is not discarded — it is carried into the phase sequence, where the prose lands before
anything that enforces it. What is dropped is the claim that a separate brief must land first.

## The claim

**Three single-writer assumptions are load-bearing, each has a named fix, and none is built.**
Two of the three are already written down. The work is to state the third and then close all
three, in that order.

## Evidence

All three are verifiable in this repository. Nothing here is supplied testimony.

**1. Serial allocation races across machines.** `docs/contracts/v1.md:87` records it as a known
limitation, names the fix — allocation against the pushed remote rather than the local checkout
— and states it is not built.

Worth being precise about what is and is not already handled, because the Contract's summary is
shorter than the mechanism. `skills/create-brief/SKILL.md:31` computes the next serial from the
directory, and step 2 at `:35` is a collision guard that increments until free, "defensive
against a stale read". That guard closes the single-machine case. It cannot close the
cross-machine one: two checkouts each read their own tree, each pass their own guard, and each
claim the same number. The race is not that the guard is missing. It is that the guard consults
a source that does not know about the other writer.

**2. The ledger is one file with one writer, and nothing says so.** A ledger is
`NNNN-slug/ledger.md`, a single document every phase of a brief appends to.
`skills/start-brief/SKILL.md:54` carries the only multi-user mechanism in the whole toolkit:
commit the ledger to `main` immediately, before any feature branch is cut, "so it's visible on
every machine that pulls."

That is a convention. Nothing enforces it, nothing checks it, and it appears in exactly one
step of one skill. Two people executing two phases of one brief edit the same file on two
branches.

**3. `start-brief` can overwrite a ledger that someone else is holding.**
`docs/briefs/0004-deferral-surfacing/ledger.md:116` records this as complication 8:
`start-brief:26` refuses to proceed only when it finds status `in-progress`. A ledger at
`pending` — written, no phase begun — is unguarded. The entry notes it is a one-line guard that
was deliberately not taken during a vocabulary phase, because smuggling a behaviour change into
a naming change is what `review-pr` exists to catch.

This one has already nearly fired with a single author. During #0003's execution a brief was
found already initiated with an unmerged remote branch that had also modified its ledger, and
re-running `start-brief` would have overwritten it. A human noticed. No mechanism did.

## Change

Four phases. Phase 1 is prose and states all three assumptions where a reader meets them.
Phases 2 to 4 close them, cheapest and most-nearly-fired first.

| Phase | Work |
|---|---|
| 1 — state the assumptions | Write each of the three where its surface is documented: the ledger's single-writer assumption in `docs/briefs/README.md`, the clobber hole beside it, and a sharpening of the Contract's concurrent-filing entry to say what the local collision guard does and does not cover. Prose only. No clause, no check. |
| 2 — the clobber guard | Make `start-brief` refuse to overwrite any ledger it did not just create, not only an `in-progress` one. Whether that guard can be more than advisory is open decision 4, and it may reshape this phase. |
| 3 — ledger write-ownership | Promote the commit-before-branch convention from a step in one skill to a stated rule with an owner: one executor per phase. Decide separately whether it earns a Contract clause. |
| 4 — remote-aware allocation | Allocate the serial against the pushed remote. The fix the Contract has named since v1 and never built. |

Phase 1 precedes the rest because that is the ordering this repo enforces on itself. Phases 2
to 4 are independent of each other and can land in any order once phase 1 is in.

## Settled decisions

- **The Contract is already the multi-user artifact.** No new artifact is needed. This brief is
  about the three record artifacts, which were built for one writer.
- **Optimistic concurrency stays the default.** #0003 settled this and it is not reopened.
  Small bites, frequent commits, and a rebase when someone lands first. Any proposal here that
  imposes coordination cost at the moment of action is wrong by that standard. Note that all
  three fixes are guards or lookups at a moment that already exists — none adds a step.
- **Recording a boundary is a legitimate answer.** Where a fix is not taken, it is named and
  the reason stated. A known boundary is not debt.
- **The prose-then-check ordering binds Contract clauses, not skill behaviour.** Phase 2 is a
  guard in a command, not an invariant, so it does not need a clause first. Phase 3 is where
  the ordering actually bites, because a write-ownership rule is a candidate clause.

## Open decisions

1. **Does the ledger stay one file per brief?** A file per phase removes the concurrent edit
   and scatters the narrative that makes a ledger worth reading. The alternative is one file
   plus a stated ownership rule. Blocks phase 3.
2. **Does write-ownership earn a clause, and in which version?** v1's stated scope is the
   structure of `docs/briefs/` only. A rule about who may write a ledger is a different
   namespace, which means Contract v2 and the first real exercise of the supersession design.
   That may be too much machinery for three sentences of prose. Blocks phase 3.
3. **What does phase 4 consult, and what does it cost?** Allocating against the pushed remote
   means a fetch at filing time. That is a network round-trip in a command that currently works
   offline, which cuts against this project's treatment of external services as optional.
   Whether the answer is "fetch and degrade to local with a warning" or something else is
   undecided. Blocks phase 4.
4. **How is a guard inside a skill verified at all?** This is the sharpest unknown here, and
   it was found while drafting rather than assumed. Phase 2 is described above as "one guard,
   with the tests it has never had" — but `start-brief` is a markdown prompt, not a script.
   The suite names it twice, at `tests/test_hosts.sh:8` and `tests/test_machine_mode.sh:23`,
   and both check only that the file gets installed. Nothing exercises what it instructs.

   So every check this repo owns applies to shell — `install.sh`, the two `tools/` scripts,
   `gather.sh`. The skills, which are where nearly all the process actually lives, are
   unverified by construction. A guard added to a prompt is a sentence an agent may or may not
   follow, and a phase that claims to "close" the clobber hole with one would be claiming more
   than it delivers. The honest options are to move the guard into something executable, to
   state plainly that skill instructions are advisory and unchecked, or to accept that this
   phase produces prose and label it so. Blocks phase 2, and arguably outgrows this brief.
5. **Does phase 2's guard need an escape hatch?** A refusal with no override is a wall the
   first time someone hits it legitimately — resuming their own interrupted work on the same
   machine. A `--force` mirrors the installer's existing vocabulary, but it also gives the
   clobber back to anyone who reaches for it reflexively.

## Non-goals

- **Not peer WIP visibility.** `_drafts/wip-visibility.md` owns that question and must not be
  re-derived here. It is also stale: its settled decision says "the git-visible half comes
  first and is useful alone," and its open decision 2 asks what such a query would cover —
  branch age, open PRs, unmerged refs. `tools/open-briefs.sh`, built in #0004 phase 3, now does
  substantially that. The draft predates it and does not know. Reconciling the two is that
  draft's work, not this one's.
- **Not the second-party review question.** Whether `review-pr`'s do-not-self-clear rule is
  redundant or load-bearing once author and reviewer differ is unanswerable before the team
  arrives, and answering it early would be invention.
- **Not a permissions or ownership model.** Git has one.
- **Not a coordination gate.** See the settled decision on optimistic concurrency.

## Success criteria

- A reader can tell which parts of this toolkit assume a single writer, without reading its
  history.
- Each assumption names its failure, its fix, and whether the fix is built.
- The three fixes are built, or explicitly deferred with a reason recorded where the assumption
  is stated.
- Each behaviour change is verifiable by something other than reading it. What that means for
  a skill is open decision 4, and it may not mean a test.

## A note on the dependency line

`Depends on: #0003, #0004` names both, and both are checked: `tools/validate-briefs.sh:138`
extracts every `#NNNN` on the line, so multiple dependencies are validated rather than merely
tolerated.

The boundary the earlier draft recorded still stands and is not fixed by that. The field cannot
express a dependency on *part* of a brief, which is what a split-out phase always is — this
brief depends on #0004's complication 8, not on #0004's status vocabulary. Nor can it name an
unfiled draft, which is why the relation to `wip-visibility.md` is stated in prose above.
Whether that is an accepted boundary or a gap to close is not this brief's question, but this
brief is an instance of it.
