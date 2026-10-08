# Ledger — #0035 orient exits 1 on macOS

`blc/2 #0035 in-progress a:in-progress(brief/0035-a-posix-sed-guard)`

**Brief:** `docs/blc/briefs/0035-orient-macos/brief.md`
**Status:** in-progress
**Started:** 2026-10-08

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | posix sed guard | in-progress | `brief/0035-a-posix-sed-guard` | — |

**a — posix sed guard.** Corrects `tools/orient.sh:276` to `sed '1{/^# /d;}'`, which POSIX
requires and every sed accepts, and adds a test that reads the shipped shell for sed brace
blocks whose closing `}` has no `;` before it. The test must not confuse a regex interval such
as `\{10\}` with a block close, because one of those is in `tools/orient.sh` already and a
guard that flagged it would be reverted the first time somebody ran it. Touches
`tools/orient.sh` and one test file.

## Dependency structure

One phase. Nothing to sequence.

## Decisions settled before planning

- **The fix and the guard ship together.** A one-character correction with nothing watching
  it leaves the project where it was before the report.
- **The guard is static, not a second interpreter.** It runs on the CI that exists.
- **Ship on the diagnosis, without a local reproduction.** GNU sed accepts the construct even
  under `--posix` and busybox could not be installed here, so the failure was never watched.
  POSIX is unambiguous, the reported symptom matches the line, and the corrected form is valid
  on every sed, so it cannot regress the one interpreter CI runs.

## Open decisions

- **What the guard covers.** *Resolved before `a` was written.* The brace-block shape only. A
  scan found no other GNU-only sed construct in the tree — no `\+`, `\?`, `\|`, `\s`, and no
  `sed -i`. A guard for shapes that do not appear would ship having never failed, which this
  project treats as unproven by definition. The guard is written so a second shape can be
  added when a second shape is found.

## Out of scope, recorded

- **A macOS CI runner.** It is the only thing that would have caught this before a person did,
  and it would give all sixty-six `sed` invocations a second implementation rather than
  covering one shape of one bug. It is a larger change than this brief and belongs in its own.
  Recorded here so the gap is not mistaken for coverage.
- **Every other tool on macOS.** None was reported as failing. None was tested either. No
  report is not the same as coverage.

## Complications found while reading the code

- `tools/orient.sh:147` contains `\(.\{10\}\)`, a POSIX regex interval. It is correct and it
  looks like a block close to a naive scan. The guard must tell them apart, and this line is
  the fixture that proves it does.
- `tools/lib/status-line.sh:125` holds an awk block with the same brace shape. The guard reads
  sed invocations only, and this line is why that scoping has to be deliberate.
- The awk matrix in `tests/run.sh` covers five candidates. The premise behind it — that one
  interpreter cannot see a portability bug — is this brief's premise too, applied to the
  interpreter that never got a matrix.

## Observed while filing

The `docs/blc/state/` declaration was written **and pushed to `main`** before
`blc-create-brief` ran, then cleared when the brief was filed. In `#0034` the same declaration
was written and cleared without ever being pushed, so nobody could have seen it. The
difference is one `git push`, and nothing in the toolkit requires it.

## Settled while building `a`

**The first detector read whole lines and was wrong three ways.** It flagged
`tools/open-briefs.sh:135`, where the brace closes a shell function, and `tools/orient.sh:119`,
where `$closed` contains the letters s-e-d. It now requires `sed` as a word and examines only
the single-quoted scripts on the line. Every sed script this toolkit ships is single-quoted; a
double-quoted one would be missed, and that limit is stated rather than hidden.

**Two guards inside the detector survived their first mutation, and the tests were wrong, not
the code.** Removing the `sed`-word requirement and removing the quote-splitting both left the
hand-fed cases green. The reason is that a shell brace group always ends `; }`, so the
whitespace collapse already covered those two examples — the cases proved one guard three
times and two guards not at all.

Re-run against the real tree, both guards proved load-bearing. Without the word requirement,
the awk block at `tools/lib/status-line.sh:185` is flagged. Without quote-splitting, the shell
parameter expansion `${1#*:}` at `tools/open-briefs.sh:134` is flagged, and so is the comment
written to explain this very fix, because prose about a `}` is not a script. Three hand-fed
cases were then added for exactly those shapes, so editing those files cannot quietly retire
the proof.

**A mutation that does not apply looks the same as a mutation nothing catches.** The first run
of these two reported no failures because the replacement text did not match and the file was
never changed. Every mutation after that asserted it had applied before the suite ran. This is
the second engagement in which a silent no-op nearly passed for evidence.

**Mutation results.** Reverting the fix in `tools/orient.sh` fails the scan. Dropping the
`sed`-word requirement, the quote-splitting, the backslash exclusion, or the whitespace
collapse each fails the detector's own cases. A detector that reports nothing fails both
positive cases. Six mutations, six caught, no survivors.

## Not proven by `a`

- **The failure was never reproduced.** GNU sed accepts the construct even under `--posix`,
  and busybox could not be installed here. The fix is shipped on the POSIX text, the reported
  symptom and the matching line. Nothing in this repository has watched it fail.
- **The guard covers one shape.** It finds a block close with no `;`. It says nothing about
  the other sixty-five `sed` invocations or about any GNU-only construct that is not this one.
- **No sed but GNU has run this code.** CI is `ubuntu-latest` and there is no macOS runner. A
  static check is not a second interpreter, and this project already holds that one
  interpreter cannot see a portability bug — which is why `tests/run.sh` matrices awk.
