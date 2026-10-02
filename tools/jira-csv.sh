#!/usr/bin/env bash
# tools/jira-csv.sh SERIAL [BRIEFS_DIR]
# Write one brief and its phases as a Jira Cloud CSV import. Writes to stdout.
#
# One Epic row for the brief, then one Task row per phase, in status-line order:
#
#   Work type    Epic, then Task
#   Summary      `#<serial> — <title>`, then `#<serial>/<letter> — <label>`
#   Work item ID 1 for the Epic, 2 onward for the phases. Jira uses it only to link rows
#                within this file; Parent names it.
#   Parent       empty for the Epic, 1 for each phase
#   Assignee     the brief's `Owner`, or `Author` when there is no `Owner`
#   Status       the BLC state with its pointer dropped: `in-progress`, `done`, `skipped`.
#                Map them to the project's workflow on the importer's value-mapping screen.
#   Description  the path of the brief, then of the ledger
#
# A one-shot seed, not a sync (#0007, "d becomes a CSV export"). Importing the same file
# twice makes two Epics, so a brief whose identity line already carries a Jira key is
# refused. After the import, put the Epic key in the brief's `Jira:` field.
#
# Exits 1, writing nothing to stdout, when the brief cannot be exported as it stands: no
# such serial, a Jira key already present, an assignee that is not one email, a ledger that
# is not blc/2, or a phase whose label cannot be read. A partial import is worse than none.
set -euo pipefail

if [ $# -lt 1 ] || [ -z "$1" ]; then
  echo "usage: tools/jira-csv.sh SERIAL [BRIEFS_DIR]" >&2
  exit 1
fi
SERIAL_ARG="$1"
BRIEFS_DIR="${2:-docs/blc/briefs}"

# The bootstrap walk below is kept character-identical to open-briefs.sh's copy; see the
# comment there and tests/test_clauses.sh.
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
for BLC_LIB in status-line identity-line phase-row; do
  if [ ! -r "$BLC_LIB_DIR/$BLC_LIB.sh" ]; then
    printf 'error: cannot read %s\n' "$BLC_LIB_DIR/$BLC_LIB.sh" >&2
    exit 1
  fi
  . "$BLC_LIB_DIR/$BLC_LIB.sh"
done

die() {
  printf 'jira-csv: %s\n' "$1" >&2
  exit 1
}

[ -d "$BRIEFS_DIR" ] || die "no $BRIEFS_DIR — run from the repo root of a brief-workflow project"

# `7`, `0007` and `#0007` all name the same brief. Base 10 is forced so `0008` is not octal.
SERIAL_NUM="${SERIAL_ARG#\#}"
case "$SERIAL_NUM" in
  ''|*[!0123456789]*) die "'$SERIAL_ARG' is not a serial" ;;
esac
SERIAL=$(printf '%04d' "$((10#$SERIAL_NUM))")

DIRS=()
for d in "$BRIEFS_DIR/$SERIAL"-*/; do
  [ -d "$d" ] && DIRS+=("$d")
done
[ "${#DIRS[@]}" -gt 0 ] || die "no brief #$SERIAL in $BRIEFS_DIR"
[ "${#DIRS[@]}" -eq 1 ] || die "#$SERIAL names ${#DIRS[@]} brief folders in $BRIEFS_DIR"
BRIEF="${DIRS[0]}brief.md"
LEDGER="${DIRS[0]}ledger.md"
[ -r "$BRIEF" ] || die "#$SERIAL has no $BRIEF"
[ -r "$LEDGER" ] || die "#$SERIAL has no ledger, so it has no phases to export"

TITLE=$(sed -n 's/^# //p' "$BRIEF" | head -1)
[ -n "$TITLE" ] || die "#$SERIAL: $BRIEF has no title line"

IDENTITY=$(blc_identity_line "$BRIEF") || die "#$SERIAL: $BRIEF has no identity line"

# A blank field or `—` is the template saying "none yet", not a key.
if JIRA=$(blc_identity_field "$IDENTITY" Jira); then
  case "$JIRA" in
    ''|—) ;;
    *) die "#$SERIAL is already in Jira as $JIRA; a second import would duplicate it" ;;
  esac
fi

rc=0
ASSIGNEE=$(blc_identity_assignee "$IDENTITY") || rc=$?
case "$rc" in
  0) ;;
  2) die "#$SERIAL: $ASSIGNEE is not one email, so the export would assign it to no one" ;;
  *) die "#$SERIAL: the identity line has no Owner or Author" ;;
esac

# The locator prints nothing and still succeeds when there is no line.
STATUS_LINE=$(blc_status_line "$LEDGER" || true)
[ -n "$STATUS_LINE" ] || die "#$SERIAL: $LEDGER has no status line"
case "$STATUS_LINE" in
  blc/2\ *) ;;
  *) die "#$SERIAL: the status line is not blc/2, and only blc/2 has lettered phases" ;;
esac
# blc/2 states carry no spaces, so the brief's state is the third field. Its pointer goes, as
# a phase's does: `done(PR#45)` would be one more value to map for every brief.
read -r _schema _serial BRIEF_STATE _rest <<<"$STATUS_LINE"
BRIEF_STATE="${BRIEF_STATE%%(*}"

# A phase the gate would complain about is a phase this export would silently drop.
UNPARSED=$(blc_status_unparsed_entries "$STATUS_LINE")
[ -z "$UNPARSED" ] || die "#$SERIAL: the status line has entries that are not phases: $(printf '%s' "$UNPARSED" | tr '\n' ' ')"

# Every field is quoted and an embedded quote is doubled (RFC 4180), so a title with a
# comma or a quote stays one field.
csv_row() {
  local sep="" f
  for f in "$@"; do
    printf '%s"%s"' "$sep" "${f//\"/\"\"}"
    sep=","
  done
  printf '\n'
}

# Built whole before any of it is printed: a refusal at the last phase must not leave the
# first rows in the caller's file looking like an export.
OUT=$(csv_row "Work type" "Summary" "Work item ID" "Parent" "Assignee" "Status" "Description")
OUT+=$'\n'$(csv_row Epic "#$SERIAL — $TITLE" 1 "" "$ASSIGNEE" "$BRIEF_STATE" "$BRIEF")

id=1
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  idx="${entry%%:*}"
  case "$idx" in
    *[!"$BLC_LOWER"]*) die "#$SERIAL: phase $idx is numbered, and only blc/2 letters are exported" ;;
  esac
  state="${entry#*:}"
  state="${state%%(*}"
  rc=0
  label=$(blc_phase_label "$idx" "$LEDGER") || rc=$?
  case "$rc" in
    0) ;;
    2) die "#$SERIAL: more than one row in $LEDGER could be phase $idx" ;;
    *) die "#$SERIAL: no row in $LEDGER gives phase $idx a label, or the cell after its id is a state" ;;
  esac
  id=$((id + 1))
  OUT+=$'\n'$(csv_row Task "#$SERIAL/$idx — $label" "$id" 1 "$ASSIGNEE" "$state" "$LEDGER")
done < <(blc_status_phase_entries "$STATUS_LINE")

printf '%s\n' "$OUT"
