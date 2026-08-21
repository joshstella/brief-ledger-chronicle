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
