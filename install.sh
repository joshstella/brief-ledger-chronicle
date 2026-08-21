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
# them, taking the six process skills as slash-commands under `.claude/commands/` and the
# rest as skills. Nothing is duplicated per host, so a wording fix lands once.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=""
MODE="project"
HOST="claude"
ASSUME_YES=false

# The six skills that drive the workflow. Claude Code installs these as slash-commands so
# they can be invoked explicitly as `/name`; Cursor has no such concept and takes them as
# ordinary skills. Everything else in skills/ installs as a skill on both hosts.
PROCESS_SKILLS="commit-push-pr create-brief init-briefs next-brief-phase review-pr start-brief"

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
    --help|-h)
      echo "Usage: bash install.sh [--host claude|cursor] [--target <path>] [--yes]"
      echo "       bash install.sh --machine"
      echo ""
      echo "  --host <name>     Agent host to install for: claude (default) or cursor."
      echo "                    claude → .claude/commands + .claude/skills + CLAUDE.md"
      echo "                    cursor → .cursor/skills + AGENTS.md"
      echo "  --target <path>   Install the process into <path> instead of current directory"
      echo "  --yes, -y         Skip the confirmation prompt (for scripted installs)"
      echo "  --machine         Install the once-per-machine user-level config into"
      echo "                    \$CLAUDE_HOME (default ~/.claude). Run once per machine,"
      echo "                    before or after any project install. Claude Code only."
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
# Machine mode is exempt: it writes to $CLAUDE_HOME, never into a project.
if [[ "$MODE" == "project" && "$TARGET_DIR" -ef "$SCRIPT_DIR" ]]; then
  echo "error: cannot install into brief-ledger-chronicle itself." >&2
  echo "  This repo is the source of the process, not a target for it." >&2
  echo "  Use --target <path> to install into another project." >&2
  exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

CREATED=()
SKIPPED=()
CONFLICTS=()

log_created() { CREATED+=("$1"); echo "  [+] $1"; }
log_skipped() { SKIPPED+=("$1"); echo "  [~] $1 (already exists, skipped)"; }
log_relinked() { CREATED+=("$1 (replaced dangling symlink)"); echo "  [+] $1 (replaced dangling symlink)"; }
# Skip with an explicit reason, for cases where "already exists" is the wrong wording.
log_skipped_as() { SKIPPED+=("$1 ($2)"); echo "  [~] $1 ($2)"; }
log_conflict() { SKIPPED+=("$1"); echo "  [!] $1 ($2 — NOT replaced; see below)"; }

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
    gh)     echo "    macOS: brew install gh   |  Linux: https://cli.github.com/manual/installation" ;;
    node)   echo "    macOS: brew install node |  Linux: https://nodejs.org/en/download" ;;
    npm)    echo "    Comes with Node.js — install node first" ;;
    claude) echo "    https://claude.ai/code — install the Claude Code CLI" ;;
  esac
}

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
for dep in git gh node npm claude; do
  if command -v "$dep" &>/dev/null; then
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
# install creates — `/init-briefs` reads the brief README template from
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
# Skills are deliberately NOT linked here. They install per-project so a project can
# tune its own copy; a machine-wide link would silently override every such tune with
# whatever the repo happens to be at, and the tune would come back the moment someone
# ran `git pull`.

if [[ "$MODE" == "machine" ]]; then
  echo ""
  echo "Checking machine-mode sources..."

  MISSING_SOURCES=()
  for src in "personal/CLAUDE.md" "skills" "templates/docs/briefs/README.md"; do
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
  echo "  $CLAUDE_HOME/briefs/README.template.md  → templates/docs/briefs/README.md"
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

  link_into_place "$SCRIPT_DIR/templates/docs/briefs/README.md" \
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
echo "Checking templates..."

MISSING_TEMPLATES=()
for tpl in \
  "templates/CLAUDE.md" \
  "templates/AGENTS.md" \
  "templates/.claude/settings.local.json" \
  "templates/docs/briefs/README.md" \
  "templates/docs/briefs/_drafts/README.md"; do
  if [[ ! -f "$SCRIPT_DIR/$tpl" ]]; then
    echo "  [✗] $tpl — missing"
    MISSING_TEMPLATES+=("$tpl")
  fi
done

if [[ ! -d "$SCRIPT_DIR/skills" ]]; then
  echo "  [✗] skills — missing"
  MISSING_TEMPLATES+=("skills")
fi

# Every process skill must be present before anything is written: on Claude Code these
# are the slash-commands, and a half-installed command set is worse than none.
for s in $PROCESS_SKILLS; do
  if [[ ! -f "$SCRIPT_DIR/skills/$s/SKILL.md" ]]; then
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

echo "  [✓] all templates present"

# ── Step 3: Target confirmation ───────────────────────────────────────────────

# Host layout, resolved once and used by every step below.
ALL_SKILL_COUNT="$(ls -d "$SCRIPT_DIR"/skills/*/ | wc -l | tr -d ' ')"
PROCESS_COUNT="$(echo $PROCESS_SKILLS | wc -w | tr -d ' ')"
UTILITY_COUNT=$((ALL_SKILL_COUNT - PROCESS_COUNT))

if [[ "$HOST" == "cursor" ]]; then
  SKILLS_DST_REL=".cursor/skills"
  RULES_FILE="AGENTS.md"
else
  SKILLS_DST_REL=".claude/skills"
  COMMANDS_DST_REL=".claude/commands"
  RULES_FILE="CLAUDE.md"
fi

echo ""
echo "Target directory: $TARGET_DIR"
echo "Agent host:       $HOST"
echo ""
echo "This will create or update:"
echo "  $TARGET_DIR/docs/briefs/        (brief/ledger structure)"
echo "  $TARGET_DIR/docs/chronicles/    (generated chronicles)"
echo "  $TARGET_DIR/docs/install-log/   (append-only record of every install)"
if [[ "$HOST" == "cursor" ]]; then
  echo "  $TARGET_DIR/$SKILLS_DST_REL/       ($ALL_SKILL_COUNT skills)"
else
  echo "  $TARGET_DIR/$SKILLS_DST_REL/     ($UTILITY_COUNT skills)"
  echo "  $TARGET_DIR/$COMMANDS_DST_REL/   ($PROCESS_COUNT process commands)"
  echo "  $TARGET_DIR/.claude/settings.local.json  (permission allowlist — if absent)"
fi
echo "  $TARGET_DIR/$RULES_FILE           (project process rules — if absent)"
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

# ── Step 4: Scaffold docs structure ──────────────────────────────────────────

SCAFFOLD_DIRS="$TARGET_DIR/docs/briefs/_drafts
$TARGET_DIR/docs/chronicles
$TARGET_DIR/docs/install-log
$TARGET_DIR/$SKILLS_DST_REL"
if [[ "$HOST" == "claude" ]]; then
  SCAFFOLD_DIRS="$SCAFFOLD_DIRS
$TARGET_DIR/$COMMANDS_DST_REL"
fi

while IFS= read -r dir; do
  [[ -n "$dir" ]] || continue
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_created "${dir#$TARGET_DIR/}"
  fi
done <<< "$SCAFFOLD_DIRS"

# Copy brief READMEs (only if absent)
for src_rel in "docs/briefs/README.md" "docs/briefs/_drafts/README.md"; do
  src="$SCRIPT_DIR/templates/$src_rel"
  dst="$TARGET_DIR/$src_rel"
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    log_created "$src_rel"
  else
    log_skipped "$src_rel"
  fi
done

# ── Step 5: Place the skills ─────────────────────────────────────────────────
#
# Same source files either way. On Cursor every skill goes to .cursor/skills/ as a
# directory. On Claude Code the six process skills become flat slash-command files under
# .claude/commands/ (the command name comes from the filename, which is why SKILL.md is
# renamed to <skill>.md), and the rest install as skills. The shared YAML frontmatter is
# valid in both places, so no per-host copy of the prose exists.

echo ""
echo "Skills:"
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  skill_name="$(basename "$skill_dir")"

  if [[ "$HOST" == "claude" ]] && is_process_skill "$skill_name"; then
    dst="$TARGET_DIR/$COMMANDS_DST_REL/$skill_name.md"
    if [[ ! -f "$dst" ]]; then
      cp "$skill_dir/SKILL.md" "$dst"
      log_created "$COMMANDS_DST_REL/$skill_name.md"
    else
      log_skipped "$COMMANDS_DST_REL/$skill_name.md"
    fi
    continue
  fi

  dst="$TARGET_DIR/$SKILLS_DST_REL/$skill_name"
  if [[ ! -d "$dst" ]]; then
    cp -r "$skill_dir" "$dst"
    log_created "$SKILLS_DST_REL/$skill_name"
  else
    log_skipped "$SKILLS_DST_REL/$skill_name"
  fi
done

# ── Step 6: Project rules file ───────────────────────────────────────────────
#
# CLAUDE.md and AGENTS.md say the same thing to different readers; each host only looks
# for its own, so only that one is written.

echo ""
echo "Configuration:"
if [[ ! -f "$TARGET_DIR/$RULES_FILE" ]]; then
  cp "$SCRIPT_DIR/templates/$RULES_FILE" "$TARGET_DIR/$RULES_FILE"
  log_created "$RULES_FILE"
else
  log_skipped "$RULES_FILE"
fi

# ── Step 7: settings.local.json (Claude Code only) ───────────────────────────

if [[ "$HOST" == "claude" ]]; then
  SETTINGS_DST="$TARGET_DIR/.claude/settings.local.json"
  if [[ ! -f "$SETTINGS_DST" ]]; then
    cp "$SCRIPT_DIR/templates/.claude/settings.local.json" "$SETTINGS_DST"
    log_created ".claude/settings.local.json"
  else
    log_skipped ".claude/settings.local.json"
  fi
fi

# ── Step 8: Append to the install log ────────────────────────────────────────
#
# An install is a recurring *event*, not a unit of work, so it gets a log — not a brief
# and not a draft. This matters beyond tidiness: the previous version of this step
# hardcoded `docs/briefs/0001-bootstrap/` and guarded on `[[ ! -d "$BRIEF_DIR" ]]`,
# which asks "does 0001-bootstrap/ exist?" when the question is "is serial 0001 free?".
# Installing into a repo that already had briefs therefore wrote a *second* #0001,
# deterministically, every time — bypassing `/create-brief`, which is the single point
# of serial assignment precisely so that cannot happen. A log has no serial to collide
# with, so the whole class of bug goes away rather than being guarded against.
#
# Appending also makes re-runs meaningful instead of something to suppress: upgrading an
# onboarded project is a real event worth a line, and appending never overwrites, so the
# installer's never-clobber posture is preserved without any exists-check at all.

LOG_FILE="$TARGET_DIR/docs/install-log/install-log.md"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
MACHINE="$(hostname)"
VERSION="$(git -C "$SCRIPT_DIR" describe --tags --always 2>/dev/null || git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"

# Header written once; entries appended under it forever after.
if [[ ! -f "$LOG_FILE" ]]; then
  cat > "$LOG_FILE" <<'LOGHEAD_EOF'
# Install log

Every run of `brief-ledger-chronicle`'s `install.sh` against this repository, oldest
first. Appended automatically — add entries by running the installer, not by hand.

This is a record of *what was installed here and when*. The reasoning behind how the
toolchain is put together (per-project skills, never-overwrite, and so on) lives
upstream in the brief-ledger-chronicle repository, not duplicated into every project
it onboards.

LOGHEAD_EOF
  log_created "docs/install-log/install-log.md"
else
  # Deliberately not logged into SKIPPED: an append is neither a create nor a skip, and
  # recording it there would make the log list itself as skipped inside its own entry.
  echo "  [+] docs/install-log/install-log.md (entry appended)"
fi

# Built inline rather than from the CREATED/SKIPPED arrays' raw form so the entry reads
# as a list at a glance; the arrays themselves carry per-file detail below. Which list a
# skill lands in depends on the host, so the entry records what this project actually got
# rather than what the source happens to contain.
SKILL_LIST=""
CMD_LIST=""
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  skill_name="$(basename "$skill_dir")"
  if [[ "$HOST" == "claude" ]] && is_process_skill "$skill_name"; then
    CMD_LIST+="  - $skill_name"$'\n'
  else
    SKILL_LIST+="  - $skill_name"$'\n'
  fi
done
[[ -n "$CMD_LIST" ]] || CMD_LIST="  (none — this host takes them all as skills)"$'\n'

cat >> "$LOG_FILE" <<ENTRY_EOF
## $TIMESTAMP — $MACHINE

- **Host:** $HOST
- **Installer version:** $VERSION
- **Created:** ${#CREATED[@]} · **Skipped:** ${#SKIPPED[@]}

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

### Skipped — already present

$(if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  for s in ${SKIPPED[@]+"${SKIPPED[@]}"}; do echo "  - $s"; done
else
  echo "  (none)"
fi)

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

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo ""
  echo "Skipped — already exist (${#SKIPPED[@]}):"
  for item in ${SKIPPED[@]+"${SKIPPED[@]}"}; do echo "  $item"; done
fi

echo ""
echo "Next steps:"
echo "  1. Review and edit $RULES_FILE — fill in the project-specific section."
if [[ "$HOST" == "claude" ]]; then
  echo "  2. Review .claude/settings.local.json — add any project-specific permissions."
else
  echo "  2. Skills are under .cursor/skills/ — tune any of them for this project."
fi
echo "  3. git add -A && git commit -m 'Bootstrap: brief-ledger-chronicle install'"
echo "  4. Open docs/install-log/install-log.md to see what this run did."
echo ""
