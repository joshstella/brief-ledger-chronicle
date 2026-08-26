# Closing the single-writer holes before the second writer arrives

**Serial:** #0005 · **Created:** 2026-08-25T12:40:16Z · **Author:** josh.stella@gmail.com · **Depends on:** #0003, #0004

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

The three holes live in this repository. The near-miss under item 3 does not. It is supplied.

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
step of one skill. Two people on two phases of one brief would collide on that file. That is
not the use case this brief now designs for. See settled decisions.

**3. `start-brief` can overwrite a ledger that someone else is holding.**
`docs/briefs/0004-deferral-surfacing/ledger.md:116` records this as complication 8:
`start-brief:26` refuses to proceed only when it finds status `in-progress`. A ledger at
`pending` — written, no phase begun — is unguarded. The entry notes it is a one-line guard that
was deliberately not taken during a vocabulary phase, because smuggling a behaviour change into
a naming change is what `review-pr` exists to catch.

Supplied, and not in #0003's ledger: during that brief's execution a ledger was found
already written, with an unmerged remote branch that had also modified it. Re-running
`start-brief` would have overwritten it. A human noticed. No mechanism did. The hole does
not depend on this story. Complication 8 is enough.

## Change

Four phases. Phase 1 is prose and states all three assumptions where a reader meets them.
Phases 2 to 4 close them, cheapest first.

| Phase | Work |
|---|---|
| 1 — state the assumptions | Write each of the three where its surface is documented: the ledger's single-writer assumption in `docs/briefs/README.md`, the clobber hole beside it, and a sharpening of the Contract's concurrent-filing entry to say what the local collision guard does and does not cover. Prose only. No clause, no check. |
| 2 — the clobber guard | Make `start-brief` refuse to overwrite any ledger it did not just create, not only an `in-progress` one. Whether that guard can be more than advisory is open decision 4, and it may reshape this phase. |
| 3 — ledger write-ownership | State in `docs/briefs/README.md` that one person owns the serial, the ledger stays one file, and commit-before-branch is how that owner makes it visible on their other machines. Not a Contract clause. |
| 4 — remote-aware allocation | **Skipped.** Leave the race. The later merge renumbers. Fetch-then-allocate does not close the gap, and a lock at filing is a coordination step this brief rejected. |

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
  guard in a command, not an invariant, so it does not need a clause first. A write-ownership
  *clause* would be Contract v2. This brief does not add one while ownership is a team
  convention.
- **One person owns a serial.** Starting place: humans scope each brief to one team member.
  That person runs `start-brief` and the later phases. Phases are not a way to split a brief
  across people. Relaxing this later is allowed. Designing the ledger for two executors now
  is not.
- **Assignment is explicit.** A person is handed a serial. Nobody takes work off a pile of
  unblocked briefs. Human diligence is accepted. This brief does not build a work queue, an
  unblocked-pending query as an assignment mechanism, or an assignee field. `Author` is who
  filed the brief. The owner is who runs `start-brief` for that serial. Those can be
  different people. They must not be collapsed into one identity-line field. Once started,
  later phases stay with that owner.
- **Parentage lives in content, not in the serial.** A parent lists its children in a Child
  Briefs table. A child names its parents in `Depends on`. The serial stays a flat identity
  from `create-brief`. Hierarchical numbers cannot express a DAG, fight max+1 allocation, and
  fight `BRIEFS-8`. This is not a phase here. It is a constraint on anything this brief might
  be tempted to add around "who owns which work."

## Open decisions

1. ~~**Does the ledger stay one file per brief?**~~ **Resolved:** yes. One owner, one
   narrative. A file per phase spends readability to move the same hotspot into an index.
   See the ledger.
2. ~~**Does write-ownership earn a clause, and in which version?**~~ **Resolved:** not
   while this is a team convention. Humans scope briefs. A clause would tell other
   programmers they can rely on an ownership protocol. Nobody has been told that.
3. ~~**What does phase 4 consult, and what does it cost?**~~ **Resolved:** consult nothing
   extra. Leave the race. If two branches claim the same serial, the one that reaches `main`
   second renumbers before it merges. Remote-aware read does not close the gap: `create-brief`
   does not publish the serial, so two fetches can still agree on the same next number.
   Building a lock at filing time would be a coordination step this brief already rejected.
   See the ledger.
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
- **Not a Child Briefs convention, and not an unblocked-work query.** A consuming project is
  trying a parent table plus `Depends on` as the map. Filing reserves the serial. Starting
  claims it. `tools/open-briefs.sh` does not walk `Depends on`, so it cannot answer "what can
  start today." That is a status question, and a useful one, but assignment does not wait on
  it. Specific assignment makes a pile-grab query the wrong fix. Reconciling that map with
  the README is not this brief. It must not become a fifth phase.

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

Found in use, and it settles the boundary: a child that must start before its parent finishes
means the parent is still too large. Split the parent. Do not add phase-level `Depends on`.
File and start stay two acts. Filing plus an update to the parent's Child Briefs row is the
reservation for an idea. `create-brief` only guards serials, so two people can still file two
briefs for one idea if that row is not updated in the same change. Specific assignment makes
that rare. It does not make it impossible. Phase 2's clobber guard is what makes the claim at
`start-brief` real for the executor. It does not reserve the idea at filing time.
