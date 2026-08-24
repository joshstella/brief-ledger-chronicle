# Briefs

How work is specified, filed, and tracked in this repository. A **brief** is a
self-contained spec for a unit of work; this directory is where briefs live across their
whole lifecycle.

## Lifecycle

1. **Draft** — authored number-free in `_drafts/`. Unnumbered, unordered, and committed
   to git, so a parked idea is available from any workstation and survives indefinitely.
   Deferring a draft costs nothing and leaves no gap in the sequence.
2. **Filed** — `/create-brief` moves a draft into a serial-numbered folder
   `NNNN-slug/brief.md`. Filing is the one-way door: this is the moment a draft becomes
   committed work and earns its identity.
3. **Executed** — a `ledger.md` joins the folder as the work is carried out, and the
   serial rides into `main` via the PR title (`[#NNNN] …`).

## Layout

```
docs/briefs/
  _drafts/            committed holding area for unnumbered drafts
  NNNN-slug/          one filed brief
    brief.md          the spec (carries the identity line)
    ledger.md         execution record (added on execution)
  README.md           this file
```

## Serials

A serial is a zero-padded four-digit identity handle (`0001`, `0002`, …) on the
**folder**. It is **assigned at filing time by `/create-brief`** — next serial = max in
`docs/briefs/` + 1 — never chosen by the author and never assigned during authoring.
That single point of assignment is what keeps numbers from colliding. The serial encodes
**identity only** — never status or phase.

## The identity line

Each `brief.md` carries one line directly under its H1:

```
**Serial:** #0010 · **Created:** 2026-06-23T14:20:00Z · **Author:** name@org.tld · **Depends on:** #0004
```

- **Serial** — assigned by `/create-brief` at filing.
- **Created** — ISO-8601 UTC, stamped when the draft is written into `_drafts/` (not
  modified-time; git tracks that). It is the staleness cue: an old `Created` means
  re-ground the brief against current code before executing.
- **Author** — a real, routable email, the stable identity key the rest of the stack
  (SSO, git, the tracker) joins on.
- **Depends on** — `#NNNN` or `—`. The only field the author declares; the rest the
  pipeline stamps.

**Correlation IDs.** External identifiers each get their own named field and encode one
thing — never overloaded into the serial or slug. A tracker key is a separate field,
e.g. `· **Jira:** PROJ-1234`, added when wired. The serial stays the internal sequence;
external keys stay external; they reference each other, they don't merge.

## Commands

- **`/init-briefs`** — one-time, idempotent repo setup: creates this structure and these
  READMEs. Run once when adopting the convention in a repo.
- **`/create-brief <draft>`** — files an unnumbered draft into `NNNN-slug/brief.md`,
  assigning the serial and carrying provenance forward. Errors toward `/init-briefs` if
  the structure is absent. One brief per invocation.
- **`/start-brief` / `/next-brief-phase`** — read `NNNN-slug/brief.md`, write the ledger
  to `NNNN-slug/ledger.md`.

## Structural invariants

The rules this layout must satisfy live in **[Contract v1](../contracts/v1.md)**, clauses
`BRIEFS-1` through `BRIEFS-8`. They are stated there and not restated here, so there is one
place to read them and one place to change them.

This file explains the convention. The Contract states it.

## Known limitation — writers outside the pipeline

`/create-brief` is the single point of serial assignment, but nothing *enforces* that it
is the only writer. Any script, installer, or agent that creates a `NNNN-slug/` folder
directly bypasses both the max+1 allocation and the collision guard.

Not hypothetical: this toolkit's own installer did exactly this until 2026-08-21. It
hardcoded `docs/briefs/0001-bootstrap/` and checked whether *that folder* existed rather
than whether *serial `0001` was free*, so every install into a repo that already had
briefs wrote a duplicate `#0001` — deterministically, not as a race. One project carried
the duplicate for six weeks. The fix was to stop writing briefs from the installer at
all: install records are an append-only log, not a unit of work.

If you automate anything that files briefs, route it through `/create-brief`.

## Known limitation — the ledger is an archive, and a bad inbox

A ledger records what a brief is doing. Nothing reads it back. Every command here writes
into `docs/briefs/`; none of them asks what is already sitting there unfinished. So a brief
that stalls stays stalled silently, and the cost of the stall grows in a place the record
never looks.

Not hypothetical: a brief in a consuming project was filed on 2026-06-23, shipped four of
its five phases, and deferred the fifth on 2026-06-25. **The deferral was recorded
correctly, and that is the point.** The ledger named the branch, said "pushed, no PR", gave
the rationale, listed three issues blocking a merge, and specified the resume path. No rule
was broken and no invariant was violated.

Fifty-seven days later it surfaced, because a human happened to ask in an unrelated session
which briefs were open. By then the branch was 248 commits behind `main`, a dry-run merge
conflicted in all three code files it touches, and upstream had added roughly 770 lines to
the two source files the branch also edits. Work that was mergeable on 2026-06-25 needed its
integration rewritten.

Nothing in this convention can see that. The Contract governs folder shape, serials,
identity and dependencies — the things a brief *is*, not the things it is *doing*. A brief
can sit in-progress forever and satisfy every clause. The nearest cue points the wrong way:
`Created` is documented above as the signal to re-ground a brief *before* executing it, and
there is no equivalent for one already in flight. `BRIEFS-8` flags a gap in the serial
sequence; nothing flags a gap in time.

The structural half is sharper than the record-keeping half. A deferred phase parks code on
a branch, and `docs/briefs/` has no concept of branches. The ledger names one in prose,
nothing resolves it, nothing notices it decaying, and deleting the branch leaves the ledger
reading "code on branch" while pointing at nothing.

Until something reads ledgers back, **the check is manual**: ask periodically which briefs
are open, and treat a long-deferred phase as a branch that is quietly getting more expensive.
A known boundary is a legitimate resting place; an unwatched one is not.

The other known boundary, concurrent filing, is recorded in the Contract beside the
clause it threatens.
