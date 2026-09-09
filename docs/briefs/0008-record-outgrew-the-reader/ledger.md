# Ledger — #0008 The record outgrew the reader
`blc/2 #0008 in-progress a:done(PR#41) b:done(PR#42) c:done(PR#43) d:done(PR#44) e:in-progress(brief/0008-e-the-read,PR pending)`

**Brief:** `docs/briefs/0008-record-outgrew-the-reader/brief.md`
**Status:** in-progress
**Date:** 2026-09-09
**Depends on:** #0006 (done, PR #31)

## Phases

| Phase | Status | Notes |
|---|---|---|
| `a — the layering` | done (PR#41) | Move the brief-table logic out of the chronicle skill into `tools/`; `gather.sh` calls it. No behaviour change. Blocked by open decision 1. |
| `b — the declaration` | done (PR#42) | The `docs/state/` convention: one file per contributor, `git config user.email` lowercased verbatim. Decisions 2, 3, 6, 7 all resolved. |
| `c — the verb` | done (PR#43) | The tool itself, plus the thin `blc-orient` skill over it (see decision 2). Emits landed state, intended state, off-limits, and the authored part. Exits zero on absent sources. Blocked by open decisions 4, 5. |
| `d — the check` | done (PR#44) | Tests: determinism, graceful absence, budget ceiling, no shared paths between contributors, clean run in an empty fixture. |
| `e — the read` | in-progress (`brief/0008-e-the-read`) | Point `blc-start-brief` step 4, `blc-next-brief-phase` step 5, and `blc-review-pr` step 3 at the verb; have `blc-create-brief` write and clear the declaration. Skill guards, not checks. |

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
2. ~~What the tool is called.~~ **Resolved 2026-09-09:** `tools/orient.sh`, plus a thin
   `blc-orient` skill over it.

   Two artifacts, and the split is deliberate. The brief is emphatic that this is a
   script — *"This is a script, so unlike a skill it can actually be asserted"* — and its
   whole testability argument rests on that, so the script is where the behaviour lives.
   But the brief's plan reaches an agent only through phase `e`, which points three
   existing skills at the command. A fresh agent that is not already running
   `blc-start-brief` is exactly the *"new agent arriving at this repository"* from the
   Ground, and it has no way to learn the tool exists. The skill is the discovery path:
   `/blc-` completes into the workflow.

   No `blc-` prefix on the script. #0010's convention exists because skills land in the
   host's shared namespace; `tools/` is a directory in the repository and has nothing to
   collide with. `validate-briefs.sh`, `open-briefs.sh` and `list-briefs.sh` are all
   unprefixed for the same reason.

   The name breaks the `<verb>-<noun>.sh` pattern of the other three, and that is the
   honest signal: they query the briefs directory, this one summarizes the repository.

   **Plan impact.** The skill is an artifact the brief did not scope. It belongs in phase
   `c`, which ships the verb, rather than `e`, which stays what the brief says it is:
   pointing the three existing skills at the command. This is the first time a skill in
   this repo wraps a repo-level tool — `blc-chronicle` wraps its own `scripts/gather.sh`,
   and nothing invokes `tools/` on an agent's behalf today.
3. ~~Where the authored file lives.~~ **Resolved 2026-09-09:** its own file,
   `docs/orientation.md`.

   The deciding argument is phase `d`, not taste. `d` asserts a size cap, and a cap is
   only enforceable on a file with one purpose and one owner. `AGENTS.md` is the file a
   team fills with stack and build notes, so the cap test would have to parse a section
   out of a file whose growth nobody controls — and would fail or pass for reasons that
   have nothing to do with the authored content.
4. The budget number. Blocks `c`, because `d` asserts it.
5. Whether the verb ships to targets. Blocks `c`.
6. ~~How a contributor filename is normalized.~~ **Resolved 2026-09-09:** lowercase the
   address and use it verbatim — `docs/state/josh.stella@gmail.com.md`.

   Lowercasing is the whole rule, and it exists for the case-insensitive filesystem the
   brief names. `@` and `.` are legal in a path on every filesystem this runs on, so
   nothing needs escaping. Verbatim keeps the mapping reversible in both directions —
   given a file you know the contributor, given a contributor you know the file — which a
   slug does not, and it cannot collide two addresses into one path.
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

- `brief/0008-a-the-layering` — phase `a`. Cut from `main` at c6c82c2. Merged as PR #41.
- `brief/0008-b-the-declaration` — phase `b`. Cut from `main` at 832b5cd. Merged as PR #42.
- `brief/0008-c-the-verb` — phase `c`. Cut from `main` at 3669df8. Merged as PR #43.
- `brief/0008-d-the-check` — phase `d`. Cut from `main` at the #43 merge. Merged as PR #44.
- `brief/0008-e-the-read` — phase `e`. Cut from `main` at the #44 merge.

## Phase `e` — what executing it changed

**`orient` does not replace `AGENTS.md`, and the brief's wording implies it might.** The
brief says to point the three steps *at the command* where they currently name `AGENTS.md`.
Read literally that drops architecture rules, which is what `blc-review-pr` needs most in
step 3 and which `orient` does not answer. `orient` reports state; `AGENTS.md` holds
project rules. The instruction now runs `orient` **first** and reads `AGENTS.md` after.

**Half of what the brief asks `blc-create-brief` to do would be theatre.** It says write the
declaration when a serial is claimed and clear it at filing. Both happen inside one run,
seconds apart, so a claim written there is cleared before it could ever be pushed — nobody
could read it. The useful half is implemented: clearing your own claim at filing, because
once the brief is filed the claim is derivable. The write half is documented as *not* done
and why, because the moment worth writing at is before this command runs, by a person.

**The valuable part of the wiring was not in the brief at all.** `blc-create-brief` now
checks other contributors' declarations for a claim on the serial it is about to take. That
is the only warning available for the half of the serial race `docs/briefs/` structurally
cannot show — the number is taken and unfiled, so the directory looks free. This is what
made evidence 7 worth acting on, and the brief's phase `e` did not name it.

**Part of the untestable phase turned out to be testable.** *"A skill guard is not a check"*
holds — nothing can force an agent to run the command. But whether the instruction is
*present* is mechanical, and a rename could sever the wiring in files no other test reads.
Four tests now assert that the three skills name `tools/orient.sh`, that `blc-create-brief`
knows about `docs/state/`, and that both the shipped rules file and the stub `AGENTS.md` a
target receives name the command. That does not make the guard a check; it makes the
plumbing a check and leaves the guard a guard.

**#0010's namespace sweep caught this phase writing `create-brief` unprefixed** in a new
comment. First time that guard has fired on work it was not written for.

**This repository still has no `AGENTS.md`.** The brief's Ground opens with the fact that
three skills tell an agent to read a file that does not exist here. Phase `e` fixed that for
every *target* — the stub and rules file both point at `orient` now — and did not fix it
here, because `docs/orientation.md` carries what this repo would put in one and creating an
`AGENTS.md` was not in scope. Worth a separate brief, not a silent addition.

## Phase `d` — what executing it changed

**Writing the tests found two bugs and one design mistake in `c`.**

*The empty-tree placeholder was read as an open brief.* `list-briefs.sh` emits a row of
dashes when there are no briefs, and that row has no status to filter on, so rung 0 showed
it as work in flight. A fresh install — the case the brief cares most about — displayed a
dash row instead of "Nothing open." The filter now requires a serial in the first cell.

*`docs/orientation.md` was checked for but never placed.* Phase `c` added it to the
installer's template-existence list and not to the loop that copies files, so the installer
verified a file it never shipped.

*And it should not ship at all.* That is the design mistake. The authored file is the one
part of the output that is not derived, and it is a statement about **this** project.
Shipping this repository's copy would install our principles into someone else's
repository — the same category error as shipping a numbered brief folder, which the
installer has always refused to do. A target authors its own, and orient's absence message
is what asks for it. The test now asserts it is *not* present after an install.

**Two of the tests are canaries, not checks.** The budget and cap tests measure this
repository's real output rather than a fixture, so they fail when the record outgrows the
budget — which is #0008's thesis failing, and should be loud. Both were verified by
padding `docs/orientation.md` until they broke: the cap at 352 tokens against 250, the
budget at 798 against 700. The first attempt at the budget canary did not trip, because
100 extra tokens still fit; that is the headroom decision 4 was chosen to have.

**The cost-does-not-grow test is the one that matters most.** Seven additional closed
briefs move the output by no more than ten tokens. That is the flat-rung property stated as
an assertion rather than an intention, and it is what decision 8 bought.

## Phase `c` — what executing it changed

**The brief's source for "off-limits" does not exist where it is needed.** The brief says
to derive it from *"the installer's ownership map"* in `install.sh`, and names the coupling
that creates as a standing tension. Both miss the harder problem: `install.sh` is not in a
target. Deriving from it would have produced a section that works only in this repository —
the cobbler's-shoes failure the brief warns about, in the one place it did not look.

`docs/install-log/install-log.md` is the answer. The installer writes it into every target,
append-only, listing every path it created. It is the installer's own record rather than a
restatement of it, so it cannot drift, and it is present exactly where the verb runs. The
tension is dissolved, not accepted.

**The log records what was written, not who owns it, and the first draft overclaimed.** A
run against a real target listed `AGENTS.md` and `.gitignore` as upstream-owned. Both are
project-owned by design — the installer creates them once and never clobbers them — so the
output was telling a reader not to edit the two files most likely to be theirs. Inferring
ownership would mean restating `install.sh`'s rules here, which is the drift this brief
argues against, so the section now says strictly what the log supports: these are paths an
install wrote. **Recording ownership class in the install log is the real fix and it is not
in this brief** — it belongs to `blc-installer-builder`, which owns that file.

**The cap did its job on the first file written against it.** `docs/orientation.md` came in
at 348 tokens against a 250 cap and went through three rounds of cutting to reach 248. No
principle was dropped; the prose was. That is the mechanism working as designed — quantity
forced triage — and it is also the limit of it, since nothing about a cap says the eight
principles are the right eight.

**Determinism ruled out the obvious freshness stamp.** Reporting "last fetched N days ago"
reads better and is not deterministic. Counting commits behind the upstream is exact,
derived from refs, and identical across two runs, so that is what the header does.

**Measured, not estimated.** 418 tokens total against the 700 budget, with the filtered
state section at 68 where the full table is 348. The brief's two unverified estimates —
~200 for off-limits and ~250 for authored — came in near enough that the premise holds.

## Phase `b` — what executing it changed

**Nothing here is enforced by code, and that is the phase's real weakness.** The
normalization rule is prose in `docs/state/README.md`. Nothing reads it until phase `c`,
so between these two phases the rule is exactly the kind of hand-maintained convention
this brief measured at 43%. `tests/test_state.sh` pins the expected answers against a
local implementation of the rule so that `c` has something to be wrong against, but that
is a placeholder for enforcement, not enforcement. Scope was left alone deliberately
rather than pulling a helper forward out of `c`.

**No declaration was written for this brief, on purpose.** The obvious dogfooding move is
to declare #0008 in `docs/state/`. It would have been wrong: #0008 is filed and has a
ledger, so every fact about it is derivable, and the convention says declarations hold
only what derivation cannot reach. The correct steady state for a contributor with
nothing unfiled is no file at all. That the directory ships with only a README is the
convention working.

**The briefs README claimed a race was open that this phase narrows.** `docs/briefs/`
says single-point assignment *"is what keeps numbers from colliding"*, and Contract v1.1
separately records that two checkouts can still pick the same number. Both are true and
the pair read as a contradiction. A pointer now sits at the serial section. The Contract
is untouched — it is not wrong, and #0009's precedent for rewording it in place does not
apply to a clause that still describes reality.

**The installer names its docs in four places, not three.** Beyond the template check,
the ship loop and the summary echo, `docs/state/` needed adding to `SCAFFOLD_DIRS`:
`place_file` does not create parent directories, so the first install wrote the README
nowhere and reported success. Caught by installing into an empty repository, not by the
suite.

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

## Closeout

All five phases merged. Checked against the brief's success criteria on 2026-09-09:

- **One command answers all three questions.** `tools/orient.sh` — in flight, off-limits,
  values.
- **Under budget, asserted.** 416 tokens against 700, measured against this repository
  rather than a fixture, so the test fails when the record outgrows the premise.
- **Deterministic.** Two runs with no change produce identical bytes. This is why the
  freshness line counts commits behind the upstream instead of reporting elapsed time.
- **Clean on an empty tree.** Every source degrades to a stated absence and exits zero,
  verified in a bare git repository and in a fresh install.
- **Nothing written.** A test asserts the repository is untouched after a run.
- **No shared paths.** One ledger per brief, one declaration per contributor, no committed
  output.
- **A claimed-but-unfiled serial is visible to a peer who has fetched**, and
  `blc-create-brief` now warns on one before taking the number.
- **The three skills name it** where they named `AGENTS.md`, and so do the rules file and
  stub `AGENTS.md` that ship to a target.

**What the brief got wrong, in order of consequence.** Its source for "off-limits" —
`install.sh`'s ownership map — is not present in a target, so that section would have
worked only here; the install log replaced it. Its phase `e` asks `blc-create-brief` to
write a claim it would clear seconds later, and misses the check that makes declarations
pay for themselves. It mis-numbers its own untestable phase. And its central measurement,
243 tokens for the state table, was 348 by the time work started — the scaling tension it
listed as a future risk was already live.

**What it got right.** The verb framing, which made every noun formulation's problems not
arise. The three-mechanism split — derived, declared, authored — which is what stopped this
design stalling a third time. And the insistence on a script over a skill, which is the only
reason phases `c` and `e` could be checked at all.

**The claim this brief cannot support.** *"This repository is the worst available test of
the premise."* Still true. `orient` saves perhaps nine thousand tokens here against a
62,000-token record. The design is aimed at repositories where orientation costs hundreds
of thousands, and nothing local will show whether the filtering rule holds there. Treat the
first application to a large unrelated repository as the real test.

**Still open, deliberately.** The install log records what an install wrote, not who owns
it, so `orient` cannot say which paths are safe to edit. Fixing that means recording an
ownership class in the log, which belongs to `blc-installer-builder`. And `chronicle.md`'s
merge conflict, named in the brief's settled decisions, still has no answer.
