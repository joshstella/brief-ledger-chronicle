# A project cannot add a gate

**Created:** 2026-09-09T12:40:00Z · **Author:** josh.stella@gmail.com · **Depends on:** —

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

**A project puts an executable in `checks/`. `validate-briefs.sh` runs it and honours its
verdict.**

Not a second place to write prose — that is `AGENTS.md`, and it works. The missing piece is
that a project's rule can fail a check the way `BRIEFS-3` can.

- Checks live in **`checks/` at the repository root**, a directory the installer never
  creates, writes to, or scans.
- A check prints findings in the gate's existing vocabulary — `defect` fails the run,
  `judgment` reports and does not — and exits accordingly.
- Checks **add** clauses. A check can never suppress or downgrade a toolkit clause: the
  Contract is a published promise, and a promise a consumer can switch off is not one.
- Project findings carry a project namespace, never `BRIEFS-N`, so a reader can always tell
  whose rule failed.
- **A check that errors is a defect.** A gate that fails open is not a gate.

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

**4. The distinction is already in the tooling's vocabulary.** `validate-briefs.sh` separates
`[defect]`, which fails, from `[judgment]`, which reports. Checks need no new concepts, only
access to the existing ones.

**5. Every other candidate location is inside the installer's blast radius.** The installer
scaffolds `docs/briefs/`, `docs/briefs/_drafts/`, `docs/contracts/`, `docs/chronicles/`,
`docs/install-log/`, `docs/state/` and `tools/`, and ships named files into most of them.
Under the replace-and-prune policy those are toolkit-owned. A project-owned directory nested
beside them puts the ownership boundary *inside* a tree the installer sweeps, where nothing
marks it and a slightly broader glob erases a project's enforcement during an upgrade.

**6. Nothing about this is hypothetical for a team.** Projects have house rules — required
brief sections, naming, ownership, review requirements. Today every one of them is a
suggestion, and the first time one is skipped nothing notices.

## Change

| Phase | Work |
|---|---|
| `a — the check contract` | Write down the interface: that checks live in `checks/`, how they are discovered and ordered, what arguments they receive, what output the gate parses, what each exit status means, and that a check cannot touch a toolkit clause. Documentation and a worked example. No behaviour change. |
| `b — the runner` | `validate-briefs.sh` discovers, runs, and aggregates `checks/`. Deterministic order. Toolkit clauses are evaluated first and independently, so a broken check can never mask them. Errors fail closed. |
| `c — the proof` | Tests: a passing check, a failing check, a check emitting a judgment, a crashing check, a non-executable file, no `checks/` directory at all, and two checks running in a fixed order. Plus the negative that matters — a check that tries to clear a toolkit defect does not. And that an install leaves `checks/` untouched. |

## Tension

**Failing closed on a broken check blocks all work on that project.** A check with a syntax
error stops every validation run until someone fixes it. The alternative is worse — a
silently skipped check is a rule the project believes it has — but the failure mode is
loud and total, and it will happen on someone's first attempt.

**The toolkit will be running code it did not write.** The mitigation is that the code is
the project's own, in its own repository, executed by its own contributor. It is still a
change in what `install.sh`'s output does, and it deserves saying out loud rather than
discovering.

**`checks/` is a new top-level directory and the name is not ours alone.** A project may
already have one, meaning something entirely different. The toolkit cannot claim it, only
read it — which is the correct posture for a project-owned path, and also means a collision
is the project's to resolve, with no help from us.

**The installer must now promise never to touch a path.** Ownership has so far been a
question of what the installer writes. `checks/` makes it also a question of what it must
refrain from writing, and that promise has to be recorded in the ownership map rather than
merely observed. This is a direct dependency on the install brief's phase `a`.

**Project findings will be mistaken for Contract clauses.** The Contract is a published
promise with external consumers. A project rule that looks like one dilutes that. A
namespace helps and will not fully prevent it, because the two appear in the same output.

**Checks couple to the gate's output format, which has no compatibility promise.** A project
check written against today's `defect`/`judgment` vocabulary breaks if that vocabulary
changes. The toolkit gains a consumer it cannot see and therefore cannot avoid breaking.

**This does nothing for the skills.** Guidance stays unenforceable — that is what guidance
is. A project can now enforce rules about the *record*, because a script can read the
record. It still cannot enforce how an agent behaves while producing it, and no mechanism
in this brief changes that.

**One gate is not all gates.** `blc-review-pr` is the review gate and is a skill, so it
cannot take checks in any meaningful sense. Extending only the script-shaped gate leaves the
prose-shaped one exactly as it was.

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
- **They are called checks, not hooks.** The gate already says `defect` and `judgment`;
  "hook" implies a general event system this brief explicitly does not build, and
  "skill hook" would advertise skill extension, which was rejected above.
- **They live in `checks/` at the repository root.** Chosen because the installer has no
  claim on it — not because it is convenient. Every `docs/` and `tools/` candidate sits in
  a tree the installer scaffolds and prunes.
- **Checks add; they never subtract.** No check can suppress or downgrade a toolkit clause.
- **Fail closed.** A check that cannot run is a defect.
- **Checks are project-owned.** Never shipped, never replaced, never pruned by the installer.

## Open decisions

1. ~~Where do checks live?~~ **Resolved 2026-09-09: `checks/` at the repository root.**
2. **What is the check interface?** Arguments in and text out, or a stricter structured
   format that is easier to parse and harsher to write. Blocks `a`.
3. **Which tools take checks?** `validate-briefs.sh` is the gate and is obvious.
   `open-briefs.sh` and `orient` are observers — extending them is a different feature with
   a different risk profile. Blocks `b`.
4. **Any executable, or shell only?** Shell keeps the toolkit's zero-dependency posture.
   Any executable is more useful and drags a runtime into the gate. Blocks `a`.
5. **Does the toolkit ship an example check?** An example teaches the interface and is one
   more toolkit-owned file in a project-owned directory. Blocks `a`.

## Non-goals

- **Not a second prose channel.** `AGENTS.md` is the one.
- **Not extending the skills.** Skills are prompts; their guidance stays guidance.
- **Not per-contributor behaviour.** Explicitly rejected above.
- **Not a plugin system.** Checks answer one question — does this record satisfy this
  project's rules — and are not a general extension surface.
- **Not a change to the Contract.** No clause is added, altered, or made optional.

## Success criteria

- A project can add a rule about its own records that fails `validate-briefs.sh` when
  violated, without editing a toolkit file.
- A project finding and a toolkit clause are distinguishable in the output by name.
- A check cannot clear a toolkit defect, and a test proves it.
- A check that crashes fails the run and says which check it was.
- A project with no `checks/` behaves exactly as it does today, byte for byte.
- An install run against a project with `checks/` leaves every file in it unmodified.
- Two checks run in a stated, deterministic order.
