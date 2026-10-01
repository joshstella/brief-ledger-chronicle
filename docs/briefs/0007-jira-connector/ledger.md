# Ledger — #0007 Jira as a reporting surface, written from BLC

`blc/2 #0007 done a:done(PR#69) b:done(PR#75) c:done(PR#76) d:done(PR#78)`

**Brief:** `docs/briefs/0007-jira-connector/brief.md`
**Started:** 2026-09-30
**Status:** done
**Closed:** 2026-10-01

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the mapping | done (PR#69) | — |
| b | the fields | done (PR#75) | — |
| c | my assignments | done (PR#76) | — |
| d | the publisher | done (PR#78) | — |

**a — the mapping.** `docs/briefs/README.md` and `Manifesto.md`: Jira is optional reporting,
brief maps to Epic, phase maps to ticket, `Owner:` is an optional identity-line field distinct
from `Author`. The Epic key lives on the brief; no phase key is stored at all, per decision 2.
Drops "added when wired". Documentation only — no field is carried, validated, or published by
this phase.

**b — the fields.** Decisions 2 and 6 removed most of this phase: no per-phase key needs a
home, and nothing validates. The `Jira:` carry also already exists, in `blc-create-brief`
step 4. What is left is three small edits to that one skill:

- Carry `Owner:` from the draft when the draft has one, and write nothing when it does not.
  No fallback. `Author` gets one because `Author` is required; `Owner` is not, and the brief
  settled that an omitted `Owner` means `Author` at read time. A fallback would make the
  field always present and quietly delete that decision.
- Move the `Jira:` append to *before* `Depends on`, which today it follows. Phase `a` found
  why: anything after `Depends on` was inside the dependency scan. #0016 has since ended
  `Depends on` at the next `·` in every reader here, so the move no longer fixes a trap in this
  toolkit. It keeps the README's order, and that order is the backstop #0016 kept (its
  decision 5) for a reader elsewhere that still reads greedily. `Owner:` goes before it too.
  It is in step 4.
- Drop "(and, later, `**Jira:** …`)" from the `## Input` bullet at line 20. "Later" is the
  same future tense as "added when wired", which phase `a` removed from the README one file
  away.

No Jira call. Absence of either field stays ordinary.

**c — my assignments.** `list-briefs.sh --owner <email>` lists the briefs assigned to an email
— `Owner`, or `Author` when `Owner` is absent (decision 7). It does not fetch. A skill fetches, then runs it. Tests land with it.

**d — the publisher.** Re-planned on 2026-10-01 as a CSV export; see "d becomes a CSV export"
below. `tools/jira-csv.sh <serial>` prints one brief as a CSV for Jira's importer: an Epic row
and one ticket row per phase. It calls nothing and reads nothing from Jira. Tests land with it.
The label stays "the publisher", because the README's examples cite `#0007/d — the publisher`
and a CSV export still publishes.

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

## Re-plan after #0016, 2026-10-01

Phase `a` merged as PR#69 on 2026-09-30. #0016 then ran and changed three things under the
remaining phases.

**`b`'s reason changed, and its edits did not.** See the `b` row above.

**`c` moves to `list-briefs.sh` (decision 7).** The brief chose between `open-briefs.sh` and a
sibling. Since then `open-briefs.sh` has become a phase-level report of exceptions: it measures
branches and asks the forge. "What is mine" is a question about briefs, not phases.
`list-briefs.sh` already lists every brief with its state and reads the identity line through
#0016's shared reader. An owner filter there adds a flag, not a program, so `install.sh` needs
no new tool entry. `c` still needs a skill that fetches and then runs the query. Whether that
skill is a process skill, which `install.sh` and three tests list by name, is decided in `c`.

**`d` waits for a Jira tenant, by choice on 2026-10-01.** Five of its decisions are open (1, 3,
4, 5 and 9), and no Jira tenant is reachable. The re-plan also found a possible blocker the brief
does not name. Jira Cloud's API assigns an issue by `accountId`, not by email. A search by email
can return no match when the user's profile hides the email. So "set the Epic assignee from
`Owner`" may not be possible as written. This is from Atlassian's API, not from a test, because
no tenant is reachable. A publisher built now would be proven only against a stub.

`d` stays `pending`, not `deferred`. `deferred` means code parked on a branch, and `d` has no
code. `open-briefs.sh` reads a `deferred` phase and would report "no branch recorded" on every
run. The brief stays `in-progress` while `d` waits.

## d becomes a CSV export, 2026-10-01

Earlier the same day, `d` was left `pending` until a Jira tenant existed. It was then re-planned
as a CSV file for Jira's own importer. Atlassian's documentation for Jira Cloud, read on
2026-10-01, gives three facts that decide the shape:

- **One file can hold the hierarchy.** Each row has a `Work item ID`. A child gives its
  parent's ID in a `Parent` column, and a `Work type` column says Epic or Task. Parents come
  before children.
- **The importer sets the assignee from an email.** This removes the `accountId` problem above,
  for this path only.
- **A second import duplicates every row** unless each row carries a `Work item key`. Decision 2
  stores no phase key, so the export is a one-shot seed (decision 11).

Four open decisions dissolve, because the export calls nothing: 1, 3, 5 and 9. Decision 4 is
settled by the importer's own value mapping.

**What this does not deliver.** The brief's success criteria say that a ledger status change
updates Jira, and that the next write from BLC restores a hand edit on the board. A CSV import
does neither. After the first import, the board is not updated from here. A live publisher
would close that gap, and it would bring back every decision dissolved here. It is not planned.

The export reads each phase's label from the ledger's phase table, because the README fixes the
ticket summary as `#<serial>/<letter> — <label>`. No reader of labels exists, and one is added
to `tools/lib/phase-row.sh`. The rule that picks a brief's assignee moves from `list-briefs.sh`
into `tools/lib/identity-line.sh`, so the query and the export cannot disagree about whose a
brief is.

## Phase a — what it does

Documentation, and three tests. No program ships, and no field is read or written by anything.
The suite goes from 358 to 362 passing. Why a documentation phase carries tests at all is
below.

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
"Phase ids" table and once in the new section's prose. One rule written in two places is the
writer-side seam #0013 found inside `blc-start-brief`, so the prose points at the table
instead.

**Three tests ship with this phase, which is not a contradiction.** The phase pins no program,
but it makes one claim about a program that already ships: that `validate-briefs.sh` says
nothing about `Jira:` or `Owner:`. That sentence is true today by accident, and a later clause
could falsify it in silence. A fixture carrying `Owner: not-an-email` and `Jira: !!!` and
asserting zero defects and zero judgments converts it into a pinned fact. The fixture carries
a positive control, because a fixture that quietly lost its fields would assert nothing.

**Writing that test found a trap.** The dependency parse reads everything after `Depends on:`
and treats any `#NNNN` as a dependency, whatever field it sits in. `PROJ-1234` carries no `#`,
which is why the trap holds until someone writes a reference the ordinary way.

It has a loud half and a quiet one. A serial that does not exist is a `[defect]` that blocks.
A serial that does exist is reported by nothing: the record gains an edge nobody declared,
and `list-briefs.sh` does not show it, because that tool stops reading at the next `·` and the
validator does not. Two readers of one field, disagreeing. That is the class #0014 named in
its finding 7, where `open-briefs.sh` and `list-briefs.sh` disagreed about where the status
line lives. Here the pair is `list-briefs.sh` and the validator, and the field is
`Depends on`.

The quiet half is the one worth a test, and it is proved by contrast rather than by a clean
run: removing the brief it names turns the same fixture into a dangling dependency. A clean
run alone cannot tell a swallowed reference from an ignored one.

Five mutations, six kills: teaching the validator to check `Owner` shape, stopping the
dependency scan at the next separator, letting it read the whole identity line, and dropping
first the `Owner` and then the `Jira` value from the fixture. Narrowing the scan kills two of
the three trap tests, which is correct — both describe what the wide scan does.

**The settled decisions were nearly invisible to `blc-chronicle`.** Its `gather.sh` reads
`###` headings only inside a `## Big decisions` section, and both of mine sat under
`## Open decisions`. The chronicle would have reported no forks for the phase whose whole
payload is two decisions. They are moved. This is not a new habit: eight of the fifteen ledgers
here have no `## Big decisions` section, so the same silence covers most of this repository's
record. Closing that is not this brief's work, and it is named here so it is not lost.

## Phase b — what it does

`blc-create-brief` writes the identity line as `Serial · Created · Author · Owner · Jira ·
Depends on`. It writes `Owner` and `Jira` only when the draft carries them, and adds neither. A draft's own `Owner` or `Jira` line is consumed into the identity line, the same as
its `Created` and `Author` line. The `## Input` section no longer says "later".

**Proof.** The skill is prose, and nothing runs it. The order of its template is still a fact a
test can read. `test_identity_line_create_brief_writes_the_readme_order` reads the template's
labels in order and expects exactly those six. Two mutants were run, and both were killed:
`Jira` after `Depends on`, and no `Owner`. The test pins the order only. The rule that `Owner`
is written only when the draft has one is prose, and nothing tests it.

## Phase c — what it does

`tools/list-briefs.sh --owner <email>` prints the brief table with only the briefs assigned to
that email that are not `done` or `skipped` (decisions 7 and 8). Assigned means `Owner`, or
`Author` when the brief has no `Owner`. The two are compared without regard to case. It reads
both through #0016's shared reader. With nothing assigned, it prints the dash row, as for an
empty tree. `--owner` with `--tsv` is an error, because the chronicle's scan lists every brief.
Without `--owner`, the output is byte-identical to the output before this phase.

An `Owner` that is present and not one email is reported on stderr, and the brief is assigned
to no one. This covers a blank `Owner`, two emails in one field, and an address in backticks,
quotes or angle brackets. It does not fall back to `Author`, because `Owner` was written to say
the filer is not the executor. The `Author` it falls back to gets the same check, because
`validate-briefs.sh` does not anchor its `Author` check. Only unfinished briefs are checked.
The exit status stays 0 (decision 6).

The new utility skill `blc-my-briefs` fetches and then runs the query. The query reads the
working tree, so a fetch alone changes nothing it sees. On the default branch the skill runs
`git pull --ff-only`. On any other branch it does not pull, and it says how many commits the
checkout is behind `origin/<default>`. Chosen on 2026-10-01. A utility skill is found by glob,
so `install.sh` needs no edit. `README.md` and the two test lists of utility skills name it.

**Proof.** `tests/test_list_briefs.sh` gains 13 tests: owner, fallback, an `Owner` that takes
the brief away from its `Author`, case, unfinished states including `planned` and a `blc/1`
`done(commit …)`, a malformed `Owner`, an `Owner` in markup, a malformed `Author`, no report on
a finished brief, the unfiltered table, the dash row, argument errors, and no fetch. Seventeen
mutants were run, and all were killed. One mutant survived at first: an email check with no end
anchor accepted `me@x.org, you@x.org`, which then matched no one and reported nothing. The
two-email fixture was added. Review then found the same silence for an address in backticks and
for the `Author` fallback. Both are fixed, with a test each. The skill is prose, and nothing
tests its fetch or pull.

**Known and left as they are**, by choice on 2026-10-01, after review:

- An argument after the briefs directory is ignored. `list-briefs.sh docs/briefs --owner me@x.org`
  prints every brief. `main` already ignored `docs/briefs --tsv` the same way.
- `--owner --tsv` takes `--tsv` as the email and prints a dash row.
- A brief with no identity line, or no `Author`, is dropped from `--owner` without a message.
  `validate-briefs.sh` reports both as `BRIEFS-5` defects.
- The loop's output is captured with `$( )`, so an error inside the loop no longer stops the
  script.
- `is_closed` uses backslash escapes in a bracket expression. Only bash 5.2 was tested.
- In the skill, the behind-count fails when `origin/<default>` does not exist, and every
  failed `pull --ff-only` is called a divergence, though a dirty tree or a branch with no
  upstream also fails it.

## Phase d — what it does

`tools/jira-csv.sh <serial>` writes one brief as a Jira Cloud CSV import, to stdout. The first
row is the Epic, with the summary `#<serial> — <title>`. Then each phase is a `Task` with the
summary `#<serial>/<letter> — <label>`, in status-line order. Each Task gives the Epic's
`Work item ID` as its `Parent`. The assignee is the brief's, by the shared rule. The Status
column holds the BLC state without its pointer, so the importer maps one value per state.
`install.sh` ships the script. "Reporting to a tracker" in the README now says how to import
the file, and what drifts after the import.

The script refuses, with exit 1 and nothing on stdout, a brief that it cannot export whole.
That is a brief with a `Jira:` key, an assignee that is not one email, a `blc/1` ledger, a
numbered phase, a status-line entry that is not a phase, or a phase label that cannot be read.
A blank `Jira:` or `—` is read as "not imported yet".

Two shared readers changed. `blc_identity_assignee` in `tools/lib/identity-line.sh` now holds
the `Owner`-else-`Author` rule and its email check. `list-briefs.sh --owner` calls it, and its
output is unchanged. `blc_phase_label` in `tools/lib/phase-row.sh` reads a label from the two
row shapes that `blc-start-brief` writes. It returns 2 when two rows could be the phase, so the
export refuses rather than picks one. It accepts any spacing before the em dash, because the
shared row matcher does. A mutant found the first version refused `a—label`, a row that the
gate counts as phase `a`. It returns 1 when the cell after the id is a state, such as `done`
or `done (PR#70)`. A table with no label column puts the status there.

**Review found two defects, and both are fixed.** The Epic row kept its pointer, so `#0008`
exported its Epic as `done(PR#45)`. The README said each state is one value to map, and for
Epics that was false. The whole-export test used an Epic state with no pointer, so neither the
tests nor the mutants saw it. The label reader also took a status cell as a label on a table
with no label column, and the export named a ticket `#0001/a — done`.

**Proof.** `tests/test_jira_csv.sh` has 19 tests. One compares a whole export: phases out of
table order, a skipped phase, and pointers to drop. The others cover quoting, the serial
spellings, the `Author` fallback, the Epic pointer, an Epic with no phases, each refusal, the
load list, and a run from a fixture install. `test_contract_ship.sh` installs the script and
runs it in a fresh target. The bootstrap-walk test in `test_clauses.sh` now covers it. The two
readers have 11 new tests and one new assertion in `test_list_briefs.sh`. The suite goes to
468 passing. Mutants: 27 of 27 on the script, and 27 of 28 on the readers. The survivor
rewrites a branch that the matcher never lets the reader reach.

Run against this repository, the script exports `#0007`, `#0008` and `#0010` to `#0016`. It
refuses `#0001` to `#0006`, which are `blc/1`. It refuses `#0009`, because a second table in
that ledger has a cell that also matches phase `a`.

**Known and left as they are:**

- No file from this script has been imported into a real Jira. The column names and the
  import steps come from Atlassian's documentation, read on 2026-10-01.
- Two candidate rows are refused even when they give the same label, as in `#0009`.
- Lines end in LF, not the CRLF of RFC 4180.

Also left as they are, by choice on 2026-10-01, after review:

- A repeated phase id, as in `a:done a:pending`, exports two Tasks with one summary.
  `validate-briefs.sh` does not report it either.
- The serial on the status line is not compared with the folder's serial.
- The title is read with `sed | head -1` under `pipefail`. A brief with very many `# ` lines
  can make the script exit 141 with no message. Nothing reaches stdout.
- The script header lists only some of the refusals.
- The Description holds the path as the caller typed it. A trailing slash on `BRIEFS_DIR`
  gives `//`, and an absolute `BRIEFS_DIR` puts a local path into Jira.
- A `\|` inside a label cell cuts the label short.

## Open decisions

The brief carries eight. Their phase references are renumbered to the ids above, and one is
added.

| # | decision | blocks |
|---|---|---|
| 1 | **Dissolved 2026-10-01.** The Epic and its tickets are created when a person imports the CSV. | `d` |
| 2 | **Settled 2026-09-30, see below.** Where do phase ticket keys live? | `b` |
| 3 | **Dissolved 2026-10-01.** The export does not contact Jira. | `d` |
| 4 | **Settled 2026-10-01.** The CSV carries BLC's phase states. Jira's importer maps each value to a status. | `d` |
| 5 | **Dissolved 2026-10-01.** The person who imports is logged in to Jira. The export needs no credentials. | `d` |
| 6 | **Settled 2026-09-30, see below.** Contract clause? | `b` |
| 7 | **Settled 2026-10-01: neither.** `list-briefs.sh --owner <email>`. | `c` |
| 8 | **Settled 2026-10-01.** Every brief that is not `done` or `skipped`. This includes `planned` (no ledger) and `no-line`, which the brief's default did not name. | `c` |
| 9 | **Dissolved 2026-10-01.** The export writes a file. A test reads the file. | `d` |
| 10 | **Settled 2026-10-01.** One run exports one brief, named by its serial. | `d` |
| 11 | **Settled 2026-10-01.** A brief whose identity line has `Jira:` is not exported, because it was already imported and a second import duplicates every row. | `d` |
| 12 | **Settled 2026-10-01.** The Epic summary is `#<serial> — <title>`. | `d` |
| 13 | **Settled 2026-10-01.** A brief whose assignee is not one email is not exported. An Epic with no assignee would import without a message. | `d` |
| 14 | **Settled 2026-10-01.** A skipped phase is exported, with Status `skipped`. The Epic shows the whole plan, and the importer mapping decides what `skipped` becomes. | `d` |
| 15 | **Settled 2026-10-01.** A phase is a `Task`. Every Jira Cloud project template has that work type. | `d` |
| 16 | **Settled 2026-10-01.** The export writes to stdout. The person who runs it redirects the output to a file. | `d` |
| 17 | **Settled 2026-10-01.** A `blc/2` brief whose status line names no phase exports as an Epic with no Tasks. A planned brief is still a real Epic. | `d` |

## Big decisions

Settled here, and each one changed a later phase. The table above keeps what is still open.

### Decision 2 is settled: nowhere. A phase ticket is found, not recorded.

The brief offered one answer — a field per phase — and flinched at it in the same sentence.
The flinch was correct, though not for the reason I first wrote down. I argued that a second
parenthetical would break a line two Contract clauses gate on. Review showed that claim is
false twice: `BRIEFS-10` reads frontmatter and fences, not the status line, and both clauses
are `[judgment]` and never block. `docs/briefs/README.md` says so eleven lines below the
section I was writing.

The true objection is the opposite shape and is stronger. `blc_status_phase_entries` splits a
phase entry at the first colon and never reads the parenthetical, so a key stored there passes
every clause. It does not pass unnoticed, though, and this took four review rounds to state
correctly. `open-briefs.sh` reads the parenthetical and treats the first field that is not a
PR or a commit as a branch, so position decides the damage. All three shapes were run:

| pointer | what `open-briefs.sh` does |
|---|---|
| `a:in-progress(PROJ-12,brief/…)` | reports a branch that does not exist, and measures nothing |
| `a:in-progress(brief/…,PROJ-12)` | drops the key with no trace |
| `a:done(PROJ-56)` | never parses the pointer |

The table covers the shapes where a branch exists. The first is the loud failure and the
second is the normal one, because an `in-progress` phase normally carries its branch — a
convention, not a check. `open-briefs.sh` has its own message for a phase that carries none,
and a key alone in the pointer is that fourth shape.

Neither of the first two is a reader of a key, and the first is worse than silence: the false
finding replaces the branch-distance measurement the tool exists to produce.

The phase table has the same cost in a quieter form: `phase-row.sh` already carries three
table schemas and says in its own comment that it does not parse columns. A key column needs
a reader, and that reader is a fourth schema.

Neither is necessary, because #0009 already made the identity derivable. `docs/briefs/README.md`
pins the Jira summary as `#<serial>/<letter> — <label>`. That string is computable from the
ledger with no call to Jira. So the publisher lists the children of the Epic on the identity
line and matches the summary it can regenerate.

**This closes #0009's one surviving open decision.** #0009 chose the summary format and left
it carried rather than resolved, recording that it "binds #0007". Settling decision 2 by
depending on that format is what binds it. The dependency also made #0009's worked examples
wrong: they were written when #0007 had five numbered phases and the publisher was `c`, and
the re-plan above moved the publisher to `d`. Five example cells in "Phase ids" named a phase
that is now "my assignments". They are corrected in `docs/briefs/README.md`, because decision
2 makes that table the one place the format is written, and an example there that contradicts
the ledger is the drift the citation was meant to avoid.

#0009's own brief and ledger still say `#0007/b`. They are not corrected: they record what was
true when they were written, which is what a ledger is for.

The reason to prefer this is the brief's own claim, not the saved work. "The record stays in
git" sits badly beside a ledger field that only Jira can produce and that BLC cannot rebuild if
it is lost. A derived identity is recomputed from the record instead of stored beside it.

Three costs, all real. JQL `summary ~` is a text search, so the lookup must scope to
`parent = <Epic>` and then compare the string exactly on the client. That one sits inside
decision 9. A PM who renames the summary orphans the ticket, which the brief already answers:
a hand edit in Jira is stale until the next write, and renaming it back is the stated
behaviour.

The third was missed on the first pass and is the one that bites. **The label is part of the
summary, so it is a sync surface.** Rename a phase label in the ledger and every ticket for
that phase orphans, with no hand edit on the board at all. I had written that a derived
identity "cannot go stale, because there is nothing to keep in sync". That is false: the
ledger is what the tracker is matched against, and the ledger is editable. The claim is
removed and the cost is stated in the README beside the hand-rename cost.

This does not overturn the decision. A stored key has the same failure and a worse one — it
also goes stale when the record is copied, rebased, or hand-repaired, and it cannot be
recomputed. A derived identity at least regenerates from the record that is authoritative.

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
`Jira:` and the publisher are export. `Owner:` is the field #0005 refused. #0005 named the
owner role and deliberately left the field out, to keep this toolkit from becoming a pickup
queue. This brief takes it as correlation rather than as a queue, which its own Tension
section states.

That leaves one silence. A typo in `Owner:` makes phase `c` return an empty list, and the
executor cannot tell "nothing is mine" from "my address is misspelled in that brief". This is
the shape #0014 and #0015 each found: a result that looks like an answer and is not.

**The assignments query reports a malformed `Owner:` on stderr.** It is already reading the
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
