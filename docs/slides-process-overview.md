# brief-ledger-chronicle — Slide Deck

*Practical overview for new projects and collaborators.*
*16 slides. Suggested layout: dark background, monospace accents, minimal decoration.*

> **A note on the examples.** The deck shows Claude Code throughout — `/create-brief`,
> `.claude/`, `CLAUDE.md`. On Cursor the same six process files install to
> `.cursor/skills/`; the process contract is `.cursor/rules/brief-ledger-chronicle.mdc`
> and `AGENTS.md` is a project-owned architecture stub. Invoke skills by name rather
> than with a leading slash. The workflow, the brief convention, and everything the deck
> actually argues are identical on both. See the README's "What lands where" table.

---

## Slide 1 — Cover

**brief-ledger-chronicle**

A portable workflow that keeps AI-assisted development traceable, reviewable, and narrable.

*Install once. Brief everything. Nothing reaches main unreviewed.*

---

## Slide 2 — The Problem

**Work done with AI disappears.**

- The model writes code. You merge it. Two weeks later: why did this change?
- Git log says *what*. Nothing says *why*.
- No record of what was considered and rejected.
- No way to hand the context to the next session — or the next person.

**AI amplifies velocity. Without process, it also amplifies opacity.**

---

## Slide 3 — What This Is

**A three-layer paper trail designed for solo and small-team AI-assisted development.**

| Layer | What it captures | Where it lives |
|---|---|---|
| **Brief** | The intent — why, what, how | `docs/briefs/NNNN-slug/` |
| **Ledger** | The execution — what actually happened | `docs/briefs/NNNN-slug/ledger.md` |
| **Chronicle** | The narrative — the story of the codebase | `docs/chronicles/` |

Each layer is a plain Markdown file. No app. No database. Just git.

---

## Slide 4 — The Brief

**Before you build, you write a brief.**

A brief is a short spec that answers:
- What problem does this solve?
- What decisions are already made? *(settled)*
- What decisions remain open? *(open)*
- What are the phases, in order?

```
docs/briefs/0017-chart-interaction-overhaul/
  brief.md     ← the spec
  ledger.md    ← added when execution begins
```

The brief earns a **serial** (`#0017`) when filed. That serial travels into every PR title and commit message — making git history traceable back to intent.

---

## Slide 5 — The Identity Line

**Every brief carries one line that makes it machine-readable.**

```
**Serial:** #0017 · **Created:** 2026-06-28T09:12:00Z · **Author:** name@org.tld · **Depends on:** #0016
```

- **Serial** — assigned at filing, never by the author
- **Created** — ISO-8601 UTC; staleness cue
- **Author** — a real email; the identity key the whole stack joins on
- **Depends on** — the only field the author controls

This line is what lets the review gate find the governing intent for any PR.

---

## Slide 6 — The Brief Lifecycle

```
_drafts/idea.md          ← author writes, no number yet
       ↓  /create-brief
0017-slug/brief.md       ← serial assigned, one-way door
       ↓  /start-brief
0017-slug/ledger.md      ← execution begins, phases tracked
       ↓  /next-brief-phase (repeat per phase)
PR title: [#0017] …     ← serial rides into main
```

**Filing is the commitment.** A draft costs nothing and can wait indefinitely. A filed brief is work you've decided to do.

---

## Slide 7 — The Ledger

**The ledger is the honest record of what actually happened.**

It tracks:
- Phase sequence and status (done / in-progress / pending)
- Complications found during execution that the brief didn't anticipate
- **Big decisions** — judgment calls made during review, with reasoning

The Big decisions section is the most valuable part. It's where the human–AI interaction produced information that exists nowhere else: the fork in the road, and which way you went.

*If nothing interesting was decided, the section stays empty. Sparseness is the point.*

---

## Slide 8 — The Review Gate

**Nothing reaches `main` unreviewed.**

```
/commit-push-pr
  → stages files
  → calls /review-pr automatically
  → if: Request changes → STOP. Nothing is committed.
  → if: Approve → commit, push, open PR
```

The review checks:
- Correctness (real bugs)
- Test adequacy (not just presence — does the test cover the changed behavior?)
- Intent (did the diff honor the brief's settled decisions?)
- Cross-project preferences (types, scope, security, comments)

**The gate is not a formality. Request changes halts the chain.**

---

## Slide 9 — The Chronicle

**The chronicle renders the brief/ledger history into a narrative.**

Run `/chronicle` when you want:
- The story of how the codebase got here
- Onboarding context for a new collaborator
- A retrospective
- A record of what you decided, and why, a year later

The codebase speaks in first person. It narrates the eras, the forks, the roads not taken.

*The chronicle is a derived artifact — generated on demand, never committed as source of truth. The briefs and ledgers are the record; the chronicle is a rendering of them.*

---

## Slide 10 — The Daily Workflow

**Four commands cover 90% of the work.**

| Command | When |
|---|---|
| `/create-brief` | Before starting anything non-trivial |
| `/start-brief` | When you're ready to execute |
| `/next-brief-phase` | Moving to the next phase |
| `/commit-push-pr` | Every time work is ready to merge |

Two more for setup and history:

| Command | When |
|---|---|
| `/init-briefs` | Once, when onboarding a new repo |
| `/chronicle` | When you want the narrative |

---

## Slide 11 — What's Installed

**Three skills and six commands land in your project.**

```
.claude/
  skills/
    chronicle/          → /chronicle
    installer-builder/  → package skills for distribution
    to-do/              → /to-do
  commands/
    commit-push-pr.md   → /commit-push-pr
    review-pr.md        → /review-pr
    create-brief.md     → /create-brief
    start-brief.md      → /start-brief
    next-brief-phase.md → /next-brief-phase
    init-briefs.md      → /init-briefs

docs/briefs/
  README.md             ← brief convention reference
  _drafts/              ← unnumbered draft holding area

docs/install-log/
  install-log.md        ← append-only record of every install run
```

---

## Slide 12 — How to Install

**Requirements:** `git`, `gh` (GitHub CLI). Claude Code installs also expect `node`, `npm`,
and the `claude` CLI.

```bash
# 1. Clone the process repo (once per machine)
git clone https://github.com/joshstella/brief-ledger-chronicle.git

# 2. Wire up user-level config (once per machine) — DON'T SKIP
bash /path/to/brief-ledger-chronicle/install.sh --machine

# 3. Run the installer in your project (once per project)
bash /path/to/brief-ledger-chronicle/install.sh --target /path/to/your-project

# On Cursor instead — per project, no machine-level step:
bash /path/to/brief-ledger-chronicle/install.sh --host cursor --target /path/to/your-project

# Add --yes to either to skip the confirmation prompt.

# Machine mode (--machine) symlinks into ~/.claude:
# - CLAUDE.md            → personal working agreement, applies everywhere
# - commands/            → commands available in every repo
# - briefs/README.template.md → the template /init-briefs reads
# Symlinks, so `git pull` updates every machine-level artifact at once.
# Never overwrites a real file — reports a conflict and leaves it alone.

# Project mode (--target) copies into the repo:
# - checks all dependencies and tells you what's missing
# - creates docs/briefs/, docs/contracts/, docs/chronicles/, docs/install-log/, tools/,
#   and the host skill dirs
# - writes a process-rules file the installer owns (.claude/rules or .cursor/rules)
# - writes a CLAUDE.md / AGENTS.md stub only if absent — never overwrites
# - appends an entry to docs/install-log/install-log.md recording what was installed
# - default is idempotent; --force replaces installer-owned copies, not the stub
```

**Why step 2 is called out:** the commands degrade gracefully when their user-level paths
are absent, so skipping it leaves a machine that *looks* configured but can't be
reproduced from clean. This was found by doing a first from-clean install and hitting it.

---

## Slide 13 — Process contract vs project architecture

**The installer owns the process. The project owns architecture.**

Process rules land in `.claude/rules/brief-ledger-chronicle.md` (Claude Code) or
`.cursor/rules/brief-ledger-chronicle.mdc` (Cursor). `--force` replaces that file.

`CLAUDE.md` / `AGENTS.md` are a stub written only if absent: a pointer at the process
file, plus an empty project-specific section. The installer never overwrites them.

Key process rules:
- Use the skills — don't bypass them (`commit-push-pr`, not raw `git push`)
- Tests gate `main` — no silent exemptions
- Brief required for non-trivial work before the first commit
- Default prose is STE-flavored via `ste-writing`

Working style and code style live in `personal/CLAUDE.md` (Claude Code machine-level)
and in user-level Cursor rules, not in the project stub.

---

## Slide 14 — What You Get

**Traceability.** Every commit on `main` carries a serial that links to a brief, a ledger, and a review record.

**Honesty.** The ledger records complications and decisions, not just successes. The chronicle inherits that honesty.

**Portability.** Skills and commands travel with the repo. A new collaborator clones and runs `install.sh`. The process is already there.

**Narrative.** The chronicle turns months of briefs into a story. You can answer "how did we get here?" without reading git blame.

**A floor, not a ceiling.** The process enforces a mechanical minimum. It doesn't replace judgment — it creates the record that makes judgment reviewable.

---

## Slide 15 — What It's Not

- Not a project management tool. No tickets, no sprints, no burndown charts.
- Not a documentation system. The briefs are *specs*, not docs. Architecture lives in `AGENTS.md` / `CLAUDE.md` and design docs.
- Not AI-specific. The skills happen to run in Claude Code, but the brief/ledger convention is plain Markdown and works without AI tooling.
- Not heavyweight. A brief is a short Markdown file. A ledger is another one. The overhead is proportional to the work.

*A brief for a one-line fix is overkill. A brief for a five-phase refactor is essential.*

---

## Slide 16 — Getting Started

**For a new project:**

```bash
bash install.sh --target /path/to/your-project
# → edit CLAUDE.md / AGENTS.md (fill in the project-specific section)
# → git add -A && git commit -m "Bootstrap: brief-ledger-chronicle install"
# → write your first draft in docs/briefs/_drafts/
# → run /create-brief to file it
# → run /start-brief to begin
```

**Source:**
`github.com/joshstella/brief-ledger-chronicle`

**The install log in every project** (`docs/install-log/install-log.md`) records exactly what was installed, when, and on which machine — appending a new entry each time you re-run the installer to pick up upstream changes. The process documents itself from the first run.

---

*End of deck.*
