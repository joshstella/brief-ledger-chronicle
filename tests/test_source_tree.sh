# File modes in this repository's own tree.
#
# install.sh chmods every tool it places, so every assertion of the form "the
# installed tool is executable" passes whatever the source mode is. Five such
# assertions exist. All five stayed green while tools/open-briefs.sh sat at
# 100644 through two merges and their reviews: the suite was watching the copy,
# on the far side of the step that repairs it.
#
# The mode read here is the git index's, not the filesystem's. The index is
# what a fresh clone materializes, and a chmod that was never staged leaves
# every other checkout broken while looking repaired on the one that ran it.

# Sourced by run.sh rather than invoked, so their mode carries no meaning.
# Matched by pattern, not listed, so adding a test file needs no edit here.
source_tree_is_sourced_not_invoked() {
  case "$1" in
    tests/lib.sh|tests/test_*.sh) return 0 ;;
    *) return 1 ;;
  esac
}

test_source_tree_every_invoked_script_is_executable_in_the_index() {
  git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { skip "not a git checkout"; return; }

  # Every field is local: run.sh sources all test files into one shell, so an
  # undeclared loop variable is a global. See "Helper names are shared across
  # every test file" in tests/README.md.
  local mode _sha _stage path checked=0 bad=""
  # `git ls-files -s` emits `<mode> <sha> <stage>\t<path>`. Read rather than a
  # hardcoded roster: a roster needs editing at the moment someone is adding a
  # tool and thinking about something else, which is when this last broke.
  while read -r mode _sha _stage path; do
    source_tree_is_sourced_not_invoked "$path" && continue
    checked=$((checked + 1))
    [ "$mode" = "100755" ] || bad="$bad $path($mode)"
  done < <(git -C "$REPO_ROOT" ls-files -s -- '*.sh')

  # A scan that matches nothing reports success, which is the failure mode this
  # whole file exists to name. Prove the scan looked at something.
  [ "$checked" -gt 0 ] || fail "the scan found no invoked scripts — it is broken, not clean"
  [ -z "$bad" ] || fail "not executable in the git index:$bad"
}
