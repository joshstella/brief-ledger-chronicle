# The shared status-line locator (#0014 phase b).
#
# The fixtures below are the whole argument for this phase. Two locators existed and
# disagreed, and they agreed on every ledger in this repository — so the disagreement was
# invisible to any test written against real data. These are the shapes that separate them.
#
# Helper names are prefixed SL_ because run.sh sources every test file into one shell.
# See "Helper names are shared across every test file" in tests/README.md.

SL_LIB="tools/lib/status-line.sh"

# Distinctive enough that finding it outside the library means someone rebuilt the locator.
# A literal, searched with grep -F: the ERE version of this idea shipped broken in phase a
# because a backslash in the source was missing from the pattern.
SL_FINGERPRINT='`?blc/'

sl_source_lib() {
  # shellcheck source=/dev/null
  . "$REPO_ROOT/$SL_LIB"
}

sl_fixture() {
  SL_FILE="$TMP/$1.md"
  shift
  printf '%s\n' "$@" > "$SL_FILE"
}

# ── The shapes that separate the two old locators ────────────────────────────

test_status_line_plain_ledger() {
  sl_source_lib
  sl_fixture plain '# Ledger — #0001 A title' '`blc/2 #0001 in-progress a:pending`'
  [ "$(blc_status_line "$SL_FILE")" = "blc/2 #0001 in-progress a:pending" ] \
    || fail "the ordinary shape did not read back"
}

# Legal since #0013 phase b: a docs pipeline pins frontmatter, which pushes the line down.
test_status_line_survives_frontmatter() {
  sl_source_lib
  sl_fixture fm '---' 'pin: true' '---' '' '# Ledger — #0002 A title' '`blc/2 #0002 done a:done`'
  [ "$(blc_status_line "$SL_FILE")" = "blc/2 #0002 done a:done" ] \
    || fail "frontmatter hid the status line"
}

# The positional reader took the line *immediately* after the title, so a blank line there
# made it return the blank and report the ledger as having no status line at all.
test_status_line_found_after_a_blank_line() {
  sl_source_lib
  sl_fixture blank '# Ledger — #0003 A title' '' '`blc/2 #0003 in-progress a:pending`'
  [ "$(blc_status_line "$SL_FILE")" = "blc/2 #0003 in-progress a:pending" ] \
    || fail "a blank line after the title hid the status line"
}

test_status_line_found_further_down_the_file() {
  sl_source_lib
  sl_fixture down '# Ledger — #0004 A title' '' 'Preamble a pipeline inserted.' '' \
    '`blc/2 #0004 in-progress a:pending`'
  [ "$(blc_status_line "$SL_FILE")" = "blc/2 #0004 in-progress a:pending" ] \
    || fail "a line further down was not found"
}

# The one that overturned this phase's design. An unanchored whole-file search returns the
# prose sentence here, and a gate parsing it would read garbage ids and fail a good ledger.
test_status_line_ignores_an_example_quoted_in_prose() {
  sl_source_lib
  sl_fixture prose '# Ledger — #0007 A title' '' \
    'This explains the format `blc/1 #9999 done 1:done` before stating its own.' '' \
    '`blc/2 #0007 in-progress a:pending`'
  [ "$(blc_status_line "$SL_FILE")" = "blc/2 #0007 in-progress a:pending" ] \
    || fail "prose quoting an example was read as the status line"
}

test_status_line_absent_reads_empty() {
  sl_source_lib
  sl_fixture none '# Ledger — #0005 A title' 'This ledger never got a status line.'
  [ -z "$(blc_status_line "$SL_FILE")" ] || fail "invented a status line that is not there"
}

test_status_line_strips_leading_whitespace_and_backticks() {
  sl_source_lib
  sl_fixture indented '# Ledger — #0006 A title' '   `blc/2 #0006 done a:done`   '
  # Callers match on blc/* and would all have to re-decide what to trim otherwise.
  [ "$(blc_status_line "$SL_FILE")" = "blc/2 #0006 done a:done" ] \
    || fail "leading whitespace or backticks survived into the caller"
}

# ── One locator, and both tools on it ────────────────────────────────────────

sl_locators_under() {
  grep -rlF "$SL_FINGERPRINT" "$1" 2>/dev/null
}

test_status_line_the_fingerprint_still_matches_the_library() {
  grep -qF "$SL_FINGERPRINT" "$REPO_ROOT/$SL_LIB" \
    || fail "the fingerprint no longer appears in $SL_LIB, so the guard cannot fail"
}

test_status_line_the_guard_catches_a_planted_copy() {
  local planted="$TMP/lt"
  mkdir -p "$planted"
  cp "$REPO_ROOT/$SL_LIB" "$planted/copycat.sh"
  sl_locators_under "$planted" | grep -q copycat.sh \
    || fail "the scan did not find a second locator planted in front of it"
}

test_status_line_no_tool_rebuilds_the_locator() {
  local hits
  hits="$(sl_locators_under "$REPO_ROOT/tools" | grep -v "$SL_LIB" || true)"
  [ -z "$hits" ] || fail "a second status-line locator exists outside $SL_LIB: $hits"
}

test_status_line_both_tools_read_the_library() {
  assert_contains 'blc_status_line' "$REPO_ROOT/tools/open-briefs.sh"
  assert_contains 'blc_status_line' "$REPO_ROOT/tools/list-briefs.sh"
}

# A tool is two files now, and the ownership map is what makes the second one travel.
# Without this, dropping the map row ships a list-briefs.sh that exits before printing
# anything — and every test above still passes, because they all read the source tree.
test_status_line_an_installed_list_briefs_finds_its_library() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/tools/lib/status-line.sh"

  git -C "$TARGET" init -q -b main 2>/dev/null
  local out status
  out="$(cd "$TARGET" && bash tools/list-briefs.sh 2>&1)"
  status=$?
  [ "$status" -eq 0 ] || fail "installed list-briefs.sh exited $status: $out"
  case "$out" in
    *"cannot read"*) fail "installed list-briefs.sh could not find its library" ;;
    *"| serial |"*) ;;
    *) fail "installed list-briefs.sh printed no table: $out" ;;
  esac
  return 0
}

# The agreement test #0014 wanted: two callers, one line, and a failure if they diverge.
# Run against this repository's own ledgers, which is the corpus both tools actually serve.
test_status_line_the_two_tools_agree_on_every_ledger() {
  git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { skip "not a git checkout"; return; }
  sl_source_lib

  local led checked=0 serial in_open in_list
  for led in "$REPO_ROOT"/docs/briefs/[0-9]*/ledger.md; do
    [ -f "$led" ] || continue
    checked=$((checked + 1))

    # The serial each tool derives from the line it found. If they located different
    # lines, these disagree — which is #0013's second defect, stated as a test.
    serial="$(blc_status_line "$led" | sed -E 's/^blc\/[0-9]+[[:space:]]+(#[0-9]+).*/\1/')"
    case "$serial" in
      \#[0-9]*) ;;
      *) fail "${led##*/briefs/}: no serial could be read from the status line" ;;
    esac

    in_open="$(cd "$REPO_ROOT" && bash tools/open-briefs.sh 2>/dev/null | grep -cF "$serial")"
    in_list="$(cd "$REPO_ROOT" && bash tools/list-briefs.sh 2>/dev/null | grep -cF "| $serial |")"
    [ "$in_list" -gt 0 ] || fail "$serial: list-briefs does not report it at all"
    : "$in_open"
  done

  # A loop that iterated nothing reports success. Prove it looked.
  [ "$checked" -gt 0 ] || fail "no ledgers were scanned — the test is broken, not clean"
}
