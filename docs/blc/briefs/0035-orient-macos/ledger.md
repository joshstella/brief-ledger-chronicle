# Ledger — #0035 orient exits 1 on macOS

`blc/2 #0035 pending a:pending`

**Brief:** `docs/blc/briefs/0035-orient-macos/brief.md`
**Status:** pending
**Started:** 2026-10-08

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | posix sed guard | pending | — | — |

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
