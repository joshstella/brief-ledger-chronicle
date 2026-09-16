# Ledger — #0014 The shape nothing prescribes
`blc/2 #0014 in-progress a:in-progress(brief/0014-a-the-shared-matcher) b:pending c:pending`

**Brief:** `docs/briefs/0014-the-shape-nothing-prescribes/brief.md`
**Started:** 2026-09-16
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the shared matcher | in-progress | `brief/0014-a-the-shared-matcher` |
| b | the clause | pending | — |
| c | the upgrade | pending | — |

**a — the shared matcher.** One implementation of the phase-row matcher in `tools/lib/`, read
by both `open-briefs.sh` and `validate-briefs.sh`, with a test that fails if the two ever
disagree. No behaviour change. Carries the installer and ownership-map work in complications
1 and 2 below.

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
- `tests/test_phase_row.sh` is new: 283 tests pass, up from 276.

**Scope call — `validate-briefs.sh` does not source it yet.** The brief's phase `a` says
the matcher is "used by both" tools, but `validate-briefs.sh` has no phase-row logic until
`BRIEFS-9` exists in phase `b`, so sourcing it now would add an unused import and phase
`a` would stop being provably behaviour-preserving. What phase `a` ships instead is the
guarantee that makes "used by both" enforceable when `b` arrives:
`phase_row_no_tool_defines_its_own_matcher` scans `tools/` for a re-derived pattern and
fails if one appears. The brief's agreement test belongs in `b`, where there are two
callers to disagree.

**b — the clause.** `BRIEFS-9`: every phase id in a status line is findable in the phase
table. Validator check citing the clause, Contract text, and tests — including the three
shapes #0013 left unmatched, which become failures instead of silences.

**c — the upgrade.** How an existing repository crosses into a clause that did not exist
yesterday. Blocked by open decision 2.

## Dependency structure

Strict chain: `a → b → c`. `b` needs the matcher; `c` needs the clause to exist before it
can decide how to introduce it.

## Open decisions

1. ~~Where the shared matcher lives.~~ Resolved on initiation; see the brief's settled
   decisions. The answer was forced rather than chosen — see complication 3.
2. **Whether `BRIEFS-9` gates immediately or reports for one version.** Blocks phase `c`.
   #0003 faced this question and demoted a gate to a report.

## Complications

Found on initiation, reading the brief against `main` at `afe97e4`. None were visible when
the draft was written. Phase `a` carries 1, 2, and 4.

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
