# --force: replace installer-owned copies, leave the project's own record alone.
#
# Default install pins whatever a project was onboarded with. --force is the
# explicit opt-in to take this checkout over those copies. Numbered briefs,
# ledgers, chronicles, and the install log are not installer-owned.

test_force_help_documents_the_flag() {
  run_install "" --help
  assert_status 0
  assert_out "--force"
  assert_out "Project mode only"
}

test_force_is_rejected_in_machine_mode() {
  run_install y --machine --force
  assert_status 1
  assert_err "--force is project mode only"
  assert_no_file "$CLAUDE_HOME_DIR/CLAUDE.md"
}

test_force_does_not_overwrite_an_existing_claude_md() {
  echo "PROJECT-OWNED CONTENT" > "$TARGET/CLAUDE.md"
  run_install y --force --target "$TARGET"
  assert_status 0
  assert_contains "PROJECT-OWNED CONTENT" "$TARGET/CLAUDE.md"
  assert_out "CLAUDE.md (already exists, skipped)"
  assert_not_contains "CLAUDE.md (replaced)" "$OUT"
  assert_file "$TARGET/.claude/rules/brief-ledger-chronicle.md"
}

test_force_overwrites_a_tuned_command() {
  mkdir -p "$TARGET/.claude/commands"
  echo "LOCALLY TUNED" > "$TARGET/.claude/commands/review-pr.md"
  run_install y --force --target "$TARGET"
  assert_status 0
  assert_not_contains "LOCALLY TUNED" "$TARGET/.claude/commands/review-pr.md"
  assert_matches "^name: review-pr" "$TARGET/.claude/commands/review-pr.md"
  assert_out ".claude/commands/review-pr.md (replaced)"
}

test_force_overwrites_a_tuned_cursor_skill() {
  mkdir -p "$TARGET/.cursor/skills/ste-writing"
  echo "OLD SKILL" > "$TARGET/.cursor/skills/ste-writing/SKILL.md"
  run_install y --host cursor --force --target "$TARGET"
  assert_status 0
  assert_not_contains "OLD SKILL" "$TARGET/.cursor/skills/ste-writing/SKILL.md"
  assert_contains "Default writing style for brief-ledger-chronicle" \
                  "$TARGET/.cursor/skills/ste-writing/SKILL.md"
  assert_out ".cursor/skills/ste-writing (replaced)"
}

test_force_does_not_overwrite_agents_md() {
  echo "PROJECT-OWNED AGENTS" > "$TARGET/AGENTS.md"
  run_install y --host cursor --force --target "$TARGET"
  assert_status 0
  assert_contains "PROJECT-OWNED AGENTS" "$TARGET/AGENTS.md"
  assert_out "AGENTS.md (already exists, skipped)"
  assert_not_contains "AGENTS.md (replaced)" "$OUT"
  assert_file "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
}

test_force_replaces_cursor_process_rules() {
  mkdir -p "$TARGET/.cursor/rules"
  echo "OLD PROCESS" > "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
  run_install y --host cursor --force --target "$TARGET"
  assert_status 0
  assert_not_contains "OLD PROCESS" "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
  assert_contains "alwaysApply: true" "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
  assert_out ".cursor/rules/brief-ledger-chronicle.mdc (replaced)"
}

test_force_replaces_claude_process_rules() {
  mkdir -p "$TARGET/.claude/rules"
  echo "OLD PROCESS" > "$TARGET/.claude/rules/brief-ledger-chronicle.md"
  run_install y --force --target "$TARGET"
  assert_status 0
  assert_not_contains "OLD PROCESS" "$TARGET/.claude/rules/brief-ledger-chronicle.md"
  assert_contains "ste-writing" "$TARGET/.claude/rules/brief-ledger-chronicle.md"
  assert_out ".claude/rules/brief-ledger-chronicle.md (replaced)"
}

test_force_overwrites_an_existing_briefs_readme() {
  mkdir -p "$TARGET/docs/briefs"
  echo "EXISTING REGISTRY DOCS" > "$TARGET/docs/briefs/README.md"
  run_install y --force --target "$TARGET"
  assert_status 0
  assert_not_contains "EXISTING REGISTRY DOCS" "$TARGET/docs/briefs/README.md"
  assert_contains "How work is specified" "$TARGET/docs/briefs/README.md"
}

# The reason the installer stopped writing briefs: --force must not revive that.
test_force_leaves_an_existing_brief_untouched() {
  mkdir -p "$TARGET/docs/briefs/0007-something"
  echo "ORIGINAL BRIEF" > "$TARGET/docs/briefs/0007-something/brief.md"
  run_install y --force --target "$TARGET"
  assert_status 0
  assert_contains "ORIGINAL BRIEF" "$TARGET/docs/briefs/0007-something/brief.md"
  assert_count 1 "$(count_numbered_briefs "$TARGET")" "numbered brief folders"
}

test_force_does_not_create_a_numbered_brief() {
  run_install y --force --target "$TARGET"
  assert_status 0
  assert_count 0 "$(count_numbered_briefs "$TARGET")" "numbered brief folders created"
  assert_no_dir "$TARGET/docs/briefs/0001-bootstrap"
}

# An upgrade is still an append. Truncating the log to look "current" would
# destroy the history --force exists to record.
test_force_appends_the_install_log() {
  run_install y --target "$TARGET"
  run_install y --force --target "$TARGET"
  assert_status 0
  local n
  n=$(grep -c '^# Install log' "$TARGET/docs/install-log/install-log.md" 2>/dev/null || true)
  assert_count 1 "$n" "header occurrences"
  assert_count 2 "$(count_log_entries "$TARGET/docs/install-log/install-log.md")" "log entries"
  extract_log_entry "$TARGET/docs/install-log/install-log.md" 2 "$TMP/force-entry.txt"
  assert_contains "**Replaced:**" "$TMP/force-entry.txt"
}

# Without --force the pin still holds. This is the same contract as
# test_project_never_overwrites_an_existing_claude_md; it lives here so a
# regression that makes --force the default fails a test named for force.
test_force_absent_still_skips_existing_claude_md() {
  echo "PROJECT-OWNED CONTENT" > "$TARGET/CLAUDE.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_contains "PROJECT-OWNED CONTENT" "$TARGET/CLAUDE.md"
  assert_out "CLAUDE.md (already exists, skipped)"
  assert_not_contains "CLAUDE.md (replaced)" "$OUT"
}
