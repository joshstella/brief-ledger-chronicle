# The draft nothing writes

**Serial:** #0032 · **Created:** 2026-10-08T11:40:00Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## The finding

`docs/blc/briefs/_drafts/README.md` tells a contributor that a draft is an idea written
down, that drafts are committed, and that `/blc-create-brief` owns numbering and is the
one-way door. It describes the filer completely and never says what writes the draft.

Nothing does. The toolkit ships fourteen skills and not one of them writes into
`_drafts/`. Every draft in this repository was written by hand, including this one, and
the shape they share is a convention nobody checks.

This matters more than a missing convenience, because the draft is an input to a skill.
`blc-create-brief` step 4 reads `Created` and `Author` out of the draft and consumes them
into the identity line. A hand-written draft that omits them does not fail: the filer
stamps `Created` = now and resolves `Author` from git config, so the brief is filed with
the date it was filed rather than the date the idea was had. The record loses the one fact
the draft existed to keep.

Proposed by a colleague, who wrote the skill against an installed project and found the
change could not survive there. Toolkit-owned paths are replaced by the next install, so
the fix belongs here.

## What is settled

1. A skill writes drafts. It does not file, number, or commit.
2. It joins `PROCESS_SKILLS`, so Claude Code reaches it as a machine-level command.
3. Both descriptions are rewritten. The filer and the drafter currently cross their nouns:
   the filer says "file a draft brief" and the drafter says "write an unnumbered brief",
   so the word that distinguishes them appears on the wrong one.
4. The provenance line the drafter writes is pinned by a test, the way
   `tests/test_identity_line.sh` already pins the filer's identity line. It is a contract
   between two skills, not a format preference.

5. An empty body is written as an empty body. A parked idea with nothing under the title
   is legitimate, and a skill that invents a finding to avoid an empty file is the worse
   failure by a long way.
6. `Depends on` is always written, with `—` when the user gives none. Every draft in this
   repository carries it. The filer reads both shapes, so this is for the next person
   reading the directory rather than for the tool.

## What is undecided

1. **Whether the drafter should report that a draft is empty.** Settled decision 5 keeps
   the empty file. It does not say whether the skill's report distinguishes "you asked for
   a title and nothing else" from "the command was abandoned half way".

## The test that would have caught it

A test asserting that the provenance template in the drafter is the one the filer reads,
by the same method `test_identity_line.sh` uses on the filer. It fails today because there
is no drafter.

## Non-goals

Validating drafts. `BRIEFS-7` is the only clause that reaches `_drafts/`, and widening the
contract to the shape of a parked idea would make a draft a thing you can get wrong.
