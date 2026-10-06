# The trailer that credits the wrong agent

**Created:** 2026-10-06T04:37:06Z · **Author:** josh.stella@gmail.com
**Depends on:** —

## The finding

Step 5 of `skills/blc-commit-push-pr/SKILL.md` tells the agent to end every commit message
with a fixed line:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

`install.sh` ships that file to both hosts and substitutes nothing. Checked across the whole
skills tree and the installer: this is the only host-specific string in host-neutral prose.

A Cursor host therefore writes a Claude trailer on every commit the skill makes. The
attribution is wrong, and it is wrong in the permanent record, which is the one place this
toolkit exists to keep honest.

Found on 2026-10-06 while installing `2f6aa89` into a real project. That repository installs
with `--host cursor` and its 197 commits all carry
`Co-authored-by: Cursor <cursoragent@cursor.com>`. The skill would have contradicted the
history it was about to join, on its first run.

## Why it has not been a problem

The author works on Claude Code. The one string that is not host-neutral is correct for the
host the author uses, so nothing ever looked wrong. The Cursor install path is exercised, but
nobody had yet run `blc-commit-push-pr` from it and then read the resulting trailer.

This is the failure mode "one source, two hosts" is supposed to prevent, surviving because the
second host was installed and not used for this one step.

## A constraint the obvious fix does not survive

A skill reaches a host three ways, and they do not share a mechanism:

1. `place_dir` copies `skills/<name>/` to `.cursor/skills/<name>` on Cursor.
2. `place_file` copies `skills/<name>/SKILL.md` to `.claude/commands/<name>.md` for the six
   process skills on Claude.
3. Machine mode calls `link_into_place` and **symlinks** `skills/<name>/SKILL.md` into
   `$CLAUDE_HOME/commands/`.

A template token such as `{{COAUTHOR}}` works for 1 and 2 and leaks raw through 3. You cannot
substitute into a symlink, and machine mode is the path where the source file is read directly.

## The shape of a fix

Keep the literal Claude trailer in the source file. Machine mode is Claude by definition, so
the symlinked path is then already right and stays untouched. Have the installer rewrite that
one line to the Cursor trailer when, and only when, `--host cursor`.

The substitution runs in one direction, after the copy, in `place_file` and `place_dir`. The
source stays readable prose rather than a template.

Tests assert that each host gets its own trailer, and that machine mode still resolves to the
Claude line through the symlink.

## Open questions a brief would have to settle

1. **Does the substitution belong in the copy helpers or in a post-install pass?** Putting it
   in `place_file` and `place_dir` means every toolkit file pays for a check that one file
   needs. A single named pass over the installed skill is narrower and easier to test, and it
   adds a step that a future file has to remember to join.
2. **Is one line special-cased, or is there a host-string mechanism?** Today there is exactly
   one such string. A mechanism for one instance is a speculative abstraction. A special case
   is a thing the next host-specific string will not find.
3. **What does a third host do?** The trailer has no neutral value. "No trailer" is a real
   answer and changes what the skill writes on every host.
4. **Does the installed copy get corrected on upgrade?** A project installed before this fix
   carries the wrong line until someone re-installs. The toolkit replaces skills
   unconditionally on every run, so the answer is probably yes and free, but it should be
   stated rather than assumed.

## Why this is a draft and not a brief

The fix is decided in shape and the defect is real and located, so this is closer to a brief
than most drafts here. It stays a draft because question 2 changes what gets built, and
because `#0025` is open and holds the current serial. Filing it takes one run of
`blc-create-brief`.

## Two findings from the same run, each needing its own serial

Recorded here so they are not lost. Neither belongs in this brief — different defects,
different fixes.

**`tools/lib/phase-row.sh` cannot match a backticked phase id.** Line 42 reads

```
pattern="^\|[[:space:]]*~*\`?${idx}[[:space:]]*(\||—)"
```

It allows an opening backtick and provides for no closing one. `` | `a — label` | `` matches.
`` | `a` | label | `` does not, and every phase in such a ledger then reports as missing from
its own table under `BRIEFS-9`. Seen twice in one project, which rewrote its ledgers into the
accepted shape both times. Still present at `2f6aa89`.

**The install log does not survive the `docs/blc/` move as a rename.** `#0020` moves tracked
files with `git mv` and it works: 88 of 93 renames in a real upgrade were byte-identical, and
7 of the 8 rewritten files still pair as renames. `docs/install-log/install-log.md` is the
one that does not, and it still does not at a 40% rename threshold. No content is lost — 335
lines are preserved and 171 appended — but `git log` on the new path starts at the move
commit. The install log is the one file whose whole purpose is continuity.
