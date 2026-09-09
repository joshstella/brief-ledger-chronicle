# Ledger — #0008 The record outgrew the reader
`blc/2 #0008 pending a:pending b:pending c:pending d:pending e:pending`

**Brief:** `docs/briefs/0008-record-outgrew-the-reader/brief.md`
**Status:** pending
**Date:** 2026-09-09
**Depends on:** #0006 (done, PR #31)

## Phases

| Phase | Status | Notes |
|---|---|---|
| `a — the layering` | pending | Move the brief-table logic out of the chronicle skill into `tools/`; `gather.sh` calls it. No behaviour change. Blocked by open decision 1. |
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

1. Where the current-state table lives. Blocks `a`.
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

None yet. Phase `a` branches as `brief/0008-a-the-layering` once decision 1 is settled.
