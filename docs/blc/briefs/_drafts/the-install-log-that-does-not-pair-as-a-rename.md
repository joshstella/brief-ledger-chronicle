# The install log does not pair as a rename

**Created:** 2026-10-07T09:55:00Z · **Author:** josh.stella@gmail.com
**Depends on:** #0020

## The finding

#0020 moves tracked files to `docs/blc/` with `git mv`, and it works. In a real upgrade on
2026-10-06, 88 of 93 renames were byte-identical, and 7 of the 8 rewritten files still pair as
renames.

`docs/install-log/install-log.md` is the one that does not. It still does not pair at a 40%
rename threshold. No content is lost — 335 lines are preserved and 171 appended — but `git log`
on the new path starts at the move commit.

The install log is the one file whose whole purpose is continuity. It is the file a target
reads to learn what an install wrote, and it is the only record an interrupted upgrade leaves.

Split out of #0026, which found it and does not fix it.

## What is undecided

1. **Whether this is fixable at all.** The file is appended to in the same run that moves it, so
   the move and the rewrite are one commit. Splitting them into two commits would pair the
   rename and would put a commit on a target's history that does nothing else.
2. **Whether `--follow` is the answer instead.** `git log --follow` may already cross it, which
   would make this a documentation item rather than a defect. Not measured.
3. **Whether `docs/blc/ignore-revs` should carry the move commit**, as it does for #0017.

## The test that would have caught it

An upgrade fixture with an old-layout install log. Assert that `git log` on the new path
reaches a commit older than the move.
