# The installer cannot take anything back

**Created:** 2026-09-09T11:35:00Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## Ground

`install.sh` only ever adds. It copies files in, skips what exists, and replaces on
`--force`. Nothing in it removes a file the toolkit shipped in an earlier version and no
longer ships.

That was harmless while the toolkit only grew. #0010 ended it: nine skills were renamed to
`blc-<name>` and `to-do` was deleted outright. A project that installed before that and
reinstalls after gets the nine new skills **beside** the ten old ones. The old copies are
not inert — they are valid skills the host will offer, they still instruct `feature/`
branch names and `blc/1` ledgers, and half of them now have a near-identical twin one
letter away in the same menu.

#0010 saw this and declined it, on the record and with a reason:

> No migration path was correct exactly once — one install, owned by the author, renamed
> before anyone else adopted the toolkit. The next rename will have to build what this one
> skipped. This brief should not be cited as precedent for skipping it again.

The count of installs is no longer one. There is a project carrying an old copy, and the
toolkit is about to be handed to a team.

## The claim

**The install log is already the ownership record. Removal reads it and nothing else.**

Every run appends an entry naming every skill and command it installed:

```
### Skills installed

  - blc-chronicle
  …
### Commands installed
```

So the stale set is a difference, not a list: *everything a previous entry says was
installed, that the current source no longer ships.* A skill the log has never named was
not put there by this toolkit, and is never touched.

That gives deletion a derived source of truth instead of a hardcoded roster of old names —
which would rot exactly the way the names it names rotted. It is the same move #0008 made
when it read the log for "off-limits" rather than restating `install.sh`'s internals.

**No log, no deletion.** An absent or silent log is absent evidence, and the installer
treats absence as "not mine".

## Evidence

**1. The log already carries what is needed, in every target, and has since before this
was a problem.** `install.sh` writes `### Skills installed` and `### Commands installed`
with the full list on every run, appended, never rewritten. Nothing new has to be recorded
for this to work on projects that already exist.

**2. #0008 proved the log is usable as a derived ownership source in a target.**
`tools/orient.sh` reads it for the "off-limits" section, specifically because `install.sh`
is not present in an installed project and restating its rules would drift. The same
reasoning applies here, and the parsing is already written.

**3. Deletion is not unprecedented in this installer.** `place_dir` already runs
`rm -rf "$dst"` under `--force`. What is new is removing something the current run is *not*
about to rewrite.

**4. The failure is silent and it compounds.** A stale skill does not error. It is offered
by the host beside its replacement, and an agent that picks `start-brief` over
`blc-start-brief` writes a `blc/1` ledger and a `feature/` branch into a project whose
tools have moved on — a whole class of drift that looks like the workflow working.

**5. The blast radius is known exactly.** Ten skills, plus six command files on a Claude
Code host. Not a guess: it is #0010's own change list.

## Change

| Phase | Work |
|---|---|
| `a — the reading` | Parse the install log into "what previous installs put here": the union of every `### Skills installed` and `### Commands installed` list across entries. Read-only, no removal, tested against a log with several entries, a log with one, a malformed log, and no log at all. |
| `b — the difference` | Compute stale = logged − currently shipped. Report it and stop. This is the whole feature minus the irreversible part, and it is the form the first release should take. |
| `c — the removal` | Delete the stale set, behind whatever gate the open decisions settle. Refuse when the log is absent. Never follow a symlink out of the target. Record what was removed in the new log entry, so the record of a removal is as durable as the record of an install. |

## Tension

**Deletion is the one act this installer cannot walk back, and its entire posture is the
opposite.** Every other behaviour is never-clobber: skip what exists, refuse authored
config, append to `.gitignore` rather than rewrite it. A prune that is wrong destroys work
no `--force` flag was asked for. That asymmetry is why phase `b` stops at reporting.

**The log records what was written, not who owns it now.** #0008 hit this and worked around
it. A shipped skill a project has since edited in place looks identical to one it never
touched, and deleting it loses that edit silently. Nothing in the log distinguishes them.

**A symlinked skills directory turns a prune into a delete of the source.** This repository
just committed `.cursor/skills → skills/` so Cursor can load its own skills. Any removal
that walks that path deletes the toolkit's source tree, not a stale copy. The installer
refuses to install into itself, which makes this unreachable *here* — but a target is free
to symlink, and nothing would stop it.

**A rename is indistinguishable from a delete plus an add.** The log has no concept of
identity across a rename, so `chronicle → blc-chronicle` is recoverable only as "the old
one is gone, the new one is here". That is sufficient for removal and useless for anything
that wants to migrate content — a project that added notes inside `skills/chronicle/`
cannot have them carried forward.

**Pre-log installs are unreachable.** Any target installed before the log existed has no
evidence, so it gets no cleanup and must be done by hand. This cannot be fixed later: the
information was never written.

## Settled decisions

- **The log is the only ownership evidence.** No hardcoded list of old skill names, ever.
  Such a list would need editing at exactly the moments people forget, which is the failure
  #0010 already had.
- **Absence of evidence is absence of ownership.** No log, no entry, no removal.
- **Reporting ships before removing.** Phase `b` is releasable on its own and phase `c` is
  not required to follow immediately.
- **A removal is logged like an install.** The new entry names what it deleted. An
  append-only record that omits its own destructive acts is not a record.

## Open decisions

1. **Is removal default or opt-in?** A flag is safer and will be forgotten by exactly the
   people who need it. Default is correct and is the irreversible choice. Blocks `c`.
2. **Does it prune anything besides skills and commands?** Stale `tools/` scripts and docs
   have the same problem and a much worse blast radius. Blocks `c`.
3. **What happens when the target's copy differs from what was shipped?** Detectable by
   hashing, but the log records no hash, so this only works from now on. Blocks `c`.
4. **Does `--force` change the answer?** Today it means "take upstream's copy". It could
   reasonably mean "and drop what upstream no longer has". Blocks `c`.

## Non-goals

- **Not a migration of content.** Nothing is carried from an old skill into its renamed
  successor. The log cannot support it and this brief does not attempt it.
- **Not a version-aware upgrade path.** There are no toolkit versions to reason about,
  only what a log entry says was installed.
- **Not a fix for pre-log installs.** Stated as unreachable above.
- **Not a change to never-clobber.** Authored config keeps every protection it has.

## Success criteria

- A project holding the pre-#0010 skill set is told, exactly and by name, which of its
  installed skills the toolkit no longer ships.
- A skill the log never recorded is never named and never removed, including one whose name
  happens to match an old toolkit skill.
- A target with no install log gets no removal and a clear statement of why.
- After a removal, the log entry for that run names what was deleted.
- The suite proves a removal is refused when it would leave the target, including through a
  symlinked skills directory.
