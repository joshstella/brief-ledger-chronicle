# Ledger — #0017 The BLC docs tree

`blc/2 #0017 in-progress a:done(PR#80) b:done(PR#81) c:in-progress(brief/0017-c-the-installer) d:pending`

**Brief:** `docs/blc/briefs/0017-blc-docs-tree/brief.md`
**Started:** 2026-10-01
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the move | done (PR#80) | — |
| b | the record | done (PR#81) | — |
| c | the installer | in-progress | `brief/0017-c-the-installer` |
| d | the contract | pending | — |

The ids and labels are the brief's. What each phase covers changed against the repository, as
the re-plan below records.

**a — the move.** `git mv` `docs/briefs/`, `docs/contracts/`, `docs/chronicles/`,
`docs/state/` and `docs/orientation.md` under `docs/blc/` (decision 3). Change the default root
in the five tools that take a briefs directory: `validate-briefs.sh`, `open-briefs.sh`,
`list-briefs.sh`, `orient.sh` and `jira-csv.sh`. Keep each positional argument. `orient.sh` also
hardcodes `docs/state`, `docs/install-log`, `docs/orientation.md`,
`docs/chronicles/chronicle.md` and `docs/contracts/v1.2.md`. Those follow the same root.
`gather.sh` hardcodes `docs/briefs` with no argument, and it gains the same default. A fresh
install writes to `docs/blc/`: `install.sh` sources, destinations, ownership map and appended
`.gitignore` block all move here (re-plan below). Update the skills, templates, `README.md`,
`Manifesto.md`, the slides, `.gitignore` and the tests. Tests cover the new default and the
positional override in each tool. Publish Contract v1.3, which was `d` (re-plan below).

**b — the record.** Rewrite the path references inside existing briefs and ledgers so they
resolve. When `a` merged, that was 166 references in 33 files: 29 brief and ledger files and the
four drafts. This is the brief's settled exception to "The record is the work". Two kinds of
reference keep the old path, settled 2026-10-01. #0017's own brief and ledger describe the move,
so they are not rewritten. A line that tells what an older version did keeps the path that
version used. Add `a`'s squash commit to `docs/blc/ignore-revs`. The chronicle is a rendering, so
the next chronicle run refreshes it and `b` does not edit it.

**c — the installer.** An upgrade of an install that has the old layout moves the old trees
under `docs/blc/` and writes each move to the install log (decision 1). Before it moves or writes
anything, it checks `docs/blc/`. If that directory is empty or absent, the install continues. If
it holds files that are not the toolkit's, the install stops and says why (decision 2). A fresh
install is already correct after `a`.

**d — the contract.** Contract v1.3 re-scopes `BRIEFS-1` to `BRIEFS-10` to the new root.
v1.2 stays published. Done in `a` instead. `d` stays `pending` until `c` is settled, because
the upgrade path may need a clause. If it does not, `d` is `skipped`.

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

**A fresh install moves into `a`, settled 2026-10-01.** Everything `a` changes also ships:
the tools, the skills, the shipped READMEs and the templates. In the brief's split, `install.sh`
on `main` would install tools that read `docs/blc/briefs` into a target where it creates
`docs/briefs`, from the merge of `a` to the merge of `c`. So `a` also moves where a fresh install
writes, and `c` keeps only the upgrade of an existing install. The cost: an upgrade of an
existing install is broken between `a` and `c`. There is one user. A fallback in each tool to
`docs/briefs` was rejected, because it is a third layout the brief does not plan for.

**Contract v1.3 moves into `a`, settled 2026-10-01.** The reason is the same as for the fresh
install. Every Contract version ships, and v1 to v1.2 say they cover `docs/briefs/`. A fresh
install from `main` after `a` would hold a Contract about a directory it does not have, until
`d` merged. A test caught this in `a`. v1.3 changes the root and nothing else: the clause
text, the tags and the checks are the same. v1.2 is marked superseded and its text is not
edited, which keeps the settled "v1.2 stays published". Rejected: mark the old paths as not
in an installed copy until `d`, which keeps an install inconsistent on purpose for two phases.

**A success criterion is narrowed, settled 2026-10-02.** The brief says "Every path reference
inside a brief or ledger resolves." After `b`, that is false on purpose. It now reads: every
reference to a document inside a brief or ledger resolves. A line that records what a tool did
with a path keeps the path the tool used, and #0017's own brief and ledger keep the paths they
describe moving. Four rewritten paths do not resolve here and never did: a draft that became
#0015, the install log that exists only in a target, and a state file that was never committed.
The brief's text is not edited.

**The brief is retitled.** The draft was "Someone else's docs tree". On filing, its slug became
`blc-docs-tree`, and on 2026-10-01 the title was changed to match: "The BLC docs tree".

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | **Settled 2026-10-02: the install moves them and logs each move.** From the brief: does an upgrade migrate an existing install, or refuse and print instructions? #0012 adds a constraint the brief did not name: the ownership map marks `docs/briefs`, `docs/state` and `docs/chronicles` as project trees, which the installer never changes. This move is the one exception. It changes where project files are, not what they hold, and the install log names each one, so the project can see and reverse it. Rejected: refuse and print instructions, which leaves every upgrade to a hand-run move. | `c` |
| 2 | **Settled 2026-10-02: an empty `docs/blc/` is used, and one with files stops the install.** From the brief: what does an install do when `docs/blc/` exists and is not the toolkit's? If `docs/blc/` is absent or empty, the install continues. If it holds files, the install stops before it changes anything and says why, so the project moves its own files first. A `docs/blc/` that the toolkit installed is not a stop: a second install and an upgrade both meet one. | `c` |
| 3 | **Settled 2026-10-01: it moves.** `docs/orientation.md` becomes `docs/blc/orientation.md`. `orient.sh` reads it, and the brief's claim is one root for what the toolkit uses. | `a` |
| 4 | **Settled 2026-10-01: still one user.** #0013's evidence came from an install in another repository owned by the same person. The condition behind `b` holds. | `b` |
| 5 | **Settled 2026-10-01: dates follow renames and skip an ignore list.** The move reset every brief's first and last dates to the move commit, because `git log -- <dir>` does not follow a rename. `b` would then reset every last date again, because its rewrite is a real content change. The new `tools/lib/touch-log.sh` follows each tracked file back through its rename records and drops the commits that `docs/blc/ignore-revs` names. It does not use `git log --follow`, the first version, because `--follow` also follows copies: a test found a new ledger taking an older brief's history from a near-identical ledger. `list-briefs.sh`, `gather.sh` and `orient.sh` all read dates through it. Rejected: follow renames only, which loses the timeline at `b`. Accept the reset, which loses it at `a`. Drop `b`, which reverses a settled decision. The cost is a list kept by hand, against "derived beats declared". | `a` |
| 6 | **Settled 2026-10-01: "first" means when the brief was written.** Following renames moves some first dates earlier, because the old reader lost history at each folder rename. "First" is now the first commit of the brief's text, including its time as a draft. Rejected: the ledger's first commit (when work started), and both as two columns. `Created:` is not a source. It is written by hand, and #0005's is 18 hours after its first commit. | `a` |
| 7 | **Settled 2026-10-01: `validate-briefs.sh` reads `brief-checks/` from the working directory.** It found the root by depth above the briefs directory. The move made that depth three, and then the old `docs/briefs` layout, which the positional argument keeps, resolved to the repository's parent: review reproduced it running the parent's checks and skipping the repository's own. Every other tool already says "Run from the repository root". Rejected: git's top level, because the validator runs without a repository. Depth for the default path only, because it drops project checks without saying so for every other path. | `a` |

## Complications

- `.gitignore` in this repository, and the block that `install.sh` appends to a target's
  `.gitignore`, name `docs/chronicles/`. An existing target keeps the old rule after an upgrade
  unless `c` handles it.
- The chronicle narrates old paths in past tense. It is a rendering, so `b` leaves it to the
  next chronicle run.
- Merged PR descriptions and commit messages keep the old paths. The brief records this cost
  in its tension.
- An upgrade of an old-layout install between `a` and `c` splits its install log. The old log
  stays at `docs/install-log/`, and the installer starts a new one at `docs/blc/install-log/`.
  The installer finds no previous entries, so it removes no stale toolkit paths. That is safe,
  and `c` has to join the two logs.
- A squash commit has no hash until its PR merges. So `b`'s branch adds `a`'s squash commit to
  `docs/blc/ignore-revs`, and `c`'s branch adds `b`'s. Between the merge of `a` and the merge
  of `b`, every brief shows the move as its last touch.
- An upgrade of an existing install moves that target's tree in its own commit. That target
  needs the commit in its own ignore list, or its dates reset (decision 5). `c` has to handle
  this.
- `a`'s squash commit records this ledger as a delete and a create, not a rename: `a` changed it
  too much for git to match the two. So the reader cannot follow it back, and with that commit
  ignored, the commits to this ledger on `main` before the move do not count. #0017's last date
  is its brief's last commit before the move, until a later commit touches it. Only #0017 is
  affected. The other moved files were renamed with small changes.
