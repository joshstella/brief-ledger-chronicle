# brief-ledger-chronicle

**Install it into your project and be creative — the tools will document what happened.**

Brief, ledger, and chronicle keep your reasoning legible without ceremony. Nothing here is
mandatory scaffolding: write what's worth writing, skip what isn't, and the record
accumulates as a side effect of doing the work.

Bootstraps the brief/ledger/review workflow into any project using **Cursor** (skills under
`.cursor/skills/`). Clone this repo once per machine; run `install.sh` in each project you
want to onboard.

## What it installs

**Skills** (`.cursor/skills/`) — invoked when the agent reads skill descriptions or when you
name the workflow:

| Skill | Purpose |
|-------|---------|
| `commit-push-pr` | Stage → review gate → commit → push → open PR |
| `review-pr` | Review a diff or PR against the governing brief and AGENTS.md |
| `create-brief` | File a draft into `docs/briefs/NNNN-slug/` |
| `start-brief` | Initiate a brief: plan phases, write ledger, branch first phase |
| `next-brief-phase` | Continue a multi-phase brief |
| `init-briefs` | One-time idempotent `docs/briefs/` scaffold |
| `chronicle` | Narrative history from briefs, ledgers, and git |
| `ste-writing` | ASD-STE100 prose lint for commits and PRs |
| `to-do` | Append timestamped notes to `docs/to-dos/todo.md` |
| `installer-builder` | Package skills into a distributable `.tgz` |

**Templates:**

- `AGENTS.md` — generic project process rules (edit the project-specific section)
- `docs/briefs/README.md` — brief convention and structural invariants

## Requirements

- `git`
- `gh` (GitHub CLI)

The installer checks for these and tells you what to install if anything is missing.

## Usage

```bash
# In the repo you want to onboard:
bash /path/to/brief-ledger-chronicle/install.sh

# Or with --target if you're running from elsewhere:
bash install.sh --target /path/to/my-project
```

The installer is idempotent — re-running skips files that already exist and never overwrites.

After install, the target project has:

- `docs/briefs/` with README and `_drafts/`
- `docs/chronicles/`
- `.cursor/skills/` with all workflow skills
- `AGENTS.md` (if not already present)
- `docs/briefs/0001-bootstrap/` recording what was installed and when

## How the process works

1. **Author a brief** in `docs/briefs/_drafts/`.
2. **File it** with the `create-brief` skill — assigns serial `NNNN`.
3. **Execute** with `start-brief`; continue with `next-brief-phase`.
4. **Every commit to `main`** goes through `commit-push-pr`, which runs `review-pr` as a
   gate before anything is committed.
5. **`chronicle`** renders brief/ledger history into prose when you want the story.

See `docs/briefs/README.md` for the full brief convention.

## This repo's own record

`docs/briefs/0001-bootstrap/` documents the creation of this repo.

## Relation to claude-process-automation

This repo is the Cursor-native successor to
[claude-process-automation](https://github.com/joshstella/claude-process-automation). The
brief/ledger/chronicle convention is unchanged; only the install target and agent wiring
differ (`.cursor/skills/` + `AGENTS.md` instead of `.claude/` + `CLAUDE.md`).

## License

MIT — see [LICENSE](LICENSE).
