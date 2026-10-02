# tools/lib/touch-log.sh — when a path was touched, from #0017 phase a (decisions 5 and 6).
#
# Helper names are prefixed tl_ because run.sh sources every test file into one shell.

tl_source_lib() {
  # shellcheck source=/dev/null
  . "$REPO_ROOT/tools/lib/touch-log.sh"
}

tl_repo() {
  REPO="$TMP/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
}

# usage: tl_commit <iso-date> <message>
# Every date here carries a non-zero offset. git 2.43 prints a UTC author date as `+00:00` and
# later versions print `Z`, so a UTC fixture asserts the git version, not the reader.
tl_commit() {
  git -C "$REPO" add -A
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git -C "$REPO" commit -qm "$2" >/dev/null 2>&1
}

# usage: tl_ledger <path> <title>
# Every ledger this writes differs only in its title, which is what makes two of them a copy
# in git's eyes.
tl_ledger() {
  mkdir -p "$(dirname "$REPO/$1")"
  printf '%s\n' "# Ledger — $2" '' '## Big decisions' '' '## Something else' '' '### Not a fork' \
    > "$REPO/$1"
}

# usage: tl_dates <ignore-file> <path>...
# Prints the ISO dates blc_touch_log reports, newest first, one per line.
tl_dates() {
  local ignore="$1"
  shift
  ( cd "$REPO" && tl_source_lib && blc_touch_log "$(blc_touch_skip "$ignore")" "$(blc_touch_renames)" "$@" ) \
    2>"$ERR" | cut -d' ' -f2
}

test_touch_log_follows_a_file_through_a_rename() {
  tl_source_lib
  tl_repo
  tl_ledger old/0001-a/ledger.md a
  tl_commit 2026-01-01T00:00:00-04:00 "add"
  git -C "$REPO" mv old new
  tl_commit 2026-02-01T00:00:00-04:00 "move"
  assert_count "2026-02-01T00:00:00-04:00
2026-01-01T00:00:00-04:00" "$(tl_dates none new/0001-a/)" "dates of a moved folder"
}

# `git log --follow` was the first version of this, and it follows copies. A ledger that is a
# near-copy of an older brief's took that brief's history, so its first date moved to before
# it existed.
test_touch_log_does_not_follow_a_copy() {
  tl_source_lib
  tl_repo
  tl_ledger 0001-a/ledger.md a
  tl_commit 2026-01-01T00:00:00-04:00 "first brief"
  tl_ledger 0002-b/ledger.md b
  tl_commit 2026-02-01T00:00:00-04:00 "second brief"
  assert_count "2026-02-01T00:00:00-04:00" "$(tl_dates none 0002-b/)" "dates of a near-copy"
}

# A brief is a draft, then filed, then moved: three names. Its first date is the draft's.
test_touch_log_follows_a_chain_of_renames() {
  tl_source_lib
  tl_repo
  tl_ledger docs/briefs/_drafts/thing.md thing
  tl_commit 2026-01-01T00:00:00-04:00 "draft"
  mkdir -p "$REPO/docs/briefs/0001-thing"
  git -C "$REPO" mv docs/briefs/_drafts/thing.md docs/briefs/0001-thing/brief.md
  tl_commit 2026-02-01T00:00:00-04:00 "file"
  mkdir -p "$REPO/docs/blc"
  git -C "$REPO" mv docs/briefs docs/blc/briefs
  tl_commit 2026-03-01T00:00:00-04:00 "move"
  assert_count "2026-01-01T00:00:00-04:00" "$(tl_dates none docs/blc/briefs/0001-thing/ | tail -1)" \
    "first date of a draft that was filed and moved"
}

# A file's old names are names, not patterns. Read as a pattern, `what-[x].md` matched an
# unrelated older draft, `what-x.md`, and the brief's first date moved to before it existed.
test_touch_log_reads_an_old_name_literally() {
  tl_source_lib
  tl_repo
  mkdir -p "$REPO/_drafts"
  printf 'other\n' > "$REPO/_drafts/what-x.md"
  tl_commit 2025-12-01T00:00:00-04:00 "another draft"
  tl_ledger "_drafts/what-[x].md" mine
  tl_commit 2026-01-01T00:00:00-04:00 "this draft"
  mkdir -p "$REPO/0001-a"
  git -C "$REPO" mv "_drafts/what-[x].md" 0001-a/brief.md
  tl_commit 2026-02-01T00:00:00-04:00 "file"
  assert_count "2026-01-01T00:00:00-04:00" "$(tl_dates none 0001-a/ | tail -1)" \
    "first date of a brief whose draft name holds a glob character"
}

test_touch_log_drops_an_ignored_commit_named_by_an_abbreviated_hash() {
  tl_source_lib
  tl_repo
  tl_ledger old/0001-a/ledger.md a
  tl_commit 2026-01-01T00:00:00-04:00 "add"
  git -C "$REPO" mv old new
  tl_commit 2026-02-01T00:00:00-04:00 "move"
  printf '# the move\n%s\n' "$(git -C "$REPO" rev-parse --short HEAD)" > "$REPO/ignore-revs"
  assert_count "2026-01-01T00:00:00-04:00" "$(tl_dates ignore-revs new/0001-a/)" "dates without the move"
}

# Two entries make the skip list two lines. The one true awk refused that in a -v value, and
# every tool that dates briefs failed under it once a second commit was ignored.
test_touch_log_drops_two_ignored_commits() {
  tl_source_lib
  tl_repo
  tl_ledger old/0001-a/ledger.md a
  tl_commit 2026-01-01T00:00:00-04:00 "add"
  git -C "$REPO" mv old new
  tl_commit 2026-02-01T00:00:00-04:00 "move"
  printf 'edit\n' >> "$REPO/new/0001-a/ledger.md"
  tl_commit 2026-03-01T00:00:00-04:00 "rewrite"
  git -C "$REPO" log --format=%H -2 > "$REPO/ignore-revs"
  assert_count "2026-01-01T00:00:00-04:00" "$(tl_dates ignore-revs new/0001-a/)" "dates without either commit"
  [ ! -s "$ERR" ] || fail "two ignored commits reported: $(cat "$ERR")"
}

test_touch_log_without_an_ignore_file_ignores_nothing() {
  tl_source_lib
  tl_repo
  tl_ledger 0001-a/ledger.md a
  tl_commit 2026-01-01T00:00:00-04:00 "add"
  assert_count "2026-01-01T00:00:00-04:00" "$(tl_dates no-such-file 0001-a/)" "dates"
  [ ! -s "$ERR" ] || fail "a missing ignore file reported: $(cat "$ERR")"
}

test_touch_log_an_untracked_path_has_no_dates() {
  tl_source_lib
  tl_repo
  tl_ledger 0001-a/ledger.md a
  tl_commit 2026-01-01T00:00:00-04:00 "add"
  tl_ledger 0002-b/ledger.md b
  assert_count "" "$(tl_dates none 0002-b/)" "dates of an uncommitted brief"
}

test_touch_log_a_repository_with_no_commits_has_no_renames() {
  tl_source_lib
  tl_repo
  ( cd "$REPO" && set -eo pipefail && r="$(blc_touch_renames)" && printf 'ok[%s]' "$r" ) >"$OUT" 2>"$ERR"
  assert_out "ok[]"
}

# ── Through list-briefs.sh ───────────────────────────────────────────────────

# The case #0017 is about: a whole tree moved in one commit, and the commit named in the
# ignore list beside the briefs directory. The table keeps its pre-move dates and order.
test_touch_log_list_briefs_keeps_dates_through_an_ignored_move() {
  tl_repo
  fixture_install_tool "$REPO" list-briefs.sh
  tl_ledger docs/briefs/0001-a/ledger.md a
  printf '# A\n' > "$REPO/docs/briefs/0001-a/brief.md"
  tl_commit 2026-01-01T00:00:00-04:00 "first"
  tl_ledger docs/briefs/0002-b/ledger.md b
  printf '# B\n' > "$REPO/docs/briefs/0002-b/brief.md"
  tl_commit 2026-02-01T00:00:00-04:00 "second"
  mkdir -p "$REPO/docs/blc"
  git -C "$REPO" mv docs/briefs docs/blc/briefs
  tl_commit 2026-03-01T00:00:00-04:00 "move"
  git -C "$REPO" rev-parse HEAD > "$REPO/docs/blc/ignore-revs"
  ( cd "$REPO" && bash tools/list-briefs.sh ) >"$OUT" 2>"$ERR"
  assert_out "| #0002 | B | no-line | 2026-02-01T00:00:00-04:00 | 2026-02-01T00:00:00-04:00 | — |"
  assert_out "| #0001 | A | no-line | 2026-01-01T00:00:00-04:00 | 2026-01-01T00:00:00-04:00 | — |"
  assert_not_contains "2026-03-01" "$OUT"
}

# Resolved once per run. The first version resolved it once per brief and printed the same
# complaint once for every brief in the table.
test_touch_log_list_briefs_reports_a_bad_ignore_entry_once() {
  tl_repo
  fixture_install_tool "$REPO" list-briefs.sh
  tl_ledger docs/blc/briefs/0001-a/ledger.md a
  tl_ledger docs/blc/briefs/0002-b/ledger.md b
  printf 'notacommit\n' > "$REPO/docs/blc/ignore-revs"
  tl_commit 2026-01-01T00:00:00-04:00 "add"
  ( cd "$REPO" && bash tools/list-briefs.sh ) >"$OUT" 2>"$ERR"
  assert_count 1 "$(grep -c 'notacommit is not a commit here' "$ERR")" "reports of the bad entry"
}
