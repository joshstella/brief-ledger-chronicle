# brief-ledger-chronicle

**Install it into your project and be creative — the tools will document what happened.**

Brief, ledger, and chronicle keep your reasoning legible without ceremony. Nothing here is
mandatory scaffolding: write what's worth writing, skip what isn't, and the record
accumulates as a side effect of doing the work.

Works with **Claude Code** and **Cursor**. One set of source files serves both — only where
they land differs, so a wording fix lands once rather than twice.

## Install

```bash
# Claude Code (default) — once per machine, wires up ~/.claude
bash /path/to/brief-ledger-chronicle/install.sh --machine

# Then once per project:
bash /path/to/brief-ledger-chronicle/install.sh --target /path/to/my-project

# Cursor — per project; there is no machine-level step
bash /path/to/brief-ledger-chronicle/install.sh --host cursor --target /path/to/my-project
```

Add `--yes` to skip the confirmation prompt for scripted installs. Both modes are
idempotent: re-running skips what already exists and never overwrites anything, so
re-running to pick up upstream changes is safe.

**Skipping the machine step is the failure mode this repo learned the hard way.** The
process files degrade gracefully when their user-level paths are missing — `init-briefs`
hand-writes a README instead of copying the template, and `create-brief` falls back to git
config — so a machine can look configured while being unrunnable from clean.

## What lands where

| | Claude Code | Cursor |
|---|---|---|
| Process files | `.claude/commands/` (as `/slash` commands) | `.cursor/skills/` |
| Other skills | `.claude/skills/` | `.cursor/skills/` |
| Project rules | `CLAUDE.md` | `AGENTS.md` |
| Permissions | `.claude/settings.local.json` | — |
| Machine-level | `~/.claude/` symlinks | — |

Both hosts also get `docs/briefs/` (with `_drafts/`), `docs/chronicles/`, and
`docs/install-log/install-log.md`.

The six process files are the same document either way; Cursor has no slash-command
concept, so it reads them as ordinary skills. The shared YAML frontmatter is valid in both
places, which is what makes a single source possible.

## What it installs

**Process** — the workflow itself:

| | Purpose |
|---|---|
| `commit-push-pr` | Stage → review gate → commit → push → open PR |
| `review-pr` | Review a diff or PR against the governing brief and project rules |
| `create-brief` | File a draft into `docs/briefs/NNNN-slug/` |
| `start-brief` | Initiate a brief: plan phases, write ledger, branch the first phase |
| `next-brief-phase` | Continue a multi-phase brief, re-planning from what it taught |
| `init-briefs` | One-time idempotent `docs/briefs/` scaffold |

**Skills** — useful alongside it:

| | Purpose |
|---|---|
| `chronicle` | Narrative history from briefs, ledgers, and git |
| `ste-writing` | ASD-STE100 prose pass, wired into commit messages and PR bodies |
| `to-do` | Append timestamped notes to `docs/to-dos/todo.md` |
| `installer-builder` | Package a file set into a distributable `.tgz` |

**Templates** — `CLAUDE.md` / `AGENTS.md` project rules, the brief-convention README, and a
starter permission allowlist.

## How the process works

1. **Author a brief** in `docs/briefs/_drafts/` — unnumbered, and free to sit indefinitely.
2. **File it** with `create-brief`, which assigns the serial. This is the one-way door.
3. **Execute** with `start-brief`; continue with `next-brief-phase`.
4. **Every commit to `main`** goes through `commit-push-pr`, which runs `review-pr` as a
   gate *before* anything is committed.
5. **`chronicle`** renders the record into prose whenever you want the story.

The installer never files a brief. `create-brief` is the single point of serial assignment,
so anything else writing a `NNNN-slug/` folder would bypass both its allocation and its
collision guard — see "Known limitations" in `docs/briefs/README.md`.

See `docs/briefs/README.md` for the full convention and its structural invariants.

## Requirements

`git` and `gh` (GitHub CLI). Claude Code installs also expect `node`, `npm`, and the
`claude` CLI. The installer checks and tells you what is missing before writing anything.

## Tests

```bash
bash tests/run.sh              # everything
bash tests/run.sh host_        # just the host-layout tests
```

50 tests covering argument handling, both host layouts, project install, the install log,
and machine-mode symlinking. Plain bash, no dependencies. CI runs them on every push and
pull request. See `tests/README.md` — including why the suite is validated by breaking
`install.sh` on purpose rather than by going green.

## License

MIT — see [LICENSE](LICENSE).
