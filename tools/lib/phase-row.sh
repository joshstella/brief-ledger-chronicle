# The phase-row matcher, defined once.
#
# Sourced, never invoked: no shebang, no execute bit. `tools/lib/` is the directory
# whose name carries that meaning, and `tests/test_source_tree.sh` exempts it from the
# executable-mode rule on that basis alone.
#
# `open-briefs.sh` reads this today, and it is the only reader. `validate-briefs.sh`
# joins in #0014 phase `b`, when BRIEFS-9 gives it a reason to look at a phase table;
# it has none before that, and an unused import would have cost phase `a` the
# no-behaviour-change property that made it reviewable.
#
# There is one definition because #0013's second defect was two readers disagreeing
# about where the status line lives, and a second independent copy would reproduce that
# defect on purpose. Nothing may re-derive it locally — see `tests/test_phase_row.sh`,
# which plants a copy in front of its own scan to prove the scan can still see one.
#
# Function names are prefixed `blc_`. This file is sourced into tools that already have
# globals of their own, and an unprefixed helper is one collision away from being
# silently replaced by whichever definition is read last.

# Build the extended-regex that could match the phase row for `$1`.
#
# Deliberately not a full table parse: three schemas are in use across the existing
# ledgers, and a scan for the token survives all three where a column index does not.
#
# One matcher serves both index alphabets, because the shapes overlap. A phase row
# writes its id one of three ways:
#
#   | a | the row scan | done |         the id alone in the first cell
#   | `a — the row scan` | done |       id and label em-dashed into one cell
#   | `brief/0001-x` | phase 1 of it |  the id in prose, numeric schema only
#
# The first two are anchored to the first cell and are what `blc-start-brief` writes.
# The third cannot be anchored: #0009 left the numeric scan loose for install targets
# that put the id elsewhere, and a test pins that latitude. It is *added* to the
# numeric pattern, never substituted for the anchored form — the two-column shape and
# the prose shape both occur, and matching only one of them is how this broke.
blc_phase_row_pattern() {
  # Local, because a caller's loop variable named `pattern` is otherwise this
  # function's return value.
  local idx="$1" pattern
  pattern="^\|[[:space:]]*~*\`?${idx}[[:space:]]*(\||—)"
  case "$idx" in
    [0-9]*) pattern="${pattern}|^\|.*phase ${idx} " ;;
  esac
  printf '%s' "$pattern"
}

# Emit every line of `$2` that could be the phase row for id `$1`, `grep -n` style.
#
# Every candidate is returned rather than the first. Callers decide what to do with
# them; the reason they get all of them is recorded at each call site, because the
# reporter and the gate want different things from the same list.
blc_phase_row_find() {
  grep -nE "$(blc_phase_row_pattern "$1")" "$2"
}

# Print the label of letter phase `$1` from the phase table in ledger `$2`. Returns 1 when no
# row gives a label, and 2 when more than one row could be the phase's.
#
# The one column this file reads, because a Jira summary is `#<serial>/<letter> — <label>`
# (docs/blc/briefs/README.md, "Phase ids") and the label exists nowhere else. Only the two shapes
# `blc-start-brief` writes are read: the label in the cell after the id, or after the em dash
# in the id's own cell. A third shape, or two candidate rows, returns non-zero rather than a
# guess: a wrong label is a ticket summary that the next export cannot match.
blc_phase_label() {
  local idx="$1" rows line cell label
  case "$idx" in
    ""|*[!abcdefghijklmnopqrstuvwxyz]*) return 1 ;;
  esac
  rows=$(blc_phase_row_find "$idx" "$2") || return 1
  [ "$(printf '%s\n' "$rows" | grep -c .)" -eq 1 ] || return 2
  line="${rows#*:|}"
  cell="${line%%|*}"
  cell="${cell//\`/}"
  cell="${cell//\~/}"
  cell="${cell#"${cell%%[! ]*}"}"
  cell="${cell%"${cell##*[! ]}"}"
  if [ "$cell" = "$idx" ]; then
    label="${line#*|}"
    label="${label%%|*}"
    # A table with no label column puts the status here. A state is never a label, and taking
    # it would name a ticket `#0001/a — done`.
    local state trimmed="${label#"${label%%[! ]*}"}"
    trimmed="${trimmed%"${trimmed##*[! ]}"}"
    for state in pending in-progress deferred done skipped planned; do
      case "$trimmed" in
        "$state"|"$state("*|"$state ("*) return 1 ;;
      esac
    done
  else
    # Any spacing before the dash, because the matcher allows any: a row the gate counts as
    # the phase must not be one the export refuses.
    cell="${cell#"$idx"}"
    cell="${cell#"${cell%%[! ]*}"}"
    case "$cell" in
      —*) label="${cell#—}" ;;
      *) return 1 ;;
    esac
  fi
  label="${label//\`/}"
  label="${label//\~/}"
  label="${label#"${label%%[! ]*}"}"
  label="${label%"${label##*[! ]}"}"
  [ -n "$label" ] || return 1
  printf '%s' "$label"
}

# ── What counts as a phase entry in a status line ────────────────────────────
#
# Shared for the same reason the matcher above is shared, and it was forked before it was
# shared. #0014 phase `c` gave the gate a shape filter that `open-briefs.sh` did not have,
# and review found the two disagreeing on `bc:in-progress(feature/x)`: the reporter saw a
# live phase `bc` and the gate did not see it at all. That is the exact defect this brief
# exists to close, committed inside the phase that closes it — because the *matcher* was
# shared and nobody noticed the *tokenizer* was a second reader of the same line.
#
# `docs/blc/briefs/README.md`, "Phase ids", is the rule: a phase has one id, and the index is a
# letter. `blc/1` numbered them instead, and six ledgers here still do.
# Spelled out rather than `[a-z]` / `[0-9]`. A bracket *range* in a shell `case` follows the
# locale's collation order, and under many UTF-8 locales `[a-z]` also accepts `B` through
# `Z`. This function decides which ids a published Contract clause examines, so its alphabet
# must not depend on the environment variable of whoever runs CI.
BLC_LOWER='abcdefghijklmnopqrstuvwxyz'
BLC_DIGIT='0123456789'

blc_is_phase_index() {
  case "$1" in
    '') return 1 ;;
    ["$BLC_LOWER"]) return 0 ;;
    *[!"$BLC_DIGIT"]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Emit the phase entries of a status line, one per line, each whole: `id:state(pointer)`.
#
# `set -f` matters and is not defensive habit. A status line is data read out of a file this
# toolkit did not write, and `for token in $1` globs: with files named `q:done` and
# `z:pending` in the working directory, a status line containing a bare `*` made the gate
# report two phases the ledger never mentioned, naming a directory the reader cannot see.
blc_status_phase_entries() {
  local token id had_f=0
  case "$-" in *f*) had_f=1 ;; esac
  set -f
  for token in $1; do
    case "$token" in *:*) id="${token%%:*}" ;; *) continue ;; esac
    blc_is_phase_index "$id" && printf '%s\n' "$token"
  done
  [ "$had_f" -eq 1 ] || set +f
}

# Emit the tokens that are shaped like a phase entry but whose id is not a phase index.
#
# Split out rather than folded into the function above, because the two callers want
# opposite things from the same tokens: the reporter skips what it cannot parse, and the
# gate complains about it. A malformed id that both tools silently dropped would be a phase
# declared in the record and looked for by nobody, which is the silence `BRIEFS-9` exists to
# break.
#
# "Shaped like a phase entry" is narrower than "contains a colon", and the difference is the
# whole judgement here. `bc:in-progress(feature/x)` is someone writing a phase id wrong, and
# staying quiet about it is the failure. `2026-01-01T00:00:00Z` is a timestamp — digits and
# colons, matching no intent to declare a phase — and complaining about it would be noise in
# a clause whose credibility depends on being worth reading. So the id must be all lowercase
# letters to qualify as a wrong phase id; anything else is not a phase entry at all.
blc_status_unparsed_entries() {
  local token id had_f=0
  case "$-" in *f*) had_f=1 ;; esac
  set -f
  for token in $1; do
    case "$token" in *:*) id="${token%%:*}" ;; *) continue ;; esac
    blc_is_phase_index "$id" && continue
    case "$id" in
      '' | *[!"$BLC_LOWER"]*) ;;
      *) printf '%s\n' "$token" ;;
    esac
  done
  [ "$had_f" -eq 1 ] || set +f
}
