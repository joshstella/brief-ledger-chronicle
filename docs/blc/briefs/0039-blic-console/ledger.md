# Ledger — #0039 The record nobody is watching while it changes

`blc/2 #0039 in-progress a:done(blic/bake-off) b:pending`

**Brief:** `docs/blc/briefs/0039-blic-console/brief.md`
**Status:** in-progress
**Started:** 2026-10-14

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | the bake-off | done | `blic/bake-off` | — (no PR; the prototypes do not return) |
| b | the delivered answer | pending | — | — |

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

## Result of `a`, 2026-10-14

Five prototypes ran in parallel, each in its own worktree on its own branch off
`blic/bake-off`, over the frozen read surface and this repository's own 39 briefs. All five
branches are pushed. None merges to `main`.

| # | Branch | Stack | Wrote | Cold start | Cost to a user |
|---|---|---|---|---|---|
| 1 | `blic/p1-bash` | bash and ANSI | 1,028 lines | 21 ms first frame, 1.95 s populated | nothing |
| 2 | `blic/p2-go` | Go and Bubble Tea | 2,340 lines | 4.05 s build, 3.13 s to frame | ≈367 MB toolchain for a 5.4 MiB binary |
| 3 | `blic/p3-ts` | TypeScript and Ink | 1,964 lines | 4.24 s install, 8.56 s to screen | 71 MB `node_modules`, 62 dependencies, ≈105 MB RSS |
| 4 | `blic/p4-watch` | bash, two commands, no screen | 395 lines | 2.15 s from a cold clone | nothing |
| 5 | `blic/p5-ambient` | bash, prompt and status line | 689 lines | 28 µs per prompt | nothing |

### Every prototype concluded it should not win

Including the three that built the thing they were asked to build, and each for its own
reason, written before any of them saw another's report.

- **1** proved the no-build constraint survives a live full-screen view, then said the panes
  were not what made the exercise worthwhile — two lines of text were.
- **2** said a pane you have to look at is not better than a shell prompt you cannot avoid,
  and costs 367 MB more.
- **3** said the honest answer to "what can only this do" is *nothing a user sees*, and that
  the right outcome is to keep the schema and throw the renderer away.

Convergence this strong across five independent runs is either the result or a shared bias
from the brief's framing. It is recorded as both, because nothing here can tell them apart.

### The open decision about derivability is answered, and the answer is smaller than the claim

**The record supports deriving what is wrong with the record. It does not support deriving
what to do about the work.** Prototype 4 wrote ten rules. Three fire against the 39 real
briefs; seven have no instance at all, because this repository closes a phase on the day it
opens one, so the states that would need a decision never persist long enough to be read.

Of the 17 items the record does yield, 16 are repairs to the record itself — and
`tools/validate-briefs.sh` has printed every one of them on every run since each brief closed.
So the value on offer is **delivery, not derivation.** The derivation was already done, by the
gate, and ignored. The one live brief yields "phase a is in-progress on `blic/bake-off`",
which is the sentence the brief predicted a prototype would be limited to, and the only part
that made it actionable came from git rather than from the ledger.

What is missing is specific: a phase row records a state and a pointer, not what the phase is
waiting for, and the vocabulary deliberately merges "not started" with "in review" under
`in-progress`.

### Two walls stopped all five, and neither is caused by having no screen

- **No notification transport reaches this machine.** No pseudo-terminal, no notification
  daemon on the session bus, WSL interop refuses the connection. Writing to a named tty is the
  only thing that worked.
- **Nothing survives a suspend** or a `wsl --shutdown` with `systemd --user` offline.

Prototype 5 found the structural half: **Cursor hooks cannot tell you a peer's work landed.**
Every hook event is fired by your own agent, and there is no timer event and no
filesystem-watch event, so another person's push cannot fire a hook at all. Hooks can warm a
cache, and they can show a sentence at `beforeShellExecution` — which is the right moment,
just before you add to a trunk that moved, and is a permission gate wearing an informational
hat.

### The finding nobody was asked for

The brief's two questions want **different shapes**, and building them ambiently split them
apart. "What is mine" is 35 characters, fits in a shell prompt, and costs 28 µs. "What changed
that I did not do" is a queue you enumerate and acknowledge. A one-line surface can only carry
its cardinality, and with the synthetic peers running, prototype 5 reported that the badge
"stopped feeling like information and started feeling like a badge that would read ↑37 within
a week". Widening the line does not fix a shape mismatch.

A console that answered the second half would be an inbox living in a terminal. **That is a
third design, and this bake-off did not price it.**

### Faults found in the instrument, and one in shipped code

Three prototypes independently hit the same thing, and it is not the instrument's:
**`blc_status_phase_entries` in `tools/lib/phase-row.sh` splits a status line on whitespace,**
so the older pointer form `1:done(commit 92a7168)` arrives as state `done(commit` with no
pointer. Five ledgers here carry that form, and the function is shared by `open-briefs.sh` and
`validate-briefs.sh`, so `BRIEFS-9` reads a truncated state on those briefs. Nothing is
drifting today because all five are closed. It belongs to a brief of its own, not to this one.

Instrument faults, left unfixed because it was frozen for the comparison: `snapshot <rev>`
accepts a revision and silently drops it; brief-level `state` keeps its pointer while
phase-level `state` splits it; `snapshot` is about 60% slower than fetching the same
subcommands in parallel; and a commit touching only `experiments/` classifies as `code`
through a path that is dead code.

### What this cannot prove

- **No full-screen prototype has ever been drawn to a real terminal.** This machine has no
  pseudo-terminal, so prototypes 1, 2 and 3 were proved with scripted input and capture modes.
  Redraw, flicker and resize behaviour is genuinely untested, and all three say so.
- **The fixture has one author and one live brief.** Every real event is the author's, so the
  notification half ran on synthetic peers throughout. The five-line answer is five lines
  because 38 of 39 briefs are done; four contributors and nine live briefs would produce a
  list that scrolls, and a list that scrolls wants filtering, and filtering wants a cursor.
- **Prototype 5's hook finding is read from documentation, not observed.** Nothing was
  installed, so no hook was seen to fire, and whether the CLI renders `user_message` on an
  `allow` verdict is marked unverified.

## Re-run on a real terminal, 2026-10-14

The section above lists "no full-screen prototype has ever been drawn to a real terminal" as
a thing the bake-off cannot prove. That limit is gone. All five prototypes ran again over the
same fixture, and two of the bake-off's conclusions change.

**The machine does have a pseudo-terminal.** `tmux` 3.4 is installed. A `tmux` session reports
`/dev/pts/7`, and `tmux capture-pane` reads the frame back as text. The bake-off recorded the
absence as a property of the machine. It was a property of the agent's own shell. Prototypes
1, 2 and 3 were each started inside a `tmux` session at 120x36 and then resized.

| # | What ran | Result |
|---|---|---|
| 1 | `blic` live at 120x36 | draws, then **corrupts the frame** |
| 2 | `go build` then `./blic` | draws, **survives resize** |
| 3 | `npm run build` then `node dist/cli.js` | draws, **ghosts on shrink** |
| 4 | `./blic` | 4 lines, 3 actions, no screen needed |
| 5 | `./blic-refresh.sh` then the prompt | 27 µs per prompt, as reported |

### Two redraw defects, both invisible to the method that cleared them

**Prototype 1 does not clip the detail pane.** Select #0003 and the `status` and `next` values
run past the right edge. The terminal wraps them, and the overflow overwrites the left pane.
`Stale branches nothing pru…` becomes `le branches nothing pru…`. The frame then scrolls and
the brief rows paint out of order. The defect is deterministic. Three keystrokes reach it.

**Prototype 3 does not clear the screen when it shrinks.** Resize from 120x36 to 80x24 and
glyphs from the wider frame stay on the right edge. `state in-progress` reads
`state in-progresscord nobody is watchin…`. Whole rows disappear. A resize back to 140x40
repairs it, so the damage is in the shrink path only.

**Prototype 2 handles both.** It clips every line, it reflows on resize, and at 80x24 it adds
`DETAIL · lines 1–9 of 17 · j/k scrolls` where the other two simply lose the content.

The reason the bake-off missed these matters more than the defects. Prototype 1 proved its
rendering with `--frames`, which writes each frame to standard output. A pipe never wraps, so
a line too long for the terminal prints in full and the saved frame looks correct.
**`session.txt` cannot show the defect it was used to rule out.** A capture mode that bypasses
the terminal cannot answer a question about the terminal.

### What the re-run confirms

- **Prototype 2's dependency cost is real.** Go 1.27.2 is a 68 MB download and 283 MB on disk.
  The module cache adds 72 MB. The total is 355 MB against the 367 MB first reported. The
  build takes 3.4 s and produces a 6.4 MB binary.
- **Prototype 3 is honest about its weight.** 24 of 24 tests pass. The build takes 0.33 s with
  `node_modules` already present. Resident memory starts at 107 MB and reaches 118 MB after
  one resize.
- **Prototype 5's per-prompt cost holds.** 27 µs against the 28 µs reported. A cold refresh
  costs 3.2 s, and the prompt shows `reading the record…` until the cache is warm.
- **Prototype 4 still answers the brief in four lines.** It names the one live item, the 16
  undated closes, and 7 merged branches to prune.

### The badge argument is now measured, not predicted

Prototype 5 predicted that the unread count "would read ↑37 within a week". Prototype 1 ran
for about 21 minutes with the default 7 second synthetic interval. The badge read **184 new**,
and the synthetic events had pushed every real git event out of the feed. The rate is
synthetic and proves nothing about a real team. The shape of the failure is not synthetic. An
unbounded feed with no grouping buries the record it exists to report.

### Still unproved

- **One author, one live brief.** The re-run changed the terminal, not the fixture. The
  notification half still runs on synthetic peers.
- **Nothing was observed over a suspend.** The longest session was about 21 minutes.
- **Prototype 5's hook finding is still read from documentation.** Nothing was installed.

A small fault found on the way: prototype 1 started with `--no-peer` still reads the peer file
at line 232 and prints `No such file or directory`.

### Corrections to the section above, later the same day

Three claims above are wrong. Running the five prototypes again, to choose between them rather
than to test them, found all three. The claims stay in place and these corrections follow them.

**Prototype 3 does not fail only when it shrinks.** The text above says a resize back to
140x40 repairs the frame, "so the damage is in the shrink path only". That is wrong. Prototype
3 draws a corrupt first frame in a 120x30 terminal with no resize at any point. `state
in-progress` reads `state in-progresscord nobody is watching while it changes`. The `DETAIL`
header does not appear at all. A start at 80x24, left to settle for 12 seconds, fails the same
way. A grow to 120x36 repairs it. The rule is width, not direction. This reaches a person who
opens the console in a default terminal and never touches the window, so the defect is worse
than the first report says. The first report reached 80 columns only by shrinking from 120.
That is the same fault of method this section names in the bake-off.

**WSL interop does not refuse the connection.** The "Two walls" section says it does.
`powershell.exe` answers from this shell and reports version 5.1.26100.9444. The failure comes
after that. `notify.sh --send --transport windows` exits 0 and shows nothing, and no toast
reached the author's desktop. The send path uses `NotifyIcon.ShowBalloonTip`, which Windows 10
and Windows 11 suppress, in a process that exits before a tray icon can render. The same path
sends all output to `/dev/null` and returns success whenever PowerShell exits 0. The probe
agrees with it because `interop_works()` runs `powershell.exe -NoProfile -Command exit`. That
proves PowerShell starts. It proves nothing about a notification. A transport that reports
itself available and then delivers nothing is worse than one that refuses.

**The `--no-peer` fault is not small.** The line above calls it small. Prototype 1 started with
`--no-peer` writes that error to standard error on every poll. The lines land on the terminal
and destroy the display in a few seconds.

### What a terminal would still answer

`bell` and `osc9` report unavailable in every probe run so far. Both report that way only
because the shell running the probe has no controlling terminal. The probe's own note says
Windows Terminal honors OSC 9. Nobody has run the probe from a real terminal yet. The question
of where a notification lands stays open. It is not closed by the two walls above.

## Branches

`blic/bake-off`, cut from `main`. It carries the read surface and the five prototype branches
are cut from it. It is outside `brief/` on purpose: the name is reserved for phase branches
that return to `main` by merge, and this one does not return.
