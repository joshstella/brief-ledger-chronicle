# Prototype 2 — Go and Bubble Tea, one static binary

Bake-off for brief #0039. Branch `blic/p2-go`, cut from `blic/bake-off`. Nothing here merges
to `main`.

All numbers below are measured on the machine that built this prototype: WSL2 on Linux
6.18, 16 cores, a fast SSD and a link that pulled 66.8 MB in about three seconds. A four-core
laptop on a slow link will be worse. Where I estimate rather than measure, I say so.

---

## 1. What it is

A single Go program that reads `experiments/blic/read.sh` and `experiments/blic/peer-events.sh`
and draws one screen.

- **Language:** Go 1.26.0.
- **Direct dependencies:** two — `github.com/charmbracelet/bubbletea v1.3.10` and
  `github.com/charmbracelet/lipgloss v1.1.0`.
- **Total module graph:** 25 modules. `go list -m all` prints 26 lines, and one of them is
  this module.
- **Runtime dependencies of the built binary:** none of its own. It is a static Go binary. It
  does need `bash` and `git` on the path, because the data contract for the bake-off is a
  shell script, not a file format.

Start it:

```
cd experiments/blic/p2-go && ./run.sh
```

`run.sh` is eleven lines. It builds and runs. Three flags matter:

```
./run.sh -no-peer                     # no synthetic events, only the real record
./run.sh -capture 'j,4,peer:0'        # plain-text frames, no terminal needed
./run.sh -session '4,j,tab' -hold 3s  # run the real program against a scripted input stream
```

The screen holds four surfaces at once.

1. **Briefs**, left. Filtered. The default filter is "mine and in flight", which is one brief
   in this fixture. Keys `1` to `5` switch the filter, `/` searches.
2. **Detail**, top right. The derived next action, the reason for it, the status line, the
   phase table with state, pointer and label, and the gate's judgments against that brief.
3. **Feed**, bottom right. Git events from `read.sh events`, newest first, merged with the
   synthetic peer events. Every synthetic line carries the text `SYNTH ⚠` and a separate
   color.
4. **Status bar**, bottom. Identity, brief count, gate count, declaration count, the age and
   the cost of the last read, and the state of the peer stream.

The left pane fills its spare rows with the two things no filter puts in front of you: the
gate's judgments grouped by clause, and the declaration window.

The console never writes a record, never pushes, and never calls a forge. It holds no state
between runs. The peer stream is a child process and dies with the program.

---

## 2. Startup cost

Cold checkout to a running console, on a machine with no Go toolchain, measured:

| Step | Measured |
|---|---|
| Download and extract `go1.26.0.linux-amd64.tar.gz` | **4.26 s** |
| `go mod download` and a cold `go build` (empty module cache, empty build cache) | **4.05 s** wall, 14.54 s CPU |
| Binary start to the first frame on screen | **3.13 s** |
| **Total, no toolchain present** | **≈ 11.4 s** |

Two of those numbers need a note.

**The 3.13 s first frame is not Go's.** `read.sh snapshot` alone takes 3.15 s on this fixture.
The binary adds no measurable time. Prototype 1 in bash will see the same 3.1 s, because the
cost is the instrument, and most of the instrument is the gate. Measured per command:

| `read.sh` command | Wall | User CPU |
|---|---|---|
| `declarations` | 0.00 s | 0.00 s |
| `events` | 0.30 s | 0.24 s |
| `defects` | 0.91 s | 0.93 s |
| `briefs` | 1.91 s | 1.69 s |
| `snapshot` | 3.11 s | 2.84 s |

That table changed the design. A console that reran the whole snapshot every 20 seconds would
hold about 15% of one core for the whole day to notice a commit. So the console polls
`read.sh events` every 20 seconds at 0.3 s, and the full snapshot every 5 minutes, and `r`
forces the full read. The steady cost is about 1.5% of a core plus 1%. Both intervals are
flags.

**The 4.05 s build is 14.54 s of CPU across 16 cores.** On four cores, expect about 10 s. That
figure is an estimate and I did not measure it.

Rebuild after one file changes: **0.19 s**. The second build onward is free.

---

## 3. Dependency cost

A user must already have:

- **A Go toolchain.** Without it nothing runs. `run.sh` exits with a message that says so.
- **`bash` and `git`.** Without them the binary starts and the first read fails. The error
  reaches the status bar instead of the terminal, which is worse, and is a defect.

The toolchain is the whole argument, so here is its weight:

| Artifact | Size |
|---|---|
| Go tarball, downloaded once | 66.8 MB |
| Extracted `GOROOT` | 232 MB apparent, 269 MiB on disk |
| Module cache for 25 modules | 69 MB |
| Build cache after one cold build | 66 MB |
| **Toolchain and cache total** | **≈ 367 MB** |
| **Binary produced** | **5.67 MB** (3.94 MB with `-ldflags="-s -w"`) |

So this prototype spends about 367 MB of disk to produce a 5.4 MiB binary, against a 3 kB
bash script that needs nothing.

The optional-download path removes the toolchain from the user and does not remove it from
the project. Somebody builds and publishes one binary per platform, signs or notarizes it for
macOS, and keeps that pipeline alive. The repository gains a release process it does not have
today. That is the real cost of this path, and it is not a number I can measure here.

The binary itself is honest. It is static, it has no shared-library dependency, and it starts
in under a millisecond.

---

## 4. Size

Code I wrote:

| | Lines |
|---|---|
| Go, excluding tests | 1,952 |
| Go, excluding tests, blank lines and comments | 1,628 |
| Go tests | 377 |
| Shell (`run.sh`) | 11 |
| **Total** | **2,340** |

Dependencies, excluded from that count: 25 modules, 69 MB of module cache.

Nineteen tests cover the typed boundary, the next-action derivation, the synthetic marking,
the filters, the search, the two polling cadences, and one check that no frame is ever taller
or wider than the terminal. `go vet` and `gofmt` are clean. The tests run in 3.2 s, and almost
all of that is one real call to `read.sh snapshot`.

---

## 5. What it does that the others cannot

Four things, and I believe only the second and third are out of reach of a careful bash
prototype.

**The three answers stay on one screen.** What is mine, what that brief wants next, and what
changed are all visible at once and stay visible. A watch loop re-prints and a bash view can
do the same layout. What a loop cannot hold is the selection: I move through 16 flagged briefs
with `j` and the detail pane follows, with no re-run and no scrollback.

**The read surface is typed, and drift stops the console.** `read.sh` has no schema and no
tests. The Go structs in `internal/record/types.go` cite the `printf` line in `read.sh` that
writes each field, and the decoder rejects unknown fields. A field added to the instrument
fails the decode loudly. A `jq` pipeline would drop it in silence and keep drawing. This is
the one place the author's typing rule buys something the bash rule cannot.

**It refuses to show an unmarked synthetic event.** The README says a console that shows a
peer event without marking it lies about the record. Here the decoder rejects a peer line that
carries no `"synthetic": true` and the error goes to the status bar. The honesty is a type
rule, not a convention a future edit can forget. The mark is also text, `SYNTH ⚠`, not only
color, so it survives a plain-text capture and a color-blind reader.

**Two polling cadences.** Section 2 explains why. Any prototype can do this. None of the
others has a reason to measure it, because none of the others plans to run for eight hours.

---

## 6. What it cannot do

### Limits

- **It cannot run without a toolchain or a published binary.** Section 3. This is the limit
  the bake-off exists to price.
- **It cannot leave the terminal.** A desktop notification needs another dependency or a
  shell-out, and a shell prompt integration is not something a full-screen program can do.
  The brief's open question about where notification lands is not answered here, and cannot
  be.
- **It cannot see the forge.** The console is forbidden to call GitHub or GitLab. So a phase
  pointer that says `PR#125` is a string. The console cannot say whether that PR is open,
  merged, or has a review waiting on me. The strongest "what changed that I did not do" signal
  in a real team is a review comment, and it is out of scope by construction.
- **It cannot tell a true status line from a stale one.** It reads the same line the stale
  scan reads. It can show the disagreement the gate already found. It cannot find a brief
  whose line is confidently wrong.
- **The next action is derivable in five shapes only.** A done brief with no `Closed` date
  wants `blc-close-brief`. A filed serial with no ledger wants `blc-start-brief`. A phase in
  progress with a pointer wants a review. A phase that is planned wants
  `blc-next-brief-phase`. Everything finished with an open brief wants the closeout.
  Everything else prints `none derivable` and names the state. That is the honest answer to
  the brief's third open question: **the next action is derivable, and the derivation is
  thin.** It depends on the gate's output more than on the ledger. Take the gate away and
  three of the five shapes go with it.
- **One brief defeats it today, and the brief is #0039 itself.** Its ledger uses the phase
  state `pending`, which is not in the five-state vocabulary in `docs/blc/briefs/README.md`.
  The console reports `phase b is "pending", which is not a state this console knows`. This
  is the same class of defect the brief names about `tools/list-briefs.sh` printing `planned`.
  I left the behavior as it is. A console that quietly mapped `pending` to `planned` would be
  a sixth reader with a private opinion.
- **No pseudo-terminal exists on this machine, so I never watched it in a real terminal.**
  `script` cannot open a pty here and the program refuses to start on `/dev/tty`. I added two
  ways to get evidence anyway. `-capture` drives the real model and view and prints frames.
  `-session` runs the real Bubble Tea program against a scripted input stream with no
  terminal, which exercises the loop, the commands, the ticker, the key decoder and the peer
  subprocess. `SESSION.txt` holds both. What neither proves is the redraw: flicker, resize,
  and alt-screen behavior are untested. Treat the layout as proved and the terminal behavior
  as unproved.

### Ran out of time, not limits

- No mouse support, no color-profile override, no configuration file.
- The detail pane scrolls, and the scroll indicator only appears when content overflows. It
  is not pretty.
- The feed cannot be filtered to one brief, which it obviously should be able to do.
- Never run on macOS or Windows. The code has no platform-specific part, so I expect it to
  work, and expectation is not a test.
- The error from a missing `git` or `bash` lands in the status bar, where a user who cannot
  see a status bar yet will not find it.

---

## 7. What it was like to sit beside

I spent most of the build driving it through `-capture`, which is a strange way to meet a
console, and the thing I noticed first is that the default view is almost empty. One brief is
mine and in flight. That is correct and it is also an anticlimax: the console's own fixture has
nothing for it to tell me. Filling the empty rows with the gate summary fixed the feeling and
taught me the real lesson — the thing I want on open is not a list of briefs, it is the four
lines that say sixteen briefs are flagged and nobody has declared anything. The list is how I
drill in afterward. When I pressed `4` and walked the sixteen flagged briefs with `j`, each one
reading `NEXT blc-close-brief / BRIEFS-11: status line says done and the ledger records no
Closed date`, the brief's claim stopped being an argument. Sixteen times is not a backlog, it
is a thing nobody has ever been told. The peer feed is the part I trust least. Watching
`SYNTH ⚠ docs: file #0041, the serial two people took` arrive while I worked was the exact
scenario the brief describes, and I still did not feel told. It appeared in a pane I was not
looking at. A line in a pane is not a notification. If this console shipped as it stands, I
would learn about a serial collision the next time I happened to glance right, which is the
same failure as orient, with a nicer font.

---

## 8. What I would throw away

**The three-pane layout.** It is the most defensible-looking part and the least earned. The
detail pane is mostly whitespace for a brief with two phases, and the brief list is one row
at the default filter. A console that opened on the digest and the feed, and showed a brief's
detail only when asked, would fit in half the code and tell me more per glance.

**`NextAction`, in this repository.** The derivation lives in Go, which means prototype 1 and
prototype 3 will each write their own and the three will disagree about what `pending` means.
That is exactly the "sixth reader" defect #0013 was filed about, and I rebuilt it here. The
next action belongs in the read surface, where all five prototypes read one answer. I kept it
in Go only because the surface is frozen for the bake-off.

**The 400-event feed buffer and the alt screen.** Both assume the console is a place you go.
Everything in section 7 says it is not. The thing worth keeping from this prototype is three
hundred lines: the typed decode, the refusal to show an unmarked synthetic event, the
two-cadence polling, and the digest. The screen around them is what I would throw away first.

---

## Notes on the instrument

I did not change `read.sh`. Four things I worked around, reported as the rules ask.

1. **The phase tokenizer splits on `(` and a pointer with a space survives the split.** Brief
   #0002 phase 1 arrives as `"state":"done(commit"` with an empty pointer, because the real
   token is `done(commit 92a7168)`. `internal/record/derive.go` re-splits the state on the
   last `)`. The repository's own tools share this tokenizer, so this is a defect in
   `tools/lib/status-line.sh`, not in the instrument's copy of it.
2. **Phase labels are empty for most older briefs.** `blc_phase_label` finds a row for #0028
   and #0039 and finds nothing for #0003. The console prints `(no row in the ledger table)`
   rather than hiding the gap.
3. **`read.sh snapshot --since X` works by accident.** The dispatcher shifts and then reads
   `${2:-}`, so `--since X` passes `X` and a bare `read.sh snapshot X` passes nothing. The
   help text does not mention `--since` on `snapshot` at all.
4. **Every `closed` field is empty, including on the 38 done briefs.** That is not a defect in
   the instrument. That is the fixture reporting the finding the brief was written about.

One artifact of my setup leaks into the frames in `SESSION.txt`. I worked in a git worktree at
`.worktrees/p2-go`, so `read.sh` reports the repository root as that path and the header shows
`p2-go` where it should show `brief-ledger-chronicle`. The console prints what the instrument
tells it.

---

## The verdict the brief asks for

The repository values bash and markdown with no build. This prototype is 2,340 lines, a
367 MB toolchain, a release pipeline the project does not have, and a 5.4 MiB binary per
platform. It buys a typed boundary that catches instrument drift, a refusal to lie about
synthetic events, and a layout that holds three answers at once.

**It should not win.** Not because it is bad — it is the best interface of the five by some
distance, and I would use it. It should not win because section 7 says the feed did not notify
me, and that is the half of the brief that matters. A pane I have to look at is not better
than a shell prompt I cannot avoid, and it costs 367 MB more. If prototype 4 or prototype 5
can tell me a serial was taken without asking me to look at a screen, this prototype has lost
on the thing it was built to prove, and the right outcome is to take the four ideas in
section 8 and put them somewhere cheaper.
