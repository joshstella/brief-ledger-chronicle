---
name: blc-orient
description: >-
  Get oriented in this repository cheaply: what is in flight, what must not be broken, what
  it values. Run this first in an unfamiliar repo. Use when the user asks to blc-orient.
---

# blc-orient

Run `tools/orient.sh` from the repository root and read what it prints.

That is the whole skill. The behaviour lives in the script, deliberately — a script can be
asserted by the test suite and an instruction to an agent cannot, and this repository names
that difference rather than blurring it. This file exists so the capability is discoverable:
an agent arriving with no knowledge of the project will not guess that `tools/orient.sh`
exists, but it will see `/blc-orient`.

## Steps

1. **Run it.** From the repository root: `bash tools/orient.sh`.
   - If the script is missing, this project has the skill without the toolkit's tools.
     Say so and stop; do not reconstruct the output by reading the repository, which is
     the expensive read this exists to replace.
2. **Act on the freshness line first.** If it reports commits behind the upstream, the
   rest of the output is describing a checkout that has already moved. Fetch, then re-run.
3. **Read the rest as an index, not as truth.** It is deliberately lossy. It tells you
   which of the deeper rungs to open — a brief, a ledger, `Manifesto.md` — and it is not a
   substitute for any of them.

## When to run it

- Before starting work in a repository you have not read.
- Before `blc-create-brief`, so you see what is already in flight and who has claimed a
  serial that is not filed yet.
- After a long gap, when your picture of the project is stale.

Roughly 700 tokens, and flat: it costs about the same in a project with two hundred briefs
as in one with two, because it filters to open work rather than listing history.

## What it does not do

- **It does not gate.** Nothing here blocks a commit or fails a build.
- **It does not write.** Its output is never committed; if you find it in a tracked file,
  something has gone wrong.
- **It does not replace the record.** Briefs, ledgers and git remain the truth.
