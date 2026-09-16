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
