# tools/list-briefs.sh — the brief table, extracted from the chronicle by #0008a.
#
# The table's own behaviour (ordering, status parsing, missing ledgers, pipes in
# titles) is asserted through the chronicle in test_gather.sh, which is where those
# tests were written and where they still run. This file covers what the extraction
# newly made possible or newly put at risk: the tool standing on its own, the --tsv
# contract the chronicle depends on, the --owner filter, and the fact that it ships.

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

# #0013 phase b legalized the frontmatter placement in `open-briefs`. This reader always
# accepted it, and pinning that keeps the two from drifting apart again — the disagreement
# was the defect, not either reader on its own.
test_list_briefs_reads_a_status_line_under_frontmatter() {
  list_repo
  mkdir -p "$REPO/docs/briefs/0001-fm"
  printf '# The thing\n' > "$REPO/docs/briefs/0001-fm/brief.md"
  printf -- '---\ntitle: fm\ntags: [ledger]\n---\n\n# Ledger\n`blc/2 #0001 done a:done`\n' \
    > "$REPO/docs/briefs/0001-fm/ledger.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "add 0001-fm" >/dev/null 2>&1
  run_list docs/briefs
  assert_status 0
  assert_out "| #0001 | The thing | done |"
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

# ── --owner: what is mine (#0007 phase c) ────────────────────────────────────

# usage: lb_brief <folder> <identity-tail> [ledger-status-line]
# The identity tail follows `**Author:** `, e.g. 'me@x.org · **Owner:** you@x.org'.
lb_brief() {
  local folder="$1" tail="$2" status="${3:-}" n="${1%%-*}"
  mkdir -p "$REPO/docs/briefs/$folder"
  printf '# Brief %s\n\n**Serial:** #%s · **Created:** 2026-01-01T00:00:00Z · **Author:** %s · **Depends on:** —\n' \
    "$n" "$n" "$tail" > "$REPO/docs/briefs/$folder/brief.md"
  [ -n "$status" ] && printf '# Ledger\n%s\n' "$status" > "$REPO/docs/briefs/$folder/ledger.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "add $folder" >/dev/null 2>&1
}

lb_listed() { grep -q "^| #$1 |" "$OUT"; }

test_list_briefs_owner_lists_a_brief_owned_by_the_email() {
  list_repo
  lb_brief 0001-a 'filer@x.org · **Owner:** me@x.org' '`blc/2 #0001 in-progress a:in-progress`'
  run_list --owner me@x.org docs/briefs
  assert_status 0
  lb_listed 0001 || fail "the owner's brief is not listed: $(cat "$OUT")"
}

test_list_briefs_owner_falls_back_to_author() {
  list_repo
  lb_brief 0001-a 'me@x.org'
  run_list --owner me@x.org docs/briefs
  lb_listed 0001 || fail "a brief with no Owner is not listed for its Author: $(cat "$OUT")"
}

# Owner exists to say the filer is not the executor. Listing it for both would undo that.
test_list_briefs_owner_takes_the_brief_away_from_the_author() {
  list_repo
  lb_brief 0001-a 'me@x.org · **Owner:** you@x.org'
  run_list --owner me@x.org docs/briefs
  ! lb_listed 0001 || fail "the Author still sees a brief someone else owns"
  run_list --owner you@x.org docs/briefs
  lb_listed 0001 || fail "the Owner does not see the brief"
}

test_list_briefs_owner_ignores_case() {
  list_repo
  lb_brief 0001-a 'filer@x.org · **Owner:** Me@X.org'
  run_list --owner mE@x.ORG docs/briefs
  lb_listed 0001 || fail "the match depends on case"
}

# Decision 8: assigned is everything not finished, a brief with no ledger included.
test_list_briefs_owner_lists_only_unfinished_briefs() {
  list_repo
  lb_brief 0001-planned 'me@x.org'
  lb_brief 0002-going 'me@x.org' '`blc/2 #0002 in-progress a:in-progress`'
  lb_brief 0003-parked 'me@x.org' '`blc/2 #0003 deferred a:deferred`'
  lb_brief 0004-noline 'me@x.org' 'no status line here'
  lb_brief 0005-done 'me@x.org' '`blc/2 #0005 done a:done`'
  lb_brief 0006-skipped 'me@x.org' '`blc/2 #0006 skipped a:skipped`'
  lb_brief 0007-old 'me@x.org' '`blc/1 #0007 done(commit 383ed5b) 1:done`'
  run_list --owner me@x.org docs/briefs
  assert_status 0
  local s
  for s in 0001 0002 0003 0004; do lb_listed "$s" || fail "#$s is unfinished and not listed"; done
  for s in 0005 0006 0007; do ! lb_listed "$s" || fail "#$s is finished and listed"; done
}

# A misspelt Owner makes "mine" come back empty, which looks like an answer (decision 6).
test_list_briefs_owner_reports_a_malformed_owner() {
  list_repo
  lb_brief 0001-a 'me@x.org · **Owner:** me at x dot org'
  lb_brief 0002-b 'me@x.org · **Owner:**'
  lb_brief 0003-c 'me@x.org · **Owner:** me@x.org, you@x.org'
  run_list --owner me@x.org docs/briefs
  assert_status 0
  assert_contains "#0001: Owner 'me at x dot org' is not an email" "$ERR"
  assert_contains "#0002: Owner '' is not an email" "$ERR"
  # One owner per brief. Two would match neither of them, and say nothing.
  assert_contains "#0003: Owner 'me@x.org, you@x.org' is not an email" "$ERR"
  ! lb_listed 0001 || fail "a malformed Owner fell back to the Author"
  ! lb_listed 0002 || fail "a blank Owner fell back to the Author"
  ! lb_listed 0003 || fail "a two-email Owner was listed"
  # Assigned to no one means no one, including the malformed value itself.
  run_list --owner 'me@x.org, you@x.org' docs/briefs
  ! lb_listed 0003 || fail "a malformed Owner was listed under its own value"
}

# Markdown or mail syntax around an address would make it match no one, with no message.
test_list_briefs_owner_reports_an_owner_in_markup() {
  list_repo
  lb_brief 0001-a 'me@x.org · **Owner:** `me@x.org`'
  lb_brief 0002-b 'me@x.org · **Owner:** <me@x.org>'
  run_list --owner me@x.org docs/briefs
  assert_contains "#0001: Owner '\`me@x.org\`' is not an email" "$ERR"
  assert_contains "#0002: Owner '<me@x.org>' is not an email" "$ERR"
}

# validate-briefs.sh does not anchor its Author check, so this Author passes BRIEFS-5.
test_list_briefs_owner_reports_a_malformed_author_it_falls_back_to() {
  list_repo
  lb_brief 0001-a 'me@x.org, you@x.org'
  run_list --owner me@x.org docs/briefs
  assert_status 0
  assert_contains "#0001: Author 'me@x.org, you@x.org' is not an email" "$ERR"
  ! lb_listed 0001 || fail "a two-email Author was listed"
}

test_list_briefs_owner_does_not_report_a_finished_brief() {
  list_repo
  lb_brief 0001-a 'me@x.org · **Owner:** nope' '`blc/2 #0001 done a:done`'
  run_list --owner me@x.org docs/briefs
  [ ! -s "$ERR" ] || fail "a finished brief was reported: $(cat "$ERR")"
}

test_list_briefs_without_owner_reports_nothing_and_lists_everything() {
  list_repo
  lb_brief 0001-a 'me@x.org · **Owner:** nope'
  lb_brief 0002-b 'me@x.org' '`blc/2 #0002 done a:done`'
  run_list docs/briefs
  [ ! -s "$ERR" ] || fail "the unfiltered table reported: $(cat "$ERR")"
  lb_listed 0001 && lb_listed 0002 || fail "the unfiltered table dropped a brief: $(cat "$OUT")"
}

test_list_briefs_owner_with_nothing_assigned_is_a_dash_row() {
  list_repo
  lb_brief 0001-a 'you@x.org'
  run_list --owner me@x.org docs/briefs
  assert_status 0
  assert_out "| — | — | — | — | — | — |"
}

test_list_briefs_owner_refuses_a_missing_email_and_tsv() {
  list_repo
  run_list --owner
  assert_status 1
  assert_contains "--owner needs an email" "$ERR"
  run_list --tsv --owner me@x.org
  assert_status 1
  assert_contains "does not apply to --tsv" "$ERR"
  run_list --bogus
  assert_status 1
  assert_contains "unknown option --bogus" "$ERR"
}

# The skill fetches. The query must not: a report that changes the repository is a surprise.
test_list_briefs_owner_does_not_fetch() {
  list_repo
  git clone -q --bare "$REPO" "$TMP/upstream.git"
  git -C "$REPO" remote add origin "$TMP/upstream.git"
  lb_brief 0001-a 'me@x.org'
  run_list --owner me@x.org docs/briefs
  assert_status 0
  [ ! -e "$REPO/.git/FETCH_HEAD" ] || fail "the query fetched"
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
