# Ledger — #0012 An install is not an update
`blc/2 #0012 in-progress a:done(PR#50) b:done(PR#51) c:done(PR#51) d:in-progress`

**Brief:** `docs/briefs/0012-an-install-is-not-an-update/brief.md`
**Started:** 2026-09-09
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the ownership map | done(PR#50) | `brief/0012-a-the-ownership-map` |
| b | the replace | done(PR#51) | `brief/0012-bc-replace-and-prune` |
| c | the prune | done(PR#51) | `brief/0012-bc-replace-and-prune` |
| d | the socialization | in-progress | `brief/0012-d-the-socialization` |

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

1. ~~What does `--force` mean once the default replaces?~~ **Resolved 2026-09-10: retire
   it.** Phase `b` removes the flag.
2. ~~Does the prune cover shipped docs and tools, or only skills and commands?~~
   **Resolved 2026-09-10: skills and commands only.** The brief's claim names those two
   lists as the ownership evidence for removal; `### Created` includes scaffold dirs that
   must never be pruned.
3. ~~Is there a dry run, and is it the first release?~~ **Resolved 2026-09-10: no.**
   `--print-ownership` is the static half; removal ships with the first prune release.

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

## Phase a — what it found

**The two-column table in the brief did not survive contact with the code.** The installer
appends to `.gitignore` and the install log on every run. The map declares a third owner,
`append`. Resolved 2026-09-10: keep three owners; the brief's table is corrected to match.

**Six copies were found and four were removed.** The template preflight, the docs ship
loop, the tools ship loop, the skill placement loop, and the install log's skill list all
now read the map. Two remain by design: `SCAFFOLD_DIRS` (creates empty containers rather
than placing files; folding it in would have changed behaviour) and the pre-install summary
(prose kept readable; pinned with a test instead of derived).

**The pre-install summary keeps its prose**, per the decision to pin it with a test rather
than derive it. `ownership_map_backs_every_path_the_summary_promises` fails if the summary
names a path the map does not know.

**One behaviour changed, deliberately.** The old preflight checked
`templates/.claude/settings.local.json` on every host. The map only names it on a Claude
host, so a Cursor install with that template missing no longer aborts. It never used it. The
map made the check honest rather than broad.

**`--print-ownership` was added.** The map is a shell function inside a script that runs top
to bottom, so nothing could assert against it without keeping a second copy — which is the
failure being fixed. The flag prints the map for a host and exits, writing nothing. It is
exempt from the self-install guard, because refusing it would make the map unreadable from
the one checkout guaranteed to have it. **This may be most of the answer to open decision 3**
(dry run): reporting what the installer owns is the static half of reporting what it would
change.

**The guards were broken on purpose to prove they catch.** Dropping `tools/orient.sh` from
the map stopped it shipping and two `orient` tests failed — which is the proof that the map
drives placement rather than sitting beside it. Omitting one skill from the map failed six
tests across four files, including the coverage guard written for exactly that.

Twenty-six tests added, suite at 247.

**Review found four bugs before merge.** (1) A missing process skill no longer aborted — the
map-derived preflight could not notice what the map never mentioned. Restored a roster check
against `PROCESS_SKILLS`. (2) `PRINT_OWNERSHIP` was environment-injectable and turned an
install into a silent no-op; initialized like every other flag. (3) One test asserted an
untouched temp dir stayed empty; fixed to pass `--target`. (4) Nothing asserted install ⊆
map; added, with scaffold directories as the declared exception. Also refused
`--machine --print-ownership`, which was answering the wrong question with exit 0.

## Phases b and c — what they did

**`place_file` and `place_dir` now replace by default.** Toolkit-owned paths are written
every run. Project-owned paths (`write_project_stub`, numbered brief folders) unchanged.
Second install on a tuned target reports `Replaced`, not `Skipped`.

**`--force` is retired, not repurposed.** Passing it exits 1 with a message. A flag that
does nothing would be a trap for anyone who remembers what it used to do.

**Prune reads `### Skills installed` and `### Commands installed` only** — not
`### Created`, which names scaffold dirs that must never be removed. Stale is a name the
log recorded and the current source no longer ships. No log means no removal and a line
saying why. A symlinked skills or commands tree refuses the whole prune with exit 1.
Removals land in `### Removed` on the run's log entry.

**Six prune tests added.** Suite at 250. `test_force.sh` rewritten for replace-by-default;
`test_project_mode.sh` and `test_contract_ship.sh` updated to match.

## Phase d — what it does

**Shipped rules name the policy.** `templates/process-rules.md` gains a "Toolkit-owned vs
project-owned" section: local edits to toolkit paths do not survive install; customize through
`AGENTS.md` and `brief-checks/`.

**Docs and comments aligned.** `README.md`, `tests/README.md`, machine-mode comments in
`install.sh` and `test_machine_mode.sh`, and `blc-installer-builder` no longer describe
`--force` or idempotent skip.

**`test_force.sh` renamed to `test_replace.sh`.** Two socialization tests assert the shipped
rules on both hosts. Suite at 253.

## Notes

Brief #0011 depends on this one — `brief-checks/` needs the ownership map from `a` to record
a path the installer promises never to touch. Phase `a` should treat "never written" as a
first-class category in the map, not as the absence of an entry.
