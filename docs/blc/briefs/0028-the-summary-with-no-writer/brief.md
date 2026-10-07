# The summary with no writer

**Serial:** #0028 · **Created:** 2026-10-07T12:31:56Z · **Author:** josh.stella@gmail.com · **Depends on:** #0027

## Summary

A brief's exported description comes from its `## The claim` section, and nothing writes that
section. Ten of twenty-six briefs do not have one, including five of the last six, so their Jira
Epic imports with a file path where its prose should be. This brief gives the summary a writer:
`blc-create-brief` writes a `## Summary` of two to five sentences when it files a brief, and
`tools/jira-csv.sh` prefers that section and falls back to the claim. No existing brief is
changed.

*This section is the convention it proposes.*

## This is not a rule being broken

`docs/blc/briefs/README.md` is explicit: "Neither is required: a brief without them is valid, and
`validate-briefs.sh` does not look for them." The export degrades on purpose — a missing claim
gives the Epic its file path as the Description, plus a warning, and the export still succeeds.

So the briefs below violate nothing. What this brief changes is that the option has quietly
become the default.

## The evidence

**10 of 26 briefs have no `## The claim`.** Measured 2026-10-07.

- #0001, #0002, #0003, #0004 — the first four, written before the convention existed.
- #0005 through #0015 all have it, and #0017, #0018, #0019, #0022, #0023.
- #0016, #0020, #0021, #0024, #0025, #0026, #0027 do not.

The pattern is not random. The run from #0005 to #0023 is near-unbroken, and five of the last six
briefs lack it. **#0027 is the brief that found this, and it does not have one either.** The
convention held while one person wrote briefs one way, and lapsed when the drafts started coming
from somewhere else.

## Where the requirement is written is part of the problem

The one definition is `docs/blc/briefs/README.md:288`, inside `## Reporting to a tracker` — the
section about the Jira export. A person writing a brief has no reason to read it. A person
reading it is already exporting, which is after the brief is written.

Nothing in the authoring path mentions it: not `blc-create-brief`, not
`docs/blc/briefs/_drafts/README.md`, not `templates/`. There is no `brief.md` template at all.

## The asymmetry, and why a skill is the right fix

| half | written by | present |
|---|---|---|
| phase paragraph in the ledger | `blc-start-brief` | reliably |
| `## The claim` in the brief | nothing | 16 of 26 |

Both halves are read by the same export. Only one has a writer.

**The writer being a skill is not the weakness it looks like.** `blc-start-brief` is a skill too,
and nothing enforces it either. The ledger half is reliable because writing the ledger is a step
that has to happen anyway, and the paragraph is part of the artifact being written. Filing a
brief is the same kind of step: every brief passes through `blc-create-brief` exactly once, which
is already why it is the single point of serial assignment. Putting the summary there buys the
same reliability the working half has — not a guarantee, but parity.

## What the export does

Read `## Summary`. If it is absent or empty, read `## The claim`. If both are absent, keep
today's behaviour: the brief's path alone, and a warning naming which sections were looked for.

The claim is not removed and no brief is backfilled. Sixteen briefs have a claim that reads well,
and they keep exporting exactly as they do now.

## What is settled

1. **`blc-create-brief` writes it, at filing time.** Not at export time: an agent summarizing on
   each export gives a different description every run, nothing in the suite can assert it, and
   the record never holds the text that reached Jira. Decided 2026-10-07.
2. **The export prefers `## Summary` and falls back to `## The claim`.** No backfill, no brief
   edited, no existing export changed. Decided 2026-10-07.
3. **The section is `## Summary`.** It reads as what it is, and it matches the heading this
   repository already uses at the top of every PR body. Decided 2026-10-07.
4. **The agent writes the prose, and does not stop to ask.** Filing is already a one-run step and
   a question in the middle of it costs a turn on every brief. The text is agent prose in the
   record under the person's `Author` field, which is true of a filed brief's other derived
   fields and is the cost accepted here. A person who dislikes the summary edits it; it is a
   section in a file, not a generated artifact. Decided 2026-10-07.
5. **`validate-briefs.sh` does not count sentences.** Two to five is guidance for the writer, not
   a shape to check. A sentence counter in a shell script is a parser for something with no
   grammar, and an abbreviation ends a sentence in it. Decided 2026-10-07.

## What is undecided

1. **Whether a draft may carry its own `## Summary`.** If it does, filing should leave it alone
   rather than overwrite a person's words with an agent's. The question is whether the skill
   checks for one before it writes.
2. **Whether two `## Summary` sections refuse, as two claims do.** Consistency says yes.
3. **Whether the drafts README should name the section.** A draft author who knows the heading
   exists may write a better summary than an agent reconstructs at filing time. Against: a second
   place stating the convention is a second place for it to drift.

## The test

Export a brief with both sections and assert the Epic's Description is the summary, not the
claim. Export one with only a claim and assert the claim is used, which is the proof that no
existing brief changed. Export one with neither and assert the path and the warning.

Each of those is a small edit to the fixtures that already exist for the claim.

What cannot be tested is that `blc-create-brief` ever writes the section. It is a skill, and a
skill guard is not a check. The same is true of the ledger half that works, which is the argument
for putting it there rather than the argument against.

## Non-goals

- Do not backfill a summary into a closed brief. A summary written after the work is a
  reconstruction, and the record does not hold those.
- Do not remove `## The claim`, and do not make the export refuse without one.
- Do not summarize at export time.
