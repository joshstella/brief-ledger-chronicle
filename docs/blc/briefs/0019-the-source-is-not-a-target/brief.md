# The source is not a target, and still has to run itself

**Serial:** #0019 · **Created:** 2026-10-03T11:13:17Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## Ground

blc assumes two things are separate. The toolkit is copied into a project and pinned at
onboarding. The project's record evolves on top of that copy. In this repository the two are
one directory. Pinning means nothing here, because every change is the toolkit changing.

`install.sh:114` states half of the answer: "This repo is the source of the process, not a
target for it." That is right, and the guard stays. The other half was never stated: if the
source is not a target, how does it run its own process? Each time that question came up, it
got a local answer. The answers do not agree with each other, and they do not agree between
hosts.

Work on blc meets exceptions to blc that no other repository meets. This brief collects them
and gives them one mechanism.

## The claim

**The toolkit source self-hosts by committed links, never by an install, and both hosts get
the same thing a target install gives them.**

A link is not a copy, so nothing drifts and an edit is live at once. Live is correct for the
repository whose work is the toolkit. `.cursor/skills -> ../skills` already does this for
Cursor and is pinned by `tests/test_skill_names.sh:156`. This brief makes that the rule, gives
Claude Code the same, and closes what neither host gets today.

## Evidence

Measured 2026-10-03 against `main` at `ad788c7`.

| Piece | Target install (both hosts) | Here, Claude | Here, Cursor |
|---|---|---|---|
| All 11 skills | yes | 6 commands from `--machine`, plus 4 links placed by hand; `blc-my-briefs` absent | yes, via `.cursor/skills` |
| Process rules (`templates/process-rules.md`) | yes | no | no |
| `CLAUDE.md` / `AGENTS.md` | stub (`install.sh` `write_project_stub`) | none | none |
| `no-cq-leak` rule | n/a | **absent** | `.cursor/rules/no-cq-leak.mdc` |
| Install log | yes | no | no |

**1. Claude Code cannot load this repository's skills from the repository.** There is no
`.claude/`. On 2026-09-16 four links were placed by hand in `~/.claude`: `commands/blc-orient.md`
and `skills/blc-chronicle`, `blc-installer-builder`, `blc-ste-writing`. They are not in any
install log, so `--uninstall` does not remove them, and a `--machine` run meets
`commands/blc-orient.md` as a path it does not own. They are also machine-wide, so they appear
in every other repository on the machine, beside that repository's own pinned copies.

**2. `blc-my-briefs` is unreachable from Claude Code here.** It is in neither the machine roster
nor the hand-placed links. Nobody noticed, which is the cost of per-skill workarounds.

**3. A hard rule binds one host only.** `no-cq-leak.mdc` is `alwaysApply: true` for Cursor.
A Claude Code session in this repository has no such rule.

**4. Neither host gets the process rules.** A target receives `templates/process-rules.md` as
`.claude/rules/brief-ledger-chronicle.md` or `.cursor/rules/brief-ledger-chronicle.mdc`. This
repository, which writes those rules, runs without them.

**5. Neither host gets an agent file.** There is no `CLAUDE.md` or `AGENTS.md`. The user's global
working agreement says each project's `CLAUDE.md` defines what "covered" means for tests. Here
nothing defines it.

**6. A workaround was about to become a reclassification.** Branch
`brief/orient-is-a-process-skill` added `blc-orient` to `PROCESS_SKILLS` so that `--machine`
would link it. That changes what every adopter's host gets, to fix a problem only this
repository has. `tests/test_hosts.sh:9` and `tests/test_machine_mode.sh:35` classify orient as a
utility skill and would fail. The change is withdrawn; see non-goals.

## Change

| Phase | Work |
|---|---|
| `a — the Claude links` | Commit `.claude/skills/<s>` → `../../skills/<s>` for the utility skills and `.claude/commands/<s>.md` → `../../skills/<s>/SKILL.md` for `PROCESS_SKILLS`, matching a target's split. Tests mirror the two Cursor tests at `test_skill_names.sh:156`: each link resolves, and each is committed as mode `120000`. A test that the self-hosted set equals the set a target install places, for each host, so a new skill cannot reach one host and miss the other. |
| `b — the rules` | Process rules reach both hosts in this repository. Blocked by open decision 1. |
| `c — the repo rule` | `no-cq-leak` binds both hosts. One source file, linked into each host's rules directory. Test that both resolve to the same file. |
| `d — the seeded agent file` | `install.sh` seeds `CLAUDE.md` / `AGENTS.md` from the Manifesto instead of the current stub. This repository gets the same seed once and commits it; from then on it is project-owned, as in any target. Blocked by open decisions 2 and 3. |
| `e — orient names it` | `tools/orient.sh` detects self-hosting (a host's skills path is a link into `skills/`) and says "self-hosted toolkit source" instead of "not set up by the installer". Test in `tests/test_orient.sh`. |

Chain: `a` first, because `b`, `c` and `d` all add to the `.claude/` tree it creates. `b`, `c`,
`d` are independent of each other. `e` is independent of all of them.

Outside the repository, after `a` merges: delete the four hand-placed links in `~/.claude`.
That is machine state, not repository state, so no test can see it. The ledger records it.

## Tension

**Live links remove the pin, on purpose.** A target pins what it was onboarded with. Here, a
half-edited skill is the skill the next session loads. That is the correct trade for the
source, and it is also a way to break your own tools mid-brief. The Cursor link has carried
this risk since 2026-09-15 without incident; that is evidence, not proof.

**Everyone who clones the toolkit gets a `.claude/` and a `.cursor/`.** People clone it to run
`install.sh` or to contribute. Neither is harmed. A person reading the tree may still take the
dot-directories for an install. Phase `e` and the agent file are what say otherwise.

**Machine mode and project mode overlap here.** After `a`, the six process commands exist in
both `~/.claude/commands` and `.claude/commands`. In this checkout both resolve to the same
file. How Claude Code resolves a name defined at both levels is not verified.

**Seeding the agent file from the Manifesto puts the toolkit's values into someone else's
repository.** `tests/test_orient.sh:370` refuses to ship `docs/blc/orientation.md` for exactly
that reason: "Shipping this repo's copy would install our principles into someone else's
repository." Phase `d` does what that test forbids, for a different file. Either the test's
reason is wrong, or the seed must be limited to what an adopter has agreed to by adopting.
That is open decision 2, and it must be settled before `d`, not discovered during it.

**Phase `d` is not self-hosting.** It changes what every target install writes. It is in this
brief because the agent file is one of the gaps, and the user chose the Manifesto as its source.
It may be a brief of its own. That is open decision 3.

**Some exceptions stay.** The `.gitignore` negation for `templates/.claude/settings.local.json`
exists because this repository ships templates. Files that are both a shipped template and
this repository's own copy, such as `docs/blc/briefs/README.md`, stay that way. Self-hosting
does not touch either. They are the cost of being the source.

## Settled decisions

Resolved 2026-10-03 during drafting.

- **The guard at `install.sh:114` stays.** Self-hosting is by links. An install into the source
  duplicates `skills/` and gives two copies to keep in sync.
- **Parity is the requirement.** Whatever a target install gives one host, this repository
  gives both, or the brief records why a host cannot have it.
- **No fabricated install log.** This repository was not installed. Orient learns to say so
  correctly (phase `e`) rather than reading a log written to satisfy it.
- **The agent file is seeded from the Manifesto.** User direction. The scope of the seed is
  open decision 2.

## Open decisions

1. **How the Cursor rules file gets its frontmatter.** `install.sh:205` prepends
   `alwaysApply: true` at install time, and a link cannot prepend. Options: (a) put the
   frontmatter in `templates/process-rules.md` and link both hosts to it — assumes Claude Code
   ignores Cursor's keys, not verified; (b) commit a generated `.mdc` and a test that fails when
   it drifts from the template; (c) a `tools/self-host.sh` that regenerates it. (a) keeps one
   source if the assumption holds.
2. **What part of the Manifesto seeds a target's agent file.** The whole essay, a derived
   excerpt, or a pointer. And how that squares with the reason `test_orient.sh:370` gives for not
   shipping `orientation.md`. Also whether the seed overlaps `templates/process-rules.md`, which
   already ships the process rules; two copies of one rule is the drift this toolkit argues
   against.
3. **Whether phase `d` stays in this brief.** It changes every adopter's install, which is a
   larger blast radius than the rest.
4. **One agent file or two.** A real `AGENTS.md` with `CLAUDE.md` as a link, or two files.
   Whether Claude Code reads `AGENTS.md` natively is not verified.

## Non-goals

- **Not reclassifying `blc-orient` as a process skill.** The stash on
  `brief/orient-is-a-process-skill` is withdrawn. It solved this repository's problem by changing
  every adopter's install.
- **Not lifting the self-install guard.**
- **Not changing machine mode's roster.** `--machine` still links `PROCESS_SKILLS` only.

## Success criteria

- A fresh clone, opened in either host, loads all 11 skills with no machine step and no hand
  links.
- Process rules and `no-cq-leak` bind both hosts in this repository.
- A test fails when a skill reaches one host's self-hosted tree and not the other's.
- `tools/orient.sh` in this repository reports self-hosting, not a missing install.
- The four hand-placed links in `~/.claude` are deleted, and the ledger says so.
