# Ledger — #0022 The agent file an install writes, and nobody authored

`blc/2 #0022 in-progress a:done(PR#105) b:in-progress(brief/0022-b-skills-are-prompts,PR#106) c:pending d:pending`

**Brief:** `docs/blc/briefs/0022-the-agent-file-nobody-authored/brief.md`
**Started:** 2026-10-05
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the seed | done (PR#105) | — |
| b | skills are prompts | in-progress (PR#106) | `brief/0022-b-skills-are-prompts` |
| c | one file or two | pending | — |
| d | this repository | pending | — |

The brief plans four phases. `a — what the file is for` was docs and the ledger only, and it
existed to settle decision 1. Decision 1 is settled below, before any phase runs, so the phase
has no work left of its own. Its output is folded into `a — the seed`, which carries it with
tests. The brief's `b`, `c` and `d` are this ledger's `a`, `b` and `c`.

A docs-only phase would have merged test-exempt. This project's rule is that tests gate `main`,
and a phase that cannot be tested is a phase worth questioning rather than exempting.

**a — the seed.** `install.sh` stops writing prose into a new target's `AGENTS.md` or
`CLAUDE.md`. The stub becomes a short pointer and the questions a project must answer for
itself, because the installer cannot know them. It names the two files that already hold the
rest: `templates/process-rules.md` for process and `docs/blc/orientation.md` for what the
project values. One of the questions is what "covered" means for tests in that project, which
is the gap #0019 found here. Tests: a new target gets the file, an existing file is still
skipped and still logged as skipped, the text repeats no line of the process rules file, and it
names `orientation.md`.

**b — skills are prompts.** `templates/process-rules.md` says the skills are the gates. It
does not say that nothing enforces them. One sentence puts that next to the claim it
qualifies, so a target's agent does not read "gate" as a mechanical block. It goes in the
rules file, which an install owns and rewrites, and not in the agent file, which an install
writes once and never corrects. Tests for both hosts, because Cursor gets a generated copy
with frontmatter and Claude Code gets the template itself.

**c — one file or two.** A target gets one agent file, not one per host. `AGENTS.md` holds the
text and `CLAUDE.md` is a link to it, so both hosts read the same bytes however the project is
installed. Today `install.sh` picks the name from `$HOST`, so a project installed for both
hosts gets two files with the same text and no relation between them. Tests: a Cursor install
and a Claude Code install, a target that already has one of the two, and a target that has
both. Waits on decision 2.

**d — this repository.** This repository gets the agent file an install would write, once, and
commits it. From then on it owns it, as any target does. It answers the questions `a` seeds,
including what "covered" means for tests here. Tests: the committed file exists and answers
them. Waits on decision 3.

## Dependency structure

`a` and `c` are independent in substance. `a` changes what the agent file says; `c` changes what
it is called and how many there are. Run them one after another anyway, because both edit
`write_project_stub` and the second would land on a conflict. `d` comes last: it uses the text
`a` writes and the name `c` settles.

`b` touches none of that. It edits `templates/process-rules.md`, which no other phase reads, so
it could run at any point. It runs second because it is the only phase with no open decision in
front of it.

Re-lettered on 2026-10-05, after `a`: "skills are prompts" is new and takes `b`, "one file or
two" was `b` and is now `c`, and "this repository" was `c` and is now `d`. No merged PR cites
either letter.

Nothing here is provisional. Decision 1 is settled before `a`, so no phase can reorder the ones
after it.

## Phase `a`, as executed

The stub now opens by saying the file belongs to the project, names the two files that hold
the rest, and asks five questions. One of them is what "covered" means for tests. The closing
instruction the installer prints changed with it: it said "fill in the project-specific
section", and that section no longer exists.

**The first test was unproven, and it is gone.** This ledger planned a test that the stub
repeats no line of the process rules file. It was written, and it passed against the old stub,
which is the defect this phase fixes. The duplication was never line-identical: the stub wrote
"The installed skills are the gates" where the rules write "Installed skills are the gates". No
textual comparison catches a restatement. It is replaced by a test for two named phrases that
belong to the process rules, which asserts each is absent from the stub and present in the rules
file. The second half is what stops the test rotting: a phrase the rules file drops is a phrase
the test can no longer police.

A third phrase, `bash tools/orient.sh`, was in that list and is dropped. The review found it
passed by accident: the stub names `tools/orient.sh` and omits the word `bash`, so the
assertion held on a space rather than on the thing it claimed to police. The two phrases that
remain fail honestly against the old stub.

**The stub restated a process rule, and the review caught it.** The first draft asked what
"covered" means and explained it with "a merge to `main` needs tests covering the change",
which is `templates/process-rules.md` line 32 in other words. That is the defect this phase
exists to remove, written into the fix. The question now stands alone and names no rule. The
test for named phrases did not catch this, and could not: the phrase was not on its list, and
no list is complete. The guard here is the review, not the suite.

Two tests, not four. "An existing file is still skipped and still logged as skipped" was already
covered by `test_project_never_overwrites_an_existing_claude_md` and by two tests in
`tests/test_replace.sh`, one per host name. A third copy would have proved nothing new.

`test_project_creates_the_expected_tree` asserted the old `## Project-specific` heading, so it
moved with the change. All three tests were seen to fail with the old `install.sh` in place.
The suite is 558, from 556.

## Big decisions

**The Manifesto does not ship to targets, and one sentence of it does. 2026-10-05, after `a`.**

Decision 1 was reopened after `a` merged. The question put was an excerpt of `Manifesto.md`
that is appropriate for an agent, rather than the whole file or nothing.

Reading the Manifesto for that excerpt is what closed the question. Most of it argues: against
spec-first process, against ceremony, for play. None of that instructs an agent. Six statements
do, and one more was already in `templates/process-rules.md` in other words. So an excerpt
exists. It is small.

Then the destination failed. Every one of those six is a statement about the toolkit's process,
which puts it in the same class as `templates/process-rules.md` — a file an install owns and
rewrites every run. The agent file is written once and never again. An excerpt placed there
freezes on install day and no upgrade can correct it. The Manifesto names that failure itself:
"a contract that has drifted is worse than no contract, because it is believed."

Dropping the Manifesto for targets also dissolves evidence 2 of the brief, instead of answering
it. There is no exception to `test_orient_authored_file_does_not_ship_to_a_target` to justify,
because nothing authored here is shipped. The Manifesto's own rules say the same: keep the
provided surface small, treat everything external as optional. It stays in this repository, and
`tools/orient.sh` names it in the footer for anybody who wants the argument.

One statement survived on its own merits, and it is `b`. Nothing a target receives says the
skills are unenforced. In this repository that comes from `docs/blc/orientation.md`, which a
target authors for itself, so a target never gets it. An agent reading "the skills are the
gates" with nothing beside it will take "gate" to mean a mechanical block. That is a fact about
the tools, not an argument about programming, and it belongs in the rules file.

**This overturns a non-goal of the brief.** The brief says "Not changing
`templates/process-rules.md`. That file is the installer's, and it works." It does work, for
everything it says. The gap is a thing it does not say, and no other file an install writes can
carry it. The non-goal held against adding process prose to a file that already covers process.
It does not hold against the one sentence that makes the rest of the file honest.

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | **Settled 2026-10-05: nothing.** From the brief, carried from #0019 decision 2. The installer seeds no prose. The stub becomes a pointer plus the questions a project must answer. Evidence found while planning: `tools/orient.sh` already reads `docs/blc/orientation.md` for what a project values, and prints "nobody has written down what matters here" when it is absent. So principles already have a home, and process has one in `templates/process-rules.md`. That leaves the agent file with architecture, stack, build commands and the test-coverage definition — facts about one project that no installer can know. This also answers evidence 2 of the brief: the installer is not shipping this repository's principles into a target, because it ships no principles at all. Rejected: the whole Manifesto, a derived excerpt, and a test-coverage prompt alone. | `a` |
| 2 | **One agent file or two.** From the brief, carried from #0019 decision 4. Claude Code reads `AGENTS.md` natively from v2.1.277, but only when no `CLAUDE.md` exists. Older versions need `CLAUDE.md`. A real `AGENTS.md` with `CLAUDE.md` as a link to it gives one text to both hosts on every version. That version claim is from the Claude Code documentation, not from a run here. | `c` |
| 3 | **Whether `d` is this brief's job.** From the brief, where it is decision 3. This repository's agent file could be written by hand now, with no installer change. | `d` |

## Complications

Found while reading the code. None is in the brief.

- **A third file already holds the principles.** `tools/orient.sh` line 25 reads
  `docs/blc/orientation.md`, and `test_orient_authored_file_does_not_ship_to_a_target` keeps an
  install from writing it into a target. The brief treats the agent file and the process rules
  as the only two. There are three, and the third is the one the Manifesto would duplicate.
- **`PROCESS_RULES_REL` is host-shaped, and the stub names it.** The stub text interpolates
  `$PROCESS_RULES_REL`, which is `.cursor/rules/brief-ledger-chronicle.mdc` for Cursor and
  `.claude/rules/brief-ledger-chronicle.md` for Claude Code. A project installed for both hosts
  needs both named, or the pointer is wrong for one of them. `b` has to deal with this, not `a`.
- **The install log records the file by its host name.** `install.sh` line 409 prints the
  ownership row as `project file - $RULES_FILE`, and line 869 and line 872 name it in the
  summary the installer prints. `b` changes that name. Those three sites and their tests move
  with it.
- **The final instruction names the section that goes away.** Line 1280 tells the user to
  "fill in the project-specific section". `a` replaces that section with questions, so the
  instruction has to change in the same phase or it points at nothing.

## Branches

`brief/0022-a-the-seed` (phase `a`, merged as PR#105, deleted).
`brief/0022-b-skills-are-prompts` (phase `b`).

## Phase `b`, as executed

The sentence sits directly under "Installed skills are the gates; bypassing them is the defect",
because that is the claim it qualifies. It says the skills instruct an agent, that a skipped gate
and one that ran look the same afterwards, and to say where a skill was relied on instead of a
check.

**The drift test from #0019 `c` fired on the first real edit to the template, which is what it
was built for.** `.cursor/rules/brief-ledger-chronicle.mdc` is a generated copy, and
`self_host_cursor_rules_file_matches_the_installer` failed until it was regenerated with `bash
install.sh --print-process-rules --host cursor`. #0019 closed with that trap recorded and
nothing to regenerate it. The record was read and the test caught the rest.

Two tests, one per host. Cursor receives a generated copy with frontmatter prepended and Claude
Code receives the template itself, so a sentence proved on one path is not proved on the other.
Both were seen to fail without the change.
