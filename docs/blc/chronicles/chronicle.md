# Chronicle — brief-ledger-chronicle

| serial | title | status | first | last | depends-on |
|---|---|---|---|---|---|
| #0007 | Jira as a reporting surface, written from BLC | done | 2026-09-07T23:09:10-04:00 | 2026-10-01T14:38:30-04:00 | — |
| #0016 | The readers that guess | done | 2026-09-30T16:45:08-04:00 | 2026-10-01T11:05:31-04:00 | — |
| #0015 | The interpreter nothing pins | done | 2026-09-29T14:01:37-04:00 | 2026-09-30T11:47:50-04:00 | #0014 |
| #0014 | The shape nothing prescribes | done | 2026-09-16T05:59:30-07:00 | 2026-09-29T13:18:40-04:00 | #0013 |
| #0013 | A reader that cannot find it reports it missing | done | 2026-09-16T04:11:33-07:00 | 2026-09-16T04:59:49-07:00 | — |
| #0011 | A project cannot add a gate | done | 2026-09-09T09:41:04-04:00 | 2026-09-10T20:45:11-04:00 | #0012 |
| #0012 | An install is not an update | done | 2026-09-09T09:41:04-04:00 | 2026-09-10T14:36:35-04:00 | — |
| #0008 | The record outgrew the reader | done(PR#45) | 2026-09-07T23:09:10-04:00 | 2026-09-09T07:29:06-04:00 | #0006 |
| #0010 | The skills live in someone else's namespace | done(PR#39) | 2026-09-08T09:29:26-04:00 | 2026-09-09T06:45:49-04:00 | #0009 |
| #0009 | One name for a phase, used everywhere | done(PR#36) | 2026-09-07T23:09:10-04:00 | 2026-09-09T06:26:43-04:00 | #0004 |
| #0006 | One chronicle, newest first, with a brief table | done(PR#30) | 2026-09-04T12:18:22-04:00 | 2026-09-07T23:09:10-04:00 | — |
| #0005 | Closing the single-writer holes before the second writer arrives | done(PR#26) | 2026-08-25T10:13:58-04:00 | 2026-08-26T09:56:07-04:00 | #0003, #0004 |
| #0004 | The ledger is an archive and a bad inbox | done(PR#18) | 2026-08-24T14:25:31-04:00 | 2026-08-24T14:47:30-04:00 | #0003 |
| #0003 | A fourth artifact: the Contract | done(PR#11) | 2026-08-21T15:52:02-04:00 | 2026-08-24T14:41:42-04:00 | — |
| #0002 | Add MIT license | done(commit 383ed5b) | 2026-08-02T13:50:18-04:00 | 2026-08-24T14:41:42-04:00 | #0001 |
| #0001 | Bootstrap: brief-ledger-chronicle repository | done(commit 92a7168) | 2026-08-02T13:38:06-04:00 | 2026-08-24T14:41:42-04:00 | — |

As of 2026-10-01, all sixteen briefs are done and no phase is open. The most recent close is
#0007, which exports a brief to Jira as a one-shot CSV import. It closed with two of its own
success criteria unmet: a ledger status change does not update Jira, and nothing restores a
hand edit on the board. The ledger records that gap and says a live publisher is not planned.
Four drafts wait in `docs/briefs/_drafts/` with no serial. They are about the toolkit's
unmarked footprint in an adopter's `docs/` tree, a memory layer that three skills read and
nothing writes, an install that records no provenance, and the unmeasured cost of handing a
brief to another person. A fifth draft, on polling peers for work in progress, is marked
superseded and stays only because older briefs cite it.

## The tracker, and the readers that guess — 2026-09-30 to 2026-10-01

**#0007** was filed on 2026-09-07 and waited three weeks. Its subject was Jira as a reporting
surface. Managers would report from a board they already know, and the people doing the work
would change it in the record. The brief settled the direction before any code: "One-way,
BLC → Jira." A brief is an Epic, a phase is a ticket, and a new `Owner:` field says who
executes a brief when that is not its author. "The record stays in git."

When execution started on 2026-09-30, the ledger opened with a re-plan against the repository.
The brief described a `blc/1` status line, numbered phases and old skill names, and the
repository had moved past all three. A separate test phase dissolved into the phases whose
programs it would pin. The publisher had no seam a test could reach, which became an open
decision of its own.

Phase `a` (PR#69) was documentation, and it carried the brief's two main forks. The first was
where a phase ticket's Jira key should live. The status line and the phase table were both
hardened artifacts with readers that would misread a key. The choice was "nowhere. A phase
ticket is found, not recorded." A ticket summary has the form `#<serial>/<letter> — <label>`,
which #0009 had already made derivable, so a key can be regenerated from the record and never
needs storing. The ledger states the cost plainly: "The label is part of the summary, so it is
a sync surface." The second fork was whether `Owner:` and `Jira:` deserved a Contract clause.
The answer was no: "This is an export, not part of how BLC works." A malformed `Owner:` would be
reported on stderr by the query that reads it, not gated by the validator.

**#0016** was filed the same afternoon and ran ahead of #0007's later phases. Its subject was a
pattern the record had now shown three times: ad hoc Markdown readers that disagreed about the
same file until someone tested them side by side. The identity line still had two readers that
disagreed about where `Depends on` ended. The pointer reader treated anything that was not a
PR or a commit as a branch name, so a GitLab merge request token became a missing branch.
Four phases, PR#70 to PR#73, gave the identity line one shared reader, gave pointers a stated
vocabulary that reports what it does not recognise, added `tools/detect-forge.sh`, and taught
the skills and the installer to work with either `gh` or `glab`. Moving the `BRIEFS-5` gate
onto the shared reader carried a rule: "nothing that failed may now pass." Nine fixtures changed
verdict under the new reader. None of them was one of the sixteen real briefs.

#0016 changed #0007's remaining plan, and the ledger records a second re-plan on 2026-10-01.
`open-briefs.sh` had become a report of phase-level exceptions, so "what is mine" became a flag
on `list-briefs.sh` instead. Phase `b` (PR#75) carried the new fields through `blc-create-brief`.
Phase `c` (PR#76) added `list-briefs.sh --owner` and a `blc-my-briefs` skill that fetches before
it asks. The publisher waited for a Jira tenant that did not exist.

Later the same day, phase `d` was re-planned again, as a CSV file for Jira's own importer.
Atlassian's documentation gave three facts that decided the shape: one file can carry the Epic
and its children, the importer assigns by email, and a second import duplicates every row.
Four open decisions dissolved because the export calls nothing. `tools/jira-csv.sh` (PR#78)
exports one brief and refuses a brief it cannot export whole. Review before merge found two
defects: the Epic row kept its status pointer, and the label reader could take a status cell
for a label. Both were fixed before merge. The closeout (PR#79) recorded the gap described above.

## The shape nothing prescribes — 2026-09-16 to 2026-09-30

**#0013** began in an adopting repository with forty-two ledgers. After install,
`open-briefs.sh` reported a false `[drift]` and a false `[no-line]`. In both cases the record was
correct and the reader was narrow: it looked for one shape, did not find it, and blamed the
record. The brief's claim was that a reader reports what it found, not what it failed to look
for. Phase `a` (PR#55) let the row scan consider every matching row, and phase `b` (PR#56) made a
status line under YAML frontmatter legal. The fork was whether to keep the line's position
strict and only improve the message. The ledger rejected that: two of the three readers already
accepted frontmatter, and detecting it only to decline it costs as much as reading it.

The same ledger found the cause behind the symptom. Nothing prescribed the phase table's shape.
On 2026-09-09 a run wrote a split-column table, later runs imitated it, and the letter matcher
was "dead for the week" without one failing test, because a row nobody can find produces no
finding. #0013 fixed the reader and left the shape to a draft.

That draft became **#0014**. Its claim was findability, not a prescribed layout: a phase id on
the status line that no row can be found for is a problem, and the validator should say so.
Phase `a` (PR#61) moved the row matcher into `tools/lib/phase-row.sh`. Phase `b` (PR#62) was
inserted during execution, and it gave the status line one shared locator. The locator search
was anchored after a baseline showed why: "Finding the wrong line is worse than finding none."
Phase `c` (PR#63) published `BRIEFS-9` and `BRIEFS-10` in Contract v1.2, and phase `d` (PR#64)
wrote the criteria for promoting a judgment clause to a defect.

The central fork was whether the new clauses should block. The answer was "it complains and
never blocks." A wrong `[judgment]` costs a warning. A wrong `[defect]` "breaks someone else's
build on the day they upgrade." The close states the consequence without softening it: the
brief claimed a defect and shipped a judgment, and the ledger records that as a gap rather than
rewriting the success criteria. Review across the phases found seven guards that could not
fail, which produced a published rule: one mutation per code path a guard claims.

**#0015** followed directly. #0014's first promotion criterion needed the checks to pass under
every claimed awk interpreter, and "No such claim exists." The draft expected a live defect
under `mawk`. Execution falsified that before any code changed, because the suite already
passed. Phase `a` (PR#66) ran the suite under every awk on the PATH and named the ones it could
not find. Phase `b` (PR#67) answered where the claim should be written: "nowhere" in prose. The
interpreter set lives in `tests/run.sh`, and documents point at the command that prints it,
because "A prose copy would be a second answer." CI now runs four interpreters.

## Ownership: what the installer owns, and what a project may add — 2026-09-09 to 2026-09-10

**#0012** named a fact about `install.sh`: a re-run skipped existing paths and removed nothing,
so there was no update, only a first install and later gap-filling. After #0010's rename, a
reinstall left the old skills beside the new ones, and the result "reads as the workflow
working." #0010 had predicted this: "The next rename will have to build what this one skipped."
Four phases, PR#50 to PR#52, declared an ownership map, replaced toolkit-owned files on every
run, pruned skills and commands that the install log showed the toolkit had placed, and told
users plainly that local edits to those files do not survive. The ownership map met the code
and gained a third owner, `append`, that the two-column design had not foreseen. `--force` was
retired, because "A flag that does nothing is a trap."

**#0011** depended on that map. A project could add guidance but not a gate: the validator ran
eight fixed clauses with no place for a ninth. Phase `a` (PR#53) made `validate-briefs.sh` run
scripts from a project-owned `brief-checks/` directory after its own clauses, and phase `b`
(PR#54) proved it with eight tests. The directory has no `blc-` prefix on purpose. `blc-` had
come to mean "replaced on update", and this is the one path where the opposite holds. The brief
was candid about its footing: "Nobody has asked for this." It was built on a belief that teams
have house rules, and it says it is worth abandoning if that belief is wrong.

## Names, and a verb for orientation — 2026-09-07 to 2026-09-09

**#0009** settled what a phase is called before a tracker could invent a second scheme. Numbers
already meant briefs in speech, so "Do 3 on 6" could not be parsed. Phases became letters, and
the status line became `blc/2`. The ledger reversed the brief's order: readers first, then the
convention, because a skill writing `blc/2` before the parsers could read it would drop briefs
from the chronicle "with no error." The work landed in PR#34 to PR#36, forward-only, with no
historical ledger rewritten. One open decision, the Jira summary format, passed to #0007.

**#0010** prefixed every skill with `blc-`. Nothing collided yet, and the brief named that as
the problem: "a fact about this week, held in place by nobody." Two phases, PR#38 and PR#39,
renamed nine skills, removed `to-do`, and pinned the namespace with tests. A planned third phase,
an installer that would remove the old names, was dropped because only one install existed:
"Reinstalling was the migration." Two days later #0012 built that removal for every install.

**#0008** began from a missing file. Agents were told to read `AGENTS.md`, and this repository
had none. What it had was tens of thousands of tokens of record that agents did not read
cheaply, so they re-derived settled decisions. The brief made orientation a verb. Five phases,
PR#41 to PR#45, moved the brief table into `tools/list-briefs.sh`, added per-contributor
declarations under `docs/state/`, added `tools/orient.sh` with a `blc-orient` skill, tested it,
and pointed the process skills at it. The same brief dropped the peer-polling draft: "dropped,
not deferred." The record has gaps here. Three of the brief's open decisions show no written
resolution in the ledger, and the closeout leaves the rule for filtering a large repository
unproven.

## The chronicle enters the record — 2026-09-04 to 2026-09-07

**#0006** reversed a rule that #0003 and the installer had set: never commit a chronicle. Use
had moved to one document at a fixed path, newest first, with a brief table at the top. Phases
landed in PR#28 to PR#30. `gather.sh` gained the table, the skill learned to edit one file in
place, and the ignore rule stopped hiding that file. A fifth phase came from review. The
Manifesto still called the Contract the only derived artifact in git, and the brief named the
error in the earlier reasoning: "#0003 treated 'derived' and 'uncommitted' as one property.
They are not." This file is the result.

## The Contract and the single writer — 2026-08-21 to 2026-08-26

**#0003** added a fourth artifact. Briefs, ledgers and chronicles recorded how the system came
to be, and none stated what it is. The invariants already existed, scattered, duplicated and
unchecked, and "A contract that has drifted is worse than no contract, because it is believed."
Three phases, PR#9 to PR#11, extracted Contract v1, built `tools/validate-briefs.sh`, and ended
the hand-synced README copies. Two planned phases were skipped. One fork kept the tag name
`[judgment]` over a tidier alternative, because another skill reads it in other projects:
"Change the name nobody reads, not the one something reads." The ledger also reframed the
artifact: "A Contract is a claim someone stakes, not a stage a system reaches," and overclaiming
is the defect class.

**#0004** found that the toolkit recorded deferrals faithfully and surfaced them never. The
evidence came from a consuming project: a phase deferred for fifty-seven days, its branch 248
commits behind. Three phases, PR#15, PR#17 and PR#18, documented the hole, fixed a status
vocabulary with a `blc/1` status line, and added `tools/open-briefs.sh`. Its forks produced
rules that later briefs still use: "if a reason was given, it is `deferred`", "An
acknowledgement has a shelf life", and "a stale line is worse than no line." The query found
three defects in the session that built it. One was PR#16, which merged into its stacked base
rather than `main`: "work that looks landed and is not." The ledger also said what was still
missing: "Nothing invokes the query."

**#0005** prepared for a second writer. Three single-writer assumptions were load-bearing:
serial allocation, one ledger with one writer, and a skill that could overwrite another
person's ledger. PR#26 stated the assumptions, told `blc-start-brief` to refuse an overwrite,
and fixed one owner per serial. Remote-aware allocation was skipped: leave the race and renumber
the loser, because fetching first does not close it. Asked whether the skill's guard could be
verified, the ledger answered "it is not," and labelled it as an instruction.

## Origin — 2026-08-02 to 2026-08-21

The repository began on 2026-08-02 with commit `92a7168`, a Cursor-native port of an earlier
Claude Code process toolkit. It shipped ten skills installed into `.cursor/skills/`, with
project rules in `AGENTS.md`, and it was renamed brief-ledger-chronicle the same day. **#0001**
records that creation as one action. **#0002** added the MIT license directly on `main`, before
its brief existed, and the ledger records it retroactively with the note that "the convention
is brief first, then work."

The record is then silent for nineteen days. On 2026-08-21, six pull requests and two direct
commits landed without a brief serial. They gave one source tree for both Claude Code and
Cursor, made Simplified Technical English the default for process prose, added the Manifesto,
and split process rules from project architecture. Those changes shaped everything above, and no brief or ledger explains them.
This chronicle can report only what flowed through the registry.

<!-- chronicle:closed-through:2026-10-01 -->
