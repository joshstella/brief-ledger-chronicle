# orient exits 1 on macOS

**Serial:** #0035 · **Created:** 2026-10-08T22:22:58Z · **Author:** josh.stella@gmail.com · **Depends on:** —

A contributor ran `blc-orient` on macOS. It printed the state of the repository correctly,
then exited 1. The failure is in the last section:

    tools/orient.sh:276    sed '1{/^# /d}' "$AUTHORED"

POSIX requires a `;` or a newline before a closing `}` in a sed script. GNU sed accepts the
construct without one. BSD sed, which macOS ships, rejects it. `set -euo pipefail` on line 18
turns the rejection into exit 1.

This is not cosmetic. `orient` is step 1 of `blc-start-brief`, `blc-next-brief-phase` and
`blc-review-pr`. On macOS the toolkit fails at its own first gate.

## The finding behind the bug

`tests/run.sh` runs an awk matrix over five candidates — `awk gawk mawk original-awk busybox`
— built on the premise that one interpreter cannot see a portability bug. The premise is
correct and the investment is real.

**There is no equivalent for sed.** Twelve shipped files hold sixty-six `sed` invocations, and
every one of them has only ever run against GNU sed, because CI is `ubuntu-latest` and nothing
else. The project bought a matrix for one interpreter and left the other untested.

A scan found exactly one POSIX-invalid construct, the line above. That is a good result and it
is not evidence of safety: the scan was written after the bug was known, and it looks for the
one shape that bug had.

## Settled before filing

1. **The fix and a guard, together.** A one-character fix with nothing watching it is the
   same position the project was in yesterday.
2. **The guard is static, not a second interpreter.** It reads shipped shell for sed brace
   blocks whose `}` has no `;` before it, and it must not confuse a regex interval `\{10\}`
   with a block close. A static check runs on the CI that exists. A macOS runner is the
   better answer and a larger one.
3. **Ship on the diagnosis.** The failure was not reproduced here: GNU sed accepts the
   construct even under `--posix`, and busybox could not be installed. POSIX is unambiguous,
   the line matches the reported symptom, and the corrected form is valid on every sed, so it
   cannot regress the interpreter CI does run.

## Open

- Whether the guard covers only the brace-block shape or the wider set of GNU-only sed
  constructs — `\+`, `\?`, `\|`, `\s`, `-i` without an argument. A scan found none of those
  today, so a guard for them would ship having never failed.
- Whether a macOS runner belongs in this brief or its own. It is the only thing that would
  have caught this before a person did, and it would give the sixty-six invocations a second
  implementation rather than one shape of one bug.

## Out of scope, recorded

The reporter's `orient` output was otherwise correct, so nothing else is suspected. No other
tool was reported as failing, and no other tool was tested on macOS either — absence of a
report is not coverage.
