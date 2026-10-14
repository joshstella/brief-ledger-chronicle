#!/usr/bin/env bash
# blic watch — one line when the record changes and I did not change it. Silent otherwise.
#
#   blic watch                     poll the record every 20s, no peer source
#   blic watch --peer              also follow experiments/blic/peer-events.sh --stream
#   blic watch --interval 60       slower poll
#   blic watch --transport bell    force a notification transport (see notify.sh --probe)
#   blic watch --once              one poll, then exit (for tests)
#
# Silence is the normal state. The only lines on stdout are events, so the output of a ten
# minute run against an idle repository is an empty file.
#
# Read-only, and it does not fetch: a fetch is a network call this prototype is not allowed to
# make, which is exactly why a one-author repository needs the synthetic peer source.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/json.sh
. "$HERE/lib/json.sh"

READ_SH="${BLIC_READ_SH:-$HERE/../read.sh}"
PEER_SH="${BLIC_PEER_SH:-$HERE/../peer-events.sh}"
INTERVAL=20
PEER=0
ONCE=0
QUIET=0
TRANSPORT=auto
while [ $# -gt 0 ]; do
  case "$1" in
    --interval) INTERVAL="$2"; shift 2 ;;
    --peer) PEER=1; shift ;;
    --once) ONCE=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --transport) TRANSPORT="$2"; shift 2 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "blic watch: unknown option: $1" >&2; exit 2 ;;
  esac
done

ME="$(git config user.email 2>/dev/null || true)"
TRUNK=main
git rev-parse --verify --quiet origin/main >/dev/null 2>&1 && TRUNK=origin/main
RECORD_DIR="docs/blc"
cd "$(git rev-parse --show-toplevel)"

TMP="$(mktemp -d)"
PEER_PID=""
cleanup() {
  # The peer stream sleeps in a child of its own, so the process group gets the signal, not
  # just the shell that started it.
  if [ -n "$PEER_PID" ]; then
    pkill -P "$PEER_PID" 2>/dev/null || true
    kill "$PEER_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP"
}
# A handler that cleans up and returns leaves the loop running: a `trap cleanup TERM` made
# this watcher survive `timeout`, which is the opposite of the durability anybody wants.
trap cleanup EXIT
trap 'cleanup; exit 0' INT TERM HUP

SEEN="$TMP/seen"
: > "$SEEN"

say() {
  local who="$1" kind="$2" ref="$3" subject="$4" synthetic="$5"
  printf '%s  %-18s %-11s %-7s %s%s\n' \
    "$(date +%H:%M:%S)" "$who" "$kind" "$ref" "$subject" \
    "$([ "$synthetic" = 1 ] && printf ' [synthetic]' || true)"
  bash "$HERE/notify.sh" --send --transport "$TRANSPORT" "$kind $ref $subject" || true
}

# ── The repository poll ──────────────────────────────────────────────────────
# Two tiers. The cheap tier is two git ref reads and one `find`; it runs every interval and
# costs about 20ms. The expensive tier is read.sh, and it runs only when the cheap tier moved.
# A watcher that called read.sh every 20 seconds would burn 2s of CPU per poll to tell a
# person nothing, which is the shape of a polling loop that gets switched off.
LAST_REF=""
fingerprint() {
  printf '%s %s' \
    "$(git rev-parse "$TRUNK" HEAD 2>/dev/null | tr '\n' ' ')" \
    "$(find "$RECORD_DIR" -name '*.md' -printf '%T@ ' 2>/dev/null | cksum)"
}

poll_repo() {
  local fp; fp="$(fingerprint)"
  [ "$fp" = "$LAST_REF" ] && return 0
  local first="$LAST_REF"
  LAST_REF="$fp"
  [ -n "$first" ] || return 0            # the first poll establishes the baseline, silently

  local json rec who mine kind serial phase subject sha
  json="$(bash "$READ_SH" events 2>/dev/null || echo '[]')"
  while IFS= read -r rec; do
    [ -n "$rec" ] || continue
    sha="$(blic_field "$rec" sha)"
    [ -n "$sha" ] || continue
    grep -qxF "$sha" "$SEEN" && continue
    printf '%s\n' "$sha" >> "$SEEN"
    mine="$(blic_field "$rec" mine)"
    # The whole contract of this command: my own work is not news.
    [ "$mine" = true ] && continue
    who="$(blic_field "$rec" who)"
    kind="$(blic_field "$rec" kind)"
    serial="$(blic_field "$rec" serial)"
    phase="$(blic_field "$rec" phase)"
    subject="$(blic_field "$rec" subject)"
    say "$who" "$kind" "${serial:+#$serial$phase}" "$subject" 0
  done < <(blic_records "$json" sha)
}

# Seed `seen` with everything already in the log, so a start is not a flood.
seed() {
  local rec
  while IFS= read -r rec; do
    [ -n "$rec" ] || continue
    printf '%s\n' "$(blic_field "$rec" sha)" >> "$SEEN"
  done < <(blic_records "$(bash "$READ_SH" events 2>/dev/null || echo '[]')" sha)
  LAST_REF="$(fingerprint)"
}

# ── The peer source ──────────────────────────────────────────────────────────
# One author means every real event is mine, so the half of #0039 this command exists for has
# no real data behind it. The synthetic stream stands in, and every line it produces keeps the
# `[synthetic]` mark — a console that drops it is lying about the record.
peer_line() {
  local rec="$1" who kind serial phase subject
  who="$(blic_field "$rec" who)"
  kind="$(blic_field "$rec" kind)"
  serial="$(blic_field "$rec" serial)"
  phase="$(blic_field "$rec" phase)"
  subject="$(blic_field "$rec" subject)"
  [ "$(blic_field "$rec" mine)" = true ] && return 0
  say "$who" "$kind" "${serial:+#$serial$phase}" "$subject" \
    "$([ "$(blic_field "$rec" synthetic)" = true ] && echo 1 || echo 0)"
}

seed
if [ "$QUIET" = 0 ]; then
  printf 'blic watch · %s · every %ss · peer %s · transport %s · quiet unless something is not mine\n' \
    "$(git rev-parse --abbrev-ref HEAD)" "$INTERVAL" \
    "$([ "$PEER" = 1 ] && echo on || echo off)" \
    "$([ "$TRANSPORT" = auto ] && bash "$HERE/notify.sh" --pick || printf '%s' "$TRANSPORT")" >&2
fi

if [ "$ONCE" = 1 ]; then
  poll_repo
  exit 0
fi

if [ "$PEER" = 1 ]; then
  mkfifo "$TMP/peer"
  bash "$PEER_SH" --stream > "$TMP/peer" &
  PEER_PID=$!
  exec 3<> "$TMP/peer"
fi

# One blocking read does both jobs: it waits out the tick and it collects a peer line the
# moment it arrives. A second loop or a sleep would make one of the two late.
elapsed=0
while :; do
  if [ "$PEER" = 1 ]; then
    if IFS= read -r -t 1 -u 3 line; then
      [ -n "$line" ] && peer_line "$line"
    fi
  else
    sleep 1
  fi
  elapsed=$((elapsed + 1))
  if [ "$elapsed" -ge "$INTERVAL" ]; then
    elapsed=0
    # Off by default. The loop counts ticks, not seconds, so the only way to know whether it
    # kept time is to have it say so, and a watcher that logs its own polls is the noise this
    # command exists to avoid. Tests set it; people do not.
    [ -n "${BLIC_TICK_LOG:-}" ] && date +%s >> "$BLIC_TICK_LOG"
    poll_repo
  fi
done
