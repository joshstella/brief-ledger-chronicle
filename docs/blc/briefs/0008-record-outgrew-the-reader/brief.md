# The record outgrew the reader

**Serial:** #0008 · **Created:** 2026-09-08T01:55:00Z · **Author:** josh.stella@gmail.com · **Depends on:** #0006

## Ground

A new agent arriving at this repository has no cheap read. `start-brief` step 4,
`next-brief-phase` step 5, and `review-pr` step 3 all instruct it to read `AGENTS.md`.
That file does not exist here. The installer writes a stub into every *target* project
and the toolkit that ships it has none, so the orientation step those three skills run
resolves to nothing.

What exists instead is 34,147 tokens of briefs and ledgers. No agent reads that, so it
does the other thing: it re-derives what was already settled. That is visible in the
record. #0005 re-records #0003's concurrency decision — *"#0003 settled this and it is
not reopened"* — and restates #0004's boundary decision almost verbatim. Those
sentences exist because the agent writing #0005 had to rediscover them.

The repository is not short of documentation. It is short of a **cheapest rung**.

## The claim

**Orientation ships as a verb. A command, not a document.**

One tool emits roughly 700 tokens answering three questions: what is in flight, what
must not be broken, and what this project values.

**Output is never committed. Inputs are committed, and every input has exactly one
writer.** That split is what makes the whole thing conflict-free. There is no generated
file to merge or clobber, and no input two contributors write at once — the same
partition #0005 used for ledgers, applied to every source.

| part | produced by | one writer per | staleness |
|---|---|---|---|
| what is in flight — landed | derived from git and the ledgers | brief | impossible |
| what is in flight — intended | declared in `docs/state/<contributor>.md` | contributor | real, self-pruning |
| what is off-limits | derived from the installer's ownership map and the Contract | — | impossible |
| what is desirable, and the architecture | assembled from one authored file, size-capped | repo | real, bounded |

Four sources, three mechanisms — derived, declared, authored. Attempting one mechanism
for all of them is what stalled this design twice.

The declared row exists because the derived one structurally cannot reach it. A ledger
begins at `start-brief`, which runs *after* `create-brief` has already chosen a serial.
Intent that has no brief yet is in no record, and that is exactly the window where two
contributors collide.

## Evidence

**1. The resolution ladder already exists and is regular.** Every rung costs between
1,000 and 3,000 tokens, because the aperture narrows as detail rises: rung 3 is fine
detail about *one* brief, not fine detail about everything.

| rung | artifact | ~tokens |
|---|---|---|
| 1 — what / why | `README.md` · `Manifesto.md` | 1,677 · 2,538 |
| 2 — how a surface works | `docs/briefs/README.md` · `docs/contracts/README.md` | 2,947 · 1,048 |
| 3 — one unit of work | one brief · one ledger, median | 1,993 · 1,578 |

Rung 0 is the missing one, and it is the only rung a reader needs before knowing which
of the others to open.

**2. Rung 0 fits the budget, measured where it can be.** The current-state table that
`gather.sh` emits today is **243 tokens** for all seven briefs. The other two parts are
estimated at ~200 and ~250, which is a claim this brief has not verified.

**3. Promotion by discipline fails, at a measured rate.** Fourteen standing decisions
sampled against the orientation documents: six reached them, eight did not. Everything
promoted came from a brief that was *about* conventions — #0003 defining the Contract,
#0005 defining ownership. Principles discovered incidentally stayed buried, including
"a skill guard is not a check" and "the chronicle is not the record." The Manifesto
predicted this: *"The tie to the code has to be structural. Discipline will fail the
way hand-synced documents have always failed."* 43% is that failure, measured.

**4. Mechanical extraction alone is not enough, also measured.** Extracting decision
sections wholesale gives 2.1x. The good cut — `## Settled decisions` from briefs only —
gives 11.7x at 2,906 tokens, but roughly half of it is implementation detail already
baked into code, because a script cannot tell a live constraint from a historical one.
That extract is rung 2 material, read deliberately. It is not rung 0.

**5. `open-briefs.sh` does not already do this.** It emits 41 tokens and speaks only
about exceptions — currently that `#0007` has no ledger. It answers "what needs
attention," not "what is the state." Complementary.

**6. Doctrine already has the slot, and verbs already ship.** The Manifesto: *"Some
tools report, some tools gate, and the difference is named. `chronicle` and
`open-briefs.sh` observe."* A new observer needs no amendment. `install.sh` already
ships `tools/validate-briefs.sh` and `tools/open-briefs.sh` into every target.

**7. The declaration file closes a race the Contract documents as open.** Contract v1.1:
*"`create-brief` does not publish the serial, so two checkouts can fetch the same
`origin/main` and still pick the same next number. Closing it for real means publishing
a reservation before the other reader runs — a push at filing time. This project does
not do that."* A per-contributor file, pushed when work is picked up, is that
reservation. It is also the only answer available to the case the discarded
`wip-visibility` draft named: *"Visible to nobody. A local uncommitted change, a
decision someone has made but not written down, a refactor that exists as an intention.
No amount of tooling reaches this."* Tooling still cannot reach it. A cheap place to
declare it converts "ask every peer" into "read a directory."

**8. Every noun formulation required a doctrine change; the verb requires none.**
Considered and discarded during drafting: redefining a Contract to be agent-authored
and non-gating (rewrites the Manifesto's Contract section, orphans BRIEFS-1 through
BRIEFS-8, and removes "publishing is the act that makes breaking it a crisis"); a
generated `AGENTS.md` (mixes authored and generated content in one project-owned file,
and every contributor regenerates the same path); a committed digest (merge conflicts
on a file where hand-resolution is meaningless, with no `.gitattributes` in the repo to
govern it). The verb formulation makes all three questions not arise.

## Change

Five phases. The layering has to be settled before anything is written, because the
current-state table is presently inside a skill and the verb belongs beside the other
tools. The declaration convention comes before the verb that aggregates it.

| Phase | Work |
|---|---|
| `a — the layering` | The table comes from `skills/chronicle/scripts/gather.sh`; the verb belongs in `tools/`. Today both tools are standalone and nothing in `tools/` reaches into a skill. Settle the direction — move the table logic down to `tools/` and have `gather.sh` call it, or accept the new coupling — then make the move. No new behaviour. |
| `b — the declaration` | The `docs/state/` convention: one file per contributor, named from `git config user.email` under a stated normalization rule. It holds only what cannot be derived — work picked up but not yet filed, and a serial about to be claimed. Not a status report, not a standup, not recurring. Written when work is picked up, emptied when it lands. |
| `c — the verb` | The tool itself. Emits the parts. Landed state from the ledgers and git; intended state aggregated from `docs/state/`; off-limits from the installer's ownership classes and the Contract clauses; desirable and architecture read from the authored file. Exits zero and says so when a source is absent, so it works in a project with no briefs and no declarations. |
| `d — the check` | Tests: output is deterministic across two runs with no repo change; each part degrades to a stated absence rather than an error; total stays under the budget; two contributors' declaration files never touch the same path; it runs clean in a fixture project with an empty `docs/briefs/` and no `docs/state/`. This is a script, so unlike a skill it can actually be asserted. |
| `e — the read` | Point `start-brief` step 4, `next-brief-phase` step 5, and `review-pr` step 3 at the command. Have `create-brief` write the declaration when a serial is claimed, and clear it at filing. This is a skill guard, not a check — see the Tension. |

## Tension

**The last phase cannot be tested.** Phases `a` through `c` produce a script the suite
can assert. Phase `d` is an instruction to an agent, and *"a skill guard is not a
check"* — a buried decision from #0006 that this brief is relying on. A verb nothing
runs is exactly as useless as a document nothing reads, and the mechanism that makes it
run is the untestable part.

**Two thirds of the size claim is unverified.** 243 tokens for current state is
measured. The ~200 for off-limits and ~250 for desirable are estimates. If the real
figure is 1,500, rung 0 stops being cheaper than rung 1 and the premise fails.

**The authored third still decays.** A size cap makes curation self-enforcing — a ninth
principle means arguing one of eight out — but a cap governs quantity, not quality.
Nothing here guarantees the eight are the right eight.

**"What is in flight" is only as true as the checkout.** The verb derives state from
local refs, so on a stale clone it reports confidently and wrongly. The concrete case is
on the record: during #0003, three merged PRs and two deleted branches were invisible to
a second machine until `git fetch --prune` ran. Declarations make this worse, not
better — they are pushed by someone else, so reading them on a stale clone misses
exactly the work they exist to reveal. Either the verb refuses to answer on a stale
checkout or it stamps its output with how old the refs are. Neither is in this brief.

**A declaration nobody writes is invisible, and writing it benefits other people.**
That is the worst possible incentive shape, and this repository has already measured
what happens to maintenance that helps someone else: 43%. Two things blunt it — the
declaration is event-triggered rather than maintained, and phase `e` has `create-brief`
write it automatically at the moment a serial is claimed. Neither covers the case that
motivated it: work someone is thinking about but has not started. That case remains
unreachable, as the discarded `wip-visibility` draft correctly said it would.

**Stale declarations have no pruner.** A contributor who leaves holds a file claiming
in-flight work indefinitely. `open-briefs.sh` detects branches that no longer exist, so
the pattern for catching this exists, but nothing in this brief applies it.

**The state section does not scale, and this repository is too small to reveal it.**
243 tokens covers seven briefs — about 35 each. Two hundred briefs is 7,000 tokens
against a rung-0 budget of 700. So rung 0 cannot paste the full table; it must filter to
open and recent work. That collides with #0006, which settled that the chronicle table
stays complete on every run. One generator, two consumers, two filtering rules — and the
filtering rule for rung 0 is not designed here.

**This repository is the worst available test of the premise.** The whole record is
62,000 tokens. The problem this brief describes is a repository where orientation costs
hundreds of thousands, and a 700-token rung 0 saves perhaps 9,000 here. The ratio is
real but the absolute number is small enough that the design could be wrong in ways
nothing local will surface. Cobbler's shoes: the toolkit is being fitted on the one
codebase where the pain barely exists. Treat the first application to a large unrelated
repository as the actual test, and expect the filtering rule above to be what breaks.

**Declarations scale with people, and rungs must not.** Twenty contributors is twenty
files. The verb aggregating them into a few lines is what preserves the flat rung cost,
so `docs/state/` is a *source* and never something a reader opens directly. If anyone
starts reading the directory, the rung property is already broken.

**Deriving off-limits couples the verb to the installer.** Ownership classes live in
`install.sh` as comments and ship lists. A verb that reads them is coupled to a file
that exists to be edited by `installer-builder`. Restating them instead is the drift
this brief argues against.

## Settled decisions

Resolved 2026-09-07 during drafting.

- **Orientation is a verb, not a document.** The capability ships; the content is local
  and derived. This is the decision every other one below follows from.
- **Output is never committed; every input has exactly one writer.** This is the whole
  conflict story. Generated output has nothing to merge. Inputs are partitioned — a
  ledger per brief, a declaration per contributor, one authored file per repo — which is
  #0005's *"one owner, one narrative"* applied past the ledger.
- **Three mechanisms: derived, declared, authored.** Attempting one mechanism for all
  of them is what stalled this design twice.
- **Declarations hold only what cannot be derived.** Work picked up but not yet filed,
  and a serial about to be claimed. Anything computable from the record is computed,
  because derived beats declared wherever both are possible.
- **`wip-visibility` is dropped, not deferred.** Its git-visible half is `open-briefs.sh`
  plus this verb. Its peer-poll half was triggered by publishing a Contract version —
  an event that has happened once, and that #0009 chose to avoid repeating by rewording
  v1.1 in place. Its one durable contribution, that some work is reachable by no tooling
  at all, is carried into the Tension above.
- **The authored part is capped.** A fixed token budget, enforced, so growth forces
  triage rather than accretion.
- **The Contract is not redefined and not touched.** Redefining it to be agent-authored
  and advisory was taken seriously and rejected: it orphans the only working Contract,
  which has a genuine external consumer in every install target.
- **Promotion-by-convention is rejected as the primary mechanism.** Measured at 43%
  over seven briefs, against a Manifesto that already says discipline fails.
- **`chronicle.md`'s merge conflict is a separate problem.** It is synthesized prose,
  deliberately committed by #0006, and expensive to regenerate. The verb framing does
  not rescue it. It needs its own answer.

## Open decisions

1. **Where does the current-state table live?** `tools/` with `gather.sh` calling it, or
   left in the skill with the verb reaching in. Blocks phase `a`.
2. **What is the tool called?** Existing names are `<verb>-<noun>.sh`. Blocks phase `b`.
3. **Where does the authored file live** — a section of `AGENTS.md`, or its own file?
   `AGENTS.md` is project-owned and never clobbered, which suits it, but it is also the
   file a team fills with stack and build notes. Blocks phase `b`.
4. **What is the budget number?** ~250 tokens is this draft's guess. Blocks phase `c`,
   since the test asserts it.
5. **Does the verb ship to targets?** Both existing tools do. Downstream is where
   contributor count is highest and orientation cost is worst, which argues yes.
6. **How is a contributor filename normalized?** `git config user.email` is the source,
   matching how #0007 defaults its assignments query, but `@` and `.` in a path need a
   stated rule that survives a case-insensitive filesystem and an address change.
   Blocks phase `b`.
7. **What prunes an abandoned declaration?** Nothing here does. Options are an age
   stamp the verb reports on, or a `open-briefs.sh`-style check that the named branch
   still exists. Blocks phase `b`.

## Non-goals

- **Not a gate.** It reports. It never blocks.
- **Not a Contract change.** No clause, no version, no redefinition.
- **Not a committed artifact.** If it ends up committed, the design has failed.
- **Not the chronicle merge problem.** Named in settled decisions, handled elsewhere.
- **Not a status report, not a standup, and not recurring.** A declaration is written
  when work is picked up and cleared when it lands. It answers one question and is not
  a place to report progress.
- **Not a peer poll.** No message is generated for humans to send. That was
  `wip-visibility`'s proposal and it is dropped with it.
- **Not a replacement for the record.** Briefs, ledgers, and git remain the truth. This
  is an index over them and is allowed to be lossy.

## Success criteria

- One command answers, for the repository it is run in: what is in flight, what must
  not be broken, what this project values.
- Total output stays under the budget, and a test asserts it.
- Two runs with no repository change produce identical output.
- It runs clean in a project with an empty `docs/briefs/`, reporting absence rather
  than failing.
- Nothing it produces is written to a tracked file.
- Two contributors working simultaneously never write the same path — not a ledger, not
  a declaration, not the output.
- A serial claimed but not yet filed is visible to a peer who has fetched.
- `start-brief`, `next-brief-phase`, and `review-pr` name it where they currently name
  `AGENTS.md`.
- A fresh agent that runs it can name the open brief and the surfaces it must not edit
  without reading any ledger.
