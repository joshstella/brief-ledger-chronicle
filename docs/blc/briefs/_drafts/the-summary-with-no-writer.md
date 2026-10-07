# The summary with no writer

**Created:** 2026-10-07T12:02:00Z · **Author:** josh.stella@gmail.com · **Depends on:** #0027

## The claim

A brief's summary is its `## The claim` section, and nothing writes it. A phase's description is
a ledger paragraph, and `blc-start-brief` writes one for every phase it plans. The two halves of
the same reporting feature are not built the same way, and only the half with a writer is
reliably there.

## This is not a rule being broken

`docs/blc/briefs/README.md` is explicit: "Neither is required: a brief without them is valid, and
`validate-briefs.sh` does not look for them." The export degrades on purpose — a missing claim
gives the Epic its file path as the Description, plus a warning, and the export still succeeds.

So the briefs below violate nothing. The question this draft raises is whether an optional thing
that is absent most of the time is still worth calling optional, or whether the option has
quietly become the default.

## The evidence

**10 of 26 briefs have no `## The claim`.** Measured 2026-10-07.

- #0001, #0002, #0003, #0004 — the first four, written before the convention existed.
- #0005 through #0015 all have it, and #0017, #0018, #0019, #0022, #0023.
- #0016, #0020, #0021, #0024, #0025, #0026, #0027 do not.

The pattern is not random. The run from #0005 to #0023 is near-unbroken, and five of the last six
briefs lack it. **#0027 is the brief that found this, and it does not have one either.** The
convention held while one person wrote briefs one way and lapsed when the drafts started coming
from somewhere else.

## Where the requirement is written is part of the problem

The one definition is `docs/blc/briefs/README.md:288`, inside `## Reporting to a tracker` — the
section about the Jira export. A person writing a brief has no reason to read it. A person
reading it is already exporting, which is after the brief is written.

Nothing in the authoring path mentions it: not `blc-create-brief`, not
`docs/blc/briefs/_drafts/README.md`, not `templates/`. There is no `brief.md` template at all.

## The asymmetry

| half | written by | present |
|---|---|---|
| phase paragraph in the ledger | `blc-start-brief`, for every phase it plans | reliably |
| `## The claim` in the brief | nothing | 16 of 26 |

The ledger half is reliable because a skill writes it as part of a step that happens anyway. The
brief half depends on the author remembering a convention documented in the export's own section.

## What is undecided

1. **Whether the claim becomes required.** `validate-briefs.sh` could gate it as a `[defect]` or
   report it as a `[judgment]`. "Report, don't gate" is a stated project value, which argues for
   the judgment. Against both: 10 existing briefs would need backfilling, and a brief written
   after the fact is the thing the process explicitly forbids.
2. **Whether something writes it instead.** `blc-create-brief` could add an empty
   `## The claim` heading at filing time, so the brief carries the shape and the author fills it.
   An empty section is not better than no section for the export, which reads the text.
3. **Whether the draft format carries it.** A draft is written before a serial exists. If the
   heading belongs anywhere, the draft is where the thinking is freshest.
4. **Whether the export should fall back to something better than a path.** The H1 title is
   already in `Summary`. The first paragraph of the brief is a candidate, and guessing which
   paragraph is a summary is how readers get the wrong one — see #0013.
5. **Whether this matters at all.** If briefs are exported rarely, a path-only Description is a
   small cost paid by few. The count above says nothing about how often `jira-csv.sh` runs.

## The test

Whatever is chosen, the test is the same shape: a brief with no claim, exported, and an assertion
about what lands in the Description. That test exists today and asserts the path. It would have
to change, which is the signal that the behaviour changed.

If the gate route is taken, the test is that `validate-briefs.sh` names the brief and says which
kind of finding it is, and that the exit status matches the gate-or-report decision.

## Non-goals

- Do not backfill a claim into a closed brief. A summary written after the work is a
  reconstruction, and the record does not hold those.
- Do not make the export refuse. A thinner ticket is better than no import.
