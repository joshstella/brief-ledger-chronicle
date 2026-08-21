# Polling peers for invisible work in progress

**Created:** 2026-08-21T19:06:20Z · **Author:** josh.stella@gmail.com
**Depends on:** #0003

> Draft note: unnumbered by design. `create-brief` assigns the serial at filing.

## Ground

A Contract states what consumers may rely on. Publishing one is a commitment made against an
incomplete picture: it can only describe work that is visible. Work that is in flight and
unlanded is *pre-drift* — the Contract is about to be wrong and nothing on the page says so.

This is not hypothetical. During the session that produced #0003, three merged
PRs and two deleted branches were invisible to a second machine until `git fetch --prune` ran.
That is the benign case: the record existed and simply had not been pulled. The malign case is
work that is not in any record yet.

## The default is not to poll

Narrowed after a working session on incentives. Optimistic concurrency is the normal path:
commit in small bites, at least daily, and if someone lands first you rebase. The cost of
moving fast is a merge you pay yourself, not a gate imposed on you, and frequent commits are
what keep that cost small. Asking peers before ordinary work inverts that — it pays a
coordination cost up front to avoid a rebase that was cheap anyway.

So this is not a step in the normal flow. **It fires only when a claim is expensive to
unwind** — publishing a Contract version that others will build against. A Tuesday afternoon
refactor does not qualify. If the answer to "what happens if someone moved first" is "I
rebase," do not send a message to anyone.

## The problem splits in two

1. **Visible to git.** Unmerged branches, open PRs, stale remote-tracking refs, unpushed
   commits on other checkouts. Mechanically answerable, today, solo, with no integration and
   no third-party service.
2. **Visible to nobody.** A local uncommitted change, a decision someone has made but not
   written down, a refactor that exists as an intention. No amount of tooling reaches this. It
   requires asking people, and it only becomes a real cost at team scale.

Only the second needs a message to humans. The first is a query.

## Change

Generate a peer poll **from the Contract's own clauses**, so the questions name the exact
surfaces about to be promised rather than asking an open question nobody answers.

Not "anyone got WIP?" — which is ignored because it is unanswerable — but a message naming the
clauses, the affected surfaces, and a deadline. Because it is derived from the clauses, the
poll cannot drift from what is being promised.

## Settled decisions

- **Generated text, not an integration.** The output is a message the author pastes. No API
  token, no bot, no service dependency. Per the Manifesto's "treat everything external as an
  optional artifact to piggyback on" — no integration is load-bearing, and none requires the
  other tool to exist.
- **Slack is a rendering target, not a requirement.** The same body should paste into email, a
  PR comment, or a standup doc.
- **The git-visible half comes first** and is useful alone. It needs no message to anyone.
- **Polling is the exception, not a stage.** The trigger is an expensive-to-unwind claim, not
  the start of work.

## Open decisions

1. **Whether this is a skill or part of the Contract skill.** Publishing a version and polling
   before publishing may be one action with two steps rather than two commands.
2. **What the git-visible query actually covers.** Branch age, open PRs, and unmerged refs are
   obvious; unpushed work on *other* checkouts is not reachable from one clone at all, which is
   a limit worth stating rather than papering over.
3. **Whether a deadline belongs in the generated text by default.** It makes the poll
   answerable, but a default deadline imposed by a tool is exactly the ceremony this project
   argues against.

## Non-goals

- Not a status-reporting tool. It asks one question, tied to one pending publication.
- Not a standup replacement, and not recurring. It fires when a Contract version is about to
  be published.
- Not a gate. An unanswered poll does not block publishing; it informs it.
- Not a substitute for moving fast. If the work is cheap to redo, skip this entirely and take
  the rebase.
