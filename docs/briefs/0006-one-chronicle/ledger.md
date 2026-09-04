# Ledger — #0006 One chronicle, newest first, with a brief table
`blc/1 #0006 pending 1:pending 2:pending 3:pending 4:pending`

**Brief:** `docs/briefs/0006-one-chronicle/brief.md`
**Status:** pending
**Date:** 2026-09-04

## Phase sequence

| id | status | what it does |
|---|---|---|
| `phase 1 — the digest` | pending | `gather.sh` emits a Markdown table of every brief, newest last-touch first, on full and incremental runs. Columns: serial, title, status, first, last, depends-on. Title from the first `#` line of `brief.md`. Status from the ledger `blc/1` overall token, or `planned` if there is no ledger. Incremental filtering stays for commits and for what is new to narrate. The table is not filtered. |
| `phase 2 — the check` | pending | Tests in `tests/test_gather.sh` for the table: last-touch order, title, status, full table under a cutoff, planned when there is no ledger. Also rewrite the tests that today pin first-commit list order and the `executed` token — those strings will move or die when the table lands. |
| `phase 3 — the skill and the path` | pending | Rewrite `skills/chronicle/SKILL.md`: write only `docs/chronicles/chronicle.md`; refresh the table from gather; prepend new era prose under it; update the closed-through marker; no sibling; drop the notes-vault path. Present-tense paragraph after the table; origin at the bottom. Instruction, not a check. |
| `phase 4 — the ignore` | pending | Stop hiding `chronicle.md`. Keep the folder. Installer, `.gitignore`, `tests/test_project_mode.sh`, and any README/slides that still say "never committed." Other files under `docs/chronicles/` may stay ignored. |

## Dependency structure

- **Strict chain: phase 1 → phase 2.** Phase 2 is the check for phase 1. Landing the digest without the tests would leave a green suite asserting the old list order and the `executed` token — a lie about the new table. Stack 1 and 2 on one PR.
- **Strict chain: phase 2 → phase 3.** The skill pastes a table the digest already shaped and that the suite has pinned.
- **Phase 4 lands with phase 3, or immediately after.** The brief says landing the skill while the ignore still drops `chronicle.md` is the old rule under a new name. Prefer one PR for 3 and 4.
- **Not parallel.** Apparent independence between 1 and 3 is false: 3 consumes 1's columns.
- **Not provisional.** Open decisions were resolved at filing.

## Open decisions

None. Resolved 2026-09-04 in the brief.

## Complications found in the code, not addressed by the brief

1. **The suite pins the old briefs list.** `test_gather_orders_briefs_by_first_commit_not_by_serial` takes the first `0001`/`0002` slug in the whole digest. A last-touch table printed first fails that test even when first-commit order is still correct somewhere else. `test_gather_marks_a_brief_with_a_ledger_as_executed` asserts the word `executed`, which the table replaces with a `blc/1` token. Phase 2 has to rewrite those tests, not add new ones beside them.

2. **A ledger with no `blc/1` line has no status the brief named.** The brief says overall token, or `planned` if there is no ledger. `gather_ledger` in the tests writes a ledger without a status line. `open-briefs.sh` already treats a missing line as a finding. Phase 1 must pick a token for that case. The brief did not.

3. **Uncommitted briefs have no last-touch.** `gather.sh` already uses `0000-uncommitted` for a missing first-commit. Last-touch is empty on the same briefs. Sort order for those rows is unstated.

4. **Already-installed projects keep the old ignore.** `install.sh` appends `docs/chronicles/` and never rewrites a `.gitignore` that already has that line. `--force` does not touch `.gitignore`. Phase 4's installer change will not un-hide `chronicle.md` in a target that already installed. Those projects need an ignore edit by hand, or a new installer behaviour the brief did not ask for.

5. **The existing briefs bullet list will duplicate the table** if phase 1 adds a table and leaves the list. Two orders in one digest. Dropping the list is the cleaner digest and is why complication 1 exists.

## Branches

| branch | phase | state |
|---|---|---|
| — | — | none yet; branch after this ledger is on `main` |

## Big decisions

None beyond the brief. Filing resolved the five open decisions. The pairing of 1+2 and 3+4 is a sequencing call from contact with the suite and the ignore, not a reopening.
