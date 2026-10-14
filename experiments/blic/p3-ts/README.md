# blic-p3 — TypeScript and Ink

Prototype 3 of the [#0039](../../../docs/blc/briefs/0039-blic-console/brief.md) bake-off.
Read-only. It merges nothing, writes nothing, and calls no forge.

```
cd experiments/blic/p3-ts && npm install && npm start
```

Read [REPORT.md](REPORT.md) for the measured cost and the honest verdict, and
[session-capture.txt](session-capture.txt) for one recorded session.

## Keys

| | |
|---|---|
| `↑` `↓` `j` `k` | move the cursor |
| `PgUp` `PgDn` `g` `G` | jump ten, first, last |
| `⇥` | switch pane |
| `f` | cycle the filter: mine · open → in flight → gate judgments → all |
| `p` | pause the feed, which holds lines and replays them |
| `r` | force a read now |
| `q` | quit |

## Flags

| | |
|---|---|
| `--no-peers` | do not start `peer-events.sh` |
| `--peer-interval=N` | seconds between synthetic events (default 7) |
| `--event-interval=N` | seconds between `read.sh events` polls (default 5) |
| `--snapshot-interval=N` | seconds between `read.sh snapshot` reads (default 60) |
| `--filter=F` | start on a filter, for captures that cannot press `f` |
| `--select=N` | start with row N selected |
| `--capture=N` | render with no keyboard, exit after N seconds |

## Layout

| Path | What |
|---|---|
| `schema/read-surface.schema.json` | the shape of `read.sh` output, written down |
| `src/read-surface/generated/` | types generated from that schema — `npm run types` |
| `src/read-surface/` | the shell-out client and a runtime walker of the same schema |
| `src/model/` | the status vocabulary, the brief view, the next action |
| `src/feed/` | the two event sources and the provenance union that marks them |
| `src/ui/` | Ink components and a pure reducer |

`npm test` runs 24 cases on the built output with `node:test`. No test framework is
installed. The runner is in Node.
