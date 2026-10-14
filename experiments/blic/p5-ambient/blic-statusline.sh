#!/usr/bin/env bash
# blic-statusline.sh — the Cursor CLI status line. Spawned on every conversation update with
# a StatusLinePayload on stdin; whatever it prints becomes the rows above the prompt.
#
#   echo '{"cwd":"/path/to/repo","model":{"display_name":"Opus"}}' | ./blic-statusline.sh
#
# Two rows. The first is the record, which is the point of this prototype. The second is the
# session, which is what a status line is usually for, and it is here because a surface that
# replaces the user's existing status line has to earn the space it took.
#
# No jq. The skill's examples use it and it is not installed on this machine; a status line
# that dies on a missing dependency prints nothing and the CLI keeps the previous text, so
# the failure looks like a frozen field rather than an error. Bash pattern matching instead.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/blic-cache.sh
. "$HERE/lib/blic-cache.sh"

payload="$(cat)"

# One field out of a flat-ish JSON document, by name. Good enough for a payload whose shape
# is documented and fixed, and wrong for JSON in general — see the note above about jq.
jget() {
  local key="$1" re
  re="\"$key\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
  [[ "$payload" =~ $re ]] && { printf '%s' "${BASH_REMATCH[1]}"; return 0; }
  re="\"$key\"[[:space:]]*:[[:space:]]*([0-9]+(\.[0-9]+)?)"
  [[ "$payload" =~ $re ]] && { printf '%s' "${BASH_REMATCH[1]}"; return 0; }
  return 1
}

cwd="$(jget cwd || true)"
[ -n "$cwd" ] || cwd="$(jget current_dir || true)"
[ -n "$cwd" ] || cwd="$PWD"
model="$(jget display_name || true)"
pct="$(jget used_percentage || echo 0)"; pct="${pct%%.*}"
width="$(jget render_width_chars || echo 100)"

# Walk up for the repo root without forking git. The status line runs every 300ms at the
# fastest; it should not be the most expensive thing in the session.
root="$cwd"
while [ -n "$root" ] && [ ! -e "$root/.git" ]; do root="${root%/*}"; done

dim=$'\033[90m'; cyan=$'\033[36m'; yellow=$'\033[33m'; reset=$'\033[0m'

record=""
if [ -n "$root" ] && [ -r "$root/experiments/blic/read.sh" ]; then
  cache="$(blic_cache_dir "$root")"
  if read -r gen line 2>/dev/null < "$cache/line"; then
    age=$(( EPOCHSECONDS - gen ))
    record="$line"
    [ "$age" -gt $(( ${BLIC_TTL:-20} * 10 )) ] && record="$record  (read ${age}s ago)"
    # The status line is allowed to refresh the cache because it already runs on a timer the
    # user chose. It still spawns detached: a 3.5s read inside a 2s timeout would be killed
    # halfway and print nothing.
    [ "$age" -gt "${BLIC_TTL:-20}" ] && \
      ( BLIC_REPO="$root" "$HERE/blic-refresh.sh" --auto >/dev/null 2>&1 & ) 2>/dev/null
  else
    record="reading the record…"
    ( BLIC_REPO="$root" "$HERE/blic-refresh.sh" --auto >/dev/null 2>&1 & ) 2>/dev/null
  fi
fi

if [ -n "$record" ]; then
  # Truncation is by the payload's own width, which is the one number a shell prompt never
  # gets to know and the one real advantage this surface has over the prompt segment.
  [ "${#record}" -gt "$width" ] && record="${record:0:$(( width - 1 ))}…"
  printf '%sblc%s %s%s%s\n' "$dim" "$reset" "$yellow" "$record" "$reset"
fi
printf '%s%s%s %sctx %s%%%s\n' "$cyan" "${model:-?}" "$reset" "$dim" "$pct" "$reset"
