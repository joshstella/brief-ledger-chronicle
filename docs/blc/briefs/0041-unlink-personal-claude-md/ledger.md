# Ledger — #0041 Machine mode stops linking the personal CLAUDE.md

`blc/2 #0041 done a:done`

**Brief:** `docs/blc/briefs/0041-unlink-personal-claude-md/brief.md`
**Status:** done
**Started:** 2026-10-19
**Closed:** 2026-10-19

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | the unlink | done | `brief/0041-a-the-unlink` | #162 |

**a — the unlink.** Machine mode stops linking `personal/CLAUDE.md` into `~/.claude/CLAUDE.md`.
In `install.sh` it removes the link, the source check, the line in the printed plan, the
conflict hint that says to merge into `personal/CLAUDE.md`, and the comment at `:664` that
gives the personal agreement as a reason for machine mode. Machine mode keeps the command
links and the brief README template. The file stays in the repository as an example to copy,
so its own header changes: it no longer says that the installer links it. The tests that use
the `CLAUDE.md` link as their proof of a machine install move to the brief README template
link. A new test proves the change: after a machine install, `~/.claude/CLAUDE.md` does not
exist, and a link that an old install made is left as it was. The architecture document
changes in the same phase, because its citation names the line that this phase removes.

## Dependency structure

One phase. Nothing is parallel and nothing is provisional.

## Settled in the brief

- Keep `personal/CLAUDE.md`. Remove only the link.
- Leave existing links alone. The machine step does not remove an old link and does not
  report it.

## Open decisions

None.

## Complications the brief does not name

- **Seven tests use the `CLAUDE.md` link as their proof.** Besides the two the brief names,
  `tests/test_machine_mode.sh` uses it to test the dangling-link replacement, the refusal to
  overwrite a real file, the refusal of a foreign symlink, the run without a toolchain and the
  declined prompt. Those tests test `link_into_place`, not the personal agreement. They move
  to `briefs/README.template.md`, so the guards stay tested.
- **The architecture check fails if its citation is left.** `docs/architecture/README.md:49`
  cites `install.sh :: $SCRIPT_DIR/personal/CLAUDE.md`, and
  `tests/test_check_architecture.sh` runs the check on this repository. Phase `a` rewrites
  that bullet.
- **`personal/CLAUDE.md` describes its own install.** Line 3 says the installer links it.
- **The author's machine depends on the old link.** `~/.claude/CLAUDE.md` here is a link to
  `personal/CLAUDE.md`. The settled decision keeps it working.

## Big decisions

**`README.md` does not change.** Decided 2026-10-19 at the review gate.

The brief lists a `README.md` update of the machine-mode description. The README does not
name the files that machine mode links. It says only that the step "wires up ~/.claude", and
that is still true after this phase. An edit would add a sentence about a file that the
installer no longer touches. The brief's line was written before anyone read the README text.

## Branches

`brief/0041-a-the-unlink`, cut from `main` at `91c66d3`.
`brief/0041-closeout`, cut from `main` at `11cf164`.

## Close, 2026-10-19

### What shipped

`install.sh --machine` does not write `~/.claude/CLAUDE.md` now. A person who runs the
machine step gets the command links and the brief README template, and does not get one
author's global instructions.

One phase, `a` (#162). The link, its source check, its line in the printed plan and its
conflict hint are removed. `personal/CLAUDE.md` stays, and its header says that it is an
example to copy. The seven tests that used the `CLAUDE.md` link to test `link_into_place` use
the brief README template link now. Two new tests prove the change.

Both settled decisions held. The work overturned one line of "What changes": `README.md` did
not change. See Big decisions.

### What the record shows that the brief did not predict

- **The link was the proof for five more tests than the brief named.** The brief named two
  tests. Seven used the link, and five of them tested the linking guards, not the personal
  agreement. The cost of the brief was mostly in moving those tests to a different link so
  that the guards stay tested. The removal itself was four small edits.
- **The README change in the brief was written without reading the README.** The README never
  named the linked files, so there was nothing to update. Planning found the architecture
  citation and the file's own header, but planning did not read the README. It was read only
  after the code was written.
- **The settled decision "leave existing links alone" has a cost on the author's machine.**
  The author's `~/.claude/CLAUDE.md` is still the old link. So the header edit in this phase
  changed the author's live global instructions. Those instructions now start with "An
  example to copy, not part of the install". The file still works, but on this machine it
  describes itself incorrectly.

### Open after close

- **A machine that ran the old step keeps the link and gets no notice.** This is the settled
  decision. But the brief exists because of a class, and a person who ran the old machine
  step before this change still has the author's instructions, with no message from any later
  run. The brief chose silence over a report. Nobody has checked if anyone in the class ran the
  old step.
- **`test_machine_leaves_an_old_personal_agreement_link_alone` asserts that "CLAUDE.md" does
  not occur anywhere in the install output.** A later output line that names `CLAUDE.md` for a
  different reason makes this test fail.
- No bug ledger (`review-<branch>.md`) was written. The review found no correctness bugs.

### What this cannot prove

- **The new tests were not run against the old `install.sh`.** From the old code, both fail
  there: the old code makes the link, and a re-run prints the `CLAUDE.md` label when it skips
  a correct link. That is a reading, not a run.
- **The full suite ran locally under mawk and gawk only.** original-awk and busybox are not
  installed here. CI (`install-sh`) passed on both commits of #162.
- **The review was written by the author of the code.** `blc-review-pr` returned Approve with
  suggestions. One suggestion, the `-f` comment, was fixed in #162 before the merge. The
  other is the open item above.
