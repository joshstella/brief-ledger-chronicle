# The chronicle's source digest — skills/chronicle/scripts/gather.sh.
#
# This script had no tests until after it shipped broken on one of its two paths,
# and the failure it shipped with is the reason the fixtures below are shaped the
# way they are. It runs under `set -euo pipefail`, so any benign non-zero inside a
# pipeline — grep finding nothing, head closing a pipe — ends the run mid-loop with
# empty stderr and a digest that simply stops. Nothing downstream notices: a
# chronicle written from a truncated digest reads as a complete history of a
# shorter period.
#
# So the assertions are about completeness, not just content. A test that only
# checked for a header would pass against every truncation this script has had.

GATHER() { printf '%s' "$REPO_ROOT/skills/chronicle/scripts/gather.sh"; }

run_gather() {
  ( cd "$REPO" && bash "$(GATHER)" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# Real git, because the script reads real git. The dates are set explicitly so the
# chronological-ordering test asserts something git decided rather than something
# the filesystem happened to do.
gather_repo() {
  REPO="$TMP/repo"
  BRIEFS="$REPO/docs/briefs"
  mkdir -p "$BRIEFS/_drafts"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
  echo "# Briefs" > "$BRIEFS/README.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "root" >/dev/null 2>&1
}

# usage: gather_brief <folder> [depends-on-text]
# Omitting the second argument is the ordinary case of a brief that declares no
# dependency — not a malformed one.
gather_brief() {
  local folder="$1" dep="${2:-}"
  mkdir -p "$BRIEFS/$folder"
  {
    echo "# ${folder#*-}"
    [ -n "$dep" ] && echo "**Depends on:** $dep"
    echo ""
    echo "Body."
  } > "$BRIEFS/$folder/brief.md"
}

# usage: gather_ledger <folder> [big-decision-headings...]
gather_ledger() {
  local folder="$1"
  shift
  mkdir -p "$BRIEFS/$folder"
  {
    echo "# Ledger — ${folder#*-}"
    echo ""
    echo "## Big decisions"
    echo ""
    local h
    for h in "$@"; do echo "### $h"; echo ""; done
    echo "## Something else"
    echo ""
    echo "### Not a fork"
  } > "$BRIEFS/$folder/ledger.md"
}

# usage: gather_commit <iso-date> <message>
gather_commit() {
  git -C "$REPO" add -A
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" \
    git -C "$REPO" commit -qm "$2" >/dev/null 2>&1
}

# ── The bug this file was written for ────────────────────────────────────────
#
# A brief with no `Depends on:` line made grep exit 1, pipefail carried it out of
# the command substitution, and set -e ended the run. Exit 1, empty stderr, digest
# truncated after the briefs header. Invisible in a repo where every brief happens
# to carry the line, which is exactly where it went unnoticed.

test_gather_a_brief_without_a_depends_on_line_does_not_end_the_run() {
  gather_repo
  gather_brief "0001-alpha"
  gather_ledger "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  assert_out "0001-alpha"
  # The section after the briefs loop has to be reached, or the digest is truncated
  # in exactly the way that produced a wrong chronicle.
  assert_out "## Commits referencing a brief serial"
}

test_gather_a_missing_depends_on_renders_as_a_dash() {
  gather_repo
  gather_brief "0001-alpha"
  gather_ledger "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  assert_out "depends-on: —"
}

test_gather_a_present_depends_on_is_extracted() {
  gather_repo
  gather_brief "0002-beta" "#0001"
  gather_ledger "0002-beta"
  gather_commit "2026-01-01T00:00:00" "seed #0002"
  run_gather
  assert_status 0
  assert_out "depends-on: #0001"
}

# Mixed is the case that matters: one brief without the line must not stop the
# briefs that sort after it.
test_gather_one_brief_without_depends_on_does_not_hide_the_others() {
  gather_repo
  gather_brief "0001-alpha"
  gather_ledger "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  gather_brief "0002-beta" "#0001"
  gather_ledger "0002-beta"
  gather_commit "2026-01-02T00:00:00" "seed #0002"
  run_gather
  assert_status 0
  assert_out "0001-alpha"
  assert_out "0002-beta"
}

# ── Chronology ───────────────────────────────────────────────────────────────
#
# The header calls git first-commit date authoritative, which is only meaningful
# if it can disagree with serial order. Committing 0002 first makes them disagree.

test_gather_orders_briefs_by_first_commit_not_by_serial() {
  gather_repo
  gather_brief "0002-beta"
  gather_ledger "0002-beta"
  gather_commit "2026-01-01T00:00:00" "seed #0002"
  gather_brief "0001-alpha"
  gather_ledger "0001-alpha"
  gather_commit "2026-06-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  local first
  first=$(grep -oE '000[12]-(alpha|beta)' "$OUT" | head -1)
  [ "$first" = "0002-beta" ] \
    || fail "expected 0002-beta first by commit date, got ${first:-nothing}"
}

# ── Ledger presence and forks ────────────────────────────────────────────────

test_gather_marks_a_brief_without_a_ledger_as_planned() {
  gather_repo
  gather_brief "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  assert_out "planned"
}

test_gather_marks_a_brief_with_a_ledger_as_executed() {
  gather_repo
  gather_brief "0001-alpha"
  gather_ledger "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  assert_out "executed"
}

test_gather_lists_big_decision_headings_as_forks() {
  gather_repo
  gather_brief "0001-alpha"
  gather_ledger "0001-alpha" "The first fork" "The second fork"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  assert_out "fork · The first fork"
  assert_out "fork · The second fork"
}

# Headings under a later section are not forks. Without this, the awk range could
# run to end-of-file and every heading in the ledger would be reported as a fork.
test_gather_stops_collecting_forks_at_the_next_section() {
  gather_repo
  gather_brief "0001-alpha"
  gather_ledger "0001-alpha" "The first fork"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  assert_not_contains "fork · Not a fork" "$OUT"
}

# ── Drafts ───────────────────────────────────────────────────────────────────

test_gather_lists_drafts_with_their_titles() {
  gather_repo
  gather_brief "0001-alpha"
  printf '# Some parked idea\n' > "$BRIEFS/_drafts/parked.md"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  assert_out "parked.md: Some parked idea"
}

test_gather_does_not_list_the_drafts_readme_as_a_draft() {
  gather_repo
  gather_brief "0001-alpha"
  printf '# Drafts\n' > "$BRIEFS/_drafts/README.md"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  assert_not_contains "README.md:" "$OUT"
}

test_gather_says_so_when_there_are_no_drafts() {
  gather_repo
  gather_brief "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather
  assert_status 0
  assert_out "(none since ever)"
}

# ── Incremental mode ─────────────────────────────────────────────────────────

test_gather_incremental_omits_briefs_untouched_since_the_cutoff() {
  gather_repo
  gather_brief "0001-old"
  gather_ledger "0001-old"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  gather_brief "0002-new"
  gather_ledger "0002-new"
  gather_commit "2026-06-01T00:00:00" "seed #0002"
  run_gather "2026-03-01"
  assert_status 0
  assert_out "0002-new"
  assert_not_contains "0001-old" "$OUT"
}

test_gather_incremental_names_the_window_it_used() {
  gather_repo
  gather_brief "0001-alpha"
  gather_ledger "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather "2025-01-01"
  assert_status 0
  assert_out "Incremental since: 2025-01-01"
}

# The empty result has to be stated. Silence would read as "no briefs exist".
test_gather_incremental_says_so_when_nothing_is_new() {
  gather_repo
  gather_brief "0001-alpha"
  gather_ledger "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather "2026-06-01"
  assert_status 0
  assert_out "(no new briefs since 2026-06-01)"
}

# The incremental path is the one that shipped broken, and it broke by ending early
# rather than by printing anything wrong. Reaching the final section is the check.
test_gather_incremental_runs_to_the_end() {
  gather_repo
  gather_brief "0001-alpha" "#0000"
  gather_ledger "0001-alpha" "A fork"
  gather_commit "2026-01-01T00:00:00" "seed #0001"
  run_gather "2025-01-01"
  assert_status 0
  assert_out "## Parked / considered"
  assert_out "## Commits referencing a brief serial"
}

# ── The commit section and its ceiling ───────────────────────────────────────

test_gather_lists_commits_that_name_a_serial() {
  gather_repo
  gather_brief "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "work #0001 something"
  run_gather
  assert_status 0
  assert_out "work #0001 something"
}

test_gather_says_none_found_when_no_commit_names_a_serial() {
  gather_repo
  gather_brief "0001-alpha"
  gather_commit "2026-01-01T00:00:00" "no serial here"
  run_gather
  assert_status 0
  assert_out "(none found)"
}

# Under the ceiling, nothing is dropped, so claiming a truncation would be a lie.
test_gather_is_silent_about_truncation_when_nothing_is_dropped() {
  gather_repo
  gather_brief "0001-alpha"
  local i
  for i in $(seq 1 5); do
    echo "$i" >> "$BRIEFS/0001-alpha/brief.md"
    gather_commit "2026-01-01T00:00:0$i" "work #0001 iter $i"
  done
  run_gather
  assert_status 0
  assert_not_contains "older commits omitted" "$OUT"
}

# Over the ceiling the digest silently dropped commits, and a chronicle written
# from it would be a history missing events with nothing to say they were missing.
test_gather_names_the_total_when_it_truncates_the_commit_list() {
  gather_repo
  gather_brief "0001-alpha"
  local i
  for i in $(seq 1 65); do
    echo "$i" >> "$BRIEFS/0001-alpha/brief.md"
    gather_commit "2026-01-01T00:00:00" "work #0001 iter $i"
  done
  run_gather
  assert_status 0
  assert_out "older commits omitted"
  local shown
  shown=$(sed -n '/## Commits referencing/,$p' "$OUT" | grep -c ' · ')
  [ "$shown" -eq 60 ] || fail "expected 60 commit lines under the cap, got $shown"
}

# ── Refusals ─────────────────────────────────────────────────────────────────
#
# Both refusals must be loud. This script's failure mode is a quiet stop, so a
# refusal that said nothing would be indistinguishable from the bug.

test_gather_refuses_outside_a_git_repository() {
  REPO="$TMP/plain"
  mkdir -p "$REPO/docs/briefs"
  run_gather
  [ "$LAST_STATUS" -ne 0 ] || fail "expected a non-zero status outside a git repo"
  assert_err "Not inside a git repo."
}

test_gather_refuses_without_a_briefs_directory() {
  REPO="$TMP/norepo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q -b main
  run_gather
  [ "$LAST_STATUS" -ne 0 ] || fail "expected a non-zero status with no docs/briefs"
  assert_err "No docs/briefs"
}

# ── Self-check ───────────────────────────────────────────────────────────────
#
# The fixtures above are all synthetic. This one runs the script against the
# repository it ships in, which is the only case where the digest's claims are
# checkable against a history someone actually lived.
test_gather_runs_clean_against_this_repository() {
  REPO="$REPO_ROOT"
  run_gather
  assert_status 0
  assert_out "## Commits referencing a brief serial"
  local briefs
  briefs=$(grep -cE '^- [0-9]{4}-' "$OUT")
  [ "$briefs" -ge 4 ] || fail "expected at least 4 briefs in this repo's digest, got $briefs"
}
