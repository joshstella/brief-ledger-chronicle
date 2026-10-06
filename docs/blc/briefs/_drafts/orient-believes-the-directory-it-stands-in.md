# Orient believes the directory it stands in

**Created:** 2026-10-06T03:33:59Z · **Author:** josh.stella@gmail.com
**Depends on:** #0021

## The finding

`tools/orient.sh` finds the repository root and then does not use it for the record.
Line 31 sets `ROOT` from `git rev-parse --show-toplevel`. The script uses `ROOT` to find
other scripts (lines 84, 115, 234). It does not use `ROOT` to find the data. Every
data path is relative to the current directory:

| line | path | source |
|---|---|---|
| 19–28 | `BRIEFS_DIR`, `STATE_DIR`, `AUTHORED`, `INSTALL_LOG`, `CHRONICLE`, `CONTRACT` | default `docs/blc/briefs` and its siblings |
| 228 | `.cursor/skills .claude/skills/*` | self-host check |
| 270 | `Manifesto.md` | footer, added by #0021 |

Run from a subdirectory, orient finds none of these files. It exits 0 and reports each
one as absent. On 2026-10-05, in an adopting repository at installer `177+2f6aa89`, the
command `bash ../tools/orient.sh` from `src/` printed these lines:

| what it prints | what is true |
|---|---|
| `No docs/blc/briefs — nothing filed here yet.` | 42 briefs are filed |
| `No docs/blc/install-log/install-log.md — this repo was not set up by the installer.` | the log records 10 installer runs |
| `No docs/blc/orientation.md — nobody has written down what matters here.` | the file has 60 lines |

The freshness line was correct, because git commands do not depend on the current
directory. So the output had one correct line about git and three incorrect lines about
the record.

## Why this is worse in orient than in its siblings

Four other tools take the same relative default. They fail loudly. From the same
subdirectory:

| tool | result |
|---|---|
| `validate-briefs.sh` | `error: not a directory: docs/blc/briefs`, exit 2 |
| `open-briefs.sh` | `error: not a directory: docs/blc/briefs`, exit 2 |
| `list-briefs.sh` | `No docs/blc/briefs — run from the repo root…`, exit 1 |
| `jira-csv.sh SERIAL` | `jira-csv: no docs/blc/briefs — run from the repo root…`, exit 1 |

Orient is different on purpose. #0021 made each section change a missing input into a
stated absence, because a stated absence is a true statement in a new project. That
decision is correct for a project that has no record. It is incorrect for a project that
has a record which orient cannot see. The output for these two projects is the same, and
orient tells the reader to trust it instead of the record. Because orient fails without
an error, the reader has no way to know that the output is wrong.

## Why it went unnoticed

- **Every test runs orient from the root.** `tests/test_orient.sh` calls
  `$REPO_ROOT/tools/orient.sh` with the fixture root as its working directory. No test
  changes into a subdirectory first. The suite passes 570 tests at `2f6aa89` and does not
  test this case.
- **The skills say "from the repository root".** `blc-orient` step 1 and `blc-my-briefs`
  say it. `blc-start-brief`, `blc-next-brief-phase` and `blc-review-pr` give the relative
  command `bash tools/orient.sh`. A relative command fails loudly outside the root, so
  that path is safe. The unsafe path is an agent whose shell is already in a subdirectory
  and that uses `../tools/orient.sh` or an absolute path. That is a normal thing to do,
  because an agent's shell keeps its working directory between commands.
- **It was found during a review.** The `blc-review-pr` gate ran orient from `src/` as a
  probe. No user reported it.

## The likely fix, and the defect it can cause

The narrow fix is one line after line 31: `cd "$ROOT"`. It fixes all three
outputs, the self-host check and the footer.

But the fix changes the meaning of an explicit argument. Today `orient.sh path/to/briefs`
resolves the path from the caller's directory. After `cd`, it resolves the path from the
root. A caller in a subdirectory that passes a relative path that is correct for that
directory gets a different directory, or no directory. The fix must make the argument
absolute before the `cd`, or must say in a comment that the argument is relative to the
root.

## What is actually undecided

1. **Whether the siblings change too.** The siblings fail loudly, so they do not give
   incorrect answers. A `cd "$ROOT"` in each one makes them work from a subdirectory. It
   also makes their argument relative to the root, which is the same trade as above, in
   four more places. The other choice is to fix orient only, because only orient fails
   without an error.
2. **What an explicit argument is relative to.** It can be relative to the caller (resolve
   the argument, then `cd`) or relative to the root (document it). The caller choice
   follows usual shell behavior. The root choice matches the default path. All five
   tools must use one rule, whatever question 1 decides.
3. **Whether orient must also say when it is not at the root.** A note such as
   `(ran from src/, read from the root)` costs one line. It tells a reader that the
   script resolved the path. It also adds a line to a 700-token output that has a fixed
   budget. Without the `cd` fix, the note is the minimum honest output. With the fix, the
   note is optional.

## Non-goals

- Do not change #0021's stated-absence design. It is correct when the input is truly
  absent. This brief makes sure that "absent" means absent.
- Do not make any tool work outside a git work tree. Line 30 already refuses that case,
  and that is correct.
- Do not change the skills' instruction "run from the repository root". The script must
  be correct whether or not a caller obeys that instruction.

## The test that would have caught it

One fixture with a filed brief and an install log. Run orient from a subdirectory of
that fixture. Assert that the output is the same as the output from the root. If
question 1 extends the fix, do the same test for each sibling.
