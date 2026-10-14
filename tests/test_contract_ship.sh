# What a target receives of the briefs Contract, and the check the Contract names.
#
# Phase 1 shipped the rules restated in a second README copy. Phase 4 ships the
# Contract itself, from this repository's own docs/, so no second copy exists to
# hand-sync. These tests pin the two things that makes possible and the two ways
# it could become a lie: a rule document whose links dangle in the target, and a
# `checked:` path naming a script that was never installed.

# Every version this repository holds, not a list of them. `install.sh` decides what to ship
# with the same glob over the same directory, so a list written out here could only ever lag
# that one — which is how v1.4 and v1.5 came to install unasserted. This stays correct while
# the installer stays derived; if it ever goes back to naming versions, the two lists are
# again two things to keep in step, and this test would agree with the tree against the target.
#
# The floor belongs to the caller, not in here. A `fail` inside `$( )` dies in the subshell,
# the loop reads an empty list, and the test passes having checked nothing — the same shape
# of silence this brief is about.
contract_versions_here() {
  local v
  for v in "$REPO_ROOT"/docs/blc/contracts/v*.md; do
    [ -f "$v" ] || continue
    printf '%s\n' "${v##*/}"
  done
}

test_ship_places_the_contract() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/docs/blc/contracts/README.md"
  local name found=0
  for name in $(contract_versions_here); do
    found=$((found + 1))
    assert_file "$TARGET/docs/blc/contracts/$name"
    # Asserted over every version, v1.md included. The list this replaced started at v1.1,
    # which read as a judgment that v1.md does not carry the clause. It does, once rather
    # than twice: the later versions restate it in their change note. The omission was a
    # list written before v1.md was worth adding to it.
    assert_contains "BRIEFS-1" "$TARGET/docs/blc/contracts/$name"
  done
  [ "$found" -gt 0 ] || fail "no contract version in this repository — the scan checked nothing"
}

test_ship_places_the_contract_for_cursor_too() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/docs/blc/contracts/README.md"
  local name found=0
  for name in $(contract_versions_here); do
    found=$((found + 1))
    assert_file "$TARGET/docs/blc/contracts/$name"
  done
  [ "$found" -gt 0 ] || fail "no contract version in this repository — the scan checked nothing"
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
  local doc path found=0 scanned=0
  # Every document install.sh ships under docs/, not the ones that happen to name a
  # tool today. The property is about the shipped set; scanning a subset of it would
  # let a tool named in the omitted document go unchecked.
  #
  # So the set is read from the target rather than written out. The list that used to sit
  # here was exactly the subset this comment warns about: it ended at v1.3, and it never
  # covered docs/blc/state/README.md, which install.sh has always shipped.
  while IFS= read -r doc; do
    # Not redundant after `find -type f`: a `find` that matched nothing still feeds this loop
    # one empty line, and the floor below is what has to catch that, not a stat on "".
    [ -f "$doc" ] || continue
    scanned=$((scanned + 1))
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
  done <<EOF
$(find "$TARGET/docs" -type f -name '*.md' | sort)
EOF
  [ "$scanned" -gt 0 ] || fail "the target has no documents under docs/ — the scan read nothing"
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

# open-briefs.sh exits 2 without the detector beside it, so a target that got one and not the
# other would have a query that cannot run. Asserted by running it, not by listing files.
test_ship_places_an_open_briefs_query_that_runs() {
  run_install y --target "$TARGET"
  assert_status 0
  [ -x "$TARGET/tools/detect-forge.sh" ] || fail "installed detect-forge.sh is not executable"
  git -C "$TARGET" init -q 2>/dev/null
  ( cd "$TARGET" && PATH="/usr/bin:/bin" ./tools/open-briefs.sh docs/blc/briefs ) >"$TMP/q.txt" 2>&1
  assert_count 0 "$?" "open-briefs exit status in a fresh target"
  assert_contains "open-briefs: docs/blc/briefs" "$TMP/q.txt"
}

# Run in a target with no briefs, it must get far enough to say so: a missing library stops
# it earlier, with a different message.
test_ship_places_a_jira_export_that_runs() {
  run_install y --target "$TARGET"
  assert_status 0
  [ -x "$TARGET/tools/jira-csv.sh" ] || fail "installed jira-csv.sh is not executable"
  ( cd "$TARGET" && PATH="/usr/bin:/bin" ./tools/jira-csv.sh 1 ) >"$TMP/j.txt" 2>&1
  assert_count 1 "$?" "jira-csv exit status in a fresh target"
  assert_contains "no brief #0001 in docs/blc/briefs" "$TMP/j.txt"
}

# The rules without the check would be a Contract whose strongest claim is backed
# by nothing in the tree that holds it.
test_ship_places_a_validator_that_runs() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/tools/validate-briefs.sh"
  [ -x "$TARGET/tools/validate-briefs.sh" ] \
    || fail "installed validator is not executable"
  "$TARGET/tools/validate-briefs.sh" "$TARGET/docs/blc/briefs" >"$TMP/v.txt" 2>&1
  assert_count 0 "$?" "validator exit status against a fresh target"
  assert_contains "clauses decided" "$TMP/v.txt"
}

# The failure this phase could most easily introduce. The shipped README points at
# the Contract with a relative link, which resolves in this repository whether or
# not install.sh places docs/blc/contracts/ in the target.
test_ship_every_relative_link_in_the_briefs_readme_resolves() {
  run_install y --target "$TARGET"
  assert_status 0
  local readme="$TARGET/docs/blc/briefs/README.md" link found=0
  for link in $(grep -oE '\]\(\.\.?/[^)]+\)' "$readme" | sed 's/^](\(.*\))$/\1/' | sort -u); do
    found=$((found + 1))
    [ -e "$TARGET/docs/blc/briefs/$link" ] \
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
  local contract name path found=0 scanned=0
  for name in $(contract_versions_here); do
    contract="$TARGET/docs/blc/contracts/$name"
    [ -f "$contract" ] || continue
    scanned=$((scanned + 1))
    for path in $(grep -oE 'checked: `[^`]+`' "$contract" | sed 's/checked: `\(.*\)`/\1/' | sort -u); do
      found=$((found + 1))
      [ -f "$TARGET/$path" ] \
        || fail "installed ${contract##*/} names a check absent from the target: $path"
    done
  done
  # `scanned` and `found` answer different questions. A version that installed but names no
  # check leaves `found` where it was, and only the second floor would notice. A version that
  # did not install at all leaves both — but `ship_places_the_contract` is the test that owns
  # that failure, and this one should not report it in the wrong words.
  [ "$scanned" -gt 0 ] || fail "no contract version reached the target — the scan read nothing"
  [ "$found" -gt 0 ] || fail "installed Contract names no checks at all"
}

# The point of the phase. A target gets the file this repository lives by, not a
# copy of it — so the two cannot say different things.
test_ship_the_briefs_readme_is_this_repos_own_file() {
  run_install y --target "$TARGET"
  assert_status 0
  cmp -s "$REPO_ROOT/docs/blc/briefs/README.md" "$TARGET/docs/blc/briefs/README.md" \
    || fail "installed briefs README differs from this repository's own copy"
  # Every version in the tree, not a list of them. The versions were named one per line up
  # to v1.3, so publishing v1.4 added a file this test did not look at — a new Contract
  # could have installed wrong, or not installed at all, and the assertion about the
  # installed Contract would still have passed.
  local v name
  for v in "$REPO_ROOT"/docs/blc/contracts/v*.md; do
    name="${v##*/}"
    cmp -s "$v" "$TARGET/docs/blc/contracts/$name" \
      || fail "installed Contract $name differs from this repository's own copy"
  done
  return 0
}

# Publishing a version means marking the one before it superseded. Two versions that both say
# `current` leave a reader to guess which clause text binds.
#
# The expected name stays written out rather than derived from the highest version on disk.
# That is the point of it: publishing a version has to be a deliberate edit here, so a file
# dropped into the directory cannot promote itself to current without someone saying so.
#
# This is the one version name in this file that a sweep must leave alone, and the reason is
# not style. The other lists answered "what ships", which the tree is the authority for, so
# reading the tree made them right. This one answers "what did someone decide", which the tree
# cannot answer. Derive it and the test still passes, every time, having stopped checking the
# thing it exists for (#0038).
test_ship_exactly_one_contract_version_is_current() {
  local current
  current=$(grep -lx '\*\*Status:\*\* current' "$REPO_ROOT"/docs/blc/contracts/v*.md | sed 's#.*/##')
  assert_count "v1.5.md" "$current" "Contract versions marked current"
}

# A structural guard rather than a behavioural one: the drift can only come back by
# reintroducing a second copy for the installer to read.
test_ship_no_second_copy_of_the_briefs_docs_exists() {
  assert_no_dir "$REPO_ROOT/templates/docs"
}

# The Contract is toolkit-owned and replaced every run (#0012b).
test_ship_default_replaces_a_stale_contract() {
  mark_prior_install
  mkdir -p "$TARGET/docs/blc/contracts"
  # Staled over every version rather than the first three. A list here does not go
  # unasserted when a version is published — it goes unstaled, which looks the same from
  # the report: the newest Contract was the one whose replacement nobody proved.
  local name found=0
  for name in $(contract_versions_here); do
    found=$((found + 1))
    echo "OLD CONTRACT $name" > "$TARGET/docs/blc/contracts/$name"
  done
  [ "$found" -gt 0 ] || fail "no contract version in this repository — nothing was staled"
  run_install y --target "$TARGET"
  assert_status 0
  for name in $(contract_versions_here); do
    assert_not_contains "OLD CONTRACT" "$TARGET/docs/blc/contracts/$name"
    assert_contains "BRIEFS-1" "$TARGET/docs/blc/contracts/$name"
  done
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
  local readme="$TARGET/docs/blc/contracts/README.md" path absent=0
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
