# The ownership map — #0012a.
#
# The map exists to be the single place that says what the installer owns. These tests
# hold it to that in two directions: that the map is well-formed and host-correct, and
# that the parts of install.sh which used to keep their own copies now agree with it.
#
# The second direction is the one that matters. A map nothing is checked against is the
# sixth copy of the fact, which is the failure #0012 was written about.

# The map, for a host, as raw TSV. Read through the installer rather than reimplemented
# here: a test that rebuilt the list would pass while the installer shipped something
# else, which is precisely the drift being fixed.
print_map() {
  PATH="$STUB_BIN:$PATH" bash "$REPO_ROOT/install.sh" --host "$1" --print-ownership 2>"$ERR"
}

# Same map, on disk, because assert_contains reads a file rather than a string.
map_file() {
  local f="$TMP/map-$1.tsv"
  print_map "$1" > "$f"
  printf '%s' "$f"
}

map_field() { print_map "$1" | awk -F'\t' -v c="$2" '{print $c}'; }

# ── Shape ────────────────────────────────────────────────────────────────────

test_ownership_map_prints_four_tab_separated_fields() {
  local bad
  bad="$(print_map cursor | awk -F'\t' 'NF != 4' | head -1)"
  [ -z "$bad" ] || fail "every row needs 4 tab-separated fields; got: $bad"
}

test_ownership_map_uses_only_the_three_declared_owners() {
  local bad
  bad="$(map_field cursor 1 | sort -u | grep -vE '^(toolkit|project|append)$' || true)"
  [ -z "$bad" ] || fail "unexpected owner(s): $bad"
}

test_ownership_map_uses_only_the_declared_kinds() {
  local bad
  bad="$(map_field cursor 2 | sort -u | grep -vE '^(file|dir|tree)$' || true)"
  [ -z "$bad" ] || fail "unexpected kind(s): $bad"
}

# Project-owned means nothing is shipped. A project row carrying a source would be a
# contradiction the rest of the installer would happily act on.
test_ownership_map_project_rows_ship_nothing() {
  local bad
  bad="$(print_map cursor | awk -F'\t' '$1 != "toolkit" && $3 != "-"' | head -1)"
  [ -z "$bad" ] || fail "non-toolkit row names a source: $bad"
}

test_ownership_map_toolkit_rows_all_ship_something() {
  local bad
  bad="$(print_map cursor | awk -F'\t' '$1 == "toolkit" && $3 == "-"' | head -1)"
  [ -z "$bad" ] || fail "toolkit row ships nothing: $bad"
}

# The preflight reads these paths and aborts on a miss. If the map can name something
# the checkout does not have, every install fails at the preflight instead of here.
test_ownership_map_every_toolkit_source_exists() {
  local missing="" src kind
  while IFS=$'\t' read -r _o kind src _d; do
    [ "$src" = "-" ] && continue
    case "$kind" in
      file) [ -f "$REPO_ROOT/$src" ] || missing="$missing $src" ;;
      dir)  [ -d "$REPO_ROOT/$src" ] || missing="$missing $src" ;;
    esac
  done < <(print_map cursor | awk -F'\t' '$1 == "toolkit"')
  [ -z "$missing" ] || fail "map names sources that do not exist:$missing"
}

test_ownership_map_no_destination_is_claimed_twice() {
  local dupes
  dupes="$(map_field cursor 4 | sort | uniq -d)"
  [ -z "$dupes" ] || fail "two rows claim the same destination: $dupes"
}

# ── The host split ───────────────────────────────────────────────────────────

# The same source becomes a directory on one host and a flat command file on the other.
# This is the reason the map is a function of the host rather than a constant.
test_ownership_map_process_skills_become_commands_on_claude() {
  assert_contains "skills/blc-start-brief/SKILL.md" "$(map_file claude)"
  assert_contains ".claude/commands/blc-start-brief.md" "$(map_file claude)"
}

test_ownership_map_process_skills_stay_directories_on_cursor() {
  assert_contains ".cursor/skills/blc-start-brief" "$(map_file cursor)"
  assert_not_contains "commands/blc-start-brief.md" "$(map_file cursor)"
}

# A utility skill is a directory on both hosts. Without this, a map that turned every
# skill into a command file would still pass the test above.
test_ownership_map_utility_skills_are_directories_on_both_hosts() {
  assert_contains ".claude/skills/blc-chronicle" "$(map_file claude)"
  assert_contains ".cursor/skills/blc-chronicle" "$(map_file cursor)"
}

test_ownership_map_settings_ship_only_to_claude() {
  assert_contains ".claude/settings.local.json" "$(map_file claude)"
  assert_not_contains "settings.local.json" "$(map_file cursor)"
}

test_ownership_map_names_the_hosts_own_rules_file() {
  assert_contains "AGENTS.md" "$(map_file cursor)"
  assert_contains "CLAUDE.md" "$(map_file claude)"
}

# ── Coverage: the map against the source tree ────────────────────────────────

# Every skill in the repo appears exactly once. A skill missing from the map is a skill
# the installer would stop shipping the moment placement reads the map — which it now does.
test_ownership_map_covers_every_skill_in_the_repo() {
  local missing="" name
  for d in "$REPO_ROOT"/skills/*/; do
    name="$(basename "$d")"
    print_map cursor | grep -q "skills/$name" || missing="$missing $name"
  done
  [ -z "$missing" ] || fail "skills absent from the map:$missing"
}

test_ownership_map_lists_each_skill_once_per_host() {
  local dupes
  dupes="$(print_map claude | awk -F'\t' '$3 ~ /^skills\//' \
    | sed -E 's#^[^\t]*\t[^\t]*\tskills/([^/\t]+).*#\1#' | sort | uniq -d)"
  [ -z "$dupes" ] || fail "skill listed twice: $dupes"
}

# ── Coverage: the map against what an install actually does ──────────────────

# The strongest assertion available: install into a real target, then require that every
# toolkit destination the map promised is present. This is what makes the map a
# description of behaviour rather than a document beside it.
test_ownership_map_every_toolkit_destination_lands_in_a_target() {
  run_install "y" --host cursor --target "$TARGET" --yes
  assert_status 0
  local missing="" kind dst
  while IFS=$'\t' read -r _o kind _s dst; do
    case "$kind" in
      file) [ -f "$TARGET/$dst" ] || missing="$missing $dst" ;;
      dir)  [ -d "$TARGET/$dst" ] || missing="$missing $dst" ;;
    esac
  done < <(print_map cursor | awk -F'\t' '$1 == "toolkit"')
  [ -z "$missing" ] || fail "map promised destinations the install did not write:$missing"
}

test_ownership_map_every_toolkit_destination_lands_on_claude_too() {
  run_install "y" --host claude --target "$TARGET" --yes
  assert_status 0
  local missing="" kind dst
  while IFS=$'\t' read -r _o kind _s dst; do
    case "$kind" in
      file) [ -f "$TARGET/$dst" ] || missing="$missing $dst" ;;
      dir)  [ -d "$TARGET/$dst" ] || missing="$missing $dst" ;;
    esac
  done < <(print_map claude | awk -F'\t' '$1 == "toolkit"')
  [ -z "$missing" ] || fail "map promised destinations the install did not write:$missing"
}

# The log's skill list is what phase c will read to decide what is stale. If it stopped
# agreeing with the map, prune would remove the wrong things — so pin it now, while the
# only cost of being wrong is a red test.
test_ownership_map_agrees_with_the_install_logs_skill_list() {
  run_install "y" --host cursor --target "$TARGET" --yes
  assert_status 0
  local missing="" name
  for d in "$REPO_ROOT"/skills/*/; do
    name="$(basename "$d")"
    grep -q -- "- $name" "$TARGET/docs/install-log/install-log.md" \
      || missing="$missing $name"
  done
  [ -z "$missing" ] || fail "install log omits skills the map ships:$missing"
}

# The pre-install summary stays hand-written prose, because a person deciding whether to
# proceed reads it. This is the guard that keeps the prose honest: every path it names
# must be a path the map knows about.
test_ownership_map_backs_every_path_the_summary_promises() {
  run_install "y" --host cursor --target "$TARGET" --yes
  assert_status 0
  local map_text unmatched="" path
  map_text="$(map_file cursor)"
  for path in "docs/briefs/" "docs/contracts/" "docs/state/" "tools/" ".cursor/skills/" "AGENTS.md"; do
    assert_out "$path"
    grep -qF -- "${path%/}" "$map_text" || unmatched="$unmatched $path"
  done
  [ -z "$unmatched" ] || fail "summary names paths the map does not:$unmatched"
}

# ── Project-owned means never written ────────────────────────────────────────

# The map's whole point is that this column is load-bearing. A project-owned file that
# an install rewrites would make the declaration a comment.
test_ownership_map_project_owned_files_survive_a_reinstall() {
  run_install "y" --host cursor --target "$TARGET" --yes
  assert_status 0
  printf 'project architecture notes, authored by hand\n' > "$TARGET/AGENTS.md"
  run_install "y" --host cursor --target "$TARGET" --yes
  assert_status 0
  assert_contains "authored by hand" "$TARGET/AGENTS.md"
}

test_ownership_map_project_owned_trees_survive_a_reinstall() {
  run_install "y" --host cursor --target "$TARGET" --yes
  assert_status 0
  mkdir -p "$TARGET/docs/briefs/0001-a-brief"
  printf '# kept\n' > "$TARGET/docs/briefs/0001-a-brief/brief.md"
  printf '# mine\n' > "$TARGET/docs/state/someone@example.com.md"
  run_install "y" --host cursor --target "$TARGET" --yes
  assert_status 0
  assert_contains "kept" "$TARGET/docs/briefs/0001-a-brief/brief.md"
  assert_contains "mine" "$TARGET/docs/state/someone@example.com.md"
}

# ── The flag itself ──────────────────────────────────────────────────────────

test_ownership_map_printing_writes_nothing_to_a_target() {
  print_map cursor >/dev/null
  [ -z "$(ls -A "$TARGET")" ] || fail "--print-ownership wrote into the target"
}

# Refusing this from the source checkout would make the map unreadable from the one
# directory guaranteed to have it.
test_ownership_map_printing_is_exempt_from_the_self_install_guard() {
  local f="$TMP/self.txt"
  (cd "$REPO_ROOT" && PATH="$STUB_BIN:$PATH" \
    bash "$REPO_ROOT/install.sh" --host cursor --print-ownership) > "$f" 2>&1
  assert_contains "toolkit" "$f"
  assert_not_contains "cannot install into" "$f"
}

test_ownership_map_printing_is_documented_in_help() {
  local f="$TMP/help.txt"
  PATH="$STUB_BIN:$PATH" bash "$REPO_ROOT/install.sh" --help > "$f" 2>&1
  assert_contains "--print-ownership" "$f"
}
