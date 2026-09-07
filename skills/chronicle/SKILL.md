---
name: chronicle
description: Generate a narrative history — a "chronicle" — of a codebase by interrogating its brief registry (docs/briefs/), execution ledgers, and git history, telling the story of how the system came to be. Use whenever the user wants a project origin story, a "how did we get here" narrative, onboarding context for a new hire, a retrospective or postmortem-of-progress, an engagement summary for a client, or wants to synthesize the docs/briefs record and git timeline into prose. Trigger even on casual phrasings like "tell the story of this repo", "what's the journey of this project", "our story", or "write up how this came together" — and even if the user doesn't say the word "chronicle".
---

# Chronicle

Turn a project's structured record — its briefs, ledgers, and git history — into a
clear narrative of how the system came to be. The brief registry holds the *why* of every
change and its provenance; git holds the *when* and the *scale*; the ledgers hold *what
actually happened*. This skill weaves them into a readable, professional history rather
than a list.

**A chronicle is a derived rendering, not the record.** Briefs, ledgers, and git are the
record. The file in the tree is a report run off that record. The next run may refresh
the table, the present-tense paragraph, and the closed-through marker. It may prepend
new era prose. It does not become a source of truth by sitting in git.

**One file, one path:** `docs/chronicles/chronicle.md`. Edit that file in place. Do not
write a sibling. Do not write to a notes vault or a user-named path. The folder stays
for a later archive feature. This skill does not add one.

This file is an instruction to the agent. Nothing in the test suite exercises what it
tells you to write.

## What it reads

- `docs/briefs/NNNN-slug/brief.md` — each brief's purpose, design rationale, the work, and
  open decisions. The *why*.
- `docs/briefs/NNNN-slug/ledger.md` — the execution record (phases, outcomes). The *what
  happened*. A brief with no ledger was planned but not (yet) executed — itself part of
  the story. Its **Big decisions** section is prime narrative material: judgment calls
  resolved during review, where the human–agent interaction carried information that
  exists nowhere else. These are the *forks the codebase navigated* — weight them heavily.
- `docs/briefs/_drafts/*.md` — parked/deferred drafts: the roads considered and not taken.
- **git history** — last-touch date per brief (row and era order), first-commit date
  (a table column), and squash subjects carrying `[#NNNN]` (which changes belong to which
  brief). The *when*.
- Optionally `docs/design/` for context on what a change produced — but see the grounding
  rule: a chronicle is the story of *becoming*, not a statement of current state.

## Closed-date markers

The one file carries a hidden marker on its last line:

```
<!-- chronicle:closed-through:YYYY-MM-DD -->
```

`YYYY-MM-DD` is the date of the repo's HEAD commit at time of writing. This marks that
everything merged on or before that date is already fully narrated. On the next run, the
skill reads this marker and passes the date to `gather.sh`. The table stays complete.
The cutoff filters what is new to narrate.

The marker is invisible in rendered Markdown. If the file is read by a human, they see
prose; if it is scanned by the next run, the marker is the only machine-readable state.

## Method

1. **Read the one file, if it exists.**
   - Path is `docs/chronicles/chronicle.md`. No other path. Do not scan siblings.
   - If the file exists, grep its last 5 lines for
     `<!-- chronicle:closed-through:(\d{4}-\d{2}-\d{2}) -->`.
   - If a date is found, record it as `PRIOR_DATE`. This run is **incremental**.
   - If the file is missing or has no marker, this is a **full run**.

2. **Gather the timeline.** From the repo root, run `scripts/gather.sh [PRIOR_DATE]`. It
   emits a structured digest: repo origin and head; a brief table of every brief, newest
   last-touch first, with serial, title, status, first, last, and depends-on (the table
   is never filtered); a **To narrate** list (filtered when a cutoff is set); the parked
   drafts; and the commits that reference a brief serial. Status is the `blc/1` overall
   token, `planned` if there is no ledger, or `no-line` if the ledger has no status line.
   If `gather.sh` does not exist, gather manually using the same filtering logic: the
   table still lists every brief; only narration and commits take the cutoff.

3. **Read the prose.** Walk the briefs in **To narrate** (incremental) or every brief
   (full run), newest last-touch first. Read each `brief.md` and its `ledger.md` if
   present.

4. **Read the roads not taken.** Skim `_drafts/` for what was considered and parked; on
   an incremental run, only surface drafts added or materially changed since `PRIOR_DATE`.

5. **Assemble the spine.** Last-touch order from git; causal links from the depends-on
   edges ("X laid the foundation Y built on"); the *why* from briefs; the *what happened*
   from ledgers; the **forks** from each ledger's Big decisions; the *considered-but-deferred*
   from drafts. The forks and the roads-not-taken are the dramatic beats — clean phases are
   connective tissue.

6. **Write `docs/chronicles/chronicle.md`.** Create `docs/chronicles/` if it is missing.
   The file always has this shape, top to bottom:

   1. A title.
   2. The brief table, pasted from the digest. Refresh it on every run. Do not rebuild
      the columns by hand.
   3. A present-tense paragraph: where the work is now. Refresh it on every run.
   4. Era sections, newest first.
   5. Origin last. The first commit and the starting shape of the system live here.
   6. The closed-through marker as the last line.

   On an **incremental** run: refresh the table and the present-tense paragraph. Prepend
   new era prose under the paragraph. Do not rewrite prior era prose. Do not retell
   origin. Update the marker. Do not add a sibling. Do not open with a "this continues
   from `<prior-filename>`" preamble.

   On a **full** run: write the whole file in that order.

7. **Stamp the marker** as the very last line:
   ```
   <!-- chronicle:closed-through:YYYY-MM-DD -->
   ```
   `YYYY-MM-DD` is today's date (from the system prompt) — or the date of HEAD if
   the session date is unavailable.

## Voice & structure

- **Point of view: third person, professional.** Write about the system and the team
  objectively — "The system began as a single service that did one thing…" / "The team
  chose to…" Tone is clear and direct: the register of a well-written engineering
  retrospective or client engagement summary, not a personal essay.
- **Newest work first.** Table rows and era sections follow last-touch, not serial and
  not first-commit. First-commit stays a table column. A brief that started early and
  moved yesterday sits at the top.
- **Group into eras** where the history has natural seams. Each era: the briefs that
  constituted it, why they happened, what changed, what they enabled.
- **Dependency edges become causal narrative**, not footnotes.
- **The Big decisions are the forks** — give them weight. Each is a moment where the work
  hit genuine ambiguity and a choice was made with reasoning; that's where a history stops
  being a list and becomes a story. Render the tension and the resolution, grounded in what
  the ledger records.
- **Include the roads not taken.** A draft parked, a brief decomposed rather than built —
  an honest account includes what was weighed and set aside.
- **Present tense lives in one paragraph after the table.** That paragraph is current
  position. Era prose is past tense. Origin is past tense and last.

## Grounding rules (non-negotiable)

- **Narrate only what the record supports.** Do not invent motivations, dates, or outcomes
  that aren't in the briefs, ledgers, or git. The third-person frame is not licence to
  fabricate — stay grounded in what the record shows.
- **Distinguish recorded fact from inference.** Where the record is silent, stay quiet or
  say so plainly rather than filling the gap with a plausible story.
- **Row and era order from last-touch**, never from serial numbering.
- **A chronicle is the story of becoming — changes and their reasoning — not current
  state.** The two are complementary layers; don't present the chronicle as system
  documentation. The present-tense paragraph is a pointer, not a spec.
- **Completeness is bounded by what flowed through the registrar.** Work that skipped a
  brief leaves a hole the chronicle inherits. If the history looks suspiciously gapless or
  gappy, say the record is what it is rather than smoothing it over.

## Output options

- **The one file** — default. Always `docs/chronicles/chronicle.md`.
- **Inline** — also render to the conversation if the user asks for it in addition to
  the file, or instead of writing the file.

Do not write several `.md` files. Do not write to a user-named path.

## Portability

Works on any repo with the brief convention plus git — your own company or a client
engagement. The methodology travels; the story it tells belongs to whatever repo it runs
in. (For a client, a generated "here's everything we did and why" is close to a
deliverable in itself.)

## Renaming

To call this `our-story` instead of `chronicle`: rename the folder and the `name:` field
in this frontmatter. The output path stays `docs/chronicles/chronicle.md` unless a later
brief changes it. Nothing else depends on the skill name.
