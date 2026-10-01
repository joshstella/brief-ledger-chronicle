# Declarations — `docs/state/`

One file per contributor, holding **only what the record cannot derive**.

Everything else about the state of this repository is computed. Which briefs are open,
which phases are in flight, which branches exist, what landed and when — all of that is
read out of the ledgers and git, and a declaration that repeated it would be a second
copy that goes stale. This directory exists for the one thing derivation structurally
cannot reach: **work you have picked up that is not in the record yet.**

A ledger begins at `blc-start-brief`, which runs *after* `blc-create-brief` has already
chosen a serial. Between deciding to work on something and filing it, you are invisible.
That window is where two contributors pick the same serial, or quietly start the same
work. A declaration is how you become visible during it.

## The file

`docs/state/<your git email, lowercased>.md`

    git config user.email        →  Josh.Stella@Example.com
    docs/state/josh.stella@example.com.md

Lowercased, and otherwise verbatim. `@` and `.` are legal in a path, so nothing is
escaped or slugged. The mapping runs both ways — given the file you know the contributor,
given the contributor you know the file — which matters because the whole point is that
someone else can read it.

**You write your file and no one else's.** That is the entire concurrency story. Two
contributors declaring at the same moment touch different paths, so there is nothing to
merge and nothing to clobber. It is `#0005`'s *one owner, one narrative* applied past the
ledger, and it is why this is a directory rather than a shared file.

## What goes in it

Two things:

- **Work picked up but not yet filed.** You are starting on something and there is no
  brief for it yet.
- **A serial about to be claimed.** You are about to run `blc-create-brief` and intend to
  take the next number.

That is the list. If something can be read out of a ledger, a branch, or a commit, it
does not belong here.

## What does not

- **Not a status report.** Progress on filed work is in its ledger.
- **Not a standup.** Nothing here is written on a schedule, and nothing is written for a
  human audience to skim.
- **Not recurring.** You write when you pick something up and clear it when it lands.
  A declaration nobody has cleared is a bug, not a history.
- **Not a place to think out loud.** Drafts go in `docs/briefs/_drafts/`.

## Writing one

```markdown
# josh.stella@example.com

## 2026-09-09 — claiming #0011

About to file a brief on the installer's dependency check. Taking serial 0011.

## 2026-09-09 — picked up, not filed

Looking at why the chronicle's incremental mode re-narrates the last era. No brief yet.
```

A date on each entry, a line saying what it is, and nothing else. The date is load-bearing:
nothing prunes this directory automatically, so `orient` reports how old each entry is and
a stale declaration shows up as stale rather than as truth. Clearing an entry is deleting
it — an empty file, or no file at all, is the correct steady state for someone with
nothing unfiled.

## Reading them

**Don't.** Run `orient`, which aggregates every declaration into a few lines.

This is not a style preference. The value of this directory is that orientation costs the
same whether the project has two contributors or twenty, and that property only holds if
readers go through the tool. Twenty declaration files read directly is twenty files' worth
of tokens, which is the cost this whole design exists to avoid. `docs/state/` is a
*source*. If anyone is opening it by hand, the thing it was built for has already broken.
