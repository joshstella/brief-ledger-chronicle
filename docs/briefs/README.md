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

## Ledger status

One vocabulary, used at both levels — for the brief as a whole and for each phase in it.
Five states, and no others:

| state | means | carries |
|---|---|---|
| `pending` | it exists and has a place in the sequence; no real progress | — |
| `in-progress` | a branch exists | the branch, always; the PR once there is one |
| `deferred` | parked on purpose, and someone said why | branch and PR as above, plus a reason |
| `done` | done | the PR, or a commit where there is no forge |
| `skipped` | not being done | a reason |

**One person owns a serial.** A team member is given the brief. That person runs
`start-brief` and the later phases. Phases are that person's sequence, not a way to split
the brief across people. `Author` on the identity line is who filed. The owner is who
executes. Those can be different people. They are not two fields to merge.

This is a team convention, not a Contract clause. Nothing checks it. Relaxing it later is
allowed. Designing the ledger for two executors on one serial is not the use case.

The ledger stays **one file** per brief, `NNNN-slug/ledger.md`. One owner, one narrative.
`start-brief` commits that file to `main` before any feature branch is cut so the owner
sees it on every machine that pulls.

**`in-progress` names its branch.** That is what makes it the only state anything can
interrogate: whether the branch still exists, whether a PR was ever opened, how far `main`
has moved since. A branch named in prose is not resolvable; a branch in the status field is.
Backfill the PR number when the PR opens — a phase row left reading `PR #TBD` is the
failure this convention is trying to avoid, in miniature.

**`done` points at a PR or a commit, not a branch,** because the branch is usually deleted by
then. A commit is allowed so the vocabulary works with no forge at all.

**If a reason was given, it is `deferred`.** Both `in-progress` and `deferred` fit a parked
branch, so the tie is broken by rule rather than by mood on the day.

**Deferring does not stop the branch rotting.** Saying why you parked something lowers the
noise it should make; it does not exempt it from going stale. See the known limitation below
for what that cost looked like when it was measured.

### The status line

Every ledger opens with one line under its title, so a scan costs a line instead of a table:

```
`blc/1 #0003 done 1:done(PR#9) 2:done(PR#10) 3:skipped 4:done(PR#11)`
```

`blc/1` is the schema version. The line restates what the phase table says, deliberately: a
reader or a tool gets the whole state without parsing prose. **Redundancy has a price** — a
stale line is worse than no line, because a cheap scan trusts it and stops looking. Update it
in the same edit that changes a status, never separately.

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

`tools/open-briefs.sh` now reads ledgers back. It lists every `in-progress` and `deferred`
phase, resolves the branch each one names, and reports how far the trunk has moved since —
plus any ledger whose status line disagrees with its phase table. It reports and never gates,
because a long deferral is often the right call and the point is to surface it, not forbid it.

**What it does not do is run itself.** The incident above surfaced because a human asked. A
query nobody invokes buys exactly as much as no query. Until something calls it on a cadence,
**the check is still manual** — run it periodically, and treat a long-deferred phase as a
branch that is quietly getting more expensive. A known boundary is a legitimate resting
place; an unwatched one is not.

The other known boundary, concurrent filing, is recorded in the Contract beside the
clause it threatens. If two branches claim the same serial, the second to reach `main`
renumbers. Fetching first does not prevent that.

## Known limitation — one ledger, one owner, unchecked

The convention is stated above under Ledger status: one person owns the serial, the ledger
is one file, and that file is committed to `main` before a feature branch so the owner
sees it on their other machines.

Nothing enforces any of that. An agent that skips the commit, or a second person who runs
`next-brief-phase` on a serial they were not given, is not caught. Git will merge or
conflict if two branches edit the same file. This toolkit will not notice until then.

Two executors on one serial is out of scope for now. The remaining cost for the intended
use is one owner on two machines — the clobber stop and concurrent filing — not a missing
file-per-phase layout.

This is not a Contract clause. No consumer has been told they can rely on an ownership
protocol.

## Known limitation — start-brief can overwrite a ledger

`start-brief` is a markdown prompt. It now tells the agent to stop when *any* ledger file
already exists, not only one with status `in-progress`, and to overwrite only after the
user confirms a restart. That is the instruction. It is not a check.

Found 2026-08-24 in this toolkit's own `start-brief`. Unifying the status vocabulary put
`pending` and `in-progress` in one set. Only `in-progress` was guarded. The hole is older
than that vocabulary. The previous word, `initiated`, had the same gap.

The remaining hole is the same class as every other skill instruction: an agent that skips
the stop is indistinguishable from one that followed it, except by reading the ledger
afterwards. The test suite asserts that `start-brief` is installed. It does not assert
that this stop ran.
