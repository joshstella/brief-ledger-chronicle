# The install log: an append-only record of every run, replacing the numbered
# bootstrap brief the installer used to write.

LOG_REL="docs/blc/install-log/install-log.md"

test_log_is_created_on_first_install() {
  run_install y --target "$TARGET"
  assert_file    "$TARGET/$LOG_REL"
  assert_matches "^# Install log" "$TARGET/$LOG_REL"
}

test_log_has_one_entry_after_one_install() {
  run_install y --target "$TARGET"
  assert_count 1 "$(count_log_entries "$TARGET/$LOG_REL")" "log entries"
}

# An install is a recurring event. Re-running the installer to pick up new upstream
# commands is a real thing that happens and is worth a line.
test_log_appends_one_entry_per_run() {
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  assert_count 3 "$(count_log_entries "$TARGET/$LOG_REL")" "log entries"
}

test_log_header_is_written_only_once() {
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  local n
  n=$(grep -c '^# Install log' "$TARGET/$LOG_REL" 2>/dev/null || true)
  assert_count 1 "$n" "header occurrences"
}

# ── The version (#0023 b) ────────────────────────────────────────────────────
#
# The version identifies a build and promises nothing. The Contract carries every promise
# this toolkit makes, is versioned separately, and binds the briefs directory only. So the
# number is derived rather than chosen: the count orders, the hash identifies, and no human
# picks either. It is read from the source checkout with no network call, because the
# installer has never made one.

# A complete source tree the installer can run from, in a git repo the test controls.
log_source_repo() {
  local dest="$TMP/vsrc" d
  mkdir -p "$dest"
  cp "$REPO_ROOT/install.sh" "$dest/"
  for d in commands skills templates personal docs tools; do
    [ -e "$REPO_ROOT/$d" ] && cp -R "$REPO_ROOT/$d" "$dest/"
  done
  git -C "$dest" init -q .
  git -C "$dest" add -A >/dev/null 2>&1
  git -C "$dest" -c user.email=t@t -c user.name=t commit -qm one >/dev/null 2>&1
  echo "$dest"
}

test_log_version_is_the_commit_count_and_hash() {
  local src count sha
  src="$(log_source_repo)"
  run_install_from "$src" y --target "$TARGET"
  assert_status 0
  count="$(git -C "$src" rev-list --count HEAD)"
  sha="$(git -C "$src" rev-parse --short HEAD)"
  assert_contains "**Installer version:** $count+$sha" "$TARGET/$LOG_REL"
}

# A shallow clone counts only what it fetched, so a count read from one is wrong. Reporting
# it anyway would put a number in a target's log that orders against other targets and is
# believed. `--depth` is how CI checks out by default, so this is the likeliest way to hit it.
test_log_version_refuses_to_count_a_shallow_source() {
  local src shallow
  src="$(log_source_repo)"
  # A real clone, not a file touched to look like one. The fixture used to `touch .git/shallow`
  # and call that the same thing git tests for. It was not the same thing, and the difference
  # was only visible on one machine: the test passed everywhere developers run it and failed on
  # a newer CI runner image. A clone makes the condition by the mechanism the installer meets in
  # the field, so no claim about how git reads that file has to stay true.
  #
  # `--depth` needs a transport that can truncate history, so the source is named as a file://
  # URL rather than a path.
  shallow="$TMP/vsrc-shallow"
  if ! git clone -q --depth 1 "file://$src" "$shallow" 2>/dev/null; then
    fail "could not make a shallow clone of the fixture source"
    return
  fi
  # The fixture is checked, or a clone that quietly came back complete would let this test pass
  # while proving nothing — which is the failure being repaired.
  if [ "$(git -C "$shallow" rev-parse --is-shallow-repository)" != "true" ]; then
    fail "the fixture clone is not shallow, so this test would prove nothing"
    return
  fi
  run_install_from "$shallow" y --target "$TARGET"
  assert_status 0
  assert_contains "**Installer version:** unknown (shallow clone)" "$TARGET/$LOG_REL"
}

test_log_version_is_unknown_without_a_git_source() {
  local src
  src="$(log_source_repo)"
  rm -rf "$src/.git"
  run_install_from "$src" y --target "$TARGET"
  assert_status 0
  assert_contains "**Installer version:** unknown" "$TARGET/$LOG_REL"
}

test_log_entry_records_version_skills_and_commands() {
  run_install y --target "$TARGET"
  assert_contains "**Installer version:**" "$TARGET/$LOG_REL"
  assert_contains "### Skills installed"   "$TARGET/$LOG_REL"
  assert_contains "### Commands installed" "$TARGET/$LOG_REL"
  assert_contains "  - blc-review-pr"          "$TARGET/$LOG_REL"
}

test_log_first_entry_lists_what_was_created() {
  run_install y --target "$TARGET"
  extract_log_entry "$TARGET/$LOG_REL" 1 "$TMP/entry1.txt"
  assert_contains "### Created"            "$TMP/entry1.txt"
  assert_contains "CLAUDE.md"              "$TMP/entry1.txt"
  assert_contains "### Skipped — already present" "$TMP/entry1.txt"
}

test_log_second_entry_reports_replacements() {
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  extract_log_entry "$TARGET/$LOG_REL" 2 "$TMP/entry2.txt"
  assert_contains "**Created:** 0" "$TMP/entry2.txt"
  assert_contains "**Replaced:**" "$TMP/entry2.txt"
}

# An append is neither a create nor a skip. Recording it as skipped made the log
# list itself inside its own entry.
test_log_does_not_list_itself_as_skipped() {
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  extract_log_entry "$TARGET/$LOG_REL" 2 "$TMP/entry2.txt"
  sed -n '/### Skipped/,$p' "$TMP/entry2.txt" > "$TMP/skipped.txt"
  assert_not_contains "install-log.md" "$TMP/skipped.txt"
}

# The entry once carried a `Target:` field holding an absolute path, which put the
# operator's home-directory layout into a committed file for no benefit — the
# target is the repo holding the log.
test_log_leaks_no_absolute_target_path() {
  run_install y --target "$TARGET"
  assert_not_contains "$TARGET" "$TARGET/$LOG_REL"
  assert_not_contains "Target:" "$TARGET/$LOG_REL"
}

test_log_is_not_written_when_the_prompt_is_declined() {
  run_install n --target "$TARGET"
  assert_no_file "$TARGET/$LOG_REL"
}
