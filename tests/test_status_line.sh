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
#
# A literal, searched with grep -F. The phase `a` version of this idea was an ERE that
# matched nothing, because the source held a backslash the pattern did not. That is not a
# historical note: this value was `\`?blc/` until the locator moved from grep to awk, where
# the slash needs escaping, and the two controls below failed on the next run and said so.
# Keep the controls; the fingerprint will go stale again.
SL_FINGERPRINT='`?blc\/'

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

# list-briefs.sh gained the same symlink walk open-briefs.sh carries, and shipped it with
# no test — review proved that by replacing the walk with a plain `dirname` and watching
# all 303 tests stay green. Phase `a` learned this lesson for one tool; the second tool did
# not inherit it, because the lesson lived in a test named after the first.
sl_assert_list_briefs_runs_from() {
  local what="$1" script="$2" out status
  out="$(cd "$REPO_ROOT" && bash "$script" docs/briefs 2>&1)"
  status=$?
  [ "$status" -eq 0 ] || fail "$what: list-briefs exited $status"
  case "$out" in
    *"cannot read"*) fail "$what: looked for lib/ beside the link" ;;
    *"| serial |"*) ;;
    *) fail "$what: printed no table" ;;
  esac
}

test_status_line_list_briefs_runs_through_a_symlink() {
  local linkdir="$TMP/lbin"
  mkdir -p "$linkdir"
  ln -s "$REPO_ROOT/tools/list-briefs.sh" "$linkdir/list-briefs.sh"
  sl_assert_list_briefs_runs_from "a single symlink" "$linkdir/list-briefs.sh"
}

test_status_line_list_briefs_runs_through_a_symlink_chain() {
  local linkdir="$TMP/lchain" i
  mkdir -p "$linkdir"
  ln -s "$REPO_ROOT/tools/list-briefs.sh" "$linkdir/l1.sh"
  for i in 2 3 4 5; do
    ln -s "$linkdir/l$((i - 1)).sh" "$linkdir/l$i.sh"
  done
  sl_assert_list_briefs_runs_from "a five-link chain" "$linkdir/l5.sh"

  (cd "$linkdir" && ln -sf ./l5.sh rel.sh)
  sl_assert_list_briefs_runs_from "a relative link" "$linkdir/rel.sh"
}

test_status_line_list_briefs_runs_from_a_path_with_spaces() {
  local linkdir="$TMP/l dir with space"
  mkdir -p "$linkdir"
  ln -s "$REPO_ROOT/tools/list-briefs.sh" "$linkdir/lb.sh"
  sl_assert_list_briefs_runs_from "a path containing spaces" "$linkdir/lb.sh"
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

# The agreement test: one line, two tools, and a failure when they diverge.
#
# The first version of this ran both tools and discarded one result — `: "$in_open"` — so
# blinding open-briefs.sh entirely left it green. Review proved that by setting the tool's
# status line to the empty string: eighteen other tests failed and this one passed. It was
# the phase `a` defect one phase later, under a name that claimed the opposite.
#
# So it is written against the shapes that used to divide the two readers, not against this
# repository's ledgers, which agreed under both old locators and can therefore prove
# nothing. Each fixture is placed in a real repo and read by both tools.
sl_agreement_repo() {
  SL_REPO="$TMP/agree"
  rm -rf "$SL_REPO"
  mkdir -p "$SL_REPO/docs/briefs/0001-shape/"
  git -C "$SL_REPO" init -q -b main
  git -C "$SL_REPO" config user.email t@example.com
  git -C "$SL_REPO" config user.name Test
  fixture_install_tool "$SL_REPO" list-briefs.sh
  fixture_install_tool "$SL_REPO" open-briefs.sh
  printf '# Brief\n' > "$SL_REPO/docs/briefs/0001-shape/brief.md"
  printf '%s\n' "$@" > "$SL_REPO/docs/briefs/0001-shape/ledger.md"
  git -C "$SL_REPO" add -A
  git -C "$SL_REPO" commit -qm fixture >/dev/null 2>&1
}

# usage: sl_assert_tools_agree <label> <ledger-lines...>
# The ledger says in-progress with an open phase, so a reader that finds the line has
# something to report and a reader that misses it says [no-line]. Divergence is visible.
sl_assert_tools_agree() {
  local label="$1"; shift
  sl_agreement_repo "$@"

  local open_out list_out
  open_out="$(cd "$SL_REPO" && bash tools/open-briefs.sh docs/briefs 2>&1)"
  list_out="$(cd "$SL_REPO" && bash tools/list-briefs.sh docs/briefs 2>&1)"

  case "$open_out" in
    *"[no-line]"*) fail "$label: open-briefs found no status line; list-briefs did" ;;
  esac
  case "$list_out" in
    *"no-line"*) fail "$label: list-briefs found no status line; open-briefs did" ;;
    *"in-progress"*) ;;
    *) fail "$label: list-briefs did not read the status as in-progress" ;;
  esac
}

test_status_line_tools_agree_on_the_ordinary_shape() {
  sl_assert_tools_agree "plain" \
    '# Ledger — #0001 A title' \
    '`blc/2 #0001 in-progress a:in-progress(feature/x)`' \
    '' '| a | the thing | in-progress |'
}

test_status_line_tools_agree_on_a_blank_line_after_the_title() {
  sl_assert_tools_agree "blank after title" \
    '# Ledger — #0001 A title' \
    '' \
    '`blc/2 #0001 in-progress a:in-progress(feature/x)`' \
    '' '| a | the thing | in-progress |'
}

test_status_line_tools_agree_on_a_line_further_down() {
  sl_assert_tools_agree "further down" \
    '# Ledger — #0001 A title' \
    '' 'Preamble a docs pipeline inserted.' '' \
    '`blc/2 #0001 in-progress a:in-progress(feature/x)`' \
    '' '| a | the thing | in-progress |'
}

test_status_line_tools_agree_under_unterminated_frontmatter() {
  sl_assert_tools_agree "unterminated frontmatter" \
    '---' 'title: broken' '' \
    '# Ledger — #0001 A title' \
    '`blc/2 #0001 in-progress a:in-progress(feature/x)`' \
    '' '| a | the thing | in-progress |'
}

# The shape review found: an example at column 0 inside a fence, above the real line. This
# is how docs/briefs/README.md prints the status line, so a ledger documenting its own
# format would have handed both readers the example.
test_status_line_tools_agree_when_a_fence_holds_an_example() {
  sl_assert_tools_agree "fenced example" \
    '# Ledger — #0001 A title' \
    '' '```' '`blc/2 #9999 done z:done`' '```' '' \
    '`blc/2 #0001 in-progress a:in-progress(feature/x)`' \
    '' '| a | the thing | in-progress |'
}

test_status_line_a_fenced_example_is_not_read_as_the_status() {
  sl_source_lib
  sl_fixture fenced '# Ledger — #0001 A title' \
    '```' '`blc/2 #9999 done z:done`' '```' \
    '`blc/2 #0001 in-progress a:pending`'
  [ "$(blc_status_line "$SL_FILE")" = "blc/2 #0001 in-progress a:pending" ] \
    || fail "an example inside a fence was read as the ledger's own status line"
}

test_status_line_a_tilde_fence_counts_too() {
  sl_source_lib
  sl_fixture tilde '# Ledger — #0001 A title' \
    '~~~' '`blc/2 #9999 done z:done`' '~~~' \
    '`blc/2 #0001 in-progress a:pending`'
  [ "$(blc_status_line "$SL_FILE")" = "blc/2 #0001 in-progress a:pending" ] \
    || fail "a tilde fence was not treated as a fence"
}
