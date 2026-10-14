#!/usr/bin/env bash
# Numbers for REPORT.md. Nothing in the console depends on this file.
#
#   experiments/blic/p1-bash/measure.sh
#
# Measures, in order: time to the first frame, time to a populated frame, bytes written for
# one cursor move, idle CPU over a window, and the lag from a synthetic event being printed
# by the stream to the console having it on screen.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(git -C "$HERE" rev-parse --show-toplevel)"
BLIC="$HERE/blic"
export BLIC_ROWS=40 BLIC_COLS=118

now_ms() { printf '%s' "$(( $(date +%s%N) / 1000000 ))"; }

echo "== 1. time to first frame (what you see before the record arrives)"
for i in 1 2 3; do
  t0=$(now_ms)
  BLIC_SCRIPT_DELAY=0 "$BLIC" --keys 'q' --frames --no-peer >/dev/null 2>&1
  t1=$(now_ms)
  echo "   run $i: $((t1 - t0)) ms"
done

echo "== 2. time to a populated frame (the record is on screen)"
for i in 1 2 3; do
  t0=$(now_ms)
  "$BLIC" --once --no-peer >/dev/null 2>&1
  t1=$(now_ms)
  echo "   run $i: $((t1 - t0)) ms"
done

echo "== 3. bytes on the wire for one cursor move, 40x118"
# Run the same session with one more keypress each time, every key landing after the record
# has loaded. The difference between consecutive runs is what one cursor move costs, and
# the count of positioned writes in it is how many of the 40 rows were touched.
prev=0
for n in 0 1 2 3; do
  keys=""
  for ((i = 0; i < n; i++)); do keys+="j"; done
  cap="$(mktemp)"
  BLIC_SCRIPT_DELAY=0.1 BLIC_COLOR=1 "$BLIC" --settle --keys "${keys}q" --no-peer > "$cap" 2>/dev/null
  total=$(wc -c < "$cap")
  rows=$(grep -ao $'\033\[[0-9]*;1H' "$cap" | wc -l)
  if (( n == 0 )); then
    echo "   $n moves: $total bytes, $rows row writes (the first full paint)"
  else
    echo "   $n moves: $total bytes, $rows row writes (+$((total - prev)) bytes for this move)"
  fi
  prev=$total
  rm -f "$cap"
done

echo "== 4. idle CPU over 20 s (stdin held open by a fifo, so read(1) blocks as it would)"
fifo="$(mktemp -u)"; mkfifo "$fifo"
out="$(mktemp)"
"$BLIC" --no-peer > "$out" 2>&1 < "$fifo" &
pid=$!
exec 9>"$fifo"
sleep 3
read -r _ _ _ _ _ _ _ _ _ _ _ _ _ u0 s0 _ < "/proc/$pid/stat" 2>/dev/null
sleep 20
read -r _ _ _ _ _ _ _ _ _ _ _ _ _ u1 s1 _ < "/proc/$pid/stat" 2>/dev/null
hz=$(getconf CLK_TCK)
cpu=$(( ( (u1 - u0) + (s1 - s0) ) * 1000 / hz ))
echo "   main process: ${cpu} ms of CPU in 20000 ms = $((cpu * 100 / 20000))% of one core"
printf 'q' >&9
exec 9>&-
sleep 1
kill "$pid" 2>/dev/null
rm -f "$fifo" "$out"

echo "== 5. lag from a synthetic event to it being on screen"
# peer-events.sh prints its first line the moment it starts, and the console starts it as
# part of its own startup. So: launch, poll the console's own output every 10 ms, and take
# the time the marked line first reaches stdout. The time to the first frame (section 1)
# is inside this number, because the event cannot be drawn before the frame it sits in.
fifo="$(mktemp -u)"; mkfifo "$fifo"
out="$(mktemp)"
t0=$(now_ms)
"$BLIC" --peer-interval 30 > "$out" 2>&1 < "$fifo" &
pid=$!
exec 9>"$fifo"
hit=""
for ((i = 0; i < 600; i++)); do
  if grep -aq 'SYN' "$out" 2>/dev/null; then hit=$(now_ms); break; fi
  sleep 0.01
done
printf 'q' >&9; exec 9>&-; sleep 0.5; kill "$pid" 2>/dev/null
if [ -n "$hit" ]; then echo "   launch to the first marked event on stdout: $((hit - t0)) ms"
else echo "   the marked event never reached stdout — look at it"; fi
rm -f "$fifo" "$out"

# The first event is printed by the stream at its own start, so the number above is a floor.
# The second one arrives mid-session and is the one the poll interval governs.
fifo="$(mktemp -u)"; mkfifo "$fifo"
out="$(mktemp)"
t0=$(now_ms)
"$BLIC" --peer-interval 3 > "$out" 2>&1 < "$fifo" &
pid=$!
exec 9>"$fifo"
hit2=""
for ((i = 0; i < 900; i++)); do
  # The stream's second event is the only one that mentions #0041, so this cannot be
  # satisfied by the first event's row being repainted when the record finishes loading.
  if grep -aq 'declare #0041' "$out" 2>/dev/null; then hit2=$(now_ms); break; fi
  sleep 0.01
done
printf 'q' >&9; exec 9>&-; sleep 0.5; kill "$pid" 2>/dev/null
if [ -n "$hit2" ]; then
  echo "   second event: on stdout $((hit2 - t0)) ms after launch, and the stream printed it"
  echo "   3000 ms after launch, so the console took about $((hit2 - t0 - 3000)) ms to show it"
fi
rm -f "$fifo" "$out"

echo "== 6. cost of composing and writing one frame"
# Twenty moves with no delay, against the same session with none. The difference divided by
# twenty is what a keypress costs in the loop: compose, diff, write.
t0=$(now_ms); BLIC_SCRIPT_DELAY=0 "$BLIC" --settle --keys 'q' --no-peer >/dev/null 2>&1; t1=$(now_ms)
base=$((t1 - t0))
t0=$(now_ms); BLIC_SCRIPT_DELAY=0 "$BLIC" --settle --keys 'jjjjjjjjjjjjjjjjjjjjq' --no-peer >/dev/null 2>&1; t1=$(now_ms)
with=$((t1 - t0))
echo "   settle only: ${base} ms; settle + 20 moves: ${with} ms"
echo "   one frame: $(( (with - base) / 20 )) ms"

echo "== 7. size"
wc -l "$HERE/blic" "$HERE/lib/json.awk" "$HERE/lib/shape.awk" "$HERE/measure.sh"
