# p5-ambient — no new surface

**Prototype 5 of the #0039 bake-off.** Branch `blic/p5-ambient`, from `blic/bake-off`.
Nothing here merges to `main`. Nothing here is installed. It writes no record.

The thesis under test: the record should appear where the person is already looking, and a
fifth terminal pane is a place nobody looks. Three surfaces, all over the frozen `read.sh`.

Every number below comes from `./bench.sh`. Re-run it. The raw output of the run quoted here
is in `captures/bench.txt`.

---

## 1. What it is

Bash and awk. No build step, no runtime, no package manager, no daemon, no database, no
login. `jq` is **not** used — it is not installed on this machine, and a surface that runs on
every shell prompt cannot carry a dependency the shell does not already have.

Three surfaces and one shared cache:

| Surface | File | How a person starts it |
|---|---|---|
| Shell prompt segment | `blic-prompt.bash` | `. blic-prompt.bash && PS1='$(blic_prompt) \w \$ '` in `~/.bashrc` |
| Cursor CLI status line | `blic-statusline.sh` | one `statusLine` key in `~/.cursor/cli-config.json` |
| Agent-event hooks | `hooks/blic-{notify,warm}.sh` | three entries in `.cursor/hooks.json` |

Plus `bin/blic` out of band: `line` for shells that cannot source bash, `why` for the three
lines behind the one line, `ack` to quieten the counter, `refresh`, `doctor`.

The architecture is one idea. **The slow read never happens in front of a person.**
`blic-refresh.sh` runs `read.sh`, renders a line, and leaves it in a cache outside the repo.
Every surface prints that line. A prompt spawns the refresh detached, at most once per
`BLIC_TTL` (default 20s), and never waits for it.

It is not a daemon. There is no process between invocations, nothing starts at login, and
nothing needs killing. Close every shell, CLI session and agent session and refreshing stops.

What the line looks like against this repository, with the synthetic peers switched on:

```
▸ #0039a · ↑5~ · !16 · the bake-off
```

35 characters. `▸` the phase in flight, `#0039a` mine, `↑5~` five changes I did not make and
the `~` says every one of them is synthetic, `!16` the gate's sixteen `BRIEFS-11` judgments,
then the phase label in whatever room is left. Full captures in `captures/`.

## 2. Startup cost

Measured, not estimated.

| | |
|---|---|
| Install, surface 1 | one line in `~/.bashrc` plus one `PS1` edit |
| Cold cache → first prompt | **1.6ms**, and the prompt is not blocked; the segment is empty |
| Cold cache → line appears | **3165ms**, in the background, while you keep typing |
| `refresh --full` | 3155ms |
| `refresh --events` | 322ms |

The 3.2s is `read.sh`'s, not this prototype's: `read.sh briefs` is 1906ms and `read.sh
defects` is 920ms on this fixture. p5 pays it once per commit rather than once per prompt,
because the brief facts are a function of HEAD and the refresher compares HEAD before
deciding which tier to run.

There is no "time to a running console" because there is no console to run. The cost of
having it open is zero; it is already open.

## 3. Dependency cost

| Needs | Why | Without it |
|---|---|---|
| bash 4.2+ | `EPOCHSECONDS`, associative arrays, `printf -v` | surface 1 is unavailable; use `bin/blic line` from any shell |
| awk | the two parsers | nothing parses; every surface goes silent |
| git | `read.sh` needs it anyway | nothing works, but nothing works in this repo anyway |
| a writable `XDG_RUNTIME_DIR` or `/tmp` | the cache | no cache, no line |
| python3 | **only** `capture.sh`, to get a pty | captures fall back to a labelled reproduction |

`jq` is not required and `bin/blic doctor` says so explicitly. No network, no forge, no
install step, nothing fetched.

What a user must already have that is not a package: **a `PS1` they are willing to edit.**
That is the real dependency and it is a bigger ask than it looks. A person with a themed
prompt from a framework is being asked to find the right hook in someone else's shell
plugin, and for them this prototype is harder to install than downloading a binary.

## 4. Size

689 lines written, 424 of them not comment or blank.

| | total | code |
|---|---|---|
| `blic-refresh.sh` | 142 | 89 |
| `bin/blic` | 104 | 80 |
| `lib/render.sh` | 76 | 52 |
| `blic-prompt.bash` | 72 | 35 |
| `blic-statusline.sh` | 71 | 40 |
| `lib/parse-briefs.awk` | 70 | 57 |
| `hooks/blic-notify.sh` | 61 | 29 |
| `lib/parse-events.awk` | 38 | 21 |
| `hooks/blic-warm.sh` | 29 | 13 |
| `lib/blic-cache.sh` | 26 | 8 |
| **shipped total** | **689** | **424** |
| harness (`bench.sh`, `capture.sh`, `lib/pty-session.py`) | 325 | 248 |

The surface a person installs — `blic-prompt.bash` — is 35 lines of code. Everything else is
the cache and the renderer behind it.

## 5. What it does that the others cannot

**It is on the screen when you were not asking.** That is the whole claim of #0039 and it is
the only one of the five that gets it without the person choosing to look. The other four
need a pane. A pane is a decision you make once, forget, and then cover with a build log.

Specifically:

- **Zero marginal attention.** 28µs per prompt. The line is in the place your eyes already
  land between commands, next to the branch name you already read.
- **It costs nothing to ignore.** Four of the five prototypes compete with a build log for
  screen space. This one competes with nothing, so there is no moment where keeping it open
  is a trade.
- **It is already where the agent is.** The Cursor status line puts the record above the
  prompt of the thing that is editing the record. No other prototype is inside the editor.
- **It knows the terminal width.** The CLI payload carries `render_width_chars`, which a
  shell prompt never learns, so the status line truncates correctly on a narrow window. See
  `captures/cursor-statusline.txt`.
- **It is silent where it has nothing to say.** Outside a BLC repo the segment renders
  nothing and the status line drops the record row. A console cannot be silent; being open
  is its whole state.

Honest deduction: none of this is a *capability*. Every fact it shows, `tools/orient.sh`
already derives. What p5 changes is when you see it, not what you see.

## 6. What it cannot do

Limits, not missing features.

**The hooks cannot notify you of someone else's work.** This is the central finding and it is
a hard limit, not a gap in the implementation.

- Every Cursor hook event is triggered by *your* agent: `sessionStart`, `preToolUse`,
  `beforeShellExecution`, `afterFileEdit`, `beforeSubmitPrompt`, `stop`, and the rest. **There
  is no timer event and no filesystem-watch event.** A peer's push cannot fire a hook. Nothing
  in the hook system can observe the record changing.
- So a hook can only sample the record at moments you create. `blic-warm.sh` on `sessionStart`
  and `stop` keeps the cache warm; that is all those two events can do, because neither has a
  documented output field.
- Only four events can show a person a sentence — `beforeShellExecution`, `beforeMCPExecution`,
  `preToolUse`, `subagentStart` — and all four are permission gates. **An informational hook
  has to attach itself to a gate**, which is why `blic-notify.sh` is on
  `beforeShellExecution` matching `git (push|commit)`. It returns `permission: "allow"` with
  a `user_message`, so it interrupts nothing.
- **Whether the CLI renders `user_message` on an `allow` verdict is unverified.** Nothing here
  was installed, so nothing was observed firing. If `allow` swallows the message, this surface
  degrades to `permission: "ask"` — a modal you must dismiss in exchange for a line you could
  have read — and that trade is worse than the prompt segment, which is already free.
- A hook could shell out to `notify-send` or `osascript` for a desktop notification. That is a
  side effect rather than a supported channel, it needs a binary that is not guaranteed, and
  it is outside what hooks are for. Not built.

The honest summary of surface 3: **hooks can refresh, and can tell you about a change at the
moment you are about to add to the trunk. They cannot tell you when it happens.** The moment
it happens is reachable only by polling, and the one surface that gets to poll for free is the
shell prompt, because the person polls it for you by pressing return.

Other limits:

- **It cannot show you anything while you are not at a prompt.** Twenty minutes inside `vim`
  or a long build is twenty minutes of nothing. A watch loop sees a push the moment it lands;
  p5 sees it the next time you press return. For `blic why` style detail the segment is also
  the wrong shape — one line cannot hold five events, so it holds a count and a command.
- **One line is one line.** Sixteen `BRIEFS-11` judgments render as `!16`. The segment can
  tell you the gate is unhappy and it can never tell you which brief. It is a pointer to
  `blic why`, and a pointer is strictly less than the list.
- **It cannot be interactive.** No selection, no drill-down, no key bindings. `blic why` is a
  separate command you type.
- **The `↑` counter needs an acknowledgement that only a human can give.** `blic ack` is the
  only thing that clears it, and if a person does not run it the counter is noise within a
  day. The brief warns that a stale line is worse than no line; this is where p5 is exposed to
  exactly that.
- **The cache can be read mid-refresh.** Each file lands atomically via `mv`, but a reader
  that reads `facts` and `events` in the same breath can straddle two refreshes. It is a
  rendering, so the cost is one stale line, but it is real and `capture.sh` has to wait around
  it.
- **It cannot know what the next action is.** It reports the phase in flight and that phase's
  label from the ledger table. The brief asks whether "next action" is derivable; from this
  record, with this reader, the answer is no. `▸ #0039a · the bake-off` is a state, and the
  verb is still in the person's head.
- **Two worktrees of one repo are two caches.** Correct — they hold different branches — but
  it means the numbers differ between panes and that surprised me the first time.

Ran out of time, not limits: a tmux status-right example, a zsh `precmd` hook that beats the
6ms script path, and a `blic ack --older-than` so the counter decays on its own.

## 7. What it was like to sit beside

I forgot it was there, which is both the point and the problem. For the first twenty minutes
it was genuinely good: `▸ #0039a · !16` sat at the left of every prompt and I stopped
wondering which brief I was on, in a way that `orient` never achieved because `orient` is a
thing you decide to run. The `!16` nagged at me — it is the undated closes the brief cites,
and I looked at them because the number was in my eye line, not because I ran the gate. That
is the claim working. Then I switched the synthetic peers on and watched `↑5~` appear, and the
feeling changed. The counter is a demand. With one author and five fake events it is a demo;
with a real team, if I did not run `blic ack`, it would sit at `↑37` within a week and become
wallpaper, and I would have built exactly the stale status line that
`docs/blc/briefs/README.md:165` warns about. The half that answers "what is mine" wants to be
ambient. The half that answers "what changed that I did not do" wants to be an inbox, and an
inbox does not fit in a prompt.

## 8. What you would throw away

- **The `↑` counter, in its current form.** It is the weakest thing here. An unread count with
  a manual acknowledgement is a notification badge, and a notification badge in a prompt
  rots. If this won, the counter should show only what landed since the last refresh and then
  expire on its own, or it should not be in the prompt at all.
- **`bin/blic why`.** It is the console sneaking back in. The moment a one-line surface needs
  a second command to explain itself, the argument "nobody opens a fifth pane" has been
  conceded in the implementation while the report still makes it. Either the line is enough or
  prototype 1 or 4 is right.
- **`hooks/blic-notify.sh`.** Built, measured at 5ms, and I would not install it. It is
  attached to a permission gate because that is the only place a sentence can go, which means
  it is the wrong mechanism wearing the right shape. The `beforeShellExecution` insight — that
  the moment before you push to a trunk that moved is the one moment a notification is worth
  an interruption — is worth keeping. It should be a check inside `blc-commit-push-pr`, which
  already runs there, rather than a hook pretending the editor has a notification channel.
- **Not the two-tier cache.** That part is right and the next prototype should steal it
  whatever shape it takes. A 3.2s read is unaffordable in any live surface, and HEAD is a
  sufficient cache key for everything except an uncommitted edit.

---

## The honest question: is a dedicated console needed at all?

Both directions, with the numbers.

### The case that the prompt segment already wins

- **The cost is not comparable.** 28µs per prompt, against the stated 50ms threshold: p5 is
  **roughly 1800 times under budget** and three orders of magnitude from anything a person
  could feel. Repeat runs give 26–28µs; the loop overhead of an empty bash function in the
  same harness is 6–8µs, so a third of that figure is the measurement.
  A console costs a pane. A pane is the most expensive thing on the screen.
- **It needs no decision.** Prototypes 1 through 4 all need "open the console" to become a
  habit. Half of #0039's finding is that `tools/orient.sh` already works and nobody runs it.
  A surface whose adoption depends on a new habit is answering the brief with the same defect
  the brief describes.
- **"What is mine" fits.** The fixture's answer is one brief and one phase. It is 35
  characters. It does not need a screen, and a screen built for it would be mostly empty — the
  console's second-best feature would be the 38 done briefs it could also show you, which is
  the archive nobody is asking for.
- **The gate's output is a number.** `!16` moved me to look at the sixteen undated closes.
  The console's version of that is the same number in a bigger font.

### The case that it does not

- **The ambient surface sees one axis.** The prompt is where "what is mine" belongs. It is the
  wrong shape for "what changed that I did not do", and I found that by building it: the
  counter wants to be a list you work through, and a one-line surface can only hold its
  cardinality. That is a shape mismatch, not a width problem, and widening the line does not
  fix it.
- **Latency is not the only cost.** 28µs is free and the acknowledgement is not. Somebody has
  to run `blic ack`, and the counter is wrong until they do. A console has an obvious place to
  put "mark as read" — the thing you are already looking at — and a prompt does not.
- **It only fires when you press return.** The brief asks for the record reported "when it
  happens rather than at the next orient". p5 reports it at the next *prompt*, which is better
  than the next orient and is not what was asked. Prototype 4's watch loop is the only one of
  the five that can honestly claim the former.
- **The install is per-person and per-shell.** `~/.bashrc`, `~/.cursor/cli-config.json`,
  `.cursor/hooks.json` — three files, two of them in a home directory, and a different answer
  for zsh and fish. A console is one command a project can document once. For a toolkit that
  installs itself into other repositories, that difference matters more than microseconds.

### What I actually think

**A dedicated console is not needed for "what is mine". It may still be needed for "what
changed that I did not do", and if it is, that is a different product from the one #0039
describes.**

The brief asks for two surfaces and treats them as one thing. Building them ambiently
separated them: the first is a *state* that wants to be glanceable, idempotent and always
visible, and the prompt segment is a better answer than any console at 28µs. The second is a
*queue* that wants to be enumerable, acknowledgeable and ordered, and no one-line surface can
be those. The bake-off would be served by stopping the comparison here and asking whether the
second half is really a console or really an inbox — because a console that answers it would
be an inbox that happens to live in a terminal, and that is a third design nobody has priced.

If one thing ships, ship the prompt segment. It is 35 lines of code, it costs 28µs, and it
makes `tools/orient.sh` something you no longer have to remember.
