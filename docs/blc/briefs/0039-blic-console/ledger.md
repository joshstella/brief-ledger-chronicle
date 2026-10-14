# Ledger — #0039 The record nobody is watching while it changes

`blc/2 #0039 in-progress a:in-progress(blic/bake-off) b:pending`

**Brief:** `docs/blc/briefs/0039-blic-console/brief.md`
**Status:** in-progress
**Started:** 2026-10-14

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | the bake-off | in-progress | `blic/bake-off` | — |
| b | the console | pending | — | — |

**a — the bake-off.** Nobody knows what shape a BLC console should be, and the design proposal
says so in its own open questions. This phase answers it with evidence instead of argument.
Five prototypes run in parallel on isolated branches, over one frozen read surface and one
fixture — this repository's own briefs — and each files the same report. The prototypes cover
a bash view with no build step, a compiled static binary, a typed Node application, a watch
loop with no full-screen view at all, and no new surface at all. None merges to `main`; the
output of this phase is five working programs and five reports, not a shipped tool.

**b — the console.** Provisional. It builds the winner properly: tests, the read surface it
needs published rather than improvised, and the normal gates. Its shape depends entirely on
what `a` returns, so it is a placeholder with a letter rather than a plan. If prototype 4
wins, `b` is small and is not a terminal application at all.

## Dependency structure

A strict chain of two, and the second is **provisional** until the first completes. `b` cannot
be planned before `a` reports, and re-planning `b` from `a`'s result is the expected path, not
a failure of this plan.

Inside `a`, the five prototypes are **parallel tracks** with one shared dependency: the frozen
read surface. They do not read each other's work. Divergence is the point — five agents that
converged would mean the brief had already decided.

## Settled before `a` began, 2026-10-14

- **The console is read-only.** A console that edits the record is the proposal's record
  verbs, a separate argument with separate risks. Reading is what nothing does today.
- **The fixture is this repository's own briefs.** A prototype that looks good against
  synthetic records has proved nothing about 39 real ones with uneven ledgers, two of which
  carry defects a console should surface on open.
- **The read surface is an instrument, not a deliverable.** Frozen, untested, uninstalled,
  living on the bake-off branch. It exists so the five are compared on what they show rather
  than on whether they parse a ledger correctly.
- **No prototype merges to `main`.** They are evidence. The winner is rebuilt under the gates.
- **Every prototype files the same report.** Startup cost, dependency cost, what it does that
  the others cannot, what it cannot do, and what it was like to sit beside. Five reports in
  five shapes would be five opinions.
- **The two stack rules are priced, not adjudicated.** The repository values bash and markdown
  with no build. The author's standing rule is strongly typed with explicit interfaces at
  every boundary. This is the first BLC proposal where both cannot hold. `a` reports what each
  costs; the choice is the author's and is not delegated to an agent.

## Open decisions

Each blocks `b`, not `a` — `a` exists to answer them.

- **Where a notification lands.** Terminal, desktop, shell prompt, or editor.
- **What counts as an event.** A push to the trunk is obvious; a branch appearing or a
  declaration edited may be noise.
- **Whether a next action is derivable from the record at all**, or whether the ledger only
  supports reporting state. A prototype that can say no more than "phase b is in progress" has
  answered this.

## Complications found while planning

- **The design proposal this brief comes from cannot be cited in this repository.** Its
  evidence is drawn from a product repository, and this repository's rules forbid product
  names, paths and internals in its files. Every claim was restated as a property, or replaced
  with evidence from this repository's own record. The brief is correct and is a weaker
  argument than the proposal, and that cost is real.
- **The brief's own evidence is this repository's unfixed state.** #0028 is `done` with no
  `**Closed:**` date and has been reported on every gate run since. It is cited as evidence
  and is also a live defect. Nothing in this brief fixes it.
- **`tools/orient.sh` is the incumbent and is good.** The console is not competing with
  nothing. It has to be better than running one script on purpose, and "it is always running"
  is the only advantage on offer.
- **A watch loop is a process that outlives a shell.** The prototypes that poll have to say
  what happens on a laptop that sleeps, and none of them can be judged on a run that lasted
  five minutes.

## Branches

`blic/bake-off`, cut from `main`. It carries the read surface and the five prototype branches
are cut from it. It is outside `brief/` on purpose: the name is reserved for phase branches
that return to `main` by merge, and this one does not return.
