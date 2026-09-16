# A reader that cannot find it reports it missing

**Serial:** #0013 · **Created:** 2026-09-16T02:41:40Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## Ground

The toolkit was installed into an adopting repository carrying 42 ledgers, and its readers
were run against them. Two findings came back. They look unrelated — one is a false `[drift]`,
the other a false `[no-line]` — and they are the same failure twice.

In both, a reader looked for something in one exact shape, failed to find it, and reported a
defect **in the record**. The record was fine. The reader was narrow. A reporter that says
"your ledger disagrees with itself" when it means "I could not find the row" spends the trust
that makes every other finding worth reading.

`tools/open-briefs.sh` is the only reader with this problem, and it has it twice.

## The claim

**A reader reports what it found, not what it failed to look for.**

Two changes, both in `tools/open-briefs.sh`:

1. **The drift scan matches every row that could be the phase's row, and reports drift only
   when none of them agrees with the status line.** One matcher serves both index alphabets:
   the id standing alone in the first cell, plus the legacy shapes already in the tree.
2. **A ledger may open with YAML frontmatter, and its status line sits under the title
   wherever the title landed.** `open-briefs` skips a leading `---` block. `docs/briefs/README.md`
   says so in the sentence that currently says "line under its title".

Neither tool gains an exit code. Both still report and never gate.

## Evidence

**1. The numeric row scan matches prose, not rows.** `tools/open-briefs.sh:204` finds the
phase row with `grep -n "^|.*phase $idx "`. That matches any table row containing the literal
text `phase N ` — including rows of a *second* table. A ledger that keeps a cost or timing
table alongside its phase table produced a false `[drift]`: a row of the shape

```
| 14:02–14:18 | drafting phase 2 | 0.40 |
```

matched, does not contain the word `done`, and was reported as disagreeing with a status line
that said `2:done`. The actual phase row, `| 2 | ... | done |`, is matched by nothing —
a bare id in the first cell contains no `phase 2 ` anywhere. `head -1` then seals it: the
first match wins, so a decoy shadows the real row even when the real row is present.

**2. The letter scan is blind to the shape this toolkit currently writes.**
`tools/open-briefs.sh:205` requires the id followed by an em dash: `` `a — the thing` ``.
The two newest ledgers in this repository — #0011 and #0012, both written by the current
`blc-start-brief` — put the id in its own column: `| a | the runner | done(PR#53) |`. That
pattern matches **zero** rows in either file. The guard on an empty row then reports clean,
so drift is *unreportable* on the ledger shape the toolkit itself now produces.

The seam is visible in the instructions: `blc-start-brief` step 5 says a phase id looks like
`a — domain types`, and its own step 6 output splits id and label into two columns. Both
shapes are in the tree. The scan knows one.

`test_open_briefs_reports_drift_on_a_letter_indexed_ledger` passes only because its fixture
uses the em-dash shape. It pins that the scan works; it does not pin that the scan is used.

**3. The two readers disagree about where the status line lives.** `open-briefs.sh:145` reads
it strictly — `sed -n '2p'`. `list-briefs.sh:51` reads it permissively — `grep -m1 -E 'blc/[0-9]+'`,
and `tools/orient.sh` inherits that read. A ledger whose first line must be `---` cannot put
its status line on line 2 without breaking its own frontmatter, so the line goes after the
closing fence. Two of the three readers find it there. The third reports
`no blc/N status line under the title`, of a line the reader can see with their own eyes.

**4. Nothing checks placement, so the disagreement was free to last.** `tools/validate-briefs.sh`
has no clause about the status line at all — `BRIEFS-1` to `BRIEFS-8` never mention it.
"Line 2" is not a rule. It is one reader's `sed` expression, promoted to a rule by being the
strictest thing in the tree.

**5. Reading what it did not write is already this toolkit's posture.** `blc/1` lines are
never rewritten; every reader dual-reads both schemas; `open-briefs` carries an explicit note
at lines 199–202 that the numeric scan stays unanchored because an install target may lay its
tables out differently. Widening a reader is the established move here. Narrowing the record
to suit a reader is not.

## Change

| Phase | Work |
|---|---|
| `a — the row scan` | One matcher, both alphabets: the id alone in the first cell, plus `phase N` anywhere in the row for `blc/1` and `id —` in the first cell for `blc/2`. Every match considered, `head -1` gone. Drift reported only when no matching row agrees with the state. Regression tests: a ledger with a second table that mentions `phase N`, and a letter-indexed ledger whose phase row puts the id alone in its own cell. The four contract tests stay green. |
| `b — the line's home` | `open-briefs` skips a leading `---` frontmatter block before reading the status line. `docs/briefs/README.md` states the placement rule for both shapes. The `[no-line]` text says where it looked. Regression test for a frontmatter ledger in `test_open_briefs.sh`, and a matching one in `test_list_briefs.sh` pinning that the permissive reader keeps agreeing. |

Independent in logic — different code paths, different defects. Sequential in practice,
because both edit `tools/open-briefs.sh` and a parallel pair would conflict for no gain.

## Tension

**False negatives replace false positives, deliberately.** "Drift only when no row agrees"
means a ledger with a stale phase row *and* a second table that happens to carry the right
word reports clean. That is a real hole and it is the price of the rule. It is worth paying:
this tool never gates, so a false positive costs trust in every finding it will ever emit,
and a false negative costs one missed drift that the next reader of the ledger still sees.
A reporter nobody believes reports nothing at all.

**Widening the matcher widens what a phase row is.** A second table with a bare `2` in its
first cell will now match. "Any row agrees" absorbs the common case — one true row clears it —
but a ledger whose real row is missing while a decoy matches still reports drift. That report
is correct on its own terms: no row agrees with the line.

**Placement becomes two rules where it was one.** "Line 2" was checkable at a glance. "The
first `blc/` line under the title, where the title may follow a frontmatter block" is still a
bounded positional read, not a search — but it is no longer one `sed` expression, and the
README has to carry the longer sentence.

**The two readers still will not converge.** `list-briefs` stays `grep -m1` and is not
narrowed by this brief: it is a display tool that names a status, and tightening it would
newly report `no-line` on ledgers it reads correctly today. After this brief `open-briefs`
accepts a strict subset of what `list-briefs` accepts. That asymmetry stops being an accident
and becomes a recorded decision, which is the most this brief can honestly claim.

**Nothing here is checked.** No Contract clause, no `brief-checks` script. Placement stays a
convention held up by readers agreeing to be generous, and the next reader written against
line 2 will reintroduce the same defect. #0011 shipped the mechanism that could close this;
using it is not this brief's job.

**One target, 42 ledgers.** Both defects are stated generically and both fixtures are
synthetic, but the sample that found them is a single adopting repository. A second target
may carry a third shape neither matcher knows.

## Settled decisions

Resolved 2026-09-16 during drafting.

- **Frontmatter placement becomes legal.** The alternative — keep line 2 strict and merely
  improve the message — was considered and rejected. Three reasons. Two of the three readers
  already accept the frontmatter placement, so strictness would be the minority position
  enforcing itself on the majority. The constraint is imposed by a target's docs pipeline,
  not chosen by its author; a ledger cannot be moved to line 2 without breaking the file for
  every other tool that reads it. And the better message option (b) asks for costs the same
  work as fixing it: to say *"your line is after frontmatter"* the reader must detect the
  frontmatter — and would then decline to act on what it just found.
- **The `[no-line]` text changes under either option.** `no blc/N status line under the title`
  describes the record. It should describe the read: what was examined, and where.
- **One matcher, both alphabets.** The two defects in the row scan have one cause — the scan
  knows some phase-row shapes and not others — and two patterns that drift apart is how it
  got here.
- **Every match considered; drift only when none agrees.** Chosen over ranking matches or
  scoring them. There is no principled ranking; "the record contains a row that agrees" is a
  claim the tool can actually make.
- **The numeric scan is not anchored to the first cell.** `open-briefs.sh:199–202` states the
  latitude and `test_open_briefs_reports_drift_when_a_numeric_id_is_not_in_the_first_cell`
  pins it. First-cell matching is *added* to the numeric pattern, never substituted for it.
- **`list-briefs` is not narrowed.** Stated above under Tension. It reads a superset; that is
  now deliberate.
- **No ledger is rewritten.** `blc/1` lines and em-dash phase rows stay exactly as they are.
  Both fixes are reader-side, which is the only side that can be fixed once without asking
  every adopter to migrate.
- **Only a leading `---` block is skipped.** Line 1 exactly, closed by the next `---`. Not
  TOML fences, not a block further down, not a frontmatter parser.
- **Neither tool gains a non-zero exit.** `docs/briefs/README.md` says these observe rather
  than gate, and a defect in a reporter is not a reason to make it a gate.
- **Each phase carries its own tests.** Both defects are silent failures, so a phase that
  merged without its regression test would be indistinguishable from one that shipped nothing.

## Open decisions

None. The placement question was the only one, and it is settled above rather than deferred —
leaving it open would mean shipping a fix to a reader without saying what the reader is
entitled to expect.

## Non-goals

- **Not a full table parse.** Three table schemas are in use and the token scan survives all
  three. `open-briefs.sh:188–191` already says why, and this brief agrees with it.
- **Not a frontmatter feature.** Nothing gains the ability to *read* frontmatter. One reader
  gains the ability to step over it.
- **Not converging the two readers onto one implementation.** A shared parsing library for two
  scripts with different jobs is a bigger change than either defect justifies.
- **Not a Contract clause and not a `brief-checks` script.** Placement stays convention.
- **Not a migration.** No existing ledger in any repository is edited by this work.

## Success criteria

- A ledger carrying a second table whose cells mention `phase N` reports no drift when its
  real phase row agrees with the status line.
- A letter-indexed ledger written as `| a | label | status |` reports drift when its table
  disagrees, and reports clean when it agrees. This repository's own #0011 and #0012 become
  scannable.
- A ledger opening with YAML frontmatter is read identically by `open-briefs`, `list-briefs`,
  and `orient`.
- A ledger with genuinely no status line still reports `[no-line]`, in words that say where
  the reader looked.
- Each defect has a test that fails before its fix and passes after.
- All four contract tests stay green: `..._reports_drift_between_line_and_table`,
  `..._reports_drift_on_a_letter_indexed_ledger`,
  `..._reports_drift_when_a_numeric_id_is_not_in_the_first_cell`,
  `..._reports_a_ledger_with_no_status_line`.
- `bash tests/run.sh` is green, and neither tool exits non-zero on any finding.
