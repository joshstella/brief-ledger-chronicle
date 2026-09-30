# What a target receives of the briefs Contract, and the check the Contract names.
#
# Phase 1 shipped the rules restated in a second README copy. Phase 4 ships the
# Contract itself, from this repository's own docs/, so no second copy exists to
# hand-sync. These tests pin the two things that makes possible and the two ways
# it could become a lie: a rule document whose links dangle in the target, and a
# `checked:` path naming a script that was never installed.

test_ship_places_the_contract() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/docs/contracts/v1.md"
  assert_file "$TARGET/docs/contracts/v1.1.md"
  assert_file "$TARGET/docs/contracts/v1.2.md"
  assert_file "$TARGET/docs/contracts/README.md"
  assert_contains "BRIEFS-1" "$TARGET/docs/contracts/v1.1.md"
  assert_contains "BRIEFS-1" "$TARGET/docs/contracts/v1.2.md"
}

test_ship_places_the_contract_for_cursor_too() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/docs/contracts/v1.md"
  assert_file "$TARGET/docs/contracts/v1.1.md"
  assert_file "$TARGET/docs/contracts/v1.2.md"
  assert_file "$TARGET/docs/contracts/README.md"
}

# Generalised deliberately. A test naming open-briefs.sh would have caught the bug
# that prompted it and nothing after: the briefs README shipped for a full day
# telling targets that tools/open-briefs.sh reads their ledgers back, while the
# installer carried only the validator. The failing property is not "this tool is
# missing" but "the shipped prose names a tool the target does not have", so that is
# what is asserted — every tools/ path the installed docs mention has to resolve.
test_ship_every_tool_the_installed_docs_name_is_present() {
  run_install y --target "$TARGET"
  assert_status 0
  local doc path found=0
  # Every document install.sh ships under docs/, not the ones that happen to name a
  # tool today. The property is about the shipped set; scanning a subset of it would
  # let a tool named in the omitted document go unchecked.
  for doc in "$TARGET/docs/briefs/README.md" "$TARGET/docs/briefs/_drafts/README.md" \
             "$TARGET/docs/contracts/README.md" "$TARGET/docs/contracts/v1.md" \
             "$TARGET/docs/contracts/v1.1.md" "$TARGET/docs/contracts/v1.2.md"; do
    [ -f "$doc" ] || continue
    # Underscores and digits included so a tool named off the lowercase-hyphen
    # convention is caught rather than skipped. A pattern that silently ignores the
    # name it cannot parse would report success for the case it failed to look at.
    for path in $(grep -oE 'tools/[a-z0-9_-]+\.sh' "$doc" | sort -u); do
      found=$((found + 1))
      [ -f "$TARGET/$path" ] \
        || fail "installed docs name a tool absent from the target: $path (in ${doc##*/})"
      [ -x "$TARGET/$path" ] \
        || fail "installed tool is not executable: $path"
    done
  done
  [ "$found" -gt 0 ] || fail "installed docs name no tools at all — the scan found nothing to check"
}

# Shipping a git-dependent tool into a directory with no git makes the briefs README
# name something the reader cannot run. The installer cannot fix that, but staying
# silent about it reproduces the defect this file exists to catch, one step along:
# present, documented, and unrunnable.
test_ship_warns_when_the_target_is_not_a_git_repo() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_out "is not a git repository"
  assert_out "open-briefs.sh does not"
}

# The warning has to be conditional, or it is noise every real install learns to skip.
test_ship_is_silent_about_git_when_the_target_is_a_repo() {
  git -C "$TARGET" init -q
  run_install y --target "$TARGET"
  assert_status 0
  assert_not_contains "is not a git repository" "$OUT"
  assert_file "$TARGET/tools/open-briefs.sh"
}

# The query ships for the same reason the validator does, and is pinned separately
# so a regression names itself rather than surfacing as a generic scan failure.
test_ship_places_the_open_briefs_query() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/tools/open-briefs.sh"
  [ -x "$TARGET/tools/open-briefs.sh" ] \
    || fail "installed open-briefs.sh is not executable"
}

# The rules without the check would be a Contract whose strongest claim is backed
# by nothing in the tree that holds it.
test_ship_places_a_validator_that_runs() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/tools/validate-briefs.sh"
  [ -x "$TARGET/tools/validate-briefs.sh" ] \
    || fail "installed validator is not executable"
  "$TARGET/tools/validate-briefs.sh" "$TARGET/docs/briefs" >"$TMP/v.txt" 2>&1
  assert_count 0 "$?" "validator exit status against a fresh target"
  assert_contains "clauses decided" "$TMP/v.txt"
}

# The failure this phase could most easily introduce. The shipped README points at
# the Contract with a relative link, which resolves in this repository whether or
# not install.sh places docs/contracts/ in the target.
test_ship_every_relative_link_in_the_briefs_readme_resolves() {
  run_install y --target "$TARGET"
  assert_status 0
  local readme="$TARGET/docs/briefs/README.md" link found=0
  for link in $(grep -oE '\]\(\.\.?/[^)]+\)' "$readme" | sed 's/^](\(.*\))$/\1/' | sort -u); do
    found=$((found + 1))
    [ -e "$TARGET/docs/briefs/$link" ] \
      || fail "installed briefs README links to $link, absent from the target"
  done
  [ "$found" -gt 0 ] || fail "expected a relative link in the installed briefs README"
}

# The consumer-side mirror of briefs_every_named_check_path_resolves. That test
# guards this repository; a target is where the claim is easiest to break, because
# nothing in the target was written by hand.
test_ship_the_installed_contract_names_a_check_that_exists() {
  run_install y --target "$TARGET"
  assert_status 0
  local contract path found=0
  for contract in "$TARGET/docs/contracts/v1.md" "$TARGET/docs/contracts/v1.1.md" \
                  "$TARGET/docs/contracts/v1.2.md"; do
    for path in $(grep -oE 'checked: `[^`]+`' "$contract" | sed 's/checked: `\(.*\)`/\1/' | sort -u); do
      found=$((found + 1))
      [ -f "$TARGET/$path" ] \
        || fail "installed ${contract##*/} names a check absent from the target: $path"
    done
  done
  [ "$found" -gt 0 ] || fail "installed Contract names no checks at all"
}

# The point of the phase. A target gets the file this repository lives by, not a
# copy of it — so the two cannot say different things.
test_ship_the_briefs_readme_is_this_repos_own_file() {
  run_install y --target "$TARGET"
  assert_status 0
  cmp -s "$REPO_ROOT/docs/briefs/README.md" "$TARGET/docs/briefs/README.md" \
    || fail "installed briefs README differs from this repository's own copy"
  cmp -s "$REPO_ROOT/docs/contracts/v1.md" "$TARGET/docs/contracts/v1.md" \
    || fail "installed Contract v1 differs from this repository's own copy"
  cmp -s "$REPO_ROOT/docs/contracts/v1.1.md" "$TARGET/docs/contracts/v1.1.md" \
    || fail "installed Contract v1.1 differs from this repository's own copy"
  cmp -s "$REPO_ROOT/docs/contracts/v1.2.md" "$TARGET/docs/contracts/v1.2.md" \
    || fail "installed Contract v1.2 differs from this repository's own copy"
}

# A structural guard rather than a behavioural one: the drift can only come back by
# reintroducing a second copy for the installer to read.
test_ship_no_second_copy_of_the_briefs_docs_exists() {
  assert_no_dir "$REPO_ROOT/templates/docs"
}

# The Contract is toolkit-owned and replaced every run (#0012b).
test_ship_default_replaces_a_stale_contract() {
  mkdir -p "$TARGET/docs/contracts"
  echo "OLD CONTRACT" > "$TARGET/docs/contracts/v1.md"
  echo "OLD SUPERSEDED" > "$TARGET/docs/contracts/v1.1.md"
  echo "OLD CURRENT" > "$TARGET/docs/contracts/v1.2.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_not_contains "OLD CONTRACT" "$TARGET/docs/contracts/v1.md"
  assert_not_contains "OLD SUPERSEDED" "$TARGET/docs/contracts/v1.1.md"
  assert_not_contains "OLD CURRENT" "$TARGET/docs/contracts/v1.2.md"
  assert_contains "BRIEFS-1" "$TARGET/docs/contracts/v1.md"
  assert_contains "BRIEFS-1" "$TARGET/docs/contracts/v1.1.md"
  assert_contains "BRIEFS-1" "$TARGET/docs/contracts/v1.2.md"
}

# The Contract README ships into every target, and #0015b gave it a command to run and a path
# under `tests/`. `install.sh` ships `docs/`, `tools/` and `templates/` — never `tests/`. So a
# consumer reading criterion 1 was told to run something their repository does not contain.
#
# This is the same failure `ship_every_relative_link_in_the_briefs_readme_resolves` was written
# for, one file over: a path that resolves here because this is where it was written. The two
# existing path tests scan `v1.md`, `v1.1.md` and `v1.2.md` for the `` checked: `...` `` form,
# and the new pointer is in neither a version file nor that form.
#
# The rule is not "every path must resolve". Some reasoning genuinely refers to the toolkit's
# own repository, and stripping it would cost a consumer the reason behind a published tag.
# The rule is that a path the target does not carry must say so where it is named.
IN_SOURCE_ONLY_MARKER="not in an installed copy"

test_ship_the_contract_readme_marks_paths_it_does_not_ship() {
  run_install y --target "$TARGET"
  assert_status 0
  local readme="$TARGET/docs/contracts/README.md" path absent=0
  assert_file "$readme"

  # Blank-line-separated blocks, so the marker has to sit beside the path it excuses. A
  # file-wide `grep` would let one marker anywhere license every unshipped path in the
  # document, including one added later in an unrelated paragraph — which is not the rule
  # stated above, and the rule is the part a reader relies on.
  local block="" blocks="$TMP/contract-blocks"
  rm -rf "$blocks"; mkdir -p "$blocks"
  awk -v out="$blocks" '
    BEGIN { n = 1 }
    /^[[:space:]]*$/ { n++; next }
    { print >> (out "/" n) }
  ' "$readme"

  local file
  for file in "$blocks"/*; do
    [ -f "$file" ] || continue
    for path in $(grep -oE '(tests|tools|docs|templates|skills)/[A-Za-z0-9_./-]+' "$file" \
                  | sed 's/[.,)]*$//' | sort -u); do
      [ -e "$TARGET/$path" ] && continue
      absent=$((absent + 1))
      # The paragraph naming the path, or the one on either side of it. A path is often cited
      # in a fenced block whose sentence sits above or below it, and a rule that could only be
      # satisfied inside the fence would be satisfied by putting prose in a code block.
      local n="${file##*/}"
      grep -hq "$IN_SOURCE_ONLY_MARKER" \
        "$file" "$blocks/$((n - 1))" "$blocks/$((n + 1))" 2>/dev/null \
        || fail "the installed Contract README names '$path', which the target does not have,
and neither the paragraph naming it nor the ones beside it say so. A consumer follows the
reference and finds nothing. Either stop naming it, or mark it '$IN_SOURCE_ONLY_MARKER'."
    done
  done

  # Positive control. If the README ever stops naming an unshipped path, this test is passing
  # over a question that is no longer being asked, and it should be deleted rather than kept
  # as a green line. That is the state the marker exists for.
  [ "$absent" -gt 0 ] \
    || fail "the installed Contract README no longer names any path absent from a target.
This test has nothing left to check and is now decoration — remove it, or the marker rule it
guards, deliberately rather than by attrition."
}
