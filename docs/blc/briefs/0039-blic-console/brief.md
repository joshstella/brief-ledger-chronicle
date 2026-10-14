# The record nobody is watching while it changes

**Serial:** #0039 · **Created:** 2026-10-14T04:47:41Z · **Author:** josh.stella@gmail.com · **Depends on:** —

BLC writes a record and gives one cheap way to read it: `tools/orient.sh`, run by a person who
remembers to run it. Nothing watches the record. A contributor learns that a phase merged, a
serial was taken, or a declaration went stale by asking, and only if they think to ask.

This brief proposes BLIC, a console that sits in a terminal and answers two questions
continuously: **what is mine to do next**, and **what changed that I did not do**. It is the
interface half of the BLIC design proposal of 2026-10-13. The verb layer that proposal also
describes is a dependency of this one, not its subject.

## The finding

**Every gap the record has today is a gap in attention, not in format.** This repository's own
state is the evidence, and it is the strongest available because this repository is the one
that takes the convention most seriously.

- `tools/validate-briefs.sh` reports 16 judgments against 38 briefs. One of them is #0028:
  status `done`, no `**Closed:**` date. It has been reported on every run since it closed and
  it is still there, because the report goes to whoever happens to run the gate.
- `docs/blc/briefs/README.md:165` says a stale status line "is worse than no line, because a
  cheap scan trusts it and stops looking". It then asks a person to update the line and the
  table in the same edit. The warning and the mitigation are both prose.
- The project rules name the declaration window — work picked up and not yet filed — as
  "invisible to every ledger, and it is where two people pick the same serial". The fix on
  offer is a file each contributor remembers to write.
- `tools/list-briefs.sh:103` prints `planned` for a brief with no ledger. The five-state
  vocabulary in `docs/blc/briefs/README.md` does not have that state. A tool and a document
  disagree, and the disagreement has survived because nothing reads them together.

None of these is a hard problem. Each survives because the record is read in bursts, by one
person, after the fact.

## The claim

A console that reads the same records, derives nothing a human could not derive, and is
**running while the work happens** turns each of those from a thing you find into a thing you
are told. Two surfaces, both over the existing record:

- **Mine, next.** The open briefs where I am Owner or Author, with the phase that is actually
  in flight, and the next action that phase implies.
- **Theirs, new.** A push to the trunk, a phase that merged, a serial claimed, a declaration
  filed or cleared — reported when it happens rather than at the next orient.

## What this brief is not

- **It is not the verb layer.** The proposal's `blic <verb>` surface, the per-project binding
  file, and the record verbs that edit status lines are a separate argument with separate
  risks. The console needs a read surface, which this brief builds as an instrument and does
  not publish.
- **It is not a service.** BLC is bash and markdown and spread because of it. Anything that
  needs a daemon, a database or a login is out, and a prototype that needs one has answered
  the question by needing it.
- **It does not write the record.** This brief's console reads. A console that edits is the
  record verbs, and they come after something is known about the reading.

## Phase a is an experiment, not an implementation

The honest state of this brief is that **nobody knows what shape this should be**, and the
proposal's own open questions say so. A brief that answered them from the armchair would be a
brief written to look decided.

So phase a is a bake-off. Five prototypes run in parallel on isolated branches, over one
frozen read surface and one fixture — this repository's own 38 briefs, which already contain
the stale lines and the undated close named above. Each answers the same questions and none
merges to `main`.

| # | Tries | Settles |
|---|---|---|
| 1 | Bash and ANSI, no build step | Whether "no service, no build" survives a live view |
| 2 | Go and Bubble Tea, one static binary | The optional-download path at full fidelity |
| 3 | TypeScript and Ink, typed at the boundary | The cost of a toolchain against what it buys |
| 4 | No full-screen app: a watch loop and a next-action list | Whether this needs a screen at all |
| 5 | No new surface: the editor's own status line and hooks | Whether this belongs in a terminal |

Prototype 4 is the one that can end the others. It is the cheapest thing that satisfies the
claim, and if it is enough, the four interfaces are answered rather than ranked.

## The read surface is an instrument

The five prototypes share one frozen reader over the records, so they are compared on what
they show and not on whether they read the ledger correctly. It is throwaway by construction:
it lives on the bake-off branch, it has no tests, and nothing installs it. If a prototype
wins, the read surface it needs is built properly, with tests, before anything ships.

Stating this because the instrument is the easiest thing in this brief to mistake for the
deliverable.

## Settled before the bake-off

- **The console is read-only.** Decided above; it bounds every prototype.
- **The fixture is this repository.** Not a synthetic record. A prototype that looks good
  against invented briefs has proved nothing about 38 real ones with uneven ledgers.
- **No prototype merges to `main`.** They are evidence. The winner is rebuilt under the
  normal gates.
- **Each prototype files the same report.** Startup cost, dependency cost, what it does that
  the others cannot, what it cannot do, and the honest sentence about what it felt like to sit
  beside. Comparable reports or the bake-off produces five opinions.

## Open

- **Where notification lands.** Terminal output, a desktop notification, the shell prompt, or
  the editor. Prototype 5 exists because the answer may be "none of the terminal ones".
- **What counts as an event.** A push to the trunk is obvious. A branch appearing is less so,
  and a declaration edited is cheap to detect and may be noise. Polling interval is the same
  question wearing a different hat.
- **Whether "next action" is derivable.** `orient` reports state. The claim says the console
  reports the next action, which is a stronger thing, and the ledger may not carry enough to
  support it. A prototype that can only say "phase b is in progress" has found that out.
- **Two of the project's own rules conflict here and the conflict is not resolvable by
  argument.** The repository values bash and markdown with no build. The author's standing
  code rule is strongly typed with explicit interfaces at every boundary. A terminal
  application is the first thing BLC has proposed where both cannot hold. The bake-off is
  designed to price the conflict rather than to win it.
- **The design proposal's remaining questions** — the binding file's format, where team
  decisions live, whether the Contract moves to v1.6 or v2, and whether skills switch to verbs
  in one release — belong to the verb layer and are out of scope here. They are listed so the
  next reader knows they were seen and left.
