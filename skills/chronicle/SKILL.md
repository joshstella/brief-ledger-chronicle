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

**A chronicle is a derived artifact, not part of the record.** The briefs, ledgers, and
git history are the system of record; a chronicle is a *rendering* of them — like a report
run off a database, not a row added to it. So it is generated on demand and read by a
human; it does **not** get written back into the repo. (It's the first of a possible family
of derived views — timeline decks, engagement summaries — all rendered from the same
`gather.sh` digest. Keeping the mechanical-digest → human-rendering split clean is what
makes the next rendering cheap.)

## What it reads

- `docs/briefs/NNNN-slug/brief.md` — each brief's purpose, design rationale, the work, and
  open decisions. The *why*.
- `docs/briefs/NNNN-slug/ledger.md` — the execution record (phases, outcomes). The *what
  happened*. A brief with no ledger was planned but not (yet) executed — itself part of
  the story. Its **Big decisions** section is prime narrative material: judgment calls
  resolved during review, where the human–agent interaction carried information that
  exists nowhere else. These are the *forks the codebase navigated* — weight them heavily.
- `docs/briefs/_drafts/*.md` — parked/deferred drafts: the roads considered and not taken.
- **git history** — first-commit date per brief (the authoritative chronology), commit
  counts (scale), and squash subjects carrying `[#NNNN]` (which changes belong to which
  brief). The *when*.
- Optionally `docs/design/` for context on what a change produced — but see the grounding
  rule: a chronicle is the story of *becoming*, not a statement of current state.

## Closed-date markers

Every written chronicle carries a hidden marker on its last line:

```
<!-- chronicle:closed-through:YYYY-MM-DD -->
```

`YYYY-MM-DD` is the date of the repo's HEAD commit at time of writing. This marks that
everything merged on or before that date is already fully narrated. On the next run, the
skill reads this marker, passes the date to `gather.sh` as a `--since` cutoff, and frames
the output as an addendum rather than a full retelling.

The marker is invisible in rendered Markdown. If the file is read by a human, they see
prose; if it is scanned by the next run, the marker is the only machine-readable state.

## Method

1. **Check for a prior closed-date marker.**
   - Locate the output directory (the notes vault or whatever path the user names).
   - List `*chronicle*.md` files there; take the most recently modified.
   - If one exists, grep its last 5 lines for `<!-- chronicle:closed-through:(\d{4}-\d{2}-\d{2}) -->`.
   - If a date is found, record it as `PRIOR_DATE`. This run is **incremental**; note the
     prior filename so the narrative can reference it.
   - If none is found, this is a **full run**; proceed without a cutoff.

2. **Gather the timeline.** From the repo root, run `scripts/gather.sh [PRIOR_DATE]`. It
   emits a structured digest: repo origin and head, every brief ordered by **git
   first-commit date**, each with its last-touch date, commit count, executed-or-not flag,
   and depends-on edge; the parked drafts; and the commits that reference a brief serial.
   When `PRIOR_DATE` is supplied, `gather.sh` limits its output to briefs that have at
   least one commit after `PRIOR_DATE` and commits in that same window — everything before
   the cutoff is already narrated. If `gather.sh` does not exist, gather manually using
   the same filtering logic: read only briefs whose `git log -1 --format='%aI'` is after
   `PRIOR_DATE`, and limit the commits scan to `git log --since=PRIOR_DATE`.

3. **Read the prose.** Walking the (filtered) briefs in chronological order, read each
   `brief.md` (purpose, rationale, open decisions) and its `ledger.md` if present.

4. **Read the roads not taken.** Skim `_drafts/` for what was considered and parked; on
   an incremental run, only surface drafts added or materially changed since `PRIOR_DATE`.

5. **Assemble the spine.** Chronology from git; causal links from the depends-on edges
   ("X laid the foundation Y built on"); the *why* from briefs; the *what happened* from
   ledgers; the **forks** from each ledger's Big decisions; the *considered-but-deferred*
   from drafts. The forks and the roads-not-taken are the dramatic beats — clean phases are
   connective tissue.

6. **Write the narrative** (see Voice & structure). On an incremental run, open with a
   single-paragraph preamble: *"This continues from `<prior-filename>`, which covers
   everything through `PRIOR_DATE`. The eras below describe work merged after that date."*
   Do not retell prior eras — reference the prior file. Close with the updated "Where I am
   now" coda (it supersedes the prior one).

7. **Write to `.md` file(s)** — the chronicle is a Markdown deliverable. Write to a path
   the user names, kept **outside the tracked repo tree** (a notes vault, a decks folder, a
   gitignored output dir) so it never drifts against the record it describes. Multi-part
   cuts (eras, per-workspace) become several `.md` files. Never commit it into the repo;
   render inline to the conversation only if the user asks instead of a file.

8. **Append the closed-date marker** as the very last line of every written `.md` file:
   ```
   <!-- chronicle:closed-through:YYYY-MM-DD -->
   ```
   `YYYY-MM-DD` is today's date (from the system prompt) — or the date of HEAD if
   the session date is unavailable. This is what the next run will read.

## Voice & structure

- **Point of view: third person, professional.** Write about the system and the team
  objectively — "The system began as a single service that did one thing…" / "The team
  chose to…" Tone is clear and direct: the register of a well-written engineering
  retrospective or client engagement summary, not a personal essay.
- **Chronological spine from git first-commit dates**, not serial order. Serials are
  *filing* order and can differ from when work actually began; git is the truth.
- **Group into eras** where the history has natural seams (e.g. the foundation era → the
  refactor into modules → the feature build-out → the workflow tooling). Each era: the
  briefs that constituted it, why they happened, what changed, what they enabled.
- **Dependency edges become causal narrative**, not footnotes.
- **The Big decisions are the forks** — give them weight. Each is a moment where the work
  hit genuine ambiguity and a choice was made with reasoning; that's where a history stops
  being a list and becomes a story. Render the tension and the resolution, grounded in what
  the ledger records.
- **Include the roads not taken.** A draft parked, a brief decomposed rather than built —
  an honest account includes what was weighed and set aside.
- **Close with a brief "current state" coda**, explicitly noting that present *state*
  lives in the design docs and READMEs — the chronicle is how the system got here, not a
  statement of what's here now.

## Grounding rules (non-negotiable)

- **Narrate only what the record supports.** Do not invent motivations, dates, or outcomes
  that aren't in the briefs, ledgers, or git. The third-person frame is not licence to
  fabricate — stay grounded in what the record shows.
- **Distinguish recorded fact from inference.** Where the record is silent, stay quiet or
  say so plainly rather than filling the gap with a plausible story.
- **Chronology from git**, never from serial numbering.
- **A chronicle is the story of becoming — changes and their reasoning — not current
  state.** The two are complementary layers; don't present the chronicle as system
  documentation.
- **Completeness is bounded by what flowed through the registrar.** Work that skipped a
  brief leaves a hole the chronicle inherits. If the history looks suspiciously gapless or
  gappy, say the record is what it is rather than smoothing it over.

## Output options

- **One `.md` file** (default) — the full chronicle, written to a user-named path outside
  the tracked tree.
- **Several `.md` files** — for era / date-range / per-workspace cuts, one file per part.
  In a monorepo, chronicle one workspace (`apps/syzygy`) by filtering briefs and git paths
  to it.
- **Onboarding cut** — a shorter "how did we get here, for someone joining" `.md`.
- **Inline** — render to the conversation only if the user asks for it instead of a file.

## Portability

Works on any repo with the brief convention plus git — your own company or a client
engagement. The methodology travels; the story it tells belongs to whatever repo it runs
in. (For a client, a generated "here's everything we did and why" is close to a
deliverable in itself.)

## Renaming

To call this `our-story` instead of `chronicle`: rename the folder and the `name:` field
in this frontmatter. Nothing else depends on the name.
