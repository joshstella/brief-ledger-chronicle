# Polling peers for invisible work in progress

**Status:** superseded by `record-outgrew-the-reader.md`, 2026-09-07. Not filed, not deferred.

**Created:** 2026-08-21T19:06:20Z · **Author:** josh.stella@gmail.com
**Depends on:** #0003

> This draft is kept because filed briefs point at it. #0005 delegates a scope boundary
> here ("Not peer WIP visibility — `_drafts/wip-visibility.md` owns that question"), and
> #0003 and #0004 cite it for the multi-machine invisibility problem. Deleting it would
> break those references. It is no longer a proposal.

## What it proposed

Generate a peer poll from a Contract's own clauses, so the questions name the exact
surfaces about to be promised. Fire it only when a claim is expensive to unwind —
publishing a Contract version — never as a step in ordinary work.

## Why it was dropped

**The git-visible half is built or planned elsewhere.** Unmerged branches, open PRs, and
stale refs are `open-briefs.sh` today and the state section of
`record-outgrew-the-reader.md` next.

**The poll half is triggered by an event that does not occur.** Publishing a Contract
version has happened once. #0009 then chose to reword v1.1 in place rather than
supersede it, making the trigger rarer still. A mechanism whose precondition is avoided
by design is not worth building.

## What survived, and where it went

**The limit statement**, which was this draft's real contribution:

> Visible to nobody. A local uncommitted change, a decision someone has made but not
> written down, a refactor that exists as an intention. No amount of tooling reaches
> this. It requires asking people.

That is still true. `record-outgrew-the-reader.md` carries it in its Tension, and answers
the reachable part of it with per-contributor declarations in `docs/state/` — which
convert "ask every peer" into "read a directory," without pretending to reach the work
nobody has written down.

**The trigger principle** — that coordination is paid only when a claim is expensive to
unwind, and ordinary work takes the rebase instead — is #0003's optimistic-concurrency
decision, re-affirmed in #0005. It does not depend on this draft.
