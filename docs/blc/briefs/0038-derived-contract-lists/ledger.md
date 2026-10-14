# Ledger — #0038 The fix that was applied once and not propagated

`blc/2 #0038 done a:done`

**Brief:** `docs/blc/briefs/0038-derived-contract-lists/brief.md`
**Status:** done
**Started:** 2026-10-14
**Closed:** 2026-10-14

## Phases

| id | label | status | branch | PR |
|---|---|---|---|---|
| a | derived contract lists | done | `brief/0038-a-derived-contract-lists` | #156 |

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
`brief/0038-closeout`, cut from `main` at `3dbdee0`.

## Close, 2026-10-14

### What shipped

`tests/test_contract_ship.sh` no longer names a Contract version in a list. Publishing `v1.6`
puts it under every assertion in that file the day the file exists, with no edit here.

One phase, `a` (#156). Five lists became reads of `docs/blc/contracts/`, the same glob
`install.sh:423` uses to decide what it ships. Every loop got a floor, because a derived list
passes whether or not the derivation found anything. The one hand-written version name that
answers a decision rather than a fact stayed written out, with the reason beside it.

All four decisions settled before the phase held. The fifth list the brief did not name was
found while planning, and folding it in was decided before any code was written.

### What the record shows that the brief did not predict

- **The defect was never silent. It was reported in the wrong words.** The brief said `v1.4`
  and `v1.5` are "asserted by none of them". The counterfactual says otherwise: run the old
  test file against an installer that ships only `v1.md` through `v1.3.md` and two tests fail
  — the already-derived `cmp` test and the relative-link test. So a Contract that failed to
  install would have been caught. It would have been caught by tests that exist for other
  reasons, naming other properties, while every test whose stated job is to assert the
  Contract installed stayed green. That is a weaker claim than the brief made and it is the
  true one. It also explains how the defect survived: nothing ever went red, so nobody was
  sent to the lists.
- **The floor is the part that nearly shipped broken.** The first draft put
  `[ "$found" -gt 0 ] || fail` inside the helper. A `fail` in a command substitution dies in
  the subshell, the caller loops over an empty list, and the test passes having checked
  nothing. The fix for a test that cannot report emptiness was written as a test that cannot
  report emptiness. Caught by reading, not by a run: the suite was green either way, which is
  the whole point.
- **One of the five lists carried its own specification.**
  `ship_every_tool_the_installed_docs_name_is_present` had a comment saying the property is
  about the shipped set and that scanning a subset would let a tool in an omitted document go
  unchecked, written above a hand-written subset. The comment needed no rewrite. Obeying it
  found a second omission the brief did not name: `docs/blc/state/README.md` ships on every
  install and no list here had ever scanned it.
- **"Derive everything" was wrong, and the file said so before this brief did.**
  `ship_exactly_one_contract_version_is_current` already explained why its version name is
  written out. The brief's contribution was not finding that rule but naming the two
  categories — a derived list answers what ships, a written name answers what someone decided
  — so the next sweep has a test to apply rather than a precedent to respect.

### Open after close

- **`install.sh:959` prints "Contract v1.5" in the install banner.** It is a hand-written
  version name outside this file and it will go stale the same way. Out of scope here, and
  the same question as the parent draft's citations.
- **The parent draft keeps the other half.** `_drafts/contract-citation-drift.md` holds the
  `v1.3` citations in the skills, the README, the architecture doc and `tests/test_briefs.sh`.
  Deciding which citation of a specific version is right to leave alone needs the argument
  that draft has not had.
- **The tool scan now reads `install-log.md`, which the installer writes rather than ships.**
  It passes today. No fixture builds a target whose install log names a tool a later version
  removed, so whether that test would then fail usefully or only make noise is unknown.
- **The derivation is correct while `install.sh` stays derived.** If the installer goes back
  to naming versions, these tests agree with the tree against the target, and the two lists
  are again two things to keep in step. Said at the site; nothing enforces it.
- No bug ledger (`review-<branch>.md`) was written. There were no surviving correctness bugs.

### What this cannot prove

- **A floor proves the loop ran, not that the loop would catch the defect.** Both were tested
  separately: pointing the helper's glob at a pattern that matches nothing fails all four
  floors, and mutating the installer fails three of the changed tests. Neither shows the
  assertions cover a case nobody thought of.
- **The mutation only models a version that does not install.** A version that installs with
  the wrong content was already caught by the `cmp` test before this change, and a version
  that installs correctly but states no clause is caught by nothing here.
- **The review was written by the author of the code.** `blc-review-pr` returned Approve with
  one scope item for the person to settle, and Bugbot found no bugs. No person read the diff
  before it merged.
