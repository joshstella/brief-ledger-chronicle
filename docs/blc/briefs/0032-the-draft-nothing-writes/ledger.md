# Ledger — #0032 The draft nothing writes

`blc/2 #0032 in-progress a:in-progress(brief/0032-a-the-skill-that-writes-a-draft) b:pending`

**Brief:** `docs/blc/briefs/0032-the-draft-nothing-writes/brief.md`
**Started:** 2026-10-08
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the skill that writes a draft | in-progress | `brief/0032-a-the-skill-that-writes-a-draft` |
| b | the machine-level command | pending | — |

**a — the skill that writes a draft.** Ship `skills/blc-create-draft/`, its tracked symlink
under `.claude/skills/`, and the rewritten descriptions on both the drafter and the filer. The
test comes first and must fail: the provenance template in the drafter is the one
`blc-create-brief` reads, asserted by the method `tests/test_identity_line.sh` already uses on
the filer. It fails today because there is no drafter.

**b — the machine-level command.** Add `blc-create-draft` to `PROCESS_SKILLS`. The list is
hand-written in four places — `install.sh`, `tests/test_hosts.sh`, `tests/test_machine_mode.sh`
and `tests/test_skill_names.sh` — so this phase is the four edits and the machine-mode tests
that read them.

## Dependency structure

`b` follows `a`. Naming a skill in `PROCESS_SKILLS` before the skill exists fails the
machine-mode tests, which assert a command link for every name on the list.

The four copies of that list are not this brief's to fix. They are a hand-maintained second
copy of a fact — the kind "Derived beats declared" exists to catch — and noticing that while
adding a fifth entry to it is worth recording even though nothing here acts on it.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | a skill writes drafts; it does not file, number, or commit | a |
| 2 | it joins `PROCESS_SKILLS` | b |
| 3 | both descriptions are rewritten, not only the new one | a |
| 4 | the provenance template is pinned by a test | a |
| 5 | an empty body is written as an empty body | a |
| 6 | `Depends on` is always written, `—` when absent | a |
| 7 | the report names a draft that has no body | a |

**Decision 7 answers the brief's one open question.** Decision 5 keeps an empty draft, and an
empty draft is also what a run that stopped half way leaves behind. The two are identical on
disk, so the report is the only place they can be told apart. It says so once, at the end, for
the file it just wrote — not as a warning, because nothing is wrong.

**Decision 3 is the one that touches shipped prose.** The two descriptions cross their nouns
today: the filer offers "file a draft brief" and the drafter would offer "write an unnumbered
brief". The word that separates them sits on the wrong skill in each case, and the filer is the
one-way door, so the more confusable sentence is guarding the irreversible step. Rewording only
the new skill leaves half of a mutual ambiguity in place.

**Decision 4 is why this is not a documentation change.** `blc-create-brief` step 4 reads
`Created` and `Author` out of the draft. A draft missing them does not fail — the filer stamps
`Created` = now and resolves `Author` from git config — so the brief is filed with the date it
was filed rather than the date the idea was had. The failure is a wrong date in the permanent
record, written in silence. That is a contract between two skills, and this repository already
tests the filer's half of it.

## What this cannot prove

A skill is prose and nothing runs it. The test pins the template the skill shows; it cannot
make an agent follow the steps around it. This is the "A skill guard is not a check" case, and
it is named here rather than left to look like coverage.

The drafter also cannot be proved to help. The defect it addresses — a filed brief carrying the
filing date instead of the authoring date — is already in this repository's record, in every
brief filed from a hand-written draft that omitted the line. Nothing measures how often that
happened, and this brief does not go back and look.
