# Ledger — #0017 Someone else's docs tree

`blc/2 #0017 pending a:pending b:pending c:pending d:pending`

**Brief:** `docs/briefs/0017-blc-docs-tree/brief.md`
**Started:** 2026-10-01
**Status:** pending

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the move | pending | — |
| b | the record | pending | — |
| c | the installer | pending | — |
| d | the contract | pending | — |

The ids and labels are the brief's. What each phase covers changed against the repository, as
the re-plan below records.

**a — the move.** `git mv` `docs/briefs/`, `docs/contracts/`, `docs/chronicles/` and
`docs/state/` under `docs/blc/`. Change the default root in the five tools that take a briefs
directory: `validate-briefs.sh`, `open-briefs.sh`, `list-briefs.sh`, `orient.sh` and
`jira-csv.sh`. Keep each positional argument. `orient.sh` also hardcodes `docs/state`,
`docs/install-log`, `docs/orientation.md`, `docs/chronicles/chronicle.md` and
`docs/contracts/v1.2.md`. Those follow the same root. `gather.sh` hardcodes `docs/briefs` with no
argument, and it gains the same default. Update the source side of `install.sh`, the skills,
templates, `README.md`, `Manifesto.md`, the slides, `.gitignore` and the tests. Tests cover the
new default and the positional override in each tool. Installed targets keep the old layout until
`c`.

**b — the record.** Rewrite the path references inside existing briefs and ledgers so they
resolve. Today that is 153 references in 28 files. This is the brief's settled exception to "The
record is the work". The chronicle is a rendering, so the next chronicle run refreshes it and
`b` does not edit it.

**c — the installer.** `install.sh` writes to `docs/blc/`, the ownership map moves to the new
paths, and an upgrade of an existing install does what open decisions 1 and 2 settle. Blocked by
both.

**d — the contract.** Contract v1.3 re-scopes `BRIEFS-1` to `BRIEFS-10` to the new root.
v1.2 stays published.

## Dependency structure

A strict chain: `a → b → c → d`. The brief allows `b` to run in parallel with `c` and `d`.
That parallel is not taken. Each phase branch writes this ledger's status line, so two open
phase branches conflict on it, as #0016 found. `b` goes before `c` because it is the smaller
change and needs no decision.

The sequence after `a` is provisional until open decisions 1 and 2 are settled. They can
reshape `c`.

## Re-plan against the repository, 2026-10-01

The draft was written on 2026-09-16. Four facts changed under it.

**#0014 published Contract v1.2.** The brief's settled decisions say "Contract goes to v1.2 and
v1.1 stays published" and "v1.2 is published once". v1.2 now exists and covers `BRIEFS-9` and
`BRIEFS-10`. So `d` publishes v1.3, and v1.2 is the version that stays reachable. The intent
of the decisions is unchanged.

**The tree has more readers than the draft counted.** The draft names four tools. There are now
five, because #0007 added `jira-csv.sh`. `gather.sh` in the chronicle skill also hardcodes the
briefs root, and it takes no argument for it. `orient.sh` reads two paths the draft did not
list: `docs/orientation.md` and `docs/contracts/v1.2.md`.

**The numbers in the tension grew.** The draft justifies `b` with "thirteen briefs and twelve
ledgers" and "124 dead links", and it asks that anyone who cites this as precedent cite those
numbers too. Today the figure is 153 references in 28 brief and ledger files. Across all tracked
files it is 636 references in 80 files.

**`#0013` is closed.** The settled decision that it finishes first is met.

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | From the brief: does an upgrade migrate an existing install, or refuse and print instructions? #0012 adds a constraint the brief did not name. The ownership map marks `docs/briefs`, `docs/state` and `docs/chronicles` as project trees, which the installer never changes. Moving them is a change to project-owned files. | `c` |
| 2 | From the brief: what does an install do when `docs/blc/` exists and is not the toolkit's? | `c` |
| 3 | New: does `docs/orientation.md` move to `docs/blc/orientation.md`? The project writes it, the toolkit reads it, and the installer does not ship it (#0008). | `a` |
| 4 | New: the brief's tension says "Once there is a second adopter, the answer changes" about rewriting the record. #0013's evidence came from an install in another repository. Does that install count as a second adopter? If it does, the settled decision behind `b` rests on a condition that no longer holds. | `b` |

## Complications

- `install.sh` names each shipped file twice: as a source path in this repository and as a
  destination in the target. `a` moves the sources and `c` moves the destinations. Between the
  two, the installer reads from the new layout and writes the old one.
- `.gitignore` in this repository, and the block that `install.sh` appends to a target's
  `.gitignore`, name `docs/chronicles/`. An existing target keeps the old rule after an upgrade
  unless `c` handles it.
- The chronicle narrates old paths in past tense. It is a rendering, so `b` leaves it to the
  next chronicle run.
- Merged PR descriptions and commit messages keep the old paths. The brief records this cost
  in its tension.
