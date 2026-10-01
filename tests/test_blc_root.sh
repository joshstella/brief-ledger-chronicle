# The toolkit's one root — docs/blc/ — from #0017 phase a.
#
# Every tool that reads the record takes it from `docs/blc/briefs` when given no argument,
# and from its positional argument when given one. Both halves are asserted per tool: a tool
# that kept the old default would pass an override test, and a tool that ignored its argument
# would pass a default test.
#
# The default tests also put a tree at the old `docs/briefs` and assert it is not read. #0017
# rejected a fallback to the old layout, so a tool that found it would be a third layout the
# brief does not plan for.
#
# Helper names are prefixed br_ because run.sh sources every test file into one shell.

# usage: br_tree <briefs-dir>
# One brief with everything every reader needs: an identity line with an author, a blc/2
# status line, and a phase table with a label.
br_tree() {
  local dir="$1/0001-thing"
  mkdir -p "$dir" "$1/_drafts"
  echo "# Briefs" > "$1/README.md"
  echo "# Drafts" > "$1/_drafts/README.md"
  printf '# The thing\n\n**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —\n' \
    > "$dir/brief.md"
  printf '%s\n' '# Ledger — The thing' '' \
    '`blc/2 #0001 in-progress a:in-progress(brief/0001-a-first)`' '' \
    '| id | label | status | branch |' '|---|---|---|---|' \
    '| a | the first | in-progress | `brief/0001-a-first` |' > "$dir/ledger.md"
}

# usage: br_repo [old|new|elsewhere]...
# A git repository with a tree at each named place: old is docs/briefs, new is docs/blc/briefs,
# elsewhere is elsewhere/briefs. The tools orient and gather call are installed beside it.
br_repo() {
  local where
  REPO="$TMP/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
  fixture_install_tool "$REPO" list-briefs.sh
  for where in "$@"; do
    case "$where" in
      old) br_tree "$REPO/docs/briefs" ;;
      new) br_tree "$REPO/docs/blc/briefs" ;;
      elsewhere) br_tree "$REPO/elsewhere/briefs" ;;
    esac
  done
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm root >/dev/null 2>&1
}

# usage: br_run <tool path under the repository root> [args...]
br_run() {
  local tool="$1"
  shift
  ( cd "$REPO" && bash "$REPO_ROOT/$tool" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# ── validate-briefs.sh ───────────────────────────────────────────────────────

test_blc_root_validate_briefs_defaults_to_docs_blc_briefs() {
  br_repo new old
  br_run tools/validate-briefs.sh
  assert_status 0
  assert_out "validate-briefs: docs/blc/briefs — 1 brief(s)"
}

test_blc_root_validate_briefs_does_not_read_the_old_root() {
  br_repo old
  br_run tools/validate-briefs.sh
  [ "$LAST_STATUS" != 0 ] || fail "expected a refusal with only docs/briefs present"
  assert_not_contains "docs/briefs —" "$OUT"
}

test_blc_root_validate_briefs_reads_its_argument() {
  br_repo elsewhere
  br_run tools/validate-briefs.sh elsewhere/briefs
  assert_status 0
  assert_out "validate-briefs: elsewhere/briefs — 1 brief(s)"
}

# Project checks live at the repository root, read from the working directory.
test_blc_root_validate_briefs_finds_project_checks_at_the_root() {
  br_repo new
  mkdir -p "$REPO/brief-checks"
  printf '%s\n' '#!/usr/bin/env bash' 'echo "root check ran"' 'exit 1' > "$REPO/brief-checks/rule.sh"
  br_run tools/validate-briefs.sh
  assert_status 1
  assert_out "root check ran"
}

# The validator once found the root by depth above the briefs directory. Given the old
# docs/briefs layout, three levels up was the repository's parent: it ran the parent's
# brief-checks/ and skipped the repository's own.
test_blc_root_validate_briefs_runs_only_the_repositorys_checks_for_any_briefs_path() {
  br_repo old
  mkdir -p "$REPO/brief-checks" "$TMP/brief-checks"
  printf '%s\n' '#!/usr/bin/env bash' 'echo "root check ran"' 'exit 1' > "$REPO/brief-checks/rule.sh"
  printf '%s\n' '#!/usr/bin/env bash' 'echo "outside check ran"' 'exit 1' > "$TMP/brief-checks/rule.sh"
  br_run tools/validate-briefs.sh docs/briefs
  assert_status 1
  assert_out "root check ran"
  assert_not_contains "outside check ran" "$OUT"
}

# ── open-briefs.sh ───────────────────────────────────────────────────────────

test_blc_root_open_briefs_defaults_to_docs_blc_briefs() {
  br_repo new old
  br_run tools/open-briefs.sh
  assert_status 0
  assert_out "open-briefs: docs/blc/briefs — 1 brief(s)"
}

test_blc_root_open_briefs_does_not_read_the_old_root() {
  br_repo old
  br_run tools/open-briefs.sh
  [ "$LAST_STATUS" != 0 ] || fail "expected a refusal with only docs/briefs present"
  assert_err "docs/blc/briefs"
}

test_blc_root_open_briefs_reads_its_argument() {
  br_repo elsewhere
  br_run tools/open-briefs.sh elsewhere/briefs
  assert_status 0
  assert_out "open-briefs: elsewhere/briefs — 1 brief(s)"
}

# ── list-briefs.sh ───────────────────────────────────────────────────────────

test_blc_root_list_briefs_defaults_to_docs_blc_briefs() {
  br_repo new
  br_run tools/list-briefs.sh
  assert_status 0
  assert_out "| #0001 | The thing |"
}

test_blc_root_list_briefs_does_not_read_the_old_root() {
  br_repo old
  br_run tools/list-briefs.sh
  [ "$LAST_STATUS" != 0 ] || fail "expected a refusal with only docs/briefs present"
  assert_err "docs/blc/briefs"
}

test_blc_root_list_briefs_reads_its_argument() {
  br_repo elsewhere
  br_run tools/list-briefs.sh elsewhere/briefs
  assert_status 0
  assert_out "| #0001 | The thing |"
}

# ── jira-csv.sh ──────────────────────────────────────────────────────────────

test_blc_root_jira_csv_defaults_to_docs_blc_briefs() {
  br_repo new
  br_run tools/jira-csv.sh 1
  assert_status 0
  assert_out '"docs/blc/briefs/0001-thing/brief.md"'
}

test_blc_root_jira_csv_does_not_read_the_old_root() {
  br_repo old
  br_run tools/jira-csv.sh 1
  assert_status 1
  [ ! -s "$OUT" ] || fail "a refusal wrote to stdout: $(head -2 "$OUT")"
}

test_blc_root_jira_csv_reads_its_argument() {
  br_repo elsewhere
  br_run tools/jira-csv.sh 1 elsewhere/briefs
  assert_status 0
  assert_out '"elsewhere/briefs/0001-thing/brief.md"'
}

# ── orient.sh ────────────────────────────────────────────────────────────────

test_blc_root_orient_defaults_to_docs_blc_briefs() {
  br_repo new old
  br_run tools/orient.sh
  assert_status 0
  assert_out "The thing"
  assert_not_contains "No \`docs/blc/briefs\`" "$OUT"
}

test_blc_root_orient_does_not_read_the_old_root() {
  br_repo old
  br_run tools/orient.sh
  assert_status 0
  assert_out "No \`docs/blc/briefs\` — nothing filed here yet."
}

# One argument moves every sibling, so a declaration beside the given briefs directory is
# read, and none at the default root is needed.
test_blc_root_orient_reads_its_argument_and_its_siblings() {
  br_repo elsewhere
  mkdir -p "$REPO/elsewhere/state"
  printf '# someone\n\n## 2026-09-09 — unfiled work\n' > "$REPO/elsewhere/state/someone.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm declare >/dev/null 2>&1
  br_run tools/orient.sh elsewhere/briefs
  assert_status 0
  assert_out "The thing"
  assert_out "**someone**"
}

# ── gather.sh ────────────────────────────────────────────────────────────────

# gather.sh takes no briefs argument, so it has a default and nothing to override.
test_blc_root_gather_reads_docs_blc_briefs() {
  br_repo new old
  br_run skills/blc-chronicle/scripts/gather.sh
  assert_status 0
  assert_out "- 0001-thing"
}

test_blc_root_gather_does_not_read_the_old_root() {
  br_repo old
  br_run skills/blc-chronicle/scripts/gather.sh
  [ "$LAST_STATUS" != 0 ] || fail "expected a refusal with only docs/briefs present"
  assert_err "docs/blc/briefs"
}
