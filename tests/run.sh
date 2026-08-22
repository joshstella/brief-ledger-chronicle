#!/usr/bin/env bash
# Test runner for install.sh and the Contract validator.
#
# Usage: bash tests/run.sh [name-filter]
#
# No framework and no dependencies — see tests/README.md for the reasoning.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$REPO_ROOT/tests"
FILTER="${1:-}"

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
