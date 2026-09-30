#!/usr/bin/env bash
# Test runner for install.sh and the Contract validator.
#
# Usage: bash tests/run.sh [name-filter]
#
# No framework and no dependencies — see tests/README.md for the reasoning.

# Parameter expansion rather than `dirname`, so this line survives a PATH holding no coreutils.
# The matrix's own tests set PATH to a directory of stub awks and nothing else, which is the
# only way to ask "what does discovery do when gawk is absent" on a machine that has gawk.
BLC_SELF_DIR="${BASH_SOURCE[0]%/*}"
[ "$BLC_SELF_DIR" = "${BASH_SOURCE[0]}" ] && BLC_SELF_DIR="."
REPO_ROOT="$(cd "$BLC_SELF_DIR/.." && pwd)"
TESTS_DIR="$REPO_ROOT/tests"

# Read before the matrix, because the driver passes it down to each inner run. Losing this
# assignment does not fail: an unset FILTER makes the selection pattern `**`, every run becomes
# a full run, and the driver tests spawn matrices of matrices until the machine is out of
# processes. The suite stays green the whole way down.
FILTER="${1:-}"

# ── The awk matrix ───────────────────────────────────────────────────────────
#
# tools/lib/status-line.sh decides BRIEFS-10, and awk implementations disagree in ways that
# are quiet rather than loud. mawk matches an interval expression minimally where gawk matches
# it maximally — `a{2,3}` against `aaaa` gives RLENGTH 2 under mawk and 3 under gawk — so a
# length computation returns a smaller number instead of failing. One interpreter cannot see
# that.
#
# The list is fixed and not overridable. A list that could be narrowed at run time is the same
# move as not testing, which is what Contract promotion criterion 1 forbids.
BLC_AWK_CANDIDATES="awk gawk mawk original-awk busybox"

# Discovery uses shell builtins and the candidate binaries only — no sed, grep, awk, mktemp, or
# dirname. That is what lets a test set PATH to a directory it controls and get an answer about
# the directory rather than about the machine.
# `</dev/null` for the same reason the busybox probe below carries it: an awk that does not
# know --version falls through to reading a program from stdin, and the suite hangs with no
# output and no failure. Reproduced with a stub. The hazard was written down beside the busybox
# probe and not here, which is how one of two adjacent calls ends up guarded.
blc_awk_version() {
  { "$@" --version </dev/null 2>&1 || true; } | { IFS= read -r line || true; printf '%s' "$line"; }
}

# One line per candidate: "<name>\t<path>\t<applet>\t<version>", or "<name>\tnot-found\t\t".
# Every candidate appears. An absent interpreter is a line, never a silence.
#
# The applet is a separate field rather than being glued onto the path. busybox is invoked as
# two words, and folding that into one string means the path can no longer be quoted, so an awk
# living under a directory with a space in its name produces a shim that splits mid-path.
blc_awk_discover() {
  local name path ver
  for name in $BLC_AWK_CANDIDATES; do
    path="$(command -v "$name" 2>/dev/null)" || path=""
    if [ -z "$path" ]; then
      printf '%s\tnot-found\t\t\n' "$name"
      continue
    fi
    if [ "$name" = busybox ]; then
      # busybox is one binary holding many applets; only the awk applet is in scope, and a
      # busybox built without it is not an awk we found. The probe reads an empty program from
      # /dev/null, so it cannot block on a terminal and has no side effects.
      "$path" awk '' </dev/null >/dev/null 2>&1 || { printf 'busybox\tnot-found\t\t\n'; continue; }
      ver="$(blc_awk_version "$path" awk)"
      printf 'busybox\t%s\tawk\t%s\n' "$path" "${ver:-(version unknown)}"
      continue
    fi
    ver="$(blc_awk_version "$path")"
    printf '%s\t%s\t\t%s\n' "$name" "$path" "${ver:-(version unknown)}"
  done
}

# Builds the run plan from discovery: which interpreters run, in order, and which names are
# aliases of one already in the list. The driver below reads these arrays and adds nothing, so
# there is one implementation of "what the matrix is" rather than a planner and a runner that
# can disagree — the defect #0014 spent four phases removing.
blc_awk_plan() {
  MATRIX_DISPLAY=(); MATRIX_NAMES=(); MATRIX_PATHS=(); MATRIX_APPLETS=(); MATRIX_VERS=()
  MISSING=""
  local seen rest m_name m_path m_applet m_ver m_key
  seen=$'\n'
  # Split by hand rather than with `IFS=<tab> read -r a b c d`. Tab is IFS whitespace, so that
  # form collapses runs of tabs and an empty applet field silently shifts the version left into
  # it — which made every version read empty, disabled the dedupe, and reported three
  # interpreters where there are two. Parameter expansion preserves empty fields exactly.
  while IFS= read -r rest; do
    [ -n "$rest" ] || continue
    m_name="${rest%%$'\t'*}";   rest="${rest#*$'\t'}"
    m_path="${rest%%$'\t'*}";   rest="${rest#*$'\t'}"
    m_applet="${rest%%$'\t'*}"; m_ver="${rest#*$'\t'}"
    if [ "$m_path" = "not-found" ]; then
      MISSING="$MISSING $m_name"
      continue
    fi
    # Two names for one implementation are one interpreter. `awk` is usually a link to gawk or
    # mawk, and running the same program twice would inflate the matrix into a claim it does
    # not earn. The alias is still reported, because "awk resolves to gawk here" is the fact a
    # reader needs and is not derivable from the list of names.
    #
    # The key is the version string, not the path. /usr/bin/awk and /usr/bin/gawk are distinct
    # paths naming one implementation, and resolving the link would need `readlink` — an
    # external binary, which would break the property that this answers questions about a PATH
    # a test controls. Two binaries reporting the same version are the same awk; if the version
    # is unknown they are assumed distinct, because merging on ignorance would drop a run while
    # reporting a wider matrix than ran.
    #
    # The seen-set is newline-delimited. It was `%`-delimited, and a version string containing
    # `%` then collided with an unrelated one and collapsed two real implementations into one
    # run. `m_ver` comes from a single `read -r` and so cannot contain a newline, which makes
    # this delimiter impossible to forge rather than merely unlikely.
    m_key="$m_ver"
    case "$m_key" in
      ''|'(version unknown)') m_key="path:$m_path $m_applet" ;;
    esac
    case "$seen" in
      *$'\n'"$m_key"$'\n'*) MATRIX_DISPLAY+=("$m_name (alias)"); continue ;;
    esac
    seen="$seen$m_key"$'\n'
    MATRIX_DISPLAY+=("$m_name")
    MATRIX_NAMES+=("$m_name")
    MATRIX_PATHS+=("$m_path")
    MATRIX_APPLETS+=("$m_applet")
    MATRIX_VERS+=("$m_ver")
  done <<EOF
$(blc_awk_discover)
EOF
}

blc_awk_print_matrix() {
  echo ""
  echo "awk matrix"
  echo "=========="
  local n
  for n in ${MATRIX_DISPLAY+"${MATRIX_DISPLAY[@]}"}; do printf '  %s\n' "$n"; done
  [ -z "$MISSING" ] || printf '  not found:%s\n' "$MISSING"
}

# Exits 2 with a reason rather than reporting success over an empty matrix. "No check exists"
# must not read as "the check passed", which is the rule the Contract states for clauses and
# applies just as well to the runner that decides them.
blc_awk_require_one() {
  [ "${#MATRIX_NAMES[@]}" -gt 0 ] && return 0
  echo ""
  echo "error: no awk found on PATH — the suite cannot run" >&2
  exit 2
}

# Plan, report, refuse — in that order, from one place. The planner and the driver both need
# all three, and writing the sequence twice gives a guard two code paths to be deleted from
# independently: a mutation that removes it from one leaves the other printing the same refusal,
# so the suite stays green over a runner that no longer refuses anything.
blc_awk_prepare() {
  blc_awk_plan
  blc_awk_print_matrix
  blc_awk_require_one
}

if [ "${1:-}" = "--interpreters" ]; then
  blc_awk_discover
  exit 0
fi

# Prints the plan and exits without running anything. This is the seam the matrix's own tests
# use for the planning half: it reaches the dedupe and the labelling on a PATH the test built,
# and needs no binary beyond bash and the candidate stubs. The driver is tested separately,
# against a PATH whose first entry shadows every real awk.
if [ "${1:-}" = "--matrix-plan" ]; then
  blc_awk_prepare
  for i in "${!MATRIX_NAMES[@]}"; do
    printf 'run %s/%s: %s\t%s\t%s\t%s\n' \
      "$((i + 1))" "${#MATRIX_NAMES[@]}" "${MATRIX_NAMES[$i]}" \
      "${MATRIX_PATHS[$i]}" "${MATRIX_APPLETS[$i]}" "${MATRIX_VERS[$i]}"
  done
  exit 0
fi

# BLC_AWK_INNER marks the inner run and is set only by the driver below. It is not a way to
# select interpreters: it suppresses the matrix entirely, which is why it is named for what it
# is rather than for an awk. Setting it by hand runs one pass under whatever `awk` PATH gives,
# which is useful while developing and is not a matrix run — nothing prints a matrix summary,
# so the output cannot be mistaken for one. BLC_AWK_VERSION travels with it and is what the
# inner suite checks itself against.
if [ -z "${BLC_AWK_INNER:-}" ]; then
  blc_awk_prepare

  MATRIX_SHIM="$(mktemp -d)"
  trap 'rm -rf "$MATRIX_SHIM"' EXIT
  MATRIX_FAILED=""
  MATRIX_TOTAL="${#MATRIX_NAMES[@]}"
  for i in "${!MATRIX_NAMES[@]}"; do
    mkdir -p "$MATRIX_SHIM/$i"
    # %q quotes the path, so an awk under a directory with a space in its name still produces
    # one word. The applet is unquoted and empty for everything but busybox.
    printf '#!/bin/sh\nexec %s %s "$@"\n' \
      "$(printf '%q' "${MATRIX_PATHS[$i]}")" "${MATRIX_APPLETS[$i]}" > "$MATRIX_SHIM/$i/awk"
    chmod +x "$MATRIX_SHIM/$i/awk"

    echo ""
    echo "── run $((i + 1))/$MATRIX_TOTAL: ${MATRIX_NAMES[$i]} — ${MATRIX_VERS[$i]}"
    # The version is handed to the inner run so the inner run can check that the shim gave it
    # the interpreter this line just named. Without that check the driver can execute one awk
    # while reporting another, and every test still passes — a green report that is evidence of
    # something which did not happen.
    PATH="$MATRIX_SHIM/$i:$PATH" \
      BLC_AWK_INNER="${MATRIX_NAMES[$i]}" BLC_AWK_VERSION="${MATRIX_VERS[$i]}" \
      bash "$REPO_ROOT/tests/run.sh" "$FILTER" \
      || MATRIX_FAILED="$MATRIX_FAILED ${MATRIX_NAMES[$i]}"
  done

  echo ""
  if [ -n "$MATRIX_FAILED" ]; then
    echo "awk matrix: FAILED under$MATRIX_FAILED (of $MATRIX_TOTAL)"
    exit 1
  fi
  printf 'awk matrix: %s interpreter(s) passed' "$MATRIX_TOTAL"
  [ -z "$MISSING" ] || printf ', not found:%s' "$MISSING"
  echo ""
  exit 0
fi

# install.sh's project mode gates on git, gh, node, npm and claude being on PATH.
# Only git is actually used by anything it does, and `claude` cannot be installed on
# a CI runner at all — so the suite supplies inert stubs for the other four and lets
# the real git through. Tests that care about the dependency check build their own
# PATH instead (see run_install_with_path).
STUB_BIN="$(mktemp -d)"
for tool in gh node npm claude; do
  printf '#!/bin/sh\nexit 0\n' > "$STUB_BIN/$tool"
  chmod +x "$STUB_BIN/$tool"
done
trap 'rm -rf "$STUB_BIN"' EXIT

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

for f in "$TESTS_DIR"/test_*.sh; do
  # shellcheck source=/dev/null
  . "$f"
done

PASS=0
FAIL=0
SKIP=0
FAILED_NAMES=""

echo ""
echo "brief-ledger-chronicle test suite"
echo "================================="
echo ""

for t in $(declare -F | awk '{print $3}' | grep '^test_' | sort); do
  case "$t" in
    *"$FILTER"*) ;;
    *) continue ;;
  esac

  TEST_FAILED=0
  TEST_SKIPPED=0
  SKIP_REASON=""
  FAILURE_LINES=""

  setup
  "$t"
  teardown

  if [ "$TEST_SKIPPED" = 1 ]; then
    SKIP=$((SKIP + 1))
    printf '  skip  %s (%s)\n' "${t#test_}" "$SKIP_REASON"
  elif [ "$TEST_FAILED" = 0 ]; then
    PASS=$((PASS + 1))
    printf '  ok    %s\n' "${t#test_}"
  else
    FAIL=$((FAIL + 1))
    printf '  FAIL  %s\n' "${t#test_}"
    printf '%s' "$FAILURE_LINES"
    FAILED_NAMES="${FAILED_NAMES}    ${t#test_}"$'\n'
  fi
done

echo ""
if [ "$SKIP" -gt 0 ]; then
  echo "$PASS passed, $FAIL failed, $SKIP skipped"
else
  echo "$PASS passed, $FAIL failed"
fi

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failed:"
  printf '%s' "$FAILED_NAMES"
  exit 1
fi

if [ "$PASS" = 0 ]; then
  echo ""
  echo "error: no tests ran${FILTER:+ (filter: $FILTER)}" >&2
  exit 1
fi

exit 0
