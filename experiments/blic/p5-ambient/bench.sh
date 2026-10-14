#!/usr/bin/env bash
# bench.sh — the numbers REPORT.md quotes. Run it; do not trust the report without it.
#
#   ./bench.sh            all of it
#   ./bench.sh prompt     the per-prompt number only
#
# The claim under test is that an ambient surface costs nothing a person can feel. 50ms per
# prompt is the stated threshold in the bake-off instructions, and the honest way to answer it
# is to time the thing the shell actually runs, not the thing that fills the cache.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"
export BLIC_CACHE_DIR="${BLIC_CACHE_DIR:-${TMPDIR:-/tmp}/blic-bench-$$}"
N="${BLIC_BENCH_N:-200}"

ms() { printf '%s' "$(( ($2 - $1) / 1000000 ))"; }
us() { printf '%s' "$(( ($2 - $1) / 1000 ))"; }

echo "=== bench.sh — p5-ambient ==="
echo "repo      $REPO"
echo "cache     $BLIC_CACHE_DIR"
echo "iterations $N"
echo

if [ "${1:-all}" = "all" ]; then
  echo "--- the instrument, for reference (read.sh is frozen; these are its numbers) ---"
  for c in me declarations events defects briefs snapshot; do
    s=$(date +%s%N); "$REPO/experiments/blic/read.sh" "$c" >/dev/null 2>&1; e=$(date +%s%N)
    printf '  read.sh %-13s %sms\n' "$c" "$(ms "$s" "$e")"
  done
  echo
fi

rm -rf "$BLIC_CACHE_DIR"
echo "--- cold start: empty cache to a rendered line ---"
s=$(date +%s%N); "$HERE/blic-refresh.sh" --full >/dev/null 2>&1; e=$(date +%s%N)
printf '  refresh --full         %sms\n' "$(ms "$s" "$e")"
s=$(date +%s%N); "$HERE/blic-refresh.sh" --events >/dev/null 2>&1; e=$(date +%s%N)
printf '  refresh --events       %sms\n' "$(ms "$s" "$e")"
s=$(date +%s%N); "$HERE/blic-refresh.sh" --auto >/dev/null 2>&1; e=$(date +%s%N)
printf '  refresh --auto (warm)  %sms\n' "$(ms "$s" "$e")"
echo

# ── The number that matters ──────────────────────────────────────────────────
# Measured the way the shell pays it: the sourced function, called in a loop, with the spawn
# throttle already satisfied so the loop measures the steady state rather than one refresh.
echo "--- per-prompt cost, sourced function (the installed path) ---"
# Exported on its own line. See the note at the top of blic-prompt.bash about what an
# assignment prefix on `.` does to this variable.
export BLIC_P5_DIR="$HERE"
# shellcheck source=blic-prompt.bash
. "$HERE/blic-prompt.bash"
cd "$REPO" || exit 1
blic_prompt >/dev/null            # warm the $PWD memo and the spawn throttle
_blic_spawned=$EPOCHSECONDS
s=$(date +%s%N)
for ((i=0;i<N;i++)); do blic_prompt >/dev/null; done
e=$(date +%s%N)
printf '  blic_prompt x%-4s      %sus total, %sus each\n' \
  "$N" "$(us "$s" "$e")" "$(( ($e - $s) / 1000 / N ))"

# The directory-change path walks up for .git and rebuilds the cache path. It is the worst
# case a prompt can hit and it still should not be felt.
s=$(date +%s%N)
for ((i=0;i<N;i++)); do _blic_pwd=""; blic_prompt >/dev/null; done
e=$(date +%s%N)
printf '  after cd (relocate) x%-4s %sus each\n' "$N" "$(( ($e - $s) / 1000 / N ))"

# For contrast: an empty bash function call, to separate our cost from the loop's.
noop() { :; }
s=$(date +%s%N); for ((i=0;i<N;i++)); do noop; done; e=$(date +%s%N)
printf '  empty function x%-4s   %sus each (loop overhead)\n' "$N" "$(( ($e - $s) / 1000 / N ))"
echo

# Startup, measured the way a person meets it: source one line, then type. The first prompt
# is not blocked by the refresh, so the two numbers below are "what it cost me" and "when the
# line turned up", and they are different questions.
echo "--- cold cache, from a shell that has just sourced the segment ---"
rm -rf "$BLIC_CACHE_DIR"
_blic_pwd=""; _blic_spawned=0
s=$(date +%s%N); first="$(blic_prompt)"; e=$(date +%s%N)
printf '  first prompt           %sus, rendered: [%s]\n' "$(us "$s" "$e")" "$first"
# Bounded. A benchmark that waits forever for a line that is never coming reports nothing,
# and "it never came" is itself a result worth printing.
out=""
for ((i=0;i<200;i++)); do
  out="$(blic_prompt)"; [ -n "$out" ] && break
  sleep 0.1; _blic_spawned=0
done
if [ -n "$out" ]; then
  printf '  line appears after     %sms  [%s]\n' "$(ms "$s" "$(date +%s%N)")" "$out"
else
  printf '  line appears after     NEVER (gave up at 20s) — the refresh is not landing\n'
fi
echo

echo "--- per-prompt cost, standalone script (zsh/fish/tmux path) ---"
M=$(( N / 10 )); [ "$M" -ge 10 ] || M=10
s=$(date +%s%N); for ((i=0;i<M;i++)); do "$HERE/bin/blic" line >/dev/null; done; e=$(date +%s%N)
printf '  blic line x%-4s        %sms each\n' "$M" "$(( ($e - $s) / 1000000 / M ))"
s=$(date +%s%N); for ((i=0;i<M;i++)); do bash -c ':'; done; e=$(date +%s%N)
printf '  bash -c : x%-4s        %sms each (interpreter startup)\n' "$M" "$(( ($e - $s) / 1000000 / M ))"
echo

echo "--- Cursor CLI status line, per conversation update ---"
payload="{\"cwd\":\"$REPO\",\"render_width_chars\":100,\"model\":{\"display_name\":\"Claude 4 Opus\"},\"context_window\":{\"used_percentage\":34.5}}"
s=$(date +%s%N)
for ((i=0;i<M;i++)); do printf '%s' "$payload" | "$HERE/blic-statusline.sh" >/dev/null; done
e=$(date +%s%N)
printf '  blic-statusline.sh x%-3s %sms each (budget: timeoutMs 2000)\n' "$M" "$(( ($e - $s) / 1000000 / M ))"
echo

echo "--- hook scripts, per event ---"
hp="{\"cwd\":\"$REPO\",\"command\":\"git push\"}"
s=$(date +%s%N); for ((i=0;i<M;i++)); do printf '%s' "$hp" | "$HERE/hooks/blic-notify.sh" >/dev/null; done; e=$(date +%s%N)
printf '  blic-notify.sh x%-4s   %sms each\n' "$M" "$(( ($e - $s) / 1000000 / M ))"
s=$(date +%s%N); for ((i=0;i<M;i++)); do printf '%s' "$hp" | "$HERE/hooks/blic-warm.sh" >/dev/null; done; e=$(date +%s%N)
printf '  blic-warm.sh x%-4s     %sms each\n' "$M" "$(( ($e - $s) / 1000000 / M ))"
echo

echo "--- size ---"
printf '  lines of code (sh/bash/awk, excluding docs and examples): %s\n' \
  "$(cat "$HERE"/blic-refresh.sh "$HERE"/blic-prompt.bash "$HERE"/blic-statusline.sh \
        "$HERE"/bin/blic "$HERE"/lib/*.sh "$HERE"/lib/*.awk "$HERE"/hooks/*.sh "$HERE"/bench.sh | wc -l)"
printf '  of that, comment and blank: %s\n' \
  "$(cat "$HERE"/blic-refresh.sh "$HERE"/blic-prompt.bash "$HERE"/blic-statusline.sh \
        "$HERE"/bin/blic "$HERE"/lib/*.sh "$HERE"/lib/*.awk "$HERE"/hooks/*.sh "$HERE"/bench.sh \
     | grep -cE '^[[:space:]]*(#|$)')"
rm -rf "$BLIC_CACHE_DIR"
