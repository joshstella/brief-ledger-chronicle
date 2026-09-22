# The shape nothing prescribes

**Serial:** #0014 · **Created:** 2026-09-16T10:52:17Z · **Author:** josh.stella@gmail.com · **Depends on:** #0013

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
| `a — the shared matcher` | One implementation of the phase-row matcher in `tools/lib/`, read by `open-briefs.sh`, with a guard that fails if any tool re-derives it. No behaviour change. Carries the installer and ownership-map work a new `tools/` path brings with it. |
| `b — the shared locator` | One implementation of the status-line locator in `tools/lib/`, read by `open-briefs.sh` and `list-briefs.sh`. The two disagree today by design — one walks structurally past frontmatter, the other searches the whole file — and `c` adds a third reader that gates. Resolves to a whole-file search with an anchored match: the line must begin with the token. That form finds the placements the structural reader misses and refuses the prose the unanchored search swallows, and returns identical results on every ledger here. |
| `c — the clauses` | Two `[judgment]` clauses, neither of which blocks. `BRIEFS-9`: every phase id in a status line is findable in the phase table. `BRIEFS-10`: a ledger's frontmatter and code fences are closed. `validate-briefs.sh` becomes the second reader of both shared pieces, with a test that fails if the readers ever disagree. Validator checks citing each clause, Contract v1.2 text, and tests — including the three shapes #0013 left unmatched, which become complaints instead of silences. |
| `d — the promotion` | The version at which the two `[judgment]` clauses become `[defect]`, and what has to be true first. Unblocked 2026-09-22 by open decision 2, and narrowed by it: a clause that never fails a build has no day-one crossing to manage, so what remains is the promotion rather than the introduction. |

Strict chain. `b` reconciles the locator; `c` needs both shared pieces; `d` needs the clause to
exist before it can decide how to introduce it.

**Re-lettered 2026-09-16, after phase `a` merged.** A new `b` was inserted and the former `b`
and `c` moved down one letter:

| was | is |
|---|---|
| `a — the shared matcher` | `a` — unchanged, merged as PR#61 |
| `b — the clause` | `c` |
| `c — the upgrade` | `d` |

The mapping is recorded rather than applied quietly because merged PRs cite phase ids as they
were, and a silent re-lettering strands them. Only `a` has merged, and it keeps its letter, so
nothing is stranded here.

The insertion came from a finding phase `a` could not have seen: `open-briefs.sh` and
`list-briefs.sh` already locate the status line two different ways, deliberately. They agree on
all thirteen ledgers in this repository today, so nothing is broken — but the clause adds a
third reader that *gates*, and a gate that disagrees with a reader about where the line lives
is #0013's second defect rebuilt inside the brief written to prevent it.

**Amended 2026-09-16, after phase `a` was reviewed.** The `a` row originally required the
matcher "used by both `open-briefs.sh` and `validate-briefs.sh`, with a test that fails if the
two ever disagree". That cannot be met in `a`: an agreement test needs two call sites, and
`validate-briefs.sh` has no reason to read a phase table until `BRIEFS-9` exists. Both
requirements moved to the clause phase, which the re-lettering above then renamed `b` → `c`.
This paragraph said `b` until 2026-09-16, when it was written; that token is now corrected in
place rather than left to be read through the table.

Two agreement tests come out of this, and they are not the same one moving. Phase `b` created
a second call site for the *locator* — `open-briefs.sh` and `list-briefs.sh` — so `b` owed and
delivered agreement between those two reporters. Phase `c` adds `validate-briefs.sh` as a
reader of *both* shared pieces, and the phase-row matcher still has one caller until it does;
the agreement `c` owes is between the gate and the reporters, and cannot be written earlier.
The settled decisions already implied the split —
"sharing source does not prove both tools call it alike" is an argument about call sites, not
about files. Recorded here rather than quietly rewritten, since this brief descends from one
about a record that moved without saying so.

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
- **The shared matcher lives in `tools/lib/`.** Resolved 2026-09-16 on initiation, closing open
  decision 1. Duplication was excluded by this brief already: the claim, evidence 5, phase `a`,
  and the success criteria each require one implementation, and the agreement test the
  duplication option offered is required in either arrangement, since sharing source does not
  prove both tools call it alike. Reaching the matcher by subprocess was considered and
  rejected — `validate-briefs.sh` runs without git by design and `install.sh` says so, while
  `open-briefs.sh` reads git history; that arrangement would make the gate need git. The price
  is a new ownership-map row, the `chmod +x` and summary lines in `install.sh`, and an
  exemption in `tests/test_source_tree.sh`, where `tools/lib/` is exempt **by path** — a
  directory whose name means "sourced, not invoked".
- **v1.2 is published once.** `_drafts/someone-elses-docs-tree.md` also targets v1.2, where it
  re-scopes the existing clauses to `docs/blc/`. Whichever brief finishes second carries the
  publication and cites both changes. This one adds a clause; that one moves what the clauses
  are about, so they do not collide beyond the version number.

## Open decisions

1. ~~**Where the shared matcher lives.**~~ **Resolved 2026-09-16** — see "The shared matcher
   lives in `tools/lib/`" above. Struck rather than removed, and the numbering below is held,
   so the reference from phase `d` still resolves — the phase that cites decision 2, which
   the 2026-09-16 re-lettering moved from `c` to `d`. This sentence said `c` until re-review
   caught it, which is pointed: its only job is to keep a cross-reference resolving, and it
   was the last stale one in the file.
2. ~~**Whether `BRIEFS-9` gates immediately or reports for one version.**~~ **Resolved
   2026-09-22 — it complains and never blocks.** A clause that lands already failing is the
   honest signal; a clause that reports first is the kinder upgrade. #0003 faced this exact
   question and demoted a gate to a report, and this follows it.

   `BRIEFS-9` lands as `[judgment]`, which is not a new mechanism: `docs/contracts/v1.1.md`
   already defines the tag as "scope `both` · checked: `tools/validate-briefs.sh` (never
   blocks)", and `BRIEFS-8` has shipped that way since v1. The validator prints the finding,
   counts it in the summary, and exits zero.

   This unblocks phase `d`. It also shrinks it: the hard part of "how an existing repository
   crosses into a clause that did not exist yesterday" was always the repositories the clause
   would fail on day one, and a clause that cannot fail a build has no crossing to manage.
   What `d` still owes is the promotion — the version at which `[judgment]` becomes
   `[defect]`, and what has to be true first.

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
