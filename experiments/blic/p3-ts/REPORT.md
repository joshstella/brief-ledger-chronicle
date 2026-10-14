# Prototype 3 — TypeScript and Ink, typed at the boundary

Bake-off entry for [#0039](../../../docs/blc/briefs/0039-blic-console/brief.md). Branch
`blic/p3-ts`. Nothing here merges to `main`.

What this prototype was built to settle: **the cost of a toolchain against what it buys.**
The numbers below are measured on this machine, on this fixture, with the commands shown.

---

## 1. What it is

**Stack.** TypeScript 5.6 compiled by `tsc` to ES modules, React 18 rendered to the terminal
by [Ink](https://github.com/vadimdemedes/ink) 5, run on Node 22.23.2. No bundler, no test
framework, no linter, no runtime schema library.

**Runtime dependencies — 2 direct, 44 in the tree.**

| Package | Why |
|---|---|
| `ink` | the terminal renderer: flexbox layout, frame diffing, raw-mode input |
| `react` | Ink's component model and reconciler |

**Build dependencies — 4 direct, 18 more in the tree.**

| Package | Why |
|---|---|
| `typescript` | the compiler, which is the whole point of the entry |
| `@types/node`, `@types/react` | types for the two platforms it talks to |
| `json-schema-to-typescript` | generates the read surface types from the schema |

**How a person starts it.**

```
cd experiments/blic/p3-ts && npm install && npm start
```

`npm start` builds and runs. Useful flags: `--no-peers`, `--peer-interval=N`,
`--event-interval=N`, `--snapshot-interval=N`, `--filter=mine-open|in-flight|judged|all`,
`--capture=N`. `npm test` runs 24 tests on the built output.

**Keys.** `↑↓` or `j`/`k` move, `PgUp`/`PgDn` jump ten, `g`/`G` ends, `⇥` switches pane,
`f` cycles the filter, `p` pauses the feed and holds its lines, `r` forces a read, `q` quits.

---

## 2. Startup cost

Measured, not estimated. `npm cache clean --force` first, `node_modules`, `dist` and
`package-lock.json` deleted, then each stage timed with `date +%s.%N`:

| Stage | Time |
|---|---|
| cold `npm install` (empty cache, network) | **4.24 s** |
| `tsc --build` | **0.97 s** |
| node boot to the first populated frame | **3.35 s** |
| **cold checkout to a console showing briefs** | **8.56 s** |

Second-run numbers, for a contributor who already has the cache: `npm ci` 1.99 s, build
0.97 s, first frame 3.35 s — **6.3 s**.

**3.1 s of that first frame is `read.sh snapshot`,** which every prototype pays. Node boot
and the first render together are 0.21 s. The thing the toolchain adds to startup is the
0.97 s build, and `npm install` once.

Measured separately, because the brief's claim is about a thing that runs all day:

| | |
|---|---|
| `read.sh snapshot` | 3.10–3.20 s (39 briefs: `validate-briefs.sh` ~1.0 s, per-brief `git log` the rest) |
| `read.sh events` | 0.34 s |
| `read.sh briefs` / `defects` / `me` | 2.07 s / 0.99 s / 0.00 s |

So the console polls on two cadences: `events` every 5 s, `snapshot` every 60 s or on `r`.
One interval would either miss events or keep a core busy for a record that changes a few
times an hour.

---

## 3. Dependency cost

**What a user must already have:** Node ≥ 18 and npm, plus network access on first run.
Nothing else. No daemon, no database, no login, no forge call, no global install.

**Size on disk:**

| Tree | `du -sh` | packages | files |
|---|---|---|---|
| full (`npm ci`) | **71 MB** | **62** | 7,248 |
| runtime only (`npm ci --omit=dev`) | 25 MB | 44 | — |

The 25 MB runtime figure is not a path a user can take: no build output is committed, so
without `typescript` there is nothing to run. Either you take the 71 MB or someone ships a
`dist/`.

**What breaks without Node:** everything. There is no fallback and no degraded mode — the
process will not start. A user without Node has to install a 40–60 MB runtime from
nodejs.org or a package manager before the 71 MB of `node_modules` is even relevant. On a
locked-down machine that is a ticket, not a command. Prototype 2's single static binary has
no equivalent of this paragraph, and prototype 1 has no equivalent of this whole section.

**Process cost while running**, sampled from `/proc/<pid>/status` every 10 s over a 60 s run:

| t | 10 s | 20 s | 30 s | 40 s | 50 s | 60 s |
|---|---|---|---|---|---|---|
| RSS | 104.5 MB | 107.1 MB | 107.4 MB | 96.1 MB | 106.0 MB | 107.9 MB |

**~105 MB RSS, oscillating with GC, no monotonic growth.** The dip at 40 s is a collection.
The feed is capped at 200 entries so a day-long session has a ceiling. Add to that one
`bash` child every 5 s for `read.sh events`, one every 60 s for `snapshot`, and one
long-lived `bash` for the peer stream. For comparison the shell it replaces is a few MB. The
JavaScript runtime costs two orders of magnitude more memory for the same information.

---

## 4. Size

Hand-written, excluding dependencies and generated output:

| | lines |
|---|---|
| source (`src/**`, no tests) | 1,483 |
| tests (`node:test`, 24 cases) | 262 |
| `schema/read-surface.schema.json` | 157 |
| `package.json`, `tsconfig.json`, `.gitignore` | 62 |
| **total hand-written** | **1,964** |
| generated from the schema (`read-surface.ts`) | 197, not counted above |

Where the 1,483 went: rendering (five components plus the colour table) 500, pure state — a
reducer, a filter and the brief model — 406, the read surface (client, schema walker, state
parser) 275, the two event sources 217, configuration and argument parsing 146. That last
number is larger than it looks like it should be, and it is the price of flags a capture can
drive in place of keystrokes it cannot record.

---

## 5. What it does that the others cannot

**It generates its model of the read surface from a schema, and then checks the instrument
against that schema at runtime.** `schema/read-surface.schema.json` is the only place the
shape is written. `npm run types` generates `src/read-surface/generated/read-surface.ts`
from it, and `src/read-surface/validate.ts` walks the same file at runtime to check what
`read.sh` actually returned. Types and checks cannot drift, because there is one source.
Honest result on this fixture: **zero violations.** The schema describes the instrument
correctly, so the runtime check earned nothing today. It is a tripwire for the day `read.sh`
changes, and on a frozen instrument a tripwire that never fires is just a cost.

**The typed boundary made one lie impossible rather than unlikely.** Provenance is a
discriminated union — `{source:'record', event:RecordEvent} | {source:'synthetic',
event:PeerEvent}` — not a boolean. The README says a console that shows a synthetic event
unmarked is lying about the record. Here the unmarked case is a branch that has to be
deleted for the lie to happen, and `PeerEvent.synthetic` is typed `true`, not `boolean`, so
nothing can construct a synthetic event that denies being one. That is a different kind of
guarantee from remembering to print a tag.

**It separates what the gate says from what it worked out itself.** `DEFECTS` is
`validate-briefs.sh` output, parsed and attributed. `LINTS` is this console's own reading,
labelled as such. The fixture produces 16 of the first and **22 of the second across 6
briefs** — 21 are phases that are in a status line and not in the phase table, the BRIEFS-9
disagreement #0039 cites, and 1 is against the instrument itself (§6).

**It found a defect in the frozen instrument and showed it instead of hiding it.** See §6.

**None of that needs Ink.** Everything above is the type system and the schema. The parts
Ink supplies — side-by-side panes, a cursor that stays inside a window, a feed that pauses
and holds rather than drops — are pleasant and, I think, reproducible in bash with more
effort and less safety. **The honest answer to "what can only this do" is: nothing a user
sees.**

---

## 6. What it cannot do

**Limits, not missing features:**

- **It cannot answer "what is mine" usefully on this fixture.** All 39 briefs are mine, one
  is open, and `declarations` is empty. The default pane holds exactly one row. That is the
  fixture being honest about a one-author repository, and no interface fixes it.
- **"Next action" is only partly derivable, and the console says which.** Over all 39
  briefs: **17 derived, 0 observed, 22 nothing owed.** Sixteen of the seventeen are "status
  says done and there is no `Closed` date: run `blc-close-brief`" — derived from the gate's
  judgment, not from the ledger. **One** comes from the ledger itself, because exactly one
  phase in this repository is in flight. The brief asks whether the ledger carries enough to
  name a next action. On this evidence: barely, and mostly by borrowing the gate's opinion.
  `NextAction.confidence` is in the type for that reason.
- **It cannot report an event the instrument cannot classify.** `read.sh` falls through to
  `code` for a hand-made commit, and the console shows what it is given.
- **It cannot show a real peer.** No prototype can. Every "THEIRS" line in the capture is
  synthetic and marked.
- **No TTY means no keyboard.** Ink needs raw mode, so a capture through a pipe cannot
  record a keystroke, and each frame is appended instead of repainted. `--filter` and
  `--select` exist so the capture can show what `f` reaches, and the file says so.
- **A resize is only as good as Ink's layout.** Ink overlaps rather than scrolls when a
  column overflows, so both panes count their own rows. Below about 24 rows the detail pane
  shows "… N more findings" and hides things.

**Two defects in the frozen instrument, worked around and reported rather than edited:**

1. **`read.sh snapshot <rev>` accepts a revision and drops it.** The dispatcher does
   `snapshot) shift || true; cmd_snapshot "${2:-}"` — after the shift, the revision is `$1`
   and `$2` is unset, so `cmd_events` always gets the default 40 commits. Worked around by
   polling `read.sh events --since` as a separate process.
2. **The phase tokenizer loses a pointer that contains a space.** `1:done(commit 92a7168)`
   reaches a consumer as state `done(commit` with `pointer` empty. One phase in this fixture
   (#0002) is affected. The console prints `pointer lost` in magenta rather than reporting
   `commit` as if it were a pointer, and files it as a lint against the instrument, not
   against the record.

**Also worth saying: the brief-level `state` field is not the five-state vocabulary.** For
**9 of 39 briefs** it arrives with the pointer glued on — `done(PR#11)`, `done(commit
92a7168)`. Every consumer must split it. This is the sharpest thing the exercise taught me
about typing a boundary: I wanted `state: RecordState` as an enum, and that type would have
been **a lie about the data**. The schema says `string` with a description of why, and
`parseState` turns it into `{state, pointer, pointerTruncated, offVocabulary}` once. The
type system did not fix the ragged record. It made me write the raggedness down.

**Not a limit, just unbuilt:** no search, no jump-to-serial, no way to open a brief in
`$EDITOR`, no desktop notification, no watch on the working tree (so a local edit shows up
on the next `snapshot`, within 60 s, and an uncommitted change never shows at all).

---

## 7. What it was like to sit beside

Calm, and then quietly useless. The first thing I noticed is that I stopped running
`orient.sh`, because the answer was already on the screen — and the second thing I noticed is
that the screen almost never changed. The record moves a few times an hour at most, and I had
built a thing that redraws every five seconds to tell me that nothing had happened. The feed
is the part I actually watched, and on this fixture the only lines in it were synthetic ones
I had asked for. The moment it earned its place was opening the `judged` filter and seeing
sixteen briefs marked done with no `Closed` date, each with the exact next action attached.
That is a real finding I would otherwise have met as a line of gate output I scrolled past.
But that is a report I want once, not a pane I want for eight hours. Sitting beside it, the
honest feeling was that I had built a dashboard for a system with one user and three events a
day, and the 105 MB of resident memory sat in `htop` next to my editor the whole time.

---

## 8. What you would throw away

**Ink and React.** They are 25 MB and 44 packages for flexbox in a terminal, and nothing they
drew could not have been drawn with `printf` and three cursor codes. Every argument this
prototype wins, it wins with the schema and the type system — which cost `typescript` and
`json-schema-to-typescript` as build dependencies and nothing at runtime. If the console
stays, strip the renderer and keep the model.

**The 60-second snapshot poll.** Re-reading 39 briefs and re-running the gate on a timer, to
find out that nothing changed, is the wrong shape. The right trigger is a watch on
`.git/HEAD`, `.git/refs` and `docs/blc/` — which is `fs.watch`, costs nothing, and is a
thing prototype 4's loop has the same need for.

**The runtime schema walker,** unless the read surface stops being frozen. It found zero
violations on the fixture. It is 126 lines earning nothing today.

**`--filter` and `--select`.** They exist because a capture has no keyboard. That is a
testing problem solved in the product.

**What I would keep,** in order. `schema/read-surface.schema.json` and the generated types,
which are the honest artifact of this exercise: a written-down description of a read surface
that had none. `parseState`, because nine of thirty-nine briefs need it and every future
reader will otherwise rediscover it. The provenance union. The `NextAction.confidence`
field, which is the only part of the UI that admits what the record cannot support.

**Should this approach win?** No — not given the repo's values. The toolchain buys exactly
one thing worth having, and it is not the interface: it is being forced to write down the
shape of the record and the places where the record disagrees with its own documentation. A
schema and a generated type are 350 lines that would help any of the five prototypes, and
they do not require that the console be a React application. **The right outcome of this
entry is that the schema is kept and the renderer is thrown away.**
