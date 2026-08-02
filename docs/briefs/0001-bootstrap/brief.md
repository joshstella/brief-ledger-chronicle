# Bootstrap: brief-ledger-chronicle repository

**Serial:** #0001 · **Created:** 2026-08-02T17:40:00Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## Overview

Create **brief-ledger-chronicle** as the Cursor-native home for the brief/ledger/review workflow,
ported from claude-process-automation. Skills install to `.cursor/skills/`; project rules
live in `AGENTS.md`. No Claude Code CLI dependency.

## Settled decisions

- Repo name: `brief-ledger-chronicle`.
- Workflow commands become Cursor skills (one directory per skill under `skills/`).
- Installer requires only `git` and `gh`.
- Per-project skill install (`.cursor/skills/`), idempotent, never overwrite.

## Open decisions

- Whether to publish skills globally to `~/.cursor/skills/` as an optional install mode.
- Whether to add a structural validator script for brief invariants (CI hook).

## Phases

Single atomic creation — recorded in the ledger.
