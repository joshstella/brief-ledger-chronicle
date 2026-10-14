#!/usr/bin/env bash
# experiments/blic/read.sh — the frozen read surface for the #0039 bake-off.
#
#   read.sh snapshot            everything a console needs, one JSON document
#   read.sh events [--since X]  record events only, newest first (X: git revision or date)
#   read.sh me                  the current git identity
#
# THIS IS AN INSTRUMENT, NOT A DELIVERABLE. It exists so five prototypes are compared on
# what they show rather than on whether they parse a ledger correctly. It has no tests,
# nothing installs it, and it does not go to main. If a prototype wins, the read surface it
# needs is built properly under the normal gates. See docs/blc/briefs/0039-blic-console/.
#
# Frozen for the duration of the bake-off: a prototype that changes it is comparing itself
# against a different instrument than the other four.
#
# It reads the record only. It never writes, fetches, or calls a forge.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
BRIEFS_DIR="docs/blc/briefs"
STATE_DIR="docs/blc/state"

# The ledger locator and the phase tokenizer are the repository's own, not a second reading
# of the same files. A private copy here would be a sixth reader free to disagree with the
# five tools that already share these — the defect #0013 was filed about.
# shellcheck source=/dev/null
. tools/lib/status-line.sh
# shellcheck source=/dev/null
. tools/lib/phase-row.sh

# ── JSON ─────────────────────────────────────────────────────────────────────
# Hand-rolled because the instrument must run with nothing installed. `jq` is a reasonable
# dependency for a prototype and is not a reasonable dependency for the thing all five share.
jstr() {
  local s="${1-}"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
  printf '"%s"' "$s"
}
jbool() { [ "${1:-0}" = 1 ] && printf 'true' || printf 'false'; }

ME="$(git config user.email 2>/dev/null || true)"

# ── One brief ────────────────────────────────────────────────────────────────
# Identity fields come from the brief body, state from the ledger. A brief with no ledger is
# a filed serial nobody has started, and it is reported rather than skipped: that is the
# window the project rules call invisible to every ledger.
emit_brief() {
  local dir="$1" slug serial brief ledger line state title owner author created closed
  slug="$(basename "$dir")"
  serial="${slug%%-*}"
  brief="$dir/brief.md"
  ledger="$dir/ledger.md"

  title=""
  [ -f "$brief" ] && title="$(sed -n 's/^# //p' "$brief" | head -1)"
  [ -n "$title" ] || title="$slug"

  # `**Owner:**` and `**Author:**` sit on the identity line, which is one line with ` · `
  # separators. Read by name rather than by position: the line's field order has changed
  # across the 39 briefs here and a positional read returns the neighbour.
  owner=""; author=""; created=""
  if [ -f "$brief" ]; then
    owner="$(sed -n 's/.*\*\*Owner:\*\* *\([^·]*\).*/\1/p' "$brief" | head -1)"
    author="$(sed -n 's/.*\*\*Author:\*\* *\([^·]*\).*/\1/p' "$brief" | head -1)"
    created="$(sed -n 's/.*\*\*Created:\*\* *\([^ ·]*\).*/\1/p' "$brief" | head -1)"
  fi
  owner="$(printf '%s' "$owner" | sed 's/[[:space:]]*$//')"
  author="$(printf '%s' "$author" | sed 's/[[:space:]]*$//')"

  # Assignment is Owner, or Author when there is no Owner. The same rule list-briefs.sh
  # uses for --owner, so "mine" means one thing in this repository.
  local assignee mine=0
  assignee="${owner:-$author}"
  [ -n "$ME" ] && [ "$(printf '%s' "$assignee" | tr 'A-Z' 'a-z')" = "$(printf '%s' "$ME" | tr 'A-Z' 'a-z')" ] && mine=1

  line=""; state="planned"; closed=""
  if [ -f "$ledger" ]; then
    line="$(blc_status_line "$ledger" || true)"
    if [ -n "$line" ]; then state="$(blc_status_state "$line")"; else state="no-line"; fi
    closed="$(sed -n 's/^\*\*Closed:\*\* *//p' "$ledger" | head -1)"
  fi

  local touched
  touched="$(git log -1 --format=%cI -- "$dir" 2>/dev/null || true)"

  printf '{'
  printf '"serial":%s,' "$(jstr "$serial")"
  printf '"slug":%s,' "$(jstr "$slug")"
  printf '"dir":%s,' "$(jstr "$dir")"
  printf '"title":%s,' "$(jstr "$title")"
  printf '"state":%s,' "$(jstr "$state")"
  printf '"status_line":%s,' "$(jstr "$line")"
  printf '"owner":%s,' "$(jstr "$owner")"
  printf '"author":%s,' "$(jstr "$author")"
  printf '"assignee":%s,' "$(jstr "$assignee")"
  printf '"mine":%s,' "$(jbool "$mine")"
  printf '"created":%s,' "$(jstr "$created")"
  printf '"closed":%s,' "$(jstr "$closed")"
  printf '"touched":%s,' "$(jstr "$touched")"
  printf '"has_ledger":%s,' "$(jbool "$([ -f "$ledger" ] && echo 1 || echo 0)")"
  printf '"phases":['

  # Phase state comes from the status line, the label from the table. The two can disagree —
  # that disagreement is BRIEFS-9 and is one of the things a console exists to show — so both
  # are reported and neither is corrected here.
  local first=1 entry id rest pstate pointer label
  if [ -n "$line" ]; then
    while IFS= read -r entry; do
      [ -n "$entry" ] || continue
      id="${entry%%:*}"; rest="${entry#*:}"
      pointer=""; pstate="$rest"
      case "$rest" in
        *\(*\)) pointer="${rest#*(}"; pointer="${pointer%)}"; pstate="${rest%%(*}" ;;
      esac
      label=""
      [ -f "$ledger" ] && label="$(blc_phase_label "$id" "$ledger" 2>/dev/null || true)"
      [ "$first" = 1 ] || printf ','
      first=0
      printf '{"id":%s,"label":%s,"state":%s,"pointer":%s}' \
        "$(jstr "$id")" "$(jstr "$label")" "$(jstr "$pstate")" "$(jstr "$pointer")"
    done <<EOF
$(blc_status_phase_entries "$line")
EOF
  fi
  printf ']}'
}

cmd_briefs() {
  local dir first=1
  printf '['
  for dir in "$BRIEFS_DIR"/[0-9]*/; do
    dir="${dir%/}"
    [ -d "$dir" ] || continue
    [ "$first" = 1 ] || printf ','
    first=0
    emit_brief "$dir"
  done
  printf ']'
}

# ── Declarations ─────────────────────────────────────────────────────────────
# A `##` entry is a claim. Same reading orient.sh uses since #0037: a file with no entries
# claims nothing, whatever prose it holds.
cmd_declarations() {
  local f first=1 who claims touched
  printf '['
  for f in "$STATE_DIR"/*.md; do
    [ -f "$f" ] || continue
    who="$(basename "$f" .md)"
    [ "$who" = "README" ] && continue
    claims="$(sed -n 's/^## //p' "$f")"
    [ -n "$claims" ] || continue
    touched="$(git log -1 --format=%cI -- "$f" 2>/dev/null || true)"
    [ "$first" = 1 ] || printf ','
    first=0
    printf '{"who":%s,"mine":%s,"touched":%s,"claims":[' \
      "$(jstr "$who")" "$(jbool "$([ "$who" = "$ME" ] && echo 1 || echo 0)")" "$(jstr "$touched")"
    local c cfirst=1
    while IFS= read -r c; do
      [ -n "$c" ] || continue
      [ "$cfirst" = 1 ] || printf ','
      cfirst=0
      jstr "$c"
    done <<EOF
$claims
EOF
    printf ']}'
  done
  printf ']'
}

# ── Defects ──────────────────────────────────────────────────────────────────
# The gate's own output, parsed, not re-derived. A console that computed its own idea of a
# defect would be a second validator for the first one to disagree with.
cmd_defects() {
  local out line first=1 clause kind subject message
  out="$(bash tools/validate-briefs.sh "$BRIEFS_DIR" 2>&1 || true)"
  printf '['
  while IFS= read -r line; do
    case "$line" in
      BRIEFS-*) ;;
      *) continue ;;
    esac
    clause="${line%% *}"
    kind="${line#*[}"; kind="${kind%%]*}"
    message="${line#*] }"
    subject="${message%%:*}"
    message="${message#*: }"
    [ "$first" = 1 ] || printf ','
    first=0
    printf '{"clause":%s,"kind":%s,"subject":%s,"message":%s}' \
      "$(jstr "$clause")" "$(jstr "$kind")" "$(jstr "$subject")" "$(jstr "$message")"
  done <<EOF
$out
EOF
  printf ']'
}

# ── Events ───────────────────────────────────────────────────────────────────
# Derived from git, because git is where "what changed that I did not do" already lives and
# a second event log would be a record to keep in step with the record.
#
# Classification reads the commit subject and the paths. The subject shapes are the ones
# blc-commit-push-pr and blc-close-brief write, so a hand-made commit falls through to
# "record" rather than being guessed at.
cmd_events() {
  local since="${1:-}" range=() first=1
  if [ -n "$since" ]; then
    if git rev-parse --verify --quiet "$since" >/dev/null 2>&1; then range=("$since..HEAD")
    else range=("--since=$since"); fi
  else
    range=("-n" "40")
  fi
  printf '['
  local rec sha when who subject kind serial phase files
  while IFS=$'\x1f' read -r sha when who subject; do
    [ -n "$sha" ] || continue
    files="$(git show --name-only --format= "$sha" 2>/dev/null || true)"
    case "$files" in
      *docs/blc/*) ;;
      *) kind="code" ;;
    esac
    serial=""; phase=""
    case "$subject" in
      \[#[0-9]*)
        kind="phase"
        rec="${subject#\[#}"; rec="${rec%%]*}"
        serial="$(printf '%s' "$rec" | tr -dc '0-9')"
        phase="$(printf '%s' "$rec" | tr -dc 'a-z')" ;;
      # The first `#` in the subject, not the last. A squashed commit ends with the PR
      # number — `docs: close #0038 (derived contract lists) (#157)` — and a greedy match
      # reports the brief as #157.
      docs:\ close\ \#*)
        kind="close"
        serial="$(printf '%s' "$subject" | sed -n 's/^[^#]*#\([0-9][0-9]*\).*/\1/p')" ;;
      docs:\ file\ \#*)
        kind="filed"
        serial="$(printf '%s' "$subject" | sed -n 's/^[^#]*#\([0-9][0-9]*\).*/\1/p')" ;;
      *)
        case "$files" in
          *docs/blc/state/*) kind="declaration" ;;
          *docs/blc/briefs/*) kind="record" ;;
          *) kind="code" ;;
        esac ;;
    esac
    [ "$first" = 1 ] || printf ','
    first=0
    printf '{"sha":%s,"when":%s,"who":%s,"mine":%s,"kind":%s,"serial":%s,"phase":%s,"subject":%s}' \
      "$(jstr "${sha:0:8}")" "$(jstr "$when")" "$(jstr "$who")" \
      "$(jbool "$([ "$who" = "$ME" ] && echo 1 || echo 0)")" \
      "$(jstr "$kind")" "$(jstr "$serial")" "$(jstr "$phase")" "$(jstr "$subject")"
  done <<EOF
$(git log "${range[@]}" --format="%H%x1f%cI%x1f%ae%x1f%s" 2>/dev/null || true)
EOF
  printf ']'
}

cmd_me() { printf '{"email":%s}' "$(jstr "$ME")"; }

cmd_snapshot() {
  printf '{"generated":%s,"repo":%s,"me":' \
    "$(jstr "$(date -u +%Y-%m-%dT%H:%M:%SZ)")" "$(jstr "$REPO_ROOT")"
  cmd_me
  printf ',"head":%s,"branch":%s,' \
    "$(jstr "$(git rev-parse --short HEAD)")" "$(jstr "$(git rev-parse --abbrev-ref HEAD)")"
  printf '"briefs":'; cmd_briefs
  printf ',"declarations":'; cmd_declarations
  printf ',"defects":'; cmd_defects
  printf ',"events":'; cmd_events "${1:-}"
  printf '}\n'
}

case "${1:-snapshot}" in
  snapshot) shift || true; cmd_snapshot "${2:-}" ;;
  briefs)   cmd_briefs; echo ;;
  events)   shift || true; [ "${1:-}" = "--since" ] && shift; cmd_events "${1:-}"; echo ;;
  declarations) cmd_declarations; echo ;;
  defects)  cmd_defects; echo ;;
  me)       cmd_me; echo ;;
  -h|--help) sed -n '2,10p' "$0" ;;
  *) echo "read.sh: unknown command: $1" >&2; exit 2 ;;
esac
