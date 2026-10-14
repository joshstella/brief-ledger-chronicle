# Ledger — #0037 The declarations orient counts are files, not claims

`blc/2 #0037 done a:done`

**Brief:** `docs/blc/briefs/0037-live-declarations/brief.md`
**Status:** done
**Started:** 2026-10-14
**Closed:** 2026-10-14

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | live declarations | done | `brief/0037-a-live-declarations` | #154 |

**a — live declarations.** `tools/orient.sh` lists every non-empty file in `docs/blc/state/`
under **Picked up, not yet filed**, whether or not that file claims anything, so a contributor
who cleared their declaration down to its header keeps appearing as open work on every run.
This phase makes the program count claims rather than files: line 152 already computes the
claim lines and throws them away, so the fix keeps that output, skips the file when it is
empty, and counts only when it is not. It completes the sentence in `blc-create-brief` and
`blc-close-brief`, which say to delete an entry and do not say what to do when that entry was
the last one — the drift that produces the stub. It adds the fixture for a declaration that
claims nothing, which no test has ever built. It touches `tools/orient.sh`,
`skills/blc-create-brief/SKILL.md`, `skills/blc-close-brief/SKILL.md` and
`tests/test_orient.sh`.

## Dependency structure

One phase. The three changes are the same finding and are small enough to read at once.

The two skill edits are independent of the code and could have been a parallel track. With one
person working, a second branch buys a second review and a second CI run and nothing else.

Splitting the fixture from the fix was the other option and is worse: the fixture is the test
for the fix, so the first phase would ship a test that fails by design.

## Settled before `a` began, 2026-10-14

- **Any `##` heading is a claim, whatever it says.** A declaration that reads "nothing picked
  up" still counts as live. Liveness stays structural, derived from the entry shape the
  directory already uses, rather than matched against prose a person wrote in whatever words
  they chose that day. `docs/blc/state/README.md:70` already gives the answer to emptiness:
  delete the file. A declaration that describes its own emptiness is a file to remove, not a
  phrase to recognise.
- **The heading stays unconditional.** `### Picked up, not yet filed` prints above "Nobody has
  declared unfiled work." The other sections of `orient` print their heading and then say the
  section is empty, and a heading that hides itself would be the odd one out.
- **No `brief-checks/` script fails on a stub.** `docs/blc/state/` is per-contributor state.
  A gate that fails on another person's file is a gate the person who hit it cannot clear, and
  the repository already reports declaration age rather than enforcing it.

## Open decisions

None.

## Complications found while planning

- **`[ -s "$f" ]` at `tools/orient.sh:142` is not the liveness test and must not become it.**
  It rejects a zero-byte file. The reported stubs carry a header and prose, so they pass it.
  The test that matters is whether the `sed` on line 152 printed anything.
- **The count and the print are the same work.** Line 152 prints the claims and line 153
  increments. Capturing the output to decide both is one change, not two, and a fix that
  counts separately would read the file twice to answer one question.
- **No fixture has ever fed `orient` a state file that claims nothing.**
  `tests/test_orient.sh:47` builds every declaration as
  `printf '# %s\n\n## 2026-09-09 — %s\n'`, so every fixture is live. That is why a defect this
  visible survived in the output everybody reads first.
- **The skills do not contradict the README; they stop one sentence short of it.** The fix is
  to complete an instruction, not to correct one, and the wording should not read as though
  the skills were wrong.

## Branches

`brief/0037-a-live-declarations`, cut from `main` at `80ed157`.
`brief/0037-closeout`, cut from `main` at `38311d6`.

## Close, 2026-10-14

### What shipped

`orient` counts claims rather than files. A contributor who cleared their declaration down to
its header no longer appears under **Picked up, not yet filed** on every run.

One phase, `a` (#154). It captured the output the program already computed on the line that
prints a declaration's entries, skipped the file when that output is empty, and counted only
when it is not. It completed the sentence in `blc-create-brief` and `blc-close-brief`, which
said to delete an entry and did not say what to do when that entry was the last one. It added
the fixtures.

All three decisions settled before the phase held, and none was re-opened while writing it.

### What the record shows that the brief did not predict

- **The brief was wrong that no fixture had ever covered this.** It said no test fed `orient` a
  declaration that claims nothing. `tests/test_orient.sh` already had
  `orient_ignores_an_emptied_declaration`, which builds a zero-byte file. The real gap was
  narrower and more specific: a file that is **not** empty and still claims nothing, which is
  what clearing an entry by hand leaves behind, and which `[ -s "$f" ]` passes. A fixture that
  looked adjacent to the case was part of why the case read as covered.
- **"Capture the output" was two decisions, not one.** The brief described the fix as keeping
  the `sed` result instead of discarding it. Where to keep it mattered as much: read after the
  age computation, a file that is never reported still pays for a `git log`, and that section
  is the only per-file log in the cheap read. The review gate found it; the brief did not
  anticipate that the fix had an ordering at all.
- **The fix made an existing guard redundant and the brief did not see it coming.** The brief
  named `[ -s "$f" ]` as "not the liveness test" and warned it must not become one. It is now
  subsumed by the claims check, because a zero-byte file has no `##` entries either.
- **All three open questions resolved without argument.** That is unusual enough to record. The
  one that could have grown the work — a `brief-checks/` script failing on a stub — was
  declined on a principle the repository had already written down, that a gate failing on
  another person's file is one the person who hit it cannot clear.

### Open after close

- **The repository that reported this still has its stub files.** This change makes `orient`
  ignore them. It does not remove them, and nothing prunes `docs/blc/state/`. Anything else
  that reads that directory by counting files will still count them.
- **The skills half is unenforceable by construction.** The test that covers it asserts a
  string appears in two files. It stops the sentence going missing. It cannot show an agent
  follows it, and this drift came from an agent following an instruction literally.
- **`[ -s "$f" ]` at `tools/orient.sh:142` is now redundant.** It stays because it avoids a
  `sed` on an empty file, but `orient_ignores_an_emptied_declaration` no longer distinguishes
  which of the two guards catches that case.
- No bug ledger (`review-<branch>.md`) was written. There were no surviving correctness bugs,
  but step 4 of the close had nothing to read.

### What this cannot prove

- **The fix has never run against the files that prompted it.** It was verified against
  synthetic fixtures written from the report, not against the reporting repository's own
  declarations. The report described a header and prose; a stub shaped some other way, with a
  `##` heading that disclaims in words, is reported as a live claim by design.
- **The review was written by the author of the code.** `blc-review-pr` returned Approve with
  suggestions, and one independent pass — Bugbot — found no bugs. No person read the diff
  before it merged.
- **The mutation check shows coupling, not coverage.** Reverting `orient.sh` fails exactly the
  two new behavioural tests, which shows they are tied to the change. It does not show they
  cover the cases nobody thought of.
