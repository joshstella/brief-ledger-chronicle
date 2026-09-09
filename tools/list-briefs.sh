#!/usr/bin/env bash
# tools/list-briefs.sh [--tsv] [BRIEFS_DIR]
# Emit the brief timeline, newest last-touch first.
# Run from the repository root. Writes to stdout.
#
#   default  markdown table — header row, separator, one row per brief, and
#            nothing else, so a caller can put it under whatever heading it likes
#   --tsv    the sorted scan behind that table, one brief per line:
#            <unix-last-touch> <slug> <dir> <first-iso> <last-iso>, tab separated
#
# --tsv exists because the chronicle needs the same briefs in the same order for
# its narration list, where it applies its own date filter and reads each ledger
# for forks. Without it the scan loop would live in two places and drift; with it
# there is one implementation of "which briefs, in what order" and two renderings.
#
# This is the table #0006 put in the chronicle. #0008 moved it here because it
# has more than one consumer: the chronicle narrates it in full, and the
# orientation verb wants a filtered view of the same rows. A generator with two
# consumers does not belong inside one of them.
#
# Related tools answer different questions about the same directory:
#   open-briefs.sh      — what needs attention (exceptions only)
#   validate-briefs.sh  — is the record well-formed
#   list-briefs.sh      — what is the state (every brief, always)
set -euo pipefail

MODE=table
if [ "${1:-}" = "--tsv" ]; then MODE=tsv; shift; fi
BRIEFS_DIR="${1:-docs/briefs}"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not inside a git repo." >&2; exit 1; }
[ -d "$BRIEFS_DIR" ] || { echo "No $BRIEFS_DIR — run from the repo root of a brief-workflow project." >&2; exit 1; }

# Markdown table cells cannot contain a raw pipe.
cell() { printf '%s' "$1" | tr '|' '/'; }

brief_title() {
  local t
  t=$(sed -n 's/^# //p' "$1" 2>/dev/null | head -1)
  printf '%s' "${t:-—}"
}

# The overall status token from the ledger status line. Both schema versions are
# read: blc/1 indexes phases with numbers, blc/2 with letters.
brief_status() {
  local raw
  if [ ! -f "$1" ]; then
    printf '%s' "planned"
    return
  fi
  raw=$(grep -m1 -E 'blc/[0-9]+' "$1" 2>/dev/null || true)
  if [ -z "$raw" ]; then
    printf '%s' "no-line"
    return
  fi
  raw=$(printf '%s' "$raw" | tr -d '`')
  # The token can contain a space — `done(commit 383ed5b)` — so this strips the
  # schema and serial off the front and the phase fields off the back rather than
  # taking a field by position. Taking $3 would cut that status in half.
  printf '%s' "$raw" | sed -E 's/^blc\/[0-9]+[[:space:]]+#[0-9]+[[:space:]]+//; s/[[:space:]]+[0-9a-z]+:.*$//'
}

brief_depends() {
  local dep
  dep=$(sed -n 's/.*\*\*Depends on:\*\* *//p' "$1" 2>/dev/null | head -1 | sed 's/ *·.*//')
  printf '%s' "${dep:-—}"
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

for d in "$BRIEFS_DIR"/[0-9][0-9][0-9][0-9]-*/ ; do
  [ -d "$d" ] || continue
  # `git log | head -1` takes SIGPIPE once git writes past the first line, which
  # under `set -o pipefail` plus `set -e` kills this script mid-loop. tail consumes
  # its whole input, so nothing is left writing into a closed pipe.
  fcd=$(git log --format='%aI' -- "$d" 2>/dev/null | tail -1)
  # %at is the sort key. %aI is display. String-sorting %aI mis-orders two
  # last-touches that differ only by timezone offset.
  touch_line=$(git log -1 --format='%at %aI' -- "$d" 2>/dev/null || true)
  slug=$(basename "$d")
  if [ -n "$touch_line" ]; then
    last_key="${touch_line%% *}"
    last_disp="${touch_line#* }"
  else
    last_key=0
    last_disp=—
  fi
  first_disp="${fcd:-—}"
  printf '%s\t%s\t%s\t%s\t%s\n' "$last_key" "$slug" "$d" "$first_disp" "$last_disp" >> "$tmp"
done

# Last-touch descending (unix author time). Slug is the tie-break so the order is stable.
if [ "$MODE" = tsv ]; then
  [ -s "$tmp" ] && sort -k1,1nr -k2,2r "$tmp"
  exit 0
fi

echo "| serial | title | status | first | last | depends-on |"
echo "|---|---|---|---|---|---|"

if [ -s "$tmp" ]; then
  sort -k1,1nr -k2,2r "$tmp" | while IFS=$'\t' read -r _last_key slug d first_disp last_disp; do
    serial="#${slug%%-*}"
    title=$(brief_title "${d}brief.md")
    status=$(brief_status "${d}ledger.md")
    dep=$(brief_depends "${d}brief.md")
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$(cell "$serial")" "$(cell "$title")" "$(cell "$status")" \
      "$(cell "$first_disp")" "$(cell "$last_disp")" "$(cell "$dep")"
  done
else
  echo "| — | — | — | — | — | — |"
fi
