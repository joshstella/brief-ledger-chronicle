# p1 — bash and ANSI

Prototype 1 of the #0039 bake-off. Read `REPORT.md` for the findings. This file is how you
run it.

## Start it

```
experiments/blic/p1-bash/blic
```

Nothing to install and nothing to build. Press `?` for the keys, `q` to quit.

| key | does |
|---|---|
| `j` `k` or `↑` `↓` | move the selection |
| `g` `G` | first and last brief |
| `Ctrl-F` `Ctrl-B` | page |
| `[` `]` or `←` `→` | scroll the detail pane |
| `f` | cycle the filter: mine and in flight · in flight · mine · all |
| `/` | search serial, title and slug; Return accepts, Esc clears |
| `a` | mark the feed read |
| `p` | start or stop the synthetic peer stream |
| `r` | re-read the record now |
| `?` | keys |
| `q` | quit |

## What is on the screen

- **Header** — identity, branch, and the counts that change while you sit there.
- **Left** — briefs, in-flight first, then not-started, then the undated closes. `*` marks
  mine. `done·undated` is a brief whose status line says `done` and whose ledger carries no
  `**Closed:**` date; it is still yours to do.
- **Right** — the selected brief, its phase table with each phase's pointer, the gate's
  defects against it, and a derived next action.
- **Bottom** — events, newest first. `git` is the record. **`SYN` is a synthetic event from
  `peer-events.sh` and is not in the record.** The marking is load-bearing; see
  `../README.md`.

## Flags

| flag | for |
|---|---|
| `--no-peer` | do not start the synthetic stream |
| `--peer-interval N` | seconds between synthetic events (default 7) |
| `--once` | wait for the record, print one frame, exit |
| `--keys STRING` | drive the same dispatch from a string instead of the keyboard |
| `--frames` | with `--keys`, print whole frames as text — this is how `session.txt` was made |
| `--settle` | hold the key loop until the record is loaded |

`BLIC_ROWS` and `BLIC_COLS` override the terminal size for a capture with no terminal
attached. `BLIC_TICK`, `BLIC_EVENT_POLL` and `BLIC_BRIEF_POLL` set the poll intervals.

## Files

| file | lines | what |
|---|---|---|
| `blic` | 842 | the console |
| `lib/json.awk` | 117 | JSON to flat `path<US>value`; `jq` is barred by the bake-off |
| `lib/shape.awk` | 69 | those flat lines to one record per array element |
| `measure.sh` | 127 | the numbers in REPORT.md sections 2, 3, 4 and 6 |
| `probe-limits.sh` | 61 | the failure probes in REPORT.md section 6 |
| `session.txt` | — | one real session, 17 frames, colour codes stripped |

It reads through `../read.sh` only. It writes nothing but its own temporary directory.
