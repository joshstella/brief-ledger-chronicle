# Upgrade from the old layout: an install from before #0017 wrote its trees straight under
# docs/. An upgrade moves them under docs/blc/. These tests cover what stops that move
# before anything is written, and what the prompt says will move.

# An old-layout install: one brief, one ledger, a toolkit-owned README, and an install log.
up_old_layout() {
  mkdir -p "$TARGET/docs/briefs/0001-first" "$TARGET/docs/install-log"
  printf '# Brief\n' > "$TARGET/docs/briefs/0001-first/brief.md"
  printf '# Ledger\n' > "$TARGET/docs/briefs/0001-first/ledger.md"
  printf 'old toolkit copy\n' > "$TARGET/docs/briefs/README.md"
  printf '# Install log\n' > "$TARGET/docs/install-log/install-log.md"
}

# What an upgrade between #0017's phases a and c left: the new tree beside the old one,
# with the toolkit's files and its own install log, but none of the project's.
up_half_upgraded() {
  mkdir -p "$TARGET/docs/blc/briefs" "$TARGET/docs/blc/install-log"
  printf 'new toolkit copy\n' > "$TARGET/docs/blc/briefs/README.md"
  printf '# Install log\n' > "$TARGET/docs/blc/install-log/install-log.md"
}

test_upgrade_refuses_a_docs_blc_the_toolkit_did_not_install() {
  mkdir -p "$TARGET/docs/blc/notes"
  printf 'mine\n' > "$TARGET/docs/blc/notes/plan.md"
  run_install y --target "$TARGET"
  assert_status 1
  assert_err "holds files this toolkit did not install"
  assert_err "Nothing was written"
  assert_no_dir "$TARGET/.claude"
  assert_no_file "$TARGET/.gitignore"
  assert_file "$TARGET/docs/blc/notes/plan.md"
}

# Only files make docs/blc/ the project's. Empty directories hold nothing to mix.
test_upgrade_installs_into_an_empty_docs_blc() {
  mkdir -p "$TARGET/docs/blc/briefs"
  run_install y --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/docs/blc/install-log/install-log.md"
}

test_upgrade_installs_over_its_own_docs_blc() {
  run_install y --target "$TARGET"
  assert_status 0
  printf '# Brief\n' > "$TARGET/docs/blc/briefs/notes.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_not_contains "did not install" "$ERR"
}

test_upgrade_refuses_a_project_file_in_both_trees() {
  up_old_layout
  up_half_upgraded
  mkdir -p "$TARGET/docs/blc/briefs/0001-first"
  printf '# Other brief\n' > "$TARGET/docs/blc/briefs/0001-first/brief.md"
  run_install y --target "$TARGET"
  assert_status 1
  assert_err "docs/briefs/0001-first/brief.md → docs/blc/briefs/0001-first/brief.md"
  assert_not_contains "ledger.md" "$ERR"
  assert_err "Nothing was written"
  assert_no_dir "$TARGET/.claude"
  assert_file "$TARGET/docs/briefs/0001-first/ledger.md"
}

# The install replaces the toolkit's own docs, so an old copy beside a new one is not a
# choice the project has to make.
test_upgrade_does_not_count_toolkit_docs_as_clashes() {
  up_old_layout
  up_half_upgraded
  run_install n --target "$TARGET"
  assert_status 0
  assert_not_contains "exist in both" "$ERR"
  assert_not_contains "docs/briefs/README.md →" "$OUT"
  assert_out "Old copies of the toolkit's own docs are dropped"
}

# Both logs existing is the half-upgraded case, and the logs are joined, not compared.
test_upgrade_does_not_count_the_install_log_as_a_clash() {
  up_old_layout
  up_half_upgraded
  run_install n --target "$TARGET"
  assert_status 0
  assert_out "docs/install-log/install-log.md → docs/blc/install-log/install-log.md (joined, old entries first)"
}

test_upgrade_prompt_lists_each_project_file_that_moves() {
  up_old_layout
  printf 'here\n' > "$TARGET/docs/orientation.md"
  run_install n --target "$TARGET"
  assert_status 0
  assert_out "This target has the old layout"
  assert_out "docs/briefs/0001-first/brief.md → docs/blc/briefs/0001-first/brief.md"
  assert_out "docs/briefs/0001-first/ledger.md → docs/blc/briefs/0001-first/ledger.md"
  assert_out "docs/orientation.md → docs/blc/orientation.md"
}

test_upgrade_prompt_is_silent_without_the_old_layout() {
  run_install n --target "$TARGET"
  assert_status 0
  assert_not_contains "old layout" "$OUT"
}

up_old_entry() {
  printf '# Install log\n\n## 2026-01-01T00:00:00Z — oldbox\n\n- **Host:** cursor\n' \
    > "$TARGET/docs/install-log/install-log.md"
}

test_upgrade_moves_each_project_file_under_docs_blc() {
  up_old_layout
  mkdir -p "$TARGET/docs/state" "$TARGET/docs/chronicles"
  printf 'declared\n' > "$TARGET/docs/state/me@example.org.md"
  printf 'story\n' > "$TARGET/docs/chronicles/chronicle.md"
  printf 'here\n' > "$TARGET/docs/orientation.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_contains "# Brief" "$TARGET/docs/blc/briefs/0001-first/brief.md"
  assert_contains "# Ledger" "$TARGET/docs/blc/briefs/0001-first/ledger.md"
  assert_contains "declared" "$TARGET/docs/blc/state/me@example.org.md"
  assert_contains "story" "$TARGET/docs/blc/chronicles/chronicle.md"
  assert_contains "here" "$TARGET/docs/blc/orientation.md"
  assert_out "[→] docs/briefs/0001-first/brief.md → docs/blc/briefs/0001-first/brief.md"
}

test_upgrade_leaves_one_tree_not_two() {
  up_old_layout
  mkdir -p "$TARGET/docs/contracts"
  printf 'old\n' > "$TARGET/docs/contracts/v1.md"
  printf 'here\n' > "$TARGET/docs/orientation.md"
  run_install y --target "$TARGET"
  assert_status 0
  for old in briefs contracts chronicles state install-log; do
    assert_no_dir "$TARGET/docs/$old"
  done
  assert_no_file "$TARGET/docs/orientation.md"
}

test_upgrade_drops_the_old_toolkit_docs_and_installs_current_ones() {
  up_old_layout
  run_install y --target "$TARGET"
  assert_status 0
  assert_out "docs/briefs/README.md (old copy of a toolkit file — dropped, replaced below)"
  assert_not_contains "old toolkit copy" "$TARGET/docs/blc/briefs/README.md"
  assert_contains "How work is specified" "$TARGET/docs/blc/briefs/README.md"
}

test_upgrade_moves_the_install_log_when_there_is_no_new_one() {
  up_old_layout
  up_old_entry
  run_install y --target "$TARGET"
  assert_status 0
  local log="$TARGET/docs/blc/install-log/install-log.md"
  assert_contains "oldbox" "$log"
  assert_count 2 "$(count_log_entries "$log")" "log entries: the old one and this run"
  assert_count 1 "$(grep -c '^# Install log' "$log")" "log headers"
}

test_upgrade_joins_two_install_logs_oldest_first() {
  up_old_layout
  up_old_entry
  up_half_upgraded
  printf '\n## 2026-09-01T00:00:00Z — midbox\n\n- **Host:** cursor\n' \
    >> "$TARGET/docs/blc/install-log/install-log.md"
  run_install y --target "$TARGET"
  assert_status 0
  local log="$TARGET/docs/blc/install-log/install-log.md"
  assert_count 3 "$(count_log_entries "$log")" "log entries: old, half-upgrade, this run"
  assert_count 1 "$(grep -c '^# Install log' "$log")" "log headers"
  extract_log_entry "$log" 1 "$TMP/first"
  extract_log_entry "$log" 2 "$TMP/second"
  assert_contains "oldbox" "$TMP/first"
  assert_contains "midbox" "$TMP/second"
  assert_no_dir "$TARGET/docs/install-log"
}

# The prune reads the log to find what earlier installs put here. It must run on the
# joined log, or an upgrade forgets every skill the old installs recorded.
test_upgrade_prunes_stale_skills_the_old_log_recorded() {
  up_old_layout
  printf '# Install log\n\n## 2026-01-01T00:00:00Z — oldbox\n\n### Skills installed\n  - zzz-stale-skill\n' \
    > "$TARGET/docs/install-log/install-log.md"
  mkdir -p "$TARGET/.cursor/skills/zzz-stale-skill"
  printf 'OLD\n' > "$TARGET/.cursor/skills/zzz-stale-skill/SKILL.md"
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_no_dir "$TARGET/.cursor/skills/zzz-stale-skill"
}

test_upgrade_moves_nothing_on_the_next_run() {
  up_old_layout
  run_install y --target "$TARGET"
  assert_status 0
  run_install y --target "$TARGET"
  assert_status 0
  assert_not_contains "old layout" "$OUT"
  assert_not_contains "[→]" "$OUT"
}

test_upgrade_logs_each_move_and_each_dropped_copy() {
  up_old_layout
  run_install y --target "$TARGET"
  assert_status 0
  local log="$TARGET/docs/blc/install-log/install-log.md"
  extract_log_entry "$log" 1 "$TMP/entry"
  assert_contains "### Moved — old docs/ layout to docs/blc/" "$TMP/entry"
  assert_contains "  - docs/briefs/0001-first/brief.md → docs/blc/briefs/0001-first/brief.md" "$TMP/entry"
  assert_contains "  - docs/briefs/README.md (old copy of a toolkit file — dropped)" "$TMP/entry"
  assert_out "Moved from the old docs/ layout (3):"
}

test_upgrade_logs_no_moved_section_when_nothing_moved() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_not_contains "### Moved" "$TARGET/docs/blc/install-log/install-log.md"
  assert_not_contains "Moved from" "$OUT"
  assert_not_contains "ignore-revs" "$OUT"
}

# The closing instruction is a command the project runs. Run it, and check that the tools
# then date the brief by its own work, not by the move.
test_upgrade_ignore_instruction_keeps_each_brief_dated() {
  git -C "$TARGET" init -q -b main
  git -C "$TARGET" config user.email t@example.com
  git -C "$TARGET" config user.name Test
  mkdir -p "$TARGET/docs/briefs/0001-first"
  printf '# First\n' > "$TARGET/docs/briefs/0001-first/brief.md"
  printf '# Ledger\n\n`blc/2 #0001 in-progress a:pending`\n' > "$TARGET/docs/briefs/0001-first/ledger.md"
  git -C "$TARGET" add -A
  GIT_AUTHOR_DATE="2026-03-01T12:00:00-04:00" GIT_COMMITTER_DATE="2026-03-01T12:00:00-04:00" \
    git -C "$TARGET" commit -qm "brief" >/dev/null
  run_install y --target "$TARGET"
  assert_status 0
  local cmd
  cmd="$(grep -o 'echo "\$(git rev-parse HEAD).*ignore-revs' "$OUT")"
  [ -n "$cmd" ] || fail "expected the ignore-revs command in the output"
  git -C "$TARGET" add -A
  GIT_AUTHOR_DATE="2026-10-02T12:00:00-04:00" GIT_COMMITTER_DATE="2026-10-02T12:00:00-04:00" \
    git -C "$TARGET" commit -qm "install" >/dev/null
  (cd "$TARGET" && eval "$cmd")
  (cd "$TARGET" && bash tools/list-briefs.sh) > "$TMP/list" 2>&1
  assert_contains "2026-03-01T12:00:00-04:00 | 2026-03-01T12:00:00-04:00" "$TMP/list"
}

test_upgrade_refuses_a_symlinked_old_tree() {
  mkdir -p "$TMP/elsewhere/0001-first"
  printf '# Brief\n' > "$TMP/elsewhere/0001-first/brief.md"
  mkdir -p "$TARGET/docs"
  ln -s "$TMP/elsewhere" "$TARGET/docs/briefs"
  run_install y --target "$TARGET"
  assert_status 1
  assert_err "docs/briefs is a symlink"
  assert_no_dir "$TARGET/.claude"
}
