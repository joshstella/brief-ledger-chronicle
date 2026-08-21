# The install log: an append-only record of every run, replacing the numbered
# bootstrap brief the installer used to write.

LOG_REL="docs/install-log/install-log.md"

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

test_log_entry_records_version_skills_and_commands() {
  run_install y --target "$TARGET"
  assert_contains "**Installer version:**" "$TARGET/$LOG_REL"
  assert_contains "### Skills installed"   "$TARGET/$LOG_REL"
  assert_contains "### Commands installed" "$TARGET/$LOG_REL"
  assert_contains "  - review-pr"          "$TARGET/$LOG_REL"
}

test_log_first_entry_lists_what_was_created() {
  run_install y --target "$TARGET"
  extract_log_entry "$TARGET/$LOG_REL" 1 "$TMP/entry1.txt"
  assert_contains "### Created"            "$TMP/entry1.txt"
  assert_contains "CLAUDE.md"              "$TMP/entry1.txt"
  assert_contains "### Skipped — already present" "$TMP/entry1.txt"
}

test_log_second_entry_reports_nothing_created() {
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  extract_log_entry "$TARGET/$LOG_REL" 2 "$TMP/entry2.txt"
  assert_contains "**Created:** 0" "$TMP/entry2.txt"
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
