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

**It does not fail. That is the problem.** The first reading of this draft said the command
errors where a forge disallows squash merging. The reporter corrected it. Their GitLab project
reports `merge_method: merge` and `squash_option: default_off`, and `default_off` means squash
is permitted and merely unticked by default. The flag is accepted. The merge request is
squashed. Nothing reports anything.

So the toolkit does not stop on a repository that merges differently. It quietly reshapes that
repository's history, one merge at a time, into the shape this repository uses. Their trunk
carries merge commits — `6276f59`, `32465fd`, `bcb3375` — and a merge run through this skill
would not.

A command that fails is a defect somebody finds. This one is only visible to a person who reads
the history afterwards and wonders why one commit looks unlike its neighbours.

This is the reporter's conclusion from GitLab's documented meaning of `squash_option`, not from
a run. Nobody has executed it. The fix should not wait for somebody to prove it by damaging a
trunk.

## Where it is written

| file | line | what it asserts |
|---|---|---|
| `skills/blc-commit-push-pr/SKILL.md` | 21 | the merge table hardcodes `--squash` on both forges |
| `skills/blc-commit-push-pr/SKILL.md` | 37 | "Because main is squash-merged, the title becomes the commit subject on main" |
| `skills/blc-prune-stale-branches/SKILL.md` | 30 | "the only one that can prove a squash merge, which is how this toolkit merges" |
| `skills/blc-chronicle/SKILL.md` | 37 | "squash subjects carrying `[#NNNN]`" |
| `skills/blc-start-brief/SKILL.md` | 70 | a commit "disappears into that branch's squash" |
| `tools/stale-branches.sh` | 15 | "A squash merge never passes it, and this toolkit merges by squash" |
| `tools/stale-branches.sh` | 120 | "`pr` is the only test that proves a squash merge — the merge this toolkit actually performs" |
| `tools/lib/touch-log.sh` | 57 | "A merge commit records no renames of its own here, and that is fine for a squash-merge history" |

The reporter found five of these and this repository's own review found a sixth. The last two
rows were found by counting the word rather than reading for the claim, which is itself an
argument for the guard below.

## The one that is not prose — settled, and it is a defect

`tools/lib/touch-log.sh:57` states a *consequence* rather than a fact, and the consequence is
real. The premise is load-bearing.

The first guess here was wrong about the mechanism. It supposed a rename made *in* a merge
commit would be lost. The reporter checked their own trunk and showed that does not happen: a
merge commit carries no renames of its own, and `blc_touch_renames` walks the branch commits a
merge brings in, so a `git mv` on a branch is read on either trunk shape.

The real case is a move split across two commits — add the new path in one, delete the old path
in the next:

- `-M` detects a rename **within one commit's diff**. Squashing the branch puts the add and the
  delete in one commit, so git reports `R100` and the old name's history is followed.
- A merge commit keeps them as two commits. Neither diff contains both halves, so
  `--diff-filter=R` reports nothing and the old name's history is cut off.

The reporter proved the mechanism against a real move on their trunk — merge `6667b41`, a config
file, net rename with no rename record in any commit — and said plainly that they had inferred
the effect on a brief's dates without building the fixture.

**The fixture is built and the inference holds.** One branch that adds a copy of a brief in one
commit and deletes the original in the next, merged two ways:

| trunk | first date reported for the brief |
|---|---|
| `--no-ff` merge | 2026-06-20 — the day of the move |
| squash | 2026-01-10 — the day the brief was written |

The brief was created on 2026-01-10. On a merge-commit trunk it loses five months and reads as
new work. Every date the toolkit shows comes from this function, so the error reaches
`list-briefs.sh`, the chronicle's era ordering, and `orient.sh`.

No brief in this repository's record has that shape, which is why every date here is right.
The comment's author never saw it because on a squash trunk it cannot happen.

## What is not broken

`tools/stale-branches.sh` keeps working on a merge-commit repository, and works better there.
Its `ancestor` test at line 152 is the one a squash merge defeats and a merge commit satisfies,
so such a repository proves more branches, not fewer. Only the comments over-claim. The reporter
confirmed this against their own install and noted, correctly, that they had never claimed
otherwise — that point was raised here, not by them.

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
4. ~~Does a guard sweep the shipped trees for merge-method assertions?~~ **Answered by the
   reporter.** See below.

## The guard — the reporter's answer to question 4

Their argument: the general sentence "assumes squash" cannot be matched, and the mechanism does
not need to match it, because two narrower rules are checkable.

**Rule 1 — no merge-method flag in a forge command table.** A test refuses `--squash`,
`--merge`, and `--rebase` in any skill's forge commands. The merge row then has no choice but to
take the method from the merge-methods row one line below it. As mechanical as #0026's email
guard, and it covers the one site that changes history.

This is the right rule. One implementation note, from the defect this repository shipped in
#0029 phase `a`: a naive `--merge` match is wrong. `--merge\b` matches `--merge-request`, which
appears twice in the same table as a legitimate GitLab flag. The pattern has to be
`--merge([^-]|$)` or equivalent. A guard that fires on the wrong line gets switched off.

**Rule 2 — the word `squash` only in an allow-list of files.** A new mention becomes a
deliberate edit to that list, and therefore visible at review. The reporter is explicit that
this proves nothing about whether a sentence is right; it makes a new assumption visible.

**Rule 2 has a hole, and the reported defect is in it.** An allow-list of *files* cannot catch a
new mention inside a file already on the list, and `skills/blc-commit-push-pr/SKILL.md` must be
on it — the skill legitimately discusses merge methods. Step 7's prose, the site that started
this, lives in that file. The guard as stated would have let it through.

Pin the count instead of the file. Today, per shipped file: `blc-commit-push-pr` 3,
`stale-branches.sh` 2, and one each in `touch-log.sh`, `blc-start-brief`, `blc-prune-stale-branches`,
and `blc-chronicle`. A test holding those numbers makes *any* new mention a deliberate edit to a
number, inside an allowed file or not, and the numbers fall as the prose is corrected.

Rule 1 is the mechanism. Rule 2 is a review signal, and the reporter says so plainly rather than
dressing it as proof — which is the distinction this project's own value states as "a skill
guard is not a check".

## Why this is the same defect as #0026

A fact that is true of this repository, written into a file that ships to every repository
unchanged. #0026 was an agent name; this is a merge method. Both were invisible here, because
here the assertion is correct.

The install-ee could not fix it locally. An install replaces every toolkit-owned path, so a
local edit to a shipped skill is overwritten by the next install. They said so in the report,
and they were right.

## Why this is a draft and not a brief

It should not be a draft any longer. Both questions that held it here are answered: the guard
has a checkable rule, and the touch log has a proven defect with a fixture that reproduces it.

What remains is a serial and a phase plan, roughly:

- the touch log reads a split move on any trunk shape — the correctness defect, with the
  fixture above as its test
- the merge row takes its flag from the merge-methods row, with rule 1 as its guard
- the prose pass over the remaining sites, with rule 2's pinned counts as its guard

The condition that makes this urgent has already happened. Somebody is running it, both failure
modes are silent, and one of them rewrites their history while the other misdates their record.
