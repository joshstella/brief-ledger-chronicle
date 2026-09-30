# Ledger — #0016 The readers that guess

`blc/2 #0016 in-progress a:in-progress(brief/0016-a-the-identity-reader) b:pending c:pending d:pending`

**Brief:** `docs/briefs/0016-the-readers-that-guess/brief.md`
**Started:** 2026-09-30
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the identity reader | in-progress | `brief/0016-a-the-identity-reader` |
| b | the pointer vocabulary | pending | — |
| c | the forge probe | pending | — |
| d | the forge in prose | pending | — |

The phases follow the seam the brief names in Tension: `a` is the reader half, `b` is where the
two halves meet, and `c` and `d` are the forge half.

**a — the identity reader.** A tolerant shared reader in `tools/lib/`. It locates the identity
line and returns one field's value, ending at the next `·` (decisions 2, 7, 8).
`validate-briefs.sh` and `list-briefs.sh` both use it, and a guard proves no local re-derivation
survives. `validate-briefs.sh` is the only other reader in the tree. Two tests from #0007
phase `a` pin the greedy read this phase removes, and they have to be inverted, not deleted:
`a_hash_after_depends_on_becomes_a_dependency` and
`an_existing_serial_after_depends_on_is_swallowed_in_silence`. The README paragraph "`Depends on`
goes last" keeps its rule (decision 5) and loses its loud-and-quiet account, which stops being
true. The PR must state that `BRIEFS-6` examines less than it did (decision 8).

**b — the pointer vocabulary.** `open-briefs.sh` learns `!123` as a merge-request token
(decision 3). The parser checks every field it does not recognise instead of stopping at the
first one. A field that is not a PR, an MR or a commit and does not resolve as a branch is
reported as unrecognised, not as a missing branch (decision 4). The record format in
`docs/briefs/README.md` gains the token. No forge is called yet: `!123` is parsed and shown, and
its state is reported as not checked.

**c — the forge probe.** Detection per decision 9: take the remote's host, and ask
`gh auth status --hostname <host>` and `glab auth status --hostname <host>`. Both report
through the exit code, so nothing parses their output. `open-briefs.sh` then looks up PR state
through `gh` or MR state through `glab`. If neither matches, the tool says it did not check,
as it already does when `gh` is absent. Tests use stub CLIs on `PATH`, the technique from
#0015.

**d — the forge in prose.** `blc-commit-push-pr`, `blc-review-pr` and `blc-next-brief-phase`
stop naming one forge. `README.md`, `docs/slides-process-overview.md` and the `install.sh`
dependency hint list `glab` beside `gh`. How a skill learns which forge it is on is decision 11,
below.

## Dependency structure

`a` is independent of everything else. It touches the identity line; `b`, `c` and `d` never read
it.

`b → c → d` is a strict chain. `c` needs `b`'s token before there is an MR to look up, and `d`
needs `c`'s detector before a skill can be told which CLI to use.

So there are two tracks: `a` alone, and `b → c → d`. **They run one after the other: `a` first,
then the chain.** Decided 2026-09-30. The two tracks do not depend on each other, but running
them at once would conflict on the status line every time; see the complications.

## Open decisions

The brief settled nine at filing. These three came from reading the code and block the phase
named.

| # | decision | blocks |
|---|---|---|
| 10 | **Settled 2026-09-30: it moves.** `BRIEFS-5` checks the shared reader's field values. | `a` |
| 11 | Does detection ship as a program a skill can run, or only as a sourced library? | `c` |
| 12 | Is PR/MR state normalised to one vocabulary, or printed as each CLI reports it? | `c` |

**10 — settled: move.** One reader means one reader, including for the `[defect]` clause.
"One reader" argues for moving the checks. `BRIEFS-5` is a `[defect]` clause, and moving
it changes a gate. The existing negative fixtures in `tests/test_briefs.sh` pin every current
`BRIEFS-5` failure, so a move that changes behaviour will fail them. That makes the move safe to
attempt, not free.

**11.** A skill is an instruction to an agent and cannot source a library. Without a program,
every skill that needs the forge describes detection in prose. That is a second detector, and
"a skill guard is not a check" applies. A program is a new tool, and the #0007 re-plan counted
four coordinated `install.sh` edits for each one: roster, prune list, summary, and skill list.

**12.** `gh` reports `OPEN`/`MERGED`/`CLOSED`. `glab` reports `opened`/`merged`/`closed`.
`open-briefs.sh` output is read by people, and two spellings of one state in one report is
noise.

## Complications

**Parallel tracks and one status line.** Every phase branch edits the ledger's status line. The
previous phase is marked `done` on the next phase's branch. Branches running at the same time
will therefore conflict on that one line every time. The conflicts are trivial, but they are
certain. Running `a` first, alone, costs one PR of calendar time and avoids them.

**This brief rewrites #0007's work, and #0007 is still open.** #0007 phase `a` wrote the README
paragraph and the two tests that phase `a` here changes. #0007 phase `b` moves the `Jira:`
append before `Depends on` for a reason that stops being true once this brief's phase `a` lands.
The move is still right, because decision 5 keeps the rule as a backstop. Its stated reason will
need correcting in #0007's ledger when that phase is planned.

**#0007 phase `c` should read `Owner:` through this brief's reader.** It is a new reader of an
identity-line field. If it lands first, it lands as a third local parser, which is exactly the
drift this brief exists to close. Phase `a` here should land before #0007 phase `c` starts.

**Unverified: what `auth status --hostname` actually checks.** Both CLIs document the flag and
report through the exit code; that much was checked locally. Whether each validates the token
against the host or only reads local config was not checked, because it needs the network.
That difference decides whether an expired token counts as a match (see decision 9) and has to
be settled in `c` before the fallback is written.
