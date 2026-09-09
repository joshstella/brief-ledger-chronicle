# An install is not an update

**Serial:** #0012 · **Created:** 2026-09-09T11:39:00Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## Ground

Run `install.sh` against a project that already has the toolkit and it adds what is
missing, **skips everything that already exists**, and removes nothing. `--force` is the
only path that replaces anything, and nothing at all prunes.

So there is no update. There is a first install, and after that a series of runs that fill
gaps and leave the rest exactly as it was.

That was survivable while the toolkit only grew. #0010 ended it by renaming nine skills to
`blc-<name>` and deleting `to-do`, and #0009 changed the ledger schema underneath them.
A project that installed before those and reinstalls after gets a specific, quiet mess:

- The nine renamed skills land **beside** the ten old ones. Both sets are valid, both are
  offered by the host, and the old ones still teach `feature/` branches and `blc/1`
  ledgers.
- `tools/open-briefs.sh` and `tools/validate-briefs.sh` already exist by those exact names,
  so they are **skipped**. The project keeps pre-`blc/2` tools and runs them under
  `blc/2`-era skills.
- The shipped docs under `docs/briefs/` are skipped for the same reason, so the
  instructions stay whatever they were on the day of first install.

None of that errors. It reads as the workflow working.

#0010 predicted the bill and named who would pay it:

> The next rename will have to build what this one skipped. This brief should not be cited
> as precedent for skipping it again.

## The claim

**The installer owns the paths it ships. On every run it replaces them, and removes the
ones it no longer ships.**

Not "if forced". By default, because a toolkit that only updates when someone remembers a
flag is a toolkit that is mostly out of date.

The line is ownership, not existence:

| | policy | examples |
|---|---|---|
| **Toolkit-owned** | replaced every run, pruned when upstream drops it | `skills/`, host command files, `tools/*.sh`, `docs/briefs/README.md`, `docs/contracts/*` |
| **Project-owned** | never written after creation, never removed | `AGENTS.md`, `.gitignore`, `docs/briefs/NNNN-*/`, `docs/state/*`, `docs/orientation.md`, chronicles |

**Local edits to toolkit-owned files are lost on the next install, by design.** That is the
trade being made deliberately: a file with two writers has no owner, and the alternative —
skipping anything that looks touched — is what produced the drift above. It has to be said
out loud, in the shipped rules and in the installer's own output, not discovered.

**Removal reads the install log and nothing else.** Every run appends `### Skills installed`
and `### Commands installed` with the full list. Stale is a difference: everything a
previous entry recorded, that the current source no longer ships. A path the log never
named was not put there by this toolkit and is never touched. No log, no removal.

## Evidence

**1. Skipping is the current default and it is silent.** `place_file` and `place_dir` both
log a skip and move on. A project three toolkit versions behind gets a clean-looking run
reporting nothing wrong.

**2. The log already carries the ownership evidence, in every target, written before this
was a problem.** No new recording is needed for projects that already exist.

**3. #0008 already proved the log works as a derived ownership source.**
`tools/orient.sh` reads it for "off-limits" precisely because `install.sh` is absent in a
target and restating its rules would drift. Same reasoning, same parsing.

**4. The toolkit has now shipped two breaking changes in a row.** #0009 changed the ledger
schema; #0010 renamed every skill. Both are exactly the kind of change that a
gap-filling installer cannot deliver, and there is no reason to expect them to be the last.

**5. Deletion is not new here.** `place_dir` already runs `rm -rf` under `--force`. What is
new is removing something the current run is not about to rewrite.

**6. The blast radius is known, not estimated.** Ten skills, six command files on a Claude
Code host, three tools, and the shipped docs — #0010's and #0009's own change lists.

## Change

| Phase | Work |
|---|---|
| `a — the ownership map` | One declared list of what the toolkit owns, replacing the knowledge currently spread across `install.sh`'s ship loops and comments. Every later phase reads it. No behaviour change. |
| `b — the replace` | Toolkit-owned paths are written on every run, not skipped. Decide what `--force` still means once this lands. Project-owned paths keep every protection they have. |
| `c — the prune` | Remove toolkit-owned paths the log says were installed and the source no longer ships. Refuse without a log. Never follow a symlink out of the target. Record removals in the run's own log entry. |
| `d — the socialization` | Say it where it will be read: shipped rules, installer output, `README.md`. Editing a `blc-` skill or a `tools/` script in a project is temporary, and the next install takes it back. Customizing means changing the toolkit, not the copy. |

## Tension

**This inverts the installer's founding posture, and the posture was not arbitrary.**
Never-clobber exists because an installer that overwrites is an installer people stop
trusting. The defence is that ownership is now explicit and narrow: nothing a project
authors is touched. The risk is that the boundary is wrong somewhere and the failure is
silent data loss rather than a skipped file.

**A symlinked skills directory turns a prune into a delete of the source.** This repository
committed `.cursor/skills → skills/` so Cursor can load its own skills. Removal that walks
that link deletes the toolkit, not a stale copy. Self-install is refused here so it cannot
happen in this repo, and nothing stops a target from doing the same thing.

**"Your edits will be lost" is a policy, not a mechanism.** Nothing detects an edit and
nothing warns before taking it. A project that has quietly customized a skill for months
finds out on the run that removes it. Detecting it needs a hash the log does not record and
could only record from now on.

**Pre-log installs are unreachable.** A target installed before the log existed has no
evidence and gets no cleanup. The information was never written and cannot be recovered.

**A rename is indistinguishable from a delete plus an add.** Nothing carries content from
`skills/chronicle/` to `skills/blc-chronicle/`. Notes a project kept inside a skill
directory are lost rather than moved, and the log cannot support better.

**Replacing every run makes the toolkit's own bugs arrive faster.** Today a project is
insulated from a bad release by being out of date. That insulation is the same mechanism as
the drift, and removing one removes the other.

## Settled decisions

Resolved 2026-09-09 during drafting.

- **Replacement and removal are the default.** Not a flag. A toolkit that updates only when
  someone remembers a flag is mostly out of date.
- **Local changes to toolkit-owned files are lost, and this is socialized rather than
  mitigated.** No detection, no warning-and-skip. Skipping what looks touched is the
  behaviour that caused this.
- **Ownership is the line, not existence.** Project-authored files keep every protection.
- **The log is the only ownership evidence.** No hardcoded roster of old names — such a
  list needs editing at exactly the moments people forget, which is how #0010 got here.
- **Absence of evidence is absence of ownership.** No log, no entry, no removal.
- **A removal is logged like an install.** An append-only record that omits its own
  destructive acts is not a record.

## Open decisions

1. **What does `--force` mean once the default replaces?** It may have no job left, or it
   may become the flag that overrides project-owned protection. Blocks `b`.
2. ~~Does `d` ship a way to customize legitimately?~~ **Answered 2026-09-09, elsewhere.**
   The supported answers are `AGENTS.md` for guidance, which already exists and is
   project-owned, and project checks in `brief-checks/`, filed separately as #0011.
   Neither requires editing a toolkit-owned file, which
   is what makes "your edits are lost" a livable policy rather than a dead end. Phase `d`
   points at both instead of inventing a third.
3. **Does the prune cover shipped docs and tools, or only skills and commands?** The log's
   `### Created` list reaches further than its skills list. Blocks `c`.
4. **Is there a dry run, and is it the first release?** Reporting the difference without
   removing is releasable on its own. Blocks `c`.

## Non-goals

- **Not content migration.** Nothing is carried from an old skill into its successor.
- **Not versioning.** There are no toolkit versions to reason about, only what a log entry
  says was installed.
- **Not a fix for pre-log installs.** Unreachable, stated above.
- **Not a change to project-owned protection.** `AGENTS.md` and `.gitignore` keep it.

## Success criteria

- A second install updates every toolkit-owned file to the shipped version, with no flag.
- A project holding the pre-#0010 skills is told by name which are being removed, and they
  are gone afterwards.
- A skill the log never recorded is never named and never removed, including one whose name
  matches an old toolkit skill.
- A target with no install log gets no removal and a clear statement of why.
- `AGENTS.md`, `.gitignore`, briefs, ledgers, declarations and chronicles are byte-identical
  across a reinstall.
- The log entry for a run names what that run removed.
- The suite proves removal is refused when it would leave the target, including through a
  symlinked skills directory.
- The shipped rules state that local edits to toolkit-owned files do not survive an install.
