# brief-ledger-chronicle

A process toolkit for work that needs a record: a **brief** (the claim going in), a
**ledger** (what the work taught), and a **chronicle** (the story written from those two
and from git). A **Contract** states, in the present tense, what a consumer of the briefs
convention may rely on.

[**Manifesto**](Manifesto.md) is the argument for this shape. You do not need it to install.

Works with **Claude Code** and **Cursor**. One set of source files serves both. Only the
install path differs, so a wording fix lands once.

## Install

```bash
# Claude Code (default) — once per machine, wires up ~/.claude
bash /path/to/brief-ledger-chronicle/install.sh --machine

# Then once per project:
bash /path/to/brief-ledger-chronicle/install.sh --target /path/to/my-project

# Cursor — per project; there is no machine-level step
bash /path/to/brief-ledger-chronicle/install.sh --host cursor --target /path/to/my-project
```

Add `--yes` to skip the confirmation prompt. Default is idempotent: re-running skips what
already exists. Add `--force` to replace installer-owned copies (skills, commands, process
rules, brief READMEs, settings) with this checkout. `AGENTS.md` / `CLAUDE.md`, numbered
briefs, ledgers, chronicles, and the install log are never replaced. `--force` is project
mode only.

The installer warns if the target is not a git repository. `validate-briefs.sh` still
runs there. `open-briefs.sh` does not: it reads git history.

**Skipping the machine step is the failure mode this repo learned the hard way.** Process
files degrade when user-level paths are missing — `init-briefs` hand-writes a README,
`create-brief` falls back to git config — so a machine can look configured and still be
unrunnable from clean.

## What lands where

| | Claude Code | Cursor |
|---|---|---|
| Process files | `.claude/commands/` (as `/slash` commands) | `.cursor/skills/` |
| Other skills | `.claude/skills/` | `.cursor/skills/` |
| Process contract | `.claude/rules/brief-ledger-chronicle.md` | `.cursor/rules/brief-ledger-chronicle.mdc` |
| Project architecture | `CLAUDE.md` (stub if absent, never overwritten) | `AGENTS.md` (same) |
| Permissions | `.claude/settings.local.json` | — |
| Machine-level | `~/.claude/` symlinks | — |

Both hosts also get `docs/briefs/` (with `_drafts/`), `docs/chronicles/`,
`docs/contracts/`, `docs/install-log/install-log.md`, and `tools/`.

The six process files are the same document either way. Cursor has no slash-command
concept, so it reads them as ordinary skills. Shared YAML frontmatter is valid in both
places, which is what makes a single source possible.

## What it installs

**Process** — the workflow itself:

| | Purpose |
|---|---|
| `commit-push-pr` | Stage → review gate → commit → push → open PR |
| `review-pr` | Review a diff or PR against the governing brief and project rules |
| `create-brief` | File a draft into `docs/briefs/NNNN-slug/` |
| `start-brief` | Plan phases, write the ledger, branch the first phase |
| `next-brief-phase` | Continue a multi-phase brief, re-planning from what finished phases taught |
| `init-briefs` | One-time idempotent `docs/briefs/` scaffold |

**Skills** — useful alongside it:

| | Purpose |
|---|---|
| `chronicle` | Narrative history from briefs, ledgers, and git |
| `ste-writing` | ASD-STE100 prose pass; default for process prose |
| `to-do` | Append timestamped notes to `docs/to-dos/todo.md` |
| `installer-builder` | Package a file set into a distributable `.tgz` |

**Templates** — the process-rules contract (installed as a host rules file), a stub
`CLAUDE.md` / `AGENTS.md` written only when absent, and a starter permission allowlist.

**Shipped documents** — this repository's own `docs/briefs/README.md`, the briefs Contract
(`docs/contracts/`, currently v1.1), and the tools those docs name:

| | Purpose |
|---|---|
| `tools/validate-briefs.sh` | Checks Contract clauses BRIEFS-1 through BRIEFS-8 |
| `tools/open-briefs.sh` | Reports which briefs are open, and how far `main` has moved |

Copied verbatim rather than templated, so a target reads and checks the same convention
this repository does.

Skills are markdown prompts. The two `tools/` scripts are programs. The test suite covers
the programs and the installer. It does not exercise what a skill instructs an agent to do.

## How the process works

1. **Author a brief** in `docs/briefs/_drafts/` — unnumbered. Drafts are committed to git.
   Filing, not committing, is the decision to do the work.
2. **File it** with `create-brief`, which assigns the serial. This is the one-way door.
3. **Execute** with `start-brief`. Continue with `next-brief-phase`, which re-plans the
   remaining sequence from what the finished phases taught.
4. **Every commit to `main`** goes through `commit-push-pr`, which runs `review-pr` as a
   gate before anything is committed.
5. **`open-briefs.sh`** lists `in-progress` and `deferred` phases. It reports. It does not
   gate. Nothing invokes it on a cadence yet — run it when you want to know what is open.
6. **`chronicle`** renders the record into prose when you want the story.

The brief is the claim you start with. The ledger is what the work taught, including where
the brief was wrong. A specification, if the work needs one, gets written from that record
afterwards. See the [Manifesto](Manifesto.md).

Ledger status uses one vocabulary at both levels: `pending`, `in-progress`, `deferred`,
`done`, `skipped`. Defined in `docs/briefs/README.md`.

The installer never files a brief. `create-brief` is the single point of serial assignment.
Anything else writing a `NNNN-slug/` folder bypasses both its allocation and its collision
guard — see "Known limitation — writers outside the pipeline" in `docs/briefs/README.md`.

See `docs/briefs/README.md` for the convention. See `docs/contracts/v1.1.md` for the
structural invariants.

## Requirements

`git` and `gh` (GitHub CLI). Claude Code installs also expect `node`, `npm`, and the
`claude` CLI. The installer checks and tells you what is missing before writing anything.

## Tests

```bash
bash tests/run.sh              # everything
bash tests/run.sh host_        # just the host-layout tests
```

Covers the installer (arguments, both hosts, `--force`, install log, machine-mode
symlinks), the briefs Contract, the open-briefs query, and `gather.sh`. Plain bash, no
dependencies. CI runs them on every push and pull request. See `tests/README.md`.

The count is not written here. `bash tests/run.sh` prints it.

## License

MIT — see [LICENSE](LICENSE).
