# Ledger — #0030 The merge method the toolkit assumes

`blc/2 #0030 in-progress a:in-progress(brief/0030-a-the-move-split-across-two-commits) b:pending c:pending`

**Brief:** `docs/blc/briefs/0030-the-merge-method-the-toolkit-assumes/brief.md`
**Started:** 2026-10-07
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the move split across two commits | in-progress | `brief/0030-a-the-move-split-across-two-commits` |
| b | the merge row reads the merge-methods row | pending | — |
| c | the prose, and the count that holds it | pending | — |

**a — the move split across two commits.** Make `blc_touch_renames` read a move that was made as
an add in one commit and a delete in the next, so a brief keeps its first date on a merge-commit
trunk. The fixture comes first and must fail: a branch that adds a copy of a brief and deletes
the original in the next commit, merged `--no-ff`, asserting the original first date survives.
The same fixture squash-merged passes today and is the control. How the rename is detected across
two commits is open — `git log -M` does not offer it.

**b — the merge row reads the merge-methods row.** Remove the hardcoded `--squash` from the forge
command table and make step 9 take the method from the merge-methods row it already ships. Guard
1 ships with it: a test refusing `--squash`, `--merge` and `--rebase` in any skill's forge
commands, with a pattern that does not fire on `--merge-request`.

**c — the prose, and the count that holds it.** Correct the remaining assertion sites. Guard 2
ships with it: the count of `squash` mentions per shipped file, pinned, so a new mention is a
deliberate edit to a number wherever it appears. The counts fall as the prose is corrected, so
this phase sets them last.

## Dependency structure

`a` is independent and could branch now in parallel — it touches `tools/lib/touch-log.sh` and
nothing else in this brief does.

`c` follows `b`. Guard 2 pins per-file counts of the word, and `b` removes one of them from
`blc-commit-push-pr/SKILL.md`. Pinning the counts before `b` lands would pin a number that `b`
then has to change.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | the merge row takes its flag from the merge-methods row | b |
| 2 | the touch log reads a split move on any trunk shape | a |
| 3 | guard 1 — no merge-method flag in any skill's forge command table | b |
| 4 | guard 2 — the count of `squash` mentions per shipped file is pinned | c |
| 5 | the fixture is a branch that adds then deletes, merged `--no-ff` | a |

Decisions 3 and 4 are the reporter's, adopted as argued. Decision 4 pins a count rather than an
allow-list of files, because an allow-list cannot catch a new mention inside a file already on
it, and the site that started this lives in exactly such a file.

## Settled while building `a`

**Two walks, with different thresholds.** The open question — how a rename is read across two
commits — is answered by `git log --first-parent -m`, which shows each merge commit's diff
against its first parent. That is the change a squash of the branch would have carried, so it
recovers the split move in one pass rather than one `git diff` per merge.

**The thresholds must differ, and that is the whole design.** Walk 2 matches identical content
only. Its candidate pool is everything a branch changed, and at git's default similarity it
paired an unrelated new brief with an unrelated deleted one at 58% — handing the new brief a
date from before it existed, which is the `--follow` failure #0017 removed. Walk 1 stays loose
because its pool is one commit's changes, and because filing a draft as a brief edits the file
while moving it: every brief in this record was filed that way, and at 100% each loses its
draft date.

Both directions are now pinned. Tightening walk 1 fails the draft-filing test; relaxing walk 2
fails the unrelated-pair test; removing walk 2 restores the reported defect.

**What it still misses.** A split move whose content also changed between the add and the
delete. That is the safe direction: a missed rename gives a first date that is too recent, and
a false pair gives one that is too old and silently merges two briefs' histories.

**`-m` is unproven here.** `--first-parent` has implied it since git 2.36, so no test fails
without it on any git new enough to run this suite. It stays because it is free and an older
git needs it, and because dates that are quietly wrong on an old git is the failure this brief
is about. Said here rather than left as a confident comment.

## What this brief owes the reporter

Every finding here came from somebody running the toolkit rather than writing it, and two of
this repository's own readings were wrong before they corrected them: that the hardcoded flag
fails, and that the touch log loses renames made in a merge commit. Both corrections made the
defect worse, not milder.

The structural reason matters more than the courtesy. **This defect is invisible from here.** On
a squash trunk the touch-log failure cannot occur and the hardcoded flag is correct, so no
amount of testing in this repository would have surfaced either. The comment's author wrote a
premise that was true of everything he could see.

That is the argument for both guards. They do not make the assumption true; they make the next
one visible to a person who also cannot see it.

## What this cannot prove

Guard 2 is a review signal and not a check. It reports that a count changed. It cannot say
whether the sentence that changed it is right, and a person who updates the number without
reading the sentence defeats it completely. The reporter said this plainly when proposing it,
and it is recorded here rather than softened.
