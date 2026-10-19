# Machine mode stops linking the personal CLAUDE.md

**Serial:** #0041 · **Created:** 2026-10-19T12:18:58Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## The finding

`install.sh --machine` links `personal/CLAUDE.md` to `~/.claude/CLAUDE.md`. That file is the
author's personal working agreement. Claude Code loads it in every project on the machine.
So each person who runs the machine step gets the author's working style as their global
instructions: one change at a time, TypeScript and strong types, the code-review memory rule.

No skill or tool reads this file. The only references are in `install.sh`, in the two
machine-mode tests that assert the link, and in old brief and ledger text. The process rules
that BLC needs already ship per project: "tests gate main", "covered" and "test-exempt" are
in `templates/process-rules.md`, which installs into `.claude/rules/`, and in the
`blc-review-pr`, `blc-commit-push-pr` and `blc-close-brief` skills.

The comment at `install.sh:664` gives the personal agreement as one reason that machine mode
exists. That reason mixes "BLC needs this" with "the author wants this on each machine".

## Why now

A class will install BLC into the repositories of several team members. Each of them runs
the machine step. A person who has no `~/.claude/CLAUDE.md` gets the author's file without
a warning. The machine step asks one y/N for all links, so a person cannot skip only this
link.

## What changes

- `install.sh` machine mode: remove the link, the source check for `personal/CLAUDE.md`, the
  line in the printed plan, and the reason in the comment at `:664`.
- `tests/test_machine_mode.sh` and `tests/test_hosts.sh:222`: change the assertions so that
  machine mode does not link `~/.claude/CLAUDE.md`.
- `README.md`: update the machine-mode description.

## Decided

- **Keep the file. Remove only the link.** `personal/CLAUDE.md` stays in the repository as
  an example that a person can copy if they want it. Machine mode does not link it.
- **Leave existing links alone.** A machine that ran the old machine step has a symlink to
  `personal/CLAUDE.md`. The file stays, so that link continues to work. The machine step
  does not remove it and does not report it. The installer does not change what it no
  longer owns.
