# Ledger — #0014 The shape nothing prescribes
`blc/2 #0014 pending a:pending b:pending c:pending`

**Brief:** `docs/briefs/0014-the-shape-nothing-prescribes/brief.md`
**Started:** 2026-09-16
**Status:** pending

Pending, not in-progress: open decision 1 blocks phase `a`, which is the first phase, so
no branch is cut yet. Nothing is in flight under this serial.

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the shared matcher | pending | — |
| b | the clause | pending | — |
| c | the upgrade | pending | — |

**a — the shared matcher.** One implementation of the phase-row matcher, read by both
`open-briefs.sh` and `validate-briefs.sh`, with a test that fails if the two ever disagree.
No behaviour change. Blocked by open decision 1.

**b — the clause.** `BRIEFS-9`: every phase id in a status line is findable in the phase
table. Validator check citing the clause, Contract text, and tests — including the three
shapes #0013 left unmatched, which become failures instead of silences.

**c — the upgrade.** How an existing repository crosses into a clause that did not exist
yesterday. Blocked by open decision 2.

## Dependency structure

Strict chain: `a → b → c`. `b` needs the matcher; `c` needs the clause to exist before it
can decide how to introduce it.

The sequence past `a` is provisional in one respect: if open decision 1 resolves toward a
new `tools/lib/`, phase `a` grows the installer work listed under complications below, and
that work may deserve its own phase rather than riding inside `a`.

## Open decisions

1. **Where the shared matcher lives.** Blocks phase `a`. Stated in the brief as a choice
   between duplication-plus-agreement-test and a new `tools/lib/`. See complication 3 —
   the first option appears to contradict a settled decision, so this may be narrower than
   the brief presents it.
2. **Whether `BRIEFS-9` gates immediately or reports for one version.** Blocks phase `c`.
   #0003 faced this question and demoted a gate to a report.

## Complications

Found on initiation, reading the brief against `main` at `afe97e4`. None were visible when
the draft was written.

1. **`tools/lib/` is not a free path.** The ownership map hardcodes the four tools at
   `install.sh:343-346`; a fifth entry is a hand edit there. `install.sh:856` runs
   `chmod +x` on everything it places under `tools/`, which a sourced library does not
   want. `install.sh:724` prints the tool names in the pre-install summary.
   `test_ownership_map.sh` asserts the map and the install agree in both directions, so
   each of those is load-bearing rather than cosmetic.

2. **A sourced library would fail a test merged the same day.** `tests/test_source_tree.sh`
   (`afe97e4`) asserts that every `*.sh` outside `tests/` is mode `100755` in the git
   index, because it treats everything there as invoked. A `tools/lib/matcher.sh` is
   sourced, not invoked, so it would need an exemption. The brief predates that test by
   hours and cannot have counted this.

3. **Open decision 1's first option contradicts a settled decision.** The settled
   decisions say *"One matcher, shared. Two implementations would reproduce #0013's second
   defect on purpose."* Open decision 1 then offers *"duplicated in both tools with a test
   asserting they agree"* as a live option. Under the consumption protocol a settled
   decision is fixed, which would rule that option out and leave decision 1 with one
   answer. Either the settled decision means shared *behaviour* rather than shared
   *source*, or the option is already closed. This needs the author, not a guess.

4. **A third arrangement is unlisted.** The matcher could live in one tool and be reached
   by the other through a subprocess, with no new path and no installer change. It is not
   obviously right — it couples the gate to the reporter's interface, and the brief settles
   that `open-briefs.sh` does not become a gate — but it was not considered on the record.
