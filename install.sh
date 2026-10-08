#!/usr/bin/env bash
# brief-ledger-chronicle installer
# Two modes:
#   project (default) — bootstraps the brief/ledger/review workflow into a target project
#   --machine         — links the once-per-machine user-level config into ~/.claude
# Usage: bash install.sh [--host claude|cursor] [--target <path>] [--yes]
#        bash install.sh --machine
#
# One source, two hosts. Every skill under skills/ is host-neutral prose; only where the
# files land differs. Cursor reads everything from `.cursor/skills/`; Claude Code splits
# them, taking the process skills as slash-commands under `.claude/commands/` and the
# rest as skills. Nothing is duplicated per host, so a wording fix lands once.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=""
MODE="project"
HOST="claude"
ASSUME_YES=false
# Initialized like every other flag. Left unset with a `${VAR:-false}` reader it
# would be settable from the caller's environment, which turns an install into a
# silent no-op that exits 0 and skips the self-install guard.
PRINT_OWNERSHIP=false
PRINT_PROCESS_RULES=false

# The skills that drive the workflow. Claude Code installs these as slash-commands so
# they can be invoked explicitly as `/name`; Cursor has no such concept and takes them as
# ordinary skills. Everything else in skills/ installs as a skill on both hosts.
#
# Three test files write these names out by hand again and nothing derives them, so a
# name added here has to be added there too. #0032 added the seventh and recorded the
# duplication rather than removing it. A fourth copy held only the count and is now read
# back out of this line, which is why the quoting here is load-bearing: see
# `tests/test_project_mode.sh`.
PROCESS_SKILLS="blc-close-brief blc-commit-push-pr blc-create-brief blc-create-draft blc-init-briefs blc-next-brief-phase blc-review-pr blc-start-brief"

is_process_skill() {
  case " $PROCESS_SKILLS " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# Machine-mode destination. Overridable so the machine install is testable without
# writing to the real ~/.claude.
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

# ── Parse args ────────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --host)
      HOST="$2"
      shift 2
      ;;
    --machine)
      MODE="machine"
      shift
      ;;
    --yes|-y)
      ASSUME_YES=true
      shift
      ;;
    --force|-f)
      echo "error: --force was retired in #0012. Toolkit-owned paths are replaced on every run." >&2
      echo "  Project-owned files (AGENTS.md, numbered briefs, ledgers) are still never touched." >&2
      exit 1
      ;;
    --print-ownership)
      PRINT_OWNERSHIP=true
      shift
      ;;
    --print-process-rules)
      PRINT_PROCESS_RULES=true
      shift
      ;;
    --help|-h)
      echo "Usage: bash install.sh [--host claude|cursor] [--target <path>] [--yes]"
      echo "       bash install.sh --machine"
      echo ""
      echo "  --host <name>     Agent host to install for: claude (default) or cursor."
      echo "                    claude → .claude/commands + .claude/skills + .claude/rules"
      echo "                    cursor → .cursor/skills + .cursor/rules"
      echo "  --target <path>   Install the process into <path> instead of current directory"
      echo "  --yes, -y         Skip the confirmation prompt (for scripted installs)"
      echo "  --machine         Install the once-per-machine user-level config into"
      echo "                    \$CLAUDE_HOME (default ~/.claude). Run once per machine,"
      echo "                    before or after any project install. Claude Code only."
      echo "  --print-ownership Print what this installer owns and what it will never"
      echo "                    write, for the chosen host, and exit. Touches nothing."
      echo "  --print-process-rules"
      echo "                    Print the process rules file this installer would write"
      echo "                    for the chosen host, and exit. Touches nothing."
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "$HOST" != "claude" && "$HOST" != "cursor" ]]; then
  echo "error: unknown host '$HOST'. Expected 'claude' or 'cursor'." >&2
  exit 1
fi

if [[ "$MODE" == "machine" && -n "$TARGET_DIR" ]]; then
  echo "error: --machine and --target are mutually exclusive." >&2
  echo "  --machine writes to \$CLAUDE_HOME (default ~/.claude); --target writes to a project." >&2
  exit 1
fi

# Machine mode links Claude Code's user-level config. Cursor has no equivalent user-level
# surface here, so rather than silently ignoring --host cursor, say so.
if [[ "$MODE" == "machine" && "$HOST" == "cursor" ]]; then
  echo "error: --machine is Claude Code only; there is no Cursor user-level install." >&2
  echo "  Run 'bash install.sh --host cursor --target <path>' per project instead." >&2
  exit 1
fi

if [[ -z "$TARGET_DIR" ]]; then
  TARGET_DIR="$(pwd)"
fi

# Guard: refuse to install into the repo itself — it's the source, not a target.
# Machine mode is exempt: it writes to $CLAUDE_HOME, never into a project. So is
# --print-ownership and --print-process-rules, which have no target at all: each reports what
# the installer would write for a given host and writes nothing, and refusing them here would
# make both unreadable from the one checkout that always has them.
if [[ "$MODE" == "project" && "$PRINT_OWNERSHIP" != true && "$PRINT_PROCESS_RULES" != true && "$TARGET_DIR" -ef "$SCRIPT_DIR" ]]; then
  echo "error: cannot install into brief-ledger-chronicle itself." >&2
  echo "  This repo is the source of the process, not a target for it." >&2
  echo "  Use --target <path> to install into another project." >&2
  exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

CREATED=()
SKIPPED=()
REPLACED=()
REMOVED=()
CONFLICTS=()
MOVED=()
DROPPED=()

log_created() { CREATED+=("$1"); echo "  [+] $1"; }
log_skipped() { SKIPPED+=("$1"); echo "  [~] $1 (already exists, skipped)"; }
log_replaced() { REPLACED+=("$1"); echo "  [>] $1 (replaced)"; }
log_relinked() { CREATED+=("$1 (replaced dangling symlink)"); echo "  [+] $1 (replaced dangling symlink)"; }
# Skip with an explicit reason, for cases where "already exists" is the wrong wording.
log_skipped_as() { SKIPPED+=("$1 ($2)"); echo "  [~] $1 ($2)"; }
log_conflict() { SKIPPED+=("$1"); echo "  [!] $1 ($2 — NOT replaced; see below)"; }
log_removed() { REMOVED+=("$1"); echo "  [-] $1 (removed — no longer shipped)"; }
log_moved() { MOVED+=("$1 → $2"); echo "  [→] $1 → $2"; }
log_dropped() { DROPPED+=("$1"); echo "  [-] $1 (old copy of a toolkit file — dropped, replaced below)"; }

# Toolkit-owned files are replaced every run. Project-owned paths never reach here.
place_file() {
  local src="$1" dst="$2" label="$3"
  if [[ -f "$dst" ]]; then
    cp "$src" "$dst"
    log_replaced "$label"
  else
    cp "$src" "$dst"
    log_created "$label"
  fi
}

# Toolkit-owned trees are replaced every run. Anything a project added inside a skill
# directory is lost — that is the trade #0012 makes deliberately.
place_dir() {
  local src="$1" dst="$2" label="$3"
  if [[ -e "$dst" ]]; then
    rm -rf "$dst"
    cp -r "$src" "$dst"
    log_replaced "$label"
  else
    cp -r "$src" "$dst"
    log_created "$label"
  fi
}

# AGENTS.md / CLAUDE.md are project-owned. Write a stub only when the file is
# absent. Never replace.
#
# The stub seeds no prose, because three files share this job and only one of them
# belongs to a project's agents. Process rules are $PROCESS_RULES_REL, which the
# installer owns and rewrites. What a project values is docs/blc/orientation.md,
# which the project authors and an install must never write — see
# test_orient_authored_file_does_not_ship_to_a_target. That leaves architecture,
# stack, build commands and the test-coverage definition, which are facts about one
# project that no installer can know. So the stub asks instead of answering (#0022).
write_project_stub() {
  local dst="$TARGET_DIR/$RULES_FILE"

  # An adopter who ran an older install, or who wrote one by hand, has a real CLAUDE.md and
  # no AGENTS.md. Writing AGENTS.md beside it would create the second agent file this phase
  # exists to remove, and the project would own both. Their file is the agent file. Leave it.
  if [[ -n "$RULES_COMPAT_FILE" && ! -e "$dst" && -f "$TARGET_DIR/$RULES_COMPAT_FILE" \
        && ! -L "$TARGET_DIR/$RULES_COMPAT_FILE" ]]; then
    log_skipped_as "$RULES_COMPAT_FILE" "the project's agent file, kept in place of $RULES_FILE"
    return
  fi

  if [[ -f "$dst" ]]; then
    log_skipped "$RULES_FILE"
    link_rules_compat
    return
  fi
  cat > "$dst" <<EOF
# $RULES_FILE

This file belongs to this project. brief-ledger-chronicle wrote it once, because it was
absent, and will not write it again.

The installer could not answer the questions below. It does not know this project.

## The rest of the record

Two other files carry what this one does not, and neither is a place for architecture.

- The process rules — how work reaches \`main\`. The installer owns them and rewrites them
  on every run. Do not edit them here. Cursor reads
  \`.cursor/rules/brief-ledger-chronicle.mdc\`; Claude Code reads
  \`.claude/rules/brief-ledger-chronicle.md\`. Both are named because this file is written
  once, and a project may add the second host later.
- \`docs/blc/orientation.md\` — what this project values, in its own words. Nothing seeds
  it. Until somebody writes it, \`tools/orient.sh\` reports that it is missing.

## Answer these, then delete the questions

- What is this project? What does it produce, and for whom?
- How is it built, run, and tested? Give the commands, not a description of them.
- What does "covered" mean here? Name what a test must exercise before a change is done.
- What must not break? Name the behaviour, not the file.
- What is generated, vendored, or otherwise not edited by hand?
EOF
  log_created "$RULES_FILE"
  link_rules_compat
}

# Claude Code reads AGENTS.md natively only from v2.1.277, and only when no CLAUDE.md is
# present. A relative link keeps one text for both hosts on every version. It is relative,
# not absolute, so the pair survives a clone to any path.
link_rules_compat() {
  [[ -n "$RULES_COMPAT_FILE" ]] || return 0
  local compat="$TARGET_DIR/$RULES_COMPAT_FILE"
  # -L as well as -e, because -e is false for a dangling link and a dangling CLAUDE.md is
  # still the project's to fix. This installer does not replace what a project owns.
  if [[ -L "$compat" || -e "$compat" ]]; then
    log_skipped "$RULES_COMPAT_FILE"
    return
  fi
  ln -s "$RULES_FILE" "$compat"
  log_created "$RULES_COMPAT_FILE"
}

# One process-rules.md body, two destinations. Cursor needs YAML frontmatter so
# the rule always applies; Claude Code loads .claude/rules/*.md with no paths
# field the same way.
#
# The body is printed rather than written straight to the destination, so that
# `--print-process-rules` can hand the same bytes to a caller. This repository's own
# committed Cursor file is checked against those bytes instead of against a second copy of
# the frontmatter (#0019 phase `c`).
print_process_rules() {
  if [[ "$HOST" == "cursor" ]]; then
    printf '%s\n' '---'
    printf '%s\n' 'description: brief-ledger-chronicle process — skills are the gates, STE writing, tests gate main'
    printf '%s\n' 'alwaysApply: true'
    printf '%s\n' '---'
    printf '\n'
  fi
  cat "$SCRIPT_DIR/templates/process-rules.md"
}

place_process_rules() {
  local dst label tmp
  mkdir -p "$(dirname "$TARGET_DIR/$PROCESS_RULES_REL")"
  if [[ "$HOST" == "cursor" ]]; then
    dst="$TARGET_DIR/$PROCESS_RULES_REL"
    label="$PROCESS_RULES_REL"
    tmp="$(mktemp)"
    print_process_rules > "$tmp"
    place_file "$tmp" "$dst" "$label"
    rm -f "$tmp"
  else
    place_file "$SCRIPT_DIR/templates/process-rules.md" \
               "$TARGET_DIR/$PROCESS_RULES_REL" \
               "$PROCESS_RULES_REL"
  fi
}

# Symlink $2 → $1, idempotently, without ever destroying real user content.
#
# Four cases, because the machine install runs against a $HOME that may already hold
# a hand-rolled config. Only two of them may write:
#   nothing there            → create the link
#   link already correct     → skip (this is what a re-run hits)
#   dangling link            → replace it. Safe by construction: it resolves to nothing,
#                              so it cannot be content anyone would lose. This is the
#                              case a machine whose previous config repo was deleted
#                              lands in, and the reason this installer exists.
#   real file / dir / other  → refuse and report. Never clobber authored config.
link_into_place() {
  local src="$1" dst="$2" label="$3"

  if [[ -L "$dst" ]]; then
    if [[ "$dst" -ef "$src" ]]; then
      log_skipped_as "$label" "already linked correctly"
    elif [[ ! -e "$dst" ]]; then
      rm "$dst"
      ln -s "$src" "$dst"
      log_relinked "$label"
    else
      # A symlink pointing at something real but not ours — someone else's config.
      log_conflict "$label" "links to $(readlink "$dst")"
      CONFLICTS+=("$label is a symlink to $(readlink "$dst")")
    fi
    return
  fi

  if [[ -e "$dst" ]]; then
    log_conflict "$label" "real file present"
    CONFLICTS+=("$label already exists as a real file or directory")
    return
  fi

  # Parent created here, at the point of writing, so a run that conflicts on every
  # link leaves no directories behind in the user's config.
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  log_created "$label"
}

install_hint() {
  local dep="$1"
  case "$dep" in
    git)    echo "    macOS: brew install git  |  Linux: sudo apt install git" ;;
    gh)     echo "    GitHub — macOS: brew install gh    |  Linux: https://cli.github.com/manual/installation" ;;
    glab)   echo "    GitLab — macOS: brew install glab  |  Linux: https://gitlab.com/gitlab-org/cli#installation" ;;
    node)   echo "    macOS: brew install node |  Linux: https://nodejs.org/en/download" ;;
    npm)    echo "    Comes with Node.js — install node first" ;;
    claude) echo "    https://claude.ai/code — install the Claude Code CLI" ;;
  esac
}

# ── Host layout ───────────────────────────────────────────────────────────────
# Resolved before anything reads it, because the ownership map below is host-shaped:
# the same source file becomes a skill directory on one host and a flat command file
# on the other.

# The agent file is AGENTS.md on both hosts. Claude Code gets CLAUDE.md beside it as a
# link, because it reads AGENTS.md natively only from v2.1.277 and only when no CLAUDE.md
# exists. A project installed for both hosts used to get two files with the same text and
# nothing relating them, so an edit to one left the other stale (#0022 c).
RULES_FILE="AGENTS.md"
RULES_COMPAT_FILE=""

if [[ "$HOST" == "cursor" ]]; then
  SKILLS_DST_REL=".cursor/skills"
  PROCESS_RULES_REL=".cursor/rules/brief-ledger-chronicle.mdc"
else
  SKILLS_DST_REL=".claude/skills"
  COMMANDS_DST_REL=".claude/commands"
  RULES_COMPAT_FILE="CLAUDE.md"
  PROCESS_RULES_REL=".claude/rules/brief-ledger-chronicle.md"
fi

# ── The ownership map ─────────────────────────────────────────────────────────
#
# One declaration of what this installer owns and what it must never write. Every
# step below reads it: the preflight checks these sources, the placement steps ship
# these entries, and the log records them. Before this existed the same knowledge was
# spelled out in five places that had to be edited together and were not, which is how
# a rename shipped skills that landed beside their predecessors instead of replacing
# them.
#
# Emits tab-separated `owner<TAB>kind<TAB>source<TAB>destination`:
#
#   owner        toolkit — shipped by this installer, and therefore this installer's to replace
#                project — authored by the project; never written after creation
#                append  — added to, never rewritten, so neither of the above fits
#   kind         file | dir | tree
#   source       path under $SCRIPT_DIR, or `-` when nothing is shipped
#   destination  path under $TARGET_DIR
#
# A `file` entry beats an enclosing `tree` entry. `docs/blc/briefs/` is the project's, but
# `docs/blc/briefs/README.md` inside it is shipped — stated here once so no reader has to
# infer the precedence from path lengths.
#
# A `tree` row means the installer may *create* the directory and may never write inside
# it. Creating `docs/blc/chronicles/` and handing it over is not the same act as putting a
# file in it, and the two would be indistinguishable if creation were also disowned.
#
# What this map does NOT cover: the empty directories `SCAFFOLD_DIRS` makes so that
# placement has somewhere to land — `.cursor/`, `.cursor/rules/`, `.cursor/skills/`,
# `docs/`, `docs/blc/`, `docs/blc/contracts/`, `docs/blc/install-log/`, `tools/`, and the Claude
# equivalents.
# They hold nothing this installer authored, so replacing them is meaningless. Removing
# them is not, and a later phase that prunes will have to decide about an emptied
# `.cursor/skills/` on its own evidence. Stated here because a boundary nobody wrote down
# is one a prune will guess at. `ownership_map_names_every_path_an_install_writes` fails
# if this list stops matching what an install leaves behind.
#
# `append` is a third category because the two-column story does not survive contact
# with the code: this installer *does* write `.gitignore` and the install log, and calling
# them project-owned would describe them wrongly while calling them toolkit-owned would
# eventually let something replace them. Appending is its own posture and is named as one.
ownership_map() {
  local same skill_dir skill_name

  # Every Contract version in this repository, rather than a list of them. The versions
  # were named one per line up to v1.3. Publishing v1.4 added a file the list did not
  # name, so the new Contract would not have installed at all: a target would have kept
  # the superseded version while the briefs README it also ships linked to one that was
  # not there. Found by a test, not by reading this (#0033).
  local contract_versions="" v
  for v in "$SCRIPT_DIR"/docs/blc/contracts/v*.md; do
    contract_versions="$contract_versions docs/blc/contracts/${v##*/}"
  done

  # Shipped docs, the Contract, and the tools its clauses name. Source and destination
  # are the same path: these travel from this repository's own docs/, so a target lives
  # by the files this repository lives by rather than by a template copy that drifts.
  #
  # shellcheck disable=SC2086
  for same in \
    docs/blc/briefs/README.md \
    docs/blc/briefs/_drafts/README.md \
    docs/blc/contracts/README.md \
    $contract_versions \
    docs/blc/state/README.md \
    tools/validate-briefs.sh \
    tools/open-briefs.sh \
    tools/detect-forge.sh \
    tools/list-briefs.sh \
    tools/jira-csv.sh \
    tools/orient.sh \
    tools/stale-branches.sh \
    tools/check-architecture.sh \
    tools/lib/phase-row.sh \
    tools/lib/status-line.sh \
    tools/lib/identity-line.sh \
    tools/lib/touch-log.sh; do
    printf 'toolkit\tfile\t%s\t%s\n' "$same" "$same"
  done

  # The one file whose destination name is the host's, not ours — and the one row whose
  # source is not copied verbatim: on Cursor, place_process_rules prepends the YAML
  # frontmatter that makes the rule always-apply. A later phase that replaces toolkit rows
  # with a plain `cp $src $dst` would strip it and silently disable the rule.
  printf 'toolkit\tfile\ttemplates/process-rules.md\t%s\n' "$PROCESS_RULES_REL"

  if [[ "$HOST" == "claude" ]]; then
    printf 'toolkit\tfile\ttemplates/.claude/settings.local.json\t.claude/settings.local.json\n'
  fi

  # Skills, read from the source tree rather than listed. A hardcoded roster needs
  # editing at exactly the moment someone is adding or renaming a skill and thinking
  # about something else.
  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    if [[ "$HOST" == "claude" ]] && is_process_skill "$skill_name"; then
      printf 'toolkit\tfile\tskills/%s/SKILL.md\t%s/%s.md\n' \
        "$skill_name" "$COMMANDS_DST_REL" "$skill_name"
    else
      printf 'toolkit\tdir\tskills/%s\t%s/%s\n' \
        "$skill_name" "$SKILLS_DST_REL" "$skill_name"
    fi
  done

  # The project's own. Listed rather than left implicit so that "never written" is a
  # thing this file says, not a thing it fails to say — #0011's brief-checks/ attaches
  # here, and an absent entry would be indistinguishable from an oversight.
  printf 'project\tfile\t-\t%s\n' "$RULES_FILE"
  [[ -n "$RULES_COMPAT_FILE" ]] && printf 'project\tfile\t-\t%s\n' "$RULES_COMPAT_FILE"
  printf 'project\ttree\t-\tdocs/blc/briefs\n'
  printf 'project\ttree\t-\tdocs/blc/state\n'
  printf 'project\ttree\t-\tdocs/blc/chronicles\n'
  printf 'project\ttree\t-\tbrief-checks\n'

  printf 'append\tfile\t-\t.gitignore\n'
  printf 'append\tfile\t-\tdocs/blc/install-log/install-log.md\n'
}

# Rows for one owner. Callers filter further on the source column, which is stable and
# meaningful: everything under `skills/` is a skill however the host lays it out.
map_rows() { ownership_map | awk -F'\t' -v want="$1" '$1 == want'; }

# Skill names as the map sees them, whichever shape the host gave them: `skills/<name>`
# on Cursor, `skills/<name>/SKILL.md` on Claude. Split on `/` rather than matched with a
# regex so this stays identical under BSD and GNU awk.
map_skill_names() {
  map_rows toolkit | awk -F'\t' '$3 ~ /^skills\// { split($3, a, "/"); print a[2] }'
}

# Process skills on Claude become flat command files; everything else is a skill directory.
map_command_names() {
  map_rows toolkit | awk -F'\t' '$3 ~ /^skills\// && $2 == "file" {
    split($3, a, "/"); print a[2]
  }'
}

# Names under a log heading, unioned across every entry. The log is the only evidence of
# what this toolkit put here; a path it never named is never removed.
log_names_under_heading() {
  local log="$1" heading="$2"
  awk -v h="$heading" '
    $0 == h { on = 1; next }
    /^### / { on = 0 }
    on && /^  - / { sub(/^  - /, ""); print }
  ' "$log" | sort -u
}

refuse_symlinked_tree() {
  local rel="$1"
  if [[ -L "$TARGET_DIR/$rel" ]]; then
    echo "error: refusing to prune: $rel is a symlink" >&2
    echo "  Removing through a symlink would delete the link target, not a stale copy." >&2
    exit 1
  fi
}

safe_remove_toolkit_path() {
  local rel="$1"
  local abs="$TARGET_DIR/$rel"
  [[ -e "$abs" ]] || return 0
  if [[ -L "$abs" ]]; then
    echo "error: refusing to remove symlink: $rel" >&2
    exit 1
  fi
  rm -rf "$abs"
  log_removed "$rel"
}

# Stale is a name the log recorded and the current source no longer ships. Only skills
# and commands lists are read — not ### Created, which names scaffold dirs that must
# never be pruned.
prune_stale_toolkit_paths() {
  local log="$TARGET_DIR/docs/blc/install-log/install-log.md"
  if [[ ! -f "$log" ]]; then
    echo "  [~] no install log yet — stale skills and commands are not removed"
    return 0
  fi

  refuse_symlinked_tree "$SKILLS_DST_REL"
  # Commands always live under .claude/commands/, even when this run is for Cursor.
  # A target may hold a Claude-era log after a host change; pruning must reach that
  # tree without reading $COMMANDS_DST_REL, which is unset on Cursor hosts.
  refuse_symlinked_tree ".claude/commands"

  local logged_skills logged_cmds current_skills current_cmds name
  logged_skills="$(log_names_under_heading "$log" "### Skills installed")"
  logged_cmds="$(log_names_under_heading "$log" "### Commands installed")"
  current_skills="$(map_skill_names | sort -u)"
  current_cmds="$(map_command_names | sort -u)"

  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    [[ "$name" == \(* ]] && continue
    printf '%s\n' "$current_skills" | grep -qx -- "$name" && continue
    safe_remove_toolkit_path "$SKILLS_DST_REL/$name"
  done <<< "$logged_skills"

  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    [[ "$name" == \(* ]] && continue
    printf '%s\n' "$current_cmds" | grep -qx -- "$name" && continue
    safe_remove_toolkit_path ".claude/commands/$name.md"
  done <<< "$logged_cmds"
}

# Reading the map is how anything else can be held to it — the tests assert against this
# output rather than against a second copy of the list, and a person onboarding a project
# can ask what an install is about to take over before running one. Exits before the
# dependency check, because answering "what do you own" requires nothing to be installed.
if [[ "$PRINT_OWNERSHIP" == true ]]; then
  # The map describes a project install. Machine mode writes into $CLAUDE_HOME by symlink
  # and owns none of these paths, so printing this map under --machine would answer a
  # question nobody asked, quietly and with exit 0. Refused rather than extended: what
  # machine mode owns is a real question, and it deserves its own map rather than being
  # smuggled into this one.
  if [[ "$MODE" == "machine" ]]; then
    echo "error: --print-ownership describes a project install; --machine owns no project paths." >&2
    echo "  Drop --machine to see what an install into a target would own." >&2
    exit 1
  fi
  ownership_map
  exit 0
fi

# Same contract as --print-ownership: no target, nothing written, answerable before any
# install exists. Machine mode is refused for the same reason as there — it places no rules
# file, so printing one would answer about a project install instead.
if [[ "$PRINT_PROCESS_RULES" == true ]]; then
  if [[ "$MODE" == "machine" ]]; then
    echo "error: --print-process-rules describes a project install; --machine writes no rules file." >&2
    echo "  Drop --machine to see the rules file an install into a target would write." >&2
    exit 1
  fi
  print_process_rules
  exit 0
fi

# ── Step 1: Dependency check ──────────────────────────────────────────────────
#
# Project mode only. Machine mode creates symlinks and needs nothing but coreutils,
# and it is documented as the *first* step on a new machine — gating it on the full
# project toolchain would block the one step that fixes a clean machine.

echo ""
echo "brief-ledger-chronicle installer"
echo "===================================="

if [[ "$MODE" == "project" ]]; then
echo ""
echo "Checking dependencies..."

MISSING=()
for dep in git FORGE node npm claude; do
  # Either forge CLI will do: the skills ask tools/detect-forge.sh which one the remote
  # needs, so requiring gh would refuse every GitLab project.
  if [[ "$dep" == FORGE ]]; then
    if command -v gh &>/dev/null || command -v glab &>/dev/null; then
      for cli in gh glab; do
        command -v "$cli" &>/dev/null && echo "  [✓] $cli"
      done
    else
      echo "  [✗] gh or glab — neither found"
      install_hint gh
      install_hint glab
      MISSING+=("gh or glab")
    fi
  elif command -v "$dep" &>/dev/null; then
    echo "  [✓] $dep"
  else
    echo "  [✗] $dep — not found"
    install_hint "$dep"
    MISSING+=("$dep")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  echo "Install the missing dependencies above, then re-run this script."
  exit 1
fi
fi

# ── Machine mode ──────────────────────────────────────────────────────────────
# The once-per-machine half of the install. Everything below this block is
# per-project and never touches $HOME.
#
# Why this mode exists: the commands reference user-level paths that no per-project
# install creates — `/blc-init-briefs` reads the brief README template from
# $CLAUDE_HOME/briefs/, and Claude Code reads the personal working agreement from
# $CLAUDE_HOME/CLAUDE.md. Without this step those resolve to nothing, and because the
# commands degrade gracefully rather than erroring, a machine can look configured while
# being unrunnable from clean. That is exactly the failure this mode closes.
#
# Symlinks, not copies: the repo is the single source of truth, so `git pull` updates
# every machine-level artifact at once. The tradeoff is that a pull changes your
# commands immediately, including mid-session — deliberate, and the reason a project
# install still copies rather than links (a project pins what it was onboarded with).
#
# Skills are not linked here. They install per-project, and each project run replaces
# toolkit-owned paths with whatever this checkout ships — local edits do not survive.
# Machine mode only links the slash-commands and personal CLAUDE.md; a machine-wide
# skills link would override every target on `git pull` with no per-project boundary.

if [[ "$MODE" == "machine" ]]; then
  echo ""
  echo "Checking machine-mode sources..."

  MISSING_SOURCES=()
  for src in "personal/CLAUDE.md" "skills" "docs/blc/briefs/README.md"; do
    if [[ ! -e "$SCRIPT_DIR/$src" ]]; then
      echo "  [✗] $src — missing"
      MISSING_SOURCES+=("$src")
    else
      echo "  [✓] $src"
    fi
  done

  if [[ ${#MISSING_SOURCES[@]} -gt 0 ]]; then
    echo ""
    echo "error: this brief-ledger-chronicle checkout is incomplete." >&2
    echo "  Nothing was written. Restore the files above and re-run." >&2
    exit 1
  fi

  echo ""
  echo "Machine config directory: $CLAUDE_HOME"
  echo ""
  echo "This will link (never copy, never overwrite real files):"
  echo "  $CLAUDE_HOME/CLAUDE.md                  → personal/CLAUDE.md"
  for s in $PROCESS_SKILLS; do
    echo "  $CLAUDE_HOME/commands/$s.md → skills/$s/SKILL.md"
  done
  echo "  $CLAUDE_HOME/briefs/README.template.md  → docs/blc/briefs/README.md"
  echo ""
  echo "Other skills are NOT linked — they install per-project via --target."
  echo ""
  if [[ "$ASSUME_YES" != true ]]; then
    read -r -p "Proceed? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "Aborted."
      exit 0
    fi
  fi

  echo ""
  echo "Linking..."
  echo ""

  link_into_place "$SCRIPT_DIR/personal/CLAUDE.md" \
                  "$CLAUDE_HOME/CLAUDE.md" \
                  "CLAUDE.md"

  # One link per process skill rather than one for the whole directory: the single source
  # tree stores these as skills/<name>/SKILL.md, but Claude Code wants commands/<name>.md,
  # so the shapes no longer match. Linking each file keeps the property machine mode exists
  # for — `git pull` updates every machine at once — which copying would throw away.
  for s in $PROCESS_SKILLS; do
    link_into_place "$SCRIPT_DIR/skills/$s/SKILL.md" \
                    "$CLAUDE_HOME/commands/$s.md" \
                    "commands/$s.md"
  done

  link_into_place "$SCRIPT_DIR/docs/blc/briefs/README.md" \
                  "$CLAUDE_HOME/briefs/README.template.md" \
                  "briefs/README.template.md"

  echo ""
  echo "Done."
  echo ""
  echo "Linked (${#CREATED[@]}):"
  for item in ${CREATED[@]+"${CREATED[@]}"}; do echo "  $item"; done

  if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo ""
    echo "Skipped (${#SKIPPED[@]}):"
    for item in ${SKIPPED[@]+"${SKIPPED[@]}"}; do echo "  $item"; done
  fi

  if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
    echo ""
    echo "Conflicts — resolve by hand (${#CONFLICTS[@]}):"
    for item in ${CONFLICTS[@]+"${CONFLICTS[@]}"}; do echo "  - $item"; done
    echo ""
    echo "  Nothing was overwritten. Move or delete the file above, then re-run"
    echo "  --machine to link it. If it holds config you want to keep, merge it into"
    echo "  $SCRIPT_DIR/personal/CLAUDE.md first so the repo stays the source of truth."
  fi

  echo ""
  echo "Next steps:"
  echo "  1. Onboard a project:  bash $0 --target /path/to/project"
  echo "  2. Machine-level config now tracks this repo — 'git pull' updates it everywhere."
  echo ""
  exit 0
fi

# ── Step 2: Template preflight ────────────────────────────────────────────────
# Every file the install copies must exist before the target is touched. Without
# this, a template missing from the checkout aborts mid-run under `set -e` and
# leaves the target half-installed — skills and commands copied, bootstrap brief
# never written, and no summary saying so.

echo ""
echo "Checking install sources..."

MISSING_TEMPLATES=()

# Checked before the skills glob so a missing tree is reported as one missing thing
# rather than as silence — the map's skill loop simply yields nothing without it.
if [[ ! -d "$SCRIPT_DIR/skills" ]]; then
  echo "  [✗] skills — missing"
  MISSING_TEMPLATES+=("skills")
fi

# Every toolkit source the map names, checked in the shape it will be shipped in. A
# directory entry must also carry its SKILL.md: an empty skill directory copies without
# error and leaves the host offering a skill that says nothing.
while IFS=$'\t' read -r _owner kind src _dst; do
  [[ "$src" != "-" ]] || continue
  case "$kind" in
    file)
      if [[ ! -f "$SCRIPT_DIR/$src" ]]; then
        echo "  [✗] $src — missing"
        MISSING_TEMPLATES+=("$src")
      fi
      ;;
    dir)
      if [[ ! -d "$SCRIPT_DIR/$src" ]]; then
        echo "  [✗] $src — missing"
        MISSING_TEMPLATES+=("$src")
      elif [[ ! -f "$SCRIPT_DIR/$src/SKILL.md" ]]; then
        echo "  [✗] $src/SKILL.md — missing"
        MISSING_TEMPLATES+=("$src/SKILL.md")
      fi
      ;;
  esac
done < <(map_rows toolkit)

# The map is built by globbing the source tree, so a process skill missing from skills/
# produces no row — and a check derived from the map cannot notice what the map never
# mentions. PROCESS_SKILLS is the roster each host is promised, so it is asserted against
# the map rather than derived from it. Without this a Claude install ships five
# slash-commands, reports "Done.", and exits 0.
for s in $PROCESS_SKILLS; do
  if ! map_skill_names | grep -qx -- "$s"; then
    echo "  [✗] skills/$s/SKILL.md — missing"
    MISSING_TEMPLATES+=("skills/$s/SKILL.md")
  fi
done

if [[ ${#MISSING_TEMPLATES[@]} -gt 0 ]]; then
  echo ""
  echo "error: this brief-ledger-chronicle checkout is incomplete." >&2
  echo "  Nothing was written to the target. Restore the files above" >&2
  echo "  (git status / git checkout in $SCRIPT_DIR) and re-run." >&2
  exit 1
fi

echo "  [✓] all install sources present"

# ── Step 2b: The old layout ───────────────────────────────────────────────────
# Before #0017 an install wrote its trees straight under docs/. An upgrade moves them under
# docs/blc/. Everything that can stop the move is checked here, before the prompt, so a
# refused install has written nothing.
#
# Moving project trees breaks #0012's "never written after creation" once, on purpose: the
# move changes where the files are, not what they hold, and the install log names each one.

OLD_LAYOUT="briefs contracts chronicles state install-log orientation.md"
OLD_LOG="docs/install-log/install-log.md"

# Where an old-layout path lands. Every old path is docs/<x>; its new home is docs/blc/<x>.
new_layout_path() { printf 'docs/blc/%s\n' "${1#docs/}"; }

# The old names of the files the toolkit ships under docs/blc/. These are replaced by the
# install, so an old copy is dropped, not moved, and never counts as a clash.
old_toolkit_files() {
  map_rows toolkit | awk -F'\t' '$4 ~ /^docs\/blc\// { sub(/^docs\/blc\//, "docs/", $4); print $4 }'
}

OLD_ROOTS=()
for name in $OLD_LAYOUT; do
  if [[ -e "$TARGET_DIR/docs/$name" || -L "$TARGET_DIR/docs/$name" ]]; then
    OLD_ROOTS+=("docs/$name")
  fi
done

# A docs/blc/ the toolkit installed carries its install log. Without the log, anything in
# it is the project's own, and installing into it would mix two owners in one tree.
# One exception, and it is a move this installer did not finish. A populated docs/blc/ with no
# log in it, while the old-layout log is still at docs/install-log/install-log.md, can only come
# from an interrupted upgrade: a project's own docs/blc/ does not arrive with an old-layout
# install log beside it. Resuming is safe because every path below is checked again — a file
# that already moved is no longer at its old path, so it is neither moved twice nor a clash
# (#0023).
if [[ -d "$TARGET_DIR/docs/blc" && ! -f "$TARGET_DIR/docs/blc/install-log/install-log.md" ]] \
   && [[ -f "$TARGET_DIR/$OLD_LOG" ]] \
   && [[ -n "$(find "$TARGET_DIR/docs/blc" -mindepth 1 ! -type d -print -quit)" ]]; then
  # Said out loud because the run that left this state wrote no log, so this message is the
  # only account the person gets of why their half-moved tree was accepted.
  echo ""
  echo "Note: $TARGET_DIR/docs/blc/ holds files and no install log, and $OLD_LOG is still"
  echo "  in place. That is a move an earlier run started and did not finish. Resuming it."
fi

if [[ -d "$TARGET_DIR/docs/blc" && ! -f "$TARGET_DIR/docs/blc/install-log/install-log.md" ]] \
   && [[ ! -f "$TARGET_DIR/$OLD_LOG" ]] \
   && [[ -n "$(find "$TARGET_DIR/docs/blc" -mindepth 1 ! -type d -print -quit)" ]]; then
  echo ""
  echo "error: $TARGET_DIR/docs/blc/ holds files this toolkit did not install." >&2
  echo "  The toolkit keeps everything it uses under docs/blc/, and it has no install log there," >&2
  echo "  so these files belong to the project. Nothing was written to the target." >&2
  echo "  Move them out of docs/blc/, or empty it, and re-run." >&2
  exit 1
fi

OLD_MOVES=()
OLD_CLASHES=()
if [[ ${#OLD_ROOTS[@]} -gt 0 ]]; then
  OLD_TOOLKIT="$(old_toolkit_files)"
  for root in "${OLD_ROOTS[@]}"; do
    # A move through a symlink moves the link, not the tree it points at, and the project
    # would be left with a dangling name. Same refusal as the prune.
    if [[ -L "$TARGET_DIR/$root" ]]; then
      echo ""
      echo "error: $root is a symlink, so the installer cannot move it to docs/blc/." >&2
      echo "  Nothing was written to the target. Move it by hand and re-run." >&2
      exit 1
    fi
  done
  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    printf '%s\n' "$OLD_TOOLKIT" | grep -qxF -- "$rel" && continue
    # The two logs are joined, not moved, so both existing is the expected case.
    [[ "$rel" == "$OLD_LOG" ]] && { OLD_MOVES+=("$rel"); continue; }
    dst="$(new_layout_path "$rel")"
    if [[ -e "$TARGET_DIR/$dst" || -L "$TARGET_DIR/$dst" ]]; then
      OLD_CLASHES+=("$rel → $dst")
    else
      OLD_MOVES+=("$rel")
    fi
  done < <(for root in "${OLD_ROOTS[@]}"; do
             (cd "$TARGET_DIR" && find "$root" ! -type d)
           done | LC_ALL=C sort)

  # The log moves first, not fourth where sort order puts it. Everything above decides whether
  # a move can run; this decides what survives one that dies halfway. The log is the file that
  # marks docs/blc/ as the toolkit's, so a move that fails after it has to leave it in place or
  # the guard above refuses every later run and the upgrade is stuck for good (#0023).
  OLD_MOVES_ORDERED=()
  for rel in ${OLD_MOVES[@]+"${OLD_MOVES[@]}"}; do
    [[ "$rel" == "$OLD_LOG" ]] && OLD_MOVES_ORDERED+=("$rel")
  done
  for rel in ${OLD_MOVES[@]+"${OLD_MOVES[@]}"}; do
    [[ "$rel" == "$OLD_LOG" ]] || OLD_MOVES_ORDERED+=("$rel")
  done
  OLD_MOVES=(${OLD_MOVES_ORDERED[@]+"${OLD_MOVES_ORDERED[@]}"})
fi

if [[ ${#OLD_CLASHES[@]} -gt 0 ]]; then
  echo ""
  echo "error: these project files exist in both the old docs/ layout and docs/blc/:" >&2
  for item in "${OLD_CLASHES[@]}"; do echo "  $item" >&2; done
  echo "  The installer moves the old layout under docs/blc/ and will not choose between" >&2
  echo "  two copies. Nothing was written to the target. Keep one of each pair and re-run." >&2
  exit 1
fi

# ── Step 3: Target confirmation ───────────────────────────────────────────────

# Skill counts are only used for the summary below, and are computed here rather than
# beside the host layout because they read the source tree — which Step 2 has just
# finished proving is intact. Reading it earlier would fail on a broken checkout with a
# shell error instead of the preflight's report.
ALL_SKILL_COUNT="$(ls -d "$SCRIPT_DIR"/skills/*/ | wc -l | tr -d ' ')"
PROCESS_COUNT="$(echo $PROCESS_SKILLS | wc -w | tr -d ' ')"
UTILITY_COUNT=$((ALL_SKILL_COUNT - PROCESS_COUNT))

echo ""
echo "Target directory: $TARGET_DIR"
echo "Agent host:       $HOST"
echo ""
echo "This will create or update:"
echo "  $TARGET_DIR/docs/blc/briefs/       (brief/ledger structure)"
echo "  $TARGET_DIR/docs/blc/contracts/    (Contract v1.4 — the briefs convention)"
echo "  $TARGET_DIR/docs/blc/chronicles/   (chronicle.md; other files stay ignored)"
echo "  $TARGET_DIR/docs/blc/install-log/  (append-only record of every install)"
echo "  $TARGET_DIR/docs/blc/state/        (one declaration per contributor)"
echo "  $TARGET_DIR/tools/                 (validate-briefs.sh, open-briefs.sh, detect-forge.sh, list-briefs.sh, jira-csv.sh, orient.sh, stale-branches.sh, check-architecture.sh, lib/)"
if [[ "$HOST" == "cursor" ]]; then
  echo "  $TARGET_DIR/$SKILLS_DST_REL/       ($ALL_SKILL_COUNT skills)"
  echo "  $TARGET_DIR/$PROCESS_RULES_REL"
else
  echo "  $TARGET_DIR/$SKILLS_DST_REL/     ($UTILITY_COUNT skills)"
  echo "  $TARGET_DIR/$COMMANDS_DST_REL/   ($PROCESS_COUNT process commands)"
  echo "  $TARGET_DIR/$PROCESS_RULES_REL"
  echo "  $TARGET_DIR/.claude/settings.local.json  (permission allowlist)"
fi
echo "  $TARGET_DIR/$RULES_FILE           (questions for the project to answer — if absent, never replaced)"
echo ""
echo "Toolkit-owned paths above are replaced every run. Local edits to them do not survive."
echo "Project-owned files ($RULES_FILE, numbered briefs, ledgers, declarations, chronicles)"
echo "are never written after creation."

if [[ ${#OLD_ROOTS[@]} -gt 0 ]]; then
  echo ""
  echo "This target has the old layout. These project files move under docs/blc/:"
  for rel in ${OLD_MOVES[@]+"${OLD_MOVES[@]}"}; do
    if [[ "$rel" == "$OLD_LOG" ]]; then
      echo "  $rel → docs/blc/install-log/install-log.md (joined, old entries first)"
    else
      echo "  $rel → $(new_layout_path "$rel")"
    fi
  done
  echo "Old copies of the toolkit's own docs are dropped; this install replaces them."
fi

# open-briefs.sh reads git history, so a target outside a repository receives a
# documented tool that cannot run there — the briefs README tells the reader it reads
# their ledgers back, and it exits 2 instead. Said before the prompt rather than after
# the install, so the person can decide while the choice is still theirs.
#
# Warned, not refused. The briefs, the Contract and its validator all work without git,
# and a directory that is not a repository yet usually becomes one.
if ! git -C "$TARGET_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  echo ""
  echo "Note: $TARGET_DIR is not a git repository."
  echo "  tools/validate-briefs.sh works regardless. tools/open-briefs.sh does not —"
  echo "  it reads git history, and will report an error until this becomes a repo."
fi
echo ""

if [[ "$ASSUME_YES" != true ]]; then
  read -r -p "Proceed? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo ""
echo "Installing..."
echo ""

# ── Step 3a: Move the old layout ──────────────────────────────────────────────
# Step 2b proved every move has a free destination. Runs before the prune, because the
# prune reads the install log, and only the joined log holds the old installs' entries.

# The old entries come first so the log stays oldest-first. The new log's header is dropped:
# both logs start with the same header, and one file needs it once.
join_install_logs() {
  local old="$TARGET_DIR/$OLD_LOG" new="$TARGET_DIR/docs/blc/install-log/install-log.md"
  if [[ ! -f "$new" ]]; then
    mkdir -p "$(dirname "$new")"
    mv "$old" "$new"
    log_moved "$OLD_LOG" "docs/blc/install-log/install-log.md"
    return 0
  fi
  {
    cat "$old"
    echo ""
    awk 'found || /^## / { found = 1; print }' "$new"
  } > "$new.joining"
  mv "$new.joining" "$new"
  rm "$old"
  log_moved "$OLD_LOG" "docs/blc/install-log/install-log.md (joined, old entries first)"
}

if [[ ${#OLD_ROOTS[@]} -gt 0 ]]; then
  echo "Moving the old layout under docs/blc/..."
  for rel in ${OLD_MOVES[@]+"${OLD_MOVES[@]}"}; do
    if [[ "$rel" == "$OLD_LOG" ]]; then
      join_install_logs
      continue
    fi
    dst="$(new_layout_path "$rel")"
    mkdir -p "$TARGET_DIR/$(dirname "$dst")"
    # A tracked file moves with `git mv`, because `mv` is invisible to git. To git, a tracked
    # file moved with `mv` onto a path an ignore rule matches is a deletion and nothing else,
    # and the next `git add -A` removes it from the repository. The toolkit's own chronicles
    # rule is one such rule; a target's own .gitignore can hold others this installer cannot
    # know about. Git keeps tracking a file it moved, whatever the ignore rules say (#0020).
    #
    # This stages a rename in the target's index, which the installer did not do before.
    # Accepted on purpose: it lands beside anything the person had staged, and the person
    # sees both in `git status` before committing. An untracked file is not git's to move,
    # and `git mv` refuses one, so it keeps `mv`, as does a target that is not a repository.
    if git -C "$TARGET_DIR" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
      git -C "$TARGET_DIR" mv -- "$rel" "$dst"
    else
      mv "$TARGET_DIR/$rel" "$TARGET_DIR/$dst"
    fi
    log_moved "$rel" "$dst"
  done
  # What is left is the toolkit's own old docs: Step 2b refused anything else that did
  # not move. They are dropped, not moved, because this install writes the current copy.
  # Each one is checked against the list again, because a wrong delete loses project work.
  for root in "${OLD_ROOTS[@]}"; do
    [[ -e "$TARGET_DIR/$root" ]] || continue
    while IFS= read -r rel; do
      [[ -n "$rel" ]] || continue
      if ! printf '%s\n' "$OLD_TOOLKIT" | grep -qxF -- "$rel"; then
        echo "  [!] $rel (not moved and not a toolkit file — left in place)"
        continue
      fi
      rm -f "$TARGET_DIR/$rel"
      log_dropped "$rel"
    done < <(cd "$TARGET_DIR" && find "$root" ! -type d | LC_ALL=C sort)
    if [[ -d "$TARGET_DIR/$root" ]]; then
      find "$TARGET_DIR/$root" -depth -type d -empty -delete
    fi
  done
  echo ""
fi

# ── Step 3b: Prune stale skills and commands ─────────────────────────────────
# Runs before replacement so a project is not left with stale trees beside fresh copies.
# Reads only what previous log entries recorded; no log means no removal.

echo "Pruning stale toolkit paths..."
prune_stale_toolkit_paths
echo ""

# ── Step 4: Scaffold docs structure ──────────────────────────────────────────

SCAFFOLD_DIRS="$TARGET_DIR/docs/blc/briefs/_drafts
$TARGET_DIR/docs/blc/contracts
$TARGET_DIR/docs/blc/chronicles
$TARGET_DIR/docs/blc/install-log
$TARGET_DIR/docs/blc/state
$TARGET_DIR/tools
$TARGET_DIR/tools/lib
$TARGET_DIR/$SKILLS_DST_REL"
if [[ "$HOST" == "claude" ]]; then
  SCAFFOLD_DIRS="$SCAFFOLD_DIRS
$TARGET_DIR/$COMMANDS_DST_REL
$TARGET_DIR/.claude/rules"
else
  SCAFFOLD_DIRS="$SCAFFOLD_DIRS
$TARGET_DIR/.cursor/rules"
fi

while IFS= read -r dir; do
  [[ -n "$dir" ]] || continue
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_created "${dir#$TARGET_DIR/}"
  fi
done <<< "$SCAFFOLD_DIRS"

# chronicle.md is the one committed rendering. Other files under docs/blc/chronicles/
# stay ignored so a later archive feature has a place. A parent-directory rule
# would hide the exception, so the ignore is the contents, then the one file.
#
# This is the one place the installer writes to a file it does not own, so it appends and
# never rewrites: an existing .gitignore keeps everything it had. A target that already
# has the `docs/blc/chronicles/` directory rule is left alone — that rule still hides
# chronicle.md. Un-hiding it there is a hand edit, not an installer behaviour.
#
# The rules before #0017 name `docs/chronicles/`, and they do not match the new location. A
# target that has them gets this block as well, and keeps the old lines, which now match
# nothing. Removing them is the upgrade's job in #0017 phase `c`, not a fresh install's.
GITIGNORE_DST="$TARGET_DIR/.gitignore"
if [[ -f "$GITIGNORE_DST" ]] && { grep -qxF 'docs/blc/chronicles/' "$GITIGNORE_DST" || grep -qxF '!docs/blc/chronicles/chronicle.md' "$GITIGNORE_DST"; }; then
  log_skipped_as ".gitignore" "chronicles ignore rule already present"
else
  if [[ -f "$GITIGNORE_DST" ]]; then
    printf '\n' >> "$GITIGNORE_DST"
    GITIGNORE_LABEL=".gitignore (appended chronicles ignore)"
  else
    GITIGNORE_LABEL=".gitignore"
  fi
  cat >> "$GITIGNORE_DST" <<'GITIGNORE_EOF'
# chronicle.md is the one committed rendering. Other files under this folder stay ignored.
docs/blc/chronicles/*
!docs/blc/chronicles/chronicle.md
GITIGNORE_EOF
  log_created "$GITIGNORE_LABEL"
fi

# Copy the briefs docs and the Contract. Toolkit-owned: replaced every run.
# Numbered brief folders are never written here.
#
# These ship from this repository's own docs/ rather than from a template copy. A
# second copy under templates/ was hand-synced against these files and had already
# diverged, which is the drift the Contract was extracted to end. The files a target
# receives are now the files this repository lives by.
while IFS=$'\t' read -r _owner _kind src dst; do
  case "$src" in docs/*) ;; *) continue ;; esac
  place_file "$SCRIPT_DIR/$src" "$TARGET_DIR/$dst" "$dst"
done < <(map_rows toolkit)

# Every clause in the current Contract names validate-briefs.sh, and the briefs README that
# ships beside it names open-briefs.sh. Shipping the prose without the tools would
# leave both pointing at nothing in the target — claiming a check and a query that
# are not there. Any tool this repo's own docs name has to travel with them.
#
# list-briefs.sh is here for a stronger reason than prose: the blc-chronicle skill
# reads its brief table from it and exits non-zero without it, so a target that got
# the skill and not the tool would have a chronicle that cannot run.
while IFS=$'\t' read -r _owner _kind src dst; do
  case "$src" in tools/*) ;; *) continue ;; esac
  tool_dst="$TARGET_DIR/$dst"
  if [[ -f "$tool_dst" ]]; then
    tool_is_new=false
  else
    tool_is_new=true
  fi
  place_file "$SCRIPT_DIR/$src" "$tool_dst" "$dst"
  # tools/lib/ is sourced, never invoked. An execute bit there would advertise an entry
  # point that does not exist — the same claim tests/test_source_tree.sh declines to make
  # about these files in our own tree.
  case "$src" in
    tools/lib/*) ;;
    *) chmod +x "$tool_dst" ;;
  esac
done < <(map_rows toolkit)

# ── Step 5: Place the skills ─────────────────────────────────────────────────
#
# Same source files either way. On Cursor every skill goes to .cursor/skills/ as a
# directory. On Claude Code the process skills become flat slash-command files under
# .claude/commands/ (the command name comes from the filename, which is why SKILL.md is
# renamed to <skill>.md), and the rest install as skills. The shared YAML frontmatter is
# valid in both places, so no per-host copy of the prose exists.

echo ""
echo "Skills:"
while IFS=$'\t' read -r _owner kind src dst; do
  case "$src" in skills/*) ;; *) continue ;; esac
  if [[ "$kind" == "file" ]]; then
    place_file "$SCRIPT_DIR/$src" "$TARGET_DIR/$dst" "$dst"
  else
    place_dir "$SCRIPT_DIR/$src" "$TARGET_DIR/$dst" "$dst"
  fi
done < <(map_rows toolkit)

# ── Step 6: Process rules and project stub ───────────────────────────────────
#
# Two owners, two files. The process contract is installer-owned and replaced
# every run. AGENTS.md / CLAUDE.md are project-owned: a stub is written only
# if absent, and never replaced, so architecture notes survive an upgrade.

echo ""
echo "Configuration:"
place_process_rules
write_project_stub

# ── Step 7: settings.local.json (Claude Code only) ───────────────────────────

if [[ "$HOST" == "claude" ]]; then
  place_file "$SCRIPT_DIR/templates/.claude/settings.local.json" \
             "$TARGET_DIR/.claude/settings.local.json" \
             ".claude/settings.local.json"
fi

# ── Step 8: Append to the install log ────────────────────────────────────────
#
# An install is a recurring *event*, not a unit of work, so it gets a log — not a brief
# and not a draft. This matters beyond tidiness: the previous version of this step
# hardcoded `docs/briefs/0001-bootstrap/` and guarded on `[[ ! -d "$BRIEF_DIR" ]]`,
# which asks "does 0001-bootstrap/ exist?" when the question is "is serial 0001 free?".
# Installing into a repo that already had briefs therefore wrote a *second* #0001,
# deterministically, every time — bypassing `/blc-create-brief`, which is the single point
# of serial assignment precisely so that cannot happen. A log has no serial to collide
# with, so the whole class of bug goes away rather than being guarded against.
#
# Appending also makes re-runs meaningful instead of something to suppress: upgrading an
# onboarded project is a real event worth a line, and appending never overwrites, so the
# installer's never-clobber posture is preserved without any exists-check at all.

LOG_FILE="$TARGET_DIR/docs/blc/install-log/install-log.md"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
MACHINE="$(hostname)"
# The version identifies a build and promises nothing. Nothing is chosen by hand, because a
# chosen number would be a second copy of what git already knows and would read as a
# compatibility promise the Contract has not made. The count orders and the hash identifies,
# so a target tells it is behind by subtracting two counts, offline.
installer_version() {
  local count sha
  # A shallow clone counts only what it fetched, so its count is wrong and nothing downstream
  # can tell. `--depth` is how CI checks out by default.
  [[ "$(git -C "$SCRIPT_DIR" rev-parse --is-shallow-repository 2>/dev/null)" == "true" ]] \
    && { echo "unknown (shallow clone)"; return; }
  # No separate "is this a repository" check: these fail there, into the same unknown.
  count="$(git -C "$SCRIPT_DIR" rev-list --count HEAD 2>/dev/null)" || { echo "unknown"; return; }
  sha="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null)" || { echo "unknown"; return; }
  echo "$count+$sha"
}

VERSION="$(installer_version)"

# Header written once; entries appended under it forever after.
if [[ ! -f "$LOG_FILE" ]]; then
  cat > "$LOG_FILE" <<'LOGHEAD_EOF'
# Install log

Every run of `brief-ledger-chronicle`'s `install.sh` against this repository, oldest
first. Appended automatically — add entries by running the installer, not by hand.

This is a record of *what was installed here and when*. The reasoning behind how the
toolchain is put together lives upstream in the brief-ledger-chronicle repository,
not duplicated into every project it onboards.

LOGHEAD_EOF
  log_created "docs/blc/install-log/install-log.md"
else
  # Deliberately not logged into SKIPPED: an append is neither a create nor a skip, and
  # recording it there would make the log list itself as skipped inside its own entry.
  echo "  [+] docs/blc/install-log/install-log.md (entry appended)"
fi

# Built inline rather than from the CREATED/SKIPPED arrays' raw form so the entry reads
# as a list at a glance; the arrays themselves carry per-file detail below. Which list a
# skill lands in depends on the host, so the entry records what this project actually got
# rather than what the source happens to contain.
SKILL_LIST=""
CMD_LIST=""
while IFS=$'\t' read -r _owner kind src _dst; do
  case "$src" in skills/*) ;; *) continue ;; esac
  skill_name="${src#skills/}"
  skill_name="${skill_name%/SKILL.md}"
  if [[ "$kind" == "file" ]]; then
    CMD_LIST+="  - $skill_name"$'\n'
  else
    SKILL_LIST+="  - $skill_name"$'\n'
  fi
done < <(map_rows toolkit)
[[ -n "$CMD_LIST" ]] || CMD_LIST="  (none — this host takes them all as skills)"$'\n'

# Only an upgrade from the old layout has this section. A move happens once per target, so
# an empty section on every later entry would say nothing.
MOVED_SECTION=""
if [[ $((${#MOVED[@]} + ${#DROPPED[@]})) -gt 0 ]]; then
  MOVED_SECTION=$'\n\n'"### Moved — old docs/ layout to docs/blc/"$'\n'
  for m in ${MOVED[@]+"${MOVED[@]}"}; do MOVED_SECTION+=$'\n'"  - $m"; done
  for d in ${DROPPED[@]+"${DROPPED[@]}"}; do
    MOVED_SECTION+=$'\n'"  - $d (old copy of a toolkit file — dropped)"
  done
fi

cat >> "$LOG_FILE" <<ENTRY_EOF
## $TIMESTAMP — $MACHINE

- **Host:** $HOST
- **Installer version:** $VERSION
- **Created:** ${#CREATED[@]} · **Skipped:** ${#SKIPPED[@]} · **Replaced:** ${#REPLACED[@]} · **Removed:** ${#REMOVED[@]}

### Skills installed

$SKILL_LIST
### Commands installed

$CMD_LIST
### Created

$(if [[ ${#CREATED[@]} -gt 0 ]]; then
  for d in ${CREATED[@]+"${CREATED[@]}"}; do echo "  - $d"; done
else
  echo "  (none)"
fi)

### Replaced

$(if [[ ${#REPLACED[@]} -gt 0 ]]; then
  for r in ${REPLACED[@]+"${REPLACED[@]}"}; do echo "  - $r"; done
else
  echo "  (none)"
fi)

### Removed

$(if [[ ${#REMOVED[@]} -gt 0 ]]; then
  for r in ${REMOVED[@]+"${REMOVED[@]}"}; do echo "  - $r"; done
else
  echo "  (none)"
fi)

### Skipped — already present

$(if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  for s in ${SKIPPED[@]+"${SKIPPED[@]}"}; do echo "  - $s"; done
else
  echo "  (none)"
fi)$MOVED_SECTION

ENTRY_EOF

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Done."
echo ""
echo "Created (${#CREATED[@]}):"
# `${ARR[@]+"${ARR[@]}"}` — under `set -u`, bash 3.2 (still the default /bin/bash
# on macOS) treats a bare "${ARR[@]}" on an empty array as unbound and aborts.
# CREATED is empty on any re-run where everything already exists.
for item in ${CREATED[@]+"${CREATED[@]}"}; do echo "  $item"; done

if [[ ${#REPLACED[@]} -gt 0 ]]; then
  echo ""
  echo "Replaced (${#REPLACED[@]}):"
  for item in ${REPLACED[@]+"${REPLACED[@]}"}; do echo "  $item"; done
fi

if [[ ${#REMOVED[@]} -gt 0 ]]; then
  echo ""
  echo "Removed (${#REMOVED[@]}):"
  for item in ${REMOVED[@]+"${REMOVED[@]}"}; do echo "  $item"; done
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo ""
  echo "Skipped — already exist (${#SKIPPED[@]}):"
  for item in ${SKIPPED[@]+"${SKIPPED[@]}"}; do echo "  $item"; done
fi

if [[ ${#MOVED[@]} -gt 0 ]]; then
  echo ""
  echo "Moved from the old docs/ layout (${#MOVED[@]}):"
  for item in ${MOVED[@]+"${MOVED[@]}"}; do echo "  $item"; done
fi

echo ""
echo "Next steps:"
echo "  1. Answer the questions in $RULES_FILE — the installer could not."
echo "  2. Process rules are in $PROCESS_RULES_REL — the installer owns that file."
if [[ "$HOST" == "claude" ]]; then
  echo "  3. Review .claude/settings.local.json — add any project-specific permissions."
  echo "  4. git add -A && git commit -m 'Bootstrap: brief-ledger-chronicle install'"
  echo "  5. Open docs/blc/install-log/install-log.md to see what this run did."
else
  echo "  3. Skills are under .cursor/skills/ — local edits are replaced on the next install."
  echo "  4. git add -A && git commit -m 'Bootstrap: brief-ledger-chronicle install'"
  echo "  5. Open docs/blc/install-log/install-log.md to see what this run did."
fi
# The tools date a brief by its last commit. The commit that holds this move touches every
# brief, so unless it is ignored, every brief shows the move as its last work.
if [[ ${#MOVED[@]} -gt 0 ]]; then
  echo "  6. This run moved the old docs/ layout. After the commit in step 4, add it to the"
  echo "     ignore list so each brief keeps its own dates, and commit that too:"
  echo "       echo \"\$(git rev-parse HEAD)  # BLC moved docs/ under docs/blc/\" >> docs/blc/ignore-revs"
fi
echo ""
