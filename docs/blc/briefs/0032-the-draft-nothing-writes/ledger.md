# Ledger — #0032 The draft nothing writes

`blc/2 #0032 done a:done(PR#139) b:done(PR#140)`

**Brief:** `docs/blc/briefs/0032-the-draft-nothing-writes/brief.md`
**Started:** 2026-10-08
**Status:** done
**Closed:** 2026-10-08

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the skill that writes a draft | done | PR#139 |
| b | the machine-level command | done | PR#140 |

**a — the skill that writes a draft.** Ship `skills/blc-create-draft/`, its tracked symlink
under `.claude/skills/`, and the rewritten descriptions on both the drafter and the filer. The
test comes first and must fail: the provenance template in the drafter is the one
`blc-create-brief` reads, asserted by the method `tests/test_identity_line.sh` already uses on
the filer. It fails today because there is no drafter.

**b — the machine-level command.** Add `blc-create-draft` to `PROCESS_SKILLS`. The list is
hand-written in four places — `install.sh`, `tests/test_hosts.sh`, `tests/test_machine_mode.sh`
and `tests/test_skill_names.sh` — so this phase is the four edits and the machine-mode tests
that read them.

## Dependency structure

`b` follows `a`. Naming a skill in `PROCESS_SKILLS` before the skill exists fails the
machine-mode tests, which assert a command link for every name on the list.

The four copies of that list are not this brief's to fix. They are a hand-maintained second
copy of a fact — the kind "Derived beats declared" exists to catch — and noticing that while
adding a fifth entry to it is worth recording even though nothing here acts on it.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | a skill writes drafts; it does not file, number, or commit | a |
| 2 | it joins `PROCESS_SKILLS` | b |
| 3 | both descriptions are rewritten, not only the new one | a |
| 4 | the provenance template is pinned by a test | a |
| 5 | an empty body is written as an empty body | a |
| 6 | `Depends on` is always written, `—` when absent | a |
| 7 | the report names a draft that has no body | a |

**Decision 7 answers the brief's one open question.** Decision 5 keeps an empty draft, and an
empty draft is also what a run that stopped half way leaves behind. The two are identical on
disk, so the report is the only place they can be told apart. It says so once, at the end, for
the file it just wrote — not as a warning, because nothing is wrong.

**Decision 3 is the one that touches shipped prose.** The two descriptions cross their nouns
today: the filer offers "file a draft brief" and the drafter would offer "write an unnumbered
brief". The word that separates them sits on the wrong skill in each case, and the filer is the
one-way door, so the more confusable sentence is guarding the irreversible step. Rewording only
the new skill leaves half of a mutual ambiguity in place.

**Decision 4 is why this is not a documentation change.** `blc-create-brief` step 4 reads
`Created` and `Author` out of the draft. A draft missing them does not fail — the filer stamps
`Created` = now and resolves `Author` from git config — so the brief is filed with the date it
was filed rather than the date the idea was had. The failure is a wrong date in the permanent
record, written in silence. That is a contract between two skills, and this repository already
tests the filer's half of it.

## Attribution

The skill was proposed by **Alan Read, `alan@ariatha.ai`**, who wrote it against an installed
project and found the change could not survive there, because an install replaces every
toolkit-owned path.

The filing commit `d7e7f65`, already on `main`, carries a mistyped address — `alan@ariath.ai`,
missing the second `a`. A forge matches co-authorship by address, so that trailer credits
nobody. It is recorded here rather than rewritten: `main` is published, other checkouts install
from it, and a correct name in the record is worth more than a tidy history. Every later commit
on this brief carries the right address.

## Settled while building `a`

**The guard is two tests, because the contract has two halves.** One reads the drafter's
template and pins the field order. The other reads the *filer* and asserts it still says
`<from draft>` for `Created` and `Author`. Without the second, the contract could be broken
from the far end — the filer could stop reading the fields while the drafter went on writing
them, and a test that only looked at the drafter would stay green over it.

**A weak assertion was caught before it shipped.** The first version checked that the word
"always" appeared anywhere in the skill. It happened to be true for the right reason, which is
the worst case: the assertion would have passed over a file that said "always" about something
else entirely. It now reads the line that names the field. This is the same error the #0030
review found, where a file-wide match stood in for a test of the command.

**Then the tightened version failed on its own markup.** `Depends on.*always written` does not
match `is **always** written`. Caught by running it rather than by reading it, which is the
argument for a baseline run between writing a guard and mutating it: a guard that fails at
baseline cannot tell you anything about a mutation.

**The phase split is visible in `--print-ownership`.** After `a`, the installer reports
`skills/blc-create-draft` placed as a directory by the glob, while `blc-create-brief` is placed
as `.claude/commands/blc-create-brief.md`. That command file is what `PROCESS_SKILLS` buys and
what `b` adds, so the two phases are separable in the installer's own output rather than only
on paper.

**The drafts README was the other half of the finding.** It described the filer completely and
named no writer, which is how the gap stayed invisible. It now names the drafter and states the
consequence of writing one by hand, so the document that created the expectation carries the
correction.

## Settled while building `b`

**The list is copied in five places, not four.** The plan named `install.sh` and three test
files. The fifth is `tests/test_project_mode.sh`, which wrote the *count* — `assert_count 6` —
rather than the names, so a search for the names never found it. A count is a copy of a fact
like any other and goes stale the same way. Six more copies of the same number sat in prose:
`README.md`, three comments in `install.sh`, `docs/architecture/README.md`, and the comment
above the failing test.

**This phase partly did what the plan deferred, and that is a deliberate reversal.** The
dependency section says the copies are "not this brief's to fix". The prose counts are now
reworded to carry no number, and the one in `test_project_mode.sh` is read out of
`install.sh`. The reason is narrow: bumping `6` to `7` would have reinstated the exact defect
the phase had just removed from six other sites. The four copies of the *names* are untouched
and still hand-maintained, so the deferral stands for what it was written about.

**`a` shipped a defect that the whole suite was blind to.** It linked `blc-create-draft` into
this checkout as `.claude/skills/blc-create-draft` — correct for a utility skill, wrong for a
process one, which belongs at `.claude/commands/<name>.md`. Nothing failed. Every test on this
path reads what the installer writes into a *target*; none read this repository's own links,
so the toolkit could ship a correct install while being unable to invoke the command itself.
`test_skill_names_this_repo_links_its_process_skills_as_commands` is the guard, and it was run
against the defect before the link moved.

**The derived count was mutated twice before it was believed.** Declaring a name the installer
cannot place fails it; breaking the `sed` that reads the list fails it with its own message
rather than passing on an empty string. Without the second, a renamed variable would have made
the assertion read zero and compare zero against zero.

## What shipped

Two phases, two PRs. `skills/blc-create-draft/` writes an idea into
`docs/blc/briefs/_drafts/` with no serial, and `PROCESS_SKILLS` carries its name, so Claude
Code installs it as `/blc-create-draft` and Cursor as an ordinary skill. The descriptions on
the drafter and the filer no longer cross their nouns. `tests/test_identity_line.sh` pins the
provenance template the drafter writes and the filer reads, from both ends.

All seven settled decisions held. None was re-opened by the work.

## What the record shows that the brief did not predict

**The brief was filed to close a gap in the record, and the work found two more of the same
kind.** The gap was a missing writer: everything described how a draft is *filed* and nothing
described how one is *written*, so drafts were written by hand and arrived missing the fields
the filer reads. Phase `b` then found the list of process skills copied in five places, one of
them holding a count rather than names, and six more copies of that count in prose. Same
shape: a fact stated in more places than anything reconciles.

**The suite could not see this repository's own links.** Every test on that path reads what
the installer writes into a target. Phase `a` put the new skill in the wrong one of this
checkout's two link trees and the suite stayed green, so the toolkit could have shipped a
correct install while being unable to run the command itself. The gap was in what the tests
*looked at*, not in what they asserted.

**A count is a copy.** Six prose sites and one assertion said "six process skills". Searching
for the skill *names* found none of them. The rewording removed the number rather than
bumping it, which is the only version of the fix that does not have to be made again.

**The attribution was wrong in the first commit.** The proposer's address was mistyped in a
commit already on `main`, where a forge credits co-authorship by address and so credited
nobody. It is recorded above rather than rewritten, because `main` is published and other
checkouts install from it.

## Open after close

**Nothing runs a skill, so the drafter is unproven in use.** The tests pin the template it
shows. Whether an agent reading it produces a draft with those fields is not measured here.
This is the "A skill guard is not a check" case and it is the brief's central limit, not a
footnote.

**The four hand-written copies of the process names remain.** This brief added a seventh name
to each by hand and deliberately did not build the mechanism that would make that unnecessary.
The count was derived because leaving it would have re-created a defect the same phase had
just removed; the names were left alone. An eighth process skill will need the same four edits.

**No test asserts that the four copies agree.** Adding one is cheap and was not done, so the
drift this brief worked around is still undetected until an install places the wrong set.

**`BLC_UTILITY` in `tests/test_skill_names.sh` is defined and never read,** and lists three of
the eight utility skills. Noticed while editing the line above it. Nothing acts on it here.

**The drafts README now names the drafter, and no test reads that.** `blc-create-draft` could
be renamed and that document would go stale the way `/create-brief` did, which the sweep in
`test_skill_names.sh` exists to catch for the old names only.

## What this cannot prove

A skill is prose and nothing runs it. The test pins the template the skill shows; it cannot
make an agent follow the steps around it. This is the "A skill guard is not a check" case, and
it is named here rather than left to look like coverage.

The drafter also cannot be proved to help. The defect it addresses — a filed brief carrying the
filing date instead of the authoring date — is already in this repository's record, in every
brief filed from a hand-written draft that omitted the line. Nothing measures how often that
happened, and this brief does not go back and look.
