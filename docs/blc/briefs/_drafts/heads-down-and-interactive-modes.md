# Heads-down and interactive modes

**Created:** 2026-10-13T14:07:47Z · **Author:** josh.stella@gmail.com
**Depends on:** —

## The gap

Every phase runs the same way. The agent works until the phase is done, then
`blc-commit-push-pr` stages the diff, runs the review gate and opens the pull request.

An agent stopping to ask a question is not the gap. That already happens, and nothing
prevents it. The gap is that **the pause leaves nothing behind.** A person opens a page,
clicks through it, and says the spacing is wrong. The observation reaches the code and never
reaches the record. Afterwards a reader cannot tell a phase whose interface a person used
from a phase whose interface nobody ever rendered.

The review gate cannot tell either. `blc-review-pr` reads a diff, and a diff of an interface
is markup and styles. The gate can check that tests exist and that they ran. It cannot check
that a person looked at the result. A missing test blocks unless the test plan says
`test-exempt because…`. **There is no equivalent sentence for an interface nobody saw.**

## Claim

Name the two modes. Declare the mode per phase. Make an interactive phase owe the record a
note, and let the commit gate refuse when that note is absent.

- **Heads-down** is today's behaviour, named. Naming is most of its value: a phase that says
  it is heads-down tells a reader the absence of a human check is a decision, not an omission.
- **Interactive** means the phase has one or more checkpoints where a person does something
  the agent cannot — uses a GUI, judges a layout, tries a flow — and reports what they found.

Settled while scoping, 2026-10-13:

- **The mode is per phase, declared in the ledger.** A brief with an interface phase and a
  backend phase wants both, and `blc-start-brief` already plans phases and writes them there.
- **A checkpoint owes a ledger note: what was checked, and what was observed.** A pause that
  writes nothing is invisible the moment it ends, and the record is the work.
- **An unmet checkpoint blocks the pull request, with an escape.** `blc-commit-push-pr`
  refuses an interactive phase whose checkpoint is unrecorded, unless the test plan carries an
  explicit `checkpoint-skipped because…`. Same shape as `test-exempt because…`: a sentence
  somebody can disagree with, rather than a silent gap.

## Why this is not just a skill instruction

The blocking half cannot be a skill instruction alone. A skill guard is not a check, and an
agent that was told to pause and did not looks identical afterwards to one that paused. If
the claim is that nobody ships an interface nobody saw, something has to read the ledger and
exit non-zero.

Whether that is `tools/validate-briefs.sh`, a `brief-checks/` script, or a step inside
`blc-commit-push-pr` is open.

## Open

- **Does a human check count as test evidence?** A usability pass on a GUI may be the only
  test that phase can have. If it satisfies `## Test plan`, the two mechanisms merge. If it
  does not, a phase can owe both a checkpoint note and a test exemption for the same work.
- **A phase that pauses and is never resumed.** The branch sits `in-progress` and nothing
  distinguishes waiting-on-a-person from abandoned. `deferred` may already cover it, or the
  waiting state may need to be visible to `open-briefs.sh`.
- **Does the mode belong in the `blc/2` status line?** That line is what a cheap reader
  trusts. A mode in the phase table only is invisible to anything that reads one line.
- **Does `blc-next-brief-phase` carry the mode forward?** It re-plans what remains after every
  phase, so a mode set at planning time may not survive a re-plan.
- **Contract or convention?** Declaring a mode per phase changes ledger shape. One owner per
  serial is a convention that nothing checks; a blocking checkpoint cannot be.

## Related

`_drafts/the-handoff-nothing-measures.md` is adjacent and separate. It also concerns a person
doing something during execution that the record never captures, but its subject is what a
handover between two people costs. Cite it; do not merge with it.
