# The export that omits the fields Jira expects

**Serial:** #0027 · **Created:** 2026-10-07T11:41:02Z · **Author:** josh.stella@gmail.com · **Depends on:** #0018

## The request

Feedback from use says a Jira CSV import wants these columns at minimum:

- **Summary** (required) — the title.
- **Issue Type** (required) — Task, Story, Bug, Epic.
- **Description** — the detailed explanation.
- **Priority** — Low, Medium, High.
- **Assignee / Reporter** — an email address, or an exact Atlassian account name.
- **Due Date** — one consistent format, `YYYY-MM-DD` or `MM/DD/YYYY`.
- **Labels / Components** — multi-value, comma separated.

`tools/jira-csv.sh` emits seven columns and four of those are missing.

## The evidence

The header row today:

```
"Work type","Summary","Work item ID","Parent","Assignee","Status","Description"
```

Against the list above: `Summary`, `Description` and `Assignee` are present. `Work type` is
`Issue Type` under its current name. **`Priority`, `Due Date`, `Components` and `Reporter` are
absent, and `Labels` is absent.**

`Work item ID` and `Parent` are in neither list, and both must stay. They are what links a phase
Task to its brief Epic inside one file (#0007). The feedback describes a flat sheet. This export
is a hierarchy.

## Three of the requested fields have no source

A brief's identity line carries `Serial`, `Created`, `Author`, `Depends on`, and optionally
`Owner` and `Jira`. A ledger carries phases, states and decisions. Nothing anywhere holds a
**Priority**, a **Due Date** or a **Component**.

This is the whole difficulty. The export can only write what the record holds. A default —
`Medium`, or `Created` plus two weeks — would put declared data in a file that every other column
derives, and a reader cannot tell the two apart once they are in Jira. "Derived beats declared"
exists for this.

## What is already settled

1. **The three unsourced fields ship as empty columns.** Jira then shows the field on each
   imported item and a person fills it in there, where the data belongs. The column is present,
   which is what the feedback asks for; the value is absent, which is what the record supports.
   Decided 2026-10-07.
2. **The header stays `Work type`.** #0007 chose it against Jira Cloud, which renamed the field.
   `Issue Type` is the older Server and Data Center name. The importer's mapping screen accepts
   either, so this is a naming question and not a functional one. Decided 2026-10-07.

## What is undecided

1. **Whether `Labels` is empty or derived.** Unlike Priority and Due Date, labels *can* come from
   the record: the serial, the phase letter, a fixed `blc` marker, or the brief's state. A
   derived label is useful for finding every imported item later. It is also a guess about the
   importing project's label conventions, and a wrong one is work to undo across every item.
2. **Whether `Reporter` is `Author`.** It can be derived. `Assignee` is already `Owner` or
   `Author`, so on a brief with no `Owner` the two columns hold the same email. That is true, not
   a defect, but it may read as a bug to someone looking at the sheet.
3. **The column order.** The feedback lists the fields in an order. The importer maps by header,
   not by position, so order is for the human reading the file. Required fields first is one
   rule; grouping the empty columns at the end is another.
4. **Whether an empty `Due Date` needs a format declared anywhere.** No value is written, so no
   format is used. The question is whether the tool should state the format it *would* write, so
   a person filling the column by hand before import picks the right one.

## A defect this export exposes, which may not belong here

**10 of 26 briefs have no `## The claim` section**, so `brief_claim()` finds nothing and the Epic
imports with its file path as the entire Description. Every brief since #0024 is in this set. The
briefs that lack it were filed from `_drafts/`, and the draft format has no such heading.

The fix is in how a brief is written or filed, not in `tools/jira-csv.sh`. It probably needs its
own serial. It is recorded here because this is where it was found, and because any judgment of
the Description column has to account for it.

## The test

Assert the header row names every column, in the chosen order.

Assert that `Priority`, `Due Date` and `Components` are present and empty on both an Epic row and
a Task row — an empty column that is silently dropped is the failure this guards.

Assert that a brief with an `Owner` gives a different `Assignee` and `Reporter`, and that a brief
without one gives the same email in both, so the fallback is proven rather than assumed.

Assert the existing refusals still refuse. The column change must not weaken a guard that stops a
partial import.

## Non-goals

- Do not invent a value for a field the record does not hold.
- Do not remove `Work item ID` or `Parent`. They carry the Epic-to-Task link.
- Do not make this a sync. It stays the one-shot seed #0007 settled.
