# The merge method the toolkit assumes

**Created:** 2026-10-07T14:52:00Z · **Author:** josh.stella@gmail.com
**Reported by:** an install-ee, 2026-10-07

## The finding

Shipped skills state that the trunk is squash-merged. That is true of this repository and is not
true of every repository that installs the toolkit. A person running a project with squash
merging disabled reported it.

The report named the prose. The command is the worse half:

```
| Merge (9) | `gh pr merge <n> --squash` | `glab mr merge <n> --squash --auto-merge=false --yes` |
```

Where a forge disallows squash merging, that command does not mislead — it fails. The prose is
what a reader notices first, and step 9 is where the assumption actually stops the work.

## Where it is written

| file | what it asserts |
|---|---|
| `skills/blc-commit-push-pr/SKILL.md` | the merge table hardcodes `--squash` on both forges |
| `skills/blc-commit-push-pr/SKILL.md` | "Because main is squash-merged, the title becomes the commit subject on main" |
| `skills/blc-prune-stale-branches/SKILL.md` | "the only one that can prove a squash merge, which is how this toolkit merges" |
| `skills/blc-chronicle/SKILL.md` | "squash subjects carrying `[#NNNN]`" |
| `tools/stale-branches.sh` | "A squash merge never passes it, and this toolkit merges by squash" |

## What is not broken

`tools/stale-branches.sh` keeps working on a merge-commit repository, and works better there.
Its `ancestor` test is the one a squash merge defeats and a merge commit satisfies, so such a
repository proves more branches, not fewer. Only the comment over-claims.

The `[#NNNN]` prefix still reaches the trunk under a merge commit. It lands in the merge
commit's message rather than as a subject line. Anything that reads subjects alone will miss it;
the reporter worked this out unaided and it should be credited to them.

## The shape of a fix — decided in part

**Detect and adapt.** Step 9 asks the forge which methods the repository allows and passes the
flag that fits. The toolkit already half-believes this: it ships the detection command one table
row below the hardcoded one, and step 9 already says to "confirm this repo's actual default
merge method first if unclear". The hardcoded flag and the parenthetical are the parts that did
not follow.

Open questions a brief would have to settle:

1. Where does detection run — once in preflight, so every later step knows, or at step 9 where
   it is used? Preflight pays for a forge call on every run of the skill, including runs that
   never merge.
2. What happens when a repository allows more than one method? Picking the repository's stated
   default is the obvious answer and is one more field to read.
3. What becomes of the prose that is merely wrong rather than load-bearing — the chronicle's
   "squash subjects", the prune skill's aside? Correcting them is cheap. Leaving them is a
   second copy of the same false fact.
4. Does a guard sweep the shipped trees for merge-method assertions, as #0026's guards sweep for
   agent trailers? That is the mechanism that stops the sixth site appearing. It needs a rule a
   test can state, and "a sentence that assumes squash" is harder to match than an email
   address.

## Why this is the same defect as #0026

A fact that is true of this repository, written into a file that ships to every repository
unchanged. #0026 was an agent name; this is a merge method. Both were invisible here, because
here the assertion is correct.

The install-ee could not fix it locally. An install replaces every toolkit-owned path, so a
local edit to a shipped skill is overwritten by the next install. They said so in the report,
and they were right.

## Why this is a draft and not a brief

#0029 is in flight. Question 4 is the one that decides whether this is a wording pass or a
mechanism, and it is worth more thought than an interrupt allows. The condition that makes it
urgent has already happened — somebody is running it — so it should not sit here long.
