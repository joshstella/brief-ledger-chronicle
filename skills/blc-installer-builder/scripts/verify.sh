#!/usr/bin/env bash
# verify.sh <package.tgz> — extract and install into throwaway dirs, then check.
# Never present an installer that hasn't passed this.
set -euo pipefail
TGZ="${1:?usage: verify.sh <package.tgz>}"
TGZ="$(cd "$(dirname "$TGZ")" && pwd)/$(basename "$TGZ")"
WORK="$(mktemp -d)"; HOME_T="$(mktemp -d)"
trap 'rm -rf "$WORK" "$HOME_T"' EXIT

tar -xzf "$TGZ" -C "$WORK"
DIR="$(find "$WORK" -maxdepth 1 -mindepth 1 -type d | head -1)"
[ -f "$DIR/install.sh" ] || { echo "FAIL: no install.sh in package"; exit 1; }
[ -d "$DIR/payload" ]    || { echo "FAIL: no payload/ in package"; exit 1; }

# Read DEST_ENV from the generated install.sh so we override the right variable.
DEST_ENV="$(grep -m1 '^DEST_ENV=' "$DIR/install.sh" | sed 's/^DEST_ENV="\([^"]*\)".*/\1/')"
DEST_ENV="${DEST_ENV:-DEST}"

env "$DEST_ENV=$HOME_T" bash "$DIR/install.sh" >/dev/null

payload_count="$(find "$DIR/payload" -type f | wc -l | tr -d ' ')"
installed_count="$(find "$HOME_T" -type f -not -path '*/.*-backup-*/*' | wc -l | tr -d ' ')"
echo "payload files:   $payload_count"
echo "installed files: $installed_count"
[ "$payload_count" -eq "$installed_count" ] || { echo "FAIL: file-count mismatch"; exit 1; }

nonexec="$(find "$HOME_T" -type f -name '*.sh' -not -path '*/.*-backup-*/*' ! -perm -u+x | wc -l | tr -d ' ')"
[ "$nonexec" -eq 0 ] || { echo "FAIL: $nonexec installed script(s) not executable"; exit 1; }

echo "OK: verified ($installed_count files installed, scripts executable)"
