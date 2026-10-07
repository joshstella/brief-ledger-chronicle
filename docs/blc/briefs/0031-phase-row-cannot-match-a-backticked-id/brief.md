# phase-row.sh cannot match a backticked phase id

**Serial:** #0031 · **Created:** 2026-10-07T09:55:00Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## The finding

`tools/lib/phase-row.sh` line 42 reads

```
pattern="^\|[[:space:]]*~*\`?${idx}[[:space:]]*(\||—)"
```

It allows an opening backtick and provides for no closing one. `` | `a — label` | `` matches.
`` | `a` | label | `` does not, and every phase in such a ledger then reports as missing from
its own table under `BRIEFS-9`.

Seen twice in one project, which rewrote its ledgers into the accepted shape both times.
Still present at `2f6aa89`. Found on 2026-10-06 while installing into a real project.

Split out of #0026, which found it and does not fix it.

## Why it matters

The gate reports a defect that is not in the ledger. A contributor who trusts the gate rewrites
a correct table into a different correct table, and learns that the tool is unreliable. A
contributor who does not trust the gate stops reading its output.

## What the survey settled before filing

**It is one site, not a class.** Every pattern in `tools/` that mentions a backtick was read.
`phase-row.sh:42` is the only one with the asymmetry. `phase-row.sh:75` and `:101` strip
backticks out of a cell, which is right, and `identity-line.sh:59` excludes the backtick from
the characters an address may hold, which is a different job.

**The repository has already answered the shape question once.** `tools/lib/status-line.sh`
removes every backtick on the line before matching, and says why: no status line carries one
anywhere else, so stating that is safer than trusting "the surrounding pair". Reading the id
the same way makes the two readers agree, and it is what `phase-row.sh` already does to the
cells it returns.

## What is undecided

1. **Whether the pattern strips backticks or accepts them.** Stripping follows
   `status-line.sh` and makes both ledger shapes legible. Accepting a closing backtick fixes
   the reported row and leaves `` | ``a`` | `` style variants failing. Stripping is the
   expected answer; it is written here as the open one because the fix has not been built.
2. **Whether `~` interacts.** The pattern allows leading `~` for a struck-through phase. A
   struck *and* backticked id — `` | ~~`a`~~ | `` — is a shape nobody has reported and the
   test should say which way it goes.

## The test that would have caught it

A ledger whose phase table uses `` | `a` | label | ``. Assert that `BRIEFS-9` reports no
missing phase.
