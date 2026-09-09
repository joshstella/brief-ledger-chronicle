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

**The gate takes hooks. A project drops in an executable; `validate-briefs.sh` runs it and
honours its verdict.**

Not a second place to write prose — that is `AGENTS.md`, and it works. The missing piece is
that a project's rule can fail a check the way `BRIEFS-3` can.

- Hooks live in a **project-owned** directory, so they survive the install policy and are
  never shipped or removed by the toolkit.
- A hook prints findings in the gate's existing vocabulary — `defect` fails the run,
  `judgment` reports and does not — and exits accordingly.
- Hooks **add** clauses. A hook can never suppress or downgrade a toolkit clause: the
  Contract is a published promise, and a promise a consumer can switch off is not one.
- Project clauses carry a project namespace, never `BRIEFS-N`, so a reader can always tell
  whose rule failed.
- **A hook that errors is a defect.** A gate that fails open is not a gate.

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
`[defect]`, which fails, from `[judgment]`, which reports. Hooks need no new concepts, only
access to the existing ones.

**5. Nothing about this is hypothetical for a team.** Projects have house rules — required
brief sections, naming, ownership, review requirements. Today every one of them is a
suggestion, and the first time one is skipped nothing notices.

## Change

| Phase | Work |
|---|---|
| `a — the hook contract` | Write down the interface: where hooks live, how they are discovered and ordered, what arguments they receive, what output the gate parses, what each exit status means, and that a hook cannot touch a toolkit clause. Documentation and a worked example. No behaviour change. |
| `b — the runner` | `validate-briefs.sh` discovers, runs, and aggregates hooks. Deterministic order. Toolkit clauses are evaluated first and independently, so a broken hook can never mask them. Errors fail closed. |
| `c — the check` | Tests: a passing hook, a failing hook, a hook emitting a judgment, a crashing hook, a non-executable file, no hook directory at all, and two hooks running in a fixed order. Plus the negative that matters — a hook that tries to clear a toolkit defect does not. |

## Tension

**Failing closed on a broken hook blocks all work on that project.** A hook with a syntax
error stops every validation run until someone fixes it. The alternative is worse — a
silently skipped hook is a rule the project believes it has — but the failure mode is
loud and total, and it will happen on someone's first attempt.

**The toolkit will be running code it did not write.** The mitigation is that the code is
the project's own, in its own repository, executed by its own contributor. It is still a
change in what `install.sh`'s output does, and it deserves saying out loud rather than
discovering.

**Project clauses will be mistaken for Contract clauses.** The Contract is a published
promise with external consumers. A project rule that looks like one dilutes that. A
namespace helps and will not fully prevent it, because the two appear in the same output.

**Hooks couple to the gate's output format, which has no compatibility promise.** A project
hook written against today's `defect`/`judgment` vocabulary breaks if that vocabulary
changes. The toolkit gains a consumer it cannot see and therefore cannot avoid breaking.

**This does nothing for the skills.** Guidance stays unenforceable — that is what guidance
is. A project can now enforce rules about the *record*, because a script can read the
record. It still cannot enforce how an agent behaves while producing it, and no mechanism
in this brief changes that.

**One gate is not all gates.** `blc-review-pr` is the review gate and is a skill, so it
cannot take hooks in any meaningful sense. Extending only the script-shaped gate leaves the
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
- **Hooks add; they never subtract.** No hook can suppress or downgrade a toolkit clause.
- **Fail closed.** A hook that cannot run is a defect.
- **Hooks are project-owned.** Never shipped, never replaced, never pruned by the installer.

## Open decisions

1. **Where do hooks live?** Beside the tools, or under a dedicated directory that is clearly
   the project's. The choice signals ownership and is hard to change later. Blocks `a`.
2. **What is the hook interface?** Arguments in and text out, or a stricter structured
   format that is easier to parse and harsher to write. Blocks `a`.
3. **Which tools take hooks?** `validate-briefs.sh` is the gate and is obvious.
   `open-briefs.sh` and `orient` are observers — extending them is a different feature with
   a different risk profile. Blocks `b`.
4. **Any executable, or shell only?** Shell keeps the toolkit's zero-dependency posture.
   Any executable is more useful and drags a runtime into the gate. Blocks `a`.
5. **Does the toolkit ship an example hook?** An example teaches the interface and is one
   more toolkit-owned file in a project-owned directory. Blocks `a`.

## Non-goals

- **Not a second prose channel.** `AGENTS.md` is the one.
- **Not extending the skills.** Skills are prompts; their guidance stays guidance.
- **Not per-contributor behaviour.** Explicitly rejected above.
- **Not a plugin system.** Hooks answer one question — does this record satisfy this
  project's rules — and are not a general extension surface.
- **Not a change to the Contract.** No clause is added, altered, or made optional.

## Success criteria

- A project can add a rule about its own records that fails `validate-briefs.sh` when
  violated, without editing a toolkit file.
- A project rule and a toolkit clause are distinguishable in the output by name.
- A hook cannot clear a toolkit defect, and a test proves it.
- A hook that crashes fails the run and says which hook it was.
- A project with no hooks behaves exactly as it does today, byte for byte.
- Hooks survive an install that replaces and prunes toolkit-owned files.
- Two hooks run in a stated, deterministic order.
