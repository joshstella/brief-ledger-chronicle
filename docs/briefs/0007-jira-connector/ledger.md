# Ledger — #0007 Jira as a reporting surface, written from BLC

`blc/2 #0007 in-progress a:in-progress(brief/0007-a-the-mapping) b:pending c:pending d:pending`

**Brief:** `docs/briefs/0007-jira-connector/brief.md`
**Started:** 2026-09-30
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the mapping | in-progress | `brief/0007-a-the-mapping` |
| b | the fields | pending | — |
| c | my assignments | pending | — |
| d | the publisher | pending | — |

**a — the mapping.** `docs/briefs/README.md` and `Manifesto.md`: Jira is optional reporting,
brief maps to Epic, phase maps to ticket, `Owner:` is an optional identity-line field distinct
from `Author`. Keys live on the brief and the ledger, never inside the serial. Drops "added
when wired". Documentation only — no field is carried, validated, or published by this phase.

**b — the fields.** `blc-create-brief` carries `Owner:` and an Epic key; `blc-start-brief` and
`blc-next-brief-phase` grow a place for per-phase ticket keys. Present values are shape-checked;
absence is ordinary. No Jira call.

**c — my assignments.** A program that lists open briefs for an email — `Owner`, or `Author`
when `Owner` is absent. It does not fetch. A skill fetches, then runs it. Tests land with it.

**d — the publisher.** When Jira is configured, creates the Epic and the phase tickets, sets the
Epic assignee from `Owner`, and transitions on a ledger status change. Unconfigured, it exits
zero and writes nothing. It never reads Jira to update a brief or a ledger. Tests land with it.

## Dependency structure

Strict chain for `a → b`. `c` and `d` both depend on `b` and are independent of each other, so
they can run as parallel tracks once `b` lands.

`c` is deliberately ahead of `d`, which reverses the brief's order. `c` delivers the whole
"what is mine after a fetch" capability with no Jira dependency at all and is testable today.
`d` is the phase that can stall — on a tenant, on auth, on a design question nobody has
answered yet. Building the phase that depends on nothing first means a stall in `d` costs
nothing already built.

## Re-plan against the repository, 2026-09-30

The brief was filed 2026-09-07 and eight briefs have landed since. Four things changed under it.

**The brief is written in a vocabulary the repository no longer uses.** It says `blc/1` three
times, including in the publisher's trigger — "transitions whenever `blc/1` changes". That
schema was replaced by `blc/2`, whose phase indexes are letters rather than numbers. The brief
cites Contract v1.1; v1.2 is current. The skills were renamed to `blc-*` in #0010. The phases
are numbered 1–5 and the convention is now letters. None of this changes what the brief wants.
All of it changes what the phases are allowed to say, and the publisher's trigger is defined in
terms of a status line that no longer exists.

**Phase 5 contradicts the brief's own sentence and the repository's gate.** The brief says
"Tests land with the program they pin" and then lists "5 — the check" as a separate phase.
`blc-review-pr` treats merge-bound code without tests as a blocking finding, so the publisher
and the query could not merge as written, and phase 5 would be writing tests for code that had
already shipped untested. Phase 5 is dissolved into `c` and `d`, which is what the brief's own
sentence asks for.

**The publisher has no testable seam, and that is a ninth open decision the brief never made.**
There is no Jira tenant here, no HTTP client anywhere in `tools/`, and no network in the suite.
This repository's standard of proof is mutation testing. Unless the publisher reaches Jira
through something a test can substitute — a configurable command rather than a hardcoded client
— `d` is not blocked, it is unbuildable. That is a harder blocker than the five decisions
already listed against it, and it is recorded below as decision 9.

**Two surfaces the brief does not mention.** `install.sh` carries a fixed roster of shipped
tools, a prune list, a summary block and a skill roster, each covered by tests; two new programs
mean coordinated edits in four places. And `Owner:` on the identity line lands where
`validate-briefs.sh` already decides shape, so open decision 6 now has a precedent it lacked
when written: #0015 established that a new check ships `[judgment]` and that promotion to
`[defect]` has three stated criteria, one of which nothing in this repository currently meets.

## Open decisions

The brief carries eight. Their phase references are renumbered to the ids above, and one is
added.

| # | decision | blocks |
|---|---|---|
| 1 | When is the Epic created? Default: Epic at filing, tickets at `blc-start-brief`, transitions whenever the status line changes. | `d` |
| 2 | Where do phase ticket keys live? The identity line holds Epic and Owner; phase keys need a field per phase, and the status line is already dense. | `b` |
| 3 | Jira is down. Confirm: warn, do not block. | `d` |
| 4 | Status map. Default: a small config map, not a hardcoded "In Progress". | `d` |
| 5 | Where auth lives. Env, a gitignored project file, or a CLI. No tokens in git. | `d` |
| 6 | Contract clause? Default: no new version; validate shape when `Jira:` or `Owner:` is present. | `b` |
| 7 | Extend `open-briefs.sh` or add a sibling? | `c` |
| 8 | Which states count as "assigned"? Default: `pending`, `in-progress`, `deferred`. | `c` |
| 9 | **Added by this re-plan.** How does the publisher reach Jira such that a test can substitute for it? Without an answer `d` cannot be written, let alone merged. | `d` |

Nothing blocks `a`. Decision 2 must be settled before `b` is planned in detail, because a field
per phase is a change to the phase table and possibly to the status line, which is the artifact
#0014 and #0015 spent two briefs making machine-readable.

## Complications

**The status line is a published, tested artifact now.** `blc/2` is parsed by
`tools/lib/status-line.sh` and `tools/lib/phase-row.sh`, decided by `BRIEFS-9` and `BRIEFS-10`,
and covered by tests that run under four awk implementations. Decision 2 — where per-phase
ticket keys live — is therefore not a formatting choice. Any answer that widens the status line
changes a parser two briefs were spent hardening.

**`Owner:` is a new identity-line field, and the identity line is Contract territory.** Adding
it means deciding whether its absence, its presence, or its shape is anything the validator
says a word about. The brief's default is "validate shape when present". That is a new check,
and a new check ships `[judgment]`.

**A program that filters by email touches the only personal data this toolkit records.** The
author email is already on every identity line, so `c` adds no new exposure. It does make the
record queryable by person for the first time, which is a different thing from recording it.

**No Jira tenant is reachable from this repository or its CI.** Whatever decision 9 produces,
`d`'s tests will assert against a substitute, and the first real Jira call will happen on
someone's machine outside the suite. That gap should be stated in `d` rather than discovered.
