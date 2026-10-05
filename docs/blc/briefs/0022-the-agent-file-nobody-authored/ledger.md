# Ledger — #0022 The agent file an install writes, and nobody authored

`blc/2 #0022 in-progress a:in-progress(brief/0022-a-the-seed) b:pending c:pending`

**Brief:** `docs/blc/briefs/0022-the-agent-file-nobody-authored/brief.md`
**Started:** 2026-10-05
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the seed | in-progress | `brief/0022-a-the-seed` |
| b | one file or two | pending | — |
| c | this repository | pending | — |

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

**b — one file or two.** A target gets one agent file, not one per host. `AGENTS.md` holds the
text and `CLAUDE.md` is a link to it, so both hosts read the same bytes however the project is
installed. Today `install.sh` picks the name from `$HOST`, so a project installed for both
hosts gets two files with the same text and no relation between them. Tests: a Cursor install
and a Claude Code install, a target that already has one of the two, and a target that has
both. Waits on decision 2.

**c — this repository.** This repository gets the agent file an install would write, once, and
commits it. From then on it owns it, as any target does. It answers the questions `a` seeds,
including what "covered" means for tests here. Tests: the committed file exists and answers
them. Waits on decision 3.

## Dependency structure

`a` and `b` are independent in substance. `a` changes what the file says; `b` changes what it
is called and how many there are. Run them one after another anyway, because both edit
`write_project_stub` and the second would land on a conflict. `c` comes last: it uses the text
`a` writes and the name `b` settles.

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

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | **Settled 2026-10-05: nothing.** From the brief, carried from #0019 decision 2. The installer seeds no prose. The stub becomes a pointer plus the questions a project must answer. Evidence found while planning: `tools/orient.sh` already reads `docs/blc/orientation.md` for what a project values, and prints "nobody has written down what matters here" when it is absent. So principles already have a home, and process has one in `templates/process-rules.md`. That leaves the agent file with architecture, stack, build commands and the test-coverage definition — facts about one project that no installer can know. This also answers evidence 2 of the brief: the installer is not shipping this repository's principles into a target, because it ships no principles at all. Rejected: the whole Manifesto, a derived excerpt, and a test-coverage prompt alone. | `a` |
| 2 | **One agent file or two.** From the brief, carried from #0019 decision 4. Claude Code reads `AGENTS.md` natively from v2.1.277, but only when no `CLAUDE.md` exists. Older versions need `CLAUDE.md`. A real `AGENTS.md` with `CLAUDE.md` as a link to it gives one text to both hosts on every version. That version claim is from the Claude Code documentation, not from a run here. | `b` |
| 3 | **Whether `c` is this brief's job.** From the brief, where it is decision 3 and blocks `d`. This repository's agent file could be written by hand now, with no installer change. | `c` |

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

`brief/0022-a-the-seed` (phase `a`).
