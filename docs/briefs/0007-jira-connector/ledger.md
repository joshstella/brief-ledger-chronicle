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
from `Author`. The Epic key lives on the brief; no phase key is stored at all, per decision 2.
Drops "added when wired". Documentation only — no field is carried, validated, or published by
this phase.

**b — the fields.** `blc-create-brief` carries `Owner:` and an Epic key. Decisions 2 and 6
removed the rest of this phase: no per-phase key needs a home, and nothing validates. What
remains is two optional fields carried from a draft onto the identity line. Absence is
ordinary. No Jira call.

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

## Phase a — what it does

Documentation only. No program, no field is read or written by anything, and the suite is
unchanged at 358 passing. Tests land with the program they pin, and this phase pins none.

**The Manifesto gains the rule, not the feature.** "Treat everything external as optional"
already covered carrying an ID; it did not say which direction data may move. The new bullet
says writing out is allowed and reading in is not, and gives the reason: a record two systems
can write has to be reconciled, and the reconciling becomes the process. Stated as a rule
about trackers in general, so it holds for whatever a later brief integrates.

**The identity line gains two optional fields**, `Owner` and `Jira`, described where the other
four are. `Owner` points at "One person owns a serial", which already existed as a rule with
no field; the field records that rule rather than changing it.

**"Added when wired" is gone.** It was a promise in a document that describes what is, and it
had been there long enough to read as permanent.

**A new section, "Reporting to a tracker"**, states the mapping, both settled decisions, and
the cost of finding by summary — a hand-renamed ticket is not recognised on the next publish.
That cost is stated in the same place as the behaviour, because a reader who meets it will
otherwise file it as a bug.

Review of my own draft caught the summary format written twice in one file: once in the
"Phase ids" table and once in the new section's prose. That is the shape of #0013's defect,
two readers of one rule drifting apart, so the prose points at the table instead.

## Open decisions

The brief carries eight. Their phase references are renumbered to the ids above, and one is
added.

| # | decision | blocks |
|---|---|---|
| 1 | When is the Epic created? Default: Epic at filing, tickets at `blc-start-brief`, transitions whenever the status line changes. | `d` |
| 2 | **Settled 2026-09-30, see below.** Where do phase ticket keys live? | `b` |
| 3 | Jira is down. Confirm: warn, do not block. | `d` |
| 4 | Status map. Default: a small config map, not a hardcoded "In Progress". | `d` |
| 5 | Where auth lives. Env, a gitignored project file, or a CLI. No tokens in git. | `d` |
| 6 | **Settled 2026-09-30, see below.** Contract clause? | `b` |
| 7 | Extend `open-briefs.sh` or add a sibling? | `c` |
| 8 | Which states count as "assigned"? Default: `pending`, `in-progress`, `deferred`. | `c` |
| 9 | **Added by this re-plan.** How does the publisher reach Jira such that a test can substitute for it? Without an answer `d` cannot be written, let alone merged. | `d` |

### Decision 2 is settled: nowhere. A phase ticket is found, not recorded.

The brief offered one answer — a field per phase — and flinched at it in the same sentence.
The flinch was correct, though not for the reason I first wrote down. I argued that a second
parenthetical would break a line two Contract clauses gate on. Review showed that claim is
false twice: `BRIEFS-10` reads frontmatter and fences, not the status line, and both clauses
are `[judgment]` and never block. `docs/briefs/README.md` says so eleven lines below the
section I was writing.

The true objection is the opposite shape and is stronger. `blc_status_phase_entries` splits a
phase entry at the first colon and never reads the parenthetical at all, so a key stored there
would pass every check by being invisible. It would need a new reader before it meant
anything. The phase table has the same cost in a different place: `phase-row.sh` already
carries three table schemas and says in its own comment that it does not parse columns. A key
column needs a reader, and that reader is a fourth schema.

Neither is necessary, because #0009 already made the identity derivable. `docs/briefs/README.md`
pins the Jira summary as `#<serial>/<letter> — <label>`, and its worked example is this brief's
own publisher phase. That string is computable from the ledger with no call to Jira. So the
publisher lists the children of the Epic on the identity line and matches the summary it can
regenerate.

The reason to prefer this is the brief's own claim, not the saved work. "The record stays in
git" sits badly beside a ledger field that only Jira can produce and that BLC cannot rebuild if
it is lost. A derived identity cannot go stale, because there is nothing to keep in sync.

Two costs, both real, and both already inside decision 9. JQL `summary ~` is a text search, so
the lookup must scope to `parent = <Epic>` and then compare the string exactly on the client.
And a PM who renames the summary orphans the ticket — which the brief already answers, because
a hand edit in Jira is stale until the next BLC write. Renaming it back is the stated behaviour.

This changes `a` before `a` is written. The phase row says keys live on the brief *and the
ledger*. They live on the brief only.

### Decision 6 is settled: no Contract clause, and the reason narrows the brief

This is an export, not part of how BLC works. A project that never configures Jira loses
nothing, so nothing here belongs in the document that tells adopters what their record must
look like. A clause is published per version, so there is no way to add one quietly: the
choice is a new Contract version or silence, and silence is right. `validate-briefs.sh` says
nothing about `Jira:` or `Owner:`.

**`Owner:` is not an export field, and saying "export to Jira" hides that.** Phase `c` reads
it off disk and never calls Jira; the brief says so — "`Owner` still works with no Jira." Only
`Jira:` and the publisher are export. `Owner:` is the identity field #0005 named and deferred,
landing here because this is the brief that needed it.

That leaves one silence. A typo in `Owner:` makes phase `c` return an empty list, and the
executor cannot tell "nothing is mine" from "my address is misspelled in that brief". This is
the shape #0014 and #0015 each found: a result that looks like an answer and is not.

**The assignments program reports a malformed `Owner:` on stderr.** It is already reading the
field from every open brief, so the check costs a comparison. It prints and does not gate,
which is what a report owes a reader who may not own the brief that is wrong. Not a Contract
clause, not a new version, and the finding lands in front of the one person looking for it.
This is a `c` obligation; it is written here because it is the reason `b` ships no validator.

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
