#!/usr/bin/env bash
# tools/jira-csv.sh [--summary-file PATH] SERIAL [BRIEFS_DIR]
# Write one brief and its phases as a Jira Cloud CSV import. Writes to stdout.
#
# One Epic row for the brief, then one Task row per phase, in status-line order:
#
#   Summary      `#<serial> — <title>`, then `#<serial>/<letter> — <label>`
#   Work type    Epic, then Task
#   Work item ID 1 for the Epic, 2 onward for the phases. Jira uses it only to link rows
#                within this file; Parent names it.
#   Parent       empty for the Epic, 1 for each phase
#   Priority     always empty — see below
#   Assignee     the brief's `Owner`, or `Author` when there is no `Owner`
#   Reporter     the brief's `Author`. The same email as Assignee on a brief with no `Owner`.
#   Due Date     always empty — see below
#   Labels       `blc-<serial>`, the same on every row, so one JQL term finds the import
#   Components   always empty — see below
#   Status       the BLC state with its pointer dropped: `in-progress`, `done`, `skipped`.
#                Map them to the project's workflow on the importer's value-mapping screen.
#
# Priority, Due Date and Components are emitted empty because the record holds nothing for them:
# a brief has no priority, no due date and no component. The column is there so Jira shows the
# field and a person fills it in after the import. A default would put declared data in a file
# whose every other column is derived, and nothing in Jira would tell the two apart (#0027).
#   Description  for the Epic, the text of `--summary-file` when one is given, otherwise the
#                brief's `## The claim` text, then the brief's path. For a
#                Task, the ledger paragraph that starts `**<id> — <label>.**`, without that
#                lead, then the ledger's path. A missing text gives the path alone and a
#                warning on stderr. The text is converted from markdown to Jira wiki markup.
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

usage() {
  echo "usage: tools/jira-csv.sh [--summary-file PATH] SERIAL [BRIEFS_DIR]" >&2
  exit 1
}

# The Epic's Description, supplied by a caller that can write prose. A shell script cannot
# summarize, so the only way this file holds a summary is for something else to hand it over.
#
# A file and not an argument: a summary is several sentences of free prose, and passed as an
# argument it has to meet the shell's quoting rules. A newline or a quote in it would then be a
# defect in the caller rather than in this tool (#0028).
SUMMARY_FILE=""
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --summary-file) [ $# -ge 2 ] || usage; SUMMARY_FILE="$2"; shift 2 ;;
    --summary-file=*) SUMMARY_FILE="${1#*=}"; shift ;;
    --) shift; ARGS+=("$@"); break ;;
    -*) echo "jira-csv: unknown option \`$1\`" >&2; usage ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
set -- ${ARGS[@]+"${ARGS[@]}"}

[ $# -ge 1 ] && [ -n "$1" ] || usage
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

# Convert the markdown on stdin to Jira wiki markup. Jira Cloud's CSV importer reads a
# Description as wiki markup, not markdown, so `**bold**` would show its asterisks.
#
# Only what the record uses is converted: bold, italic, code, links, tables, headings, and
# wrapped lines. Anything else passes through as text.
#
# The lines of a paragraph are joined into one, because a wiki renderer shows each newline as a
# line break. Spans are converted after the join, since a code span or a bold run can wrap.
md_to_wiki() {
  awk '
    # Inside {{...}} the renderer still reads wiki formatting, so a code span that holds
    # `--max-age` would show struck through. A backslash makes the next character literal.
    function code_escape(s,   out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (index("*_{}[]|-+^~?", c)) out = out "\\"
        out = out c
      }
      return out
    }

    # Markdown italic is one asterisk, which wiki reads as bold, so italic is converted
    # first and bold is held aside until it is done.
    function emphasis(s,   out) {
      gsub(/\*\*/, "\001", s)
      out = ""
      while (match(s, /\*[^* \t][^*]*\*/) && substr(s, RSTART + RLENGTH - 2, 1) !~ /[ \t]/) {
        out = out substr(s, 1, RSTART - 1) "_" substr(s, RSTART + 1, RLENGTH - 2) "_"
        s = substr(s, RSTART + RLENGTH)
      }
      s = out s
      gsub("\001", "*", s)
      return s
    }

    # RSTART and RLENGTH are global, and the helpers called below run match() of their own,
    # so each loop copies them before it calls one.
    function plain(s,   out, t, p, start, len) {
      out = ""
      while (match(s, /\[[^]]*\]\([^)]*\)/)) {
        start = RSTART
        len = RLENGTH
        t = substr(s, start, len)
        p = index(t, "](")
        out = out emphasis(substr(s, 1, start - 1)) "[" emphasis(substr(t, 2, p - 2)) "|" substr(t, p + 2, length(t) - p - 2) "]"
        s = substr(s, start + len)
      }
      return out emphasis(s)
    }

    # A code span opens with a run of backticks and closes at the next run of the same
    # length. A run that never closes is text.
    function spans(s,   out, run, rest, i, j, code, start, len) {
      out = ""
      while (match(s, /`+/)) {
        start = RSTART
        len = RLENGTH
        run = substr(s, start, len)
        rest = substr(s, start + len)
        out = out plain(substr(s, 1, start - 1))
        j = 0
        for (i = 1; i <= length(rest) - length(run) + 1; i++) {
          if (substr(rest, i, length(run)) == run && substr(rest, i - 1, 1) != "`" && substr(rest, i + length(run), 1) != "`") { j = i; break }
        }
        if (j == 0) { out = out run; s = rest; continue }
        code = substr(rest, 1, j - 1)
        if (code ~ /^ .* $/) code = substr(code, 2, length(code) - 2)
        out = out "{{" code_escape(code) "}}"
        s = substr(rest, j + length(run))
      }
      return out plain(s)
    }

    function emit(s) { line[++n] = s }
    function flush() { if (para != "") emit(spans(para)); para = "" }

    # A header row is the first row of a table. Its cell bars double, except an escaped bar
    # inside code.
    function row(s, header,   inner, out, i, c) {
      inner = spans(substr(s, 2, length(s) - 2))
      if (!header) return "|" inner "|"
      out = ""
      for (i = 1; i <= length(inner); i++) {
        c = substr(inner, i, 1)
        out = out ((c == "|" && substr(inner, i - 1, 1) != "\\") ? "||" : c)
      }
      return "||" out "||"
    }

    { sub(/\r$/, "") }
    /^[ \t]*$/ { flush(); in_table = 0; emit(""); next }
    /^\|/ {
      flush()
      sub(/[ \t]+$/, "")
      if ($0 ~ /^\|[ \t:|-]*-[ \t:|-]*\|$/) next
      emit(row($0, !in_table))
      in_table = 1
      next
    }
    /^#+[ \t]/ {
      flush()
      in_table = 0
      match($0, /^#+/)
      level = RLENGTH
      text = substr($0, RLENGTH + 1)
      sub(/^[ \t]+/, "", text)
      emit("h" level ". " spans(text))
      next
    }
    /^[ \t]*([-*+]|[0-9]+\.)[ \t]/ {
      flush()
      in_table = 0
      para = $0
      sub(/^[ \t]+/, "", para)
      next
    }
    {
      in_table = 0
      text = $0
      sub(/^[ \t]+/, "", text)
      para = (para == "" ? text : para " " text)
    }
    END {
      flush()
      first = 1
      while (first <= n && line[first] == "") first++
      last = n
      while (last >= first && line[last] == "") last--
      for (i = first; i <= last; i++) {
        if (line[i] == "" && line[i - 1] == "") continue
        print line[i]
      }
    }'
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

# The person who filed the brief, which is not always the person who owns it. On a brief with no
# `Owner` this is the same email as the assignee, and that is the truth about such a brief rather
# than a duplicate to suppress.
#
# A bad `Author` warns and leaves the column empty, where a bad assignee dies. Jira requires an
# assignee to be resolvable and fills an empty `Reporter` with the importing user, so the two
# failures do not cost the same. Where there is no `Owner` the assignee check above has already
# read this field and refused, so this path is only reachable with an `Owner` present.
REPORTER=""
if AUTHOR=$(blc_identity_field "$IDENTITY" Author); then
  if printf '%s' "$AUTHOR" | grep -qE "$BLC_EMAIL_RE"; then
    REPORTER="$AUTHOR"
  else
    warn "#$SERIAL: Author '$AUTHOR' is not one email, so the Reporter column is empty"
  fi
else
  warn "#$SERIAL: the identity line has no Author, so the Reporter column is empty"
fi

# One label on the Epic and on every phase Task, so a single JQL term finds the whole import
# afterwards. The phase letter is deliberately not in it: a label per phase would fragment the
# one search this exists to make possible (#0027).
LABEL="blc-$SERIAL"

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
OUT=$(csv_row "Summary" "Work type" "Work item ID" "Parent" "Description" "Priority" \
              "Assignee" "Reporter" "Due Date" "Labels" "Components" "Status")
# A missing source is a thinner ticket, not a refusal: the path still says where the text is.
EPIC_DESC="$BRIEF"
if [ -n "$SUMMARY_FILE" ]; then
  # A refusal, not a fall-through. A caller that named a file meant to use it, and quietly
  # exporting the claim instead would put the wrong text on the Epic with nothing to show for it.
  [ -r "$SUMMARY_FILE" ] || die "cannot read the summary file $SUMMARY_FILE"
  SUMMARY="$(cat "$SUMMARY_FILE")"
  [ -n "${SUMMARY//[[:space:]]/}" ] || die "the summary file $SUMMARY_FILE is empty"
  # The claim is not read at all here, so a brief with two of them still exports: the ambiguity
  # that refusal protects against is gone once the caller has said which text to use.
  EPIC_DESC="$(printf '%s\n' "$SUMMARY" | md_to_wiki)"$'\n\n'"$BRIEF"
else
  rc=0
  CLAIM=$(brief_claim "$BRIEF") || rc=$?
  [ "$rc" -eq 2 ] && die "#$SERIAL: $BRIEF has two '## The claim' sections, so its summary is ambiguous"
  if [ -n "$CLAIM" ]; then
    EPIC_DESC="$(printf '%s\n' "$CLAIM" | md_to_wiki)"$'\n\n'"$BRIEF"
  else
    warn "#$SERIAL: $BRIEF has no '## The claim' text and no --summary-file, so the Epic's Description is its path only"
  fi
fi
OUT+=$'\n'$(csv_row "#$SERIAL — $TITLE" Epic 1 "" "$EPIC_DESC" "" \
                    "$ASSIGNEE" "$REPORTER" "" "$LABEL" "" "$BRIEF_STATE")

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
        task_desc="$(printf '%s\n' "$para" | md_to_wiki)"$'\n\n'"$LEDGER"
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
  OUT+=$'\n'$(csv_row "#$SERIAL/$idx — $label" Task "$id" 1 "$task_desc" "" \
                      "$ASSIGNEE" "$REPORTER" "" "$LABEL" "" "$state")
done < <(blc_status_phase_entries "$STATUS_LINE")

printf '%s\n' "$OUT"
