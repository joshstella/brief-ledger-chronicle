#!/usr/bin/env bash
# The failure probes for REPORT.md sections 6 and 7. Each one is a claim in the report that
# would otherwise be an opinion.
#
#   experiments/blic/p1-bash/probe-limits.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(git -C "$HERE" rev-parse --show-toplevel)"
BLIC="$HERE/blic"

echo '== A. does ${#s} count cells or characters'
export LC_ALL=C.UTF-8
s=''
s='done·undated'; printf '   "%s": bash says %s, the terminal draws %s cells\n' "$s" "${#s}" "${#s}"
s='日本語のブリーフ'
printf '   "%s": bash says %s, the terminal draws %s cells — a pane padded to %s is %s short\n' \
  "$s" "${#s}" "$(( ${#s} * 2 ))" "${#s}" "${#s}"
s='🟢 shipped'
printf '   "%s": bash says %s, the terminal draws about %s\n' "$s" "${#s}" "$(( ${#s} + 1 ))"
echo "   the fixture's own titles are ASCII plus · and — , all one cell, so this does not"
echo "   show up against this record. It would against any record with CJK or an emoji."

echo
echo "== B. the same string under LC_ALL=C"
s='done·undated'
printf '   LC_ALL=C.UTF-8: %s\n' "${#s}"
printf '   LC_ALL=C:       %s\n' "$(LC_ALL=C bash -c 's="done·undated"; echo ${#s}')"

echo
echo "== C. SIGWINCH reaches the trap"
fifo="$(mktemp -u)"; mkfifo "$fifo"
out="$(mktemp)"
BLIC_ROWS=30 BLIC_COLS=100 "$BLIC" --no-peer > "$out" 2>&1 < "$fifo" &
pid=$!
exec 9>"$fifo"
sleep 3
before=$(wc -c < "$out")
kill -WINCH "$pid"
sleep 1
after=$(wc -c < "$out")
echo "   bytes written in the second after SIGWINCH: $((after - before))"
echo "   (a full repaint of a 30-row frame; 0 would mean the trap never ran)"
printf 'q' >&9; exec 9>&-; sleep 0.5; kill "$pid" 2>/dev/null
rm -f "$fifo" "$out"

echo
echo "== D. what happens when stdin is not a terminal"
timeout 20 "$BLIC" --no-peer < /dev/null > /dev/null 2>&1
echo "   blic < /dev/null exited with $? (124 would mean it hung or spun)"

echo
echo "== E. how many processes one console runs"
fifo="$(mktemp -u)"; mkfifo "$fifo"
out="$(mktemp)"
"$BLIC" --peer-interval 30 > "$out" 2>&1 < "$fifo" &
pid=$!
exec 9>"$fifo"
sleep 4
echo "   descendants of the console while idle:"
ps -o pid=,ppid=,comm= --ppid "$pid" 2>/dev/null | sed 's/^/     /'
printf 'q' >&9; exec 9>&-; sleep 0.5; kill "$pid" 2>/dev/null
rm -f "$fifo" "$out"