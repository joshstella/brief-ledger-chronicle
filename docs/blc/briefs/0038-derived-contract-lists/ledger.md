# Ledger — #0038 The fix that was applied once and not propagated

`blc/2 #0038 in-progress a:in-progress(brief/0038-a-derived-contract-lists)`

**Brief:** `docs/blc/briefs/0038-derived-contract-lists/brief.md`
**Status:** in-progress
**Started:** 2026-10-14

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | derived contract lists | in-progress | `brief/0038-a-derived-contract-lists` | — |

**a — derived contract lists.** `tests/test_contract_ship.sh` names Contract versions by hand
in five places, and every list stops at `v1.3`. `v1.4` and `v1.5` are published, ship to every
target, and are asserted by none of them. This phase replaces each list with a read of
`docs/blc/contracts/`, the same glob `install.sh` already uses to decide what it ships, and
gives each loop a floor so a derivation that finds nothing fails rather than passes. It leaves
the one hand-written version name that is correct — the test that says which version is
current — and says at that site why it is a different kind of list, so the next sweep does not
take it. The fix is proven by making the installer skip a version and confirming each derived
assertion fails. It touches `tests/test_contract_ship.sh` only.

## Dependency structure

One phase, one file. The five lists are the same defect, the proof is one mutation of the
installer, and splitting them would buy a second review of a diff a reader takes in at once.

## Settled before `a` began, 2026-10-14

- **Derive the `BRIEFS-1` assertion over every version, `v1.md` included.** The test asserts
  it in `v1.1` through `v1.3` and not in `v1.md`. Deriving widens the claim. Measurement says
  the wider claim is true: all six version files contain `BRIEFS-1`, `v1.md` once and the rest
  twice. The narrower list was not a judgment about `v1.md`; it was a list that was written
  before `v1.md` was worth adding to it.
- **The tree is the source, not the installer's list.** `install.sh:423` builds what it ships
  with `for v in "$SCRIPT_DIR"/docs/blc/contracts/v*.md`, which is the same glob. There is no
  second list to disagree with, so reading the installer would read the tree one indirection
  later. The brief asked whether a test reading the tree could catch a version the installer
  declines to ship; today the installer cannot decline, because it does not enumerate. Say
  this at the site, because the answer depends on `install.sh` staying derived.
- **The fifth list is in scope.** The brief named four. `test_ship_default_replaces_a_stale_contract`
  at `:202` is a fifth: it writes `OLD` content into `v1`, `v1.1` and `v1.2` and asserts the
  install replaced it, so a stale `v1.5` is not proven replaced today. Same defect, same file,
  same fix.
- **Floors and a mutation check both.** A derived list passes whether or not the derivation
  found anything, so every loop gets the `[ "$found" -gt 0 ]` shape two of them already use.
  The floor proves the loop ran; it does not prove the loop would catch the defect. Making
  `install.sh` skip a version and watching each assertion fail proves that.

## Open decisions

None.

## Complications found while planning

- **The trap is real and is not a style question.** `test_ship_exactly_one_contract_version_is_current`
  at `:190` asserts the name `v1.5.md` literally and says why: publishing a version has to be a
  deliberate edit, so a file dropped into the directory cannot promote itself to current. A
  sweep that replaced every literal version string would still pass and would have stopped
  checking the thing it exists for. A derived list answers what ships; a written name answers
  what someone decided.
- **One of the five lists states the principle it violates.**
  `test_ship_every_tool_the_installed_docs_name_is_present` carries the comment "Every document
  install.sh ships under docs/, not the ones that happen to name a tool today … scanning a
  subset of it would let a tool named in the omitted document go unchecked", written above a
  hand-written subset. The comment is the specification for the fix and needs no rewrite, only
  a body that obeys it.
- **The fix already exists in the file.** `:176` reads the tree, and its comment records that
  publishing `v1.4` added a file the test did not look at. Somebody met this defect, fixed the
  test in front of them, and left the rest. That is the finding the brief turns on and it
  bears on the mutation check: the phase must confirm the already-derived test is not the only
  one that catches the mutation.
- **`install.sh:959` prints "Contract v1.5" in the install banner.** It is a hand-written
  version name outside the test file. It is out of this phase's scope — the brief binds
  `tests/test_contract_ship.sh` — and it is the same question as the parent draft's stale
  citations.
- **The install suite is the slow one.** These tests each run a full `install.sh`, and the
  `install-sh` CI check takes eight to ten minutes. The mutation check costs a second pass.

## Big decisions

- **The tool scan reads every document the target has, not the contracts plus a list.**
  2026-10-14. The review gate on phase `a` raised it as scope: the brief said derive from
  `docs/blc/contracts/`, and this reads `find "$TARGET/docs" -name '*.md'`. Kept. The test's
  own comment already specified the shipped set and warned that a subset lets a tool named in
  an omitted document go unchecked, so the narrow fix would have obeyed the brief and left the
  comment false. It also surfaced a second omission the brief did not name:
  `docs/blc/state/README.md` ships on every install and no list here has ever scanned it. The
  cost is that the scan now reads `install-log.md`, which the installer writes rather than
  ships, and no fixture covers an install log that names a tool a later version removed.

## Branches

`brief/0038-a-derived-contract-lists`, cut from `main` at `e2fd440`.
