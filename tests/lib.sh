# Assertions and fixtures for the install.sh test suite. Sourced by run.sh.
#
# No `set -e` anywhere in this suite, deliberately: assertions record failures and
# keep going, so one test reports every problem it found rather than only the first.

# Reset per test by the runner.
TEST_FAILED=0
TEST_SKIPPED=0
SKIP_REASON=""
FAILURE_LINES=""
LAST_STATUS=0

fail() {
  TEST_FAILED=1
  FAILURE_LINES="${FAILURE_LINES}       - $1"$'\n'
}

skip() {
  TEST_SKIPPED=1
  SKIP_REASON="$1"
}

# ── Fixtures ─────────────────────────────────────────────────────────────────
#
# Each test gets its own target project and its own $CLAUDE_HOME, so machine-mode
# tests never touch the real ~/.claude. install.sh makes CLAUDE_HOME overridable
# specifically to allow this.

setup() {
  TMP="$(mktemp -d)"
  TARGET="$TMP/project"
  CLAUDE_HOME_DIR="$TMP/claude-home"
  OUT="$TMP/out.txt"
  ERR="$TMP/err.txt"
  mkdir -p "$TARGET"
  : > "$OUT"
  : > "$ERR"
}

teardown() {
  [ -n "${TMP:-}" ] && rm -rf "$TMP"
}

# Run the installer with the stubbed toolchain on PATH.
# usage: run_install <answer-to-prompt> [args...]
run_install() {
  local answer="$1"
  shift
  printf '%s\n' "$answer" \
    | PATH="$STUB_BIN:$PATH" CLAUDE_HOME="$CLAUDE_HOME_DIR" \
      bash "$REPO_ROOT/install.sh" "$@" >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# Run a *copy* of the installer, from a directory of the test's choosing.
# usage: run_install_from <script-dir> <answer-to-prompt> [args...]
run_install_from() {
  local dir="$1" answer="$2"
  shift 2
  printf '%s\n' "$answer" \
    | PATH="$STUB_BIN:$PATH" CLAUDE_HOME="$CLAUDE_HOME_DIR" \
      bash "$dir/install.sh" "$@" >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# A throwaway copy of the installer and everything it reads, for tests that point
# it at its own checkout. Pointing the real repo at itself would mean that if the
# self-install guard ever regressed, the test would write into the working tree
# before failing — the test would report the bug by causing damage. The copy keeps
# the blast radius inside $TMP. Only what install.sh reads is copied; .git and docs
# are not needed and would dominate the cost.
clone_installer_to_tmp() {
  local dest="$TMP/src"
  mkdir -p "$dest"
  cp "$REPO_ROOT/install.sh" "$dest/"
  local d
  for d in commands skills templates personal; do
    [ -e "$REPO_ROOT/$d" ] && cp -R "$REPO_ROOT/$d" "$dest/"
  done
  echo "$dest"
}

# Same, with an explicit PATH — for testing what the installer requires.
# usage: run_install_with_path <path> <answer-to-prompt> [args...]
run_install_with_path() {
  local path="$1" answer="$2"
  shift 2
  printf '%s\n' "$answer" \
    | PATH="$path" CLAUDE_HOME="$CLAUDE_HOME_DIR" \
      bash "$REPO_ROOT/install.sh" "$@" >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# ── Assertions ───────────────────────────────────────────────────────────────

assert_status() {
  [ "$LAST_STATUS" = "$1" ] || fail "exit status: expected $1, got $LAST_STATUS"
}

assert_file()    { [ -f "$1" ] || fail "expected file to exist: $1"; }
assert_no_file() { [ ! -f "$1" ] || fail "expected file to be absent: $1"; }
assert_dir()     { [ -d "$1" ] || fail "expected directory to exist: $1"; }
assert_no_dir()  { [ ! -d "$1" ] || fail "expected directory to be absent: $1"; }

# Fixed-string containment — the common case, and safe with markdown punctuation
# like `**Created:** 0` that would otherwise need regex escaping.
assert_contains() {
  grep -qF -- "$1" "$2" 2>/dev/null || fail "expected \"$1\" in ${2##*/}"
}

assert_not_contains() {
  if grep -qF -- "$1" "$2" 2>/dev/null; then
    fail "did not expect \"$1\" in ${2##*/}"
  fi
  return 0
}

# Regex containment, for anchors.
assert_matches() {
  grep -q -- "$1" "$2" 2>/dev/null || fail "expected /$1/ in ${2##*/}"
}

assert_out()     { assert_contains "$1" "$OUT"; }
assert_err()     { assert_contains "$1" "$ERR"; }

assert_symlink_to() {
  local link="$1" want="$2" got
  if [ ! -L "$link" ]; then
    fail "expected a symlink at $link"
    return
  fi
  got="$(readlink "$link")"
  [ "$got" = "$want" ] || fail "symlink $link -> $got, expected $want"
}

# usage: assert_count <expected> <actual> <what>
assert_count() {
  [ "$2" = "$1" ] || fail "$3: expected $1, got $2"
}

# ── Helpers ──────────────────────────────────────────────────────────────────

# Number of `## ` entries in the install log.
count_log_entries() {
  grep -c '^## ' "$1" 2>/dev/null || true
}

# Extract the Nth `## ` entry of the install log into a file.
extract_log_entry() {
  local log="$1" n="$2" dest="$3"
  awk -v want="$n" '/^## /{seen++} seen==want' "$log" > "$dest"
}

# Count duplicate four-digit serial prefixes among a target's brief folders.
count_duplicate_serials() {
  ls -d "$1"/docs/briefs/[0-9][0-9][0-9][0-9]-*/ 2>/dev/null \
    | sed 's#.*/\([0-9][0-9][0-9][0-9]\)-.*#\1#' \
    | sort | uniq -d | wc -l | tr -d ' '
}

# Count numbered brief folders in a target.
count_numbered_briefs() {
  ls -d "$1"/docs/briefs/[0-9][0-9][0-9][0-9]-*/ 2>/dev/null | wc -l | tr -d ' '
}
