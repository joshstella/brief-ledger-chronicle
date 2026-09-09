# A project cannot add a gate

**Serial:** #0011 · **Created:** 2026-09-09T12:40:00Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## Ground

A project that adopts this toolkit can tell its agents anything it likes. `AGENTS.md` is
read by four skills, the shipped rules file is always applied, and both are project-owned
and survive an install. Guidance is a solved problem.

What a project cannot do is make any of it **stick**. `tools/validate-briefs.sh` is the
gate, and it checks clauses `BRIEFS-1` through `BRIEFS-8` — hardcoded, with no place for a
project to add a ninth. Every rule a project adds is prose an agent may follow.

This repository has already measured what happens to rules that depend on being followed.
Fourteen standing decisions, six promoted, eight not: **43%**. And it named the principle
in its own values file: *a skill guard is not a check.*

So a project's own rules are permanently in the weaker category, by construction, while the
toolkit's eight are enforced.

## The claim

**A project puts a shell script in `brief-checks/`. After its own clauses pass,
`validate-briefs.sh` runs each one. A non-zero exit fails the run.**

That is the whole interface. No output format, no registration, no manifest.

- Scripts live in **`brief-checks/` at the repository root**, a directory the installer never
  creates, writes to, or scans.
- The gate runs `brief-checks/*.sh` in sorted order with `bash`, passing the briefs
  directory as the first argument.
- **Exit 0 passes. Anything else fails.** Whatever the script printed is echoed under its
  filename, so a project says what went wrong in its own words.
- Toolkit clauses are evaluated first and independently. A project script cannot suppress,
  downgrade, or clear a `BRIEFS-N` defect — it can only add a reason to fail.
- No `brief-checks/` directory, or an empty one, changes nothing.

Deliberately minimal, because nobody has asked for this yet. Everything omitted below is
omitted so that the first real use case gets to shape it.

## Evidence

**1. The gate is closed by construction.** `tools/validate-briefs.sh` names clauses
`BRIEFS-1` to `BRIEFS-8` and deliberately does not restate their text, citing ids only. It
has no notion of a clause it did not ship with.

**2. The prose channel already exists and is well wired.** `AGENTS.md` or `CLAUDE.md` is
read by `blc-init-briefs`, `blc-start-brief`, `blc-next-brief-phase` and `blc-review-pr`.
Adding a second prose channel — per-skill extension files — would compete with a working
one and split where a project's rules live.

**3. The toolkit's own tests prove scripts and not prose.** #0008 made orientation a script
specifically so it could be asserted, and its last phase could only pin that an instruction
was *present*, never that it was followed. A project's rules inherit that ceiling unless
they can run as code.

**4. Every other candidate location is inside the installer's blast radius.** The installer
scaffolds `docs/briefs/`, `docs/briefs/_drafts/`, `docs/contracts/`, `docs/chronicles/`,
`docs/install-log/`, `docs/state/` and `tools/`, and ships named files into most of them.
Under the replace-and-prune policy those are toolkit-owned. A project-owned directory nested
beside them puts the ownership boundary *inside* a tree the installer sweeps, where nothing
marks it and a slightly broader glob erases a project's enforcement during an upgrade.

**5. Exit status is a verdict every shell script already produces.** A format would have to
be specified, parsed, tested, versioned, and never broken. Exit status needs none of that,
and a script that crashes reports failure without the gate doing anything.

## Change

| Phase | Work |
|---|---|
| `a — the runner` | `validate-briefs.sh` runs `brief-checks/*.sh` after its own clauses, in sorted order, and fails the run if any exits non-zero. Documented in the briefs README: the directory, the argument, the exit convention, and that the toolkit never touches the directory. |
| `b — the proof` | Tests: a passing script, a failing script, a crashing script, two scripts in a fixed order, an absent directory, an empty directory, and a script that cannot make a toolkit defect go away. Plus that an install leaves `brief-checks/` unmodified. |

## Tension

**Failing on a broken script blocks all work on that project.** A syntax error stops every
validation run until someone fixes it. The alternative is worse — a silently skipped script
is a rule the project believes it has — but the failure mode is loud and total, and it will
happen on someone's first attempt.

**The toolkit will be running code it did not write.** The mitigation is that the code is
the project's own, in its own repository, executed by its own contributor. It is still a
change in what `install.sh`'s output does, and it deserves saying out loud rather than
discovering.

**Exit-status-only means no `judgment`.** The gate distinguishes findings that fail from
findings that merely report. A project gets the first and not the second, so anything
advisory has to either fail or stay out. Adding a judgment channel later is additive and
breaks nothing, which is the reason for leaving it out now rather than guessing at it.

**A project may already have a `brief-checks/`.** Unlikely, but the toolkit cannot claim the
name, only read it — which is the correct posture for a project-owned path, and also means a
collision is the project's to resolve, with no help from us. The `blc-` prefix would have
removed even that risk, and was rejected for a larger one: see the settled decisions.

**The installer must now promise never to touch a path.** Ownership has so far been a
question of what the installer writes. `brief-checks/` makes it also a question of what it
must refrain from writing, and that promise has to be recorded in the ownership map rather
than merely observed. This is a direct dependency on the install brief's phase `a`.

**This does nothing for the skills.** Guidance stays unenforceable — that is what guidance
is. A project can now enforce rules about the *record*, because a script can read the
record. It still cannot enforce how an agent behaves while producing it, and no mechanism
in this brief changes that.

**One gate is not all gates.** `blc-review-pr` is the review gate and is a skill, so it
cannot take scripts in any meaningful sense. Extending only the script-shaped gate leaves
the prose-shaped one exactly as it was.

**Nobody has asked for this.** It is built on the reasonable belief that adopting teams have
house rules, not on a request. Kept small for that reason, and worth abandoning rather than
growing if the belief turns out to be wrong.

## Settled decisions

Resolved 2026-09-09 during drafting.

- **Project rules are enforced by scripts, not by prose.** `AGENTS.md` remains the guidance
  channel and is not duplicated.
- **No per-skill extension files.** Considered and dropped: it would be a second prose
  channel with the same enforcement ceiling as the first, coupled to step numbering the
  toolkit renames freely.
- **Extensions key on the project, not the contributor.** A shared process that behaves
  differently depending on who ran it is not a shared process. Personal preference stays
  personal and out of scope.
- **They are called checks.** The gate already says `defect` and `judgment`; "hook" implies
  a general event system this brief does not build, and "skill hook" would advertise skill
  extension, which was rejected above.
- **They live in `brief-checks/` at the repository root.** Chosen because the installer has
  no claim on it — not because it is convenient. Every `docs/` and `tools/` candidate sits
  in a tree the installer scaffolds and prunes.
- **The directory does not take the `blc-` prefix.** `blc-` marks the ten skills, and the
  install policy is about to teach that everything so marked is replaced on update and local
  edits are lost. This is the one directory where the opposite holds. Wearing that prefix
  would tell an adopter not to edit the single path where their edits are safe. The name
  says what it checks instead, and ownership is stated in the install brief's ownership map.
- **A check is a shell script, run with `bash`.** Keeps the zero-dependency posture and means
  the gate never probes for a runtime, interprets a shebang, or cares about the executable
  bit. Barely a restriction: a shell script may call `python3`, `jq`, or anything else the
  project already depends on.
- **The interface is the exit status.** No output format to specify, parse, version, or
  break. Failing closed on a crash comes free.
- **Checks add; they never subtract.** No script can suppress or downgrade a toolkit clause.
- **Only `validate-briefs.sh` runs them.** `open-briefs.sh` and `orient` observe rather than
  gate; extending them is a different feature and waits for a reason.
- **No example script ships.** It would be a toolkit-owned file in a project-owned directory,
  which is the confusion this design is trying to avoid. The README carries a snippet instead.
- **Nothing is added to the Contract.** `brief-checks/` is a project convention, not a clause.

## Open decisions

None. Anything not settled above was cut rather than decided, on the grounds that the first
real use case is better evidence than a guess made now.

## Non-goals

- **Not a second prose channel.** `AGENTS.md` is the one.
- **Not extending the skills.** Skills are prompts; their guidance stays guidance.
- **Not per-contributor behaviour.** Explicitly rejected above.
- **Not a plugin system.** Checks answer one question — does this record satisfy this
  project's rules.
- **Not an output format, a manifest, a config file, a judgment channel, or ordering control
  beyond sorted filenames.** Each is cheap to add later and impossible to remove.

## Success criteria

- A project can add a rule about its own records that fails `validate-briefs.sh` when
  violated, without editing a toolkit file.
- A failing script's own output is what the reader sees, under its filename.
- A script cannot clear a toolkit defect, and a test proves it.
- A script that crashes fails the run.
- A project with no `brief-checks/` behaves exactly as it does today, byte for byte.
- An install run against a project with `brief-checks/` leaves every file in it unmodified.
- Two scripts run in sorted filename order.
