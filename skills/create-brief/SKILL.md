---
name: create-brief
description: >-
  File an unnumbered draft into docs/briefs/ with the next serial. Use when the user asks to create-brief or file a draft brief.
---

# create-brief

File an authored, **unnumbered** brief into `docs/briefs/` under the next serial. This
command is the **single point of serial assignment** — briefs are authored number-free
and get their identity here, at filing time, not while being written.

## Input

`create-brief <path-to-draft.md> [slug]`

- `<path-to-draft.md>` — an unnumbered draft brief (usually from `docs/briefs/_drafts/`,
  or any path). It contains a `# H1` title and a provenance line stamped at draft-write
  time: `**Created:** <ISO-8601 UTC>` and `**Author:** <email>`, optionally
  `**Depends on:** …` (and, later, `**Jira:** …`).
- `[slug]` — optional explicit slug. **Slug precedence: this arg → the draft's filename
  stem → kebab-cased H1.** The usual path is to name your draft file what you want the
  slug to be (`mobile-ts-theme.md` → slug `mobile-ts-theme`); the H1 of a real brief is
  a sentence and makes a poor slug.

## Steps

0. **Preflight.** If `docs/briefs/` or `docs/briefs/_drafts/` is missing, **stop** and
   tell the user to run `init-briefs` first. Do not scaffold the structure here — setup
   is `init-briefs`'s job; this command assumes it exists.
1. **Compute the next serial.** List `docs/briefs/`; from each entry **whose name begins
   with four digits**, parse `NNNN`; take the max and add 1; zero-pad to four. Entries
   without a leading four-digit prefix (`_drafts/`, `README`, etc.) are ignored. If there
   are none, start at `0001`.
2. **Collision guard.** If `docs/briefs/NNNN-*` already exists, increment until free —
   defensive against a stale read. Assignment must reflect the directory *now*.
3. **Resolve the slug.** By the precedence above. Strip any leading `NNNN-` from a
   derived slug (in case the draft filename was pre-numbered). Validate `^[a-z0-9-]+$` —
   reject otherwise. If the slug came from the H1 and exceeds ~40 chars, stop and ask for
   an explicit slug. If the slug already names an existing brief under a different
   serial, warn and surface it, then proceed.
4. **Stamp and file.** Create `docs/briefs/NNNN-slug/` and write `brief.md` from the
   draft. Produce **exactly one** identity line directly under the H1, prepending the
   serial and **carrying the draft's provenance forward unchanged**:
   `**Serial:** #NNNN · **Created:** <from draft> · **Author:** <from draft> · **Depends on:** <deps>`
   (append `· **Jira:** …` if the draft carried it.) `<deps>` comes from the draft's
   `**Depends on:**` line — **which, along with the draft's separate `Created`/`Author`
   line, is consumed into this single line so no duplicate remains** — or `—` if absent.
   If the draft is missing `Created`/`Author`, resolve `Author` from `git config
   user.email` (falling back to `user.name`) and stamp `Created` = now, warning that the
   draft should have carried them from write time, then proceed. Git config is the only
   identity source — every repo already has one, so there is nothing extra to install or
   keep in sync.
5. **Clean up.** Remove the draft file if it was a staging file.
6. **Report** the created path, serial, and depends-on. Do **not** auto-commit — leave
   that to `commit-push-pr` (which carries `#NNNN` into the PR title).

## Rules

- **One brief per invocation.** Serial assignment re-reads `docs/briefs/` each run and
  files one placement; this is what keeps numbering atomic and collision-free.
- The serial is assigned **only** here. Authoring tools (the feature-brief skill) produce
  unnumbered drafts and never guess a number.
- The serial encodes identity only — never status or phase.
- The unit is always a **folder**: `NNNN-slug/brief.md`. The ledger (`ledger.md`) joins
  it on execution; no brief migrates from file to directory.
