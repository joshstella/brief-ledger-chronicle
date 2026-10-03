# The toolkit's own checkout runs its own skills, on both hosts (#0019).
#
# install.sh refuses to install into this repository, because the source is not a target.
# The source still has to run its own process. It does that with committed links, never an
# install: a link is not a copy, so nothing drifts, and an edit is live in the next session.
#
# The set of links is not listed here. It is read from `install.sh --print-ownership`, the
# same map every install obeys, so "this repository gets what a target gets" is checked
# against what a target actually gets. A hand-kept roster is how `tests/test_skill_names.sh`
# came to name three of five utility skills.
#
# Only the skill and command rows are compared. The other rows a host prints are not
# self-hosting's to copy, or not yet:
#   - `.claude/settings.local.json` is per user, and global ignores exclude it.
#   - `CLAUDE.md` / `AGENTS.md` are project-owned. #0019 phase `e` decides what this
#     repository's say.
#   - the process rules file is #0019 phase `b`.

SELF_HOST_HOSTS="claude cursor"

# Prints `source<TAB>destination` for each skill and command row an install for host $1
# would place.
self_host_rows() {
  run_install y --print-ownership --host "$1"
  awk -F'\t' '$1 == "toolkit" && $4 ~ /^\.(claude|cursor)\/(skills|commands)\// { print $3 "\t" $4 }' "$OUT"
}

# Compared by destination, not by shape. Cursor reaches each skill through one directory
# link, `.cursor/skills`, and Claude Code through one link per skill, because it splits
# skills from commands. `-ef` follows both to the same inode, so either shape passes.
test_self_host_every_row_a_target_gets_resolves_here() {
  local host src dst rows checked=0
  for host in $SELF_HOST_HOSTS; do
    rows="$(self_host_rows "$host")"
    [ -n "$rows" ] || { fail "--print-ownership --host $host printed no skill rows"; continue; }
    while IFS=$'\t' read -r src dst; do
      checked=$((checked + 1))
      if [ ! -e "$REPO_ROOT/$dst" ]; then
        fail "$host: a target gets $dst and this repository does not"
      elif [ ! "$REPO_ROOT/$dst" -ef "$REPO_ROOT/$src" ]; then
        fail "$host: $dst does not resolve to $src"
      fi
    done <<< "$rows"
  done
  [ "$checked" -gt 0 ] || fail "compared no rows"
}

# The other direction. A link left behind by a rename still resolves to something, so the
# check above passes, and the host loads a skill no target has.
test_self_host_no_link_a_target_does_not_get() {
  local host rows p rel
  for host in $SELF_HOST_HOSTS; do
    rows="$(self_host_rows "$host" | cut -f2)"
    for p in "$REPO_ROOT/.$host/skills/"* "$REPO_ROOT/.$host/commands/"*; do
      [ -e "$p" ] || [ -L "$p" ] || continue
      rel="${p#"$REPO_ROOT/"}"
      printf '%s\n' "$rows" | grep -qxF "$rel" \
        || fail "$host: $rel is here and no target gets it"
    done
  done
}

# An absolute link resolves on the machine that made it and nowhere else.
test_self_host_links_are_relative() {
  local p target
  for p in "$REPO_ROOT/.cursor/skills" "$REPO_ROOT/.claude/skills/"* "$REPO_ROOT/.claude/commands/"*; do
    [ -L "$p" ] || continue
    target="$(readlink "$p")"
    case "$target" in
      /*) fail "${p#"$REPO_ROOT/"} is an absolute link: $target" ;;
    esac
  done
}

# The index is what a clone gets. A link that was copied as a file before staging is a
# second set of skill files, which is the drift self-hosting exists to prevent.
test_self_host_claude_links_are_committed_as_links() {
  git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { skip "not a git checkout"; return; }
  local mode _sha _stage path count=0
  while read -r mode _sha _stage path; do
    count=$((count + 1))
    [ "$mode" = "120000" ] || fail "$path is in the index as $mode, not as a link (120000)"
  done < <(git -C "$REPO_ROOT" ls-files -s .claude/skills .claude/commands)
  [ "$count" -gt 0 ] || fail "no .claude/skills or .claude/commands entries are in the index"
}
