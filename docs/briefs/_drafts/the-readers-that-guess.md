# The readers that guess

**Created:** 2026-09-30T20:15:00Z · **Author:** josh.stella@gmail.com
**Depends on:** —

## The finding

This toolkit writes a record in Markdown and then reads it back with small ad-hoc parsers.
Three times now, two of those parsers have been found reading the same thing and disagreeing.
Each time the disagreement was invisible until someone wrote a test that made the two answer
the same question side by side.

The repair each time was the same: put one reader in `tools/lib/` and make everyone use it.
`blc_status_line` and `blc_phase_row_*` exist because of that repair. The work was never
finished — it stopped at whichever reader had just caused a defect.

**The identity line still has no shared reader**, and its two readers disagree today:

- `tools/validate-briefs.sh:176` takes everything after `**Depends on:**` to the end of line.
- `tools/list-briefs.sh:100` takes the same text and stops at the next `·`.

#0007 phase `a` proved the consequence while testing something else. A `#NNNN` written in any
field after `Depends on` becomes a dependency. If that serial does not exist, `BRIEFS-6` blocks
with a defect. **If it does exist, nothing is reported at all**: the record holds an edge nobody
declared, the validator counts it, and `list-briefs.sh` shows no dependency. A reader asking
"what does this brief depend on" gets two different true-looking answers depending on which
tool they ask.

That phase closed the hole with a convention — `Depends on` goes last — and a test. The
convention is not checked, and the disagreement it routes around is still there.

## The same defect wearing a forge costume

The status line's phase pointer holds a branch, a PR, a commit, or a comma-separated pair.
`pointer_branch` in `tools/open-briefs.sh` walks the fields and returns the first one that is
not a PR and not a commit. Its rule, in its own comment: **anything that is not a PR or a bare
commit is a branch.**

That is a closed parser over an open vocabulary, and it does not report what it does not
understand — it guesses. #0007 phase `a` measured this for a tracker key and found three
outcomes decided by position: dropped in silence after the branch, reported as a branch that
does not exist when written before it, and never parsed at all on a closed phase. The
middle case also costs that phase its branch-distance measurement, because the tool stops.

**A GitLab merge request has no spelling in that vocabulary.** `PR#14` is the only PR token
the parser knows. Whatever a GitLab project writes instead — `MR!123`, `!123`, a URL — is not
a PR, so it is a branch, so `open-briefs.sh` reports a branch that does not exist and measures
nothing. The tool does not decline to answer. It answers wrongly, in the report whose entire
value is that its findings are believed.

This is why the two halves are one brief. The reader problem and the forge problem are the same
problem at the pointer: a slot whose contents are open-ended, read by a parser that assumes it
has seen everything.

## What else assumes GitHub

The pointer is the only place the forge reaches the *record*. Everywhere else it reaches the
*tools and the prose*, which is a different kind of work:

- **One tool call.** `open-briefs.sh:285` runs `gh pr view` for PR state. It is already
  guarded: `HAVE_GH` is probed at line 105 and the tool degrades to "state not checked: no gh".
  So the tool half is nearly done, by accident rather than by design.
- **Three skills.** `blc-commit-push-pr` (create, check, merge), `blc-review-pr` (fetch a
  diff), `blc-next-brief-phase` (confirm the previous phase merged). These are instructions to
  an agent, and they name `gh` with no alternative.
- **Two documents.** `README.md` and `docs/slides-process-overview.md` list `gh` as a
  requirement. `install.sh:268` prints an install hint for it.

A GitLab user has no path today. Nothing is broken for them — it is simply absent, except at
the pointer, where it is worse than absent.

## Tension

**The two halves are not the same kind of work, and the brief should not pretend they are.**
Unifying readers is parsing: extract, share, prove the old readers cannot come back. Adding
GitLab is invocation and prose: `glab` beside `gh`, detection, and three skills rewritten to
stop naming one forge. They meet at the pointer vocabulary and nowhere else. Any plan will
probably split along that seam, which is what phases are for — but whoever plans it should know
the seam is there before they start.

**Changing the pointer vocabulary is expensive.** `PR#` appears in the published record format
in `docs/briefs/README.md`, in thirteen of the fifteen ledgers here, and across `tests/`. The
status line is read by `BRIEFS-9`, a published Contract clause, and two briefs were spent
making it machine-readable.
Adding a token shape is a change to a tested, published artifact, not a parser tweak.

**A shared reader is not automatically the right answer.** `phase-row.sh` says in its own
comment that it deliberately does not parse columns, because three table schemas are in use and
a token scan survives all three where a column index does not. The identity line may deserve
the same latitude. "One reader" is the goal; "one strict reader" may not be.

**The guesser might be the feature.** `pointer_branch` treats unknown text as a branch because
branches have no fixed shape. A parser that refused unknown tokens would reject legitimate
branch names. The fix is probably not "know every token" but "say when you are guessing" — and
that changes what `open-briefs.sh` prints, which people read.

## Non-goals

- **Not a Markdown parser.** The record stays greppable by hand.
- **Not forge abstraction beyond GitHub and GitLab.** No plugin layer for a third.
- **Not shipping CI configuration.** `install.sh` ships `docs/`, `tools/` and `templates/`,
  and no workflow file. An adopter's CI is theirs.
- **Not requiring a forge.** `open-briefs.sh` already works with neither CLI present, and that
  must stay true.
- **Not changing what a brief or ledger looks like to a human**, beyond whatever a second PR
  token costs.

## Open decisions

1. **One brief or two?** The seam above is real. Splitting gives two smaller briefs with a
   dependency; keeping them together keeps the pointer argument in one place.
2. **Does the identity line get a strict shared reader, or a tolerant one?** See the
   `phase-row.sh` precedent.
3. **What does GitLab write in the pointer?** `MR!123` mirrors GitLab's own `!` convention and
   is unambiguous against `PR#`. `!123` is shorter and collides with nothing today. This is a
   record-format decision, so it is the one that touches the Contract.
4. **Does the parser learn to say "I do not recognise this"?** That is a new finding class in
   `open-briefs.sh` and changes its output for everyone, not only GitLab users.
5. **Is the `Depends on` convention retired once the readers agree?** The "goes last" rule
   exists to route around the disagreement. If the disagreement goes, the rule may be
   redundant — or it may be worth keeping for the phantom-dependency case, which is about the
   greedy read and not about the two readers.
6. **Detection or configuration for the forge?** Probe for `glab` and `gh` and pick, read the
   remote URL, or make it explicit. Probing is invisible until it picks wrong.
