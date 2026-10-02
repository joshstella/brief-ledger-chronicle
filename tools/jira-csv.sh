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
#   Description  for the Epic, the brief's `## The claim` text, then the brief's path. For a
#                Task, the ledger paragraph that starts `**<id> — <label>.**`, without that
#                lead, then the ledger's path. A missing text gives the path alone and a
#                warning on stderr. The text is copied as written.
#
# A one-shot seed, not a sync (#0007, "d becomes a CSV export"). Importing the same file
# twice makes two Epics, so a brief whose identity line already carries a Jira key is
# refused. After the import, put the Epic key in the brief's `Jira:` field.
#
# Exits 1, writing nothing to stdout, when the brief cannot be exported as it stands: no
# such serial, a Jira key already present, an assignee that is not one email, a ledger that
# is not blc/2, a phase whose label cannot be read, or a brief or phase with two texts that
# could be its description. A partial import is worse than none.
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

warn() {
  printf 'jira-csv: warning: %s\n' "$1" >&2
}

# Print the text of the brief's `## The claim` section, without the blank lines at either end.
# Returns 2 when the brief has two such sections: either could be the summary, and the export
# does not pick one.
brief_claim() {
  awk '
    /^## / {
      inside = ($0 ~ /^## The claim[ \t]*$/)
      if (inside) n++
      next
    }
    inside { line[++k] = $0 }
    END {
      if (n > 1) exit 2
      first = 1
      while (first <= k && line[first] ~ /^[ \t]*$/) first++
      last = k
      while (last >= first && line[last] ~ /^[ \t]*$/) last--
      for (i = first; i <= last; i++) print line[i]
    }' "$1"
}

# Print the ledger paragraph that describes phase `$1`, labelled `$2`, without its bold lead.
# Returns 1 when no paragraph starts with the phase id, 2 when two do, and 3 when the one that
# does names a label other than `$2`.
#
# The id and label reach awk through the environment. A `-v` value has its backslashes
# interpreted, and a label is free text.
phase_paragraph() {
  JC_ID_LEAD="**$1 — " JC_FULL_LEAD="**$1 — $2.**" awk '
    BEGIN { id_lead = ENVIRON["JC_ID_LEAD"]; full_lead = ENVIRON["JC_FULL_LEAD"] }
    index($0, id_lead) == 1 {
      n++
      if (n > 1) exit 2
      if (index($0, full_lead) != 1) { mismatch = 1; next }
      rest = substr($0, length(full_lead) + 1)
      sub(/^[ \t]+/, "", rest)
      if (rest != "") text = rest
      inside = 1
      next
    }
    inside && /^[ \t]*$/ { inside = 0 }
    inside { text = (text == "" ? $0 : text "\n" $0) }
    END {
      if (n > 1) exit 2
      if (n == 0) exit 1
      if (mismatch) exit 3
      if (text != "") print text
    }' "$3"
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
# A missing source is a thinner ticket, not a refusal: the path still says where the text is.
rc=0
CLAIM=$(brief_claim "$BRIEF") || rc=$?
[ "$rc" -eq 2 ] && die "#$SERIAL: $BRIEF has two '## The claim' sections, so its summary is ambiguous"
EPIC_DESC="$BRIEF"
if [ -n "$CLAIM" ]; then
  EPIC_DESC="$CLAIM"$'\n\n'"$BRIEF"
else
  warn "#$SERIAL: $BRIEF has no '## The claim' text, so the Epic's Description is its path only"
fi
OUT+=$'\n'$(csv_row Epic "#$SERIAL — $TITLE" 1 "" "$ASSIGNEE" "$BRIEF_STATE" "$EPIC_DESC")

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
  rc=0
  para=$(phase_paragraph "$idx" "$label" "$LEDGER") || rc=$?
  task_desc="$LEDGER"
  case "$rc" in
    0)
      if [ -n "$para" ]; then
        task_desc="$para"$'\n\n'"$LEDGER"
      else
        warn "#$SERIAL/$idx: the paragraph for phase $idx in $LEDGER is empty, so the Task's Description is its path only"
      fi
      ;;
    1) warn "#$SERIAL/$idx: no paragraph in $LEDGER starts with **$idx — $label.**, so the Task's Description is its path only" ;;
    2) die "#$SERIAL: more than one paragraph in $LEDGER starts with **$idx — **, so the description of phase $idx is ambiguous" ;;
    3) warn "#$SERIAL/$idx: the paragraph for phase $idx in $LEDGER does not carry the label '$label', so the Task's Description is its path only" ;;
    *) die "#$SERIAL: could not read the paragraph for phase $idx in $LEDGER" ;;
  esac
  id=$((id + 1))
  OUT+=$'\n'$(csv_row Task "#$SERIAL/$idx — $label" "$id" 1 "$ASSIGNEE" "$state" "$task_desc")
done < <(blc_status_phase_entries "$STATUS_LINE")

printf '%s\n' "$OUT"
