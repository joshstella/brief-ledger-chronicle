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

# A fragment of the pattern that is distinctive enough that finding it outside the
# library means someone re-derived the matcher rather than sourced it.
PR_FINGERPRINT='~\*\`\?'

pr_source_lib() {
  # shellcheck source=/dev/null
  . "$REPO_ROOT/$PR_LIB"
}

pr_fixture() {
  PR_FILE="$TMP/ledger.md"
  printf '%s\n' "$@" > "$PR_FILE"
}

test_phase_row_no_tool_defines_its_own_matcher() {
  local hits
  # Every .sh outside the library. If the fingerprint shows up in one, the tool is
  # building the pattern itself again and the two can drift apart on the next edit.
  hits="$(grep -rlE "$PR_FINGERPRINT" "$REPO_ROOT/tools" 2>/dev/null \
    | grep -v "$PR_LIB" || true)"
  [ -z "$hits" ] || fail "a second phase-row matcher exists outside $PR_LIB: $hits"
}

test_phase_row_open_briefs_sources_the_library() {
  assert_contains 'lib/phase-row.sh' "$REPO_ROOT/tools/open-briefs.sh"
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
