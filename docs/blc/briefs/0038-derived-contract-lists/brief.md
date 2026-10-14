# The fix that was applied once and not propagated

**Serial:** #0038 · **Created:** 2026-10-14T03:37:29Z · **Author:** josh.stella@gmail.com · **Depends on:** —

`tests/test_contract_ship.sh` names Contract versions by hand in four places. Each list stops
at `v1.3`. `v1.4` and `v1.5` are published, ship to every target, and are asserted by none of
them.

Carved out of `_drafts/contract-citation-drift.md`, which named this and said it "is a fix in
its own right and may not need the rest of this brief to land first." That draft keeps the
other half — the citations of a superseded Contract scattered through the skills, the README
and the architecture doc.

## The defect

Four hand-written lists, all ending at `v1.3`:

- **`:13-19`** `test_ship_places_the_contract` — asserts `v1.md` through `v1.3.md` are
  installed, and that three of them contain `BRIEFS-1`.
- **`:25-29`** `test_ship_places_the_contract_for_cursor_too` — the same list for the other
  host.
- **`:45-48`** `test_ship_every_tool_the_installed_docs_name_is_present` — the documents it
  scans for `tools/` paths.
- **`:152-154`** `test_ship_the_installed_contract_names_a_check_that_exists` — the contracts
  it scans for `checked:` paths.

A version added after the list was written installs unasserted. Two have been.

## The part that makes this a brief and not an edit

**The fix already exists in the same file and was not carried to the rest of it.**
`test_ship_the_briefs_readme_is_this_repos_own_file` at `:176` reads the tree:

    for v in "$REPO_ROOT"/docs/blc/contracts/v*.md

Its comment states the whole finding: *"Every version in the tree, not a list of them. The
versions were named one per line up to v1.3, so publishing v1.4 added a file this test did not
look at."* Somebody met this defect, fixed the test in front of them, and left four more.

`test_ship_every_tool_the_installed_docs_name_is_present` is worse than a stale list, because
its comment argues against itself. It says *"Every document install.sh ships under docs/, not
the ones that happen to name a tool today. The property is about the shipped set; scanning a
subset of it would let a tool named in the omitted document go unchecked"* — above a
hand-written subset. The test states the principle it violates.

## The trap

**One hand-written name is correct and must survive.** `:190`
`test_ship_exactly_one_contract_version_is_current` derives the set of files marked current
and then asserts the name `v1.5.md` literally. Its comment says why: *"The expected name stays
written out rather than derived from the highest version on disk. That is the point of it:
publishing a version has to be a deliberate edit here, so a file dropped into the directory
cannot promote itself to current without someone saying so."*

That is the difference this brief turns on. A derived list answers **"what ships"**, which the
tree is the authority for. A written name answers **"what did someone decide"**, which the
tree cannot answer and must not be allowed to. A sweep that replaces every literal version
string would delete the second kind, and the loss would be silent: the test would still pass,
and it would stop checking the thing it exists for.

## Claim

Derive the four lists from `docs/blc/contracts/`. Leave `:190` alone, and say at that site why
it is not the same kind of list, so the next sweep does not take it.

## Out of scope

- **The stale `v1.3` citations** in `skills/blc-create-brief/SKILL.md:88`, `README.md:130`,
  `docs/architecture/README.md:43` and `tests/test_briefs.sh:9`. They belong to the parent
  draft. They are a different population: a citation of a specific version is sometimes right
  to leave alone, and deciding which needs the argument the draft has not had yet.
- **Whether a clause should require this.** The parent draft asks whether the drift is a
  `[judgment]` clause, a test, or both. This brief is the test.

## Open

- **Does `BRIEFS-1` belong in every version?** `:17-19` asserts it in `v1.1` through `v1.3`
  but not in `v1.md`. Deriving the list would start asserting it in `v1.md`, `v1.4` and `v1.5`
  as well, which is a wider claim than the test makes today and may be false for `v1.md`.
- **Should the derivation read the installer's own list instead of the tree?** The tree is
  what the repository has; the installer is what a target gets. They agree today. A test that
  reads the tree proves the target matches the tree, which is the property worth having, but
  it cannot catch a version the installer silently declines to ship.
- **How is the fix proven?** A test that derives a list passes whether or not the derivation
  found anything. Each one needs a floor — the `[ "$found" -gt 0 ]` shape two of them already
  use — or a fixture that adds a version and watches the assertion count rise.
