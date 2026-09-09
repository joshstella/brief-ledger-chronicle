# tools/orient.sh — rung 0, from #0008d.
#
# The brief's argument for making orientation a script rather than a document was
# precisely that a script can be asserted: "This is a script, so unlike a skill it
# can actually be asserted." This file is that claim being cashed.
#
# Two of these tests are canaries rather than checks. The budget test measures this
# repository's real output, so it fails when the record outgrows the budget — which
# is the entire thesis of #0008 failing, and should be loud. The cap test does the
# same for the one authored file. Neither is a fixture; both are meant to break one
# day and mean something when they do.

ORIENT() { printf '%s' "$REPO_ROOT/tools/orient.sh"; }

run_orient() {
  ( cd "$REPO" && bash "$(ORIENT)" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# A project as the installer leaves it: the two tools orient depends on, and a git
# repo to read refs from. Everything else is added per-test, because the point of
# most of these is what happens when a source is missing.
orient_repo() {
  REPO="$TMP/repo"
  mkdir -p "$REPO/tools"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
  cp "$REPO_ROOT/tools/list-briefs.sh" "$REPO/tools/"
  chmod +x "$REPO/tools/list-briefs.sh"
  echo x > "$REPO/f"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm root >/dev/null 2>&1
}

# usage: orient_brief <folder> <title> [status-line]
orient_brief() {
  local folder="$1" title="$2" status="${3:-}"
  mkdir -p "$REPO/docs/briefs/$folder"
  printf '# %s\n' "$title" > "$REPO/docs/briefs/$folder/brief.md"
  [ -n "$status" ] && printf '# Ledger\n%s\n' "$status" > "$REPO/docs/briefs/$folder/ledger.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "add $folder" >/dev/null 2>&1
}

orient_declaration() {
  mkdir -p "$REPO/docs/state"
  printf '# %s\n\n## 2026-09-09 — %s\n' "$1" "$2" > "$REPO/docs/state/$1.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "declare $1" >/dev/null 2>&1
}

tokens_of() { python3 -c "import sys;print(round(len(open(sys.argv[1]).read())/4))" "$1"; }

# ── The two canaries ─────────────────────────────────────────────────────────

# Measured against this repository, not a fixture. #0008's premise is that rung 0
# stays cheap as the record grows; if this fails, the premise has failed and the
# filtering rule needs redesigning, not the number raising.
test_orient_stays_under_the_budget_in_this_repo() {
  ( cd "$REPO_ROOT" && bash "$(ORIENT)" ) >"$OUT" 2>"$ERR"
  [ $? -eq 0 ] || fail "orient failed in this repo: $(head -1 "$ERR")"
  local t; t="$(tokens_of "$OUT")"
  [ "$t" -le 700 ] || fail "orient emits $t tokens, over the 700 budget"
}

# A cap governs quantity, and quantity is the only thing about the authored file
# that can be checked. Nothing here says the principles are the right ones.
test_orient_authored_file_stays_under_its_cap() {
  local t; t="$(tokens_of "$REPO_ROOT/docs/orientation.md")"
  [ "$t" -le 250 ] || fail "docs/orientation.md is $t tokens, over the 250 cap"
}

# ── Determinism ──────────────────────────────────────────────────────────────

test_orient_two_runs_produce_identical_output() {
  orient_repo
  orient_brief 0001-thing "The thing" '`blc/2 #0001 in-progress a:in-progress`'
  orient_declaration someone@example.com "claiming #0002"
  run_orient
  cp "$OUT" "$TMP/first"
  run_orient
  diff -q "$TMP/first" "$OUT" >/dev/null || fail "two runs of orient differ"
}

# ── Degradation: every part absent ───────────────────────────────────────────

test_orient_runs_clean_in_a_repo_with_nothing() {
  orient_repo
  run_orient
  assert_status 0
  assert_out "nothing filed here yet"
  assert_out "Nobody has declared unfiled work"
  assert_out "not set up by the installer"
  assert_out "nobody has written down what matters"
}

test_orient_runs_clean_with_an_empty_briefs_directory() {
  orient_repo
  mkdir -p "$REPO/docs/briefs"
  run_orient
  assert_status 0
  assert_out "Nothing open."
}

test_orient_survives_a_missing_state_directory() {
  orient_repo
  orient_brief 0001-thing "The thing"
  run_orient
  assert_status 0
  assert_out "Nobody has declared unfiled work"
}

test_orient_refuses_outside_a_git_repo() {
  REPO="$TMP/notgit"
  mkdir -p "$REPO"
  run_orient
  [ "$LAST_STATUS" -ne 0 ] || fail "expected non-zero outside a git repo"
  assert_err "Not inside a git repo"
}

# ── The filtering rule (decision 8) ──────────────────────────────────────────

test_orient_shows_open_briefs() {
  orient_repo
  orient_brief 0001-open "Open thing" '`blc/2 #0001 in-progress a:in-progress`'
  run_orient
  assert_status 0
  assert_out "Open thing"
}

# The whole reason rung 0 stays flat. A done brief costs nothing here; it lives in
# the chronicle, which #0006 settled keeps the complete table.
test_orient_hides_done_briefs() {
  orient_repo
  orient_brief 0001-done "Finished thing" '`blc/2 #0001 done a:done`'
  run_orient
  assert_status 0
  assert_not_contains "Finished thing" "$OUT"
}

# Hiding without counting would be a table that silently stops. The count is what
# tells a reader history exists and where it is.
test_orient_counts_the_briefs_it_hides() {
  orient_repo
  orient_brief 0001-done "Finished thing"  '`blc/2 #0001 done a:done`'
  orient_brief 0002-also "Also finished"   '`blc/2 #0002 done a:done`'
  run_orient
  assert_status 0
  assert_out "2 closed"
  assert_out "chronicle.md"
}

test_orient_treats_a_brief_with_no_ledger_as_in_flight() {
  orient_repo
  orient_brief 0001-filed "Filed but unstarted"
  run_orient
  assert_status 0
  assert_out "Filed but unstarted"
}

# The property that makes the whole design hold: cost bounded by open work, not by
# history. Twenty closed briefs must not cost more than two.
test_orient_cost_does_not_grow_with_closed_briefs() {
  orient_repo
  local i small large
  for i in 1 2; do orient_brief "000$i-done" "Done $i" '`blc/2 #0001 done a:done`'; done
  run_orient
  small="$(tokens_of "$OUT")"
  for i in 3 4 5 6 7 8 9; do orient_brief "000$i-done" "Done $i" '`blc/2 #0001 done a:done`'; done
  run_orient
  large="$(tokens_of "$OUT")"
  [ $((large - small)) -le 10 ] \
    || fail "output grew $((large - small)) tokens over seven closed briefs"
}

# ── Declarations ─────────────────────────────────────────────────────────────

test_orient_reports_a_declaration_with_its_author_and_age() {
  orient_repo
  orient_declaration someone@example.com "claiming #0002"
  run_orient
  assert_status 0
  assert_out "someone@example.com"
  assert_out "claiming #0002"
  assert_out "last written"
}

test_orient_ignores_the_state_readme() {
  orient_repo
  mkdir -p "$REPO/docs/state"
  printf '# Declarations\n\n## Not a declaration\n' > "$REPO/docs/state/README.md"
  git -C "$REPO" add -A && git -C "$REPO" commit -qm readme >/dev/null 2>&1
  run_orient
  assert_status 0
  assert_out "Nobody has declared unfiled work"
}

# Clearing a declaration is emptying the file. An empty one is the steady state for
# someone with nothing unfiled, and must not be reported as in-flight work.
test_orient_ignores_an_emptied_declaration() {
  orient_repo
  mkdir -p "$REPO/docs/state"
  : > "$REPO/docs/state/someone@example.com.md"
  run_orient
  assert_status 0
  assert_out "Nobody has declared unfiled work"
}

test_orient_reports_two_contributors_separately() {
  orient_repo
  orient_declaration one@example.com "picked up the parser"
  orient_declaration two@example.com "claiming #0003"
  run_orient
  assert_status 0
  assert_out "one@example.com"
  assert_out "two@example.com"
}

# ── Off-limits, derived from the install log ─────────────────────────────────

test_orient_derives_off_limits_from_the_install_log() {
  orient_repo
  mkdir -p "$REPO/docs/install-log"
  cat > "$REPO/docs/install-log/install-log.md" <<'LOG'
# Install log

## 2026-09-09T00:00:00Z — HOST

### Created

  - docs/briefs
  - tools
LOG
  git -C "$REPO" add -A && git -C "$REPO" commit -qm log >/dev/null 2>&1
  run_orient
  assert_status 0
  assert_out "docs/briefs"
  assert_out "tools"
}

# The log records what an install wrote, not who owns it. AGENTS.md is created once
# and then belongs to the project, so orient must not tell a reader to keep off it.
test_orient_does_not_claim_ownership_the_log_does_not_record() {
  orient_repo
  mkdir -p "$REPO/docs/install-log"
  cat > "$REPO/docs/install-log/install-log.md" <<'LOG'
# Install log

### Created

  - AGENTS.md
LOG
  git -C "$REPO" add -A && git -C "$REPO" commit -qm log >/dev/null 2>&1
  run_orient
  assert_status 0
  assert_not_contains "upstream owns" "$OUT"
}

# The log lists a scaffolded directory and the files placed inside it. Naming both
# spends tokens to say one thing.
test_orient_collapses_a_child_under_its_logged_parent() {
  orient_repo
  mkdir -p "$REPO/docs/install-log"
  cat > "$REPO/docs/install-log/install-log.md" <<'LOG'
# Install log

### Created

  - tools
  - tools/open-briefs.sh
LOG
  git -C "$REPO" add -A && git -C "$REPO" commit -qm log >/dev/null 2>&1
  run_orient
  assert_status 0
  assert_not_contains "tools/open-briefs.sh" "$OUT"
}

# ── Staleness ────────────────────────────────────────────────────────────────

# Everything orient prints is derived from local refs, so on a stale clone it is
# confidently wrong. #0003 has the case on the record: merged PRs and deleted
# branches invisible to a second machine until it fetched.
test_orient_warns_when_the_checkout_is_behind_its_upstream() {
  local origin="$TMP/origin"
  git init -q --bare -b main "$origin"
  orient_repo
  git -C "$REPO" remote add origin "$origin"
  git -C "$REPO" push -q -u origin main

  # A second clone lands a commit, so the first is behind once it fetches.
  git clone -q "$origin" "$TMP/other"
  git -C "$TMP/other" config user.email o@example.com
  git -C "$TMP/other" config user.name Other
  echo y > "$TMP/other/g"
  git -C "$TMP/other" add -A
  git -C "$TMP/other" commit -qm second >/dev/null 2>&1
  git -C "$TMP/other" push -q origin main

  git -C "$REPO" fetch -q origin
  run_orient
  assert_status 0
  assert_out "1 behind"
  assert_out "fetch before trusting this"
}

test_orient_says_so_when_there_is_no_upstream() {
  orient_repo
  run_orient
  assert_status 0
  assert_out "no upstream"
}

# ── It writes nothing ────────────────────────────────────────────────────────

# "Not a committed artifact. If it ends up committed, the design has failed."
test_orient_leaves_the_repository_untouched() {
  orient_repo
  orient_brief 0001-thing "The thing"
  run_orient
  assert_status 0
  local dirty
  dirty="$(git -C "$REPO" status --porcelain)"
  [ -z "$dirty" ] || fail "orient dirtied the repo: $dirty"
}

# ── It ships ─────────────────────────────────────────────────────────────────

test_orient_installs_with_its_skill() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/tools/orient.sh"
  assert_file "$TARGET/.cursor/skills/blc-orient/SKILL.md"
  [ -x "$TARGET/tools/orient.sh" ] || fail "installed orient.sh is not executable"
}

# orient.sh is what blc-orient runs. A target with the skill and not the tool has a
# skill whose only instruction fails — the failure list-briefs.sh was shipped to avoid.
test_orient_runs_inside_a_fresh_install() {
  git -C "$TARGET" init -q -b main
  git -C "$TARGET" config user.email t@example.com
  git -C "$TARGET" config user.name Test
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  ( cd "$TARGET" && bash tools/orient.sh ) >"$OUT" 2>"$ERR"
  [ $? -eq 0 ] || fail "orient failed in a fresh install: $(head -1 "$ERR")"
  assert_out "# Orientation"
}

# The authored file is the one part of orient's output that is not derived, and it is
# a statement about *this* project. Shipping this repo's copy would install our
# principles into someone else's repository. A target authors its own, and orient's
# absence message is what asks for it.
test_orient_authored_file_does_not_ship_to_a_target() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_no_file "$TARGET/docs/orientation.md"
}

# ── The wiring (phase e) ─────────────────────────────────────────────────────
#
# Phase e is skill guards, and "a skill guard is not a check" — nothing can force an
# agent to run the command. But whether the instruction is *present* is mechanical,
# and that is the half worth pinning: a verb nothing points at is exactly as useless
# as a document nothing reads, and a rename could quietly sever the wiring in files
# no other test reads.

test_orient_is_named_by_the_three_orientation_steps() {
  local f
  for f in blc-start-brief blc-next-brief-phase blc-review-pr; do
    assert_contains "tools/orient.sh" "$REPO_ROOT/skills/$f/SKILL.md"
  done
}

# blc-create-brief is where a serial claim is cleared, and where a peer's claim is the
# only warning available for the half of the race docs/briefs/ cannot show.
test_orient_create_brief_knows_about_declarations() {
  assert_contains "docs/state" "$REPO_ROOT/skills/blc-create-brief/SKILL.md"
}

# The rules file is what a target's agents actually read, so the wiring has to
# survive installation, not just exist upstream.
test_orient_is_named_in_the_rules_a_target_receives() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_contains "tools/orient.sh" "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
  assert_contains "docs/state" "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
}

# The brief's Ground: three skills told an agent to read AGENTS.md, and in a fresh
# target that file said nothing about how to get oriented.
test_orient_is_named_in_the_stub_agents_file() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_contains "tools/orient.sh" "$TARGET/AGENTS.md"
}
