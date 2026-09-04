# One chronicle, newest first, with a brief table

**Serial:** #0006 · **Created:** 2026-09-04T16:07:34Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## Ground

A chronicle is a derived rendering. Briefs, ledgers, and git are the record. The skill
writes Markdown a human reads, stamps a closed-through date, and today it writes that
file *outside the repo* — a notes vault, a user-named path — because committed beside
its sources it would drift, and `install.sh` gitignores `docs/chronicles/` so the first
generated file does not show up in `git status` asking to be committed.

That design assumed three things that no longer match the use. The next run writes a
**sibling addendum** that points at the prior file. The spine is **oldest first**: origin,
then eras, then a "where I am now" coda at the bottom. The output path is **not a
project file**.

The ask is one document at a fixed project path, most recent changes at the top,
scrolling down the timeline, and a brief table at the top so the spine is visible
before the prose.

## The claim

**Every BLC project has one chronicle, `docs/chronicles/chronicle.md`.** It opens with a
brief table, then the story, newest last-touch first. Incremental runs prepend new prose
under a refreshed table. They do not start another file. The folder stays; later work
may archive into it. This run does not.

This reverses the "never commit a chronicle" rule from #0003 and the installer. The
chronicle is still derived — it is not the record — but it now lives in the tree at one
path, the same in every project.

## Evidence

**1. Incremental mode writes a new file.** `skills/chronicle/SKILL.md` steps 1 and 6:
find the most recently modified `*chronicle*.md`, read
`<!-- chronicle:closed-through:YYYY-MM-DD -->`, pass that date to `gather.sh`, and open
the new file with *"This continues from `<prior-filename>`…"*. Do not retell prior
eras. The prior file stays. After a few runs the story is a stack of files.

**2. The spine is oldest first.** Voice & structure: chronology from git first-commit
dates; group into eras; close with a current-state coda. `gather.sh` sorts briefs on
first-commit, ascending. The commits section is already newest first (`git log`). The
digest disagrees with itself on direction.

**3. There is no brief table.** The digest lists briefs as bullets: slug, first, last,
commit count, planned/executed, depends-on. No title. No ledger status. The skill never
puts that list at the top of the chronicle as a table.

**4. Incremental gather cannot fill a full table.** When a cutoff is set, `gather.sh`
omits briefs with no commit after that date. A table built from that digest would show
only the increment. A table of the timeline needs every brief.

**5. The output is outside the project.** The skill says write to a user-named path
outside the tracked tree. `install.sh` appends `docs/chronicles/` to `.gitignore` and
says the skill forbids committing one. `tests/test_project_mode.sh` asserts that ignore.
#0003's brief states a chronicle is "deliberately never committed as a source of truth."
The folder exists. The file is not allowed to.

**6. A skill change is an instruction.** Same class as #0005 open decision 4. The suite
exercises `gather.sh`. It does not exercise what the skill tells the agent to write.
The table in the digest is the checkable part.

## Change

Four phases. The digest comes first because the table is gather's job and the skill
consumes it. The path and ignore land with the skill so the writer has one place to
put the file.

| Phase | Work |
|---|---|
| 1 — the digest | `gather.sh` emits a Markdown table of every brief, newest last-touch first, on full and incremental runs. Columns: serial, title, status, first, last, depends-on. Title is the first `#` line of `brief.md`. Status is the overall token on the ledger `blc/1` line, or `planned` if there is no ledger. Incremental filtering stays for the commits section and for which briefs are *new to narrate*. The table is not filtered. |
| 2 — the check | Tests in `tests/test_gather.sh` for the table: last-touch order, title, status, full table under a cutoff, planned when there is no ledger. |
| 3 — the skill and the path | Rewrite `skills/chronicle/SKILL.md`: write only `docs/chronicles/chronicle.md`; refresh the table from gather; prepend new era prose under it; update the closed-through marker; do not write a sibling. Drop the notes-vault path. Present-tense paragraph after the table; origin at the bottom. |
| 4 — the ignore | Stop hiding `chronicle.md`. Keep the folder. Installer, `.gitignore` rule, and `tests/test_project_mode.sh` change so the one file can sit in git. Other files in `docs/chronicles/` may stay ignored so a later archive feature has a place. README and slides that still say "never committed" get the same pass. |

Phase 1 precedes 3 because the skill should paste a table the digest already shaped.
Phase 2 is the check for phase 1. Phase 4 can land with 3 or just after; landing the
skill while the ignore still drops the file would leave `chronicle.md` untracked, which
is the old rule under a new name.

## Tension

The Manifesto and the skill call a chronicle the story of *becoming*. That story reads
naturally oldest first. Newest-first is a reading order for someone who already knows
the origin and wants what moved. This brief takes the reading order. The origin stays
in the file. It moves to the bottom.

#0003 treated "derived" and "uncommitted" as one property. They are not. A Contract is
derived *and* committed because someone else builds against it. A chronicle is derived
and was uncommitted so it could not drift against the record *as if it were* the
record. Putting `chronicle.md` in the tree accepts drift as a refresh cost: the next
run updates the file. That is a real reversal. It is not a Contract clause.

Prepend freezes old wording, including error, until someone asks for a full rewrite.
That is the cost of not retelling.

## Settled decisions

- **Last-touch is "most recent."** Table rows and era order follow last commit on
  that brief's path. First-commit stays a column. A brief that started early and
  moved yesterday sits at the top.
- **`gather.sh` emits the table.** Same columns every run. Checkable. Incremental
  mode still emits the *full* table.
- **Prepend new prose.** Refresh the table and the marker. Do not rewrite prior
  eras on an incremental run.
- **One file, one path:** `docs/chronicles/chronicle.md`. No siblings. No
  user-named vault. The folder stays for a later archive feature; this brief does
  not add one. Edit the file in place.
- **Table columns include title and status.** Serial, title, status, first, last,
  depends-on. Status from the ledger `blc/1` overall token, or `planned`.
- **Closed-through stays.** Last line of the one file. Cutoff for new prose only.
- **A skill guard is not a check.** Phase 3 is labelled that way. See #0005.
- **The chronicle is still not the record.** Briefs, ledgers, and git are. The
  file in the tree is a rendering that a later run is allowed to refresh.

## Open decisions

None at filing. The five that blocked the draft were resolved 2026-09-04.

## Non-goals

- **Not an archive feature.** The folder is left in place. No rotation, no dated
  copies, no `chronicle-2026-09.md`.
- **Not a Contract clause.**
- **Not changing the 60-commit ceiling** or the no-depends-on path except as the
  table requires.
- **Not a full rewrite of old era prose** on every run.

## Success criteria

- `gather.sh` prints a complete brief table, newest last-touch first, with title
  and status, including when a cutoff is set. Tests say so.
- A reader opens `docs/chronicles/chronicle.md` and sees that table, then the
  newest work, then older work.
- A second run edits that file. It does not add a sibling.
- The file is not gitignored. Other files under `docs/chronicles/` may be.
- Phase 3 does not claim to be a check.
