---
name: blc-export-to-jira
description: >-
  Export one brief and its phases as a Jira CSV import, writing the Epic's description yourself.
  Use when the user asks to blc-export-to-jira, to put a brief on the board, or to report a brief
  to Jira.
---

# blc-export-to-jira

Write a short summary of a brief, then run `tools/jira-csv.sh` with it.

Everything that can be derived is derived by the script: the rows, the hierarchy, the assignee,
the reporter, the label, the states, and every phase's description. You write one thing, the
Epic's description, because it is the one field no rule can produce from the record.

The script owns every refusal. Do not pre-check a brief against the rules below and do not work
around a refusal — a refusal means the brief cannot be exported whole, and a partial import is
worse than none.

## What the summary is for

Jira is a view of a moment. The record is `docs/blc/briefs/`. Nothing you write here is kept:
the summary reaches the Epic and is not written back to the brief, the ledger, or anywhere else
(#0028). Write it for somebody reading a board, who will not open the repository.

That is also why it is written at export time rather than stored. A brief is the hypothesis the
work started with, and the ledger is expected to correct it. At export you have both, so the
summary can say what the work *is*, not only what it was proposed to be.

## Steps

1. **Read the brief and the ledger in full.** Both. The brief alone gives you the hypothesis,
   and a brief whose ledger overturned it is the case this skill exists to handle. If there is no
   ledger, the script will refuse — the brief has no phases to export.
2. **Write two to five sentences.** Use the `blc-ste-writing` skill, STE-flavored mode, as all
   process prose here does.
   - Say what the brief is about, and what the record shows became of it. A closed brief whose
     ledger records a reversal should say so; that is the most useful sentence on the board.
   - Derive every sentence from the brief and the ledger. Do not add context from this
     conversation, from the code, or from your own view of the work. A reader cannot check you.
   - Markdown is converted to Jira wiki markup by the script, so write normally. Do not write
     wiki markup yourself.
   - Do not restate the title. It is already the Epic's `Summary` field.
3. **Write it to a file** and run the script:
   `bash tools/jira-csv.sh --summary-file "$f" <serial> > "$(mktemp -d)/<serial>-jira.csv"`
   - A file, not an argument: your text has newlines in it.
   - **Write both files outside the repository.** The summary and the CSV are couriers: they
     carry the record to a board and have no use afterwards, which is the same reason nothing is
     written back. Left in the work tree they are untracked files in a repository where a sweep
     of everything untracked has already put an unrelated file into a commit. Nothing is gained
     by keeping them — a second export regenerates both from the record (#0028).
   - If the script is missing, this project has the skill without the toolkit's tools. Say so and
     stop.
4. **Show the summary you wrote, verbatim, in your report.** Not a description of it. This is the
   one field a person cannot check by reading the record, and it is the only chance to object
   before it reaches a board.
5. **Report the output path, and every warning the script printed.** A warning means a phase
   imported thinner than it should have. Name which.
6. **Say what the person does next.** The import is theirs: Jira's CSV importer, with its
   value-mapping screen for the `Status` column. After it succeeds they put the new Epic key in
   the brief's `Jira:` field, which is what stops a second export.

## One brief, once

The script refuses a brief whose identity line already carries a `Jira:` key, because a second
import makes a second Epic. This is a seed, not a sync. A later edit to the brief or the ledger
does not reach the board, and nothing here reconciles them.

If the person wants an updated description on an existing Epic, that is an edit in Jira. Do not
export again, and do not clear the `Jira:` field to make the refusal go away.

## What you do not write

Each phase's description is the ledger paragraph that starts `**<id> — <label>.**`, copied by the
script. Do not summarize phases, and do not edit the ledger to improve what the board shows.
Those paragraphs are the record, and a reader of the record and a reader of the board should see
the same words.

The three empty columns — `Priority`, `Due Date`, `Components` — are empty because the record
holds nothing for them (#0027). Do not invent values and do not offer to.
