#!/usr/bin/env bash
# hooks/blic-warm.sh — refresh the cache at the moments an agent session already gives us.
#
# Wired to sessionStart and stop. Neither event has a documented output field, so this hook
# shows nothing and decides nothing; it exists so the cache is warm when the status line and
# the prompt next read it. That is the honest division of labour in p5: hooks refresh,
# surfaces display.
#
# It is NOT a polling loop and it cannot become one. Cursor has no timer event. This fires
# when you open a session and when the agent stops, and between those it does nothing — so
# a peer who pushes while you are reading code is still unnoticed until your next prompt.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P5="${BLIC_P5_DIR:-$(cd "$HERE/.." && pwd)}"

input="$(cat)"
cwd=""
[[ "$input" =~ \"cwd\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && cwd="${BASH_REMATCH[1]}"
[ -n "$cwd" ] || cwd="$PWD"

root="$cwd"
while [ -n "$root" ] && [ ! -e "$root/.git" ]; do root="${root%/*}"; done

if [ -n "$root" ] && [ -r "$root/experiments/blic/read.sh" ]; then
  # Detached. A hook that waits 3.5s for read.sh is 3.5s a person waits for their agent.
  ( BLIC_REPO="$root" "$P5/blic-refresh.sh" --auto >/dev/null 2>&1 & ) 2>/dev/null
fi
exit 0
