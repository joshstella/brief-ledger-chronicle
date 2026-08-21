# CLAUDE.md

Project instructions for Claude Code. Adapt the project-specific sections below to this
repo; the process rules in the first section apply unchanged.

## Process — use the skills, don't go around them

This repo uses the brief-ledger-chronicle workflow. The installed skills are the gates;
bypassing them is the defect.

- **`/commit-push-pr`** — the only path to `main`. It runs the review gate before
  committing. Never use raw `git commit && git push` for work headed to `main`.
- **`/review-pr`** — called automatically by `/commit-push-pr`. Can also be run manually
  on a PR number or the staged diff.
- **`/create-brief`** — file a draft into `docs/briefs/`. A brief is the hypothesis you
  start with, not a spec you have agreed to deliver against: file it before non-trivial
  work begins, expect the ledger to correct it, and never retrofit one after the work
  shipped.
- **`/start-brief` / `/next-brief-phase`** — initiate and continue phased work.
- **`/chronicle`** — generate a narrative history from briefs, ledgers, and git. Run when
  you want the story of how the codebase got here.
- **`/init-briefs`** — one-time setup. Already run if `docs/briefs/` exists.

## Working style

- **Direct challenge over affirmation.** Say when something is wrong and why. Skip
  flattery and padding.
- **Surface friction, don't smooth it.** If two goals conflict or a requirement is
  incoherent, name the tension — that's the useful signal.
- **One change at a time.** Single fix, shown, waited on. If a task implies many edits,
  propose the sequence first.
- **Ask rather than guess** on judgment calls that turn on intent or domain knowledge.
  Mark every assumption inline so it can be corrected.

## Writing

Default prose for this process uses the `ste-writing` skill in STE-flavored mode.
Apply it to briefs, ledgers, chronicles, commit messages, PR bodies, reviews, comments,
and docs. Do not apply it to code, identifiers, or command syntax. Do not rewrite the
user's own words (to-do entries stay verbatim). The skill owns the rules. Do not copy
them here.

## Tests

Tests gate `main`. Code merges to `main` only with tests covering it — unit for logic,
integration across boundaries — run and passing. Write them as you go. A genuinely
untestable merge (pure config, generated boilerplate) gets an explicit "test-exempt
because…" in the PR, not a silent gap.

## Code style

- Strongly typed at every boundary. No `any`. Explicit named exported interfaces.
- Generate types from schemas (JSON Schema, DB schema) rather than hand-writing parallel
  interfaces that can drift.
- Comment the *why*, not the *what*. A non-obvious constraint or workaround is worth a
  comment; what the code does is already in the code.
- No speculative abstractions. No error handling for scenarios that can't happen.

## Project-specific

<!-- Add stack, build commands, architecture notes, and project-specific rules here. -->

```bash
# Example — replace with real commands:
# npm run dev      # dev server
# npm test         # test suite
# npm run build    # production build
```
