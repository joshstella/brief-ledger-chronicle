# Project mode: what a --target install creates, what it refuses to touch, and the
# duplicate-serial regression that this suite exists for.

test_project_creates_the_expected_tree() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_dir  "$TARGET/.claude/skills"
  assert_dir  "$TARGET/.claude/commands"
  assert_dir  "$TARGET/docs/briefs/_drafts"
  assert_dir  "$TARGET/docs/chronicles"
  assert_dir  "$TARGET/docs/install-log"
  assert_file "$TARGET/CLAUDE.md"
  assert_file "$TARGET/.claude/settings.local.json"
  assert_file "$TARGET/docs/briefs/README.md"
  assert_file "$TARGET/docs/briefs/_drafts/README.md"
}

# Every skill in the source must land somewhere. On Claude Code the six process skills
# become commands and the rest stay skills, so the two destinations together must account
# for the whole source tree — a skill silently dropped by the host split would otherwise
# go unnoticed.
test_project_places_every_source_skill_somewhere() {
  run_install y --target "$TARGET"
  local src cmds skills total
  src=$(ls -d "$REPO_ROOT/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
  cmds=$(ls "$TARGET/.claude/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
  skills=$(ls -d "$TARGET/.claude/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
  total=$((cmds + skills))
  assert_count "$src" "$total" "skills placed (commands + skills)"
  assert_count 6 "$cmds" "process skills installed as commands"
}

# The installer's whole posture is that it never overwrites. #0001 settles that
# per-project copies exist so a project can tune them; clobbering a tune would make
# that promise false.
test_project_never_overwrites_an_existing_claude_md() {
  echo "PROJECT-OWNED CONTENT" > "$TARGET/CLAUDE.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_contains "PROJECT-OWNED CONTENT" "$TARGET/CLAUDE.md"
  assert_out "CLAUDE.md (already exists, skipped)"
}

test_project_never_overwrites_a_tuned_command() {
  mkdir -p "$TARGET/.claude/commands"
  echo "LOCALLY TUNED" > "$TARGET/.claude/commands/review-pr.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_contains "LOCALLY TUNED" "$TARGET/.claude/commands/review-pr.md"
}

test_project_never_overwrites_an_existing_briefs_readme() {
  mkdir -p "$TARGET/docs/briefs"
  echo "EXISTING REGISTRY DOCS" > "$TARGET/docs/briefs/README.md"
  run_install y --target "$TARGET"
  assert_contains "EXISTING REGISTRY DOCS" "$TARGET/docs/briefs/README.md"
}

test_project_second_run_creates_nothing() {
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  assert_status 0
  assert_out "Created (0):"
}

# The installer must not file briefs at all. /create-brief is the single point of
# serial assignment; a writer outside that pipeline gets neither its max+1
# allocation nor its collision guard.
test_project_writes_no_numbered_brief() {
  run_install y --target "$TARGET"
  assert_count 0 "$(count_numbered_briefs "$TARGET")" "numbered brief folders created"
  assert_no_dir "$TARGET/docs/briefs/0001-bootstrap"
}

# Regression: install.sh once hardcoded docs/briefs/0001-bootstrap/ and guarded on
# whether that folder existed rather than whether serial 0001 was free. Installing
# into a repo that already held briefs wrote a second #0001 every time.
test_project_install_over_existing_0001_creates_no_duplicate_serial() {
  mkdir -p "$TARGET/docs/briefs/0001-resonance"
  printf '# Resonance\n\n**Serial:** #0001\n' > "$TARGET/docs/briefs/0001-resonance/brief.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_count 0 "$(count_duplicate_serials "$TARGET")" "duplicate serial prefixes"
  assert_count 1 "$(count_numbered_briefs "$TARGET")" "numbered brief folders"
  assert_dir    "$TARGET/docs/briefs/0001-resonance"
  assert_no_dir "$TARGET/docs/briefs/0001-bootstrap"
}

test_project_leaves_an_existing_brief_untouched() {
  mkdir -p "$TARGET/docs/briefs/0007-something"
  echo "ORIGINAL BRIEF" > "$TARGET/docs/briefs/0007-something/brief.md"
  run_install y --target "$TARGET"
  assert_contains "ORIGINAL BRIEF" "$TARGET/docs/briefs/0007-something/brief.md"
}

# The dependency check exists so a half-configured machine fails loudly. It must
# abort before writing anything.
test_project_missing_dependency_aborts_before_writing() {
  if PATH="/usr/bin:/bin" command -v claude >/dev/null 2>&1; then
    skip "claude resolves from /usr/bin:/bin here, cannot simulate absence"
    return
  fi
  local partial="$TMP/partial-bin"
  mkdir -p "$partial"
  local tool
  for tool in gh node npm; do
    printf '#!/bin/sh\nexit 0\n' > "$partial/$tool"
    chmod +x "$partial/$tool"
  done
  run_install_with_path "$partial:/usr/bin:/bin" y --target "$TARGET"
  assert_status 1
  assert_out "claude — not found"
  assert_no_dir "$TARGET/.claude"
  assert_no_dir "$TARGET/docs"
}
