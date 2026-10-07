---
name: blc-architecture
description: >-
  Read a project's code and write docs/architecture/README.md — what the system is made of and
  how the parts connect, every claim citing the code that proves it. Use when the user asks to
  blc-architecture, for an architecture document or diagram, or for a map of how this system
  fits together.
---

# blc-architecture

Write one file: `docs/architecture/README.md`. It says what the system is made of and how the
parts connect. Every claim names the code that proves it, and `tools/check-architecture.sh`
checks every one of those names.

No script can derive structure from an arbitrary codebase, so you read the code and write the
graph. That is why the citations are not optional. A committed document with no citations is a
confident statement nothing can falsify, and it starts going quietly wrong the day after it is
written (#0029).

## What this document is not

It does not say **why**. The briefs and ledgers hold the reasoning, and repeating it here makes a
second copy that drifts from the first. Write what is true now.

It is not a history. `blc-chronicle` tells the story of becoming. This file states the current
state, and the two have opposite staleness.

It is one file. Not a directory, not a file per subsystem. With several, nothing says which
should exist and nothing says which is current (#0006).

## The citation

```
<!-- cite: <path> :: <anchor> -->
```

The path is relative to the repository root. The anchor is literal text that appears in that
file — a declaration, an export, a route string, a config key. Both are checked:
`check-architecture.sh` reports a citation whose file is gone and one whose anchor no longer
appears.

The anchor is optional. With none, the citation claims only that the file exists, which is the
right claim for "this directory holds the migrations" and the wrong one for an edge.

Three rules the verifier cannot enforce for you, which is why they are here and why you must
hold them yourself:

- **Never put `-->` inside an anchor.** It ends the citation. Everything after it is lost, and
  what remains may still resolve, so the document reports a pass over a claim nothing read.
  `>`, `=>`, and `--` are all safe — this reads correctly:

  ```
  <!-- cite: src/api/handler.ts :: export const handler = () => -->
  ```

  Only the full `-->` is not.
- **Keep paths inside the repository.** An absolute path to a file outside the work tree
  resolves happily and tells a reader nothing they can open.
- **Cite only what you opened.** An anchor recalled rather than read is the failure this whole
  format exists to prevent, and a plausible wrong anchor is the one kind the verifier catches
  loudest — after it is committed.

## The diagram carries no citations

Put a Mermaid diagram at the top if the shape is worth seeing. Keep it bare: a Mermaid fence is
parsed, not rendered as Markdown, so an HTML comment inside it is text the diagram tries to
read.

Every edge the diagram draws is then restated in a list below it, one line each, carrying the
citation:

```
- The API server reads jobs from the queue. <!-- cite: src/api/worker.ts :: queue.consume -->
```

The diagram is the picture. The list is the evidence. A reader checks the list; the verifier
checks the list; the diagram is allowed to be a simplification because the list is not.

## Steps

1. **Read the code.** Entry points, build and deploy configuration, module boundaries,
   datastores, and the calls that cross between them. Breadth before depth: a map that is right
   about five components beats one that is detailed about two and silent about the rest.
2. **Write the file** to `docs/architecture/README.md`, creating the directory if needed. Use
   the `blc-ste-writing` skill, STE-flavored mode, as all process prose here does.
3. **Run `bash tools/check-architecture.sh`** and fix what it reports before you hand over. A
   citation that fails here is one you wrote wrong minutes ago, which is the cheapest moment it
   will ever be to correct.
4. **Report the citation count and anything you could not cite.** A component you believe exists
   but could not pin to a file is worth a sentence to the person. Do not write it into the
   document as an uncited claim.

## Rewriting it later

Rewrite the file; do not append to it. This document has no history — it states what is true
now, and the history lives in git and in the ledgers.

`docs/architecture/` is project-owned. No install writes it, and a reinstall does not touch it.
Nothing in the toolkit will overwrite your work here, and nothing will update it either.
