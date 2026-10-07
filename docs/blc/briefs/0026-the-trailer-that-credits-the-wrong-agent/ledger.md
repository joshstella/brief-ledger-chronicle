# Ledger — #0026 The trailer that credits the wrong agent

`blc/2 #0026 in-progress a:in-progress`

**Brief:** `docs/blc/briefs/0026-the-trailer-that-credits-the-wrong-agent/brief.md`
**Started:** 2026-10-06
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the skill names no agent | in-progress | `brief/0026-a-the-skill-names-no-agent` |

**a — the skill names no agent.** `skills/blc-commit-push-pr/SKILL.md` told the agent to end
every commit message with a trailer naming one host. That file ships to every host unchanged, so
the line credited the wrong agent everywhere except where it was written. This phase replaces the
fixed name with an instruction that defers to the running agent: attribute yourself, and only if
your host has not already done it. The file then names no agent, and is correct on a host that
self-attributes and on one that does not. Two guards sweep `skills/`, `templates/` and
`personal/` for an agent trailer and for an agent address, and both fail against the line that
shipped.

## Dependency structure

One phase. The brief asked four questions. Question 3 — does every host attribute itself — was
the one that governed the others, and the answer dissolved them: if each host writes its own
trailer, there is nothing to substitute and no mechanism to build.

## Settled decisions

| # | decision | blocks |
|---|---|---|
| 1 | Substitute at install, or write no trailer at all → **neither; the agent names itself** | a |
| 2 | Special-case the string, or build a host-substitution mechanism → **neither** | a |
| 3 | Does every host attribute itself → **no, hosts differ** | 1, 2 |
| 4 | Does an upgrade correct an installed copy → **yes, at no cost** | — |

**1 and 2 — dissolved, not chosen.** Both questions assumed the fix is a string this repository
decides, either at install time or by hand. It is not. The agent that writes the commit knows
what it is, so the file can defer to it and name nobody. That needs no substitution mechanism and
no install-time pass, and it is correct on a host this repository has never seen.

**3 — hosts differ, and the first answer to this was wrong.**

> *Superseded, recorded because the error is the point.* This was first settled as "yes, every
> host attributes itself", on the evidence that commits `7c2c716` and `6102bba` carried one
> Cursor trailer and no Claude trailer. That evidence was worthless. Both commits were written by
> the agent in that session, which typed the Cursor trailer into the message itself. The
> measurement read back the author's own habit as the host's behaviour — the same circularity
> that had already been named and discounted for the Claude side, and not noticed on the Cursor
> side because it gave the convenient answer.

The correction came from a commit that deliberately carried no trailer: `a2c4234` has none, so
Cursor adds nothing of its own. Claude Code does self-attribute, declared by the owner from use
and not derived here. So a plain deletion would have been wrong — it would have fixed the
misattribution by making Cursor commits credit no agent at all.

**4 — an upgrade corrects an installed copy.** `place_dir` in `install.sh` removes the target
directory and copies the source over it on every run, so an installed skill is replaced whole.
No migration step is needed. A target that never reinstalls keeps the old line, which is true of
every toolkit-owned file and is not specific to this fix.

## Deviations

**The ledger was written after phase `a`, not before it.** `blc-start-brief` writes the initial
ledger to `main` before the first branch is cut, so the plan is visible before the work. Here the
governing question was settled in one exchange and the fix was a deletion, and the branch was cut
before the ledger existed. The ledger is therefore in the phase commit, not on `main` ahead of
it. Recorded because a skipped gate and one that ran look the same afterwards.
