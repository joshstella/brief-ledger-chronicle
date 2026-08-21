# Host selection: one source tree, two layouts.
#
# The six process skills are the only ones that move between destinations — Cursor takes
# every skill as a skill, Claude Code takes those six as slash-commands instead. These
# tests pin both layouts and, more importantly, pin that neither host leaks the other's
# files into a project.

PROCESS="commit-push-pr create-brief init-briefs next-brief-phase review-pr start-brief"
UTILITY="chronicle installer-builder ste-writing to-do"

# ── Cursor ───────────────────────────────────────────────────────────────────

test_host_cursor_installs_every_skill_under_cursor_skills() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  local s
  for s in $PROCESS $UTILITY; do
    assert_file "$TARGET/.cursor/skills/$s/SKILL.md"
  done
}

test_host_cursor_writes_agents_md_not_claude_md() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file    "$TARGET/AGENTS.md"
  assert_no_file "$TARGET/CLAUDE.md"
}

# A Cursor install that quietly scattered .claude/ through the project would be a
# surprise, and the reverse holds below.
#
# `assert_status 0` is load-bearing, not decoration. Without it this test is satisfied by
# an installer that crashed before creating anything — mutation testing found exactly
# that: forcing the settings step to run under Cursor makes `cp` fail into a directory
# that was never scaffolded, `set -e` aborts, and "no .claude/" becomes trivially true.
# Any test built only from negative assertions needs a success assertion beside them.
test_host_cursor_creates_no_claude_directory() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_no_dir  "$TARGET/.claude"
  assert_no_file "$TARGET/.claude/settings.local.json"
}

test_host_cursor_still_writes_the_shared_docs_scaffold() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/docs/briefs/README.md"
  assert_file "$TARGET/docs/briefs/_drafts/README.md"
  assert_file "$TARGET/docs/install-log/install-log.md"
  assert_dir  "$TARGET/docs/chronicles"
}

# ── Claude Code ──────────────────────────────────────────────────────────────

test_host_claude_splits_process_skills_into_commands() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  local s
  for s in $PROCESS; do
    assert_file   "$TARGET/.claude/commands/$s.md"
    assert_no_dir "$TARGET/.claude/skills/$s"
  done
  for s in $UTILITY; do
    assert_file      "$TARGET/.claude/skills/$s/SKILL.md"
    assert_no_file   "$TARGET/.claude/commands/$s.md"
  done
}

test_host_claude_creates_no_cursor_directory() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_no_dir  "$TARGET/.cursor"
  assert_no_file "$TARGET/AGENTS.md"
}

test_host_claude_is_the_default() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_dir    "$TARGET/.claude"
  assert_no_dir "$TARGET/.cursor"
}

# The frontmatter is what lets one file serve both hosts — Cursor requires it, and Claude
# Code accepts it on a command. If it were stripped on the way out, Cursor installs would
# silently produce skills it cannot index.
test_host_shared_frontmatter_survives_into_both_layouts() {
  run_install y --host claude --target "$TARGET"
  assert_matches "^name: review-pr" "$TARGET/.claude/commands/review-pr.md"
  rm -rf "$TARGET"; mkdir -p "$TARGET"
  run_install y --host cursor --target "$TARGET"
  assert_matches "^name: review-pr" "$TARGET/.cursor/skills/review-pr/SKILL.md"
}

# On Claude Code a process skill is flattened to a single commands/<name>.md file, so
# anything else in its directory would be silently dropped. That is fine today because
# every process skill is SKILL.md and nothing else — but the day one grows a helper
# script or an asset, the install would quietly lose it. Fail here instead, at the moment
# the file is added, rather than in whatever breaks downstream.
test_host_process_skills_carry_no_auxiliary_files() {
  local s count
  for s in $PROCESS; do
    count=$(find "$REPO_ROOT/skills/$s" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" != "1" ]; then
      fail "skills/$s has $count files; Claude Code installs it flat as commands/$s.md, so only SKILL.md would survive. Either keep it single-file or teach step 5 to place a directory."
    fi
  done
}

# ── Host argument handling ───────────────────────────────────────────────────

test_host_unknown_value_is_rejected() {
  run_install y --host emacs --target "$TARGET"
  assert_status 1
  assert_err "unknown host 'emacs'"
  assert_no_dir "$TARGET/docs"
}

# Machine mode links Claude Code's user-level config; there is no Cursor equivalent.
# Silently ignoring --host cursor there would install the wrong thing without saying so.
test_host_machine_mode_rejects_cursor() {
  run_install y --machine --host cursor
  assert_status 1
  assert_err "--machine is Claude Code only"
  assert_no_file "$CLAUDE_HOME_DIR/CLAUDE.md"
}

test_host_is_recorded_in_the_install_log() {
  run_install y --host cursor --target "$TARGET"
  assert_contains "**Host:** cursor" "$TARGET/docs/install-log/install-log.md"
}

# ── Non-interactive install ──────────────────────────────────────────────────

# Without --yes the installer waits on a prompt, which makes it unusable from a script
# or a CI step. Answering "n" here proves the flag is what allowed the install, not the
# piped input.
test_host_yes_flag_installs_without_a_prompt() {
  run_install n --yes --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/CLAUDE.md"
  assert_not_contains "Aborted." "$OUT"
}

test_host_yes_flag_works_for_machine_mode() {
  run_install n --machine --yes
  assert_status 0
  assert_symlink_to "$CLAUDE_HOME_DIR/CLAUDE.md" "$REPO_ROOT/personal/CLAUDE.md"
}
