#!/usr/bin/env bash
# tools/read-record.sh — one structured reading of the record, as JSON.
#
#   read-record.sh snapshot [REV]     everything, one document
#   read-record.sh briefs             briefs and their phases
#   read-record.sh events [REV]       record events, newest first
#   read-record.sh declarations       who has claimed unfiled work
#   read-record.sh defects            the gate's own output, parsed
#   read-record.sh next               the next action each brief implies
#   read-record.sh me                 the current git identity
#
# REV is a git revision or a date. `--since REV` is accepted as the same thing.
#
# It reads. It never writes, fetches, or calls a forge.
#
# Published by #0039 phase b from the frozen bake-off instrument. The instrument had no
# tests and invented two states; both are addressed here. See
# docs/blc/briefs/0039-blic-console/ledger.md.
set -euo pipefail

# The libraries and the gate are found beside this script, not under the working directory.
# Resolving them against the cwd means the tool answers about whatever tree it was launched
# from, which is the defect #0024 was filed about, and it makes the tool untestable against
# a fixture that is not a copy of the whole toolkit.
# Parameter expansion rather than `dirname`, matching tests/run.sh.
RR_SELF_DIR="${BASH_SOURCE[0]%/*}"
[ "$RR_SELF_DIR" = "${BASH_SOURCE[0]}" ] && RR_SELF_DIR="."
RR_SELF_DIR="$(cd "$RR_SELF_DIR" && pwd)"

BLC_READ_ROOT="${BLC_READ_ROOT:-$(git rev-parse --show-toplevel)}"
cd "$BLC_READ_ROOT"
BRIEFS_DIR="${BLC_BRIEFS_DIR:-docs/blc/briefs}"
STATE_DIR="${BLC_STATE_DIR:-docs/blc/state}"

# The ledger locator and the phase tokenizer are the repository's own, not a second reading
# of the same files. A private copy here would be a sixth reader free to disagree with the
# tools that already share these — the defect #0013 was filed about.
# shellcheck source=/dev/null
. "$RR_SELF_DIR/lib/status-line.sh"
# shellcheck source=/dev/null
. "$RR_SELF_DIR/lib/phase-row.sh"
# shellcheck source=/dev/null
. "$RR_SELF_DIR/lib/identity-line.sh"

# ── JSON ─────────────────────────────────────────────────────────────────────
# Hand-rolled because this is shared by every reader of the record, and `jq` is not
# installed on every machine that runs this toolkit. It is absent on the machine that
# published this file.
jstr() {
  local s="${1-}"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
  printf '"%s"' "$s"
}
jbool() { [ "${1:-0}" = 1 ] && printf 'true' || printf 'false'; }

ME="$(git config user.email 2>/dev/null || true)"

# Split a state token into its state and its pointer: `done(PR#45)` is `done` and `PR#45`.
#
# The instrument split phase states and left brief states whole, so one document described
# the same shape two ways and every consumer had to know which level it was reading. The
# shared `blc_status_state` keeps the pointer on purpose, for callers that render it. This
# splits for the callers that do not, and `status_line` below still carries the raw line,
# so nothing the record holds is lost by the split.
#
# The pointer is cut at the LAST `)` rather than the first, because `done(commit 92a7168)`
# is a real state here and its pointer holds a space.
STATE_PART=""; POINTER_PART=""
split_state() {
  local tok="${1-}"
  STATE_PART="$tok"; POINTER_PART=""
  case "$tok" in
    *\(*\)) POINTER_PART="${tok#*(}"; POINTER_PART="${POINTER_PART%)}"
            STATE_PART="${tok%%(*}" ;;
  esac
}

# ── One brief ────────────────────────────────────────────────────────────────
emit_brief() {
  local dir="$1" slug serial brief ledger line title owner author created closed
  slug="$(basename "$dir")"
  serial="${slug%%-*}"
  brief="$dir/brief.md"
  ledger="$dir/ledger.md"

  title=""
  [ -f "$brief" ] && title="$(sed -n 's/^# //p' "$brief" | head -1)"
  [ -n "$title" ] || title="$slug"

  # The identity line is read through the shared reader, never parsed here.
  #
  # This was a local sed parser first, carried over from the bake-off instrument where it
  # was harmless because the instrument was not in tools/. In tools/ it is a second reader
  # of a line that is defined once, and tests/test_identity_line.sh caught it on the first
  # full run. The same argument as the status line above: one reader, or two that agree
  # until they do not.
  local identity=""
  owner=""; author=""; created=""
  if [ -f "$brief" ]; then
    identity="$(blc_identity_line "$brief" || true)"
    if [ -n "$identity" ]; then
      owner="$(blc_identity_field "$identity" "Owner" || true)"
      author="$(blc_identity_field "$identity" "Author" || true)"
      created="$(blc_identity_field "$identity" "Created" || true)"
    fi
  fi

  # Assignment is Owner, or Author when there is no Owner. Taken from the shared reader so
  # "mine" means in this surface exactly what it means to list-briefs.sh --owner.
  local assignee="" mine=0
  [ -n "$identity" ] && assignee="$(blc_identity_assignee "$identity" || true)"
  [ -n "$ME" ] && [ "$(printf '%s' "$assignee" | tr 'A-Z' 'a-z')" = "$(printf '%s' "$ME" | tr 'A-Z' 'a-z')" ] && mine=1

  # No invented states.
  #
  # The instrument reported `planned` for a brief with no ledger and `no-line` for a ledger
  # with no status line. Neither is in the five-state vocabulary at
  # docs/blc/briefs/README.md, and `tools/list-briefs.sh` invents the same two. That
  # disagreement between a tool and the document is one of the four findings #0039 was
  # filed about, so the published surface does not repeat it. `state` is empty when the
  # record does not say, and the two booleans below say why it is empty. A caller that
  # wants a word for the empty case chooses its own and owns it.
  local has_ledger=0 has_line=0
  line=""; closed=""
  if [ -f "$ledger" ]; then
    has_ledger=1
    line="$(blc_status_line "$ledger" || true)"
    [ -n "$line" ] && has_line=1
    closed="$(sed -n 's/^\*\*Closed:\*\* *//p' "$ledger" | head -1)"
  fi

  local state="" pointer=""
  if [ -n "$line" ]; then
    split_state "$(blc_status_state "$line")"
    state="$STATE_PART"; pointer="$POINTER_PART"
  fi

  local touched
  touched="$(git log -1 --format=%cI -- "$dir" 2>/dev/null || true)"

  printf '{'
  printf '"serial":%s,' "$(jstr "$serial")"
  printf '"slug":%s,' "$(jstr "$slug")"
  printf '"dir":%s,' "$(jstr "$dir")"
  printf '"title":%s,' "$(jstr "$title")"
  printf '"state":%s,' "$(jstr "$state")"
  printf '"pointer":%s,' "$(jstr "$pointer")"
  printf '"status_line":%s,' "$(jstr "$line")"
  printf '"owner":%s,' "$(jstr "$owner")"
  printf '"author":%s,' "$(jstr "$author")"
  printf '"assignee":%s,' "$(jstr "$assignee")"
  printf '"mine":%s,' "$(jbool "$mine")"
  printf '"created":%s,' "$(jstr "$created")"
  printf '"closed":%s,' "$(jstr "$closed")"
  printf '"touched":%s,' "$(jstr "$touched")"
  printf '"has_ledger":%s,' "$(jbool "$has_ledger")"
  printf '"has_status_line":%s,' "$(jbool "$has_line")"
  printf '"phases":['

  # Phase state comes from the status line, the label from the table. The two can disagree —
  # that disagreement is BRIEFS-9 and is one of the things a console exists to show — so both
  # are reported and neither is corrected here.
  local first=1 entry id rest label
  if [ -n "$line" ]; then
    while IFS= read -r entry; do
      [ -n "$entry" ] || continue
      id="${entry%%:*}"; rest="${entry#*:}"
      split_state "$rest"
      label=""
      [ "$has_ledger" = 1 ] && label="$(blc_phase_label "$id" "$ledger" 2>/dev/null || true)"
      [ "$first" = 1 ] || printf ','
      first=0
      printf '{"id":%s,"label":%s,"state":%s,"pointer":%s}' \
        "$(jstr "$id")" "$(jstr "$label")" "$(jstr "$STATE_PART")" "$(jstr "$POINTER_PART")"
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
# A `##` entry is a claim. The same reading orient.sh has used since #0037: a file with no
# entries claims nothing, whatever prose it holds.
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
# The gate's own output, parsed, not re-derived. A surface that computed its own idea of a
# defect would be a second validator for the first one to disagree with.
cmd_defects() {
  local out line first=1 clause kind subject message
  out="$(bash "$RR_SELF_DIR/validate-briefs.sh" "$BRIEFS_DIR" 2>&1 || true)"
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
    # The instrument pre-set `kind` from the paths here, before the subject case below. Every
    # branch of that case assigns `kind`, so the pre-set value was never read. Classifying
    # from paths happens once, in the fallback branch, where it is the answer rather than a
    # value waiting to be overwritten.
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

# ── Next action ──────────────────────────────────────────────────────────────
# The derivation lives here and not in a console.
#
# Prototype 2 of the #0039 bake-off built this in Go and then asked for it to be moved,
# against its own interest: three consoles each deriving an answer are three readers free
# to disagree about what a state means, which is the defect #0013 was filed about. One
# surface derives, every reader renders.
#
# The derivation is thin and says so. Five shapes are recognised. Everything else reports
# `none` and names the state rather than guessing, because a wrong next action is worse
# than no next action: the whole claim of #0039 is that a person trusts what this says.
emit_next_for() {
  local serial="$1" state="$2" closed="$3" has_ledger="$4" phases="$5" slug="$6"
  local action="" basis=""

  if [ "$has_ledger" = 0 ]; then
    action="blc-start-brief"
    basis="the serial is filed and has no ledger"
  elif [ "$state" = "done" ] && [ -z "$closed" ]; then
    action="blc-close-brief"
    basis="the status line says done and the ledger records no Closed date"
  elif [ "$state" = "deferred" ]; then
    # Parked on purpose, and the ledger says why. Telling somebody to act on a brief they
    # parked is the surface disagreeing with a decision already recorded.
    action="none"
    basis="the brief is deferred"
  elif [ -n "$phases" ]; then
    # `phases` arrives as `id:state:pointer` lines, in the status line's order.
    local id pstate pointer unfinished=0
    while IFS=: read -r id pstate pointer; do
      [ -n "$id" ] || continue
      case "$pstate" in
        in-progress)
          if [ -n "$pointer" ]; then
            action="blc-review-pr, then blc-commit-push-pr"
            basis="phase $id is in progress at $pointer"
          else
            action="blc-commit-push-pr"
            basis="phase $id is in progress and its status line names no branch"
          fi
          break ;;
        pending)
          action="blc-next-brief-phase"
          basis="phase $id is pending"
          break ;;
        deferred)
          action="none"
          basis="phase $id is deferred"
          break ;;
        done|skipped) ;;
        # A state outside the five-state vocabulary. The surface does not guess what it
        # meant, for the same reason it invents none of its own.
        *) unfinished=1 ;;
      esac
    done <<EOF
$phases
EOF
    # Only a phase list that is entirely done or skipped is finished. The first version of
    # this said "every phase is finished" whenever no phase matched a rule, so a deferred
    # brief — parked on purpose — was told to close, with a basis that was not true. A
    # wrong next action stated confidently is the failure this surface exists to avoid.
    if [ -z "$action" ] && [ "$unfinished" = 0 ] && [ "$state" != "done" ]; then
      action="blc-close-brief"
      basis="every phase is done or skipped and the brief is still open"
    fi
  fi

  if [ -z "$action" ]; then
    action="none"
    basis="no rule matches a brief in state '${state:-unknown}'"
  fi

  printf '{"serial":%s,"slug":%s,"action":%s,"basis":%s}' \
    "$(jstr "$serial")" "$(jstr "$slug")" "$(jstr "$action")" "$(jstr "$basis")"
}

cmd_next() {
  local dir slug serial ledger line state closed has_ledger phases first=1
  printf '['
  for dir in "$BRIEFS_DIR"/[0-9]*/; do
    dir="${dir%/}"
    [ -d "$dir" ] || continue
    slug="$(basename "$dir")"; serial="${slug%%-*}"
    ledger="$dir/ledger.md"
    has_ledger=0; line=""; closed=""; state=""; phases=""
    if [ -f "$ledger" ]; then
      has_ledger=1
      line="$(blc_status_line "$ledger" || true)"
      closed="$(sed -n 's/^\*\*Closed:\*\* *//p' "$ledger" | head -1)"
    fi
    if [ -n "$line" ]; then
      split_state "$(blc_status_state "$line")"
      state="$STATE_PART"
      local entry
      while IFS= read -r entry; do
        [ -n "$entry" ] || continue
        split_state "${entry#*:}"
        phases+="${entry%%:*}:$STATE_PART:$POINTER_PART"$'\n'
      done <<EOF
$(blc_status_phase_entries "$line")
EOF
    fi
    # A closed brief needs nothing. Reporting one would bury the briefs that do.
    if [ "$state" = "done" ] && [ -n "$closed" ]; then continue; fi
    [ "$first" = 1 ] || printf ','
    first=0
    emit_next_for "$serial" "$state" "$closed" "$has_ledger" "$phases" "$slug"
  done
  printf ']'
}

cmd_me() { printf '{"email":%s}' "$(jstr "$ME")"; }

# ── Snapshot ─────────────────────────────────────────────────────────────────
# The four heavy sections are gathered concurrently.
#
# The instrument ran them in series and cost about the sum: roughly 3.1s, of which the
# briefs scan alone was 1.9s and the gate 0.9s. They share no state and none reads
# another's output, so in parallel the document costs about the slowest one.
cmd_snapshot() {
  local since="${1:-}" tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/blc-read.XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" EXIT

  cmd_briefs       >"$tmp/briefs" &
  cmd_declarations >"$tmp/declarations" &
  cmd_defects      >"$tmp/defects" &
  cmd_events "$since" >"$tmp/events" &
  wait

  printf '{"generated":%s,"repo":%s,"me":' \
    "$(jstr "$(date -u +%Y-%m-%dT%H:%M:%SZ)")" "$(jstr "$BLC_READ_ROOT")"
  cmd_me
  printf ',"head":%s,"branch":%s,' \
    "$(jstr "$(git rev-parse --short HEAD)")" "$(jstr "$(git rev-parse --abbrev-ref HEAD)")"
  printf '"briefs":';       cat "$tmp/briefs"
  printf ',"declarations":'; cat "$tmp/declarations"
  printf ',"defects":';      cat "$tmp/defects"
  printf ',"events":';       cat "$tmp/events"
  printf '}\n'
}

usage() { sed -n '2,15p' "$0"; }

# ── Arguments ────────────────────────────────────────────────────────────────
# An unrecognised argument is an error, not a silent drop.
#
# The instrument shifted and then read `$2`, so `snapshot REV` discarded the revision and
# exited 0 while answering a different question, and `snapshot --since REV` worked only
# because the discarded token happened to sit where the read landed. A reader that
# silently answers a question nobody asked is the failure mode this brief is about.
# REV is set rather than printed, and the guard returns rather than exits.
#
# This was written first as `cmd_snapshot "$(rev_arg snapshot "$@")"`. An `exit` inside a
# command substitution ends the subshell, so the error reached stderr and the script then
# carried on and exited 0 — a reader that reports a problem and answers anyway. #0038
# records the same failure in the test suite. Keeping the parse in the current shell is
# what makes the non-zero exit real.
REV=""
parse_rev() {
  local cmd="$1"; shift
  [ "${1:-}" = "--since" ] && shift
  if [ "$#" -gt 1 ]; then
    printf 'read-record.sh: %s takes at most one revision, got: %s\n' "$cmd" "$*" >&2
    return 2
  fi
  REV="${1:-}"
}

cmd="${1:-snapshot}"
shift || true
case "$cmd" in
  snapshot)     parse_rev snapshot "$@" || exit 2; cmd_snapshot "$REV" ;;
  events)       parse_rev events "$@" || exit 2; cmd_events "$REV"; echo ;;
  briefs)       [ "$#" -eq 0 ] || { echo "read-record.sh: briefs takes no arguments" >&2; exit 2; }
                cmd_briefs; echo ;;
  declarations) [ "$#" -eq 0 ] || { echo "read-record.sh: declarations takes no arguments" >&2; exit 2; }
                cmd_declarations; echo ;;
  defects)      [ "$#" -eq 0 ] || { echo "read-record.sh: defects takes no arguments" >&2; exit 2; }
                cmd_defects; echo ;;
  next)         [ "$#" -eq 0 ] || { echo "read-record.sh: next takes no arguments" >&2; exit 2; }
                cmd_next; echo ;;
  me)           cmd_me; echo ;;
  -h|--help)    usage ;;
  *)            printf 'read-record.sh: unknown command: %s\n' "$cmd" >&2; usage >&2; exit 2 ;;
esac
