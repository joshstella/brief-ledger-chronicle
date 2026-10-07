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

BRIEFS_DIR="docs/blc/briefs"
SINCE="${1:-}"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not inside a git repo." >&2; exit 1; }

[ -d "$BRIEFS_DIR" ] || { echo "No $BRIEFS_DIR — run from the repo root of a brief-workflow project." >&2; exit 1; }
# The brief table comes from tools/list-briefs.sh — see the call sites below. It is
# located from the repository root rather than relative to this script, because the
# depth between the two differs by host: skills/ here, .cursor/skills/ or
# .claude/skills/ in an install target. The root is the one fixed point both share.
LIST_BRIEFS="$(git rev-parse --show-toplevel)/tools/list-briefs.sh"
[ -x "$LIST_BRIEFS" ] || { echo "Missing $LIST_BRIEFS — the chronicle reads the brief table from it." >&2; exit 1; }
# "New since the last chronicle" has to agree with the table's last-touch, or a commit the
# table ignores — #0017's move — would put every brief back in front of the narrator.
TOUCH_LIB="$(git rev-parse --show-toplevel)/tools/lib/touch-log.sh"
[ -r "$TOUCH_LIB" ] || { echo "Missing $TOUCH_LIB — the chronicle dates drafts with it." >&2; exit 1; }
# shellcheck source=/dev/null
. "$TOUCH_LIB"
SKIP="$(blc_touch_skip "$(dirname "$BRIEFS_DIR")/ignore-revs")"
RENAMES="$(blc_touch_renames)"
# git parses the date, so this does not depend on which `date` the host has. It prints
# `--max-age=<unix time>`.
#
# The marker is a day, and everything on that day is already narrated. git reads a bare date
# as that day at the current time of day, so the cutoff moved with the hour of the run: a
# morning run re-listed the marked day's afternoon. A bare date therefore ends at midnight.
CUTOFF=0
if [ -n "$SINCE" ]; then
  case "$SINCE" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      CUTOFF="$(git rev-parse --since="$SINCE 23:59:59")"
      CUTOFF=$(( ${CUTOFF#--max-age=} + 1 ))
      ;;
    *)
      CUTOFF="$(git rev-parse --since="$SINCE")"
      CUTOFF="${CUTOFF#--max-age=}"
      ;;
  esac
fi

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
  while IFS=$'\t' read -r last_key slug d _first _last; do
    if [ -n "$SINCE" ] && [ "$last_key" -lt "$CUTOFF" ]; then
      continue
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

echo "## Parked / considered — docs/blc/briefs/_drafts"
if [ -d "$BRIEFS_DIR/_drafts" ]; then
  found=no
  for f in "$BRIEFS_DIR/_drafts"/*.md ; do
    [ -e "$f" ] || continue
    base=$(basename "$f"); [ "$base" = "README.md" ] && continue
    if [ -n "$SINCE" ]; then
      recent=$(blc_touch_log "$SKIP" "$RENAMES" "$f" | sed -n '1s/ .*//p')
      [ -n "$recent" ] && [ "$recent" -ge "$CUTOFF" ] || continue
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
[ -n "$SINCE" ] && SINCE_FLAG="--max-age=$CUTOFF"
# `--grep` reads the whole message rather than the subject. A trunk that merges instead of
# squashing never carries the serial in a subject: git writes "Merge branch ..." there and the
# title the commit skill composed lands in the body. Matching `%s` alone found nothing on such
# a trunk, so the digest reported a history with no brief work in it and the chronicle written
# from it was silently empty (#0030).
#
# Each commit is one record, split on \001, and only the serials from the body are folded onto
# the subject's line — not the body itself. That keeps every record on one line, so the 60-line
# ceiling below still counts commits, and keeps a long message out of the digest.
#
# A serial is exactly four digits, which `docs/blc/briefs/README.md` defines and this reads back
# out. Three digits used to match too, and that is what let a PR number in: the forge writes
# "(#134)" into a subject and the body of a merge commit names the PRs it closes. Reading the
# whole message would have widened that. Four digits also keeps working past brief #1000, where
# a rule written on the leading zero would start dropping serials in silence — the failure this
# brief is about. It still matches a four-digit PR number, once this forge reaches one.
# shellcheck disable=SC2086
SERIALS=$(git log $SINCE_FLAG -E --grep='#[0-9]{4}([^0-9]|$)' --format='%x01%aI · %h · %s%n%b' 2>/dev/null \
  | awk '
      # No apostrophe anywhere in this program: it is held inside single quotes, so one in a
      # comment ends the quoting and the shell reads the rest of it as code.
      BEGIN { RS = "\001" }
      NR > 1 {
        nl = index($0, "\n")
        head = nl ? substr($0, 1, nl - 1) : $0
        body = nl ? substr($0, nl + 1) : ""
        # The serials the subject already shows. Held as comma-terminated tokens rather than
        # searched for as substrings, because the subject writes the serial as "[#0001]".
        seen = ""
        h = head
        while (match(h, /#[0-9][0-9]*/)) {
          seen = seen substr(h, RSTART, RLENGTH) ","
          h = substr(h, RSTART + RLENGTH)
        }
        out = ""
        while (match(body, /#[0-9][0-9]*/)) {
          s = substr(body, RSTART, RLENGTH)
          # `#` and four digits. The digits are matched greedily and measured, because an exact
          # length written as an interval is not supported by every awk this suite runs on.
          # `--grep` already dropped the commits with no serial at all; this is what stops a
          # PR number in the body of an ordinary commit being folded in beside its serial.
          if (RLENGTH == 5 && index(seen, s ",") == 0) { seen = seen s ","; out = out " " s }
          body = substr(body, RSTART + RLENGTH)
        }
        print head out
      }' || true)
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
