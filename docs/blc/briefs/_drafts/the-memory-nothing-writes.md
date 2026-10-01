# The memory nothing writes

**Created:** 2026-09-22T11:45:00Z · **Author:** josh.stella@gmail.com
**Depends on:** #0014

## The finding

Three shipped skills write to a memory layer that has never existed in this repository.

| skill | step | what it writes |
|---|---|---|
| `blc-review-pr` | 8 | a bug ledger keyed by branch, `review-<branch>.md`, entries flipped `open` → `fixed` on re-review |
| `blc-start-brief` | 74 | a `project` memory file `brief-<kebab>.md`, "same content" as the ledger |
| `blc-next-brief-phase` | 46 | "update the memory file and MEMORY.md in place" |

Two of them also *read* it. `blc-start-brief` step 25 and `blc-next-brief-phase` step 20 both
name `MEMORY.md` as the fallback for locating a brief when the repo ledger is not found.

There is no `MEMORY.md` in this repository, no memory directory, and no `review-*.md` or
`brief-*.md` file anywhere in the tree or outside it. Fourteen briefs have run through these
skills and the layer has been skipped every time, by every agent, without comment.

## Why it went unnoticed for fourteen briefs

Because the primary record is good enough in the session that writes it. The ledger in
`docs/briefs/<name>/ledger.md` is the source of truth and it is always present, so the
fallback path — "if no repo ledger found, read MEMORY.md" — has never been taken. A fallback
that is never reached cannot be discovered to be missing.

The bug ledger is different, and this is the part that has a cost. `blc-next-brief-phase`
step 3 says the previous phase's open correctness bugs "come before new work". That
instruction has never been executable. It did not bite during #0014 phase `b` only because
the review, the fixes and the next phase all happened inside one conversation, so the bugs
were carried in context rather than in a file. Two independent reviewers each asked where the
bug ledger lived, could not find it, and declined to guess — so neither review round produced
one, and the four confirmed bugs from the first round survived to be fixed because a human was
in the loop, not because anything recorded them.

## The uncomfortable part

This is the defect #0014 was written about, inside the tooling #0014 is written with: a record
that describes a mechanism, and no mechanism. #0014 phase `a` shipped a guard that could not
fail, phase `b` shipped two more, and underneath all three the process layer has been
asserting a durable memory that nothing has ever written.

## What is actually undecided

1. **Where it lives.** `project` memory is a host concept, and hosts differ — the two agent
   stores on this machine are empty, so nothing has claimed the term. If it lives in the repo
   it is a new toolkit-owned path in the ownership map, and a new thing the installer ships.
   If it lives outside the repo it does not survive a fresh clone, which is most of what the
   bug ledger is for.
2. **Whether the brief mirror is worth anything.** `brief-<kebab>.md` is documented as "same
   content" as the ledger. A second copy of a file that is already in git, kept in sync by
   hand, is the hand-sync #0003 phase 4 deleted between the two briefs READMEs. That argues
   for cutting it rather than building it.
3. **Whether the bug ledger is worth something separately.** It is not a mirror — it holds
   state no other file holds, namely which correctness findings from a review are still open.
   It is the half with a live consumer (`blc-next-brief-phase` step 3) and no substitute.

The likely shape is therefore *not* "build the memory layer". It is: keep the bug ledger,
decide where it lives, and strip the mirror and the `MEMORY.md` fallbacks from the three
skills, because fourteen briefs are evidence the primary record does not need a shadow.

## Non-goals

- Not a general memory or context system.
- Not a second copy of any ledger.
- Not changing where the source of truth lives: `docs/briefs/<name>/ledger.md` stays it.
