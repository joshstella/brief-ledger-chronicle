#!/usr/bin/env bash
# blic-refresh.sh — run the frozen reader, render the line, leave it in the cache.
#
#   blic-refresh.sh --auto     decide the tier (default)
#   blic-refresh.sh --events   events only, the cheap tier
#   blic-refresh.sh --full     briefs + defects + events
#   blic-refresh.sh --baseline mark everything currently in the record as seen
#
# This is the slow half of p5 and it is slow because read.sh is: a full pass is about 3.5s on
# this fixture. It never runs in front of a person. A prompt spawns it detached, at most once
# per BLIC_TTL, and reads whatever the last run left behind.
#
# It is not a daemon. There is no process between invocations, nothing to start at login, and
# nothing to kill. If every shell closes, refreshing stops.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/blic-cache.sh
. "$HERE/lib/blic-cache.sh"
# shellcheck source=lib/render.sh
. "$HERE/lib/render.sh"

REPO="${BLIC_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
[ -n "$REPO" ] || { echo "blic-refresh: not in a git repository" >&2; exit 2; }
CACHE="$(blic_cache_dir "$REPO")"
READER="$(blic_reader "$REPO")"
PEER="$(blic_peer "$REPO")"
[ -x "$READER" ] || { echo "blic-refresh: no reader at $READER" >&2; exit 2; }

mkdir -p "$CACHE"
FULL_TTL="${BLIC_FULL_TTL:-900}"

# mkdir is the lock because it is atomic on every filesystem this will meet and needs no
# flock binary. A stale lock from a killed refresh expires rather than wedging the prompt
# forever: a surface that can deadlock a shell prompt is not shippable.
LOCK="$CACHE/lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +2 2>/dev/null)" ]; then
    rmdir "$LOCK" 2>/dev/null || true
    mkdir "$LOCK" 2>/dev/null || exit 0
  else
    exit 0
  fi
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

mode="${1:---auto}"
now="$EPOCHSECONDS"
head_now="$(git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo unknown)"

fact() { printf '%s=%s\n' "$1" "$2" >>"$CACHE/facts.new"; }

read_facts_value() {
  local k="$1" line
  [ -f "$CACHE/facts" ] || return 1
  while IFS= read -r line; do
    case "$line" in "$k="*) printf '%s' "${line#*=}"; return 0 ;; esac
  done < "$CACHE/facts"
  return 1
}

# ── Tier choice ──────────────────────────────────────────────────────────────
# A full pass costs read.sh briefs (≈2.0s) plus read.sh defects (≈1.0s). Neither changes
# unless a commit lands, so HEAD is the trigger and the TTL is only a backstop for an edit
# that is not committed yet.
if [ "$mode" = "--auto" ]; then
  prev_head="$(read_facts_value head || true)"
  prev_gen="$(read_facts_value generated || echo 0)"
  if [ ! -f "$CACHE/facts" ] || [ "$prev_head" != "$head_now" ] || [ $(( now - prev_gen )) -gt "$FULL_TTL" ]; then
    mode="--full"
  else
    mode="--events"
  fi
fi

# ── Events ───────────────────────────────────────────────────────────────────
# Peer events are off unless asked for. They are synthetic and the fixture is the real
# record, so the default view of this repository is the real one.
collect_events() {
  "$READER" events 2>/dev/null | awk -f "$HERE/lib/parse-events.awk"
  if [ "${BLIC_PEER:-0}" = 1 ] && [ -x "$PEER" ]; then
    "$PEER" 2>/dev/null | awk -f "$HERE/lib/parse-events.awk"
  fi
}

collect_events >"$CACHE/events.new"
mv "$CACHE/events.new" "$CACHE/events"

# First run marks the record as already seen. The alternative is a new user's first prompt
# announcing forty commits they wrote themselves, which trains them to ignore the field.
if [ ! -f "$CACHE/seen" ] || [ "$mode" = "--baseline" ]; then
  cut -d$'\x1f' -f1 "$CACHE/events" >"$CACHE/seen"
fi

# `what changed that I did not do`: not mine, not already acknowledged.
declare -A SEEN=()
while IFS= read -r sha; do [ -n "$sha" ] && SEEN["$sha"]=1; done < "$CACHE/seen"

new_total=0; new_synthetic=0; new_top=""
while IFS=$'\x1f' read -r sha mine syn kind serial who subject; do
  [ "$mine" = 0 ] || continue
  [ -n "${SEEN[$sha]:-}" ] && continue
  new_total=$(( new_total + 1 ))
  [ "$syn" = 1 ] && new_synthetic=$(( new_synthetic + 1 ))
  if [ -z "$new_top" ]; then
    new_top="$kind${serial:+ #$serial} by ${who%%@*}"
    [ "$syn" = 1 ] && new_top="$new_top (synthetic)"
  fi
done < "$CACHE/events"

: >"$CACHE/facts.new"

# ── Briefs and defects ───────────────────────────────────────────────────────
if [ "$mode" = "--full" ] || [ ! -f "$CACHE/facts" ]; then
  "$READER" briefs 2>/dev/null | awk -f "$HERE/lib/parse-briefs.awk" >>"$CACHE/facts.new"
  # The gate's own count, not a second opinion about what a defect is.
  d="$("$READER" defects 2>/dev/null | grep -o '"clause"' | wc -l | tr -d ' ')"
  fact defects "${d:-0}"
else
  # Carry the previous pass's brief facts forward unchanged. They are a function of HEAD and
  # HEAD has not moved.
  grep -E '^(briefs_total|briefs_open|mine_open|no_ledger|mine_serial|mine_state|mine_title|mine_phase|mine_phase_state|mine_phase_label|next_phase|next_label|defects)=' \
    "$CACHE/facts" >>"$CACHE/facts.new" 2>/dev/null || true
fi

fact new_total "$new_total"
fact new_synthetic "$new_synthetic"
fact new_top "$new_top"
fact events_total "$(wc -l <"$CACHE/events" | tr -d ' ')"
fact head "$head_now"
fact generated "$now"
mv "$CACHE/facts.new" "$CACHE/facts"

# ── The rendered line ────────────────────────────────────────────────────────
# Written with the generation stamp as its first field so the prompt can test its own
# staleness with one builtin `read` and no `stat`.
stale=0
blic_load_facts "$CACHE/facts"
line="$(blic_render_line "${BLIC_WIDTH:-72}")"
printf '%s %s\n' "$now" "$line" >"$CACHE/line.new"
mv "$CACHE/line.new" "$CACHE/line"
printf '%s %s\n' "$now" "$mode" >>"$CACHE/history"
