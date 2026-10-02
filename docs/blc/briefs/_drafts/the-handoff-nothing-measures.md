# The handoff nothing measures

**Created:** 2026-09-29T11:05:00Z · **Author:** josh.stella@gmail.com
**Depends on:** —

> **Source and limits.** This draft reports one handoff experiment run on 2026-09-28 in a
> partner's private codebase. The partner's documents are proprietary, so this draft carries
> the mechanisms and the numbers, and none of their names, services, or answers. Every number
> below comes from that experiment's friction log or from the partner's own preparation notes,
> which the newcomer received after finishing. One experiment is one data point.

## Ground

BLC already supports a brief that someone else executes. `docs/blc/briefs/README.md`, "Ledger
status": *"A team member is given the brief. That person runs `blc-start-brief` and the later
phases."* `Author` is who filed. The owner is who executes. Those are different people by
design.

What BLC does not do is **measure the handover itself**. When a brief moves from the person who
knows the code to a person who does not, three questions matter, and BLC records none of them:

1. **What did the handover cost the owner?** Where they got stuck, for how long, who they had
   to ask, and what they guessed.
2. **What did the author fix before handing over?** Every obstacle the author removed is an
   obstacle the owner will never report, so the owner's number reads low by exactly that much.
3. **Was the brief ready to hand over?** Named reviewer, landing branch, a start procedure that
   somebody actually ran.

The ledger answers a different question: *what did the work teach, including where the brief
was wrong.* That overlaps with question 1 for content findings. It does not cover cost, asks,
guesses, or readiness.

### The experiment

A platform team wanted to know whether a newcomer could build against one of their published
contracts using only the written material. They wrote a self-contained handoff document for one
task: a browser UI over a catalog API, with a stub server, in a multi-repository codebase the
newcomer had never seen. It had eleven acceptance criteria and three ground rules:

- **The friction log is the deliverable.** Code that works is necessary. The log is the result.
- **Record friction as you go.** *"Reconstructed friction is always under-reported."*
- **Do not go looking for our notes or branches.** The preparers' own answers were sealed in a
  companion document, handed over only after the newcomer finished.

The newcomer worked with an AI coding agent doing the hands-on work. The newcomer made the
decisions and answered the agent's questions, and asked the platform team one question.

Before handing over, the preparers ran two gates of their own:

- **A readiness table of 14 rows.** Each row had a "passes when" condition and a recorded status.
- **A full walk of the task by the preparers themselves**, from the newcomer's starting point,
  with every obstacle they removed written into a fix log.

We started to run the experiment through BLC. We filed nothing and removed the attempt after
five minutes. The brief would have lived in a different repository from the code, the mandated
branch name did not fit `brief/NNNN-a-kebab`, and the ledger's phase rows would have named
branches that no tool in this repository can resolve. Those are real limits. They are not the
subject of this draft. See Non-goals.

## The claim

**The experiment was a test of a handover, not a development process. Two of its parts improve
ordinary handed-over work. One more is worth having as an optional measuring mode. The rest was
test apparatus, and this draft does not propose it.**

For development, a handed-over brief gains:

1. **Readiness rows** in the brief, each passing only on evidence that it was run, checked
   before the owner starts.
2. **A setup rehearsal**: before assigning, the author runs the owner's path from the owner's
   starting point up to a first working change, and records what they had to fix. Not the
   solution. The path to where the solution starts.

For measuring a handover, optionally:

3. **A friction section**, written by the owner as the work happens, with a fixed row shape and
   a summary whose numbers do not double-count. Published next to the rehearsal's fix count:
   both numbers or neither.

Not proposed, because each one only pays off as a test:

- **Sealed answers.** Hiding what the author knows costs the owner time. The return is a clean
  reading of whether the documents alone were enough.
- **A full walk whose solution is kept unmerged.** The preparers built the whole task in about
  8 hours and kept it off the base on purpose, so the newcomer would build it again. In
  development that is duplicate work: merge the author's solution, or do not build it.

## Evidence

### What the experiment produced

| Measure | Value |
|---|---|
| Friction rows | 38, in time order |
| Times a person was asked | 12. Six were for missing information (five topics). Six were decisions. One was relayed to a second person. |
| Elapsed, clock start to first working render against the live service | 60 min |
| To every acceptance criterion checked, short of the merge request | 89 min |
| To the merge request opened | 127 min |
| To a passing CI run | 146 min |
| Sum of the per-row "stuck for" column | 214 min, over 148 min elapsed (see *Friction rows overlap*) |
| Single worst obstacle | A stale local stack from an earlier checkout: 48 of the first 60 minutes |
| Preparers' fix log | 19 rows, each an obstacle the newcomer never met |
| Preparers' walk | About 8 hours, against a 4-hour ceiling they set for it |
| Readiness rows open at handover | 1 of 14 (no reviewer named) |

### Where the friction came from

Grouped by which of the three proposals would have caught or recorded it. Minutes are the
row's "stuck for" figure and overlap across rows.

| Source | Rows | Caught by |
|---|---|---|
| Leftover machine state (an old stack answering on the same ports, holding the dev server's port, serving an old build without the route) | 4 rows, 48 min as one span | **Readiness**, but only if run on the owner's machine. The preparers' walk ran on a clean machine and could not see it. |
| Repositories and branches not all named. The handoff named 3; a working local stack needed 9; 2 of those had no branch of the mandated name | 2 rows, 18 min | **Readiness**: "every repository the task needs is named, with a branch that exists" |
| The landing repository's CI cloned a sibling repository's default branch, which lacked an export the task's base branch had | 1 row, 16 min, plus a side effect on a shared runner | **Readiness**: "the landing repository's CI passes on the base branch". Not in the 14 rows. |
| Written conventions existed but nothing in the landing repository pointed at them | 1 row, 16 min | **Readiness**. The preparers left this unlinked on purpose, to see whether it could be found. It cost 16 minutes. |
| Reviewer not named | 1 row, 0 min lost, but it blocked the merge request until asked. The newcomer named himself, so author and reviewer were the same account. | **Readiness** (the row existed and was handed over open) |
| Content: the contract, the service, and the brief disagreed (identity key, data shape, a generator that produced an unusable type) | about 8 rows | **The ledger, as today.** This is "where the brief was wrong". Readiness cannot catch it and should not try. |
| Decisions only the owner could make (a permission name, how to vendor a schema, which heuristic to use for a finding) | 6 asks | **The ledger's Big decisions**, plus a friction row for the time |
| Agent tooling, not the platform (browser panel too narrow for screenshots, an unauthenticated tool, a tool-layer stall) | 3 rows | **Friction, as its own category.** Nothing in the codebase can prevent these, and mixing them in inflates the platform's number. |
| Keeping the log itself | 1 row, 8 min | **Friction row shape.** See below. |

### The preparers' own findings about their gate

These are the preparers' words, paraphrased, from their notes. They are the strongest
evidence in this draft, because the preparers found them against their own process.

- **Three readiness rows passed because an artifact existed, not because anyone ran it.** A
  script that reported success while doing nothing, a documented build that failed on a clean
  clone, and a credential recipe that pointed at configuration a newcomer does not have. Each
  failed the first time somebody executed it. Their rows said "following only the written
  steps" and "actually run". They read those as "the written steps exist".
- **The walk makes the owner's number a reading of the swept tree.** A long fix log and a low
  ask count do not show that onboarding is easy. They show that the onboarding work was done in
  advance. *"Report both numbers together or report neither."*
- **The ceiling was doubled without anyone noticing** until the walk ended. They recorded it as
  a finding about how they estimate this kind of work.
- **The single open readiness row was handed over open.** It became the owner's first friction
  row.

### What the friction log taught about keeping a friction log

- **The log needed a rewrite before it could be handed in.** Rows were inserted beside related
  rows instead of in time order. Some rows still said "open" after they were resolved. One row
  blamed the wrong cause, and a later row found the real one. The first ask count did not add
  up. The rewrite took about 8 minutes, and that is a friction row too.
- **"Stuck for" rows overlap.** An obstacle stays open while other work continues, and the
  48-minute row contains the rows that resolved it. The column summed to 214 minutes over 148
  elapsed. Anyone who adds it up concludes the log is inflated. Totals must come from
  timestamps.
- **Reconstructed rows need a mark.** Rows written after the event carried *(approx.)*. Those
  are the rows the handoff's warning applies to.
- **Clock gaps must be explicit.** A tool failure stopped the work for almost five hours. The
  log states the gap and excludes it from every total.
- **Asks split two ways, and the split matters.** Six asks were for information the documents
  should have held. Six were decisions only the owner could make. They mean different things
  about the handover.
- **"Guessed?" is the most honest column.** It records the owner's working assumption, and
  whether it was later shown wrong. One guess (a permission name) was wrong and cost a
  correction.

## Change

Sections are numbered by the claim above: readiness and the setup rehearsal are the
development feature, the friction section is the measuring mode.

### 1 — Readiness rows

The handed-over brief carries a `## Readiness` table:

| # | Check | Passes when | Status | Evidence |
|---|---|---|---|---|

**Evidence is a run, not a pointer**: a command and a date, a CI job, a browser check. A row
whose evidence is "the doc exists" has not passed. That is the three-row failure above, and it
is the same substitution this toolkit's Manifesto warns about.

A starting set, generalized from the experiment's 14 rows and the gaps its friction found:

1. **Reviewer named**, and not the owner.
2. **Landing place named**: repository, branch, base branch, merge target.
3. **Every repository the task needs is named**, with a branch that exists in each. Checked by
   cloning, not by reading a list.
4. **The start procedure runs from a clean clone**, following only the written steps.
5. **The start procedure runs on the owner's machine**, or the owner's first friction row is
   that run. A clean preparer machine does not see leftover state on the owner's.
6. **Credentials are obtainable** by someone with no prior access, following written steps.
7. **Test doubles start and validate** against the contract they stand in for (stub server,
   fixtures).
8. **Test doubles and the real service are reachable from the tool the owner will use**
   (browser dev server, CLI, whatever the task needs), tried, not asserted.
9. **The landing repository's CI passes on the base branch**, with every sibling dependency at
   the ref the task needs.
10. **Where the conventions live is findable from the landing repository.** Or the brief says
    on purpose that finding them is part of the test.
11. **Declared gaps are listed** as gaps, so the owner does not rediscover them as friction.

Status vocabulary from the experiment: *pass*, *failed then fixed*, *blocked*, *declared gap*,
*withdrawn*. An open row at assignment is allowed only if the brief says so, because the
experiment's one open row became the owner's first friction row.

### 2 — The setup rehearsal

Before assigning a brief, the author runs the owner's path from the owner's starting point up
to a **first working change**: the repositories cloned at the right branches, the build
passing, credentials obtained, test doubles running, the real service reachable, and the
landing repository's CI green on the base branch. The author does not build the solution.

This is where the experiment's preparers got most of their value. Their fix log has 19 rows.
Most are setup, access, build, and documentation obstacles: a root-owned dependency directory,
a missing credential recipe, an undiscoverable stub, dead links, a clone script that reported
success while fetching nothing, a build that failed on a clean clone. Two are platform defects
the walk happened to expose, and one is a missing check of the live service against the
contract. One row is bugs in the preparers' own solution, which is the only part that needed
the solution to exist.

In BLC terms the rehearsal is the evidence behind the readiness rows. It can be a phase the
author runs before assignment, or its own small brief that the handed-over brief `Depends on`.
Its record is the fix log: each row is an obstacle removed and what it would have cost the
owner. Fixes land through normal PRs on the base the owner will branch from.

- The rehearsal records **an estimate and an actual**. The experiment's full walk had a ceiling
  that was set and then doubled unnoticed.
- In measuring mode, the handed-over brief's close cites the rehearsal: the owner's ask count
  and elapsed times appear next to the rehearsal's fix count and duration. **Both numbers or
  neither.** Every obstacle the rehearsal removed is one the owner's count will not record.

### 3 — The friction section (measuring mode)

The owner keeps friction rows while executing a brief marked for measurement. A handed-over
brief that is not being measured does not carry this section. Row shape, taken
from the experiment unchanged:

| When | Trying to do | What stopped you | How it resolved | Who you asked | Stuck for | Guessed? |
|---|---|---|---|---|---|---|

Rules, each one earned by a failure above:

- **Append in time order. Never insert beside a related row.** Cross-reference instead ("see
  15:40").
- **A resolution is added in place. A corrected cause is a note, not a rewrite.** "Root cause
  found at 16:25: …" keeps the wrong first reading visible, which is the point.
- **Mark reconstructed rows** `*(approx.)*`.
- **"How it resolved" uses a small vocabulary first**: *asked a person*, *found a doc*, *read
  the source*, *guessed*, then free text.
- **Tooling rows say so** ("Agent tooling, not the platform:") and are counted separately.
- **Clock gaps get their own row** with start, end, and "not counted in any total".

A summary closes the section, and its numbers never come from summing "stuck for":

- elapsed time to named milestones, from timestamps (for example: first working run, every
  acceptance criterion, PR opened, CI passing);
- asks, split into *missing information* and *decision*, with who was asked;
- the single worst obstacle and its span;
- what the owner expected to find and did not.

**Relation to what exists.** A decision ask whose resolution carries reasoning not in the brief
is also a Big decisions entry. The friction row records the cost. The Big decisions entry
records the holding. A content finding ("the contract says X, the service does Y") is also a
ledger learning. Neither replaces the other: the ledger says what was learned, the friction
section says what it cost to learn it.

## Tension

**Development and measurement pull in opposite directions.** In development, everything the
author knows should reach the owner. The rehearsal's record is readable in the same tree, and
that is the handover working. In measurement, the same readability means a "find it" criterion
becomes "read it". This draft takes the development side. A measured brief that also has
discovery criteria needs something this draft does not propose (see Non-goals), and should say
which criteria a readable rehearsal invalidates.

**The rehearsal shrinks the owner's number, and that is the purpose and the cost.** The
preparers put it plainly: every removed obstacle is one the owner's count will not record.
Readiness and the rehearsal make the handover better. They also make the owner's friction log a
worse measure of the tree as it was. "Both numbers or neither" is the only mitigation, and it is
a reporting rule, not a check.

**Friction rows are written continuously. The ledger moves by phase branch.** After initiation
the ledger lives on the current phase branch and returns by merge. Friction happens between
phases too, including before the first branch exists (the experiment's first rows came from
reading the handoff). A friction section inside `ledger.md` would be split across branches
until each merges.

**Readiness checks mostly cannot be mechanical.** A `brief-checks/` script can confirm a
`## Readiness` table exists and has no *blocked* row without a stated reason. It cannot confirm
that "passes" meant "ran". #0011 gives projects the hook. The part that matters stays
`[judgment]`.

**Cost to a small brief.** Most briefs are executed by their author and need none of this. The
three proposals must be opt-in per brief, or they become the ceremony the Manifesto argues
against.

## Settled decisions

- **Scope is readiness rows, the setup rehearsal, and an optional friction section.** Chosen by
  the draft's author on 2026-09-29.
- **This is a development feature with an optional measuring mode, not a test harness.** The
  experiment was a test of a handover. Its test-only parts stay out.
- **Sealed answers, the full unmerged walk, and cross-repository or non-GitHub execution are out
  of scope.** All came up in the experiment. See Non-goals.
- **No partner specifics in this repository.** The source documents are proprietary. This
  draft keeps mechanisms and numbers only.

## Open decisions

1. **How a brief is marked as handed over, and separately as measured.** Two markers, because
   measuring mode is opt-in on top of a handover. An identity-line field (`· **Owner:** <email>`,
   in the same style as the correlation-ID fields), a section, or both. `validate-briefs.sh`
   reads the identity line by field pattern (lines 153–175), so an extra field looks tolerated,
   but that is read from the script, not tested.
2. **Where friction rows live.** A `## Friction` section in `ledger.md` (one narrative, split
   across phase branches until merge) or a sibling `friction.md` in the brief folder (written
   on whatever branch is current, same merge problem, but separable). Or committed straight to
   the default branch like ledger initiation, which widens that one exception.
3. **Whether the status line carries friction numbers.** `blc/2` has no slot. Adding one is a
   schema version, and #0009 records what a version costs. The summary may be enough.
4. **Who checks readiness, and when.** At filing (`blc-create-brief`), at assignment (no skill
   exists for that moment), or when the owner runs `blc-start-brief`, which already has a stop
   step. The experiment checked at assignment.
5. **Whether `blc-chronicle` renders the friction summary and the rehearsal's fix count
   together**, so "both or neither" is enforced by the rendering rather than by memory.
6. **Whether the rehearsal must be a separate brief** or can be phase `a` of the handed-over
   brief. A separate brief keeps one owner per serial. A phase keeps the record in one folder but
   puts two people on one serial, which the convention says it is not designed for.

## Non-goals

- **Sealed answers.** A preparer-side companion released at close. It is test apparatus: it
  costs the owner time in exchange for a clean reading. A team that wants to test its handovers
  can write that draft. The Tension above says what its absence costs a measured brief.
- **A full walk whose solution stays unmerged.** Also test apparatus. In development the
  author's solution is merged or not built. The setup rehearsal keeps the part of the walk that
  produced most of the fix log.
- **Briefs in one repository governing code in another**, a non-GitHub forge, or a merge
  target other than `main`. All three blocked the five-minute attempt. They are separate
  problems with separate drafts to come.
- **Baselines or improvement claims.** One handoff gives an absolute reading. The experiment's
  preparers were explicit that it establishes nothing about improvement, and neither does this.
- **Measuring briefs executed by their author.** Nothing changes for them.

## Success criteria

- A handed-over brief can be filed with readiness rows, and a `brief-checks/` example rejects
  a *blocked* row that has no stated reason.
- An author can record a setup rehearsal, and its fix log is readable by the owner before they
  start.
- An owner of a measured brief can keep friction rows while executing, in time order, on
  whichever branch is current, without losing rows at merge.
- The close of a measured brief shows the owner's elapsed times and ask counts next to the
  rehearsal's fix count and duration, and a reader cannot get one without the other.
- A handed-over brief that is not measured carries readiness rows and nothing else new.
- A friction summary's totals come from timestamps. Nothing in the toolkit presents a sum of
  "stuck for" as a total.
- A brief executed by its author sees no new required field, section, or step.
