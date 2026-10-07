# The merge method the toolkit assumes

**Serial:** #0030 · **Created:** 2026-10-07T14:52:00Z · **Author:** josh.stella@gmail.com · **Depends on:** —

Reported by a person running an install of this toolkit, 2026-10-07. Every finding below was
either theirs or was proved against their report.

## The report

Shipped skills state that the trunk is squash-merged. That is true of this repository and is not
true of every repository that installs the toolkit. An install replaces every toolkit-owned
path, so the reporter could not correct it locally. They said so, and they were right to send it
here.

## It does not fail, and that is the defect

The forge command table hardcodes the merge flag:

```
| Merge (9) | `gh pr merge <n> --squash` | `glab mr merge <n> --squash --auto-merge=false --yes` |
```

The first reading of this said the command errors where a forge disallows squash merging. The
reporter corrected it. Their GitLab project reports `merge_method: merge` and
`squash_option: default_off`, and `default_off` permits squash and only unticks it by default.
The flag is accepted. The merge request is squashed. Nothing reports anything.

So the toolkit does not stop on a repository that merges differently. It quietly reshapes that
repository's history into the shape this one uses, one merge at a time. Their trunk carries
merge commits — `6276f59`, `32465fd`, `bcb3375` — and a merge run through this skill would not.

A command that fails is a defect somebody finds. This one is visible only to a person who reads
the history afterwards and wonders why one commit is unlike its neighbours.

The skill already half-knows better. It ships a merge-method detection command one table row
below the hardcoded one, and step 9 already says to confirm the method before merging. The
merge row ignores the answer.

## The second defect, which squash merging was hiding

`tools/lib/touch-log.sh:57` says a merge commit records no renames of its own, "and that is fine
for a squash-merge history". The premise is load-bearing and the consequence is real.

The first guess here had the wrong mechanism: it supposed a rename made *in* a merge commit
would be lost. The reporter checked their trunk and showed that does not happen. A merge commit
carries no renames of its own, and `blc_touch_renames` walks the branch commits a merge brings
in, so a `git mv` on a branch is read on either trunk shape.

The real case is a move split across two commits — add the new path in one, delete the old path
in the next:

- `-M` detects a rename **within one commit's diff**. Squashing the branch puts the add and the
  delete in one commit, git reports `R100`, and the old name's history is followed.
- A merge commit keeps them as two commits. Neither diff holds both halves, so
  `--diff-filter=R` reports nothing and the old name's history is cut off.

The reporter proved the mechanism against a real move on their trunk — merge `6667b41`, a config
file, a net rename with no rename record in any commit — and stated plainly that they had
inferred the effect on a brief's dates without building a fixture.

The fixture was built and the inference holds. One branch adds a copy of a brief in one commit
and deletes the original in the next, merged two ways:

| trunk | first date reported for the brief |
|---|---|
| `--no-ff` merge | 2026-06-20, the day of the move |
| squash | 2026-01-10, the day the brief was written |

Every date the toolkit shows comes from this function, so the error reaches `list-briefs.sh`,
the chronicle's era ordering, and `orient.sh`. A brief moved that way reads as new work.

No brief in this repository's record has that shape, which is why every date here is correct.
The comment's author never saw it because on a squash trunk it cannot happen.

## Where the assumption is written

| file | line | what it asserts |
|---|---|---|
| `skills/blc-commit-push-pr/SKILL.md` | 21 | the merge table hardcodes `--squash` on both forges |
| `skills/blc-commit-push-pr/SKILL.md` | 37 | "Because main is squash-merged, the title becomes the commit subject on main" |
| `skills/blc-prune-stale-branches/SKILL.md` | 30 | "the only one that can prove a squash merge, which is how this toolkit merges" |
| `skills/blc-chronicle/SKILL.md` | 37 | "squash subjects carrying `[#NNNN]`" |
| `skills/blc-start-brief/SKILL.md` | 70 | a commit "disappears into that branch's squash" |
| `tools/stale-branches.sh` | 15 | "A squash merge never passes it, and this toolkit merges by squash" |
| `tools/stale-branches.sh` | 120 | "`pr` is the only test that proves a squash merge — the merge this toolkit actually performs" |
| `tools/lib/touch-log.sh` | 57 | the premise above |

The reporter found five. Review here found a sixth. Counting the word rather than reading for
the claim found the last two, which is itself the argument for the second guard below.

## What is not affected

`tools/stale-branches.sh` keeps working on a merge-commit trunk, and works better there. Its
`ancestor` test at line 152 is the one a squash merge defeats and a merge commit satisfies, so
such a repository proves more branches, not fewer. Only the comments over-claim.

The `[#NNNN]` prefix still reaches the trunk under a merge commit. It lands in the merge
commit's message rather than as a subject line. Anything reading subjects alone will miss it.

## What is settled

| # | decision | blocks |
|---|---|---|
| 1 | the merge row takes its flag from the merge-methods row, rather than hardcoding one | b |
| 2 | the touch log reads a split move on any trunk shape | a |
| 3 | guard 1 — no merge-method flag in any skill's forge command table | b |
| 4 | guard 2 — the count of `squash` mentions per shipped file is pinned | c |
| 5 | the fixture is a branch that adds then deletes, merged `--no-ff` | a |

**3 and 4 — why two guards and not one.** The general sentence "assumes squash" cannot be
matched, and the mechanism does not need to match it. This is the reporter's argument and it is
adopted. Guard 1 is mechanical and covers the one site that changes history. Guard 2 does not
prove a sentence is wrong; it makes a new mention a deliberate edit, which is a review signal.
They said so themselves rather than dressing it as proof.

Guard 2 pins a count rather than an allow-list of files. An allow-list cannot catch a new
mention inside a file already on it, and `blc-commit-push-pr/SKILL.md` has to be on it, because
the skill legitimately discusses merge methods — and step 7's prose, the site that started this,
lives in that file. A count makes any new mention visible wherever it appears.

Guard 1 needs care in the pattern. `--merge\b` also matches `--merge-request`, a legitimate
GitLab flag appearing twice in the same table. The pattern must be `--merge([^-]|$)` or
equivalent. This is the same class of defect as #0029 phase `a`, where `[^>]*` silently dropped
every citation anchor containing `>`.

## What is undecided

1. Where merge-method detection runs — once in preflight, so every later step knows, or at step
   9 where it is used. Preflight pays a forge call on every run of the skill, including runs
   that never merge.
2. What happens when a repository allows more than one method. Reading the repository's stated
   default is the obvious answer and is one more field.
3. How the touch log reads a split move. Rename detection across two commits is not something
   `git log -M` offers, so this is a real design question and not a flag.

## The test

Decision 2's fixture is the test, and it must fail before it passes. A branch that adds a copy
of a brief in one commit and deletes the original in the next, merged `--no-ff`, and an
assertion that the brief keeps its original first date. The same fixture squash-merged passes
today, which is the control.

Both guards are ordinary assertions over the shipped trees, in the shape #0026's trailer guards
already use.

## Non-goals

**Do not make this repository merge differently.** Squash merging here is fine and is not the
defect. The defect is asserting it everywhere.

**Do not fix the prose alone.** The wording pass is the cheapest part and stops nothing. Without
guard 1 the history keeps being reshaped, and without guard 2 a ninth site appears.
