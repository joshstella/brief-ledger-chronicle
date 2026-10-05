# The agent file an install writes, and nobody authored

**Serial:** #0022 · **Created:** 2026-10-05T18:05:00Z · **Author:** josh.stella@gmail.com · **Depends on:** #0019

## The finding

Every install writes `CLAUDE.md` or `AGENTS.md` from `write_project_stub` in `install.sh`. The
stub is nine lines. It says the skills are the gates, points at the process rules file, points
at `tools/orient.sh`, and leaves a comment that asks the project to fill in the rest.

Two of those three sentences repeat `templates/process-rules.md`, which the same install
writes. The third is a pointer. So the file a project is told to own starts as a restatement of
the file next to it.

This repository has no agent file at all, which #0019 found and did not fix. The owner's
working agreement expects each project's agent file to define what "covered" means for tests.
Here nothing defines it.

#0019 planned this as its phase `e` and skipped it. The reason is recorded in that ledger:
`e` is the only part of #0019 that changes what every target install writes, and the rest of
#0019 changes nothing outside this checkout.

## The claim

**A seeded agent file must say something the install does not already say, or it should not
be seeded at all.**

The question is not which text to copy. It is whether an installer should author a project's
agent file at all, given that the same repository already refuses to ship its own
`orientation.md` for exactly that reason.

## Evidence

All of this is in this repository.

**1. The stub repeats the rules file.** `write_project_stub` writes "the installed skills are
the gates; bypassing them is the defect" and a pointer to `tools/orient.sh`. The first is the
opening line of `templates/process-rules.md`. The second is its first bullet.

**2. This repository already refuses to ship authored content.**
`tests/test_orient.sh`, `test_orient_authored_file_does_not_ship_to_a_target`, asserts that an
install does not write `docs/blc/orientation.md` into a target. Its comment gives the reason:

> Shipping this repo's copy would install our principles into someone else's repository. A
> target authors its own, and orient's absence message is what asks for it.

`Manifesto.md` is authored content of the same kind, 198 lines of it. Seeding a target's agent
file from the Manifesto is the act that test forbids for `orientation.md`. Either the two cases
differ for a reason this brief has to state, or the seed is wrong.

**3. The stub is already project-owned, and already skipped.** `write_project_stub` returns
early when the file exists, and logs it as skipped. So this reaches new targets only. Whatever
it writes, a project keeps forever unless it edits it.

**4. The host decides the name, and nothing links them.** `install.sh` sets `RULES_FILE` to
`AGENTS.md` for Cursor and `CLAUDE.md` for Claude Code. A project installed for both hosts gets
two files with the same text and no relation between them.

**5. The Manifesto is an essay, not a rule set.** Its sections are "The problem", "Play, then
spec", "Rules that hold, and rules that do not", "The present tense". It argues. An agent file
is read as instructions.

## Change

| Phase | Work |
|---|---|
| `a — what the file is for` | Decide and record what a seeded agent file must contain that the process rules do not. If the answer is "nothing", the phase ends by making the stub a pointer with a filled-in question, not prose. Docs and the ledger only. |
| `b — the seed` | `install.sh` writes whatever `a` settled. Tests: a new target gets it, an existing file is still skipped, and the text does not repeat the process rules line for line. |
| `c — one file or two` | A real `AGENTS.md` with `CLAUDE.md` as a link to it, so both hosts read one text on every version. Tests for both hosts, and for a target that already has one of the two. |
| `d — this repository` | This repository gets the same file once and commits it, and owns it from then on, as any target does. |

`a` comes before `b`. `c` is independent of `a` and `b`. `d` comes last, because it uses what
`b` and `c` produce.

## Tension

Seeding more means authoring more of someone else's repository. Seeding less means every
adopter starts with a file that says nothing, and the one in this repository stays empty, which
is the gap #0019 found.

A link from `CLAUDE.md` to `AGENTS.md` makes one text serve both hosts, and it also makes the
project's own file a link it did not ask for. A project that later deletes one of them breaks
the other.

## Settled decisions

- **This is not #0019.** #0019 is about the source running its own process. This changes what
  every target install writes, which is why #0019 skipped it.
- **The agent file stays project-owned.** An install writes it once and never again. The
  existing skip behaviour does not change.

## Open decisions

1. **What a seeded agent file must say.** Carried from #0019 decision 2. The whole Manifesto, a
   derived excerpt, or a pointer. It must answer evidence 2: why this is not the thing
   `test_orient_authored_file_does_not_ship_to_a_target` forbids. Blocks `a`.
2. **One agent file or two.** Carried from #0019 decision 4. Claude Code reads `AGENTS.md`
   natively from v2.1.277, but only when no `CLAUDE.md` exists. Older versions need
   `CLAUDE.md`. A real `AGENTS.md` with `CLAUDE.md` as a link serves both on every version.
   That version claim is from the Claude Code documentation, not from a run here. Blocks `c`.
3. **Whether `d` is this brief's job.** This repository's agent file could be authored by hand
   now, without any installer change. Blocks `d`.

## Non-goals

- **Not changing an existing target's agent file.** The skip stays.
- **Not shipping `Manifesto.md` itself** to a target as a file.
- **Not a Contract clause.** An agent file is not part of how the record is shaped.
- **Not changing `templates/process-rules.md`.** That file is the installer's, and it works.

## Success criteria

- A new target's agent file says something the process rules file does not.
- An existing agent file is still skipped, and the install log still records it.
- A project installed for both hosts reads one text, whichever file its host opens.
- This repository has an agent file, and it answers what "covered" means for tests here.
- The reason an agent file may be seeded, where `orientation.md` may not, is written down.
