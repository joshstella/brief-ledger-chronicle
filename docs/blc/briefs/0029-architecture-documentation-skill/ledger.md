# Ledger — #0029 The architecture nothing draws

`blc/2 #0029 done a:done(PR#128) b:done(PR#129)`

**Brief:** `docs/blc/briefs/0029-architecture-documentation-skill/brief.md`
**Started:** 2026-10-07
**Closed:** 2026-10-07
**Status:** done

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the citation format and its verifier | done | PR#128 |
| b | the skill that writes the document | done | PR#129 |

**a — the citation format and its verifier.** Define how a claim in the architecture document
names the code that proves it, and write `tools/check-architecture.sh` to check every one. The
verifier reads `docs/architecture/README.md`, finds each citation, and reports any whose file is
gone or whose anchor no longer appears in it. It reports; it does not fail. Tested against
fixture documents: a citation that resolves, one whose file was deleted, one whose anchor was
renamed, and a document with no citations at all.

**b — the skill that writes the document.** `blc-architecture` reads a project's code and writes
`docs/architecture/README.md`: what the system is made of and how the parts connect, every edge
carrying a citation. The skill ships like `blc-export-to-jira` — by glob, with a tracked
`.claude/skills/` symlink. This phase also proves the document is project-owned: a reinstall must
not touch `docs/architecture/`, and a test asserts it.

## Dependency structure

A chain. The verifier defines the citation format, so `a` can be built and tested against fixture
documents with no skill in existence. `b` writes documents in the format `a` already checks.
Reversing them would mean a skill emitting a format nothing agrees with yet.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | A separate skill, or a reworked chronicle → **separate** | a, b |
| 2 | Whose architecture → **any project that installs the toolkit, not the toolkit** | b |
| 3 | Does it explain *why* → **no; the briefs hold that** | b |
| 4 | Committed or generated on request → **committed** | a, b |
| 5 | What an edge cites → **a path plus a literal anchor, not a line number** | a |
| 6 | Where it lives → **`docs/architecture/README.md`, one file, project-owned** | a, b |
| 7 | The skill's name → **`blc-architecture`** | b |
| 8 | A rotted citation → **reported, not failed** | a |

**1 — separate.** `blc-chronicle` carries a non-negotiable rule that a chronicle is the story of
becoming and not a statement of current state. The two artifacts have opposite staleness, opposite
update models and different sources. Behind one command, the chronicle's `closed-through` marker
would assert that the most perishable output is finished.

**2 and 4 — and why they are not the contradiction they look like.** No script can derive
structure from an arbitrary codebase; the edges this repository can derive work only because they
key on its own conventions. Scoping to any project means an agent reads the code and writes the
graph, and committing that is the stale-and-authoritative case the brief's non-goals warn about.

The citation rule is what makes it safe. An edge carrying a path and an anchor is a falsifiable
claim, and `check-architecture.sh` falsifies it. A committed document with a verifier does not go
quietly wrong; it goes noisily wrong. **The verifier is the load-bearing half of this brief, not
the skill.** A skill that draws a diagram is an afternoon. A checker that says the diagram has
rotted is what makes it worth committing.

**5 — an anchor, not a line.** Any edit above a cited line shifts every citation below it, so a
line-based verifier goes red on refactors that changed nothing it cares about. A check that is
noisy on every refactor gets switched off, which is worse than no check.

**6 — `docs/architecture/`, outside `docs/blc/`.** `docs/blc/` is toolkit-owned and replaced on
every install. This document describes the project, so it is project-owned and must survive a
reinstall. One file, following #0006: with several, nothing says which should exist, and nothing
says which is current.

**8 — report, not fail.** "Report, don't gate" is a stated value. A rotted citation means the
document is behind the code, which is a thing to know and not a reason to stop a merge. If it
later proves to be ignored, gating is a one-line change and its own decision.

## Settled while building `a`

**The citation syntax is `<!-- cite: <path> :: <anchor> -->`**, as the assumption below proposed.
The anchor is optional; with none, the citation claims only that the file exists. Two citations
on one line are two findings and both keep that line number.

**`sh`, not `bash`.** The verifier reads a document and greps files, and needs nothing bash
provides. It is the first tool here written for POSIX `sh`, and it is checked under `dash` as
well as `bash`.

**A document with no citations is not a passing document.** It reports "No citations" and says
nothing can be checked. Reporting "all resolve" over zero citations would announce success for
the exact case this tool exists to prevent — a document whose claims nothing supports.

## Found by the review gate, before the merge

The first extractor matched a citation body with `[^>]*`. That cannot cross a `>`, so an anchor
quoting `() => {}` or `if (n > 0)` matched nothing and the citation became invisible. A document
with two such citations and one plain one reported "1 citation(s), all resolve."

This is a worse failure than the one the tool is built to catch. An uncited claim is at least
silent. Here the author did cite, and the report said the evidence holds over two claims the
tool never read. `=>` is common in the code these documents will mostly describe.

The body now matches "anything up to the first `-->`", spelled out because POSIX grep has no
lazy quantifier. A greedy `.*` is wrong the other way: it swallows two citations on one line
into one match. Three mutations hold the shape — `[^>]*`, `.*`, and `[^-]*` each fail a test.

The gate is the reason this was caught. The eleven tests that shipped with the first commit all
passed over it.

## Settled while building `b`

**The diagram carries no citations; the list beneath it does.** A Mermaid fence is parsed, not
rendered as Markdown, so an HTML comment inside one is text the diagram tries to read. Every
edge the diagram draws is restated below it as a line carrying its citation. The diagram is
allowed to be a simplification, because the list is the thing a reader and the verifier both
check.

**The toolkit writes its own architecture document, which decision 2 did not call for.** The
skill still targets any project that installs the toolkit; this repository is simply its first
target. The reason is phase `a`: a format proven only against fixtures written to match it is a
format that agrees with its own defects. `docs/architecture/README.md` now carries 22 citations
into real code, and renaming a cited function makes the verifier name the line.

**This repository gates its own document, where the tool only reports.** Decision 8 is not
reversed — `check-architecture.sh` still exits 0 for every project. A test here asserts that
this repository's document has no rotted citation, because a wrong document about how the
toolkit is built is worse than none, and because every other test in that file runs against a
fixture whose other end is not real code.

## An assumption to challenge on first use

The citation syntax is not settled by anything above, and it is the detail most likely to want
revision. Phase `a` will propose an invisible HTML comment at the end of the line making the
claim — `<!-- cite: <path> :: <anchor> -->` — on the precedent of the chronicle's
`<!-- chronicle:closed-through:DATE -->` marker: invisible in rendered Markdown, trivially
greppable, and already a pattern in this toolkit.

The cost is that a human reading the rendered document cannot see which claims are evidenced. If
that turns out to matter more than clean prose, a visible citation is the alternative, and the
verifier does not care which it reads.

## What this cannot prove

Nothing can assert the diagram is *right*. The verifier proves that every claim still points at
code that exists and still contains what was cited. A document can pass every citation check and
still describe the system badly, and no test here closes that gap.

## What shipped

`tools/check-architecture.sh`, `skills/blc-architecture/`, and `docs/architecture/README.md` —
this repository's own document, 23 citations into real code. The suite grew from 624 to 647.

The brief said the verifier was the load-bearing half and the skill was an afternoon. That held.
The verifier took two commits because the review gate rejected the first one, and the skill took
one.

## What the record shows that the brief did not predict

**A Mermaid fence cannot hold a citation.** A fence is parsed, not rendered as Markdown, so an
HTML comment inside one is text the diagram tries to read. The diagram now carries no citations
and every edge it draws is restated beneath it as a cited line. The diagram may simplify,
because the list may not.

**The toolkit documents itself, which decision 2 excluded.** The skill still targets any project
that installs it; this repository became its first target because a format proven only against
fixtures written to match it agrees with its own defects. The value showed up immediately: hand
checking one claim found it false — `templates/` was described as installer-placed but not
toolkit-owned, and the ownership map says the opposite. Every citation resolved. **A resolving
citation proves the code was read, not that the sentence beside it is true.**

## Open after close

**A citation may name a path outside the repository.** `<!-- cite: /etc/hostname -->` reports a
clean resolve. The skill tells an agent to keep paths inside the work tree and nothing enforces
it. Raised twice by the review gate, deferred twice, and never settled. It is a report-only
check, so the cost is a citation a reader cannot open, not a wrong one.

**"Cite only what you opened" is unenforceable by construction.** It is the rule that matters
most and the one nothing can check. The skill says so at the site.

**22 of 23 claims in this repository's own document were never hand-checked.** One was checked
and was wrong. The rest have the same provenance.

## What the next brief inherited

#0030 corrected `tools/lib/touch-log.sh`, which this document cites. The anchor survived, and
the dogfood gate on `main` confirmed it after both merged. That is the first time the verifier
earned its keep against a change it did not anticipate.
