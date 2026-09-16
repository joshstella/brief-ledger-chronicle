# Ledger — #0013 A reader that cannot find it reports it missing
`blc/2 #0013 in-progress a:done(PR#55) b:pending`

**Brief:** `docs/briefs/0013-reader-blames-the-record/brief.md`
**Started:** 2026-09-16
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the row scan | done(PR#55) | `brief/0013-a-the-row-scan` |
| b | the line's home | pending | — |

**a — the row scan.** One matcher in `tools/open-briefs.sh`, serving both index alphabets:
the id standing alone in the first cell, plus `phase N` anywhere in the row for `blc/1` and
`id —` in the first cell for `blc/2`. Every match considered — `head -1` goes — and drift
reported only when no matching row agrees with the state. Regression tests in
`tests/test_open_briefs.sh`: a ledger carrying a second table whose cells mention `phase N`,
and a letter-indexed ledger whose phase row puts the id alone in its own cell. The four
contract tests stay green.

**b — the line's home.** `open-briefs` skips a leading `---` frontmatter block before reading
the status line, so a ledger whose first line must be `---` is read by all three readers alike.
`docs/briefs/README.md` states the placement rule for both shapes. The `[no-line]` text says
where the reader looked instead of asserting the line is absent. Regression test for a
frontmatter ledger in `tests/test_open_briefs.sh`, and a matching one in
`tests/test_list_briefs.sh` pinning that the permissive reader keeps agreeing.

## Dependency structure

Independent in logic — two different defects on two different code paths. **Sequential in
practice:** both edit `tools/open-briefs.sh`, so a parallel pair would conflict for no gain.
Run `a → b`. Neither phase is provisional; the brief carries no open decisions.

## Open decisions

None. The placement question — legalize frontmatter, or keep line 2 strict and reword the
finding — was the only one, and it is settled in the brief rather than deferred to a phase.
Frontmatter placement becomes legal. Two of the three readers already accept it, the
constraint is imposed by a target's docs pipeline rather than chosen, and the rejected
option costs the same detection work and then declines to act on what it found.

## Complications

Found at initiation by reading the code, not assumed from the brief.

**This repository already contains both decoy shapes.** The fix has a live validation surface
here, and `test_open_briefs_this_repo_scans_without_crashing` is what exercises it.

- `#0006`'s Branches table carries `` | `brief/0006-manifesto` | phase 5 | merged, PR #30; branch deleted | ``.
  That row matches the numeric scan and contains no `done`, while the status line says
  `5:done(PR#30)`. It reports clean today only because `head -1` happens to reach the real
  phase row first — the real row sits at line 16, the decoy at line 57. The ordering is luck,
  not design, and it is the same accident that failed in the install target.
- `#0009`'s numeric-to-letter mapping table carries `` | `a — the readers` | `b — the readers` | ``,
  which matches the letter scan. Under `a`, the match set after this phase is the real row
  plus that mapping row.

Both are absorbed by "any matching row agrees" and neither should produce a finding after
phase `a`. If either does, the matcher is wrong.

**`add_ledger` cannot build phase `b`'s fixture.** The helper in `tests/test_open_briefs.sh`
hardcodes the title on line 1 and the status line on line 2 — it is built from the assumption
phase `b` is removing. A frontmatter fixture needs its own helper rather than a parameter on
this one.

**`list_brief` in `tests/test_list_briefs.sh` has the same shape,** writing
`printf '# Ledger\n%s\n'`. Same treatment for the phase `b` counterpart test.

**This ledger is itself a fixture for the defect it fixes.** Its phase table is written
`| a | the row scan | …`, the two-column shape `blc-start-brief` produces and the current
letter scan cannot match. Until phase `a` lands, `open-briefs` cannot report drift on this
file — including drift in the record of the work to fix that.

**No `AGENTS.md` or `CLAUDE.md` at the repo root.** Architecture rules come from
`docs/briefs/README.md`, `Manifesto.md`, and `.cursor/rules/no-cq-leak.mdc`, which is
`alwaysApply` and governs how both defects may be described: the install target is a
destination, never a source. Every fixture in both phases is synthetic.

## Phase a — what it does

**One matcher, both alphabets.** The id alone in the first cell, the em-dashed form, and
`phase N` in prose for `blc/1`. The numeric pattern gained the anchored form and kept the
prose form, so an install target that puts the id elsewhere still works.

**Every match considered.** `head -1` is gone. Drift is reported only when no matching row
agrees, so a decoy row from a second table can no longer shadow a real row that agrees.

**#0011 and #0012 became scannable.** The letter scan matched zero rows in either file before
this phase. A mutated row in #0011 now reports drift and still exits 0.

**Four tests.** Three fail before the change and pass after. The fourth guards the opposite
error, a matcher loose enough to fire on everything.

## Big decisions

**The phase-table shape is unprescribed, and it drifted without a decision.** Found
2026-09-16 at the review gate.

`blc-start-brief` has said a phase id looks like `a — domain types` since the initial commit
and has never been edited. Nothing in `skills/`, `templates/`, or `docs/briefs/README.md`
prescribes a phase-table header. On 2026-09-09 a run wrote `| id | label | status | branch |`
into #0012; the next two runs imitated the newest ledger rather than the instruction. The
letter matcher shipped 2026-09-08 was therefore dead for the week that followed — across two
PR cycles and their reviews — and no test noticed.

Phase `a` fixes the reader, not the shape. Pinning the shape is a different brief: #0011 built
`brief-checks/` for this class of rule. Drafted as `_drafts/the-shape-nothing-prescribes.md`.

The matcher still misses `` | `a` | ``, `| ~~a~~ |`, and ``| ~~`a`~~ |``; `` `?~* `` after the
id closes all three. Left open in the bug ledger — no ledger writes those shapes today, and
widening at the gate would put an untested change into a diff whose claim is that the
behaviour is now pinned by fixtures.
