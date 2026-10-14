# Prototype 4 — no screen: `blic next` and `blic watch`

The control. The other four prototypes build a full-screen application. This one asserts that
the "I" in "interactive console" is not needed, and that two plain commands and a notification
answer the brief.

Measured on 2026-10-14, in this repository, against 39 real briefs. Every number below was
measured on the machine that ran the prototype. Where a thing could not be measured, the
report says so instead of estimating it.

---

## 1. What it is

**Stack.** Bash 5.2 and nothing else. No build step. No compile. No package file.

**Dependencies.** `bash`, `git`, `sed`, `grep`, `sort`, `find`, `date`, `wc`, `mktemp`,
`mkfifo`. All are in a stock Ubuntu shell. `jq` is **not** used and is not installed on this
machine, so the JSON that `read.sh` prints is read by a 38-line reader in `lib/json.sh`. That
reader knows the one shape `read.sh` emits and nothing more.

**How a person starts it.** From a checkout of this branch, one line each:

```
bash experiments/blic/p4-watch/blic next
bash experiments/blic/p4-watch/blic watch --peer
```

Add the directory to `PATH` and the two lines become `blic next` and `blic watch`.

Three other entry points exist, all small: `blic watch --once` for one poll, `blic transports`
to report where a notification can land, and `bash t/run.sh` for the tests.

---

## 2. Startup cost

Measured from a cold clone of this branch to the first answer on screen:

| step | time |
|---|---|
| `git clone --branch blic/p4-watch` (local, 165 commits) | 0.09 s |
| first `blic next` in the fresh clone | 2.06 s |
| **cold checkout to first answer** | **2.15 s** |
| second and later `blic next` | 2.01 s |
| `blic watch` start to steady state | 0.34 s |
| `bash t/run.sh`, 8 cases | 0.22 s |

There is no install step to include, because there is nothing to install.

Of the 2.01 s, **2.00 s is `read.sh briefs`** — the shared instrument, which runs 39 ledgers
through `sed` in a loop. The prototype's own work is about 0.05 s. For comparison, `tools/orient.sh`
takes 3.40 s and prints 45 lines; `blic next` takes 2.01 s and prints 5.

`blic watch` starts in 0.34 s, which is one `read.sh events` call to learn what it has already
seen.

---

## 3. Dependency cost

A user must already have bash and git. In this repository that is not a cost: `read.sh`,
`orient.sh` and every tool under `tools/` need the same two.

What breaks without each thing:

- **No `git`** — nothing works. Both commands read refs and commit subjects.
- **No `find -printf`** — the cheap change check in `watch` fails, and the watcher falls back
  to noticing only commits. `-printf` is GNU; BSD `find` on macOS does not have it.
- **No `jq`** — nothing. It is never called.
- **No network** — nothing. Neither command fetches, pushes, or calls a forge.
- **No notification daemon, no terminal** — `watch` still prints its line on stdout. The
  notification is an addition to the line, never a replacement for it. See §6.

---

## 4. Size

Lines I wrote, excluding the frozen instrument and excluding `REPORT.md`:

| file | lines | code lines |
|---|---|---|
| `blic` | 25 | |
| `next.sh` | 202 | |
| `watch.sh` | 178 | |
| `notify.sh` | 101 | |
| `lib/json.sh` | 38 | |
| **total shipped** | **544** | **395** |
| `t/run.sh` (tests) | 77 | 48 |
| **total written** | **621** | **443** |

"Code lines" excludes blank lines and comment lines. The gap between 544 and 395 is comment:
about one line in four, which is where the reasoning for each rule lives.

---

## 5. What it does that the others cannot

**It derives an action, and it says which rule derived it.** `blic next --why` prints the rule
name under each line. A console that shows a list of things to do, with no way to ask why a
line is there, is asking to be trusted. This one can be audited in one keystroke.

**It is the only prototype whose output composes.** `blic next | mail`, `blic next` in a shell
profile, `blic watch >> log`, `blic next` in a `git` hook, `blic watch --transport tty` writing
to a second terminal while the first one compiles. A full-screen application owns its terminal
and can do none of this. This is not a small difference: it is the whole difference between a
command and an application.

**It can run with no terminal at all.** The watcher was measured headless, detached with
`setsid nohup`, with stdout to a file. Nothing in it needs a tty, a `TERM` value, or a
character cell. The machine it was measured on has **no pty available at all** (`/dev/ptmx` is
absent) and the watcher ran for 2 hours 22 minutes there without complaint. No full-screen
prototype can make that claim.

**Silence.** Measured: one watcher, `--interval 20`, idle repository, **8573 seconds elapsed,
0 bytes on stdout, 4 seconds of CPU**. A second measurement with the poll logged to a file
(`BLIC_TICK_LOG`, off by default) recorded **12 polls in 61 wall seconds at `--interval 5`,
every gap exactly 5 seconds, no drift**. A full-screen prototype redraws; this one does not
exist until something happens.

Being honest about the other direction: **nothing here needs to be two commands rather than a
screen.** Any of the other four could print the same list. What they cannot do is not print it.

---

## 6. What it cannot do

These are limits, not missing features.

**It cannot tell me what to do about the work.** This is the finding and §9 argues it. The
ledger carries the state of a phase and a pointer to its branch. It does not carry what the
phase is waiting on. For the one brief in flight here, the strongest line the record supports
is "phase a has 1 commit not in `origin/main`". That the next act is review rather than more
work is a guess the pointer cannot settle.

**It cannot prove a squash merge.** `blc-prune-stale-branches` already says that only a forge
can, and a forge call is out of scope. The merge test here reads the trunk's commit subjects
for `[#NNNNx]`, which is what `blc-commit-push-pr` writes. It survives a squash because the
subject does. It fails on a hand-written subject, on a rebase that reworded, and on a phase
done twice. Every line it produces says "prune", never "delete".

**It cannot see a peer.** Not because of the fixture: because of the rules. The only real
source of another person's work is `git fetch`, and a read-only prototype makes no network
call. So `watch` against this repository can only ever report my own commits, which it is built
to suppress. Every peer event in this report came from `peer-events.sh` and every one of them
is marked `[synthetic]` in the output.

**Notification does not land anywhere on this machine.** Measured, by testing each transport
rather than by looking for the binary:

| transport | available here | why |
|---|---|---|
| terminal bell | no | no controlling terminal; `/dev/ptmx` absent, so no pty can be opened |
| OSC 9 | no | same |
| OSC 777 | no | same |
| `notify-send` | no | not installed; and `org.freedesktop.Notifications` answers nothing on the session bus, so installing it would not help |
| write to a tty | **yes** | the only one that worked. `BLIC_TTY=/path blic watch` was measured delivering a line to another file descriptor |
| Windows toast through WSL interop | no | `powershell.exe` is on `PATH` and `$WSL_INTEROP` is set, and the call still fails with `UtilConnectUnix: connect failed 2` |

Two things follow, and they pull in different directions. The honest one: **the environment
this was measured in is not an interactive terminal**, so "bell does not work" means "bell
cannot be reached from here", not "bell is broken in WSL2". I could not test an interactive
WSL2 terminal and I will not claim I did. The other one: **WSL2 removes the two transports
that do not depend on the terminal.** There is no notification daemon on the session bus, and
`systemctl --user is-system-running` reports `offline`, so there is nothing to supervise a
long-running watcher either. The transports that survive WSL2 are the ones that write bytes to
a file descriptor somebody is looking at. That is the terminal, and prototype 5's thesis —
that the answer may be none of the terminal ones — gets support from this table, not from an
opinion.

**It says nothing at all under the wrong git identity, and that is worse than it sounds.**
Measured, by accident, during the cold-clone timing above. The clone landed in `/tmp`, outside
the path rule that sets this author's work email, so `git config user.email` returned
`josh@ariath.ai` instead of `josh.stella@gmail.com`. Assignment is `Owner`, or `Author` when
there is no `Owner`, so **every one of the 39 briefs stopped being mine, and `blic next` printed
`nothing is yours to do. The record is consistent and nothing is in flight.`** Against a record
carrying 16 open judgments. The sentence is false and the command had no way to know it. A list
filtered by identity cannot report a defect that nobody owns, and on a fresh checkout — the
exact case where a person most needs to be told what is wrong — the identity is the thing most
likely to be unset. `tools/validate-briefs.sh` does not have this failure because it does not
filter. See §8.

**It does not survive the shell, unless it is told to.** Measured. A plain child dies on
`SIGHUP`, which is what happens when the terminal closes. Started with `setsid nohup`, it
survived a `SIGHUP` aimed at the starting shell's whole process group and kept polling. So the
durable start command is:

```
setsid nohup blic watch --peer --transport tty > ~/.blic-watch.log 2>&1 &
```

**It does not survive sleep, and nothing here can make it.** The poll loop keeps time by
counting one-second sleeps, and `sleep` does not count time the machine spent suspended. A
20-second poll that crosses a suspend resumes late by however long the suspend lasted, and then
catches up in one poll — so no event is lost, the report of it is merely late. Worse, on WSL2
the host can stop the VM outright (`wsl --shutdown`, or a host sleep with the VM idle), and
then the watcher is gone with no process left to notice. With `systemd --user` offline there is
no supervisor to restart it. **The honest answer to "a watch loop that outlives nothing is not
a control plane" is: this one outlives the terminal and does not outlive the machine.** The
thing that would fix it is a user service, and a service is what the brief rules out. That is a
real cost of the no-daemon constraint and not a gap in this prototype.

Ran out of time, which is a different list: no `--since` on `watch`, so a watcher started after
an event never reports it; no grouping of two events from the same person; no colour.

---

## 7. What it was like to sit beside

I did not sit beside it, and that is the report. I started the watcher, it printed one line
about its interval, and then it was gone — no window, no pane, nothing to glance at. Twice I
checked that it was still alive with `pgrep`, which tells you something: the absence of output
is indistinguishable from the absence of a process, and I did not trust the silence until I had
proved it twice. `blic next` was the opposite experience. I ran it, read five lines, and had
nothing left to do with it. There was no second screen to look at, no state to carry, and no
reason to run it again for several minutes. That is either the strongest thing about this
prototype or the clearest sign that it is an unfinished one, and I genuinely cannot tell which
from one session.

---

## 8. What you would throw away

**The merged-branch line.** `blc-prune-stale-branches` already does this job properly, with a
forge test that can actually prove a squash. My version re-derives a weaker answer and puts it
in the list. It is the one line in `blic next` that competes with a tool instead of reading one.

**The JSON reader.** `lib/json.sh` is 38 lines of string surgery that works because `read.sh`
emits exactly one shape. The moment the read surface is built properly, this must go. It
already cost one defect: the last brief in the array was silently dropped, because `read`
returns false on a line with no newline, and the brief it dropped was the only in-progress one
in the fixture. A hand-rolled parser that drops exactly the record that matters is the correct
argument against hand-rolled parsers.

**The grouping rule in `next`.** Sixteen briefs with one defect collapse into one line with a
list of serials. That is right for sixteen. It is wrong for three, where the serials should
each get their own line with their title, and wrong for ninety, where the serial list is a wall.
The threshold is hard-coded as "always group" and should be a judgment.

**The identity filter, as the only filter.** §6 records what it did: under an unexpected
`user.email` the command reported an empty, consistent record while sixteen judgments stood.
"Mine, next" is the brief's own framing and it is right for the work, and it is wrong for a
defect in the record, which belongs to whoever is reading. The repair is not a flag. It is two
sections in the output — what is mine, then what is wrong and unclaimed — and the second one
never filters.

**Keep:** `--why`, the two-tier poll, and the rule that my own work is never news.

---

## 9. Does this make a TUI unnecessary?

### The case that it does

The list is five lines. A five-line answer does not need a screen; it needs a prompt. Nothing
in the output of `blic next` below would be improved by a cursor, and nothing in it changes
often enough to be worth watching — the fastest-moving item in this repository's whole record
is one phase pointer, and it changes a few times a day.

The watcher proves the harder half. It ran for **8573 seconds and printed nothing**, and that
was the correct behaviour. A full-screen console would have spent those 8573 seconds drawing a
view of a record that did not change, in a window that would have to be somewhere on a screen,
in front of a person who would learn to stop looking at it. The only thing that has to break
into attention is the event, and an event is one line.

Then there is the cost side. Startup is 2.7 seconds from a cold clone, the dependency list is
"bash", and it composes with every other thing a terminal can do. The brief says BLC is bash
and markdown and is spread because of it. This prototype is the only one of the five that does
not have to argue with that.

### The case that it does not

**The list is five lines because the record is almost empty.** Thirty-eight of the thirty-nine
briefs are `done`. One is in flight. A repository with four contributors and nine live briefs
would produce a list that scrolls, and a list that scrolls wants filtering, and filtering wants
a cursor. I have not shown that this scales; I have shown that it is enough for one author with
one open brief, which is the easiest possible case.

**There is nothing to do between the two commands.** `blic next` tells you the state and
`blic watch` tells you when it changed, and neither one lets you act. The brief forbids writing,
so no prototype in this bake-off can act — but a full-screen console is at least a place where
the verbs could land later. Two commands are not a place. If the record verbs ship, prototype 4
is the design that has to be thrown away to make room for them, and the other four are not.

**Silence has a cost I measured in my own behaviour.** I checked twice that the process was
alive. A view, even a boring one, answers "is this working" for free, and a silent loop does
not. The fix is a heartbeat, and a heartbeat is the first line of a status display.

### The verdict

A full-screen console is **not needed to answer the brief's two questions.** It is needed if the
answer is going to grow a third question, a filter, or a verb. The claim in the brief is that a
console reads the same records, derives nothing a person could not derive, and runs while the
work happens. Two commands satisfy all three, on this record, today.

What ends the bake-off is not that this prototype is prettier. It is that §6 found the real
limits — notification does not land, and nothing survives a suspend — and **not one of those
limits is caused by having no screen.** Prototypes 1, 2 and 3 will meet the same two walls with
a renderer attached. If the walls are the problem, the screen is not the answer to it.

---

## Is "next action" derivable from the record?

The brief's open question, and the half this prototype was told was the harder one.

**Answer: the record supports derivation of what is wrong with the record. It does not support
derivation of what to do about the work.**

Ten rules read the record. Here is what each one found in 39 real briefs:

| rule | what it derives | real instances |
|---|---|---|
| `IN-FLIGHT` | a phase is open; how far its branch is ahead of the trunk | **1** |
| `NO-CLOSE-DATE` | status `done`, no `**Closed:**` date (BRIEFS-11) | **16** |
| `MERGED-BRANCH` | a local branch whose phase commit is in the trunk | **7 branches** |
| `PHASE-MERGED` | the phase is in the trunk and the line still says open | 0 |
| `ALL-PHASES-DONE` | every phase closed, the brief still open | 0 |
| `NO-PHASE-OPEN` | nothing in flight and a phase pending | 0 |
| `BRANCH-GONE` | the pointer names a branch that does not exist | 0 |
| `NO-LEDGER` | a filed serial with no ledger | 0 |
| `NO-STATUS-LINE` | a ledger whose status line cannot be found | 0 |
| `DECLARATION` | my declaration still claims unfiled work | 0 |

Seven of the ten rules have **no instance in the fixture**. That is not a fixture defect — it is
the finding stated the other way. This repository closes its phases on the day it opens them, so
the states that would need a decision never persist long enough to be found by a reader. The
seven are tested against hand-written snapshots in `t/run.sh` through `BLIC_SNAPSHOT`; all eight
tests pass. `bash t/run.sh` → `8 passed, 0 failed`.

Of the 17 brief-level items the record does yield:

- **16 are repairs to the record itself.** They say nothing about the work. They are also
  already printed by `tools/validate-briefs.sh`, which has reported them on every run since each
  brief closed. So the value of `blic next` on this fixture is **not derivation at all. It is
  delivery.** The derivation was already done, by the gate, and ignored.
- **1 is the live brief,** and for it the record yields `#0039 phase a has 1 commit not in
  origin/main`. Strip the git part and the ledger's own contribution is "phase a is
  in-progress on branch blic/bake-off" — which is the sentence the brief predicted a prototype
  would find itself limited to.

One more thing the 39 briefs settle: **derivation depends on an input that is not in the
record.** `mine` comes from `git config user.email`, and §6 shows the whole list emptying when
that value changes while the record does not. Whatever a console derives, it derives from the
record plus the machine, and the machine is the less reliable half.

What is missing from the ledger to make the stronger thing possible is small and specific: the
phase row records a state and a pointer, and not **what the phase is waiting for**. `in-progress`
covers "nobody has started" and "it is in review" and "it is blocked on a decision", and the
convention actively merges two of those — `docs/blc/briefs/README.md:149` says a parked branch
with a reason is `deferred` and one without is `in-progress`. A reader cannot recover the
difference, so no reader can derive the next act from it.

So: derivable for consistency, not for intent. A console built on this record can be an alarm
about the record and cannot be a work queue. That is worth knowing before anybody builds the
full-screen version of a work queue.

---

## The output

`blic next`, run against this repository's 39 briefs on 2026-10-14. This is the whole output,
unedited:

```
$ blic next
blic next · josh.stella@gmail.com · 39 briefs · 03:34
 1. #0039 phase a has 1 commit not in origin/main — review and merge it (blc-review-pr, blc-commit-push-pr)
 2. 16 briefs say done and carry no Closed date — write the close date (BRIEFS-11)
     0001 0002 0003 0004 0005 0006 0008 0009 0010 0017 0023 0024 0025 0026 0027 0028
 3. 7 local branches are merged into origin/main — blc-prune-stale-branches
```

With the audit trail:

```
$ blic next --why
blic next · josh.stella@gmail.com · 39 briefs · 03:34
 1. #0039 phase a has 1 commit not in origin/main — review and merge it (blc-review-pr, blc-commit-push-pr)
      rule IN-FLIGHT
 2. 16 briefs say done and carry no Closed date — write the close date (BRIEFS-11)
     0001 0002 0003 0004 0005 0006 0008 0009 0010 0017 0023 0024 0025 0026 0027 0028
      rule NO-CLOSE-DATE
 3. 7 local branches are merged into origin/main — blc-prune-stale-branches
      rule MERGED-BRANCH
```

And `blic watch --peer`, which is silent until a peer does something:

```
$ blic watch --peer
blic watch · blic/p4-watch · every 20s · peer on · transport none · quiet unless something is not mine
01:07:12  dana@example.test  phase       #0024b  [#0024b] split the renderer from the scan [synthetic]
01:07:19  dana@example.test  declaration         docs: declare #0041, picked up not yet filed [synthetic]
01:07:26  sam@example.test   filed       #0041   docs: file #0041, the serial two people took [synthetic]
01:07:33  sam@example.test   close       #0024   docs: close #0024 (the renderer split) [synthetic]
```

Every line above is synthetic and says so. Against the real record the same command prints the
banner and then nothing, for as long as you leave it running.

---

## A note on the instrument

`read.sh` is correct for everything this prototype asked of it. Three observations, none of
which needed a work-around:

1. **`read.sh briefs` costs 2.0 s of the 2.4 s that `blic next` takes.** It is 83% of the
   startup number every prototype will report. A real read surface should cache or batch;
   this one re-reads 39 ledgers with `sed` per field.
2. **The brief `state` field carries its pointer** — `done(commit 92a7168)`, not `done`. Every
   consumer has to cut at the first `(`. Not wrong, since the status line is written that way,
   but five prototypes will each write that line.
3. **Drafts are invisible.** `cmd_briefs` globs `[0-9]*`, so `docs/blc/briefs/_drafts/` never
   appears. That is right for a brief registry and it means no prototype can show a parked
   draft. Worth stating because an onlooker will ask where the drafts went.
