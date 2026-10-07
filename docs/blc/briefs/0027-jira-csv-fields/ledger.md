# Ledger — #0027 The export that omits the fields Jira expects

`blc/2 #0027 done a:done(PR#123)`

**Brief:** `docs/blc/briefs/0027-jira-csv-fields/brief.md`
**Started:** 2026-10-07
**Status:** done

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the columns Jira expects | done (PR#123) | `brief/0027-a-the-columns-jira-expects` |

**a — the columns Jira expects.** `tools/jira-csv.sh` emits seven columns. Feedback from use
names five more. This phase adds `Priority`, `Reporter`, `Due Date`, `Labels` and `Components`,
and puts the header in the order the feedback gives. Three of the five ship empty because the
record holds nothing for them. Two are derived: `Reporter` from `Author`, and `Labels` from the
serial.

## Dependency structure

One phase. Every decision below is settled before it starts, and all five columns are written by
the same two `csv_row` calls — splitting them would mean touching one line twice.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | Priority, Due Date and Components with no source → **ship as empty columns** | a |
| 2 | `Work type` or `Issue Type` → **`Work type` stays** | a |
| 3 | What `Labels` carries → **the serial, `blc-NNNN`** | a |
| 4 | Whether `Reporter` is added → **yes, from `Author`** | a |
| 5 | Column order → **the feedback's order, with the three columns it omits kept** | a |

**1 — empty, not defaulted.** The record holds no priority, no due date and no component. A
default would put declared data in a file whose every other column is derived, and once it is in
Jira nothing distinguishes the two. The column is present, which is what the feedback asks for.
The value is absent, which is what the record supports. A person fills it in Jira, where that
data belongs.

**2 — `Work type` stays.** Atlassian renamed this field in Jira Cloud, and #0007 chose the
current name deliberately. `Issue Type` is the Server and Data Center name. The importer maps by
a screen that accepts either, so this is naming, not function.

**3 — `Labels` carries the serial.** Unlike Priority and Due Date, this one can be derived. One
label of the form `blc-0027` on the Epic and on every phase Task makes the whole import findable
afterwards with one JQL term. The phase letter is deliberately not added: a label per phase
fragments the search this exists to make possible.

**4 — `Reporter` is `Author`.** `Assignee` is already `Owner`, or `Author` when there is no
`Owner`. So on a brief with no `Owner` the two columns hold the same email. That is accurate
rather than a defect — one person both filed and owns it — and the column has to be derivable
from the identity line or it would be the fourth empty one.

**5 — the feedback's order.** The importer maps by header name, so order serves the human reading
the file. Three existing columns are in neither list and all three must stay. `Work item ID` and
`Parent` carry the Epic-to-Task link inside one file (#0007), and go directly after `Work type`,
which is the other column describing the row's shape rather than its content. `Status` carries
the BLC state and goes last.

> *Corrected during phase `a`.* The header first written here had eleven columns and omitted
> `Status`. The export has always emitted it; the brief's evidence section counted the seven
> existing columns and accounted for six. Had the ledger been followed as written, the state of
> every brief and phase would have been dropped from the import to add five empty columns.

The resulting header:

```
"Summary","Work type","Work item ID","Parent","Description","Priority","Assignee","Reporter","Due Date","Labels","Components","Status"
```

**A known cost of this order.** `Description` moves from last to fifth, and it holds whole
paragraphs. A row is now much harder to read by eye, because the short fields sit behind a long
one. The feedback's order was chosen with this stated.

## Out of scope, recorded

**10 of 26 briefs have no `## The claim`**, so their Epic imports with a file path as the whole
Description. Every brief since #0024 is in that set, because they were filed from `_drafts/` and
the draft format has no such heading. The fix is in how a brief is written or filed, not in
`tools/jira-csv.sh`. It needs its own serial. Adding columns here does not improve those rows and
is not meant to.

## Open after close

**Three columns ship empty and nothing proves a person fills them.** The export writes `Priority`,
`Due Date` and `Components` as empty fields. The tests prove the columns are present and empty.
Whether an imported item ever gets a priority is a question about the importing team, not about
this tool, and no test here can reach it. If those fields stay empty in practice, the honest
answer is to drop the columns, not to default them.

**The order was chosen against a known cost.** `Description` sits fifth and holds paragraphs, so
a row is harder to read by eye than when it sat last. This was stated before the choice and is
recorded in case it turns out to matter more than it looked.

**`## The claim` is still missing from 10 of 26 briefs.** Their Epics import with a file path as
the whole Description, and this brief did not change that.

> *Corrected.* This was called a defect while #0027 was being written, here and in the brief.
> It is not one. `docs/blc/briefs/README.md` says of the claim and the phase paragraph: "Neither
> is required: a brief without them is valid, and `validate-briefs.sh` does not look for them."
> The export degrades by design. What is real is that nothing writes the claim, while
> `blc-start-brief` writes every phase paragraph — one half of the feature has a writer and the
> other does not. That is the draft: `docs/blc/briefs/_drafts/the-summary-with-no-writer.md`.
