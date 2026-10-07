# The architecture nothing draws

**Serial:** #0029 · **Created:** 2026-10-07T14:02:10Z · **Author:** josh.stella@gmail.com · **Depends on:** #0006

## The request

Rework `blc-chronicle` so it also produces architecture diagrams and documentation: what the
system is made of and how the parts connect, not only how it came to be.

## The rule this collides with

`skills/blc-chronicle/SKILL.md` carries it under "Grounding rules (non-negotiable)":

> **A chronicle is the story of becoming — changes and their reasoning — not current state.** The
> two are complementary layers; don't present the chronicle as system documentation.

So the request is not an addition to the chronicle. It is a reversal of a rule the chronicle was
built around, and #0006 ("one chronicle") settled the one-file shape that rule produced. Either
the rule goes, or the architecture output is a different artifact. This draft argues it is a
different artifact, and the reason is not taste.

## The two have opposite staleness

| | chronicle | architecture |
|---|---|---|
| describes | the past | the present |
| goes stale | never — history does not change | on the next merge |
| update model | append; a `closed-through` marker bounds what is new | regenerate whole; nothing is appendable |
| source | briefs, ledgers, git | the code |
| a wrong one | misremembers | misleads |

The marker is the clearest sign they do not belong together. `<!-- chronicle:closed-through:DATE -->`
exists because narrated history is finished and need not be revisited. An architecture document
has no such boundary: every line of it is provisional until the next commit. Putting both in one
file means either re-deriving settled history on every run, or carrying a diagram the marker
asserts is closed when it is the part most likely to be wrong.

**A stale diagram is worse than no diagram.** Prose that is out of date reads as dated. A box and
an arrow read as current, because a diagram carries no voice to hedge with.

## Some of it is derivable, and that is the part worth building

The repository's structure is not a matter of opinion. These edges came out of one-line greps on
2026-10-07:

**Tools to libraries** — from the `for BLC_LIB in …` line each tool sources:

```
jira-csv.sh       -> status-line, identity-line, phase-row
list-briefs.sh    -> status-line, identity-line, touch-log
open-briefs.sh    -> phase-row, status-line
validate-briefs.sh-> phase-row, status-line, identity-line
```

**Skills to tools** — from the `tools/*.sh` commands the skills tell an agent to run:
`orient.sh` is named by 6, `list-briefs.sh` by 4, `detect-forge.sh` by 4, `stale-branches.sh` by
3, `jira-csv.sh` by 2.

**Everything to its install destination** — `install.sh --print-ownership` already emits the
whole map as tab-separated rows, for either host.

None of that is a judgment call. A script can emit it, and — this is the point — **a test can
assert the emitted graph matches the tree**, exactly as `test_ownership_every_tool_in_the_source_is_declared`
asserts the ownership map does. A generated diagram that the suite checks cannot go stale without
going red.

That is the repository's own rule applied to diagrams: a script can be asserted by the test suite
and an instruction to an agent cannot.

## What is not derivable

Why `tools/lib/` exists. Why the forge is detected rather than configured. Why the ledger has one
writer. Those are the valuable half of architecture documentation and no script will produce
them. They are also, largely, already written — in the briefs and ledgers that the chronicle
reads.

Which raises the question this draft cannot settle: whether an interpretive architecture document
is a third artifact, or whether it is what the chronicle's present-tense paragraph already points
at, or whether the briefs are the documentation and anything restating them is the stale second
copy this process exists to avoid.

## What is settled

1. **A separate skill, not a reworked chronicle.** `blc-chronicle` keeps its grounding rule and
   its one file. The two artifacts have opposite staleness, opposite update models, and different
   sources, and putting them behind one command would make the `closed-through` marker assert
   that the most perishable output is finished. Decided 2026-10-07.
2. **It describes any project that installs the toolkit, not this toolkit.** A graph of `tools/`
   and `skills/` is a graph of the plumbing, which is not what a project wants a picture of.
   Decided 2026-10-07.
3. **It emits structure, not reasons.** The *why* is in the briefs and the ledgers. A document
   restating them is the stale second copy this process exists to avoid. Decided 2026-10-07.
4. **The document is committed, and every edge cites the `file:line` that proves it.**
   Decided 2026-10-07.

## The citations are what make a committed document safe

Decisions 2 and 4 look like they contradict this draft's own non-goal — "do not write a diagram
an agent composed by reading code" — and they would, without the citation rule.

No script can derive structure from an arbitrary codebase. The edges demonstrated above work only
because they key on this repository's own conventions. Scoping to any project therefore means an
agent reads the code and writes the graph. That is the stale-and-authoritative case the non-goal
was written against.

Citations change what the document is. An edge that carries `src/foo.ts:42` is a falsifiable
claim, and a script can check every one of them: the file exists, the line is still there, and it
still contains what was cited. A committed architecture document with a verifier does not go
quietly wrong — it goes red.

That is the ownership-map pattern applied to prose. The guard is not "trust the agent". The guard
is that the agent's claims are checkable, and that something checks them.

**This makes the verifier the load-bearing half of the work, not the skill.** A skill that draws
a diagram is an afternoon. A checker that tells you the diagram has rotted is the part that makes
it worth committing.

## What is undecided

1. **What the skill is called**, and what the document is called and where it sits. Both are
   expensive to change once installed — #0010 was an entire brief about renaming nine skills.
2. **How strict the citation check is.** That the file exists is cheap. That the line number is
   still the right line is not: any edit above it shifts every citation below. A check on the
   *content* at that line, or on a searchable anchor rather than a number, survives editing. A
   check that is noisy on every refactor will be switched off.
3. **Mermaid or an image.** Mermaid is text: it diffs, it reviews, it renders on both forges, and
   a test can read it. An image is none of those. Against Mermaid: a large graph renders badly
   and nothing here controls layout.
4. **Whether the test asserts the graph or only its shape.** Asserting every edge makes the test
   a second copy of the graph that must be updated with it. Asserting the generator against the
   tree — every tool in `tools/` appears, every `BLC_LIB` edge is present — tests the derivation
   instead, and is the form the ownership guard already takes.
5. **What the verifier does when a citation has rotted** — report, or fail a gate. "Report,
   don't gate" is a stated value, and this repository's own tests gate `main`. Which this is
   depends on whether the document is a promise or a convenience.
6. **Whether the skill refreshes a stale document or only reports it.** Regenerating on every
   drift makes the document a build artifact in a tracked file, which is the shape #0006
   deliberately rejected for the chronicle.

## The test

For the derived half, the test is the one the repository already knows how to write: run the
generator over the real tree, and assert that every tool, library, and skill present is in the
output, and that nothing in the output is absent from the tree. A tool added without an edge
fails, which is the failure mode that matters — the graph silently missing a part.

For the interpretive half there is no test, and the draft should say so rather than imply one.

## Non-goals

- Do not delete the chronicle's grounding rule as a side effect. If it goes, it goes deliberately
  and with its own decision recorded.
- Do not write an edge without a citation. An uncited edge is the stale-and-authoritative case,
  and it is invisible to the verifier.
- Do not restate in a new document what a brief already says. The record is the work.
