# Ledger — #0037 The declarations orient counts are files, not claims

`blc/2 #0037 in-progress a:in-progress(brief/0037-a-live-declarations)`

**Brief:** `docs/blc/briefs/0037-live-declarations/brief.md`
**Status:** in-progress
**Started:** 2026-10-14

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | live declarations | in-progress | `brief/0037-a-live-declarations` | — |

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
