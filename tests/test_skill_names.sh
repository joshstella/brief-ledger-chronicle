# The skill namespace — every skill this toolkit ships is `blc-<name>`.
#
# A skill name is not scoped to the repository that installed it: the host merges
# every skill it can see into one flat list. #0010 prefixed all nine so the toolkit
# owns its own names, and so that typing `/blc-` completes into the whole workflow.
#
# These tests exist because the rename was a one-time migration the brief chose not
# to build a mechanism for. Nothing stops a later contributor adding `deploy/` beside
# `blc-chronicle/`, and nothing would notice — the installer places whatever it finds.
# The repository sweeps below are the mechanism.
#
# The record is deliberately exempt. Briefs and ledgers back to #0001 name the old
# skills; they are the hypothesis as entered and are never rewritten, so every sweep
# here excludes `docs/briefs/` and the superseded Contract.
#
# This file is exempt too, and for a duller reason: it is the only place outside the
# record that has to write the old names down, because it is what searches for them.

# The nine, and the six of them that Claude Code takes as slash-commands.
BLC_PROCESS="blc-commit-push-pr blc-create-brief blc-init-briefs blc-next-brief-phase blc-review-pr blc-start-brief"
BLC_UTILITY="blc-chronicle blc-installer-builder blc-ste-writing"

# The names as they were before #0010. Matched with a negative lookbehind so
# `blc-start-brief` does not count as an occurrence of `start-brief`.
BLC_OLD_NAMES="commit-push-pr|create-brief|init-briefs|next-brief-phase|review-pr|start-brief|ste-writing|installer-builder"

# ── The source tree ──────────────────────────────────────────────────────────

test_skill_names_every_shipped_skill_is_prefixed() {
  local d name
  for d in "$REPO_ROOT"/skills/*/; do
    name="${d%/}"; name="${name##*/}"
    case "$name" in
      blc-*) ;;
      *) fail "skill directory is not prefixed: skills/$name" ;;
    esac
  done
}

# The host reads `name:` from the frontmatter, not the directory. A rename that moved
# the folder and left the field behind would install a skill under its old name while
# the tree looked correct.
test_skill_names_frontmatter_matches_the_directory() {
  local d name declared
  for d in "$REPO_ROOT"/skills/*/; do
    name="${d%/}"; name="${name##*/}"
    declared="$(sed -n 's/^name: *//p' "$d/SKILL.md" | head -1)"
    [ "$declared" = "$name" ] \
      || fail "skills/$name declares name: ${declared:-<none>}"
  done
}

test_skill_names_to_do_is_gone_from_the_source_tree() {
  assert_no_dir "$REPO_ROOT/skills/to-do"
}

# ── The repository sweeps ────────────────────────────────────────────────────

# The guard that outlives this brief. Every fix in phase `a` happened because someone
# noticed; this fails the suite if an unprefixed name comes back.
test_skill_names_no_unprefixed_name_survives_outside_the_record() {
  local hits
  hits="$(cd "$REPO_ROOT" && grep -rnP "(?<!blc-)\b($BLC_OLD_NAMES)\b" \
    --exclude-dir=.git --exclude-dir=briefs --exclude-dir=chronicles . 2>/dev/null \
    | grep -v '^\./docs/contracts/v1\.md:' \
    | grep -v '^\./tests/test_skill_names\.sh:' || true)"
  [ -z "$hits" ] || fail "unprefixed skill name outside the record: ${hits%%$'\n'*}"
}

test_skill_names_to_do_is_gone_outside_the_record() {
  local hits
  hits="$(cd "$REPO_ROOT" && grep -rn 'to-do' \
    --exclude-dir=.git --exclude-dir=briefs --exclude-dir=chronicles . 2>/dev/null \
    | grep -v '^\./tests/test_skill_names\.sh:' || true)"
  [ -z "$hits" ] || fail "to-do still named outside the record: ${hits%%$'\n'*}"
}

# The record keeps its own vocabulary. If this ever passes, someone has rewritten
# history that #0010 promised to leave alone.
test_skill_names_the_record_still_says_the_old_names() {
  grep -rq 'start-brief' "$REPO_ROOT/docs/briefs" \
    || fail "expected the brief record to still name start-brief"
}

# ── What actually lands in a project ─────────────────────────────────────────

test_skill_names_a_cursor_install_places_only_prefixed_skills() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  local d name
  for d in "$TARGET"/.cursor/skills/*/; do
    name="${d%/}"; name="${name##*/}"
    case "$name" in
      blc-*) ;;
      *) fail "cursor install placed an unprefixed skill: $name" ;;
    esac
  done
}

test_skill_names_a_claude_install_places_only_prefixed_skills_and_commands() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  local d f name
  for d in "$TARGET"/.claude/skills/*/; do
    name="${d%/}"; name="${name##*/}"
    case "$name" in
      blc-*) ;;
      *) fail "claude install placed an unprefixed skill: $name" ;;
    esac
  done
  for f in "$TARGET"/.claude/commands/*.md; do
    name="${f##*/}"
    case "$name" in
      blc-*) ;;
      *) fail "claude install placed an unprefixed command: $name" ;;
    esac
  done
}

# Both hosts ship the same six process skills; only the destination differs. A rename
# that updated one host's list and not the other would leave the sets disagreeing.
test_skill_names_both_hosts_agree_on_the_six() {
  local s
  run_install y --host claude --target "$TARGET"
  assert_status 0
  for s in $BLC_PROCESS; do
    assert_file "$TARGET/.claude/commands/$s.md"
  done

  teardown; setup
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  for s in $BLC_PROCESS; do
    assert_file "$TARGET/.cursor/skills/$s/SKILL.md"
  done
}

test_skill_names_no_install_places_to_do() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_no_dir  "$TARGET/.claude/skills/to-do"
  assert_no_file "$TARGET/.claude/commands/to-do.md"
}

# ── The toolkit's own checkout ───────────────────────────────────────────────
#
# install.sh refuses to install into this repository — "the source of the process,
# not a target for it" — and Cursor only loads skills from .cursor/skills/. The two
# together meant the repo that defines this workflow could not invoke it: every
# blc- command had to be run by hand here while every installed project got them.
#
# A symlink resolves it without weakening the guard. It has to stay a symlink: a
# copy would be a second set of skill files to keep in sync, which is the drift this
# whole toolkit argues against.

test_skill_names_cursor_can_see_the_skills_in_this_repo() {
  [ -L "$REPO_ROOT/.cursor/skills" ] \
    || fail ".cursor/skills is not a symlink — Cursor cannot load this repo's own skills"
  [ -f "$REPO_ROOT/.cursor/skills/blc-orient/SKILL.md" ] \
    || fail ".cursor/skills does not resolve to the skills tree"
}

# Committed as a symlink (git mode 120000), so a clone gets one entry rather than a
# duplicate copy of every skill.
test_skill_names_the_cursor_link_is_committed_as_a_link() {
  local mode
  mode="$(cd "$REPO_ROOT" && git ls-files -s .cursor/skills | awk '{print $1}')"
  [ "$mode" = "120000" ] \
    || fail "expected .cursor/skills committed as a symlink (120000), got ${mode:-untracked}"
}
