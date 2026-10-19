# Ledger — #0041 Machine mode stops linking the personal CLAUDE.md

`blc/2 #0041 in-progress a:in-progress(brief/0041-a-the-unlink)`

**Brief:** `docs/blc/briefs/0041-unlink-personal-claude-md/brief.md`
**Status:** in-progress
**Started:** 2026-10-19

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | the unlink | in-progress | `brief/0041-a-the-unlink` | — |

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
