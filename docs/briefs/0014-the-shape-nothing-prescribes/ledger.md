# Ledger — #0014 The shape nothing prescribes
`blc/2 #0014 in-progress a:done(PR#61) b:in-progress(brief/0014-b-the-shared-locator) c:pending d:pending`

**Brief:** `docs/briefs/0014-the-shape-nothing-prescribes/brief.md`
**Started:** 2026-09-16
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the shared matcher | done | PR#61 |
| b | the shared locator | in-progress | `brief/0014-b-the-shared-locator` |
| c | the clause | pending | — |
| d | the upgrade | pending | — |

Re-lettered 2026-09-16 when `b` was inserted. The former `b` is now `c`, the former `c` is now
`d`; `a` keeps its letter and its merged PR. The mapping is in the brief's Change section.
Nothing is stranded — `a` is the only phase with a PR, and it did not move.

**a — the shared matcher.** One implementation of the phase-row matcher in `tools/lib/`,
read by `open-briefs.sh`, with a guard that fails if any tool re-derives it. No behaviour
change. Carries the installer and ownership-map work in complications 1 and 2 below.

The brief's row for `a` asked for more than `a` can deliver and was amended after review to
match. See the scope call below and complication 5.

### Phase a — what it does

- `tools/lib/phase-row.sh` holds the matcher, as `blc_phase_row_pattern` and
  `blc_phase_row_find`. No shebang, no execute bit, `blc_` prefix on both functions
  because the file is sourced into tools that already have globals.
- `open-briefs.sh` sources it and lost its inline `row_pattern`. A missing library exits
  2 with the other environment failures, so a scan that cannot run never reports clean.
- `install.sh`: `tools/lib` scaffolded, `tools/lib/phase-row.sh` in the ownership map,
  the `chmod +x` loop skips `tools/lib/*`, and the pre-install summary names `lib/`.
  Verified against a real install — the library lands `-rw-r--r--` beside four
  `-rwxr-xr-x` tools, and the installed `open-briefs.sh` runs from there.
- `tests/test_source_tree.sh` exempts `tools/lib/*.sh` by path.
- `tests/test_phase_row.sh` is new: 284 tests pass, up from 276.

**A property was lost and recovered during review.** The extraction gave `open-briefs.sh`
an external dependency it never had, located by `dirname "${BASH_SOURCE[0]}"` — the
directory the script was *reached* through. Reaching it by symlink, the ordinary way a
tool lands on a `PATH`, made it exit 2 looking for `lib/` beside the link. The whole
suite stayed green and an independent review of the diff passed it; it was found by
running the tool through a symlink on purpose. `open-briefs.sh` now walks the link chain
by hand — not `readlink -f`, which is GNU-only — and
`phase_row_open_briefs_runs_through_a_symlink` pins it. Written up in `tests/README.md`
under "A refactor can remove a property nobody wrote down".

**Scope call — `validate-briefs.sh` does not source it yet.** The brief's phase `a` says
the matcher is "used by both" tools, but `validate-briefs.sh` has no phase-row logic until
`BRIEFS-9` exists in phase `b`, so sourcing it now would add an unused import and phase
`a` would stop being provably behaviour-preserving. What phase `a` ships instead is the
guarantee that makes "used by both" enforceable when `b` arrives:
`phase_row_no_tool_defines_its_own_matcher` scans `tools/` for a re-derived pattern and
fails if one appears. The brief's agreement test belongs in `b`, where there are two
callers to disagree.

**b — the shared locator.** One implementation of the status-line locator in `tools/lib/`,
read by `open-briefs.sh` and `list-briefs.sh`. Inserted after phase `a` on a finding phase
`a` could not have seen — see complication 7.

**c — the clause.** `BRIEFS-9`: every phase id in a status line is findable in the phase
table. Validator check citing the clause, Contract text, and tests — including the three
shapes #0013 left unmatched, which become failures instead of silences.

**d — the upgrade.** How an existing repository crosses into a clause that did not exist
yesterday. Blocked by open decision 2.

## Dependency structure

Strict chain: `a → b → c → d`. `c` needs both shared pieces; `d` needs the clause to exist
before it can decide how to introduce it.

## Open decisions

1. ~~Where the shared matcher lives.~~ Resolved on initiation; see the brief's settled
   decisions. The answer was forced rather than chosen — see complication 3.
2. **Whether `BRIEFS-9` gates immediately or reports for one version.** Blocks phase `d`,
   which the 2026-09-16 re-lettering moved from `c`. #0003 faced this question and demoted
   a gate to a report.

## Complications

1 to 6 were found on initiation and during phase `a`, reading the brief against `main` at
`afe97e4`. 7 to 9 were found planning phase `b`, and none of them was visible before phase
`a` landed. Phase `a` carried 1, 2, 4, 5 and 6; phase `b` carries 7; phase `c` carries 8
and 9.

1. **`tools/lib/` is not a free path.** The ownership map hardcodes the four tools at
   `install.sh:343-346`; a fifth entry is a hand edit there. `install.sh:856` runs
   `chmod +x` on everything it places under `tools/`, which a sourced library does not
   want. `install.sh:724` prints the tool names in the pre-install summary.
   `test_ownership_map.sh` asserts the map and the install agree in both directions, so
   each of those is load-bearing rather than cosmetic.

2. **A sourced library would fail a test merged the same day.** `tests/test_source_tree.sh`
   (`afe97e4`) asserts that every `*.sh` outside `tests/` is mode `100755` in the git
   index, because it treats everything there as invoked. A sourced `tools/lib/*.sh` is not,
   so phase `a` must teach that test the difference. Decided on initiation: exempt
   `tools/lib/` **by path**, a directory whose name carries the meaning, rather than
   deriving it from a missing shebang. This is the scope question left open on PR #60,
   arriving with a real case attached.

3. **Open decision 1 was narrower than the brief presented it.** It offered duplication as a
   live option, but the brief's claim, evidence 5, phase `a`, and success criteria each
   require one implementation, and the agreement test that option offered is required in
   either arrangement. The unlisted subprocess arrangement was also checked and rejected:
   `validate-briefs.sh` runs clean in a non-git directory and `install.sh:750` promises it,
   while `open-briefs.sh` reads git history twelve times, so routing the gate through the
   reporter would make the gate need git. One option remained, and it is the costly one.

4. **No shell library exists yet.** `tools/lib/` is the first, so phase `a` sets the
   precedent for how sourced code is laid out, named, and tested here. Worth deciding
   deliberately rather than by whatever the first file happens to do.

5. **The brief's phase `a` row cannot be satisfied by phase `a`.** It requires the matcher
   "read by both" tools and "a test that fails if the two ever disagree". An agreement
   test needs two call sites, and `validate-briefs.sh` has no reason to read a phase table
   until `BRIEFS-9` exists in phase `b`. The brief concedes the point in its own settled
   decisions — "sharing source does not prove both tools call it alike" is an argument
   about call sites, not about files. So the requirement belongs in `b`. **Resolved
   2026-09-16:** the author amended `brief.md`, moving "used by both" and the agreement
   test into `b`'s row, with the amendment recorded in the brief rather than applied
   silently. Ledger and brief now agree.

6. **The compensating control shipped broken.** The guard offered in place of the
   agreement test could not fail: its fingerprint was an ERE missing a backslash, so it
   matched nothing, and a verbatim copy of the matcher planted in `tools/` passed it.
   Found by review, not by the suite. Now a literal `grep -F` with two positive controls
   in front of it, mutation-tested in both directions. Written up in `tests/README.md`
   under "A guard whose pattern stops matching its own target".

7. **Two status-line locators already exist, and they disagree by design.** Found while
   planning the clause. `open-briefs.sh` walks structurally — skip frontmatter, skip to the
   title, take the next line — and `list-briefs.sh` greps the whole file for `blc/`. The
   divergence is documented in `open-briefs.sh` as a cost rule, and checked against all
   thirteen ledgers here: they **agree on every one**, so nothing is broken today.

   It matters because the clause adds a third reader that *gates*. A gate that disagrees
   with a reader about where the status line lives is #0013's second defect rebuilt inside
   the brief written to prevent it. Hence the inserted phase `b`.

   **Decision — the shared locator searches the whole file but anchors the match.** The
   line must begin with the token, allowing only leading whitespace and a backtick.

   This corrects an earlier decision recorded here, which said to take `list-briefs`'
   unanchored whole-file search on the reasoning that a permissive form "can only widen
   what is found, never fail a ledger that reads correctly today". That reasoning was
   wrong, and a baseline run before writing any code is what showed it. Against a ledger
   whose prose quotes an example status line above its own, the unanchored search returns
   **the prose sentence** — a gate parsing it would read garbage phase ids and fail a
   correct ledger. Finding the wrong line is worse than finding none.

   The anchored form dominates both existing locators on every fixture: it finds the two
   legitimate placements the structural reader misses (a blank line after the title, a line
   further down the file) and refuses the sentence the unanchored search accepts. On all
   thirteen ledgers here it returns byte-identical results to the structural reader, so it
   is not a behaviour change in this repository at all — it only decides shapes this
   repository does not yet contain.

8. **Two written claims go false when the validator sources the library.** Contract v1.1
   line 17 says the script "travels with this document, so a repository that holds the
   Contract also holds the check", and `validate-briefs.sh:15` says "No dependency beyond a
   POSIX shell and grep." Both stop being true in `c`. v1.2 is already scheduled by the
   settled decisions, so the text lands there; the header comment is `c`'s to fix.

9. **`BRIEFS-9` is the first clause that reads `ledger.md`.** All eight existing clauses
   govern the briefs directory and `brief.md`. This widens what the Contract governs from
   "the record is well-formed" to "the ledger is internally consistent". Worth taking
   deliberately rather than as a side effect of adding a ninth item. `#0007` has no ledger,
   so the check must skip a brief that has not been started.
