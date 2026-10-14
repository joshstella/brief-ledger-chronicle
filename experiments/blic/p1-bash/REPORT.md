# p1 — bash and ANSI, no build step

Prototype 1 of the #0039 bake-off. Answers the eight questions in `../README.md`, in that
order. Every number here was measured on this machine with `measure.sh` and
`probe-limits.sh`, both committed beside this file. Nothing is estimated.

Machine: WSL2 on Linux 6.18, bash 5.2.21, GNU awk 5.2.1, `TERM=xterm-256color`,
`LANG=C.UTF-8`. Fixture: this repository, 39 briefs, 16 `BRIEFS-11` judgments.

---

## 1. What it is

A single bash script and two awk programs. No build step, no package manager, no runtime
beyond a stock Linux shell.

```
experiments/blic/p1-bash/blic
```

That is the whole start command. It reads through `../read.sh`, writes nothing except its
own `mktemp -d`, and makes no network call.

| needs | why |
|---|---|
| bash 4.0 or newer | associative arrays and `printf -v` |
| awk | the JSON reader; `jq` is barred by the bake-off |
| coreutils | `date`, `wc`, `tail`, `mktemp`, `stty` |
| `tput` | terminal size; falls back to 24×80 |
| git | through the instrument, not directly except for identity and branch |
| `pkill` | to kill the peer stream's `sleep` grandchild on exit |

`whiptail` is present on this machine and is not used. It draws dialogs, not panes, and a
dialog cannot hold a live feed.

The screen is four regions: a header with the counts, a brief list filtered to mine and in
flight, a detail pane with the phase table and the gate's defects, and an event feed. Keys
are in `README.md`.

## 2. Startup cost

Cold checkout to a running console is one command, because there is nothing to install.
Measured, three runs each:

| | run 1 | run 2 | run 3 |
|---|---|---|---|
| first frame on screen | 21 ms | 27 ms | 29 ms |
| record on screen | 2460 ms | 1945 ms | 1947 ms |

The console paints its frame before the record arrives, and fills it in when the instrument
returns. Both numbers matter, and the second is almost entirely the instrument:
`read.sh briefs` takes 1.88 s on its own and `read.sh defects` 0.97 s, measured separately.
`read.sh snapshot` runs them in series and takes 3.17 s; this console calls the four
subcommands in four parallel children instead and pays the slowest, not the sum.

The install cost is zero and the warm-up cost is two seconds, every launch, and nothing in
this prototype can make the second number smaller.

## 3. Dependency cost

What a user must already have is in the table in section 1, and on any Linux box with git
they have all of it. The failures are specific:

- **No UTF-8 locale.** `${#s}` counts bytes under `LC_ALL=C`. Measured: `done·undated` is
  12 characters and bash reports 13 under C, 12 under C.UTF-8. Every pane border then sits
  one cell off per non-ASCII character in the row. The script sets `LC_ALL` to a UTF-8
  locale if it can find one, and the fallback is a layout that is a few cells wrong rather
  than no layout.
- **No `tput`.** Falls back to 24×80 and the detail pane cuts; the overflow count in the
  pane header says how much.
- **bash 3.2**, which is what `/bin/bash` is on macOS. `declare -A` and `printf -v` are
  both used and both post-date it. Untested there; stated as a limit, not as a guess.
- **`jq` absent** costs nothing, because it was never used. `lib/json.awk` is 117 lines and
  parses what the instrument emits.

## 4. Size

| file | total lines | lines that are not blank or comment |
|---|---|---|
| `blic` | 842 | 689 |
| `lib/json.awk` | 117 | 87 |
| `lib/shape.awk` | 69 | 55 |
| **the console** | **1028** | **831** |
| `measure.sh` | 127 | 97 |
| `probe-limits.sh` | 61 | 52 |

About 200 of the 831 are the JSON reader and the record shaper, and they exist only because
the instrument speaks JSON and the bake-off bars `jq`.

## 5. What it does that the others cannot

Honestly: almost nothing, and the one real thing is not a feature.

It is the only one of the five that a person can clone and run with no install, no
toolchain, and no artifact to trust, and then read and change in the terminal it is running
in. For a repository whose stated value is "bash and markdown and spread because of it",
that is the claim under test, and it holds at 39 briefs.

Two things it shows that are worth naming, though any stack could show them:

- **The undated closes are work, and the console sorts them as work.** A brief whose status
  line says `done` with no `**Closed:**` date is not finished — that is `BRIEFS-11`, and the
  brief that asked for this console names #0028 as the case that survived every run of the
  gate. The default filter has 17 rows against this fixture: #0039 in flight, and sixteen
  undated closes, each with its defect and the next action beside it. The thing the brief
  says is invisible is the first thing on the screen.
- **A derived next action, which the brief lists as an open question.** It is derivable, and
  narrowly. Every line comes off the status line, the phase states, and the Closed date:
  *phase a in flight on blic/bake-off — finish it, then blc-commit-push-pr*, or *done with no
  Closed date — blc-close-brief (BRIEFS-11 is open on this)*, or *serial filed, no ledger —
  blc-start-brief*. The ledger carries enough for the next **gate**. It does not carry what
  the phase actually needs doing, and no amount of parsing will find it there.

## 6. What it cannot do

These are limits, not an unfinished list. The unfinished list is at the end and is short.

- **It cannot measure a character.** `${#s}` counts characters, not cells. Measured:
  `日本語のブリーフ` is 8 characters and 16 cells, so a pane padded to 8 is 8 cells short and
  every border right of it moves. An emoji is 1 character and 2 cells. This fixture is ASCII
  plus `·` and `—`, all one cell, so the fault does not show against this record and would
  show against any record with a CJK title. There is no `wcwidth` in bash.
- **Input is a guess about bytes.** A key is one `read -n1`. Escape is followed by a 20 ms
  read of two more bytes to tell an arrow key from a bare Escape. That is the standard trick
  and it is still a guess: a slow link, a paste, or a terminal that sends a different prefix
  reads as the wrong key. There is no terminfo-driven key table here.
- **It never ran under a real terminal resize.** The `SIGWINCH` trap is wired and fires —
  measured, 3248 bytes of full repaint in the second after `kill -WINCH`. But the build
  environment has no pseudo-terminal (`script` fails with *failed to create
  pseudo-terminal*), so no size actually changed under it, and the transcript was captured
  with `BLIC_ROWS`/`BLIC_COLS` rather than from a terminal. Reported as untested, not as
  working.
- **It polls, and the interval is the latency.** Events are re-read every 5 s, briefs every
  60 s, and the input loop wakes every 250 ms. Measured end to end on a synthetic event: the
  stream prints it 3000 ms after launch and it is on screen 3333 ms after launch, so the
  console took **333 ms** to show it. There is no `inotify` in bash, so the only way to make
  that smaller is to wake more often.
- **Performance is only acceptable because nothing in a frame forks.** This is the most
  useful number in the report. The first working version composed rows with command
  substitution — `$(fit …)`, `$(state_colour …)` — about a hundred forks a frame, and a
  keypress cost **163 ms**. Rewritten so every helper returns through a global and every pad
  uses `printf -v`, the same frame costs **6 ms**. Idle CPU fell from 220 ms per 20 s to
  **80 ms per 20 s, which is 0.4 % of one core**. The constraint holds, and it holds on a
  rule — never fork inside a frame — that nothing in bash enforces and the next person to
  add a row will not know.
- **No types, no tests, no boundary.** 831 lines of string plumbing in which a mistyped
  array name is an empty string and a silent blank row. The repository's own code rule asks
  for explicit interfaces at every boundary and this stack cannot offer one. That conflict
  is in the brief's Open section and this prototype does not resolve it; it prices it.
- **It cannot show what it does not get.** Three faults in the frozen instrument, worked
  around rather than fixed, per the rules:
  1. `blc_status_phase_entries` splits the status line on whitespace, so the older pointer
     form `1:done(commit 383ed5b)` arrives as the single token `1:done(commit`. One brief in
     this fixture renders with the phase state `done(commit` and no pointer. The newer
     `done(PR#114)` form has no space and survives.
  2. The brief-level `state` keeps its pointer — `done(PR#45)`, `done(commit 92a7168)` — so
     every consumer strips to the first `(` before it can group or compare. The phase-level
     `state` does split. Two fields named the same thing with different contracts.
  3. `read.sh snapshot` runs the four readers in series, so the one document costs 3.17 s
     against 1.95 s for the same data fetched in parallel. A console that used `snapshot`
     would look 60 % slower for no reason of its own.
- **One more, found by running it wrong:** with stdin redirected, `read -t` returns failure
  immediately rather than timing out, and the first version spun a core at 100 %. It now
  tells a timeout from a closed stdin and exits on the second. Measured: `blic < /dev/null`
  exits 0.

Ran out of time, which is a different thing: a pane for declarations (the count is in the
header, the claims are not on screen), filtering the feed by kind, a read-marker that
survives a restart, and opening the selected brief in `$EDITOR`.

## 7. What it was like to sit beside

First, the part that makes this answer weaker than the other seven: I never sat beside it in
a terminal, because this environment has none. I watched it the way you watch a thing through
a window — scripted sessions, whole frames printed as text, about an hour of them, reading
each frame the way I would have read the screen. Take the paragraph below with that discount.

It is calm, and that surprised me. The list does not move unless the record moves, so the
screen is boring in the way a dashboard should be boring, and the one time it was not boring
was worth the whole exercise: I was reading #0024's
detail — status line `done`, no Closed date, the `BRIEFS-11` judgment right there under it —
when a `SYN` line arrived at the bottom saying `sam` had closed #0024. Two views of the same
serial disagreeing on the same screen, one from the record and one marked as not from the
record. That is the brief's claim working, and I did not have to look for it. What wore on me
was smaller and constant: the two-second gap at every launch, and knowing that the layout is
correct only because the titles happen to be ASCII. I never once wanted it to be prettier. I
twice wanted to press a key and open the ledger, and that is the verb layer, which this brief
says is not its subject.

## 8. What you would throw away

- **The JSON path.** `lib/json.awk` and `lib/shape.awk` are 200 lines and two awk processes
  per subcommand, and they exist only to undo the instrument's choice of JSON. If this won,
  the read surface it gets built on emits records, not a document, and both files are
  deleted. That is a change to the instrument's successor, not to the instrument, which was
  right to be frozen.
- **The global-variable rendering.** `FITV`, `SCOL`, `KTAG`, `BS`, `RANKV` — functions that
  return through a shared name because the alternative costs 157 ms a frame. It is fast and
  it is the exact opposite of a typed boundary. Any stack with a function call cheaper than a
  fork would keep the clean version.
- **`--keys` and `--frames`.** A second way in, built because this environment had no
  terminal. It drives the real dispatch, so it is honest, but it is 30 lines of test
  scaffold wearing the costume of a feature.
- **The whole left pane, possibly.** Seventeen rows, sixteen of which say the same thing —
  `done·undated` — and one of which is the work. Prototype 4 is the one that can end this,
  and on this fixture its output would be about four lines. If those four lines are enough,
  the other 800 lines of mine are a screen built to hold them.

## Should this approach win

No, and it should not be dismissed either, because the two halves of the question have
different answers.

**The constraint survives. The stack does not deserve the win.** "No service, no build, no
daemon" holds against a live full-screen view: 21 ms to a frame, 6 ms to redraw one, 0.4 %
of a core at rest, zero install, one file to read. Nothing in this prototype needed a
toolchain and nothing in it would be faster with one. But it is fast only because of an
unwritten rule about forking that the next contributor will break, it is 831 lines with no
types and no tests against a repository whose own rule asks for an interface at every
boundary, and it is wrong by construction on any title that is not ASCII.

**My recommendation is that prototype 4 should win and this one should be the evidence for
why.** What made the day worthwhile was not the panes. It was two lines — the derived next
action, and a marked event contradicting the record I was reading — and neither needs a
screen. If the bake-off decides it does want the screen, buy it with prototype 2 or 3, and
keep this report as the measurement of what the screen cost in the language the repository
prefers.
