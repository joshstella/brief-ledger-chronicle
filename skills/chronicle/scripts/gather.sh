#!/usr/bin/env bash
# chronicle/scripts/gather.sh [SINCE_DATE]
# Extract the structured timeline the chronicle is written from.
# Run from the repository root. Emits a markdown digest to stdout.
#
# Optional arg SINCE_DATE (ISO date, e.g. 2026-06-23): when supplied, emits only
# briefs that have at least one commit after that date and limits the commits
# section to the same window. Used by the closed-date incremental-run mechanism.
set -euo pipefail

BRIEFS_DIR="docs/briefs"
SINCE="${1:-}"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not inside a git repo." >&2; exit 1; }
[ -d "$BRIEFS_DIR" ] || { echo "No $BRIEFS_DIR — run from the repo root of a brief-workflow project." >&2; exit 1; }

echo "# Chronicle source digest"
echo
echo "Repo origin: $(git log --format='%aI · %h · %s' 2>/dev/null | tail -1)"
echo "Repo head:   $(git log -1 --format='%aI · %h · %s' 2>/dev/null)"
echo "Total commits: $(git rev-list --count HEAD 2>/dev/null || echo '?')"
if [ -n "$SINCE" ]; then
  echo "Incremental since: $SINCE  (prior eras already narrated)"
fi
echo

echo "## Briefs — ordered by git first-commit date (authoritative chronology)"
echo
tmp=$(mktemp)
for d in "$BRIEFS_DIR"/[0-9][0-9][0-9][0-9]-*/ ; do
  [ -d "$d" ] || continue
  # `git log | head -1` takes SIGPIPE once git writes past the first line, which
  # under `set -o pipefail` plus `set -e` kills this script mid-loop. tail consumes
  # its whole input, so nothing is left writing into a closed pipe.
  fcd=$(git log --format='%aI' -- "$d" 2>/dev/null | tail -1)
  # In incremental mode, skip briefs with no commits after the cutoff date.
  if [ -n "$SINCE" ]; then
    recent=$(git log --since="$SINCE" -1 --format='%aI' -- "$d" 2>/dev/null)
    [ -n "$recent" ] || continue
  fi
  printf '%s\t%s\n' "${fcd:-0000-uncommitted}" "$d" >> "$tmp"
done
if [ -s "$tmp" ]; then
  sort "$tmp" | while IFS=$'\t' read -r fcd d; do
    slug=$(basename "$d")
    lcd=$(git log -1 --format='%aI' -- "$d" 2>/dev/null)
    cnt=$(git log --oneline -- "$d" 2>/dev/null | wc -l | tr -d ' ')
    ledger="planned"; [ -f "${d}ledger.md" ] && ledger="executed"
    # A brief with no `Depends on:` line is ordinary, not an error — grep returning 1
    # for it must not end the run. Without the guard, `pipefail` carries that 1 out of
    # the substitution and `set -e` kills the script mid-loop, with empty stderr and a
    # digest that stops after the first brief. Same shape as the SIGPIPE case above:
    # a benign non-zero inside a pipeline, fatal by default.
    dep=$(grep -m1 -oE 'Depends on:[^<]*' "${d}brief.md" 2>/dev/null \
          | sed 's/Depends on://; s/\*//g; s/^[[:space:]]*//; s/[[:space:]]*$//' || true)
    echo "- ${slug}"
    echo "    first ${fcd}  ·  last ${lcd}  ·  ${cnt} commits  ·  ${ledger}  ·  depends-on: ${dep:-—}"
    if [ -f "${d}ledger.md" ]; then
      awk '/^## [Bb]ig decisions/{f=1;next} /^## /{f=0} f&&/^### /{sub(/^### /,"");print "    fork · "$0}' "${d}ledger.md"
    fi
  done
else
  echo "- (no new briefs since $SINCE)"
fi
rm -f "$tmp"
echo

echo "## Parked / considered — docs/briefs/_drafts"
if [ -d "$BRIEFS_DIR/_drafts" ]; then
  found=no
  for f in "$BRIEFS_DIR/_drafts"/*.md ; do
    [ -e "$f" ] || continue
    base=$(basename "$f"); [ "$base" = "README.md" ] && continue
    # In incremental mode, only surface drafts touched after the cutoff.
    if [ -n "$SINCE" ]; then
      recent=$(git log --since="$SINCE" -1 --format='%aI' -- "$f" 2>/dev/null)
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
