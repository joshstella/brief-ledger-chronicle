# AGENTS.md

Project instructions for Cursor agents. Adapt the project-specific section below; the
process rules in the first section apply unchanged.

## Process — use the skills, don't go around them

This repo uses the brief-ledger workflow. Installed skills under `.cursor/skills/` are the
gates; bypassing them is the defect.

- **`commit-push-pr`** — the only path to `main`. Runs the review gate before committing.
  Never use raw `git commit && git push` for work headed to `main`.
- **`review-pr`** — called by `commit-push-pr`. Can also run manually on a PR or staged diff.
- **`create-brief`** — file a draft into `docs/briefs/`. Non-trivial work gets a brief before
  it starts, not after.
- **`start-brief` / `next-brief-phase`** — initiate and continue phased work.
- **`chronicle`** — narrative history from briefs, ledgers, and git.
- **`init-briefs`** — one-time setup. Already run if `docs/briefs/` exists.

## Working style

- **Direct challenge over affirmation.** Say when something is wrong and why. Skip
  flattery and padding.
- **Surface friction, don't smooth it.** If two goals conflict or a requirement is
  incoherent, name the tension — that's the useful signal.
- **One change at a time.** Single fix, shown, waited on. If a task implies many edits,
  propose the sequence first.
- **Ask rather than guess** on judgment calls that turn on intent or domain knowledge.
  Mark every assumption inline so it can be corrected.

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
