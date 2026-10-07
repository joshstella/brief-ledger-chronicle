# Project mode: what a --target install creates, what it refuses to touch, and the
# duplicate-serial regression that this suite exists for.

test_project_creates_the_expected_tree() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_dir  "$TARGET/.claude/skills"
  assert_dir  "$TARGET/.claude/commands"
  assert_dir  "$TARGET/docs/blc/briefs/_drafts"
  assert_dir  "$TARGET/docs/blc/chronicles"
  assert_dir  "$TARGET/docs/blc/install-log"
  assert_file "$TARGET/CLAUDE.md"
  assert_file "$TARGET/.claude/rules/brief-ledger-chronicle.md"
  assert_file "$TARGET/.claude/settings.local.json"
  assert_contains "Answer these, then delete the questions" "$TARGET/CLAUDE.md"
  assert_not_contains "## Writing" "$TARGET/CLAUDE.md"
  assert_file "$TARGET/docs/blc/briefs/README.md"
  assert_file "$TARGET/docs/blc/briefs/_drafts/README.md"
}

# The installer scaffolds docs/blc/chronicles/. chronicle.md is the one committed file.
# Other files in that folder stay ignored so a later archive feature has a place.
# A parent-directory rule would hide the exception, so the written pair is the
# contents glob plus the one negation.
test_project_ignores_other_chronicles_but_not_chronicle_md() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/.gitignore"
  grep -qxF 'docs/blc/chronicles/*' "$TARGET/.gitignore" \
    || fail "expected docs/blc/chronicles/* in .gitignore"
  grep -qxF '!docs/blc/chronicles/chronicle.md' "$TARGET/.gitignore" \
    || fail "expected !docs/blc/chronicles/chronicle.md in .gitignore"
  grep -qxF 'docs/blc/chronicles/' "$TARGET/.gitignore" \
    && fail "did not expect a parent-directory docs/blc/chronicles/ rule"
}

# This is the only file the installer writes that it does not own, so append-never-rewrite
# is the whole contract. A project's existing rules must survive untouched.
test_project_appends_to_an_existing_gitignore() {
  printf 'node_modules/\n*.log\n' > "$TARGET/.gitignore"
  run_install y --target "$TARGET"
  assert_status 0
  assert_contains "node_modules/" "$TARGET/.gitignore"
  assert_contains "*.log" "$TARGET/.gitignore"
  grep -qxF 'docs/blc/chronicles/*' "$TARGET/.gitignore" \
    || fail "expected docs/blc/chronicles/* appended to existing .gitignore"
  grep -qxF '!docs/blc/chronicles/chronicle.md' "$TARGET/.gitignore" \
    || fail "expected !docs/blc/chronicles/chronicle.md appended to existing .gitignore"
}

# Appending on every run would grow the file without bound. The guard is a match on the
# exact rule, so a second install must add nothing.
test_project_gitignore_rule_is_not_duplicated() {
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  assert_status 0
  local n
  n=$(grep -cxF 'docs/blc/chronicles/*' "$TARGET/.gitignore")
  assert_count 1 "$n" "docs/blc/chronicles/* rules in .gitignore after two installs"
  n=$(grep -cxF '!docs/blc/chronicles/chronicle.md' "$TARGET/.gitignore")
  assert_count 1 "$n" "chronicle.md exceptions in .gitignore after two installs"
  assert_out "chronicles ignore rule already present"
}

# A project that already ignores the directory its own way is left completely alone —
# no trailing newline, no comment, no reformatting of a file the installer does not own.
test_project_leaves_a_gitignore_that_already_ignores_chronicles() {
  printf 'docs/blc/chronicles/\n' > "$TARGET/.gitignore"
  local before
  before=$(cat "$TARGET/.gitignore")
  run_install y --target "$TARGET"
  assert_status 0
  assert_count "$before" "$(cat "$TARGET/.gitignore")" ".gitignore contents unchanged"
}

# docs/architecture/ is project-owned: the agent writes it and no install may rewrite it
# (#0029). The hazard is specific — it sits under docs/, beside docs/blc/, which every
# install replaces wholesale. A rule that stopped at the docs/ boundary would take it.
test_project_reinstall_does_not_touch_the_architecture_document() {
  mkdir -p "$TARGET/docs/architecture"
  printf '# Architecture\n\nThe router dispatches. <!-- cite: src/router.ts :: Router -->\n' \
    > "$TARGET/docs/architecture/README.md"
  local before
  before=$(cat "$TARGET/docs/architecture/README.md")
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  assert_status 0
  assert_count "$before" "$(cat "$TARGET/docs/architecture/README.md")" \
    "docs/architecture/README.md unchanged after two installs"
}

# The installer must not create the document either. An empty or scaffolded architecture
# document is a claim about the project that nobody made, and the skill rewrites rather
# than appends, so a placeholder would only ever be noise.
test_project_install_does_not_create_an_architecture_document() {
  run_install y --target "$TARGET"
  assert_status 0
  [ ! -e "$TARGET/docs/architecture" ] \
    || fail "the installer created docs/architecture/, which the project owns"
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

# Project-owned stubs survive every run. Toolkit-owned paths are replaced (#0012b).
test_project_never_overwrites_an_existing_claude_md() {
  echo "PROJECT-OWNED CONTENT" > "$TARGET/CLAUDE.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_contains "PROJECT-OWNED CONTENT" "$TARGET/CLAUDE.md"
  assert_out "CLAUDE.md (the project's agent file, kept in place of AGENTS.md)"
  assert_no_file "$TARGET/AGENTS.md"
}

# ── The stub asks, it does not answer (#0022 a) ──────────────────────────────
#
# Three files share this job and only one of them is the project's. The stub used to
# restate the process rules, so a new target's agent file said nothing the install had
# not already written next to it. These two tests pin the half that is mechanical:
# that the stub states no process rule, and that it points at the file it is not.

# A line-by-line comparison against the rules file was tried first and passed against the
# old stub, because the duplication was never line-identical: the stub wrote "The installed
# skills are the gates" where the rules write "Installed skills are the gates". No textual
# diff catches a restatement. Named phrases do, and the second loop is what keeps them
# honest — a phrase the rules file stops using is a phrase this test can no longer police.
test_project_stub_states_no_process_rule() {
  run_install y --target "$TARGET"
  assert_status 0
  local rules="$TARGET/.claude/rules/brief-ledger-chronicle.md" phrase
  for phrase in "skills are the gates" "bypassing them is the defect"; do
    assert_not_contains "$phrase" "$TARGET/CLAUDE.md"
    assert_contains     "$phrase" "$rules"
  done
}

# orientation.md is the file an install must never write, and nothing else tells a
# project it exists. If the stub stops naming it, the absence message in orient is the
# only hint left, and that only appears once somebody runs orient.
test_project_stub_points_at_the_file_the_project_authors() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_contains "docs/blc/orientation.md" "$TARGET/CLAUDE.md"
  assert_no_file  "$TARGET/docs/blc/orientation.md"
}

# ── The gates say they are gates, and they are not (#0022 b) ─────────────────
#
# "A skill guard is not a check" is in this repository's docs/blc/orientation.md, which a
# target authors for itself and an install never writes. So nothing a target received said
# the gates it was reading about are unenforced, and an agent that believes blc-review-pr
# blocks mechanically reasons from a false premise. One sentence, in the one file an
# install owns and rewrites, so an upgrade can still correct it.
#
# Both hosts, because the Cursor copy is generated through print_process_rules with
# frontmatter prepended and the Claude Code copy is the template itself. A sentence added
# to the template reaches one of those paths without proving it reaches the other.

test_project_claude_rules_say_the_skills_are_unenforced() {
  run_install y --target "$TARGET"
  assert_status 0
  assert_contains "Nothing enforces them" "$TARGET/.claude/rules/brief-ledger-chronicle.md"
}

test_project_cursor_rules_say_the_skills_are_unenforced() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_contains "Nothing enforces them" "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
}

test_project_replaces_a_tuned_command_on_reinstall() {
  mkdir -p "$TARGET/.claude/commands"
  echo "LOCALLY TUNED" > "$TARGET/.claude/commands/blc-review-pr.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_not_contains "LOCALLY TUNED" "$TARGET/.claude/commands/blc-review-pr.md"
}

test_project_replaces_an_existing_briefs_readme() {
  mark_prior_install
  mkdir -p "$TARGET/docs/blc/briefs"
  echo "EXISTING REGISTRY DOCS" > "$TARGET/docs/blc/briefs/README.md"
  run_install y --target "$TARGET"
  assert_not_contains "EXISTING REGISTRY DOCS" "$TARGET/docs/blc/briefs/README.md"
}

test_project_second_run_replaces_toolkit_owned() {
  run_install y --target "$TARGET"
  run_install y --target "$TARGET"
  assert_status 0
  assert_out "Replaced ("
}

# The installer must not file briefs at all. /blc-create-brief is the single point of
# serial assignment; a writer outside that pipeline gets neither its max+1
# allocation nor its collision guard.
test_project_writes_no_numbered_brief() {
  run_install y --target "$TARGET"
  assert_count 0 "$(count_numbered_briefs "$TARGET")" "numbered brief folders created"
  assert_no_dir "$TARGET/docs/blc/briefs/0001-bootstrap"
}

# Regression: install.sh once hardcoded docs/briefs/0001-bootstrap/ and guarded on
# whether that folder existed rather than whether serial 0001 was free. Installing
# into a repo that already held briefs wrote a second #0001 every time.
test_project_install_over_existing_0001_creates_no_duplicate_serial() {
  mark_prior_install
  mkdir -p "$TARGET/docs/blc/briefs/0001-resonance"
  printf '# Resonance\n\n**Serial:** #0001\n' > "$TARGET/docs/blc/briefs/0001-resonance/brief.md"
  run_install y --target "$TARGET"
  assert_status 0
  assert_count 0 "$(count_duplicate_serials "$TARGET")" "duplicate serial prefixes"
  assert_count 1 "$(count_numbered_briefs "$TARGET")" "numbered brief folders"
  assert_dir    "$TARGET/docs/blc/briefs/0001-resonance"
  assert_no_dir "$TARGET/docs/blc/briefs/0001-bootstrap"
}

test_project_leaves_an_existing_brief_untouched() {
  mkdir -p "$TARGET/docs/blc/briefs/0007-something"
  echo "ORIGINAL BRIEF" > "$TARGET/docs/blc/briefs/0007-something/brief.md"
  run_install y --target "$TARGET"
  assert_contains "ORIGINAL BRIEF" "$TARGET/docs/blc/briefs/0007-something/brief.md"
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

# A PATH with every program in /usr/bin and /bin except gh and glab, plus inert node, npm and
# claude, and the forge CLIs named in $@. Prepending cannot hide /usr/bin/gh, which GitHub's
# Ubuntu runners have.
# usage: pm_forge_path [gh] [glab]
pm_forge_path() {
  PM_YARD="$TMP/pm-yard"
  rm -rf "$PM_YARD"
  mkdir -p "$PM_YARD"
  local f name
  for f in /usr/bin/* /bin/*; do
    name="${f##*/}"
    case "$name" in gh|glab) continue ;; esac
    [ -e "$PM_YARD/$name" ] || ln -s "$f" "$PM_YARD/$name"
  done
  for name in node npm claude "$@"; do
    rm -f "$PM_YARD/$name"
    printf '#!/bin/sh\nexit 0\n' > "$PM_YARD/$name"
    chmod +x "$PM_YARD/$name"
  done
}

test_project_glab_alone_satisfies_the_forge_check() {
  pm_forge_path glab
  run_install_with_path "$PM_YARD" y --target "$TARGET"
  assert_status 0
  assert_out "[✓] glab"
  assert_not_contains "[✗]" "$OUT"
}

test_project_no_forge_cli_aborts_before_writing() {
  pm_forge_path
  run_install_with_path "$PM_YARD" y --target "$TARGET"
  assert_status 1
  assert_out "gh or glab — neither found"
  assert_out "brew install gh "
  assert_out "brew install glab "
  assert_no_dir "$TARGET/.claude"
  assert_no_dir "$TARGET/docs"
}
