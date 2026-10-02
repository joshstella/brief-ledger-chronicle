# The Jira export carries what the brief says, not only where it is

**Serial:** #0018 · **Created:** 2026-10-02T20:49:14Z · **Author:** josh.stella@gmail.com · **Depends on:** #0007

## Ground

`tools/jira-csv.sh` (#0007, phase `d`) writes one brief as a Jira Cloud CSV import. It writes
one Epic row and one Task row per phase. Each row has a Description column. For the Epic, it
holds the path of the brief and the path of the ledger. For a Task, it holds the path of the
ledger.

A PM who reads the board sees a title and a path. To know what the work is, the PM must open
the repository. The board is the PM's reporting surface (#0007, "The claim"). A path is not a
report.

The Epic's Summary field already holds `#<serial> — <title>`. A Task's Summary holds
`#<serial>/<letter> — <label>`. Those are titles, and the README fixes their form. The field
that is free to hold prose is Description.

## The claim

**The Epic's Description carries a summary of the brief. Each Task's Description carries
that phase's description. The paths stay, after the prose.**

The text comes from the record. The export does not write a summary, and it does not
paraphrase. It copies a part of the brief or the ledger that the README names as the
source. If that part is not there, the export says so and falls back to the paths alone. A
missing summary costs a thinner ticket, not a refused export.

## Evidence

All of this is in this repository.

**1. The Description column holds only paths.** `jira-csv.sh` writes `$BRIEF` for the Epic
and `$LEDGER` for each Task. `tests/test_jira_csv.sh` pins that whole row.

**2. No part of a brief is named as its summary.** `## The claim` is in 12 of 17 filed
briefs. #0001 to #0004 have no such section. #0016 opens with `## The finding`. The
README prescribes no section.

**3. No part of a ledger is named as a phase's description.** Paragraphs that begin
`**<id> — <label>.**` are in 8 of 17 ledgers. `blc-start-brief` does not ask for them. A
phase table in `## Change` is more common: 12 of 17 briefs have one, in two shapes, a
numbered `| 1 — the mapping |` row (#0007) and a lettered `` | `a — the move` | `` row
(#0017). The ledger paragraph is chosen anyway, because a re-plan changes the ledger and
leaves the brief's table as it was filed.

**4. A guessed source is the defect #0014 fixed for phase rows.** #0014 made a reader that
cannot find a phase row say so rather than guess. An export that takes "the first paragraph"
when there is no named section repeats that defect in a ticket.

**5. A brief that is already in Jira cannot be exported again.** `jira-csv.sh` refuses a brief
that has a `Jira:` key, because a second import makes a second Epic. So this change reaches
only briefs that are not yet imported. As of filing, no brief has been imported.

## Change

| Phase | Work |
|---|---|
| `a — the sources` | README, "Reporting to a tracker": the brief's summary is its `## The claim` section, and a phase's description is the ledger paragraph that begins `**<id> — <label>.**`. Say what the export does when one is missing. In the import steps, say to leave "Map field value" unticked for Description, because it removes every line break. `blc-start-brief` writes a phase description for each phase it plans. No Contract clause. |
| `b — the export` | `jira-csv.sh` puts the brief summary, then the two paths, in the Epic's Description. It puts each phase's description, then the ledger path, in that Task's Description. The text is converted from markdown to Jira wiki markup on the way. A missing source gives the paths alone and a warning on stderr. Tests: summary present, summary missing, description present and missing per phase, a quote and a comma and a newline inside the prose, each converted construct, and the whole-export comparison updated. |

`a` comes before `b`. `b` reads only what `a` names.

## Tension

The richer the ticket, the more the board looks like the record. #0007 made Jira a report
that drifts after the import. A Description that is a copy of the claim drifts too. When the
brief is revised, the Epic still shows the old claim. Today a stale path is harmless. A stale
summary misinforms. The README must say that the Description is a copy from the import date.

Naming a summary section makes the brief's shape less free. #0014 kept the phase-table shape
free and made the reader say when it could not find a row. This brief takes the same path: the
section is named, it is not required, and the export says when it is missing.

## Settled decisions

- **The Epic's field is Description.** Summary is the Epic's title, and the README fixes its
  form.
- **The text is copied, not written.** No generated or paraphrased summary.
- **The paths stay** in both Descriptions, after the prose.
- **A missing source does not refuse the export.** It warns and writes the paths alone.
- **Still a one-shot CSV.** No live Jira API. #0007's reasons hold.

Resolved 2026-10-02, at filing:

- **The brief's summary is its `## The claim` section, whole.** Not only the bolded first
  paragraph, and not a new `## Summary` section.
- **A phase's description is the ledger paragraph that begins `**<id> — <label>.**`.** The
  ledger is where the plan lives, and a re-plan changes it there. The "Work" cell of the
  brief's phase table is not used.
- **No update path for Epics already in Jira.** No brief has been imported, so there is
  nothing to update.
- **The export converts the markdown that the briefs use to Jira wiki markup.** Jira Cloud's
  CSV importer reads a Description as wiki markup, not markdown ([JRACLOUD-79205][md], closed
  without a fix in 2024). Copied as written, `**bold**` shows stray asterisks and `` `code` ``
  shows its backticks. The export converts bold to `*bold*`, code to `{{code}}`, and
  `[text](url)` to `[text|url]`. Everything else stays as text. The wording does not change,
  so "copied, not written" still holds. The source for this is Atlassian's documentation, not
  an import, so `b` closes only after one import by hand.

[md]: https://jira.atlassian.com/browse/JRACLOUD-79205

## Open decisions

1. **A length limit.** A whole `## The claim` can be long. The longest in this repository is
   about 1,500 characters. Default: no limit in the export. Blocks `b`.

## Non-goals

- **Not a live publisher.** No Jira API call.
- **Not a sync.** A revised brief does not update its Epic.
- **Not generated text.** The export copies the record.
- **Not a required section.** A brief with no summary section is still valid.
- **Not a Contract clause.** `validate-briefs.sh` does not check the new sections.

## Success criteria

- An export of a brief that has the named summary section shows that text, then the two paths,
  in the Epic's Description.
- An export of a phase that has a named description shows that text, then the ledger path, in
  the Task's Description.
- A brief or phase with no named source exports with the paths alone and one warning per
  missing source.
- Prose with quotes, commas, and newlines stays inside one CSV field.
- Bold, code, and links in the copied text show as formatting in Jira, not as markdown
  characters. One import by hand confirms it.
- The README names both sources, says the Description is a copy from the import date, and
  says to leave "Map field value" unticked for Description.
- A new brief started with `blc-start-brief` has a phase description for each phase.
