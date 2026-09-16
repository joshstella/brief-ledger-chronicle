# The shared phase-row matcher (#0014 phase a).
#
# The point of tools/lib/phase-row.sh is that there is one of it. A test that only
# exercised the function would pass just as happily with a second copy pasted into a
# tool, which is the exact defect #0013 hit: two readers that agreed until they did not.
# So the first test here is about the tree, not the behaviour.
#
# Helper and fixture names are prefixed PR_ because run.sh sources every test file into
# one shell. See "Helper names are shared across every test file" in tests/README.md.

PR_LIB="tools/lib/phase-row.sh"

# A fragment of the pattern distinctive enough that finding it outside the library means
# someone re-derived the matcher rather than sourced it.
#
# Searched with `grep -F`, as a literal. The first version of this was an ERE reading
# `~\*\`\?`, which asks for `~*`?` — no backslash between the asterisk and the backtick.
# The source has one, because the backtick is escaped inside a double-quoted string. So
# the guard matched nothing at all, including the library it guards, and a verbatim copy
# of the whole matcher planted in tools/ passed it. A regex here buys nothing: the thing
# being searched for is a fixed string.
PR_FINGERPRINT='~*\`?'

pr_source_lib() {
  # shellcheck source=/dev/null
  . "$REPO_ROOT/$PR_LIB"
}

pr_fixture() {
  PR_FILE="$TMP/ledger.md"
  printf '%s\n' "$@" > "$PR_FILE"
}

pr_matchers_under() {
  grep -rlF "$PR_FINGERPRINT" "$1" 2>/dev/null
}

# The two tests below are positive controls for the guard that follows them. A scan that
# matches nothing reports success, so "no second matcher was found" and "the search is
# broken" produce identical output. These separate the two.

test_phase_row_the_fingerprint_still_matches_the_library() {
  grep -qF "$PR_FINGERPRINT" "$REPO_ROOT/$PR_LIB" \
    || fail "the fingerprint no longer appears in $PR_LIB, so the guard cannot fail"
}

test_phase_row_the_guard_catches_a_planted_copy() {
  local planted="$TMP/tools"
  mkdir -p "$planted"
  cp "$REPO_ROOT/$PR_LIB" "$planted/copycat.sh"
  pr_matchers_under "$planted" | grep -q copycat.sh \
    || fail "the scan did not find a second matcher planted in front of it"
}

# Searches tools/ only. A re-derived matcher in a skill or in brief-checks/ would not be
# seen — narrow on purpose, because tools/ is where the drift this brief is about happens.
test_phase_row_no_tool_defines_its_own_matcher() {
  local hits
  hits="$(pr_matchers_under "$REPO_ROOT/tools" | grep -v "$PR_LIB" || true)"
  [ -z "$hits" ] || fail "a second phase-row matcher exists outside $PR_LIB: $hits"
}

test_phase_row_open_briefs_sources_the_library() {
  # Named in the bootstrap's library list rather than as a full path: open-briefs.sh
  # loads several libraries in one loop since #0014 phase b.
  assert_contains 'phase-row' "$REPO_ROOT/tools/open-briefs.sh"
  assert_contains 'BLC_LIB_DIR' "$REPO_ROOT/tools/open-briefs.sh"
}

test_phase_row_library_is_not_executable_in_the_index() {
  git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { skip "not a git checkout"; return; }

  local mode
  mode="$(git -C "$REPO_ROOT" ls-files -s -- "$PR_LIB" | awk '{print $1}')"
  [ -n "$mode" ] || { fail "$PR_LIB is not tracked"; return; }
  # The complement of tests/test_source_tree.sh: that file exempts this path from
  # needing +x, and this one says the exemption is used rather than merely allowed.
  [ "$mode" = "100644" ] || fail "$PR_LIB is sourced, so it should be 100644, not $mode"
}

# Moving the matcher into lib/ gave this script an external dependency it did not have
# before, and a dependency found by `dirname "$BASH_SOURCE"` is found relative to however
# the script was reached. A symlink on a PATH directory is the ordinary way to reach a
# tool, and it sent the first version of this looking for lib/ beside the link.
pr_assert_runs_from() {
  local what="$1" script="$2" out status
  out="$(cd "$REPO_ROOT" && bash "$script" 2>&1)"
  status=$?
  # Exit 2 is this tool's "the question could not be asked" status, which is what a
  # library it cannot locate produces.
  [ "$status" -ne 2 ] || fail "$what: could not find its library"
  case "$out" in
    *"cannot read"*) fail "$what: looked for lib/ beside the link" ;;
    *"too many symbolic links"*) fail "$what: hit the hop bound on a legal chain" ;;
  esac
}

test_phase_row_open_briefs_runs_through_a_symlink() {
  local linkdir="$TMP/bin"
  mkdir -p "$linkdir"
  ln -s "$REPO_ROOT/tools/open-briefs.sh" "$linkdir/open-briefs.sh"
  pr_assert_runs_from "a single symlink" "$linkdir/open-briefs.sh"
}

# A link to a link is ordinary — a package manager's bin/ entry pointing at a versioned
# path that is itself a link. The walk has to follow the whole chain, and a relative
# target resolves against the directory holding the link rather than $PWD.
test_phase_row_open_briefs_runs_through_a_symlink_chain() {
  local linkdir="$TMP/chain" i
  mkdir -p "$linkdir"
  ln -s "$REPO_ROOT/tools/open-briefs.sh" "$linkdir/l1.sh"
  for i in 2 3 4 5; do
    ln -s "$linkdir/l$((i - 1)).sh" "$linkdir/l$i.sh"
  done
  pr_assert_runs_from "a five-link chain" "$linkdir/l5.sh"

  (cd "$linkdir" && ln -sf ./l5.sh rel.sh)
  pr_assert_runs_from "a relative link" "$linkdir/rel.sh"
}

# Every path in the resolution walk is quoted; this is the fixture that says so.
test_phase_row_open_briefs_runs_from_a_path_with_spaces() {
  local linkdir="$TMP/dir with space"
  mkdir -p "$linkdir"
  ln -s "$REPO_ROOT/tools/open-briefs.sh" "$linkdir/ob.sh"
  pr_assert_runs_from "a path containing spaces" "$linkdir/ob.sh"
}

# install.sh skips `chmod +x` for tools/lib/*. Nothing asserted the result, so deleting
# that skip left the suite green — the same shape as "An assertion downstream of a repair
# cannot see the break" in tests/README.md, inherited by the new branch of that loop.
# Both directions are checked here: removing the skip fails the first assertion, and
# removing the chmod entirely fails the second.
test_phase_row_the_installed_library_is_not_executable() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0

  local lib="$TARGET/tools/lib/phase-row.sh"
  assert_file "$lib"
  [ ! -x "$lib" ] || fail "the installed library is executable; it is sourced, not invoked"
  [ -x "$TARGET/tools/open-briefs.sh" ] || fail "an installed tool lost its execute bit"
}

# The property the ledger sells: a scan that cannot run must not report a clean tree.
# Exit 2 is this tool's "the question could not be asked" status, and the absence of a
# summary line is the part that matters — a clean summary from a tool that never loaded
# its matcher is precisely the silent-pass failure this brief exists to end.
test_phase_row_a_missing_library_refuses_to_report_a_clean_tree() {
  local orphan="$TMP/orphan" out status
  mkdir -p "$orphan"
  cp "$REPO_ROOT/tools/open-briefs.sh" "$orphan/open-briefs.sh"

  out="$(cd "$REPO_ROOT" && bash "$orphan/open-briefs.sh" 2>&1)"
  status=$?

  assert_count 2 "$status" "exit status with no library beside it"
  case "$out" in
    *"open-briefs: "*) fail "printed a summary without ever loading its matcher" ;;
  esac
  return 0
}

# ── The shapes it knows ──────────────────────────────────────────────────────

test_phase_row_matches_the_three_shapes_in_use() {
  pr_source_lib
  pr_fixture \
    '| a | the row scan | done |' \
    '| `b — the clause` | pending |' \
    '| `brief/0001-x` | phase 1 of it |'

  blc_phase_row_find a "$PR_FILE" | grep -q 'the row scan' \
    || fail "did not match the bare id in the first cell"
  blc_phase_row_find b "$PR_FILE" | grep -q 'the clause' \
    || fail "did not match the em-dashed id and label"
  blc_phase_row_find 1 "$PR_FILE" | grep -q 'phase 1 of it' \
    || fail "did not match the numeric id in prose"
}

test_phase_row_prose_form_is_numeric_only() {
  pr_source_lib
  pr_fixture '| `brief/0014-a` | phase a of it |'
  # The loose prose scan is added to the numeric pattern only. Letting it serve the
  # letter alphabet too would match most sentences containing "phase a".
  blc_phase_row_find a "$PR_FILE" | grep -q . \
    && fail "the prose form matched a letter id; it is numeric-only by design"
  return 0
}

test_phase_row_returns_every_candidate_not_the_first() {
  pr_source_lib
  pr_fixture \
    '| a | the row scan | pending |' \
    '| a | a second table says | done |'
  # open-briefs.sh reports drift only when *no* candidate agrees, which requires
  # seeing all of them. Returning the first would let a cost or timing table shadow
  # the real phase row.
  local count
  count="$(blc_phase_row_find a "$PR_FILE" | wc -l | tr -d ' ')"
  assert_count 2 "$count" "candidate rows returned"
}

# The three shapes #0013 left unmatched, pinned as unmatched *on purpose*.
#
# This is a characterization test, not an endorsement. #0014 phase a is declared "no
# behaviour change", so the gap has to be provably still here when the extraction lands;
# phase b is where it closes, and this test flipping is how that will be visible.
test_phase_row_the_three_unmatched_shapes_are_still_unmatched() {
  pr_source_lib
  local shape
  for shape in '| `a` |' '| ~~a~~ |' '| ~~`a`~~ |'; do
    pr_fixture "$shape"
    if blc_phase_row_find a "$PR_FILE" | grep -q .; then
      fail "shape now matches: $shape — if phase b did this, update this test"
    fi
  done
  return 0
}
