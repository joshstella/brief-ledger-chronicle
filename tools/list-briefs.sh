#!/usr/bin/env bash
# tools/list-briefs.sh [--tsv | --owner EMAIL] [BRIEFS_DIR]
# Emit the brief timeline, newest last-touch first.
# Run from the repository root. Writes to stdout.
#
#   default  markdown table — header row, separator, one row per brief, and
#            nothing else, so a caller can put it under whatever heading it likes
#   --tsv    the sorted scan behind that table, one brief per line:
#            <unix-last-touch> <slug> <dir> <first-iso> <last-iso>, tab separated
#   --owner  the table, with only the briefs assigned to EMAIL that are not done or
#            skipped. Assigned means `Owner`, or `Author` when there is no `Owner`, compared
#            without regard to case. A malformed `Owner` is reported on stderr. This reads
#            the working tree and does not fetch: the blc-my-briefs skill does that first.
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
OWNER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) MODE=tsv; shift ;;
    --owner)
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "error: --owner needs an email" >&2; exit 1; }
      OWNER="$2"; shift 2 ;;
    --) shift; break ;;
    -*) echo "error: unknown option $1" >&2; exit 1 ;;
    *) break ;;
  esac
done
BRIEFS_DIR="${1:-docs/blc/briefs}"
# The scan behind --tsv feeds the chronicle, which narrates every brief. A filtered scan
# would be a second "which briefs" for it to disagree with.
if [ "$MODE" = tsv ] && [ -n "$OWNER" ]; then
  echo "error: --owner filters the table; it does not apply to --tsv" >&2
  exit 1
fi

# The status-line locator is shared with open-briefs.sh, so it lives in lib/. Symlinks are
# resolved first: `dirname "$BASH_SOURCE"` reports the directory this was *reached* through,
# and a link on a PATH directory would send it looking for lib/ beside the link. This
# bootstrap is the one thing that cannot be shared — it is the code that finds the shared
# code — so it is duplicated in open-briefs.sh on purpose.
# Kept character-identical to open-briefs.sh's copy apart from the exit status, which each
# tool documents for itself, and the library list. Two copies that drift are worse than two
# copies: review found this one had already lost a comment and swapped printf for echo,
# while the ledger claimed both tools "gained the same bootstrap".
BLC_SELF="${BASH_SOURCE[0]}"
BLC_HOPS=0
while [ -L "$BLC_SELF" ]; do
  BLC_HOPS=$((BLC_HOPS + 1))
  if [ "$BLC_HOPS" -gt 40 ]; then
    printf 'error: too many symbolic links resolving %s\n' "${BASH_SOURCE[0]}" >&2
    exit 1
  fi
  BLC_SELF_DIR="$(cd -P "$(dirname "$BLC_SELF")" && pwd)"
  BLC_SELF="$(readlink "$BLC_SELF")"
  # A relative link target is relative to the directory holding the link, not to $PWD.
  case "$BLC_SELF" in
    /*) ;;
    *) BLC_SELF="$BLC_SELF_DIR/$BLC_SELF" ;;
  esac
done
BLC_LIB_DIR="$(cd -P "$(dirname "$BLC_SELF")" && pwd)/lib"
for BLC_LIB in status-line identity-line touch-log; do
  if [ ! -r "$BLC_LIB_DIR/$BLC_LIB.sh" ]; then
    printf 'error: cannot read %s\n' "$BLC_LIB_DIR/$BLC_LIB.sh" >&2
    exit 1
  fi
  . "$BLC_LIB_DIR/$BLC_LIB.sh"
done

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
  # Shared with open-briefs.sh. This used to search unanchored, which returned a prose
  # sentence for a ledger that quoted an example status line above its own.
  raw=$(blc_status_line "$1" || true)
  if [ -z "$raw" ]; then
    printf '%s' "no-line"
    return
  fi
  # Shared with validate-briefs.sh since BRIEFS-11, which asks the same question of the
  # same token. The reasoning about why this is not a positional read moved with it.
  blc_status_state "$raw"
}

# The `Depends on` value from the identity line, or `—`. Read through the shared reader so
# this column shows exactly what BRIEFS-6 checks, never prose that mentions the field.
brief_depends() {
  local identity dep=""
  identity=$(blc_identity_line "$1" || true)
  [ -n "$identity" ] && dep=$(blc_identity_field "$identity" "Depends on" || true)
  printf '%s' "${dep:-—}"
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# The email a brief is assigned to, by the shared rule in lib/identity-line.sh. A brief whose
# assignee is malformed is reported and assigned to no one. Reported here, not in
# validate-briefs.sh, because a typo makes "mine" come back empty and look like an answer
# (#0007 decision 6).
# usage: brief_assignee <brief.md> <serial>; prints the email or returns 1
brief_assignee() {
  local identity email rc=0
  identity=$(blc_identity_line "$1") || return 1
  email=$(blc_identity_assignee "$identity") || rc=$?
  case "$rc" in
    0) printf '%s' "$email" ;;
    2) printf '%s: %s is not an email, so the brief is assigned to no one\n' "$2" "$email" >&2
       return 1 ;;
    *) return 1 ;;
  esac
}

# A brief is assigned while it is not finished: planned, no-line, in-progress, deferred.
# blc/1 states can carry a pointer, as in `done(commit 383ed5b)`.
is_closed() {
  case "$1" in
    done|done[\(\ ]*|skipped|skipped[\(\ ]*) return 0 ;;
    *) return 1 ;;
  esac
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Beside the briefs directory, like every other path orient.sh derives from it. See
# lib/touch-log.sh for what belongs in it.
SKIP=$(blc_touch_skip "$(dirname "$BRIEFS_DIR")/ignore-revs")
RENAMES=$(blc_touch_renames)

for d in "$BRIEFS_DIR"/[0-9][0-9][0-9][0-9]-*/ ; do
  [ -d "$d" ] || continue
  touches=$(blc_touch_log "$SKIP" "$RENAMES" "$d")
  # `sed -n` and not `head -1`: head closes the pipe early, and under `set -o pipefail`
  # plus `set -e` the SIGPIPE kills this script mid-loop. sed and tail read all their input.
  # %at is the sort key. %aI is display. String-sorting %aI mis-orders two
  # last-touches that differ only by timezone offset.
  touch_line=$(printf '%s\n' "$touches" | sed -n '1p')
  first_line=$(printf '%s\n' "$touches" | tail -1)
  slug=$(basename "$d")
  if [ -n "$touch_line" ]; then
    last_key="${touch_line%% *}"
    last_disp="${touch_line#* }"
  else
    last_key=0
    last_disp=—
  fi
  first_disp="${first_line#* }"
  first_disp="${first_disp:-—}"
  printf '%s\t%s\t%s\t%s\t%s\n' "$last_key" "$slug" "$d" "$first_disp" "$last_disp" >> "$tmp"
done

# Last-touch descending (unix author time). Slug is the tie-break so the order is stable.
if [ "$MODE" = tsv ]; then
  [ -s "$tmp" ] && sort -k1,1nr -k2,2r "$tmp"
  exit 0
fi

echo "| serial | title | status | first | last | depends-on |"
echo "|---|---|---|---|---|---|"

rows=""
if [ -s "$tmp" ]; then
  rows=$(sort -k1,1nr -k2,2r "$tmp" | while IFS=$'\t' read -r _last_key slug d first_disp last_disp; do
    serial="#${slug%%-*}"
    status=$(brief_status "${d}ledger.md")
    if [ -n "$OWNER" ]; then
      ! is_closed "$status" || continue
      assignee=$(brief_assignee "${d}brief.md" "$serial") || continue
      [ "$(lower "$assignee")" = "$(lower "$OWNER")" ] || continue
    fi
    title=$(brief_title "${d}brief.md")
    dep=$(brief_depends "${d}brief.md")
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$(cell "$serial")" "$(cell "$title")" "$(cell "$status")" \
      "$(cell "$first_disp")" "$(cell "$last_disp")" "$(cell "$dep")"
  done)
fi
if [ -n "$rows" ]; then
  printf '%s\n' "$rows"
else
  echo "| — | — | — | — | — | — |"
fi
