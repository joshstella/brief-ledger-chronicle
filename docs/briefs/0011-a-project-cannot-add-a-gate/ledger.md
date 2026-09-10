# Ledger — #0011 A project cannot add a gate
`blc/2 #0011 in-progress a:done(PR#53) b:pending`

**Brief:** `docs/briefs/0011-a-project-cannot-add-a-gate/brief.md`
**Started:** 2026-09-10
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the runner | done(PR#53) | `brief/0011-a-the-runner` |
| b | the proof | pending | — |

**a — the runner.** `validate-briefs.sh` runs `brief-checks/*.sh` after toolkit clauses
pass, in sorted order, failing on any non-zero exit. Document the directory, argument, exit
convention, and installer non-touch in `docs/briefs/README.md`. Record `brief-checks/` in the
ownership map as project-owned.

**b — the proof.** Tests: passing, failing, crashing, and ordered scripts; absent and empty
directory; a script cannot clear a toolkit defect; install leaves `brief-checks/` unmodified.

## Dependency structure

Strict chain: `a → b`. Phase `b` depends on the runner existing.

## Open decisions

None in the brief. All settled at filing.

## Complications

None found at initiation. #0012 is done — ownership map and replace policy are in place.

## Phase a — what it does

**Runner wired.** `validate-briefs.sh` calls `brief-checks/*.sh` after toolkit clauses pass,
sorted, failing on non-zero exit with the script's output under its filename.

**Ownership recorded.** `brief-checks/` added to the ownership map as project-owned.

**Documented.** `docs/briefs/README.md` carries the directory, argument, exit convention,
installer non-touch, and an example snippet (no example script ships).
