# The shape nothing prescribes

**Created:** 2026-09-16T10:52:17Z · **Author:** josh.stella@gmail.com
**Depends on:** #0013

## Ground

#0013 fixed a reader that could not find the phase row. It did not touch the reason the row
moved.

On 2026-09-08 the letter matcher shipped, keyed to `` | `a — the readers` | `` — the shape
every ledger in the tree then used. On 2026-09-09 a run wrote `| id | label | status | branch |`
into #0012's ledger. The next two runs imitated the newest ledger rather than the instruction.
The matcher was dead for the seven days that followed, across two PR cycles and their reviews,
and the suite stayed green the whole time, because a row the scan cannot match produces no
finding at all.

`blc-start-brief` has said a phase id looks like `a — domain types` since the initial commit
on 2026-08-02 and has never been edited. Nothing in `skills/`, `templates/`, or
`docs/briefs/README.md` prescribes a phase-table header. The shape three ledgers now share was
never chosen. It was copied.

This is the toolkit's own principle arriving on schedule: **a skill guard is not a check.** The
instruction was present, unchanged, and followed loosely, and the only thing positioned to
notice was a reader designed to stay quiet.

## The claim

**A ledger whose status line names a phase that its own table cannot be matched to is a
defect, and `validate-briefs.sh` says so.**

The rule is *findability*, not a shape. For every `<id>:<state>` in the status line, at least
one phase-table row must match the same matcher `open-briefs.sh` uses. Whatever layout a
project writes stays legal, as long as its own readers can find the row.

- The matcher has one implementation, used by both the gate and the reporter.
- `validate-briefs.sh` fails on an unfindable id, citing a clause id like every other defect.
- `open-briefs.sh` keeps reporting and keeps never gating.

The shape stays free. Silence stops being available.

## Evidence

**1. The failure is silent by construction.** `open-briefs.sh` guards on an empty row and
reports clean, which is correct for a reporter and fatal for a canary. Nothing else looks at
a phase table at all.

**2. It was invisible to every gate that exists.** `validate-briefs.sh` decides eight clauses
and none of them mentions the status line or the phase table. A ledger can name phases that
appear nowhere in its own body and pass.

**3. Prose could not hold it.** The instruction was correct, unchanged for six weeks, and
three consecutive runs did something else. This is the 43% from #0011 measured again on a
smaller sample.

**4. The rule belongs to the toolkit, not to one project.** #0011 shipped `brief-checks/` for
project-specific rules, and this is not one: every adopter has ledgers and readers, and the
mismatch breaks the same way in all of them. That puts it with the other eight clauses.

**5. A shared matcher is the only arrangement the two tools cannot drift apart in.** #0013's
second defect was two readers disagreeing about where the status line lives. Writing a second
independent matcher for the gate would reproduce that defect deliberately.

## The finding this inherits

#0013 phase `a` left one gap open. Its bug ledger is keyed to `brief/0013-a-the-row-scan`, a
branch that has since merged, so the finding is tracked against nothing. It moves here.

`tools/open-briefs.sh` builds `row_pattern` to accept a leading `~~` and a leading backtick, but permits nothing
after the id. Three shapes therefore match no row and report clean: `` | `a` | ``,
`| ~~a~~ |`, and ``| ~~`a`~~ |``. Appending `` `?~* `` after the id closes all three and
changes no shape that currently matches, checked against six fixtures.

It was not taken at the review gate, deliberately. Widening the matcher treats the symptom —
the cause is that nothing prescribes the phase-table shape, so the next shape nobody chose
will be silent in the same way. Under this brief the gap stops being silent either way: a
status line naming `a` against a table no reader can match becomes a defect
`validate-briefs.sh` reports, whether the answer is a wider matcher or a corrected ledger.
That is the difference between a gap someone has to remember and one the gate finds.

## Change

| Phase | Work |
|---|---|
| `a — the shared matcher` | One implementation of the phase-row matcher, used by both `open-briefs.sh` and `validate-briefs.sh`, with a test that fails if the two ever disagree. No behaviour change. Blocked by open decision 1. |
| `b — the clause` | `BRIEFS-9`: every phase id in a status line is findable in the phase table. Validator check citing the clause, Contract text, and tests — including the three shapes #0013 left unmatched, which become failures instead of silences. |
| `c — the upgrade` | How an existing repository crosses into a clause that did not exist yesterday. Blocked by open decision 2. |

Strict chain. `b` needs the matcher; `c` needs the clause to exist before it can decide how to
introduce it.

## Tension

**Elevating a heuristic to a clause makes the clause exactly as good as the heuristic.** The
matcher is a token scan, not a parse — that is deliberate and #0013 kept it that way. A ledger
could satisfy `BRIEFS-9` with a row that merely looks like the right row. The clause proves
findability, which is all it claims, and it must not be read as proving the table is correct.

**A new clause fails ledgers that were fine yesterday.** Any adopter carrying an unmatched
shape gets a red gate on upgrade, for a real defect they could not previously see. That is the
point of the clause and still a surprise, which is why `c` exists rather than being assumed.

**Freezing the matcher into a contract means widening it is a contract change.** The
mitigating fact is that widening only ever admits more shapes, so it is a relaxation and
cannot break an adopter — but the process cost is real and lands on whoever next meets a
shape the scan does not know.

**This does nothing about the status line itself.** #0013's phase `b` legalizes frontmatter
placement; nothing checks that a ledger has a status line at all. `open-briefs` reports
`[no-line]` and moves on. A brief that gates on phase ids while ignoring whether the line
exists is enforcing the second half of a rule whose first half is still advisory.

**The writer is still unconstrained.** `blc-start-brief` will keep emitting whatever shape the
model chooses. This brief makes a bad choice fail loudly at the gate instead of silently at the
reader; it does not make the choice correct. Prescribing the shape in the skill was considered
and belongs in the settled decisions below.

**Nobody has been hurt yet.** The week of blindness cost one unreported drift on ledgers whose
owner could read them directly. The case for a Contract clause rests on the failure mode, not
on damage done, and a reader who thinks that is too heavy a response is not obviously wrong.

## Settled decisions

Resolved 2026-09-16 during drafting.

- **Findability is the rule; the shape stays free.** Prescribing one phase-table layout would
  put the toolkit in the business of formatting a project's own record, and would break the
  three existing shapes in this repository for no gain.
- **The rule is a Contract clause, not a `brief-check`.** `brief-checks/` is for rules one
  project invents. Every adopter has this problem identically.
- **Prescribing the shape in `blc-start-brief` is not the fix, though it may be an addition.**
  The instruction that drifted was already there. A more specific instruction has the same
  enforcement ceiling as the one it replaces.
- **One matcher, shared.** Two implementations would reproduce #0013's second defect on
  purpose.
- **`open-briefs.sh` does not become a gate.** It reports. The gate is the gate.
- **v1.2 is published once.** `_drafts/someone-elses-docs-tree.md` also targets v1.2, where it
  re-scopes the existing clauses to `docs/blc/`. Whichever brief finishes second carries the
  publication and cites both changes. This one adds a clause; that one moves what the clauses
  are about, so they do not collide beyond the version number.

## Open decisions

1. **Where the shared matcher lives.** Either duplicated in both tools with a test asserting
   they agree, or sourced from a new `tools/lib/`. This repository has no shell library today,
   and a new path has to be recorded in #0012's ownership map before the installer can be
   trusted around it. Blocks phase `a`.
2. **Whether `BRIEFS-9` gates immediately or reports for one version.** A clause that lands
   already failing is the honest signal; a clause that reports first is the kinder upgrade.
   #0003 faced this exact question and demoted a gate to a report. Blocks phase `c`.

## Non-goals

- **Not prescribing a phase-table shape.**
- **Not a table parser.** The token scan stays a token scan.
- **Not validating labels, branches, or column counts** — only that the id is findable.
- **Not rewriting any existing ledger.**
- **Not making `open-briefs.sh` gate.**

## Success criteria

- A ledger whose status line names `a` while no row in its phase table can be matched fails
  `validate-briefs.sh` with a clause id.
- The same ledger passes in any layout where a row does match, including all three shapes
  already in this repository.
- One matcher implementation, and a test that fails if the gate and the reporter disagree.
- The three shapes #0013 left unmatched — `` | `a` | ``, `| ~~a~~ |`, ``| ~~`a`~~ |`` — produce
  a failure rather than a silence, whether by widening the matcher or by failing the ledger.
- Every ledger currently in this repository passes unchanged.
- `open-briefs.sh` still exits 0 on every finding it can emit.
