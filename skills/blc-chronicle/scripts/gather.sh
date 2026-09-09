#!/usr/bin/env bash
# blc-chronicle/scripts/gather.sh [SINCE_DATE]
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
# The brief table comes from tools/list-briefs.sh — see the call sites below. It is
# located from the repository root rather than relative to this script, because the
# depth between the two differs by host: skills/ here, .cursor/skills/ or
# .claude/skills/ in an install target. The root is the one fixed point both share.
LIST_BRIEFS="$(git rev-parse --show-toplevel)/tools/list-briefs.sh"
[ -x "$LIST_BRIEFS" ] || { echo "Missing $LIST_BRIEFS — the chronicle reads the brief table from it." >&2; exit 1; }

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
# The chronicle is one of the table's two consumers, so it does not own it.
bash "$LIST_BRIEFS" "$BRIEFS_DIR"
echo

# Same scan, same order as the table above.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
bash "$LIST_BRIEFS" --tsv "$BRIEFS_DIR" > "$tmp"

echo "## To narrate"
echo
if [ -s "$tmp" ]; then
  narrated=0
  # Process substitution, not a pipe, so narrated is not trapped in a subshell.
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
  done < "$tmp"
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
