# Ledger — #0028 The summary with no writer

`blc/2 #0028 pending a:pending b:pending`

**Brief:** `docs/blc/briefs/0028-the-summary-with-no-writer/brief.md`
**Started:** 2026-10-07
**Status:** pending

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the export reads a summary | pending | — |
| b | filing writes one | pending | — |

**a — the export reads a summary.** `tools/jira-csv.sh` reads `## The claim` for the Epic's
Description and nothing else. This phase makes it read `## Summary` first and fall back to the
claim, keeping the path-and-warning behaviour when neither is there. The warning names both
sections, so a person who sees it knows what to add. `docs/blc/briefs/README.md` gains the new
section in its export description. No brief is edited and no existing export changes.

**b — filing writes one.** `blc-create-brief` gains a step: write a `## Summary` of two to five
sentences into the brief it files. This is the whole point of the brief — the section the export
reads has had no writer, which is why ten briefs lack its predecessor. The skill carries the rule
that a draft's own `## Summary` is left alone. `docs/blc/briefs/README.md` and
`docs/blc/briefs/_drafts/README.md` state the convention where an author reads, not only where an
exporter does.

## Dependency structure

A chain, and the order matters in one direction only. Phase `a` alone is a no-op: the export
looks for a section nothing writes and falls back exactly as it does today. Phase `b` alone would
write a section the export ignores. Shipping `a` first means the tree is never in a state where
the record holds something no reader uses.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | Who writes the summary → **`blc-create-brief`, at filing time** | b |
| 2 | What happens to `## The claim` → **kept; the export prefers `## Summary` and falls back** | a |
| 3 | The section name → **`## Summary`** | a, b |
| 4 | Agent writes the prose, or asks → **writes, without asking** | b |
| 5 | Does `validate-briefs.sh` count sentences → **no** | — |

**1 — written once, not per export.** The alternative was an agent summarizing at export time.
That gives a different Epic description on every run, nothing in the suite can assert the output,
and the record never holds the text that reached Jira. Writing it once into the brief keeps the
script doing what it already does: read a section, convert it, emit it.

**2 — the claim stays.** Sixteen briefs have a claim that reads well. A fallback costs one branch
in one function and means no brief is edited and no existing export changes. Replacing the claim
would have left those sixteen worse off to fix the ten.

**3 — `## Summary`.** It reads as what it is, and it is the heading this repository already puts
at the top of every PR body.

**4 — the agent writes, and does not stop to ask.** Filing is a one-run step and a question in
the middle of it costs a turn on every brief. The cost accepted is that agent prose lands in the
record under the person's `Author` field. It is a section in a file, so a person who dislikes it
edits it.

**5 — no sentence counting.** Two to five is guidance for the writer, not a shape to check. A
sentence counter in a shell script is a parser for something with no grammar, and an abbreviation
ends a sentence in it.

## What this cannot prove

Nothing in the suite can assert that `blc-create-brief` ever writes the section. It is a skill,
and a skill guard is not a check. That is not a gap this brief can close, and it is the same
footing as the half that works: `blc-start-brief` writes every phase's ledger paragraph and
nothing enforces that either. The reason that half is reliable is that writing the ledger is a
step that has to happen anyway, and filing a brief is the same kind of step. Parity, not a
guarantee.
