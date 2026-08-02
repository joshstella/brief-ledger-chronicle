#!/usr/bin/env bash
# brief-ledger installer
# Bootstraps the brief/ledger/review workflow into a target project (Cursor-native).
# Usage: bash install.sh [--target <path>] [--yes]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=""
ASSUME_YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_DIR="$2"; shift 2 ;;
    --yes|-y) ASSUME_YES=true; shift ;;
    --help|-h)
      echo "Usage: bash install.sh [--target <path>] [--yes]"
      echo "  --target <path>   Install into <path> instead of current directory"
      echo "  --yes             Skip confirmation prompt"
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$TARGET_DIR" ]] && TARGET_DIR="$(pwd)"

if [[ "$TARGET_DIR" -ef "$SCRIPT_DIR" ]]; then
  echo "error: cannot install into brief-ledger itself." >&2
  echo "  This repo is the source of the process, not a target for it." >&2
  echo "  Use --target <path> to install into another project." >&2
  exit 1
fi

CREATED=()
SKIPPED=()

log_created() { CREATED+=("$1"); echo "  [+] $1"; }
log_skipped() { SKIPPED+=("$1"); echo "  [~] $1 (already exists, skipped)"; }

install_hint() {
  case "$1" in
    git) echo "    macOS: brew install git  |  Linux: sudo apt install git" ;;
    gh)  echo "    macOS: brew install gh   |  Linux: https://cli.github.com/manual/installation" ;;
  esac
}

echo ""
echo "brief-ledger installer"
echo "======================"
echo ""
echo "Checking dependencies..."

MISSING=()
for dep in git gh; do
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

SKILL_COUNT="$(find "$SCRIPT_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"

echo ""
echo "Target directory: $TARGET_DIR"
echo ""
echo "This will create or update:"
echo "  $TARGET_DIR/docs/briefs/           (brief/ledger structure)"
echo "  $TARGET_DIR/docs/chronicles/       (generated chronicles)"
echo "  $TARGET_DIR/.cursor/skills/        ($SKILL_COUNT workflow skills)"
echo "  $TARGET_DIR/AGENTS.md              (project process rules — if absent)"
echo "  $TARGET_DIR/docs/briefs/0001-bootstrap/  (self-documenting install brief)"
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

for dir in \
  "$TARGET_DIR/docs/briefs/_drafts" \
  "$TARGET_DIR/docs/chronicles" \
  "$TARGET_DIR/.cursor/skills"; do
  [[ -d "$dir" ]] || mkdir -p "$dir"
done

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

echo ""
echo "Skills:"
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  skill_name="$(basename "$skill_dir")"
  dst="$TARGET_DIR/.cursor/skills/$skill_name"
  if [[ ! -d "$dst" ]]; then
    cp -r "$skill_dir" "$dst"
    log_created ".cursor/skills/$skill_name"
  else
    log_skipped ".cursor/skills/$skill_name"
  fi
done

echo ""
echo "Configuration:"
if [[ ! -f "$TARGET_DIR/AGENTS.md" ]]; then
  cp "$SCRIPT_DIR/templates/AGENTS.md" "$TARGET_DIR/AGENTS.md"
  log_created "AGENTS.md"
else
  log_skipped "AGENTS.md"
fi

BRIEF_DIR="$TARGET_DIR/docs/briefs/0001-bootstrap"
AUTHOR="$(git -C "$TARGET_DIR" config user.email 2>/dev/null || echo "unknown@example.com")"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
MACHINE="$(hostname)"

if [[ ! -d "$BRIEF_DIR" ]]; then
  mkdir -p "$BRIEF_DIR"

  SKILL_LIST=""
  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    SKILL_LIST+="  - $(basename "$skill_dir")"$'\n'
  done

  cat > "$BRIEF_DIR/brief.md" <<BRIEF_EOF
# Bootstrap: brief-ledger install

**Serial:** #0001 · **Created:** $TIMESTAMP · **Author:** $AUTHOR · **Depends on:** —

## Overview

This brief records the actions taken by \`install.sh\` to bring this repository into
conformance with the brief-ledger workflow.

## Settled decisions

- Skills install per-project under \`.cursor/skills/\`, not globally, so each repo can tune.
- Existing files are never overwritten; the installer is idempotent.

## Open decisions

- None.

## Phases

This brief has no phases — the install is a single atomic action documented in the ledger.
BRIEF_EOF

  cat > "$BRIEF_DIR/ledger.md" <<LEDGER_EOF
# Ledger — #0001 Bootstrap

**Status:** completed

## Install record

- **Date:** $TIMESTAMP
- **Machine:** $MACHINE
- **Installer version:** $(git -C "$SCRIPT_DIR" describe --tags --always 2>/dev/null || git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

## Skills installed

$SKILL_LIST
## Directories created

$(for d in "${CREATED[@]}"; do echo "  - $d"; done)

## Files skipped (already existed)

$(if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  for s in "${SKIPPED[@]}"; do echo "  - $s"; done
else
  echo "  (none)"
fi)

## Complications

None — clean first install.
LEDGER_EOF

  log_created "docs/briefs/0001-bootstrap/brief.md"
  log_created "docs/briefs/0001-bootstrap/ledger.md"
else
  log_skipped "docs/briefs/0001-bootstrap/ (bootstrap brief already exists)"
fi

echo ""
echo "Done."
echo ""
echo "Created (${#CREATED[@]}):"
for item in "${CREATED[@]}"; do echo "  $item"; done

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo ""
  echo "Skipped — already exist (${#SKIPPED[@]}):"
  for item in "${SKIPPED[@]}"; do echo "  $item"; done
fi

echo ""
echo "Next steps:"
echo "  1. Review and edit AGENTS.md — fill in the project-specific section."
echo "  2. git add -A && git commit -m 'Bootstrap: brief-ledger install'"
echo "  3. Open docs/briefs/0001-bootstrap/brief.md to see the install record."
echo ""
