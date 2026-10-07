# Ledger — #0028 The summary with no writer

`blc/2 #0028 in-progress a:in-progress(brief/0028-a-the-tool-takes-a-summary) b:pending`

**Brief:** `docs/blc/briefs/0028-the-summary-with-no-writer/brief.md`
**Started:** 2026-10-07
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the tool takes a summary | in-progress | `brief/0028-a-the-tool-takes-a-summary` |
| b | the skill that writes one | pending | — |

**a — the tool takes a summary.** `tools/jira-csv.sh` reads `## The claim` for the Epic's
Description and nothing else. This phase gives it a way to be told the text instead:
`--summary-file <path>`, read whole. The precedence is the flag, then `## The claim`, then the
brief's path with a warning. A person running the script by hand sees exactly today's behaviour.
`docs/blc/briefs/README.md` gains the flag in its export description.

**b — the skill that writes one.** A new skill reads the brief and its ledger, writes a summary
of two to five sentences, and runs the tool with it. This is the writer the Epic description has
never had. The skill ships like every other: the ownership map, the `.claude/` symlink, and the
guard in `tests/test_ownership_map.sh` that a tool or skill in the source tree reaches a target.

## Dependency structure

A chain. Phase `a` alone is complete and useful on its own: the flag exists, the fallback is
unchanged, and nothing in the repository has to use it. Phase `b` cannot ship first, because the
skill would call a flag that does not exist.

## Re-planned before execution

> *The plan below replaced an earlier one, recorded here rather than overwritten.*
>
> This ledger first planned the summary to be written **into the brief** at filing time, by
> `blc-create-brief`, with the export preferring a new `## Summary` section and falling back to
> the claim. Phase `b` was "filing writes one".
>
> The argument for it was reproducibility: an agent summarizing at export time gives a different
> description on every run. **That argument was mostly hollow.** `jira-csv.sh` refuses a brief
> that already carries a `Jira:` key, because a second import makes a second Epic. The export is
> a one-shot seed (#0007). A brief is exported once, so "two runs disagree" is a state the tool
> already prevents.
>
> Two things then favour the export: a summary written at filing describes the hypothesis, while
> one written at export describes what the brief became — and the brief is explicitly the
> hypothesis, which the ledger is expected to correct. And no agent prose lands in the permanent
> record under a person's `Author` field.
>
> The remaining objection was that the record would not hold the text sent to Jira. The owner
> answered it directly: **BLC is the system of record and Jira is for understanding state at a
> moment in time.** A view does not need to be archived. Nothing is written back.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | Where the summary is generated → **at export time, by a skill wrapping the tool** | a, b |
| 2 | What happens to `## The claim` → **kept as the fallback when no summary is supplied** | a |
| 3 | Whether the text sent to Jira is recorded → **no** | a, b |
| 4 | How the skill passes the text → **`--summary-file`, not an argument** | a |
| 5 | Whether a `## Summary` section is added to briefs → **no; superseded, see above** | — |
| 6 | Does `validate-briefs.sh` count sentences → **no** | — |

**1 — the skill is the writer.** The tool is a shell script and cannot summarize. A skill reads
the brief and the ledger, writes the prose, and runs the tool. The export is the one moment when
the whole record for a brief is in hand, which is the moment a summary is worth writing.

**2 — the claim stays, as the fallback.** Sixteen briefs have one that reads well, and a person
running `jira-csv.sh` by hand gets exactly today's behaviour. The fallback costs one branch in
one function.

**3 — nothing is written back.** Jira holds a view of a moment. BLC holds the record. A
write-back would put a second copy of the brief's meaning in the brief, which is the stale second
copy this process exists to avoid.

**4 — a file, not an argument.** A summary is several sentences of free prose. Passed as an
argument it meets the shell's quoting rules, and a newline or a quote in it becomes a defect in
the caller rather than in the tool. A file has none of those failure modes, and the tool already
refuses rather than half-writes.

**6 — no sentence counting.** Two to five is guidance for the writer, not a shape to check. A
sentence counter in a shell script is a parser for something with no grammar, and an abbreviation
ends a sentence in it.

## What this cannot prove

Nothing in the suite can assert that the skill writes a good summary, or any summary. It is a
skill, and a skill guard is not a check. What the suite can prove is the whole of the tool's
side: that a supplied file reaches the Epic's Description, that the claim is used when no file is
given, that the path and the warning survive when there is neither, and that an unreadable or
empty file is refused rather than silently ignored.
