# Ledger — #0004 The ledger is an archive and a bad inbox

**Brief:** `docs/briefs/0004-deferral-surfacing/brief.md`
**Status:** in-progress
**Date:** 2026-08-24

## Phase sequence

| id | status | what it does |
|---|---|---|
| `phase 1 — the limitation entry` | in-progress (`brief/0004-phase-1-limitation-entry`, PR#15) | Add the third entry to Known limitations in `docs/briefs/README.md`, as an incident report with the dated case, matching "writers outside the pipeline". State the hole; do not propose the mechanism. |
| `phase 2 — reconcile ledger status` | pending | Not invent a vocabulary — one exists and is ignored. Give the states one home, adopt `pending` / `in-progress` / `deferred` / `done` / `skipped` with durable pointers and reasons, and reconcile the four existing ledgers, top-level status included. Add the compressed `blc/1` status line under each ledger title, and an index atop any Big decisions section that warrants one — #0003's is 246 lines. Prerequisite for any query. |
| `phase 3 — the open-briefs query` | pending | Answer "which briefs are open?". Interrogate each `in-progress` branch — does it exist, is there a PR, how far has `main` moved — and report any ledger whose status line disagrees with its phase table. Reports; gates nothing. Shape depends on phase 2's vocabulary. |

Scope was settled on 2026-08-24 by amending the brief — see Big decisions. Phases 2 and 3
were `proposed` until then, which is no longer a state.

No cadence phase is planned. It is open decision 1, still unresolved on the threshold, and
per the brief's own sequence it is an optimisation on top of phase 3 rather than a
replacement for it.

## Dependency structure

- **Phase 1 comes first by the repo's ordering rule, not by technical dependency.** This
  project runs prose, then clause, then check, one direction. Phase 1 is the prose. Nothing
  in phases 2 or 3 needs it to have landed, but landing them first would invert the ordering
  that #0003 established.
- **Strict chain: `phase 2 → phase 3`.** A query cannot be written before "open" is defined.
- **Provisional past phase 2.** Phase 3's shape follows the vocabulary decision. If phase 2
  concludes that status should be derived rather than declared — from merged PRs, or from
  whether every phase row is closed — phase 3 is a different piece of work and
  `/next-brief-phase` re-plans it.

## Open decisions

Carried from the brief, with what each blocks.

| # | decision | blocks |
|---|---|---|
| 1 | Where surfacing happens. Leading candidate: commits landed on `main` since a ledger last changed, gated on a non-empty result. Still open inside it — threshold, or show whenever non-empty | any cadence phase — not planned here |
| 2 | Where the cadence signal comes from, and which cost it pays. **Merged with the former decision 3** — see Big decisions | any cadence phase |
| 3 | ~~Whether this can be reliable inside a prompt document~~ | **resolved** — best effort is enough, and must be documented as such. See Big decisions |
| 4 | ~~Whether ledger status is declared or derived~~ | **resolved** — declared. See Big decisions |

## Complications found in the code, not addressed by the brief

1. **"Open" is undefined, and the vocabulary has already drifted.**

   **Corrected 2026-08-24, and the correction inverts it.** First recorded as no document
   defining the allowed set, so neither spelling was wrong. That was wrong: the set *is*
   declared. `skills/start-brief/SKILL.md` stamps `initiated` and names phase statuses
   `pending` / `in-progress` / `done` / `skipped`; `skills/next-brief-phase/SKILL.md:38-40`
   moves a phase to `done`, the next to `in-progress`, and the ledger to `completed`.

   So `**Status:** complete` on #0003 is a violation of a rule that exists, not a gap. And of
   the four declared phase statuses only `pending` appears in any ledger — `done` is never
   used once, while practice invented `complete (PR #9)`, `proposed`, `dropped` and `folded
   into phase 2`.

   The correction matters more than the defect. Four invented values are not sloppiness; they
   are evidence that the declared set was insufficient, and each names something the four
   could not say. Phase 2 is therefore reconciliation, not invention, and the declared set is
   the thing that must justify itself.

   Two further points, both load-bearing for phase 2. The spec is split across two skills with
   no single home, which is this repo's own recurring failure. And **there is no declared
   `deferred` state** — the incident this brief exists for was a deferred phase inside a brief
   that stayed `in-progress`, so the current vocabulary cannot express what happened.

2. **Nothing in the toolkit reads ledger status.** `skills/chronicle/scripts/gather.sh:45`
   is the closest thing and decides `planned` versus `executed` on whether `ledger.md`
   exists. It never opens the status line. The query is unbuilt, not half-built.

3. **Contract v1 does not contain the word `ledger`.** Every clause governs folder shape,
   serials, the identity line, dependencies, draft naming and contiguity. A rule about
   ledger status is a new namespace, which means Contract v2 and the first real exercise of
   the supersession design. That is a large bill for a small rule and phase 2 should decide
   whether to pay it.

4. **Deferred phases name branches in prose.** Nothing resolves the name, so a query that
   wants branch health has to parse English. The brief already records that deleting the
   branch leaves the ledger pointing at nothing.

   **Addressed 2026-08-24** by the durable pointer on `in-progress`, `deferred` and `done`.
   A PR number or commit SHA is resolvable and survives branch deletion. Recorded as
   addressed rather than struck, because the prose branch names in existing ledgers are still
   there and phase 2 has to reconcile them.

5. **This brief is now an instance of itself.** Filing #0004 set a ledger to `initiated`.
   If it stalls, it becomes the thing it describes, and the only mechanism that would
   surface it is the one it exists to specify. Recorded as a live self-test rather than a
   joke: if nobody notices this brief going stale, that is the strongest possible evidence
   for the hole, and the weakest possible position from which to argue it does not matter.

6. **A brief can exist on disk and not in git, and the query would call it healthy.** Found
   2026-08-24 by checking repository state: this brief and its 313-line ledger sat entirely
   untracked for the whole session in which its own surfacing mechanism was designed. A
   filesystem scan finds such a brief. A git-derived staleness signal cannot — no branch, no
   PR, no commits, therefore nothing to measure and nothing to report. It reads as perfectly
   healthy precisely because it is least protected. Phase 3 has to decide what it says about
   a brief git has never seen; the honest answer is probably that untracked is its own
   finding, not an absence of one.

## Branches

| branch | carries | state |
|---|---|---|
| `brief/0004-deferral-surfacing` | the brief and this ledger; no phase work | merged, PR #14 |
| `brief/0004-phase-1-limitation-entry` | phase 1, the Known limitations entry | open, PR #15 |

**This ledger uses the vocabulary the brief settles, ahead of phase 2 landing it elsewhere.**
Deliberate. The states are decided in `brief.md`, and a ledger that argues for a vocabulary
while using a different one would be the exact defect this brief documents. The other three
ledgers stay inconsistent until phase 2 reconciles them.

## Big decisions

This section is two thirds of the ledger, so it opens with its own contents. Entries are in
file order, which is not chronological — later decisions were inserted beside the ones they
revise, so that a superseded position and its correction read together.

1. A compressed status line, and why the redundancy is accepted
2. The phase vocabulary, and the state that was missing
3. Corrected within the hour: acknowledgement does not buy silence
4. The durable pointer solves complication 4 for free, and nearly broke a rule doing it
5. Scope amended: three phases, not one
6. Best effort is enough, and must be labelled as such
7. Ledger states are declared, and the declaration already exists
8. Two open decisions turned out to be one, and listing them apart hid the trade
9. A 72-hour debounce, which is a different question from staleness
10. The cadence signal is derived from git, not stored

**A compressed status line, and why the redundancy is accepted.** 2026-08-24.

Measured before deciding, because the stated problem was not the real one. Status is already
at the top of all four ledgers — line 3 or 4, before anything else — so the obvious fix was
already in place and scanning was still expensive. #0003 costs 2,337 bytes to reach the end
of its phase table and carries about 150 bytes of status: roughly fifteen times its own
content. Position was never the cause. **Status and prose share a line**, and a markdown
table row is atomic to `head`, to `rg`, and to an agent reading a chunk, so the 398-character
description in the widest row is unavoidable overhead on the word beside it.

Two designs were considered. Narrowing the phase table to id, status and pointer, with
descriptions moved below, avoids all redundancy — but it requires rewriting every ledger's
table, including normalising #0002's five-column shape against #0003 and #0004's three-column
one and inventing a table for #0001, which has none.

The compressed line was chosen instead, and the deciding argument was not token count. **A
fixed-position line makes the three inconsistent table schemas irrelevant to any scanner,
with no migration.** The schemas stay inconsistent and stop mattering. About 60 bytes against
2,337 for #0003, a fortyfold reduction, is the smaller benefit.

`blc/1` is a schema version. Cheap to add now, impossible to retrofit once readers exist.

Visible rather than an HTML comment. Both can go stale; only the visible one can be noticed
going stale by whoever is editing the ledger. Invisible stale data has no natural correction.

**The redundancy is a real cost and is accepted with a guard.** The line restates the phase
table, so the two can disagree. The danger is not disagreement itself but that **a stale line
is worse than no line** — a cheap scan trusts it and stops looking. This is the same argument
recorded above under best effort: a signal believed reliable stops people checking by hand. It
bites harder here, because a ledger whose table says `deferred` and whose line says `done`
hides exactly the incident that produced this brief. Phase 3's query therefore reports
disagreement between the two. It is already opening every ledger, so the cost is close to
nothing, and it reports rather than gates, so the ordering rule holds.

**The phase vocabulary, and the state that was missing.** 2026-08-24.

`pending`, `in-progress`, `deferred`, `done`, `skipped`. `in-progress`, `deferred` and `done`
carry a durable pointer. `deferred` and `skipped` carry a reason.

`done` won the terminal slot because `start-brief` and `next-brief-phase` already declare it,
so the skills need no change and the two ledgers reading `completed` plus the one reading
`complete` are the things that move. Naming is arbitrary; matching the existing declaration is
not, and picking either of the other two would have edited the spec to match the drift.

`proposed` is dropped. A phase nobody has committed to belongs in a draft, not in a ledger.

**`deferred` is the finding, and it survived being nearly designed away.** It was not in the
declared set, and it only became visible once `in-progress` was first defined as requiring a
PR: a phase parked on a pushed branch with no PR then had no name at all. Not `pending`,
because real work happened. Not `in-progress`, because nothing was progressing. That unnamed
gap is the exact shape of the incident — branch pushed, "no PR", parked, 57 days.

**Amended the same day: `in-progress` now means any branch exists, and names it.** That
closes the gap that motivated `deferred` and, taken alone, puts the incident's phase back to
`in-progress` — which is what the real ledger said while nothing surfaced it for 57 days. The
amendment was kept anyway, for a reason that outweighs the loss.

**Naming the branch makes `in-progress` the only interrogable state.** Whether the branch
still exists, whether a PR was ever opened, how far `main` has moved since — all answerable
from the repository. That is staleness *derived* rather than *declared*, and it is the
stronger instrument, because the incident's failure was precisely that nobody marked anything.
A declared `deferred` only helps when someone remembers to declare it, which is the assumption
that already failed once.

`deferred` is therefore redefined rather than dropped, and the two stop competing because they
answer different questions. `in-progress` is a fact about artifacts: a branch exists.
`deferred` is a fact about intent: someone looked and parked it, with a reason.

**Corrected within the hour: acknowledgement does not buy silence.** 2026-08-24.

The redefinition above was first written with `deferred` listed "without alarm", reserving the
raise for `in-progress`. Tested against the evidence, that is wrong, and wrong in the way that
matters most.

Check the incident against the definition. The ledger named the branch, said "pushed, no PR",
gave the rationale, listed three blocking issues and specified the resume path. That is the
best-documented deferral in the corpus, so an honest author marks it `deferred` — and the
vocabulary written to catch this incident sorts the incident itself into the quiet bucket.

It also contradicts this brief's first settled decision, which insists the deferral was
recorded correctly and no rule was broken. **If correct recording earns silence, the finding
is inverted.** Nothing about a good rationale made 248 commits land more gently.

So decay is measured for `deferred` exactly as for `in-progress`. Acknowledgement lowers the
initial noise; it does not exempt. **An acknowledgement has a shelf life**, and 248 commits
outlives any. The settled decision that a known boundary is a legitimate resting place still
holds — resting is permitted, and the branch rotting underneath it is still reported.

**Both states fit a parked branch, so the tie is broken by rule**, not judgment: if a reason
was given, it is `deferred`. The first draft left it to the author, which invites the choice
being made by mood on the day. With decay measured either way, the rule costs nothing.

**What this vocabulary would and would not have caught.** Recorded because the question was
asked directly and the honest answer is only half a yes.

The signal fires: branch named, therefore resolvable; no PR; 248 commits on `main`. Loud at
any threshold. But **nothing would have run it.** The query surfaced this in reality because a
human asked in an unrelated session. Fifty-seven days of a query existing and never being
invoked is the same fifty-seven days. That is open decision 1, still unresolved, and it is the
reason the cadence question cannot be quietly dropped as an optimisation.

**The durable pointer solves complication 4 for free, and nearly broke a rule doing it.**
2026-08-24.

`(PR N)` on a status makes the record resolvable where a branch name in prose is not, and it
survives branch deletion. That is candidate fix 2, arriving as a side effect of deciding the
vocabulary rather than as work of its own, so the candidate is struck from the brief.

The later amendment adds the branch name beside it on `in-progress` and `deferred`. That does
not reintroduce the complication, which was about branches named *in prose* that nothing can
resolve. A branch in a fixed position in the status field is structured, and it is what lets
the query ask whether the branch still exists rather than parse English to find its name.

But requiring a PR number makes a forge mandatory for a valid status, and this project's rule
is that external tools are optional artifacts to piggyback on, with no integration
load-bearing. `(commit abc1234)` is therefore allowed in its place. The cost is a compound
status field that any future parser must handle; the alternative was a vocabulary that cannot
be used without GitHub.

**Scope amended: three phases, not one.** 2026-08-24. Changes a settled decision, so it is
recorded rather than edited quietly.

The brief was filed saying **prose only**, which made it a one-phase brief — the limitation
entry and nothing else. It now covers the status vocabulary and the query.

The trigger was mundane: dropping `proposed` left phases 2 and 3 of this ledger with no legal
status, which forced the question that had been dodged three times. Either they were real
phases or they were not in the ledger.

The chain constraint survives and was checked rather than assumed. This repo runs prose, then
clause, then check. Phase 1 is the prose. Phase 2's vocabulary is also prose. Phase 3 is a
query that reports and gates nothing, so it is not a check in the sense the constraint means.
No Contract clause and no enforcing check lands in any of the three, and that remains
forbidden here.

**Best effort is enough, and must be labelled as such.** 2026-08-24. Resolves open decision 3.

The cadence lives in markdown read by an agent, so it cannot be guaranteed. It does not need
to be. Surfacing a stalled brief most of the time is an enormous improvement over never, and
the alternative — holding out for a mechanism that runs — is what keeps this hole open while
the perfect version is not built. Going git-derived already reduced the cost of a missed run
from a corrupted cadence to one missed prompt.

The condition is not decoration. **It must be documented as best effort wherever it appears.**
A mechanism sold as dependable and delivered as occasional is overclaiming, which this project
treats as the primary defect class, and it is worse here than elsewhere: a reminder people
believe is reliable stops them checking by hand, so an unreliable-but-trusted prompt could
leave them worse off than no prompt. Saying "this may miss" costs one sentence.

**Ledger states are declared, and the declaration already exists.** 2026-08-24. Resolves open
decision 4.

Declared beats derived for the ordinary reason: a reader should see a status rather than
reconstruct one, and derivation would have to infer intent — a brief with every phase merged
might be complete, or might be waiting on something no commit records.

The decision was easy. Acting on it turned up the real finding, recorded as a correction to
complication 1: the vocabulary is not missing. It is declared across `start-brief` and
`next-brief-phase`, and practice ignores it. `**Status:** complete` on #0003 breaks a stated
rule. Only `pending` of the four declared phase statuses is used anywhere, `done` never
appears, and four values were invented instead — `complete (PR #N)`, `proposed`, `dropped`,
`folded into phase 2`.

That reframes phase 2 from inventing a vocabulary to reconciling one, and shifts the burden:
the invented values are the evidence, and the declared set is what has to justify itself.
Chief among the gaps, **no declared state means deferred.** The incident that produced this
brief was a deferred phase inside a brief that stayed `in-progress` — so today's vocabulary
literally cannot say what went wrong, which is a fair part of why nothing surfaced it.

**Two open decisions turned out to be one, and listing them apart hid the trade.** 2026-08-24.

The brief carried "where does the counter live" and "what is the age threshold" as separate
questions. They are the same question from two sides. **A counter of invocations avoids a
threshold and pays with stored state. A time interval avoids stored state and pays with a
threshold.** Neither escapes both.

That went unnoticed for as long as both were open, because each looked solvable on its own
terms. It surfaced only when a proposal to swap the counter for an hour interval made the
two costs trade against each other in one move. Recorded because the failure was in the
*shape* of the decision list, not in either decision — a ledger can hide a trade simply by
numbering its halves separately.

**A 72-hour debounce, which is a different question from staleness.** 2026-08-24.

Prompt at most once per 72 hours. This does not touch the staleness measure, which stays
commit-based per the entry below — 72 hours governs how often you are interrupted, not when a
branch counts as rotten. The two were briefly at risk of being conflated, and separating them
is what makes the number harmless: as a staleness threshold, 72 hours would have fired around
nineteen times across the Syzygy deferral while the branch was still cheap to merge, teaching
dismissal long before the prompt meant anything.

**It survives the objection that killed machine-local state**, and the reason is worth
keeping. Machine-local state was rejected below because a counter that does not travel gives
one person two different cadences. A debounce that does not travel gives one person a prompt
per machine per 72 hours, which costs an occasional duplicate and breaks nothing. The
objection was specific to counters and does not generalise. An untracked file under `.git/`
therefore serves: no repo noise, no merge conflicts, nothing shared between people.

What stays open is the commit threshold — how much divergence earns a mention at all.

**The cadence signal is derived from git, not stored.** 2026-08-24. Commits landed on `main`
since a ledger last changed.

Three homes were rejected first. In-repo state is a file changing on every command: git
noise, merge conflicts, and a counter shared across people, so one author's activity prompts
another about work they were not doing. Machine-local state does not travel, so one person on
two machines carries two counters — the invisibility `_drafts/wip-visibility.md` already
documents. A wall-clock hour modulus is genuinely stateless, which is its real attraction and
the reason it was considered seriously, but it fires on the clock rather than on the work:
every invocation inside a qualifying hour prompts, and some working hours never qualify at
all, so it silently never fires for those schedules and offers no signal that it is not
firing. A mechanism whose failure mode is undetectable silence is the wrong one for a hole
whose entire nature is undetectable silence.

Git-derived wins by making an existing store do the work, and by keeping the property the
original counter proposal got right: **activity is what rots a branch, not the calendar.**
The deferred branch cost what it cost because 248 commits landed on top of it, not because 57
days passed. A commit count preserves that; hours discard it. It also moves the signal from a
property of the user to a property of the stalled thing, so the prompt fires when a specific
ledger is rotting rather than on a rota.

The cost accepted, stated rather than buried: this route does **not** dissolve the threshold.
It relocates it into units that track decay. Deciding the number is still owed.

## Notes

- The counter proposal and its replacement both arrived after the brief was drafted. The
  candidates live in the brief's open decision 1; the reasoning that chose between them lives
  here, per the split this repo already uses.
