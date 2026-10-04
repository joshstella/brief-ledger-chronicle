# The move git cannot see

**Serial:** #0020 · **Created:** 2026-10-04T12:28:20Z · **Author:** josh.stella@gmail.com · **Depends on:** #0017

## The finding

An upgrade from the old layout moves a project's tracked files under `docs/blc/`. It moves them
with `mv`, not `git mv` (`install.sh:918`). The same install appends this rule to the target's
`.gitignore` (`install.sh:999`):

```
docs/blc/chronicles/*
!docs/blc/chronicles/chronicle.md
```

Any chronicle other than `chronicle.md` lands on an ignored path. Git sees the old path deleted
and does not see the new path at all. The install exits 0 and prints no warning. The next
`git add -A` or `git commit -a` removes those files from the repository.

The files stay on disk, as ignored files, on the machine that ran the install. Git history
still holds them. Every other clone loses them at the next pull, and nothing in the working
tree says so.

## Evidence

**1. It occurred in an adopting repository on 2026-10-03.** The #0017 upgrade moved six
chronicles into `docs/blc/chronicles/`, and all six became untracked. They were tracked at the
old path, and git does not ignore a tracked file, so no rule had hidden them before. A commit at
that moment would have removed the chronicle history from the repository. A person caught it by
hand. Found while writing the draft "orient answers confidently, and wrong", and parked there as
out of scope, because it is `install.sh` and not `orient.sh`.

**2. Reproduced on 2026-10-04 against `main` at `1328e48`.** A scratch git repository with the
old layout and two tracked chronicles, `chronicle.md` and `2026-09-01.md`, then
`install.sh --yes --host claude --target <it>`:

```
install exit 0
 D docs/chronicles/2026-09-01.md
 D docs/chronicles/chronicle.md
!! docs/blc/chronicles/2026-09-01.md
```

After `git add -A`, `git ls-files` lists `docs/blc/chronicles/chronicle.md` and no other
chronicle.

**3. The tests cannot see it.** `test_upgrade_moves_each_project_file_under_docs_blc` asserts
that each moved file exists at its new path, and it does. No fixture in `tests/test_upgrade.sh`
is a git repository (`up_old_layout` uses `mkdir` and `printf`), so no test can ask what git
sees. The full suite passes 534 tests.

## Why it went unnoticed

The filesystem and the index disagree, and every check reads the filesystem. The move is
correct on disk. It is wrong only in git, and only for a file that an ignore rule matches at
its new path.

This repository cannot show it. Its chronicles were never in the old layout here, and it is
never upgraded, because the source is not a target (#0019).

## The class, not the instance

Chronicles are the case that occurred. The defect is wider: **an upgrade can move a tracked
file onto any path that an ignore rule matches.** The toolkit's own rule is one source. A
target's existing `.gitignore` is another, and the installer cannot know what it holds. A
project that ignores `docs/blc/` for its docs build, or any part of it, loses every moved
file the same way.

So the fix cannot be "special-case chronicles". It must ask git about each moved path.

## What is actually undecided

1. **How the move keeps a file tracked.**
   - (a) In a git repository, move a tracked file with `git mv`. Git keeps tracking a file
     after it moves onto an ignored path, so the history follows the file. Untracked files and
     non-repositories keep `mv`. The installer then stages changes in the target, which it does
     not do today.
   - (b) Keep `mv`. After the move, ask `git check-ignore` about each moved file that was
     tracked. Refuse, or warn and list them with the command that fixes it
     (`git add -f <path>`). The installer writes nothing to the index.
   - (c) Preflight: before anything moves, find each tracked file whose new path is ignored,
     and stop with the list. Nothing moves until the person decides.

   (b) and (c) keep the installer out of the index. (a) is the only one that needs no action
   from the person.
2. **Whether the chronicles rule is right.** It assumes one committed chronicle and a scratch
   folder for the rest. The adopting repository kept six chronicles, tracked. That is a real
   use the rule forbids. If the rule changes, the fix in decision 1 is still needed for a
   target's own ignore rules.
3. **What happens to targets already upgraded.** Any project upgraded since #0017 may hold
   ignored chronicles that git no longer tracks, or may already have committed their removal.
   A check to run on an installed project, or a note to each owner, or nothing.

## The missing assertion

One line, in a fixture that is a git repository: after an upgrade, every file that was tracked
before the move is still tracked, at its new path. That is the test that fails today. It must
be seen to fail before the fix.

## Urgency

**Do not upgrade another project from the old layout until this is fixed,** or check by hand
after each upgrade with `git status --ignored`. This is the one known defect that loses project
data. It ranks above the three orient defects.

## Non-goals

- Not a general audit of every path the installer writes. This is about files it moves.
- Not removing the old `docs/chronicles/` rules from a target's `.gitignore`. #0017 left that to
  a later upgrade, and it does not affect this defect.
