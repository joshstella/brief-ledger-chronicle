---
name: blc-create-draft
description: >-
  Write a new idea into docs/blc/briefs/_drafts/ with no serial and no commitment to do the work. Use when the user asks to blc-create-draft, to start or park a draft, or to write an idea down before deciding to do it. Assigning the serial is blc-create-brief.
---

# blc-create-draft

Write an unnumbered draft into `docs/blc/briefs/_drafts/`. A draft is an idea written
down. It has no serial and no commitment to do the work.

This command does not file. Serial assignment is `blc-create-brief`.

**The provenance line is the point, not decoration.** `blc-create-brief` reads `Created`
and `Author` out of the draft when it files. A draft without them does not fail — the
filer stamps `Created` = now and resolves `Author` from git config — so the brief enters
the record with the date it was filed instead of the date the idea was had, and nothing
reports it. Write the line.

## Input

`blc-create-draft <slug>`

- `<slug>` — the draft filename stem. The user names it. A sentence title is a poor slug.
  If the user did not give a slug, stop and ask. Do not kebab-case the H1 into one.
- The H1 is the user's sentence for the work. If they did not give one, stop and ask.
  Do not invent a title.
- The body is only what the user supplied. If they supplied none, write the H1 and the
  provenance line and leave the body empty. Do not invent findings, phases, or scope.
- Optional, and only when the user supplied them: `Owner`, `Jira`. Never add a field they
  did not give.

## Steps

0. **Preflight.** If `docs/blc/briefs/` or `docs/blc/briefs/_drafts/` is missing, stop and
   tell the user to run `blc-init-briefs`. Do not scaffold the structure here.
1. **See what is already in flight.** Run `bash tools/orient.sh` from the repository root
   and read it as an index, unless you have already run it and the repository has not moved
   since. If an open brief or an existing draft already covers this work, say so and ask
   before writing.
2. **Resolve the slug.** Validate `^[a-z0-9-]+$`. Reject a name that begins with four
   digits: that shape is reserved for a filed brief, and `BRIEFS-7` is a `[defect]` the
   gate raises, so writing one here creates the defect rather than risking it. Reject
   `README`.
   If `docs/blc/briefs/_drafts/<slug>.md` already exists, stop. Do not overwrite it.
   If `docs/blc/briefs/*-<slug>/` already exists, stop and name that brief. The work is
   already filed.
3. **Stamp provenance.** `Author` is `git config user.email`. If that is empty, use
   `git config user.name` and say so. `Created` is now, UTC, from
   `date -u +%Y-%m-%dT%H:%M:%SZ`. Do not invent either value.
   If the user gave `Depends on`, check that each `#NNNN` is a folder under
   `docs/blc/briefs/`. A missing serial is a warning. Write the line anyway.
4. **Write the file** at `docs/blc/briefs/_drafts/<slug>.md`. One H1. Directly under it,
   one provenance line. No `Serial` field — that is the filer's to add, and a draft
   carrying one is a draft pretending to be a brief.

   ```markdown
   # <the user's sentence>

   **Created:** <ISO-8601 UTC> · **Author:** <email> · **Owner:** <email> · **Jira:** <key>
   **Depends on:** #NNNN
   ```

   `Owner` and `Jira` sit on the provenance line after `Author`, and only when the user gave
   them. An omitted `Owner` means `Author` when it is read, so adding one removes that
   fallback.

   `Depends on` goes last, on its own line, and is **always** written — `—` when the user
   gave no dependency. Every draft in the directory carries it, and one shape is what makes
   the directory readable at a glance.

   Keep the user's words. Where you compose a sentence, follow `blc-ste-writing` in
   STE-flavored mode.
5. **Do not file, claim a serial, or commit.** A declaration in `docs/blc/state/` is for
   work picked up but not filed, or for a serial you are about to take. This command does
   not write one. A draft is committed to git when the user wants the idea parked. Leave
   that commit to them.

## Report

Report the path, the slug, and `Created` / `Author`. Say that `blc-create-brief` is the
one-way door that assigns the serial.

If the draft has no body, say so plainly — a title and nothing else is a legitimate parked
idea, and it is also what a run that stopped half way leaves behind. The two are identical
on the disk, so the report is the only place they can be told apart. This is not a warning
and nothing is wrong.

## What this command does not do

- It does not assign a serial or write `NNNN-slug/brief.md`.
- It does not write a ledger. That is `blc-start-brief`.
- It does not overwrite a draft or a filed brief.
