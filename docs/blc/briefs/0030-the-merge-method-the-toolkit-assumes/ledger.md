# Ledger — #0030 The merge method the toolkit assumes

`blc/2 #0030 done a:done(PR#131) b:done(PR#133) c:done(PR#135)`

**Brief:** `docs/blc/briefs/0030-the-merge-method-the-toolkit-assumes/brief.md`
**Started:** 2026-10-07
**Status:** done
**Closed:** 2026-10-07

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the move split across two commits | done | PR#131 |
| b | the merge row reads the merge-methods row | done | PR#133 |
| c | the prose, and the count that holds it | done | PR#135 |

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

## Settled while building `b`

**Open question 2 is answered by a field, not by a convention.** `gh repo view` exposes
`viewerDefaultMergeMethod`, which names the method to use where the `*Allowed` fields only say
what is permitted. This repository allows all three, so that field is the only thing that
disambiguates — and it answers `SQUASH`, which is why the hardcoded flag was right here and
nowhere else. Where the default names a method its `*Allowed` field denies, the skill stops and
asks: two repository settings disagreeing is for a person to look at.

GitLab needs two fields rather than one. `squash_option` decides squashing and `merge_method`
decides the rest, so the mapping reads `always` or `default_on` as `--squash`, then
`rebase_merge` or `ff` as `--rebase`, and otherwise passes nothing. Both flags were confirmed
against `glab mr merge --help` on this machine.

**Open question 1 is answered by where it is cheap.** Detection runs at step 9, where the method
is used, not in preflight. Preflight would pay a forge call on every run of the skill, and most
runs never merge.

**Guard 1 matches the merge invocation, not the word.** The skill has to name `--squash` in its
mapping table, which is the opposite of hardcoding it, so a sweep for the flag would forbid the
fix. The guard reads only lines that invoke `gh pr merge` or `glab mr merge`. `--merge-request`
and `--auto-merge` sit on neighbouring rows and do not trip it, which a mutation confirms.

**A test that matched the file was not a test of the command.** The first version asserted
`viewerDefaultMergeMethod` appeared somewhere in the skill. Removing it from the merge-methods
command left it in the mapping table, and the test stayed green over a skill that no longer
fetched the field it picks from. The assertion is now on the line that asks.

## Settled while building `c`

**Half the mentions are correct and must stay.** A survey of the shipped files found 13 uses of
the word. Seven are right: four in `blc-commit-push-pr` are the mapping table and the
merge-methods command that phase `b` added, where naming the flag is the opposite of assuming
it, and three in `tools/lib/touch-log.sh` describe how git reads a rename, with the one claim
about trunk shape already scoped to this repository. This is why decision 4 pins a count per
file rather than forbidding the word.

**`blc-chronicle` was code, not prose.** It reads "squash subjects carrying `[#NNNN]`", which on
a merge-commit trunk finds nothing: the subject is `Merge branch ...` and the serial sits in the
body. The expectation was a sentence to reword and a skill guard to go with it. The sentence was
only the visible half — `gather.sh` greps `%s`, so the digest the chronicle is written from
returned no brief work at all and reported an empty history rather than failing. That made it a
tested fix rather than an unenforced instruction, which is the better outcome and was not
planned for.

It now matches with `--grep`, which reads the whole message, and folds the body's serials onto
the subject's line. Only the serials, not the body: the section has a 60-line ceiling that is
meant to count commits, and a folded-in body would make it count paragraphs instead.

**Reading the whole message meant tightening what a serial is.** A PR number is written exactly
like a serial, and the old match took three digits as well as four, so the forge numbers `#100`
to `#134` already counted. Reading bodies as well as subjects would have widened that from 166
commits to 181 on this repository. The match is now exactly four digits, which is not a guess:
`docs/blc/briefs/README.md` defines a serial as a zero-padded four-digit handle. That drops
every PR number here and takes the count to 177, all of them serials.

A rule written on the leading zero would also work today, and was considered. It was rejected
because it stops at brief #1000, and it stops by dropping serials in silence. Four digits fails
the other way when this forge reaches PR #1000: it over-reports, and an over-report is visible
in the digest. Silence is the failure this brief exists for.

**The first version of the de-duplication was wrong, and a mutation said so.** It tested whether
the subject already showed a serial by searching for the serial followed by a space. Subjects
write it as `[#0001]`, so the check never matched and every ordinary commit would have carried a
duplicate. The serials are now collected as comma-terminated tokens, which also stops `#001`
reading as already shown by `#0012`. Four mutations hold it.

**An apostrophe in a comment broke the whole script.** The awk program is held in single quotes,
so the word `commit's` in one of its comments ended the quoting and the shell read the rest as
code. Every test in the file failed at once, which is the loud way for it to go wrong, and the
constraint is now written at the top of the program rather than left for the next person to
rediscover.

**`blc-start-brief` kept its advice and lost its reason.** It argued the opening ledger must
reach `main` because an unpushed commit "disappears into that branch's squash". On a merge trunk
it would not disappear. The instruction is right for a reason that holds on any trunk — the
owner sees it on every machine that pulls — so the reason was corrected and the instruction left
alone.

**`stale-branches.sh` is prose only.** Two comments there claim this toolkit merges by squash.
The code is correct on a merge trunk regardless: `ancestor` is the stronger test and is tried
first, so a merge-commit branch is proved without reaching `pr`. Only the explanation was wrong.

**Guard 2 pins six counts, and six of the thirteen mentions are correct.** The final counts are
`blc-commit-push-pr` 5, `touch-log.sh` 3, `stale-branches.sh` 2, and one each in
`blc-chronicle/SKILL.md`, `gather.sh` and `blc-prune-stale-branches`. `blc-start-brief` fell to
zero and leaves the list. Both directions are proved: a new mention in any shipped file fails
it, and deleting a pinned line fails it.

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

## What shipped

Three phases, three PRs, eleven tests. `blc_touch_renames` reads a move split across two
commits, so a brief keeps its first date on a trunk that merges (PR#131). `blc-commit-push-pr`
reads the merge method from the forge instead of naming one, and stops where two repository
settings disagree (PR#133). The sites that stated a merge method as a fact are corrected, and
guard 2 pins what remains (PR#135).

All three open questions closed. Question 1 — where detection runs — is at step 9, where the
method is used, because preflight would pay a forge call on every run of the skill and most
runs never merge. Question 2 — what to do when a repository permits more than one method — is
`viewerDefaultMergeMethod` on GitHub, and `squash_option` with `merge_method` on GitLab, which
takes two fields rather than one. Question 3 — how the touch log reads a split move — is a
second walk with `git log --first-parent`, matching identical content only.

## What the record shows that the brief did not predict

**The brief under-scoped phase `c`.** It was planned as a wording pass with a counting guard.
One of its six sites was `gather.sh` grepping `%s` for a serial, which is code, and the
chronicle written from that digest on a merge trunk would have been empty rather than wrong.
A prose pass found a defect because correcting a sentence meant reading what the sentence
described.

**Correcting it widened a second defect, which had to be fixed in the same phase.** Matching
the whole message rather than the subject let PR numbers in, because the old match took three
digits and a PR number is written like a serial. Tightening to exactly four digits is read
from the contract, and it removes a conflation that was already there: on this repository the
section was counting 35 PR numbers as serials before this brief touched it.

**Three of this brief's own claims were wrong and were caught by a mutation or a reader.** The
hardcoded flag was reported as failing and does not fail; the touch log was read as losing
renames made in a merge commit and does not; and a de-duplication check written here never
matched, because subjects write the serial as `[#0001]` and the check looked for a trailing
space. Each correction made the defect worse than the reading it replaced.

## Open after close

**Guard 2 is a report, not a check,** as recorded above. Nothing changes that.

**The four-digit serial match will over-report when this forge reaches PR #1000.** It was
chosen over a leading-zero rule for that reason: it fails by listing a commit that names no
brief, which a reader sees, rather than by dropping one, which nobody sees. Telling a serial
from a PR number properly needs a syntax that distinguishes them, and that is not this brief.

**The split-move walk still misses a move whose content changed between the add and the
delete.** Recorded under phase `a` and unchanged: a missed rename gives a first date that is
too recent, which is the safe direction.

**`-m` on the second walk is unproven.** `--first-parent` has implied it since git 2.36, so no
test here fails without it. It is kept for an older git and said plainly rather than left as a
confident comment.

## What the next brief inherited

A toolkit that no longer assumes how the repository it was installed into merges, and two
guards that make the next such assumption visible to somebody who cannot see the trunk it
would be wrong on. Every finding in this brief came from a person running the toolkit rather
than writing it.
