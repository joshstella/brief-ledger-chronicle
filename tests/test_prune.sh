# Prune stale skills and commands (#0012c). Removal reads the install log only.

LOG_REL="docs/install-log/install-log.md"

# The log parser reads names only from inside a ### Skills installed or ### Commands
# installed section. Appending at EOF lands under whatever section was last — usually
# Skipped — and the name is invisible to prune.
inject_logged_skill() {
  local name="$1" log="$TARGET/$LOG_REL"
  awk -v n="$name" '
    /^### Commands installed/ && !done { print "  - " n; done = 1 }
    { print }
  ' "$log" > "$TMP/log.tmp" && mv "$TMP/log.tmp" "$log"
}

inject_logged_command() {
  local name="$1" log="$TARGET/$LOG_REL"
  awk -v n="$name" '
    /^### Created/ && !done { print "  - " n; done = 1 }
    { print }
  ' "$log" > "$TMP/log.tmp" && mv "$TMP/log.tmp" "$log"
}

test_prune_removes_a_stale_skill_recorded_in_the_log() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  mkdir -p "$TARGET/.cursor/skills/zzz-stale-skill"
  echo "OLD" > "$TARGET/.cursor/skills/zzz-stale-skill/SKILL.md"
  inject_logged_skill "zzz-stale-skill"
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_no_dir "$TARGET/.cursor/skills/zzz-stale-skill"
  assert_out ".cursor/skills/zzz-stale-skill (removed — no longer shipped)"
  assert_contains ".cursor/skills/zzz-stale-skill" "$TARGET/$LOG_REL"
}

test_prune_leaves_a_custom_skill_the_log_never_recorded() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  mkdir -p "$TARGET/.cursor/skills/my-custom-skill"
  echo "MINE" > "$TARGET/.cursor/skills/my-custom-skill/SKILL.md"
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_contains "MINE" "$TARGET/.cursor/skills/my-custom-skill/SKILL.md"
}

test_prune_without_a_log_does_not_remove_anything() {
  mkdir -p "$TARGET/.cursor/skills/zzz-stale-skill"
  echo "OLD" > "$TARGET/.cursor/skills/zzz-stale-skill/SKILL.md"
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_out "no install log yet"
}

test_prune_refuses_a_symlinked_skills_directory() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  rm -rf "$TARGET/.cursor/skills"
  ln -s "$REPO_ROOT/skills" "$TARGET/.cursor/skills"
  inject_logged_skill "zzz-stale-skill"
  run_install y --host cursor --target "$TARGET"
  assert_status 1
  assert_err "refusing to prune"
  assert_symlink_to "$TARGET/.cursor/skills" "$REPO_ROOT/skills"
}

test_prune_records_removals_in_the_log_entry() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  mkdir -p "$TARGET/.cursor/skills/zzz-stale-skill"
  inject_logged_skill "zzz-stale-skill"
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  extract_log_entry "$TARGET/$LOG_REL" 2 "$TMP/entry2.txt"
  assert_contains "### Removed" "$TMP/entry2.txt"
  assert_contains ".cursor/skills/zzz-stale-skill" "$TMP/entry2.txt"
}

test_prune_removes_a_stale_command_on_claude() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  mkdir -p "$TARGET/.claude/commands"
  echo "OLD" > "$TARGET/.claude/commands/zzz-stale-cmd.md"
  inject_logged_command "zzz-stale-cmd"
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_no_file "$TARGET/.claude/commands/zzz-stale-cmd.md"
  assert_out ".claude/commands/zzz-stale-cmd.md (removed — no longer shipped)"
}
