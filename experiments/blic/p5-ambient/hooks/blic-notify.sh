#!/usr/bin/env bash
# hooks/blic-notify.sh — a beforeShellExecution hook that speaks up when the record moved
# under you and you are about to act on it.
#
# This is the only hook shape that can show a person a sentence. The event cheat sheet gives
# `user_message` to beforeShellExecution, beforeMCPExecution, preToolUse and subagentStart,
# and to nothing else. Every informational hook therefore has to attach itself to a gate.
#
# It does not block. It returns `permission: "allow"` and a message. Whether the CLI renders
# `user_message` on an allow is UNVERIFIED — nothing here is installed, so nothing here was
# observed firing. If it does not, this surface degrades to `permission: "ask"`, which is a
# worse trade: a prompt you must dismiss, in exchange for a line you could have read.
#
# Matcher (see hooks.json.example): git push, git commit, and the blc commit skill's path.
# The moment that matters is the one before you add to a trunk that moved.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P5="${BLIC_P5_DIR:-$(cd "$HERE/.." && pwd)}"
# shellcheck source=../lib/blic-cache.sh
. "$P5/lib/blic-cache.sh"

input="$(cat)"

# Fail open, always. A hook that crashes with failClosed unset fails open by design; a hook
# that notifies about a record has no business standing between a person and their commit
# under any failure mode at all.
allow() { printf '{"permission":"allow"}\n'; exit 0; }

cwd=""
[[ "$input" =~ \"cwd\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && cwd="${BASH_REMATCH[1]}"
[ -n "$cwd" ] || cwd="$PWD"

root="$cwd"
while [ -n "$root" ] && [ ! -e "$root/.git" ]; do root="${root%/*}"; done
[ -n "$root" ] && [ -r "$root/experiments/blic/read.sh" ] || allow

cache="$(blic_cache_dir "$root")"
[ -f "$cache/facts" ] || allow

new_total=0; new_top=""; new_synthetic=0
while IFS='=' read -r k v; do
  case "$k" in
    new_total) new_total="$v" ;;
    new_synthetic) new_synthetic="$v" ;;
    new_top) new_top="$v" ;;
  esac
done < "$cache/facts"

[ "${new_total:-0}" -gt 0 ] || allow

# The message names the count, the newest item, and whether any of it is synthetic. A
# notification that hides the synthetic mark is the lie peer-events.sh exists to make
# visible.
note="$new_total change(s) landed in the record that you did not make"
[ -n "$new_top" ] && note="$note — latest: $new_top"
[ "${new_synthetic:-0}" -gt 0 ] && note="$note; $new_synthetic of them are synthetic peer events"
note="$note. Run: blic why"

printf '{"permission":"allow","user_message":%s}\n' "\"${note//\"/\\\"}\""
exit 0
