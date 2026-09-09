# Ledger — #0010 The skills live in someone else's namespace
`blc/2 #0010 in-progress a:done(PR#38) b:in-progress(brief/0010-b-the-check)`

**Brief:** `docs/briefs/0010-skill-namespace/brief.md`
**Status:** in-progress
**Date:** 2026-09-09

## Phase sequence

| id | status | what it does |
|---|---|---|
| `a — the names` | done (PR#38) | Rename nine directories under `skills/` to `blc-<name>` and delete `skills/to-do/`. Update the three structural sites in `install.sh` — `PROCESS_SKILLS`, the machine-mode symlink loop, the template-presence check — and its inline process-rules text. Update `templates/process-rules.md`, `README.md`, `Manifesto.md`, `docs/slides-process-overview.md`, `personal/CLAUDE.md`, the skill prose, and the skill names in `tools/open-briefs.sh` and `tools/validate-briefs.sh`. Reword the two `create-brief` mentions in Contract v1.1 in place. Write the naming rule into `docs/briefs/README.md`. Carries the minimum test edit needed to keep the suite green — see the re-plan below. |
| `b — the check` | in-progress (brief/0010-b-the-check) | New coverage: a fresh install places nine skills all prefixed and six slash-commands all prefixed; no unprefixed skill name and no `to-do` survives outside `docs/briefs/`; both hosts agree on the six. |

## Dependency structure

- **Strict chain: `a` → `b`.** Nothing here is parallel.
- `a` is one atomic move. A half-renamed toolkit is broken on both hosts, so there is no
  useful place to stop inside it.

## Re-plan against the brief, at initiation

**Phase `a` carries the test edits needed to stay green; `b` adds new coverage.**

As filed, `a` renames the skills and deletes `to-do`, and `b` updates the tests. Two files
hardcode the shipped skill list:

```
tests/test_hosts.sh:9         UTILITY="chronicle installer-builder ste-writing to-do"
tests/test_machine_mode.sh:35 for s in chronicle ste-writing to-do installer-builder; do
```

Landed as separate PRs in the filed order, `main` is red between them. The brief's own
argument for making the rename atomic — a half-renamed toolkit is broken on both hosts —
applies to the suite as well: a toolkit whose tests fail is not in a landable state either.

So `a` updates those two lists as part of the rename, which is the smallest edit that keeps
the suite honest, and `b` adds the assertions that pin the new namespace. Both phases stay
separately reviewable and `main` is green at every merge.

## Open decisions

None. The brief resolved its own before filing.

## Complications found in the code, not addressed by the brief

1. **`templates/process-rules.md` ships to every target and names seven skills.** It tells
   agents that `commit-push-pr` is the only path to `main`, that `review-pr` is the review
   gate, and that briefs are filed with `create-brief` then `start-brief`. The brief's phase
   `a` lists `README.md`, `Manifesto.md`, `docs/`, and the skills' own prose, but not this.
   It is the highest-stakes file in the rename: it is the agent-facing rule file in every
   installed project, and left stale it points agents at skills that no longer exist.
   `install.sh` embeds similar rule text inline near line 187 and needs the same treatment.

2. **Contract v1.1 names `create-brief` twice.** Lines 91 and 100, in the serial-collision
   prose rather than in clauses `BRIEFS-1` through `BRIEFS-8`. The brief's non-goal — not a
   Contract clause — is respected, but Contract *text* still changes. Handled the way #0009
   settled the same shape one day earlier: reword v1.1 in place, no version bump, no clause
   change, on the grounds that `install.sh` ships every version to every target forever and a
   v1.2 whose delta is a tool's name is downstream noise. `v1.md` is superseded and stays as
   history.

3. **Two tools name skills in prose.** `tools/open-briefs.sh` and `tools/validate-briefs.sh`
   reference skill names in comments and findings. Neither parses one, so nothing breaks, but
   both would describe a toolkit that no longer exists.

4. **`chronicle` is a skill name and a common noun, and only one of them renames.**
   The other eight names never appear as ordinary English, so they were renamed mechanically.
   `chronicle` appears as the artifact throughout the Manifesto, the README, and the slides —
   "a chronicle is generated and read" — and as the path `docs/chronicles/chronicle.md`, which
   contains the substring `/chronicle` and would have been corrupted by a blanket pass on the
   slash-command form. Renamed by inspection instead: backticked `` `chronicle` ``, the
   `skills/chronicle/` path, and `` `/chronicle` `` as a command. Every prose use of the word
   as an artifact was left alone.

5. **The slides were already wrong, and removing `to-do` made them right.** Slide 11 says
   "Three skills" over a list of `chronicle`, `installer-builder`, and `to-do` — omitting
   `ste-writing`, which has shipped as a utility skill the whole time. Dropping `to-do` and
   listing `ste-writing` makes the count true for the first time. Not a goal of this brief;
   noticed because the block had to be edited by hand anyway.

6. **`personal/CLAUDE.md` is machine-mode, not project-mode.** It is installed to `~/.claude`
   rather than to a target, so it is invisible to the project-mode tests. A rename that misses
   it fails only on the author's own machine, and only later.

## Re-plan after PR #38

Remainder held: `b` was the only phase left and its scope did not change. `a` resolved
complications 1, 2, 3, 4 and 5 as it went, and fixed the file named in 6. What `b` adds is
different in kind — those fixes happened because they were noticed, and `b` converts them
into a guard that fails the suite if an unprefixed name returns.

Complication 6's actual point is not resolved and is not being resolved here: machine-mode
*installed output* is covered more thinly than project-mode. `b`'s sweep catches
`personal/CLAUDE.md` as a source file, because it is in the repository, but not the installed
result. That is a standing property of the suite, not something #0010 created.

## Branches

- `brief/0010-a-the-names` — phase `a`. Cut from `main` at 2a70c4c. Merged as PR #38.
- `brief/0010-b-the-check` — phase `b`. Cut from `main` at ae81bcc.
