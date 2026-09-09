# Ledger — #0012 An install is not an update
`blc/2 #0012 pending a:pending b:pending c:pending d:pending`

**Brief:** `docs/briefs/0012-an-install-is-not-an-update/brief.md`
**Started:** 2026-09-09
**Status:** pending

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the ownership map | pending | — |
| b | the replace | pending | — |
| c | the prune | pending | — |
| d | the socialization | pending | — |

**a — the ownership map.** One declared list naming every path the toolkit owns, and the
project-owned paths it must never write after creation. Replaces knowledge currently spread
across `install.sh`'s template preflight, `SCAFFOLD_DIRS`, the ship loops, and the summary
echoes. Reading only — no placement behaviour changes. Touches `install.sh` and adds tests
that the map agrees with what the install actually writes.

**b — the replace.** Toolkit-owned paths are written on every run instead of skipped.
`place_file` and `place_dir` change default behaviour; project-owned paths keep
`write_project_stub`'s never-write protection. Settles what `--force` still means.

**c — the prune.** Remove toolkit-owned paths that a previous log entry recorded and the
current source no longer ships. Refuse without a log. Never follow a symlink out of the
target. Record removals in the run's own log entry.

**d — the socialization.** Shipped rules, installer output, and `README.md` state that
local edits to toolkit-owned files do not survive an install, and point at the two supported
customization routes (`AGENTS.md`, and `brief-checks/` once #0011 lands).

## Dependency structure

Strict chain: `a → b → c → d`.

`b` and `c` are logically independent — one changes writing, the other adds removal — and
could have been parallel tracks. They are serialized anyway because both rewrite the same
region of `install.sh`, and a two-branch merge there is a conflict with no owner. This is
the one-writer-per-file rule applied to a branch pair rather than a file pair.

`c` after `b` also avoids the worst intermediate state: pruning before replacing would
remove a project's stale skills while leaving the surviving ones un-updated.

`d` last because it describes the behaviour `b` and `c` create.

## Open decisions

1. **What does `--force` mean once the default replaces?** It may have no job left, or it
   may become the flag that overrides project-owned protection. **Blocks `b`.**
2. **Does the prune cover shipped docs and tools, or only skills and commands?** The log's
   `### Created` list reaches further than its skills list. **Blocks `c`.**
3. **Is there a dry run, and is it the first release?** Reporting the difference without
   removing is releasable on its own. **Blocks `c`.**

`a` is unblocked.

## Complications found in the code

1. **The installer states the opposite intent in a comment, as a rationale.**
   `install.sh:329–333` explains that skills are copied per-project rather than linked
   *"so a project can tune its own copy"*, and that `--force` is *"the explicit opt-in to
   take this checkout over those copies"*. That is the design this brief reverses, written
   down as justification. Machine mode's reason for not linking skills rests on the same
   sentence and collapses with it. `d` must rewrite it; `a` and `b` must not leave it
   standing while the behaviour contradicts it.

2. **Ownership knowledge sits in at least five places today.** The template preflight list
   (`install.sh:438–450`), `SCAFFOLD_DIRS` (`556–562`), the ship loops in steps 5–6, the
   pre-confirmation summary (`504–508`), and the closing summary. If `a` adds a map without
   removing these, it has added a sixth copy of a fact — the exact failure the map exists to
   prevent. The map must be the source these read from, not a parallel declaration.

3. **`place_dir` already does `rm -rf` under `--force`.** Flipping the default in `b` makes
   that the common path, so every skill directory is deleted and recopied on every run. The
   brief accepts the loss of files a project put inside a skill directory; what changes is
   that it stops being an opt-in and starts being routine.

4. **Machine mode is absent from the brief.** It links rather than copies
   (`link_into_place`, `install.sh:239`), so "replace" and "prune" mean different things
   there — removing a link is not removing a copy, and a prune that misreads one for the
   other deletes the source. The brief's phases are written as if every install copies.
   Needs a decision by `c`, and possibly a scope note in `a`.

5. **Prune parses log labels, not paths.** `### Created` records whatever string
   `log_created` was handed. Parsing it for removal assumes those labels have always been
   stable, path-shaped, and unambiguous. Any past wording change makes an old entry
   unparseable, and the brief's "no log, no removal" rule does not cover "log present but
   unreadable".

6. **Count-based assertions will move.** `CREATED` / `SKIPPED` / `REPLACED` feed both the
   summary and the log entry. After `b`, skipped collapses toward zero and replaced grows.
   Any test asserting those counts breaks for the right reason and must be re-baselined
   rather than relaxed.

## Notes

Brief #0011 depends on this one — `brief-checks/` needs the ownership map from `a` to record
a path the installer promises never to touch. Phase `a` should treat "never written" as a
first-class category in the map, not as the absence of an entry.
