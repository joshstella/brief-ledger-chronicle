# The table that sorts by the last edit

**Created:** 2026-10-06T05:55:00Z · **Author:** josh.stella@gmail.com
**Depends on:** —

## The finding

`tools/list-briefs.sh` sorts every brief by last touch, newest first. Last touch is the
author time of the newest commit that changed the brief's folder. Nothing else enters the
order. The tie-break is the slug, descending.

The order tells a reader which brief was edited last. It does not tell them what is live. In
one project on 2026-10-06 the table opened with a skipped brief, because a status correction
to its ledger was that day's newest commit. The two briefs in progress sat in rows four and
nine of twelve.

Any commit to a ledger moves its brief to the top: a status fix, a typo, a correction to a
closed brief. The rows that a reader wants first, the open work, can be anywhere.

## Who reads the order

The table has three consumers, and each one sees this order:

1. **The chronicle.** `gather.sh` prints the table, and the skill copies it to the top of
   `chronicle.md`. It is the first thing a reader of the chronicle sees.
2. **`orient.sh`.** Its "In flight" table is a filtered view of the same rows, in the same
   order.
3. **`blc-my-briefs`.** It calls `list-briefs.sh --owner`.

`--tsv` gives the same order to the chronicle's "To narrate" list.

## The change, tried in one project and withdrawn

The project edited its installed `tools/list-briefs.sh` in place, knowing the next install
would overwrite the edit. The same day it dropped the edit, without committing it, and went
back to the toolkit's order so that its checkout matched `main`. No defect in the edit was
found. The results below come from the edit while it was in place, and they stand as
evidence for that change. The order was by progress, with last touch newest first inside
each group:

| rank | status | why here |
|---|---|---|
| 1 | `in-progress` | a branch exists; the live work |
| 2 | `pending` | a ledger exists, with a plan and no progress |
| 3 | `planned` | the tool's own label for a brief with no ledger |
| 4 | `done` | closed |
| 5 | `deferred` | parked on purpose |
| 6 | `skipped` | not being done |
| 7 | anything else | `no-line`, or a token outside the vocabulary |

The owner asked for in-progress, then planned, then done, then deferred, then skipped.
`pending` was not in that list. It was put before `planned`, because a brief with a planned
ledger is further along than one with no ledger. That placement is an assumption, and the
owner has not confirmed it.

An unknown status sorts last instead of beside `pending`, so a malformed ledger shows as an
exception and not as ordinary waiting work.

The implementation is a `status_rank` function and a rank column in the temporary scan
file. The column is sorted first and then removed with `cut -f2-`, so `--tsv` keeps its
documented five-field layout. `gather.sh` reads that layout and needed no change apart from
its heading.

Checked in that project while the edit was in place:

- The table, `--tsv`, `--owner`, the `orient.sh` "In flight" table, and an incremental
  `gather.sh` all give the new order. `--tsv` still has five fields on every line.
- A fixture with one brief in each state, plus `no-line` and an unknown token, sorts as the
  table above. The fixture had no `deferred` brief; the real tree had one, and it sorted
  correctly.

## Open questions a brief would have to settle

1. **Does `--tsv` change order too?** The project's edit changed both, because `gather.sh` says the
   narration list is "the same scan, same order as the table". The narration list then walks
   briefs by progress. Step 3 of the chronicle skill still says "newest last-touch first". A
   narrator builds eras in time order, so the narration list may need the old order while the
   table takes the new one. That means two sort orders from one scan, or a `--by` flag.
2. **Is `deferred` closed or open?** The owner put it after `done`. `orient.sh` lists it as
   in flight, and `is_closed` treats it as open. The table now reads as if it is closed. The
   two views disagree, and one of them should give way.
3. **Where does `pending` go?** See the assumption above.
4. **Is "planned" a status?** The vocabulary in `docs/blc/briefs/README.md` has five states,
   and `planned` is not one of them. `list-briefs.sh` prints it for a brief with no ledger,
   and a reader takes it for a state. A brief should either add it to the vocabulary or print
   something that cannot be read as one, for example `no-ledger`.
5. **Does the order become a contract?** Today it is an implementation detail with three
   consumers. A test that pins the order makes the next change visible.

## Why this is a draft and not a brief

The shape is decided and one project runs it. Question 1 changes what gets built, and
question 2 needs the owner's decision. Filing takes one run of `blc-create-brief`.
