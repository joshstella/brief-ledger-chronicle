# The open-briefs query — tools/open-briefs.sh.
#
# Every finding the tool can emit gets a fixture that provokes it. A reporter run
# only against a healthy tree prints nothing and passes identically when each check
# is replaced by `:` — the negative fixtures are the test.
#
# This tool reports and never gates, so exit 0 is asserted even when findings fire.
# A test that let a finding fail the run would quietly turn the reporter into a
# gate, which is the thing docs/briefs/README.md says it must not become.
#
# The vocabulary is defined in docs/briefs/README.md and is not restated here.

QUERY() { printf '%s' "$REPO_ROOT/tools/open-briefs.sh"; }

# PATH without gh, so PR-state lookup takes its documented offline path. The runner
# puts an inert gh stub on PATH for the installer tests; letting it through here
# would make the assertions depend on a stub's silence.
run_query() {
  ( cd "$REPO" && PATH="/usr/bin:/bin" bash "$(QUERY)" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# A git repo with a trunk called main and one commit, so branch distances are real
# rather than mocked. The tool reads git; testing it against a fake would test the
# fake.
make_repo() {
  REPO="$TMP/repo"
  BRIEFS="$REPO/docs/briefs"
  mkdir -p "$BRIEFS/_drafts"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
  echo "# Briefs" > "$BRIEFS/README.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "root"
}

# usage: add_ledger <folder> <status-line> [phase-table-rows...]
add_ledger() {
  local folder="$1" line="$2"
  shift 2
  mkdir -p "$BRIEFS/$folder"
  {
    echo "# Ledger — ${folder#*-}"
    echo "$line"
    echo ""
    echo "| id | status | what |"
    echo "|---|---|---|"
    local row
    for row in "$@"; do echo "$row"; done
  } > "$BRIEFS/$folder/ledger.md"
  echo "# ${folder#*-}" > "$BRIEFS/$folder/brief.md"
}

commit_all() {
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "briefs" >/dev/null 2>&1
}

# usage: make_branch <name> [commits-to-add-to-main-after]
make_branch() {
  git -C "$REPO" branch "$1"
}

advance_main() {
  local n="$1" i
  for i in $(seq 1 "$n"); do
    echo "$i" >> "$REPO/churn.txt"
    git -C "$REPO" add -A
    git -C "$REPO" commit -qm "churn $i"
  done
}

# ── The quiet case ───────────────────────────────────────────────────────────

test_open_briefs_a_closed_tree_says_nothing_is_open() {
  make_repo
  add_ledger 0001-done '`blc/1 #0001 done(PR#1) 1:done(PR#1)`' \
    '| `phase 1 — a thing` | done (PR#1) | did it |'
  commit_all
  run_query docs/briefs
  assert_status 0
  assert_out "1 brief(s), 0 open phase(s), 0 not started, 0 drift, 0 untracked"
  assert_out "Nothing open."
}

# Silence and "no briefs at all" produce the same counts unless the brief count is
# asserted, so a tree with nothing in it must not read as a clean bill of health.
test_open_briefs_an_empty_tree_reports_no_briefs() {
  make_repo
  commit_all
  run_query docs/briefs
  assert_status 0
  assert_out "0 brief(s), 0 open phase(s)"
}

# ── Each finding, provoked ───────────────────────────────────────────────────

test_open_briefs_reports_an_in_progress_phase_with_its_branch() {
  make_repo
  add_ledger 0001-open '`blc/1 #0001 in-progress 1:in-progress(feature/x)`' \
    '| `phase 1 — a thing` | in-progress (`feature/x`) | doing it |'
  commit_all
  make_branch feature/x
  advance_main 3
  run_query docs/briefs
  assert_status 0
  assert_out "[in-progress] phase 1: feature/x"
  assert_out "3 commit(s) of main landed since"
  assert_out "no PR"
  assert_out "1 open phase(s)"
}

test_open_briefs_reports_a_deferred_phase_too() {
  make_repo
  add_ledger 0001-parked '`blc/1 #0001 in-progress 1:deferred(feature/parked)`' \
    '| `phase 1 — a thing` | deferred (`feature/parked`) | parked because reasons |'
  commit_all
  make_branch feature/parked
  advance_main 5
  run_query docs/briefs
  assert_status 0
  # Asserted apart rather than as one string: the finding label is padded to a
  # fixed column, so a literal match would be testing the column width.
  assert_out "[deferred]"
  assert_out "phase 1: feature/parked"
  assert_out "5 commit(s) of main landed since"
}

# The incident this tool exists for: a branch named in the ledger that no longer
# exists, leaving the record pointing at nothing.
test_open_briefs_reports_a_branch_that_does_not_exist() {
  make_repo
  add_ledger 0001-ghost '`blc/1 #0001 in-progress 1:in-progress(feature/deleted)`' \
    '| `phase 1 — a thing` | in-progress (`feature/deleted`) | gone |'
  commit_all
  run_query docs/briefs
  assert_status 0
  assert_out "branch 'feature/deleted' does not exist"
}

test_open_briefs_reports_an_open_phase_with_no_branch_recorded() {
  make_repo
  add_ledger 0001-bare '`blc/1 #0001 in-progress 1:in-progress`' \
    '| `phase 1 — a thing` | in-progress | no branch |'
  commit_all
  run_query docs/briefs
  assert_status 0
  assert_out "no branch recorded"
}

# The redundancy the status line buys has a price, and this is the check that makes
# it payable: a line that disagrees with the table is worse than no line, because a
# cheap scan trusts it.
test_open_briefs_reports_drift_between_line_and_table() {
  make_repo
  add_ledger 0001-drifted '`blc/1 #0001 in-progress 1:done(PR#1)`' \
    '| `phase 1 — a thing` | in-progress (`feature/y`) | says otherwise |'
  commit_all
  run_query docs/briefs
  assert_status 0
  assert_out "[drift]"
  assert_out "status line says 'done'"
}

test_open_briefs_reports_a_ledger_with_no_status_line() {
  make_repo
  add_ledger 0001-unlined 'Just some prose, not a status line.' \
    '| `phase 1 — a thing` | in-progress | unscannable |'
  commit_all
  run_query docs/briefs
  assert_status 0
  assert_out "[no-line]"
}

# A brief git has never seen reads clean on every branch measure precisely because
# it is least protected. Untracked has to be its own finding, not an absence of one.
test_open_briefs_reports_a_brief_that_is_not_in_git() {
  make_repo
  commit_all
  add_ledger 0001-untracked '`blc/1 #0001 in-progress 1:pending`' \
    '| `phase 1 — a thing` | pending | never committed |'
  run_query docs/briefs
  assert_status 0
  assert_out "[untracked]"
  assert_out "1 untracked"
}

# Filing and starting are separate acts. A brief that has been filed but not started
# has no ledger, and that is the state it is supposed to rest in until someone picks
# it up. It is reported so the wait is visible.
test_open_briefs_reports_a_filed_brief_as_not_started() {
  make_repo
  mkdir -p "$BRIEFS/0001-ledgerless"
  echo "# x" > "$BRIEFS/0001-ledgerless/brief.md"
  commit_all
  run_query docs/briefs
  assert_status 0
  assert_out "[not-started]"
  assert_out "1 not started"
}

# The bug this replaced: a filed brief was counted as an open phase, so a repo with
# nothing in flight reported work in flight.
test_open_briefs_does_not_count_a_not_started_brief_as_open() {
  make_repo
  mkdir -p "$BRIEFS/0001-ledgerless"
  echo "# x" > "$BRIEFS/0001-ledgerless/brief.md"
  commit_all
  run_query docs/briefs
  assert_status 0
  assert_out "0 open phase(s)"
  assert_out "Nothing open. 1 brief(s) filed and waiting"
}

# Not started is a resting state; invisible to git is not. A brief nobody else can
# see is not waiting to be picked up.
test_open_briefs_flags_a_not_started_brief_that_is_not_in_git() {
  make_repo
  commit_all
  mkdir -p "$BRIEFS/0001-ledgerless"
  echo "# x" > "$BRIEFS/0001-ledgerless/brief.md"
  run_query docs/briefs
  assert_status 0
  assert_out "[not-started]"
  assert_out "[untracked]"
  assert_out "1 untracked"
}

# ── Two index alphabets ──────────────────────────────────────────────────────
#
# blc/1 indexes phases by number, blc/2 by letter, and #0009 ruled that old lines
# are never rewritten. Both alphabets therefore have to resolve, and the drift
# scan has to find a row under either one. Both failures below are silent rather
# than loud, which is why each has a fixture: nothing else would notice them.

test_open_briefs_resolves_a_letter_index_from_a_blc2_line() {
  make_repo
  add_ledger 0001-letters '`blc/2 #0001 in-progress a:in-progress(feature/x)`' \
    '| `a — the thing` | in-progress (`feature/x`) | doing it |'
  commit_all
  make_branch feature/x
  advance_main 2
  run_query docs/briefs
  assert_status 0
  assert_out "[in-progress] phase a: feature/x"
  assert_out "2 commit(s) of main landed since"
}

# Before #0009 the drift scan looked for the literal word `phase a`, which a
# letter-indexed table never contains. The row was never found, and the guard on an
# empty row reports clean rather than erroring — so a ledger whose table contradicts
# its status line passed as healthy. That silence is the regression this pins.
test_open_briefs_reports_drift_on_a_letter_indexed_ledger() {
  make_repo
  add_ledger 0001-letters '`blc/2 #0001 in-progress a:in-progress(feature/x)`' \
    '| `a — the thing` | pending | the table and the line disagree |'
  commit_all
  make_branch feature/x
  run_query docs/briefs
  assert_status 0
  assert_out "[drift]"
  assert_out "phase a"
}

# The numeric scan is unanchored, so `phase N` is found wherever in the row it sits.
# No ledger in this repository needs that — every phase table here puts the id in the
# first cell — but an install target may lay its tables out differently, and this pins
# the latitude so a later tidy-up cannot quietly remove it.
test_open_briefs_reports_drift_when_a_numeric_id_is_not_in_the_first_cell() {
  make_repo
  add_ledger 0001-oldschema '`blc/1 #0001 in-progress 1:in-progress(feature/x)`' \
    '| `brief/0001-thing` | phase 1 of the thing | parked |'
  commit_all
  make_branch feature/x
  run_query docs/briefs
  assert_status 0
  assert_out "[drift]"
  assert_out "phase 1"
}

# ── It reports; it does not gate ─────────────────────────────────────────────

test_open_briefs_exits_zero_even_when_everything_is_wrong() {
  make_repo
  add_ledger 0001-bad '`blc/1 #0001 in-progress 1:in-progress(feature/gone)`' \
    '| `phase 1 — a thing` | deferred | drifted and dangling |'
  commit_all
  run_query docs/briefs
  assert_status 0
  assert_out "[drift]"
  assert_out "does not exist"
}

# ── Usage errors are still errors ────────────────────────────────────────────

test_open_briefs_errors_on_a_missing_directory() {
  make_repo
  commit_all
  run_query docs/nope
  assert_status 2
  assert_err "not a directory"
}

test_open_briefs_errors_outside_a_git_repository() {
  make_repo
  commit_all
  mkdir -p "$TMP/bare/docs/briefs"
  ( cd "$TMP/bare" && PATH="/usr/bin:/bin" bash "$(QUERY)" docs/briefs ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
  assert_status 2
  assert_err "not inside a git repository"
}

# ── This repo, against its own tool ──────────────────────────────────────────

test_open_briefs_this_repo_scans_without_crashing() {
  bash "$(QUERY)" "$REPO_ROOT/docs/briefs" >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
  assert_status 0
  assert_out "brief(s)"
  assert_not_contains "[no-line]" "$OUT"
  # Not asserted as absent: this repo carries filed-but-unstarted briefs, and that
  # is a healthy state. Asserted instead is that the count is always reported.
  assert_out "not started"
}
