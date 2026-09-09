# tools/list-briefs.sh — the brief table, extracted from the chronicle by #0008a.
#
# The table's own behaviour (ordering, status parsing, missing ledgers, pipes in
# titles) is asserted through the chronicle in test_gather.sh, which is where those
# tests were written and where they still run. This file covers what the extraction
# newly made possible or newly put at risk: the tool standing on its own, the --tsv
# contract the chronicle depends on, and the fact that it ships.

LIST() { printf '%s' "$REPO_ROOT/tools/list-briefs.sh"; }

run_list() {
  ( cd "$REPO" && bash "$(LIST)" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

list_repo() {
  REPO="$TMP/repo"
  mkdir -p "$REPO/docs/briefs"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
  echo "# Briefs" > "$REPO/docs/briefs/README.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm root >/dev/null 2>&1
}

# usage: list_brief <folder> <title> [ledger-status-line]
list_brief() {
  local folder="$1" title="$2" status="${3:-}"
  mkdir -p "$REPO/docs/briefs/$folder"
  printf '# %s\n' "$title" > "$REPO/docs/briefs/$folder/brief.md"
  [ -n "$status" ] && printf '# Ledger\n%s\n' "$status" > "$REPO/docs/briefs/$folder/ledger.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "add $folder" >/dev/null 2>&1
}

# ── Standing on its own ──────────────────────────────────────────────────────

test_list_briefs_emits_a_table_with_no_caller() {
  list_repo
  list_brief 0001-thing "The thing" '`blc/2 #0001 done a:done`'
  run_list docs/briefs
  assert_status 0
  assert_out "| serial | title | status | first | last | depends-on |"
  assert_out "| #0001 | The thing | done |"
}

# The table alone, so a caller can put it under any heading. The chronicle prints its
# own `## Briefs` line above the call and would print it twice if the tool did too.
test_list_briefs_emits_no_heading_of_its_own() {
  list_repo
  list_brief 0001-thing "The thing"
  run_list docs/briefs
  assert_status 0
  assert_not_contains "## Briefs" "$OUT"
}

test_list_briefs_defaults_to_docs_briefs() {
  list_repo
  list_brief 0001-thing "The thing"
  run_list
  assert_status 0
  assert_out "| #0001 | The thing |"
}

test_list_briefs_renders_an_empty_tree_as_a_dash_row() {
  list_repo
  run_list docs/briefs
  assert_status 0
  assert_out "| — | — | — | — | — | — |"
}

test_list_briefs_refuses_without_a_briefs_directory() {
  REPO="$TMP/bare"
  mkdir -p "$REPO"
  git -C "$REPO" init -q -b main
  run_list docs/briefs
  [ "$LAST_STATUS" -ne 0 ] || fail "expected a non-zero status with no docs/briefs"
  assert_err "No docs/briefs"
}

# ── The --tsv contract ───────────────────────────────────────────────────────

# The chronicle reads these five fields positionally into its narration loop. A
# column added, removed, or reordered here breaks it silently — the read succeeds
# and the wrong value lands in each variable.
test_list_briefs_tsv_emits_five_tab_separated_fields() {
  list_repo
  list_brief 0001-thing "The thing"
  run_list --tsv docs/briefs
  assert_status 0
  local fields
  fields="$(head -1 "$OUT" | awk -F'\t' '{print NF}')"
  [ "$fields" = 5 ] || fail "expected 5 tab-separated fields, got $fields"
  assert_out "0001-thing"
}

test_list_briefs_tsv_emits_no_table_markup() {
  list_repo
  list_brief 0001-thing "The thing"
  run_list --tsv docs/briefs
  assert_status 0
  assert_not_contains "| serial |" "$OUT"
}

# Both modes walk the same briefs in the same order. If they ever disagree, the
# chronicle narrates one sequence under a table showing another.
test_list_briefs_tsv_and_table_agree_on_order() {
  list_repo
  list_brief 0001-first  "First"
  list_brief 0002-second "Second"
  list_brief 0003-third  "Third"

  run_list --tsv docs/briefs
  assert_status 0
  local tsv_order
  tsv_order="$(awk -F'\t' '{print $2}' "$OUT" | sed 's/-.*//' | tr '\n' ' ')"

  run_list docs/briefs
  assert_status 0
  local table_order
  table_order="$(grep -o '#[0-9]\{4\}' "$OUT" | tr -d '#' | tr '\n' ' ')"

  [ "$tsv_order" = "$table_order" ] \
    || fail "tsv order [$tsv_order] disagrees with table order [$table_order]"
}

test_list_briefs_tsv_is_empty_for_an_empty_tree() {
  list_repo
  run_list --tsv docs/briefs
  assert_status 0
  [ ! -s "$OUT" ] || fail "expected no output for an empty tree, got: $(head -1 "$OUT")"
}

# ── It has to travel ─────────────────────────────────────────────────────────

# The chronicle skill exits non-zero without this tool, so a target that got the
# skill and not the tool would have a chronicle that cannot run at all.
test_list_briefs_installs_into_a_target() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/tools/list-briefs.sh"
  [ -x "$TARGET/tools/list-briefs.sh" ] || fail "installed list-briefs.sh is not executable"
}

test_list_briefs_is_named_in_the_install_summary() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_out "list-briefs.sh"
}
