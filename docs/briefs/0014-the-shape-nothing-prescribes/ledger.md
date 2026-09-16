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

### Phase b — what it does

- `tools/lib/status-line.sh` holds `blc_status_line`: whole-file search, anchored match,
  code fences skipped, leading whitespace stripped and every backtick removed, so callers do
  not each re-decide what to trim.
- `open-briefs.sh` lost its positional `status_line()`; its bootstrap now loads a list of
  libraries rather than one. `list-briefs.sh` lost its unanchored `grep` and gained the same
  bootstrap — which is the one thing that cannot be shared, being the code that finds the
  shared code. The duplication is accepted deliberately; keeping the copies *identical* is
  the part that needed saying, and did not hold on the first attempt — see complication 10.
- `install.sh` ships the new library through the ownership map. Dropping that row is caught
  by `status_line_an_installed_list_briefs_finds_its_library` and by
  `orient_runs_inside_a_fresh_install`.
- `tests/lib.sh` gains `fixture_install_tool`. Two fixtures hand-copied `list-briefs.sh`
  alone and broke the moment a tool became two files; the helper keeps the next such tool
  from breaking them again.
- **Orient is unaffected:** its output is byte-identical to `main` — 45 lines, 270 words,
  1683 bytes — and five runs take 2.021s against 2.018s. The positional read was a cost
  rule about file I/O, never about tokens, and `grep -m1` stops at the first match, so a
  normal ledger still costs two lines.
- 312 tests pass, up from 290. Seven mutations, each failing only its intended tests.

### Phase b — what review found, and it was the same defect twice

Three findings, all of them the shape this brief exists to address: a record that says a
property is held, and no mechanism holding it.

1. **The agreement test could not detect disagreement.** It ran both tools per ledger, then
   discarded one result with `: "$in_open"`, so the only live assertion concerned
   `list-briefs.sh`. Blinding `open-briefs.sh` entirely failed eighteen other tests and left
   this one green. It is phase `a`'s defect one phase later, under a name claiming the
   opposite — and worse than phase `a`'s, because a later phase owing an agreement test
   would have found one already written. Rewritten against the five shapes that used to
   divide the two readers; this repository's own ledgers agreed under *both* old locators
   and could therefore never have proved anything.
2. **`list-briefs.sh`'s symlink walk had no test.** Phase `a` added that walk to
   `open-briefs.sh` after review found the missing property, and pinned it. Phase `b` copied
   the walk into the second tool and copied no test: replacing it with a plain `dirname`
   left all 303 tests green while the tool broke when reached through a link. The lesson
   from `a` was recorded in a test named after one tool, so the second tool did not inherit
   it.
3. **The anchor did not defeat a fenced example.** Prose in front of an example loses to the
   anchor; an example at column 0 inside a fence does not — and that is precisely how
   `docs/briefs/README.md` prints the status line. A ledger documenting its own format would
   have handed both readers `#9999`. Nothing here does it yet, which is the only reason it
   was invisible. The locator now tracks fences.

**The control worked.** Moving the locator from `grep` to `awk` required escaping the slash,
which left `SL_FINGERPRINT` no longer matching the library it fingerprints — the identical
stale-pattern defect phase `a` shipped. This time the two positive controls added after that
review failed on the next run and named it. That is the mechanism doing its job unprompted,
and the reason the controls stay.

**Reversal — the unterminated-frontmatter test.** `open-briefs.sh` reported `[no-line]` for
a ledger whose frontmatter never closes, and a test asserted that was correct. It was not a
decision, it was half of a disagreement: `list-briefs.sh` read the same ledger and reported
its status as `done`. The skip is unbounded when the block never closes, so one stray `---`
hid a ledger's whole status from one tool and not the other. Resolved toward finding the
line, which is what the anchored locator does; the test is inverted and carries the history.

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

10. **The two bootstrap copies drifted in the commit that created the second one.** The
    duplication is accepted — it is the code that finds the shared code, so it cannot be
    shared. What was not accepted, and not noticed, is that the copies differed: one used
    `printf` and the other `echo`, one carried the comment explaining relative link targets
    and the other dropped it, one looped over a library list and the other hardcoded a path.
    The ledger said `list-briefs.sh` "gained the same bootstrap". It had not. Now aligned to
    character-identical apart from the exit status, which each tool documents separately.
    Phase `c` writes the third copy and will copy from one of these two.

11. **A malformed frontmatter block no longer draws any complaint.** Inverting the
    unterminated-frontmatter test was right — `main` did not merely stay silent, it counted
    that ledger as drift while `list-briefs.sh` reported it `done`, so the old behaviour was
    a false finding rather than a missing one. But the block is still malformed, and phase
    `b` converted a stated problem into an unstated one. No clause complains about it.
    Unowned; not scheduled.
