# The trailer that credits the wrong agent

**Serial:** #0026 · **Created:** 2026-10-06T04:37:06Z · **Author:** josh.stella@gmail.com · **Depends on:** —

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

## The host already attributes itself, which makes this larger

Measured on this repository's `main`, 2026-10-07, at `187+f33ac5c`.

| what | count |
|---|---|
| commits carrying `Co-authored-by: Claude` | 228 |
| commits carrying `Co-authored-by: Cursor` | 312 |

Two commits were made here by a person, with the skill not involved: `7c2c716` and `6102bba`.
Each carries exactly one Cursor trailer and no Claude trailer. Nobody wrote those lines.

Every squash-merged commit on `main` carries **three** Cursor trailers.

So the host adds its own attribution with no instruction. On Cursor the skill's line is not
only wrong, it is unnecessary, and it lands beside the one the host already wrote. The defect
is a duplicate and a misattribution, not a misattribution alone.

This is one host. Whether Claude Code does the same is not measured here, and it decides
between the two fixes below.

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

## The shape of a fix — two of them, and the evidence favours the second

Keep the literal Claude trailer in the source file. Machine mode is Claude by definition, so
the symlinked path is then already right and stays untouched. Have the installer rewrite that
one line to the Cursor trailer when, and only when, `--host cursor`.

The substitution runs in one direction, after the copy, in `place_file` and `place_dir`. The
source stays readable prose rather than a template.

Tests assert that each host gets its own trailer, and that machine mode still resolves to the
Claude line through the symlink.

**Or: the skill names no agent at all.** If every host attributes itself, as Cursor does here,
then the bug is that the skill writes a trailer rather than which one it writes. Deleting the
line is a smaller change than substituting into it, it needs no token, no post-install pass and
no special case, and it dissolves the symlink constraint above entirely — there is nothing left
to substitute. It also answers question 3 before a third host exists.

What it costs: on a host that does not self-attribute, the commit loses its attribution and
nothing replaces it. That is the measurement this draft does not have.

## Open questions a brief would have to settle

1. **Does the substitution belong in the copy helpers or in a post-install pass?** Putting it
   in `place_file` and `place_dir` means every toolkit file pays for a check that one file
   needs. A single named pass over the installed skill is narrower and easier to test, and it
   adds a step that a future file has to remember to join.
2. **Is one line special-cased, or is there a host-string mechanism?** Today there is exactly
   one such string. A mechanism for one instance is a speculative abstraction. A special case
   is a thing the next host-specific string will not find.
3. **Does every host attribute itself?** Cursor does, measured above. If Claude Code does too,
   "no trailer" is the fix and questions 1 and 2 disappear with it. If it does not, the
   substitution is needed and this question returns as "what does a third host do?". This is
   the first question to answer, because it decides whether the others are asked at all.
4. **Does the installed copy get corrected on upgrade?** A project installed before this fix
   carries the wrong line until someone re-installs. The toolkit replaces skills
   unconditionally on every run, so the answer is probably yes and free, but it should be
   stated rather than assumed.

## Why this is a draft and not a brief

The fix is decided in shape and the defect is real and located, so this is closer to a brief
than most drafts here. It stays a draft because question 3 changes what gets built — and since this
draft was written, the evidence above moved it from a loose end to the first question. Filing it takes one run of
`blc-create-brief`.

## Two findings from the same run, each with its own draft

Found here, fixed elsewhere. Neither belongs in this brief — different defects, different fixes.

- **`tools/lib/phase-row.sh` cannot match a backticked phase id** —
  `docs/blc/briefs/_drafts/phase-row-cannot-match-a-backticked-id.md`
- **The install log does not pair as a rename across the `docs/blc/` move** —
  `docs/blc/briefs/_drafts/the-install-log-that-does-not-pair-as-a-rename.md`
