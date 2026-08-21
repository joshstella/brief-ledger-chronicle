# Machine mode: the once-per-machine symlink install into $CLAUDE_HOME.
#
# CLAUDE_HOME is overridable precisely so these can run without touching the real
# ~/.claude. Each test gets a fresh one from setup().

test_machine_links_the_personal_agreement_and_brief_template() {
  run_install y --machine
  assert_status 0
  assert_symlink_to "$CLAUDE_HOME_DIR/CLAUDE.md" \
                    "$REPO_ROOT/personal/CLAUDE.md"
  assert_symlink_to "$CLAUDE_HOME_DIR/briefs/README.template.md" \
                    "$REPO_ROOT/templates/docs/briefs/README.md"
}

# One link per process skill, not one for a whole directory: the single source tree
# stores these as skills/<name>/SKILL.md while Claude Code wants commands/<name>.md, so
# the shapes no longer match. Linking each file preserves what machine mode exists for —
# `git pull` updating every machine at once — which copying would lose.
test_machine_links_each_process_skill_as_a_command() {
  run_install y --machine
  assert_status 0
  local s
  for s in commit-push-pr create-brief init-briefs next-brief-phase review-pr start-brief; do
    assert_symlink_to "$CLAUDE_HOME_DIR/commands/$s.md" \
                      "$REPO_ROOT/skills/$s/SKILL.md"
  done
}

# Only the six process skills become commands. Linking the utility skills machine-wide
# would override the per-project copies they are meant to be.
test_machine_links_no_utility_skills_as_commands() {
  run_install y --machine
  assert_status 0
  local s
  for s in chronicle ste-writing to-do installer-builder; do
    assert_no_file "$CLAUDE_HOME_DIR/commands/$s.md"
  done
}

# Skills are deliberately per-project so they can be tuned. Linking them
# machine-wide would silently override that.
test_machine_does_not_link_skills() {
  run_install y --machine
  assert_no_dir "$CLAUDE_HOME_DIR/skills"
}

test_machine_rerun_skips_links_that_are_already_correct() {
  run_install y --machine
  run_install y --machine
  assert_status 0
  assert_out "already linked correctly"
}

# The case the machine mode exists for: a previous config repo was deleted, so the
# link resolves to nothing. It cannot be content anyone would lose, so it is safe
# to replace.
test_machine_replaces_a_dangling_link() {
  mkdir -p "$CLAUDE_HOME_DIR"
  ln -s "$TMP/deleted-config-repo/CLAUDE.md" "$CLAUDE_HOME_DIR/CLAUDE.md"
  run_install y --machine
  assert_status 0
  assert_symlink_to "$CLAUDE_HOME_DIR/CLAUDE.md" "$REPO_ROOT/personal/CLAUDE.md"
  assert_out "replaced dangling symlink"
}

test_machine_refuses_to_clobber_a_real_file() {
  mkdir -p "$CLAUDE_HOME_DIR"
  echo "HAND-ROLLED CONFIG" > "$CLAUDE_HOME_DIR/CLAUDE.md"
  run_install y --machine
  assert_contains "HAND-ROLLED CONFIG" "$CLAUDE_HOME_DIR/CLAUDE.md"
  assert_out "Conflicts — resolve by hand"
}

test_machine_refuses_a_symlink_pointing_somewhere_else() {
  mkdir -p "$CLAUDE_HOME_DIR" "$TMP/other"
  echo "SOMEONE ELSES CONFIG" > "$TMP/other/CLAUDE.md"
  ln -s "$TMP/other/CLAUDE.md" "$CLAUDE_HOME_DIR/CLAUDE.md"
  run_install y --machine
  assert_symlink_to "$CLAUDE_HOME_DIR/CLAUDE.md" "$TMP/other/CLAUDE.md"
  assert_out "Conflicts — resolve by hand"
}

# Machine mode is documented as the first step on a clean machine, so it must not
# gate on the project toolchain — that check would block the one step that fixes a
# machine which cannot yet run anything.
test_machine_mode_needs_no_project_toolchain() {
  run_install_with_path "/usr/bin:/bin" y --machine
  assert_status 0
  assert_symlink_to "$CLAUDE_HOME_DIR/CLAUDE.md" "$REPO_ROOT/personal/CLAUDE.md"
}

test_machine_declining_the_prompt_links_nothing() {
  run_install n --machine
  assert_status 0
  assert_out "Aborted."
  assert_no_file "$CLAUDE_HOME_DIR/CLAUDE.md"
}

test_machine_writes_nothing_into_a_project() {
  run_install y --machine
  assert_no_dir "$TARGET/.claude"
  assert_no_dir "$TARGET/docs"
}
