# Host selection: one source tree, two layouts.
#
# The process skills are the only ones that move between destinations — Cursor takes
# every skill as a skill, Claude Code takes the process ones as slash-commands instead.
# These tests pin both layouts and, more importantly, pin that neither host leaks the
# other's files into a project.

PROCESS="blc-commit-push-pr blc-create-brief blc-create-draft blc-init-briefs blc-next-brief-phase blc-review-pr blc-start-brief"
UTILITY="blc-chronicle blc-installer-builder blc-my-briefs blc-orient blc-ste-writing"

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

# ── One agent file, two hosts (#0022 c) ──────────────────────────────────────
#
# AGENTS.md used to be the Cursor name and CLAUDE.md the Claude Code name, so a project
# installed for both got two files with the same text and nothing relating them. An edit to
# one left the other stale and nothing could tell. Now AGENTS.md holds the text on both
# hosts, and Claude Code gets CLAUDE.md as a link, because it reads AGENTS.md natively only
# from v2.1.277 and only when no CLAUDE.md is present.

test_host_claude_links_claude_md_to_agents_md() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/AGENTS.md"
  [ -L "$TARGET/CLAUDE.md" ] || fail "expected CLAUDE.md to be a symlink"
  # Relative, not absolute: an absolute link breaks the moment the repo is cloned anywhere
  # else, and this pair is committed.
  [ "$(readlink "$TARGET/CLAUDE.md")" = "AGENTS.md" ] \
    || fail "expected CLAUDE.md -> AGENTS.md, got $(readlink "$TARGET/CLAUDE.md")"
  assert_contains "Answer these, then delete the questions" "$TARGET/CLAUDE.md"
}

# The point of the link is one text, so the test that matters is reading the same bytes
# through both names after installing for both hosts into one project.
test_host_both_hosts_leave_one_agent_file() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/AGENTS.md"
  [ -L "$TARGET/CLAUDE.md" ] || fail "expected CLAUDE.md to be a symlink after the second host"
  printf 'EDITED BY THE PROJECT\n' >> "$TARGET/AGENTS.md"
  assert_contains "EDITED BY THE PROJECT" "$TARGET/CLAUDE.md"
}

# A project that already answered the questions must not have its link reported as new work
# on every run, and must not have the file rewritten under it.
test_host_claude_reinstall_keeps_the_pair() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  printf 'ANSWERED BY THE PROJECT\n' >> "$TARGET/AGENTS.md"
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_contains "ANSWERED BY THE PROJECT" "$TARGET/AGENTS.md"
  assert_out "AGENTS.md (already exists, skipped)"
  assert_out "CLAUDE.md (already exists, skipped)"
  [ -L "$TARGET/CLAUDE.md" ] || fail "expected CLAUDE.md to stay a symlink"
}

# A project that has AGENTS.md from a Cursor install and adds Claude Code later gets the
# link without the file being touched.
test_host_claude_links_beside_an_existing_agents_md() {
  printf 'ANSWERED ALREADY\n' > "$TARGET/AGENTS.md"
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_contains "ANSWERED ALREADY" "$TARGET/AGENTS.md"
  assert_contains "ANSWERED ALREADY" "$TARGET/CLAUDE.md"
  [ -L "$TARGET/CLAUDE.md" ] || fail "expected CLAUDE.md to be a symlink"
}

test_host_cursor_writes_process_rules_under_cursor_rules() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
  assert_contains "alwaysApply: true" "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
  assert_contains "blc-ste-writing" "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
  assert_no_file "$TARGET/.claude/rules/brief-ledger-chronicle.md"
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
  assert_file "$TARGET/docs/blc/briefs/README.md"
  assert_file "$TARGET/docs/blc/briefs/_drafts/README.md"
  assert_file "$TARGET/docs/blc/install-log/install-log.md"
  assert_dir  "$TARGET/docs/blc/chronicles"
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
}

test_host_claude_writes_process_rules_under_claude_rules() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/.claude/rules/brief-ledger-chronicle.md"
  assert_contains "blc-ste-writing" "$TARGET/.claude/rules/brief-ledger-chronicle.md"
  assert_not_contains "alwaysApply:" "$TARGET/.claude/rules/brief-ledger-chronicle.md"
  assert_no_file "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
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
  assert_matches "^name: blc-review-pr" "$TARGET/.claude/commands/blc-review-pr.md"
  rm -rf "$TARGET"; mkdir -p "$TARGET"
  run_install y --host cursor --target "$TARGET"
  assert_matches "^name: blc-review-pr" "$TARGET/.cursor/skills/blc-review-pr/SKILL.md"
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
  assert_contains "**Host:** cursor" "$TARGET/docs/blc/install-log/install-log.md"
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
