# Ledger — #0008 The record outgrew the reader
`blc/2 #0008 in-progress a:in-progress(brief/0008-a-the-layering) b:pending c:pending d:pending e:pending`

**Brief:** `docs/briefs/0008-record-outgrew-the-reader/brief.md`
**Status:** in-progress
**Date:** 2026-09-09
**Depends on:** #0006 (done, PR #31)

## Phases

| Phase | Status | Notes |
|---|---|---|
| `a — the layering` | in-progress (`brief/0008-a-the-layering`) | Move the brief-table logic out of the chronicle skill into `tools/`; `gather.sh` calls it. No behaviour change. Blocked by open decision 1. |
| `b — the declaration` | pending | The `docs/state/` convention: one file per contributor, filename derived from `git config user.email`. Blocked by open decisions 2, 3, 6, 7. |
| `c — the verb` | pending | The tool itself. Emits landed state, intended state, off-limits, and the authored part. Exits zero on absent sources. Blocked by open decisions 4, 5. |
| `d — the check` | pending | Tests: determinism, graceful absence, budget ceiling, no shared paths between contributors, clean run in an empty fixture. |
| `e — the read` | pending | Point `blc-start-brief` step 4, `blc-next-brief-phase` step 5, and `blc-review-pr` step 3 at the verb; have `blc-create-brief` write and clear the declaration. Skill guards, not checks. |

## Dependency structure

Not the strict chain the brief's phase table implies.

- `a` and `b` are **parallel tracks**. The layering move touches `gather.sh` and `tools/`;
  the declaration convention touches `docs/state/` and documentation. They share no file.
- `c` depends on **both** — it consumes the extracted table and aggregates the declarations.
- `d` and `e` both depend on `c` and are parallel to each other. `d` asserts the script;
  `e` edits four skills.

Nothing here is provisional on a phase's outcome. The open decisions are resolved by the
user before their blocked phase starts, not discovered by executing an earlier one.

## Open decisions

Carried from the brief, with the phase each blocks. Resolved before that phase, not now.

1. ~~Where the current-state table lives.~~ **Resolved 2026-09-09:** `tools/`, with the
   chronicle calling it. The coupling the brief priced in turned out to be near-free — see
   complication 3 — and the alternative left one of two consumers owning the generator.
2. What the tool is called. Blocks `b`.
3. Where the authored file lives — a section of `AGENTS.md`, or its own file. Blocks `b`.
4. The budget number. Blocks `c`, because `d` asserts it.
5. Whether the verb ships to targets. Blocks `c`.
6. How a contributor filename is normalized. Blocks `b`.
7. What prunes an abandoned declaration. Blocks `b`.

## Complications

Found by reading the code, not stated in the brief.

1. **The brief's paths are stale.** It was filed before #0010 and names
   `skills/chronicle/scripts/gather.sh`, `create-brief`, and `installer-builder`. Those are
   now `skills/blc-chronicle/scripts/gather.sh`, `blc-create-brief`, and
   `blc-installer-builder`. The brief is the hypothesis as entered and is not rewritten;
   this mapping is the correction.

2. **The brief mis-numbers its own untestable phase.** The Tension says *"Phase `d` is an
   instruction to an agent"*, but the phase table makes `d` the tests and `e` the skill
   edits. The argument is right and the letter is wrong: `e` is the untestable one.

3. **The layering is easier than the brief feared, and the ledger should say so before
   decision 1 is made.** The four helpers the table needs — `cell`, `brief_title`,
   `brief_status`, `brief_depends` — are used *only* by the table; nothing later in
   `gather.sh` touches them. And `gather.sh` already documents that it runs from the
   repository root with `BRIEFS_DIR="docs/briefs"` relative, so a call to `tools/…` resolves
   in a target exactly as it does here. The brief treats the new coupling as a real cost.
   Read against the code it is close to free.

4. **Adding a tool means editing `install.sh` in two hardcoded places.** `tools/` is not
   shipped by globbing the directory — lines 443–444 and 618 name
   `validate-briefs.sh` and `open-briefs.sh` literally, and line 502 prints that pair to the
   user. Whatever decision 5 resolves to, phase `c` touches `install.sh` in three spots, and
   `blc-installer-builder` owns that file.

5. **The brief's measurements are already stale, in the direction of its own tension.** The
   243-token table figure and the *"all seven briefs"* it covers were taken before #0008,
   #0009 and #0010 existed. Ten briefs now. The brief's evidence also cites *"#0007 has no
   ledger"* as the live example of what `open-briefs.sh` reports; that is still true, but
   #0008 has joined it. The scaling problem the brief names as a future risk grew 43% during
   the interval between filing and starting.

6. **The state section's filtering rule is genuinely undesigned, and it is not an open
   decision.** The brief's tension is explicit that rung 0 must filter to open and recent
   work while #0006 settled that the chronicle table stays complete — one generator, two
   consumers, two rules. But no open decision covers it and no phase owns it. Phase `c`
   will hit this. It is the most likely place this brief needs a re-plan.

## Branches

- `brief/0008-a-the-layering` — phase `a`. Cut from `main` at c6c82c2.

## Phase `a` — what executing it changed

**The extraction was not as clean as complication 3 said.** The four helpers were
table-only, as recorded, but the *scan loop* was not: the chronicle's "To narrate"
section reads the same sorted briefs from the same temp file. Moving only the table
would have left a second copy of the scan behind — the drift this brief exists to argue
against. So the tool has two modes: the table, and `--tsv`, the sorted scan behind it.
One implementation of "which briefs, in what order"; two renderings.

**Resolving the tool by relative path was wrong and the tests caught it.** The first cut
called `tools/list-briefs.sh` on the strength of both scripts running from the repository
root. Twenty-seven gather tests failed at once. The fixtures are bare repositories with no
`tools/`, which is the shallow reason; the real one is that relative-to-CWD is a guess
about how the caller was invoked. It now resolves from `git rev-parse --show-toplevel`,
because the depth between skill and tool differs by host — `skills/` here,
`.cursor/skills/` or `.claude/skills/` in a target — and the root is the only fixed point
both share.

**Check order is part of the interface.** Adding the dependency check above the
`docs/briefs` check changed which error a user standing in the wrong directory sees. One
test failed on exactly that. The missing-directory message is the common case and stays
first; the missing-tool message is a broken install and comes second.

**The move forced a shipping change the brief did not anticipate, and it is not
optional.** `gather.sh` now exits non-zero without the tool, so any target with the skill
and not the tool has a chronicle that cannot run. `install.sh` names its tools literally
in three places (complication 4), all three updated. This is *not* open decision 5, which
is about the orientation verb; this one had no choice in it.

**Naming, flagged.** The tool is `tools/list-briefs.sh`, following the existing
`<verb>-<noun>.sh` convention and reading as the third question about the same directory:
`validate-briefs` asks if the record is well-formed, `open-briefs` asks what needs
attention, `list-briefs` asks what the state is. This is my choice, not the brief's — the
brief's open decision 2 names the *verb*, not this. Cheap to change while it has one
caller.

**Verification.** The digest is byte-identical before and after, which is the whole claim
of a no-behaviour-change phase. 178 tests pass, 11 of them new. The order guard was
checked by inverting the tsv sort and confirming it fails. A fresh Cursor install into an
empty repository runs its chronicle to completion.
