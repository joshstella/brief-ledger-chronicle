# The version bump that leaves its readers behind

**Created:** 2026-10-08T16:06:54Z · **Author:** josh.stella@gmail.com
**Depends on:** #0034

A new Contract version is a file plus a set of pointers. `#0033` cut v1.4 and moved the
pointers it knew about. Four citations of `docs/blc/contracts/v1.3.md` stayed behind:

- `skills/blc-create-brief/SKILL.md` — "the structural rules this command enacts are
  stated in `v1.3.md`". The skill that assigns every serial cites a superseded Contract.
- `README.md` — sends a first-time reader to v1.3.
- `docs/architecture/README.md` — a `<!-- cite: -->` marker, the mechanism that doc uses
  to prove each claim against the code.
- `tests/test_briefs.sh` — a header comment saying where clause text lives.

None of them break. v1.3 is still published, because superseded is not deleted, so every
link resolves. They are wrong in the way that is hardest to catch: they work.

`tests/test_contract_ship.sh` is a separate shape of the same gap. It hand-lists v1.1
through v1.3 in four places and asserts each ships. It never asserts v1.4 ships, and it
passed the whole time. A test that enumerates what exists cannot notice what was added.

## The finding

**Nothing checks that cutting a version moves its citations.** `#0033` enumerated the cost
of a bump and the list was incomplete — which is the evidence, not an excuse. The same
class as `#0032`'s process-skill list copied in five places: a fact restated by hand in
places that have no mechanical relationship to each other.

Two populations, and they are not the same job:

- **Pointers to "current"** must move on every bump. `orient.sh`, the versions table, the
  `**Status:** current` marker.
- **Citations of a specific version** are sometimes right to leave alone. A ledger that
  argued against v1.2 should keep saying v1.2; rewriting it would falsify history.

A check that cannot tell these apart will either miss the drift or demand that closed
ledgers be edited. Closed ledgers and brief bodies are history and are out of scope.

## Open

- Whether this is a clause (`[judgment]`, consistent with how the repo treats things it
  cannot prove) or a test, or both.
- Whether the live set is derivable — toolkit-owned paths are enumerable, which is what
  makes `#0032`'s derivation trick available here.
- `test_contract_ship.sh`'s hand-listing is a fix in its own right and may not need the
  rest of this brief to land first.

Depends on `#0034` only for ordering: `#0034` cuts v1.5, so the target this brief chases
moves. Filing it after that lands avoids doing the same edit twice.
