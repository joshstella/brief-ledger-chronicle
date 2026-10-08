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
# here excludes the numbered brief folders, the drafts, and the superseded Contract.
#
# The exemption is by *file*, not by directory, and that distinction was bought the
# hard way. The first version excluded `docs/blc/briefs/` wholesale, which also excluded
# `docs/blc/briefs/README.md` and `docs/blc/briefs/_drafts/README.md` — two files that are not
# record at all. They ship to every install target and tell agents which commands to
# run, and they sat naming `/create-brief` for two briefs after that skill was renamed.
# A directory is not a category.
#
# This file is exempt too, and for a duller reason: it is the only place outside the
# record that has to write the old names down, because it is what searches for them.

# The ones Claude Code takes as slash-commands, and a sample of the ones it does not.
BLC_PROCESS="blc-close-brief blc-commit-push-pr blc-create-brief blc-create-draft blc-init-briefs blc-next-brief-phase blc-review-pr blc-start-brief"
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
    --exclude-dir=.git --exclude-dir=chronicles . 2>/dev/null \
    | grep -v '^\./docs/blc/contracts/v1\.md:' \
    | grep -v '^\./tests/test_skill_names\.sh:' \
    | grep -vE '^\./docs/blc/briefs/[0-9]{4}-' \
    | grep -vP '^\./docs/blc/briefs/_drafts/(?!README)' || true)"
  [ -z "$hits" ] || fail "unprefixed skill name outside the record: ${hits%%$'\n'*}"
}

test_skill_names_to_do_is_gone_outside_the_record() {
  local hits
  hits="$(cd "$REPO_ROOT" && grep -rn 'to-do' \
    --exclude-dir=.git --exclude-dir=chronicles . 2>/dev/null \
    | grep -v '^\./tests/test_skill_names\.sh:' \
    | grep -vE '^\./docs/blc/briefs/[0-9]{4}-' \
    | grep -vP '^\./docs/blc/briefs/_drafts/(?!README)' || true)"
  [ -z "$hits" ] || fail "to-do still named outside the record: ${hits%%$'\n'*}"
}

# The record keeps its own vocabulary. If this ever passes, someone has rewritten
# history that #0010 promised to leave alone.
test_skill_names_the_record_still_says_the_old_names() {
  grep -rq 'start-brief' "$REPO_ROOT/docs/blc/briefs" \
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

# Both hosts ship the same process skills; only the destination differs. A rename
# that updated one host's list and not the other would leave the sets disagreeing.
test_skill_names_both_hosts_agree_on_the_process_skills() {
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

# This repository links its own skills twice, and the two links are not interchangeable.
# A process skill is a slash-command, so it belongs under `.claude/commands/<name>.md`;
# everything else is a skill directory under `.claude/skills/<name>`. Which of the two a
# skill gets is the whole observable difference the process list makes here.
#
# #0032 added a skill to the process list and linked it the other way, and the suite was
# silent: every test above reads what the *installer* places into a target, and nothing
# read this checkout's own links. The toolkit could ship a correct install while being
# unable to invoke the command itself.
test_skill_names_this_repo_links_its_process_skills_as_commands() {
  local s mode
  for s in $BLC_PROCESS; do
    mode="$(cd "$REPO_ROOT" && git ls-files -s ".claude/commands/$s.md" | awk '{print $1}')"
    [ "$mode" = "120000" ] \
      || fail ".claude/commands/$s.md is ${mode:-not tracked}, expected a committed symlink (120000)"
    # The other half, or a skill could sit in both trees and look installed twice.
    [ ! -e "$REPO_ROOT/.claude/skills/$s" ] \
      || fail ".claude/skills/$s exists, but $s is a process skill and belongs in commands/"
  done
  return 0
}

# The two READMEs under docs/blc/briefs/ are documentation, not record, and they install
# into every target as the instructions an agent follows. They named `/create-brief`
# for two briefs after that skill was renamed, because the sweep excluded their whole
# directory. This asserts the distinction the exemption now makes.
test_skill_names_the_shipped_briefs_docs_are_swept() {
  local f
  for f in docs/blc/briefs/README.md docs/blc/briefs/_drafts/README.md; do
    if grep -qP "(?<!blc-)\b(create-brief|start-brief|init-briefs|next-brief-phase|review-pr)\b" "$REPO_ROOT/$f"; then
      fail "$f names a skill that no longer exists"
    fi
  done
  return 0
}

# What a target actually receives. Upstream being correct is not the same as the
# installed copy being correct.
test_skill_names_a_target_gets_instructions_that_name_real_skills() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  local f
  for f in docs/blc/briefs/README.md docs/blc/briefs/_drafts/README.md; do
    if grep -qP "(?<!blc-)\b(create-brief|start-brief|init-briefs)\b" "$TARGET/$f"; then
      fail "installed $f tells an agent to run a command that does not exist"
    fi
  done
  return 0
}

# ── Agent identity in shipped prose (#0026) ──────────────────────────────────
#
# `skills/`, `templates/` and `personal/` ship to both hosts unchanged — the installer substitutes nothing
# into them. So a string naming one agent is wrong on the other host, every time, and nothing
# noticed for as long as the author used the host it named.
#
# The match is a trailer with an address, not the words themselves. Prose that explains the
# rule has to be able to write `Co-authored-by: Cursor` without tripping the test that enforces
# it; a trailer with no address credits nobody and is not the defect.
test_skill_names_shipped_prose_names_no_agent_identity() {
  local hit
  hit="$(cd "$REPO_ROOT" && grep -rniE 'co-authored-by:[^<]*<[^>]+@' skills/ templates/ personal/ || true)"
  [ -z "$hit" ] || fail "shipped prose carries an agent trailer, which is wrong on every host but one: $hit"
}

# The same sweep by address, in case a trailer is ever written in another shape.
test_skill_names_shipped_prose_carries_no_agent_address() {
  local hit
  hit="$(cd "$REPO_ROOT" && grep -rniE '(noreply@anthropic\.com|cursoragent@cursor\.com)' skills/ templates/ personal/ || true)"
  [ -z "$hit" ] || fail "shipped prose names an agent address: $hit"
}

# The deletion has to carry its reason, or the line comes back the next time somebody thinks
# a commit should say who made it.
test_skill_names_commit_skill_defers_attribution_to_the_running_agent() {
  assert_contains "Attribute yourself, and only if your host has not already done it" \
    "$REPO_ROOT/skills/blc-commit-push-pr/SKILL.md"
}

# ── The merge method a shipped skill must not pick (#0030 b) ─────────────────

# A merge flag written here ships to every repository unchanged. Where a forge disallows the
# method the command fails and somebody finds it; where the forge merely unticks it — GitLab's
# `squash_option: default_off` — the flag is accepted, the merge request is squashed, and a
# trunk of merge commits quietly gains one that is not. That is the defect #0030 was filed for.
#
# The match is the merge invocation, not the words. The skill has to be able to write a mapping
# table naming `--squash` as the output of reading a repository's own setting, which is the
# opposite of hardcoding it. `--merge-request` and `--auto-merge` are ordinary flags on the same
# rows and must not trip this; the pattern stops a merge-method flag at its own word boundary.
test_skill_names_no_skill_hardcodes_a_merge_method() {
  local hit
  hit="$(cd "$REPO_ROOT" \
    && grep -rn -- 'gh pr merge\|glab mr merge' skills/ \
    | grep -E -- '--(squash|rebase|merge)([^a-z-]|$)' || true)"
  [ -z "$hit" ] || fail "a shipped merge command names a merge method: $hit"
}

# The guard above is worth nothing if the skill stops reading the repository's answer. The
# assertion is on the command that asks, not on the word appearing somewhere in the file: the
# mapping table names the field too, so a file-wide match stays green while the command that
# has to fetch it no longer does.
test_skill_names_commit_skill_reads_the_merge_method_it_uses() {
  local asks
  asks="$(grep -n -- 'gh repo view --json' "$REPO_ROOT/skills/blc-commit-push-pr/SKILL.md" || true)"
  [ -n "$asks" ] || fail "the commit skill has no command that asks the forge its merge methods"
  printf '%s' "$asks" | grep -q 'viewerDefaultMergeMethod' \
    || fail "the merge-methods command does not ask for the field it picks from: $asks"
  assert_contains "Never write a merge method into this file" \
    "$REPO_ROOT/skills/blc-commit-push-pr/SKILL.md"
}

# ── The mentions that remain, pinned (#0030 c) ───────────────────────────────

# Guard 1 catches the flag. It cannot catch a sentence, and a sentence is what started this:
# "Because main is squash-merged" was prose, not a command. Sweeping for the word instead would
# forbid the fix, because six of these mentions are correct — the mapping table that reads the
# method, and the comments describing how git detects a rename across a squash.
#
# So the count per file is pinned. Adding a mention means editing a number here, and that edit
# is what a reviewer sees. It is a report, not a decision: it cannot tell whether the new
# sentence is true, and a person who raises the number without reading the sentence defeats it
# completely. That limit was named when the guard was proposed and is accepted (#0030).
#
# Counts are lines containing the word, case-insensitive, so `SQUASH` in the mapping table
# counts with the rest.
test_skill_names_the_squash_mentions_are_the_pinned_ones() {
  local expected actual
  expected="$(printf '%s\n' \
    'skills/blc-chronicle/SKILL.md 1' \
    'skills/blc-chronicle/scripts/gather.sh 1' \
    'skills/blc-commit-push-pr/SKILL.md 5' \
    'skills/blc-prune-stale-branches/SKILL.md 1' \
    'tools/lib/touch-log.sh 3' \
    'tools/stale-branches.sh 2')"
  actual="$(cd "$REPO_ROOT" \
    && LC_ALL=C grep -rci -- squash skills/ tools/ 2>/dev/null \
    | grep -v ':0$' | tr ':' ' ' | LC_ALL=C sort)"
  [ "$actual" = "$expected" ] || fail "the squash mentions moved — read the lines, then pin the new counts.
pinned:
$expected
found:
$actual"
}
