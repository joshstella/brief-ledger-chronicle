# The #0039 bake-off

Five prototypes of a BLC console, built in parallel, compared on one fixture.

Read `docs/blc/briefs/0039-blic-console/brief.md` first. It holds the claim and the
constraints. This file holds only what a prototype needs to start.

## The rules

- **Nothing here merges to `main`.** These are evidence. The winner is rebuilt under the
  normal gates.
- **The read surface is frozen.** `read.sh` is shared by all five. Do not change it. If it is
  wrong, say so in your report and work around it — a prototype that edits the instrument is
  being compared against a different instrument than the other four.
- **Read-only.** No prototype writes a record, pushes, or calls a forge.
- **No daemon, no database, no login.** A prototype that needs one has answered the brief's
  question by needing it, and should say so rather than build it.

## The instrument

```
./read.sh snapshot            everything, one JSON document
./read.sh briefs              briefs only
./read.sh events [--since X]  record events, newest first (X: a git revision or a date)
./read.sh declarations        who has claimed unfiled work
./read.sh defects             the gate's own output, parsed
./read.sh me                  the current git identity
```

Every brief carries `mine`, computed the way this repository computes it: `Owner`, or
`Author` when there is no `Owner`. Every phase carries its id, label, state and pointer.
Every event carries `who`, `mine` and a `kind` — `phase`, `close`, `filed`, `declaration`,
`record` or `code`.

## The fixture, and the one thing it cannot show

The fixture is this repository: 39 briefs, real ledgers, uneven across three years of
conventions. It contains, right now, things a console should surface on open — sixteen
`BRIEFS-11` judgments, including briefs marked `done` that carry no `Closed` date.

**It has one author.** Every real event is `"mine": true`, so the half of the brief that
matters most — what changed that I did not do — has no real data behind it. Use
`./peer-events.sh` for that. Every line it prints carries `"synthetic": true`, and a console
that shows a synthetic event without marking it is lying about the record.

`./peer-events.sh --stream` prints one every few seconds, for a live view.

## What your report must answer

Write it to `REPORT.md` in your prototype's directory. Same questions, same order, so five
reports can be read as one table rather than five opinions.

1. **What it is.** Stack, dependency list, how a person starts it.
2. **Startup cost.** Time from a cold checkout to a running console, including any install.
   Measure it; do not estimate it.
3. **Dependency cost.** What a user must already have. What breaks without it.
4. **Size.** Lines of code you wrote, excluding dependencies.
5. **What it does that the others cannot.** Be specific and be honest if the answer is
   nothing.
6. **What it cannot do.** The limits you hit, not the features you ran out of time for.
   Separate those two.
7. **What it was like to sit beside.** One paragraph, first person. The brief is about a
   thing that runs while you work, and this is the only question that gets at that.
8. **What you would throw away.** If this won, what part of it is wrong.
