# Ledger — #0035 orient exits 1 on macOS

`blc/2 #0035 done a:done(PR#148)`

**Brief:** `docs/blc/briefs/0035-orient-macos/brief.md`
**Status:** done
**Started:** 2026-10-08
**Closed:** 2026-10-08

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | posix sed guard | done | `brief/0035-a-posix-sed-guard` | [#148](https://github.com/joshstella/brief-ledger-chronicle/pull/148) |

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

## What shipped

One character in `tools/orient.sh`, and a test that watches for the shape
(`a`, [#148](https://github.com/joshstella/brief-ledger-chronicle/pull/148)).
`sed '1{/^# /d;}'` is what POSIX asks for and every sed accepts. `blc-orient` returns 0 on
macOS again, which also unblocks `blc-start-brief`, `blc-next-brief-phase` and `blc-review-pr`,
since each runs it first.

The guard reads every shipped shell file for sed scripts whose closing `}` has no `;` before
it. It tells that shape apart from a regex interval, from an awk block, from a shell brace
group, from a shell parameter expansion, and from prose in a comment — each of which is in the
tree and each of which the first version got wrong.

Every settled decision held.

## What the record shows that the brief did not predict

**The detector was harder than the bug by an order of magnitude.** The fix is one character.
The guard took three rewrites, and five of the six mutations run against it were about
telling a sed block from something that merely looks like one. The brief treated the guard as
the simple half.

**Two guards survived their first mutation, and the tests were wrong rather than the code.**
Dropping the `sed`-word requirement and dropping the quote-splitting both left the hand-fed
cases green, because a shell brace group always ends `; }` and the whitespace collapse already
covered those examples. The cases proved one guard three times and two guards not at all. Only
the real tree exposed it: `tools/lib/status-line.sh:185` and `tools/open-briefs.sh:134` each
fail one of them. A test file is a worse fixture than the repository it guards, when the
question is whether a check can tell real code apart from code that resembles it.

**The comment written to explain the fix was itself flagged.** Prose about a `}` is not a
script, and the detector could not tell until it read quoted strings only. The document and the
thing it documents failed the same check.

**A mutation that does not apply looks exactly like a mutation nothing catches.** The first run
of two of these reported no failures because the replacement text did not match and the file
was never changed. Every mutation afterwards asserted it had applied before the suite ran.
This is the second engagement where a silent no-op nearly passed for evidence; `#0034` had the
same shape with `perl` failing to compile.

**The declaration worked this time, and only because of one extra command.** It was written to
`docs/blc/state/` **and pushed** before `blc-create-brief` ran. In `#0034` the identical
declaration was written and cleared without ever being pushed, so nobody could have seen it.
Nothing in the toolkit requires the push. The difference between a claim and a private note is
one `git push`, and the record cannot tell which one happened.

## Open after close

- **A second sed has still never run this code.** A static check is not an interpreter.
- **CI already carries one.** `.github/workflows` records that `ubuntu-latest` ships gawk,
  mawk and busybox, and busybox provides a `sed`. A sed matrix may therefore cost nothing to
  install, which is a cheaper first step than a macOS runner. Whether busybox sed rejects this
  construct is untested — busybox could not be installed here to find out.
- **A macOS runner is still the honest answer**, and is out of scope by decision. It is the
  only thing that would have caught this before a person did.
- **Sixty-five other `sed` invocations are unexamined for anything but this shape**, and the
  guard was written after the bug was known.
- **Double-quoted sed scripts are not read.** Every one in the tree today is single-quoted.
- No bug ledger existed for the phase branch, so no open correctness bugs were carried.

## What this cannot prove

- **That the bug is fixed.** The failure was never reproduced in this repository. GNU sed
  accepts the construct even under `--posix`, and busybox could not be installed. The fix
  rests on the POSIX text, a report from one machine, and a line that matches the symptom.
  Confirmation has to come from the macOS checkout that saw it.
- **That no other platform problem is present.** `orient` was the only tool reported, and it is
  the only tool anyone is known to have run there. No report is not coverage.
