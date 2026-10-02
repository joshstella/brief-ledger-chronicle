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
