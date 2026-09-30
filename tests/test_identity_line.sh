# The shared identity-line reader.
#
# Two readers of one line can disagree about which line it is and where a field ends, and still
# agree on every real brief, so no test against real data can see it. The fixtures below are
# the shapes that separate them.
#
# Helper names are prefixed IL_ / il_ because run.sh sources every test file into one shell.
# See "Helper names are shared across every test file" in tests/README.md.

IL_LIB="tools/lib/identity-line.sh"

il_source_lib() {
  # shellcheck source=/dev/null
  . "$REPO_ROOT/$IL_LIB"
}

IL_LINE='**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** #0002, #0003 · **Jira:** ticket #9999'

# ── The reader ───────────────────────────────────────────────────────────────

test_identity_line_a_field_ends_at_the_next_separator() {
  il_source_lib
  [ "$(blc_identity_field "$IL_LINE" "Depends on")" = "#0002, #0003" ] \
    || fail "Depends on read past the next ·: '$(blc_identity_field "$IL_LINE" "Depends on")'"
}

test_identity_line_the_last_field_ends_at_the_end_of_the_line() {
  il_source_lib
  [ "$(blc_identity_field "$IL_LINE" Jira)" = "ticket #9999" ] \
    || fail "the last field did not read to the end of the line"
}

test_identity_line_the_first_field_is_read_whole() {
  il_source_lib
  [ "$(blc_identity_field "$IL_LINE" Serial)" = "#0001" ] \
    || fail "Serial did not read back as #0001"
}

# Callers tell "the field is missing" from "the field is blank" by the return status, and
# BRIEFS-5 reports only the first. Returning 1 for a blank value would report a present
# `Depends on:` as missing.
test_identity_line_a_missing_field_returns_1_and_a_blank_one_returns_0() {
  il_source_lib
  local rc=0
  blc_identity_field "$IL_LINE" Owner >/dev/null || rc=$?
  [ "$rc" -eq 1 ] || fail "a missing field returned $rc, not 1"
  rc=0
  blc_identity_field '**Serial:** #0001 · **Depends on:**' "Depends on" >/dev/null || rc=$?
  [ "$rc" -eq 0 ] || fail "a blank field returned $rc, so it would be reported as missing"
}

test_identity_line_the_first_of_a_repeated_label_wins() {
  il_source_lib
  local line='**Serial:** #0001 · **Depends on:** #0002 · **Depends on:** #0007'
  [ "$(blc_identity_field "$line" "Depends on")" = "#0002" ] \
    || fail "a repeated label did not read the first occurrence"
}

test_identity_line_unknown_fields_are_tolerated() {
  il_source_lib
  local line='**Serial:** #0001 · **Colour:** blue · **Author:** a@b.com'
  [ "$(blc_identity_field "$line" Author)" = "a@b.com" ] \
    || fail "a field the reader does not know broke the one after it"
}

test_identity_line_locates_the_first_serial_line() {
  il_source_lib
  local f="$TMP/il-locate.md"
  printf '%s\n' '# Title' '' '**Serial:** #0004 · **Depends on:** —' '' '**Serial:** #9999' > "$f"
  [ "$(blc_identity_line "$f")" = '**Serial:** #0004 · **Depends on:** —' ] \
    || fail "did not locate the first identity line"
}

test_identity_line_absent_returns_1() {
  il_source_lib
  local f="$TMP/il-none.md" rc=0
  printf '%s\n' '# Title' 'No identity line here.' > "$f"
  blc_identity_line "$f" >/dev/null || rc=$?
  [ "$rc" -eq 1 ] || fail "a brief with no identity line returned $rc, not 1"
}

# ── The two tools agree ──────────────────────────────────────────────────────

il_repo() {
  IL_REPO="$TMP/il-repo"
  rm -rf "$IL_REPO"
  mkdir -p "$IL_REPO/docs/briefs"
  git -C "$IL_REPO" init -q -b main
  git -C "$IL_REPO" config user.email t@example.com
  git -C "$IL_REPO" config user.name Test
  echo "# Briefs" > "$IL_REPO/docs/briefs/README.md"
}

# usage: il_brief <folder> <lines...>
il_brief() {
  local folder="$1"; shift
  mkdir -p "$IL_REPO/docs/briefs/$folder"
  printf '%s\n' "$@" > "$IL_REPO/docs/briefs/$folder/brief.md"
}

il_commit() {
  git -C "$IL_REPO" add -A
  git -C "$IL_REPO" commit -qm fixture >/dev/null 2>&1
}

il_list_depends() {
  ( cd "$IL_REPO" && bash "$REPO_ROOT/tools/list-briefs.sh" ) \
    | awk -F'|' -v s="#$1" '{ gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $7) } $2 == s { print $7 }'
}

# Prose that mentions the field above the identity line must not reach the dependency column.
# A reader that took the first `Depends on` anywhere in the file would print `#9999 is parsed.`
test_identity_line_prose_above_the_line_does_not_reach_list_briefs() {
  il_repo
  il_brief 0001-prose '# Prose first' '' \
    'This brief is about how **Depends on:** #9999 is parsed.' '' \
    '**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —'
  il_commit
  local got
  got="$(il_list_depends 0001)"
  [ "$got" = "—" ] || fail "list-briefs.sh read prose above the identity line: '$got'"
  bash "$REPO_ROOT/tools/validate-briefs.sh" "$IL_REPO/docs/briefs" >"$OUT" 2>&1 \
    || fail "the validator rejected the same brief: $(cat "$OUT")"
  assert_out "0 defect(s)"
}

# The "field end" disagreement, asked of both tools on one fixture. The validator must count
# #0002 and not #9999, and list-briefs.sh must show the same value.
test_identity_line_both_tools_end_depends_on_at_the_separator() {
  il_repo
  il_brief 0002-real '# Real' '' \
    '**Serial:** #0002 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —'
  il_brief 0001-trailing '# Trailing' '' \
    '**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** #0002 · **Jira:** ticket #9999'
  il_commit
  local got
  got="$(il_list_depends 0001)"
  [ "$got" = "#0002" ] || fail "list-briefs.sh shows '$got', not #0002"
  rm -rf "$IL_REPO/docs/briefs/0002-real"
  bash "$REPO_ROOT/tools/validate-briefs.sh" "$IL_REPO/docs/briefs" >"$OUT" 2>&1 || true
  assert_out "depends on #0002"
  assert_not_contains "#9999" "$OUT"
}

# ── One reader, and both tools on it ─────────────────────────────────────────

# Code spellings of each label the identity line carries: regex-escaped and bracketed, as grep,
# sed or awk write them, and followed by a closing quote, as a quoted literal writes them.
# Comments name labels in backticks and messages name them without asterisks, so neither
# trips the guard. It is a fingerprint, not a parser: a spelling outside these four is missed.
il_fingerprints() {
  local label
  for label in Serial Created Author "Depends on"; do
    printf '%s\n' "$label:\\*\\*" "$label:[*][*]" "**$label:**'" "**$label:**\""
  done
}

il_readers_under() {
  il_fingerprints | while IFS= read -r fp; do
    grep -rlF -- "$fp" "$1" 2>/dev/null
  done | sort -u
}

# Positive control: without it the scan could quietly stop matching and report a clean tree.
test_identity_line_the_fingerprint_still_matches_the_library() {
  il_readers_under "$REPO_ROOT/tools/lib" | grep -q identity-line.sh \
    || fail "no fingerprint appears in $IL_LIB, so the guard cannot fail"
}

test_identity_line_the_guard_catches_a_planted_copy() {
  local planted="$TMP/il-planted"
  mkdir -p "$planted"
  cp "$REPO_ROOT/$IL_LIB" "$planted/copycat.sh"
  il_readers_under "$planted" | grep -q copycat.sh \
    || fail "the scan did not find a copy of the reader planted in front of it"
}

# A whole-file sed read of `Depends on`: the likeliest shape of a rebuilt reader.
test_identity_line_the_guard_catches_the_old_sed_reader() {
  local planted="$TMP/il-sed"
  mkdir -p "$planted"
  printf '%s\n' 'deps() {' \
    "  sed -n 's/.*\\*\\*Depends on:\\*\\* *//p' \"\$1\" | head -1" '}' > "$planted/rebuilt.sh"
  il_readers_under "$planted" | grep -q rebuilt.sh \
    || fail "a sed-shaped rebuild of the reader was not caught"
}

test_identity_line_the_guard_catches_a_case_shaped_rebuild() {
  local planted="$TMP/il-case"
  mkdir -p "$planted"
  printf '%s\n' 'deps() {' '  case "$1" in *"**Depends on:**"*) echo yes ;; esac' '}' \
    > "$planted/rebuilt.sh"
  il_readers_under "$planted" | grep -q rebuilt.sh \
    || fail "a case-shaped rebuild of the reader was not caught"
}

test_identity_line_the_guard_catches_every_label_in_every_spelling() {
  local planted="$TMP/il-spellings" n=0
  mkdir -p "$planted"
  printf '%s\n' "grep -F '**Depends on:**' \"\$1\"" > "$planted/single-quoted.sh"
  printf '%s\n' "grep -E '^[*][*]Serial:[*][*]' \"\$1\"" > "$planted/bracketed.sh"
  printf '%s\n' "sed -n 's/.*\\*\\*Created:\\*\\* *//p' \"\$1\"" > "$planted/created.sh"
  printf '%s\n' 'case "$1" in *"**Author:**"*) ;; esac' > "$planted/author.sh"
  n=$(il_readers_under "$planted" | wc -l)
  [ "$n" -eq 4 ] || fail "the guard caught $n of 4 planted readers: $(il_readers_under "$planted")"
}

test_identity_line_no_tool_rebuilds_the_reader() {
  local hits
  hits="$(il_readers_under "$REPO_ROOT/tools" | grep -v "$IL_LIB" || true)"
  [ -z "$hits" ] || fail "an identity-line reader exists outside $IL_LIB: $hits"
}

test_identity_line_both_tools_read_the_library() {
  assert_loads_library validate-briefs.sh identity-line
  assert_loads_library list-briefs.sh identity-line
}
