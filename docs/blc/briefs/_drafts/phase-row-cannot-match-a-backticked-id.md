# phase-row.sh cannot match a backticked phase id

**Created:** 2026-10-07T09:55:00Z · **Author:** josh.stella@gmail.com
**Depends on:** —

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

## What is undecided

1. **Whether the pattern accepts the closing backtick, or whether the shape is wrong.** Both
   ledger shapes are legible to a person. Only one is legible to the gate. If one shape is the
   rule, the gate should say so rather than silently failing the other.
2. **Whether any other pattern in `tools/lib/` has the same asymmetry.** One was found by a
   failure; the rest were not looked at.

## The test that would have caught it

A ledger whose phase table uses `` | `a` | label | ``. Assert that `BRIEFS-9` reports no
missing phase.
