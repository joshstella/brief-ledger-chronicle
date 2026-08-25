# What a target receives of Contract v1, and the check the Contract names.
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
  assert_file "$TARGET/docs/contracts/README.md"
  assert_contains "BRIEFS-1" "$TARGET/docs/contracts/v1.md"
}

test_ship_places_the_contract_for_cursor_too() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/docs/contracts/v1.md"
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
  for doc in "$TARGET/docs/briefs/README.md" "$TARGET/docs/contracts/v1.md" \
             "$TARGET/docs/contracts/README.md"; do
    [ -f "$doc" ] || continue
    for path in $(grep -oE 'tools/[a-z0-9-]+\.sh' "$doc" | sort -u); do
      found=$((found + 1))
      [ -f "$TARGET/$path" ] \
        || fail "installed docs name a tool absent from the target: $path (in ${doc##*/})"
      [ -x "$TARGET/$path" ] \
        || fail "installed tool is not executable: $path"
    done
  done
  [ "$found" -gt 0 ] || fail "installed docs name no tools at all — the scan found nothing to check"
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
  local contract="$TARGET/docs/contracts/v1.md" path found=0
  for path in $(grep -oE 'checked: `[^`]+`' "$contract" | sed 's/checked: `\(.*\)`/\1/' | sort -u); do
    found=$((found + 1))
    [ -f "$TARGET/$path" ] \
      || fail "installed Contract names a check absent from the target: $path"
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
    || fail "installed Contract differs from this repository's own copy"
}

# A structural guard rather than a behavioural one: the drift can only come back by
# reintroducing a second copy for the installer to read.
test_ship_no_second_copy_of_the_briefs_docs_exists() {
  assert_no_dir "$REPO_ROOT/templates/docs"
}

# The Contract is installer-owned, so --force takes this checkout over a stale copy.
test_ship_force_replaces_a_stale_contract() {
  mkdir -p "$TARGET/docs/contracts"
  echo "OLD CONTRACT" > "$TARGET/docs/contracts/v1.md"
  run_install y --force --target "$TARGET"
  assert_status 0
  assert_not_contains "OLD CONTRACT" "$TARGET/docs/contracts/v1.md"
  assert_contains "BRIEFS-1" "$TARGET/docs/contracts/v1.md"
}

# Default posture is unchanged: a project that tuned its Contract keeps it.
test_ship_without_force_keeps_a_projects_own_contract() {
  mkdir -p "$TARGET/docs/contracts"
  echo "PROJECT-OWNED CONTRACT" > "$TARGET/docs/contracts/v1.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_contains "PROJECT-OWNED CONTRACT" "$TARGET/docs/contracts/v1.md"
}
