#!/usr/bin/env bash
# chronicle/scripts/gather.sh [SINCE_DATE]
# Extract the structured timeline the chronicle is written from.
# Run from the repository root. Emits a markdown digest to stdout.
#
# Optional arg SINCE_DATE (ISO date, e.g. 2026-06-23): when supplied, limits
# the "To narrate" section and the commits list to work after that date. The
# brief table is never filtered — it is the full timeline, newest last-touch
# first. Used by the closed-date incremental-run mechanism.
set -euo pipefail

BRIEFS_DIR="docs/briefs"
SINCE="${1:-}"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not inside a git repo." >&2; exit 1; }
[ -d "$BRIEFS_DIR" ] || { echo "No $BRIEFS_DIR — run from the repo root of a brief-workflow project." >&2; exit 1; }

# Markdown table cells cannot contain a raw pipe.
cell() { printf '%s' "$1" | tr '|' '/'; }

brief_title() {
  local t
  t=$(grep -m1 '^# ' "$1" 2>/dev/null | sed 's/^# //' || true)
  printf '%s' "${t:-—}"
}

# Overall token on the blc/1 line. planned if there is no ledger file.
# A ledger with no blc/1 line is no-line: the brief named planned only for a
# missing file, and inventing done/pending here would be a guess.
brief_status() {
  local ledger="$1" raw
  if [ ! -f "$ledger" ]; then
    printf '%s' "planned"
    return
  fi
  raw=$(grep -m1 'blc/1' "$ledger" 2>/dev/null || true)
  if [ -z "$raw" ]; then
    printf '%s' "no-line"
    return
  fi
  raw=$(printf '%s' "$raw" | tr -d '`')
  # Overall status is the token after the serial, up to the first N: phase
  # field. It can contain spaces (`done(commit 383ed5b)`). Splitting on
  # whitespace would truncate it.
  printf '%s' "$raw" | sed -E 's/^blc\/1[[:space:]]+#[0-9]+[[:space:]]+//; s/[[:space:]]+[0-9]+:.*$//'
}

brief_depends() {
  local dep
  dep=$(grep -m1 -oE 'Depends on:[^<]*' "$1" 2>/dev/null \
        | sed 's/Depends on://; s/\*//g; s/^[[:space:]]*//; s/[[:space:]]*$//' || true)
  printf '%s' "${dep:-—}"
}

echo "# Chronicle source digest"
echo
echo "Repo origin: $(git log --format='%aI · %h · %s' 2>/dev/null | tail -1)"
echo "Repo head:   $(git log -1 --format='%aI · %h · %s' 2>/dev/null)"
echo "Total commits: $(git rev-list --count HEAD 2>/dev/null || echo '?')"
if [ -n "$SINCE" ]; then
  echo "Incremental since: $SINCE  (prior eras already narrated; table is still complete)"
fi
echo

echo "## Briefs — newest last-touch first"
echo
echo "| serial | title | status | first | last | depends-on |"
echo "|---|---|---|---|---|---|"

tmp=$(mktemp)
for d in "$BRIEFS_DIR"/[0-9][0-9][0-9][0-9]-*/ ; do
  [ -d "$d" ] || continue
  # `git log | head -1` takes SIGPIPE once git writes past the first line, which
  # under `set -o pipefail` plus `set -e` kills this script mid-loop. tail consumes
  # its whole input, so nothing is left writing into a closed pipe.
  fcd=$(git log --format='%aI' -- "$d" 2>/dev/null | tail -1)
  lcd=$(git log -1 --format='%aI' -- "$d" 2>/dev/null || true)
  slug=$(basename "$d")
  last_key="${lcd:-0000-uncommitted}"
  first_disp="${fcd:-—}"
  last_disp="${lcd:-—}"
  printf '%s\t%s\t%s\t%s\t%s\n' "$last_key" "$slug" "$d" "$first_disp" "$last_disp" >> "$tmp"
done

if [ -s "$tmp" ]; then
  # Last-touch descending. Slug is the tie-break so the order is stable.
  sort -r -k1,1 -k2,2 "$tmp" | while IFS=$'\t' read -r _last_key slug d first_disp last_disp; do
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
echo

echo "## To narrate"
echo
if [ -s "$tmp" ]; then
  narrated=0
  # Read into an array so the empty-message count is not trapped in a pipe subshell.
  while IFS=$'\t' read -r _last_key slug d _first _last; do
    if [ -n "$SINCE" ]; then
      recent=$(git log --since="$SINCE" -1 --format='%aI' -- "$d" 2>/dev/null || true)
      [ -n "$recent" ] || continue
    fi
    echo "- ${slug}"
    if [ -f "${d}ledger.md" ]; then
      awk '/^## [Bb]ig decisions/{f=1;next} /^## /{f=0} f&&/^### /{sub(/^### /,"");print "    fork · "$0}' "${d}ledger.md"
    fi
    narrated=$((narrated + 1))
  done < <(sort -r -k1,1 -k2,2 "$tmp")
  if [ -n "$SINCE" ] && [ "$narrated" -eq 0 ]; then
    echo "- (no new briefs since $SINCE)"
  fi
else
  echo "- (no briefs)"
fi
echo

rm -f "$tmp"

echo "## Parked / considered — docs/briefs/_drafts"
if [ -d "$BRIEFS_DIR/_drafts" ]; then
  found=no
  for f in "$BRIEFS_DIR/_drafts"/*.md ; do
    [ -e "$f" ] || continue
    base=$(basename "$f"); [ "$base" = "README.md" ] && continue
    if [ -n "$SINCE" ]; then
      recent=$(git log --since="$SINCE" -1 --format='%aI' -- "$f" 2>/dev/null || true)
      [ -n "$recent" ] || continue
    fi
    echo "- ${base}: $(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')"
    found=yes
  done
  [ "$found" = no ] && echo "- (none since ${SINCE:-ever})"
else
  echo "- (no _drafts directory)"
fi
echo

echo "## Commits referencing a brief serial"
SINCE_FLAG=""
[ -n "$SINCE" ] && SINCE_FLAG="--since=$SINCE"
# shellcheck disable=SC2086
SERIALS=$(git log $SINCE_FLAG --format='%aI · %h · %s' 2>/dev/null | grep -E '#[0-9]{3,4}' || true)
if [ -z "$SERIALS" ]; then
  echo "(none found)"
else
  SERIAL_COUNT=$(printf '%s\n' "$SERIALS" | wc -l | tr -d ' ')
  # sed rather than `head -60`: sed reads its whole input, so nothing is left writing
  # into a closed pipe. See the SIGPIPE note in the briefs loop.
  printf '%s\n' "$SERIALS" | sed -n '1,60p'
  # The cap is a ceiling on digest size, but a history written from a silently
  # truncated source would be wrong without saying so. Name what was dropped.
  if [ "$SERIAL_COUNT" -gt 60 ]; then
    echo "(showing the 60 most recent of $SERIAL_COUNT — older commits omitted)"
  fi
fi
