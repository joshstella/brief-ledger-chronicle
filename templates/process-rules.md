# brief-ledger-chronicle

This repo uses the brief-ledger-chronicle workflow. Installed skills are the gates;
bypassing them is the defect.

## Process

- `commit-push-pr` is the only path to `main`. Do not use raw `git commit && git push`
  for work headed to `main`.
- `review-pr` is the review gate. A Request changes verdict blocks the commit.
- Non-trivial work gets a brief before it starts (`create-brief`, then `start-brief` /
  `next-brief-phase`).
- `chronicle` renders the record. `init-briefs` is one-time setup.

## Writing

Default prose uses the `ste-writing` skill in STE-flavored mode. Apply it to briefs,
ledgers, chronicles, commit messages, PR bodies, reviews, comments, and docs. Do not
apply it to code, identifiers, command syntax, or the user's own words.

## Tests

Tests gate `main`. Merges to `main` need tests covering the change, run and passing.
An untestable merge gets an explicit "test-exempt because…" in the PR, not a silent gap.
