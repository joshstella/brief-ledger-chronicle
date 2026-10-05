# Ledger — #0019 The source is not a target, and still has to run itself

`blc/2 #0019 in-progress a:done(PR#91) b:done(PR#93) c:in-progress(brief/0019-c-the-rules,PR#102) d:pending e:pending`

**Brief:** `docs/blc/briefs/0019-the-source-is-not-a-target/brief.md`
**Started:** 2026-10-03
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the Claude links | done (PR#91) | — |
| b | the repo rule | done (PR#93) | — |
| c | the rules | in-progress (PR#102) | `brief/0019-c-the-rules` |
| d | orient names it | pending | — |
| e | the seeded agent file | pending | — |

The brief letters "orient names it" `e` and "the seeded agent file" `d`. They are swapped here
because letters run in execution order, and the agent file is the phase most likely to wait on
a decision. Orient has no open decision, so it goes first.

Re-lettered again on 2026-10-03, after `a`: "the repo rule" was `c` and is now `b`, and "the
rules" was `b` and is now `c`. No merged PR cites either letter. See "Freeze, 2026-10-03" below.

**a — the Claude links.** Commit links under `.claude/` so that Claude Code loads this
repository's own skills with no install and no machine step. Each utility skill gets a
directory link `.claude/skills/<s>` to `../../skills/<s>`. Each process skill gets a file link
`.claude/commands/<s>.md` to `../../skills/<s>/SKILL.md`. That is the same split a target
install makes. Tests: each link resolves, each is committed as mode `120000`, and the set of
links equals the skill and command rows that `install.sh --print-ownership --host claude`
prints. The same test checks `.cursor/skills` against `--host cursor`. So a skill that reaches
one host and misses the other fails the suite. After merge, the four links placed by hand in
`~/.claude` are deleted, and this ledger records it.

**b — the repo rule.** The rule that forbids product knowledge from another codebase in this
repository binds Claude Code as well as Cursor. Today only Cursor loads it, from
`.cursor/rules/no-cq-leak.mdc`. One source file, linked into each host's rules directory. Test
that both resolve to the same file.

**c — the rules.** `templates/process-rules.md` binds both hosts in this repository, as it
binds every target. Claude Code gets `.claude/rules/brief-ledger-chronicle.md`, a link to the
template. Cursor gets `.cursor/rules/brief-ledger-chronicle.mdc`, a committed file, because
Cursor needs `alwaysApply: true` frontmatter and a link cannot add it (decision 1, option b).
`install.sh --print-process-rules` prints the bytes an install writes, and a test compares the
committed file against it, so an edit to the template without a regeneration fails the suite.
Both destinations come from the rules rows of `--print-ownership`, as `a`'s parity test does.

**d — orient names it.** `tools/orient.sh` says "self-hosted toolkit source" when a host's
skills path in the repository is a link into `skills/`, instead of "not set up by the
installer". A real target, and a repository with no install, keep the current messages. Tests
in `tests/test_orient.sh` for all three cases.

**e — the seeded agent file.** `install.sh` seeds `CLAUDE.md` / `AGENTS.md` from the Manifesto
instead of the current stub. This repository gets the same seed once and commits it, and from
then on owns it, as any target does. This changes what every target install writes, so it waits
on decisions 2, 3 and 4.

## Freeze, 2026-10-03

The owner wants this repository stable for a while, because every other project on this machine
uses it. So after `a`, only one more phase runs now: the repo rule, now `b`. It is the one gap
with a real risk. A hard rule binds Cursor sessions in this repository and not Claude Code
sessions.

`c`, `d` and `e` stay `pending` during the freeze, with no branch. They are not `deferred`.
#0007's ledger defines `deferred` as code parked on a branch, and none of these has code.
`open-briefs.sh` reports a `deferred` phase with no branch on every run. `c` waits on decision 1,
`e` on decisions 2 to 4, and `d` waits only on the freeze. The brief stays `in-progress`.

**What `a` taught.** The parity test reads `--print-ownership`, and that worked on the first
attempt for both hosts, so `b` and `c` can extend it the same way. The links resolved for
Claude Code in the session that made them: `blc-my-briefs` and `blc-orient` appeared in its skill
list. Two items from `a`'s review stay open. Whether Claude Code loads `.claude/commands/` from
the project, or the machine-wide copy, is not known while both exist. Whether Cursor also reads
`.claude/skills/` is not known either.

**The links placed by hand.** `a` replaces them only inside this repository. Three of them are
skill directories in `~/.claude/skills/`, and every project on the machine can use them. So only
`~/.claude/commands/blc-orient.md` is deleted after `a`. The three skill directories stay until
the owner decides whether another project depends on them.

**`b` is marked done on its own branch, `brief/0019-freeze`.** The usual rule is that the next
phase's branch marks the previous phase `done`. A freeze has no next phase, so without this
branch `main` would show `b` `in-progress` on a deleted branch, and `open-briefs.sh` would say so
on every run. When work restarts, the next phase branches from `main` as usual.

## Dependency structure

`a` goes first. It creates the `.claude/` tree that `b` and `c` add to, and the parity test
that `b` and `c` extend. After `a`, the phases `b`, `c`, `d` and `e` are independent in the code. They
still run one after another, because each phase branch writes this ledger's status line.

`e` is provisional. If decision 3 moves it to a brief of its own, `e` becomes `skipped` here and
`blc-next-brief-phase` closes the brief after `d`.

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | **Settled 2026-10-05: option (b), a generated file with a drift test.** From the brief. Evidence 2026-10-03: the Claude Code docs say `paths` is the only frontmatter field it reads from a rule, so option (a) would work for it. (a) was rejected anyway: the installer prepends the same frontmatter for a Cursor target, so (a) also changes what every target gets, and the freeze is over for this brief only. Under (b) nothing a target receives changes. This repository commits `.cursor/rules/brief-ledger-chronicle.mdc` and links `.claude/rules/brief-ledger-chronicle.md` to the template. Rejected: (c), a `tools/self-host.sh` that regenerates it, which is a second program to keep current. | `c` |
| 2 | **What part of the Manifesto seeds a target's agent file**, how that agrees with the reason `tests/test_orient.sh:370` gives for not shipping `orientation.md`, and whether it repeats `templates/process-rules.md`. From the brief. | `e` |
| 3 | **Whether `e` stays in this brief.** From the brief. | `e` |
| 4 | **One agent file or two.** From the brief. New evidence 2026-10-03: the Claude Code docs say it reads `AGENTS.md` natively from v2.1.277, but only when no `CLAUDE.md` exists. Older versions need `CLAUDE.md`. A real `AGENTS.md` with `CLAUDE.md` as a link to it gives one text to both hosts on every version. | `e` |

## Complications

- **The skill roster in `tests/test_skill_names.sh` is stale.** `BLC_UTILITY` names three of the
  five utility skills; `blc-orient` and `blc-my-briefs` are missing. This is why `a` derives its
  set from `--print-ownership` and not from a list.
- **`--print-ownership` prints rows that self-hosting must not copy.**
  `.claude/settings.local.json` is per user, and the user's global ignore excludes it. The
  `CLAUDE.md` / `AGENTS.md` rows are project-owned, and they are `e`'s work. The rules rows are
  `c`'s. The parity test in `a` excludes each of them by name, and says why.
- **Two shapes for one parity.** `.cursor/skills` is one directory link, because Cursor takes
  every skill as a skill. Claude Code splits skills and commands, so it needs one link for each
  skill. The parity test compares destinations, not shapes.
- **Symbolic links on Claude Code.** The docs confirm it follows links for skill directories and
  rule files. For command files they do not say. The evidence is this machine:
  `~/.claude/commands/blc-orient.md` is a file link, and `/blc-orient` ran from it on
  2026-10-03.
- **Which scope wins is unclear.** After `a`, the six process commands exist in
  `~/.claude/commands` (from `--machine`) and in `.claude/commands`. The docs, as reported, list
  a precedence order and also say the project wins, and those two do not agree. In this checkout
  both resolve to the same file, so the answer has no effect here.
- **`.cursor/skills` is a link to `skills/`,** so `skills/blc-start-brief/SKILL.md` is the one
  copy of the skill that wrote this ledger.

## Branches

`brief/0019-a-the-claude-links` (phase `a`, merged as PR#91, deleted).
`brief/0019-b-the-repo-rule` (phase `b`, merged as PR#93, deleted).
`brief/0019-freeze` (marks `b` done; no phase of its own).
