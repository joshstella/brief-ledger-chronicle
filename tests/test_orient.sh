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
  fixture_install_tool "$REPO" list-briefs.sh
  echo x > "$REPO/f"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm root >/dev/null 2>&1
}

# usage: orient_brief <folder> <title> [status-line]
orient_brief() {
  local folder="$1" title="$2" status="${3:-}"
  mkdir -p "$REPO/docs/blc/briefs/$folder"
  printf '# %s\n' "$title" > "$REPO/docs/blc/briefs/$folder/brief.md"
  [ -n "$status" ] && printf '# Ledger\n%s\n' "$status" > "$REPO/docs/blc/briefs/$folder/ledger.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "add $folder" >/dev/null 2>&1
}

orient_declaration() {
  mkdir -p "$REPO/docs/blc/state"
  printf '# %s\n\n## 2026-09-09 — %s\n' "$1" "$2" > "$REPO/docs/blc/state/$1.md"
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
  local t; t="$(tokens_of "$REPO_ROOT/docs/blc/orientation.md")"
  [ "$t" -le 250 ] || fail "docs/blc/orientation.md is $t tokens, over the 250 cap"
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
  mkdir -p "$REPO/docs/blc/briefs"
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

# A declaration moved under docs/blc/ in a commit the ignore list names was last written
# when its author wrote it, not when it moved.
test_orient_dates_a_declaration_from_before_an_ignored_move() {
  orient_repo
  mkdir -p "$REPO/docs/state"
  printf '# someone@example.com\n\n## 2026-01-01 — claiming #0002\n' \
    > "$REPO/docs/state/someone@example.com.md"
  git -C "$REPO" add -A
  GIT_AUTHOR_DATE="2026-01-01T12:00:00-04:00" GIT_COMMITTER_DATE="2026-01-01T12:00:00-04:00" \
    git -C "$REPO" commit -qm "declare" >/dev/null 2>&1
  mkdir -p "$REPO/docs/blc"
  git -C "$REPO" mv docs/state docs/blc/state
  GIT_AUTHOR_DATE="2026-06-01T12:00:00-04:00" GIT_COMMITTER_DATE="2026-06-01T12:00:00-04:00" \
    git -C "$REPO" commit -qm "move" >/dev/null 2>&1
  git -C "$REPO" rev-parse HEAD > "$REPO/docs/blc/ignore-revs"
  run_orient
  assert_status 0
  assert_out "(last written 2026-01-01)"
}

test_orient_ignores_the_state_readme() {
  orient_repo
  mkdir -p "$REPO/docs/blc/state"
  printf '# Declarations\n\n## Not a declaration\n' > "$REPO/docs/blc/state/README.md"
  git -C "$REPO" add -A && git -C "$REPO" commit -qm readme >/dev/null 2>&1
  run_orient
  assert_status 0
  assert_out "Nobody has declared unfiled work"
}

# Clearing a declaration is emptying the file. An empty one is the steady state for
# someone with nothing unfiled, and must not be reported as in-flight work.
test_orient_ignores_an_emptied_declaration() {
  orient_repo
  mkdir -p "$REPO/docs/blc/state"
  : > "$REPO/docs/blc/state/someone@example.com.md"
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

# Two repositories have no install log: one nobody has installed into, and the toolkit's own
# checkout, which reaches its skills through committed links. Telling the second it "was not
# set up by the installer" reads as a missing step, and the installer refuses to run there.
test_orient_names_the_toolkit_source_instead_of_a_missing_install() {
  orient_repo
  mkdir -p "$REPO/skills/blc-orient" "$REPO/.cursor"
  ln -s ../skills "$REPO/.cursor/skills"
  run_orient
  assert_status 0
  assert_out "this is the toolkit source, not a target"
  assert_not_contains "was not set up by the installer" "$OUT"
}

# The same answer through Claude Code's shape: one link per skill, not one for the directory.
test_orient_names_the_toolkit_source_from_a_per_skill_link() {
  orient_repo
  mkdir -p "$REPO/skills/blc-orient" "$REPO/.claude/skills"
  ln -s ../../skills/blc-orient "$REPO/.claude/skills/blc-orient"
  run_orient
  assert_status 0
  assert_out "this is the toolkit source, not a target"
}

# A repository with no install and no links keeps the old answer. A link that leaves the
# repository is somebody else's checkout, not self-hosting.
test_orient_still_reports_a_repo_no_install_has_touched() {
  orient_repo
  mkdir -p "$REPO/.cursor" "$TMP/elsewhere/skills"
  ln -s "$TMP/elsewhere/skills" "$REPO/.cursor/skills"
  run_orient
  assert_status 0
  assert_out "was not set up by the installer"
  assert_not_contains "toolkit source" "$OUT"
}

# A checkout reached through a symlink. `git rev-parse --show-toplevel` resolves it and a
# followed link resolves too, so the comparison holds — but only against `$ROOT`. `$PWD` keeps
# the symlink the caller walked in through, and nothing would match.
test_orient_names_the_toolkit_source_through_a_symlinked_checkout() {
  orient_repo
  mkdir -p "$REPO/skills/blc-orient" "$REPO/.cursor"
  ln -s ../skills "$REPO/.cursor/skills"
  ln -s "$REPO" "$TMP/linked"
  ( cd "$TMP/linked" && bash "$(ORIENT)" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
  assert_status 0
  assert_out "this is the toolkit source, not a target"
}

# A target has a log, so it never reaches either message.
test_orient_prefers_the_install_log_over_the_source_message() {
  orient_repo
  mkdir -p "$REPO/skills/blc-orient" "$REPO/.cursor"
  ln -s ../skills "$REPO/.cursor/skills"
  orient_log <<'LOG'
# Install log

## 2026-09-09T00:00:00Z — HOST

### Created

  - tools
LOG
  run_orient
  assert_status 0
  assert_out "tools"
  assert_not_contains "toolkit source" "$OUT"
}

test_orient_derives_off_limits_from_the_install_log() {
  orient_repo
  mkdir -p "$REPO/docs/blc/install-log"
  cat > "$REPO/docs/blc/install-log/install-log.md" <<'LOG'
# Install log

## 2026-09-09T00:00:00Z — HOST

### Created

  - docs/blc/briefs
  - tools
LOG
  git -C "$REPO" add -A && git -C "$REPO" commit -qm log >/dev/null 2>&1
  run_orient
  assert_status 0
  assert_out "docs/blc/briefs"
  assert_out "tools"
}

# The log records what an install wrote, not who owns it. AGENTS.md is created once
# and then belongs to the project, so orient must not tell a reader to keep off it.
test_orient_does_not_claim_ownership_the_log_does_not_record() {
  orient_repo
  mkdir -p "$REPO/docs/blc/install-log"
  cat > "$REPO/docs/blc/install-log/install-log.md" <<'LOG'
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
  mkdir -p "$REPO/docs/blc/install-log"
  cat > "$REPO/docs/blc/install-log/install-log.md" <<'LOG'
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

# ── The whole log, replayed (#0021) ──────────────────────────────────────────
#
# Each run in the log has three sections that change what exists: Created, Removed, and
# Moved. Reading only Created told an adopting repository to keep off six pruned commands
# and two directories an upgrade had just moved. Every test above wrote only Created, so
# none of them could fail on that.

orient_log() {
  mkdir -p "$REPO/docs/blc/install-log"
  cat > "$REPO/docs/blc/install-log/install-log.md"
  git -C "$REPO" add -A && git -C "$REPO" commit -qm log >/dev/null 2>&1
}

test_orient_drops_a_path_a_later_run_removed() {
  orient_repo
  orient_log <<'LOG'
# Install log

## 2026-09-01T00:00:00Z — HOST

### Created

  - .claude/commands/blc-old.md
  - .claude/commands/blc-kept.md

## 2026-09-02T00:00:00Z — HOST

### Created

  (none)

### Removed

  - .claude/commands/blc-old.md
LOG
  run_orient
  assert_status 0
  assert_not_contains "blc-old.md" "$OUT"
  assert_out "blc-kept.md"
}

# The upgrade moves the project's files and drops the toolkit's old copies, then deletes
# each old tree. An old run listed the trees themselves, so they have to leave as trees.
test_orient_drops_the_old_trees_an_upgrade_moved() {
  orient_repo
  orient_log <<'LOG'
# Install log

## 2026-09-01T00:00:00Z — HOST

### Created

  - docs/contracts
  - docs/contracts/v1.md
  - docs/state
  - docs/install-log/install-log.md

## 2026-10-03T00:00:00Z — HOST

### Created

  - docs/blc/contracts
  - docs/blc/state

### Moved — old docs/ layout to docs/blc/

  - docs/state/me@example.org.md → docs/blc/state/me@example.org.md
  - docs/install-log/install-log.md → docs/blc/install-log/install-log.md (joined, old entries first)
  - docs/contracts/v1.md (old copy of a toolkit file — dropped)
LOG
  run_orient
  assert_status 0
  assert_not_contains "\`docs/contracts" "$OUT"
  assert_not_contains "\`docs/state" "$OUT"
  assert_not_contains "\`docs/install-log" "$OUT"
  assert_out "docs/blc/contracts"
  assert_out "docs/blc/state"
}

# A path an install wrote and an upgrade moved is still a path an install wrote, at its new
# place. The label after the arrow is the log's note, not part of the path.
test_orient_follows_a_logged_path_that_moved() {
  orient_repo
  orient_log <<'LOG'
# Install log

## 2026-09-01T00:00:00Z — HOST

### Created

  - docs/install-log/install-log.md

## 2026-10-03T00:00:00Z — HOST

### Moved — old docs/ layout to docs/blc/

  - docs/install-log/install-log.md → docs/blc/install-log/install-log.md (joined, old entries first)
LOG
  run_orient
  assert_status 0
  assert_out "- \`docs/blc/install-log/install-log.md\`"
  assert_not_contains "joined" "$OUT"
}

# Never the disk (decision 1). A path the install wrote and a person deleted by hand is the
# one a reader most needs to see.
test_orient_still_lists_a_logged_path_deleted_by_hand() {
  orient_repo
  orient_log <<'LOG'
# Install log

### Created

  - tools/gone-by-hand.sh
LOG
  run_orient
  assert_status 0
  assert_out "tools/gone-by-hand.sh"
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

# ── Against the trunk (#0021) ────────────────────────────────────────────────
#
# A branch's own upstream answers "is this branch current", which is not the question. The
# record the rest of the output reads lives on the trunk. Two cases are on the record: a
# pushed branch on a stale base read `0 behind / 0 ahead`, and a local branch with no upstream
# read "local-only view" while main was 43 commits behind. Both had a trunk that had moved.

# A clone of a bare origin, so `origin/HEAD` is set the way a real clone sets it, with the
# trunk then moved on by a second clone and fetched into the first.
orient_clone_with_moved_trunk() {
  local origin="$TMP/origin"
  git init -q --bare -b main "$origin"
  orient_repo
  git -C "$REPO" remote add origin "$origin"
  git -C "$REPO" push -q -u origin main
  rm -rf "$REPO"
  git clone -q "$origin" "$REPO"
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
  git clone -q "$origin" "$TMP/other"
  git -C "$TMP/other" config user.email o@example.com
  git -C "$TMP/other" config user.name Other
  echo y > "$TMP/other/g"
  git -C "$TMP/other" add -A
  git -C "$TMP/other" commit -qm second >/dev/null 2>&1
  git -C "$TMP/other" push -q origin main
}

test_orient_counts_a_pushed_branch_against_the_trunk() {
  orient_clone_with_moved_trunk
  git -C "$REPO" switch -q -c feature
  git -C "$REPO" push -q -u origin feature
  git -C "$REPO" fetch -q origin
  run_orient
  assert_status 0
  assert_out "0 behind / 0 ahead of \`origin/feature\`"
  assert_out "1 behind \`origin/main\`"
  assert_out "the record on \`origin/main\` is newer"
}

test_orient_counts_a_branch_with_no_upstream_against_the_trunk() {
  orient_clone_with_moved_trunk
  git -C "$REPO" switch -q -c local-only
  git -C "$REPO" fetch -q origin
  run_orient
  assert_status 0
  assert_out "no upstream"
  assert_out "1 behind \`origin/main\`"
  assert_out "the record on \`origin/main\` is newer"
}

# On the trunk itself the upstream count already is the trunk count. Printing both says one
# thing twice.
test_orient_does_not_repeat_the_trunk_on_the_trunk() {
  orient_clone_with_moved_trunk
  git -C "$REPO" fetch -q origin
  run_orient
  assert_status 0
  assert_out "1 behind / 0 ahead of \`origin/main\`"
  assert_not_contains "behind \`origin/main\` —" "$OUT"
}

# `git init` and a remote added later give no `origin/HEAD`. Say what is missing and how to set
# it, rather than print no trunk and let the reader assume there is nothing to compare.
test_orient_says_the_trunk_is_unknown_without_origin_head() {
  local origin="$TMP/origin"
  git init -q --bare -b main "$origin"
  orient_repo
  git -C "$REPO" remote add origin "$origin"
  git -C "$REPO" push -q origin main
  git -C "$REPO" switch -q -c feature
  run_orient
  assert_status 0
  assert_out "trunk unknown"
  assert_out "git remote set-head origin --auto"
}

# ── It writes nothing ────────────────────────────────────────────────────────

# "Not a committed artifact. If it ends up committed, the design has failed."
# The installer does not ship Manifesto.md. A footer that names it anyway sent an agent in an
# adopting repository looking for a file that was never there.
test_orient_footer_names_the_manifesto_only_when_it_exists() {
  orient_repo
  run_orient
  assert_status 0
  assert_out 'Deeper: `README.md` · `docs/blc/briefs/README.md`'
  assert_not_contains 'Manifesto.md' "$OUT"
  echo '# Manifesto' > "$REPO/Manifesto.md"
  run_orient
  assert_status 0
  assert_out 'Deeper: `README.md` · `Manifesto.md` · `docs/blc/briefs/README.md`'
}

test_orient_footer_names_the_manifesto_in_this_repo() {
  ( cd "$REPO_ROOT" && bash "$(ORIENT)" ) >"$OUT" 2>"$ERR"
  assert_out '· `Manifesto.md` ·'
}

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
  assert_no_file "$TARGET/docs/blc/orientation.md"
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
# only warning available for the half of the race docs/blc/briefs/ cannot show.
test_orient_create_brief_knows_about_declarations() {
  assert_contains "docs/blc/state" "$REPO_ROOT/skills/blc-create-brief/SKILL.md"
}

# The rules file is what a target's agents actually read, so the wiring has to
# survive installation, not just exist upstream.
test_orient_is_named_in_the_rules_a_target_receives() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_contains "tools/orient.sh" "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
  assert_contains "docs/blc/state" "$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
}

# The brief's Ground: three skills told an agent to read AGENTS.md, and in a fresh
# target that file said nothing about how to get oriented.
test_orient_is_named_in_the_stub_agents_file() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_contains "tools/orient.sh" "$TARGET/AGENTS.md"
}

# ── Where orient reads from (#0024) ──────────────────────────────────────────
#
# Orient found the repository root and then read every record path from the caller's
# directory. From a subdirectory it reported a filed record as absent and exited 0, so the
# reader had nothing to distrust. These assert the byte-identity that replaces that: one
# repository has one orientation, whatever directory the question is asked from.

# A fixture with a record worth missing — a brief, an install log and an authored file —
# so an absent-reading run differs from a correct one in all three sections.
orient_populated_repo() {
  orient_repo
  orient_brief 0001-a-thing "A thing" 'blc/2 #0001 in-progress a:in-progress(brief/0001-a-x)'
  mkdir -p "$REPO/docs/blc/install-log" "$REPO/sub/deeper"
  printf '# Install log\n\n## 2026-09-09T00:00:00Z — cursor\n\n### Created\n\n- `tools/orient.sh`\n' \
    > "$REPO/docs/blc/install-log/install-log.md"
  printf '# Orientation\n\nThe record is the work.\n' > "$REPO/docs/blc/orientation.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm populate >/dev/null 2>&1
}

test_orient_reads_the_same_record_from_a_subdirectory() {
  orient_populated_repo
  ( cd "$REPO" && bash "$(ORIENT)" ) >"$TMP/from-root" 2>"$ERR"
  ( cd "$REPO/sub/deeper" && bash "$(ORIENT)" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
  assert_status 0
  diff -u "$TMP/from-root" "$OUT" >/dev/null \
    || fail "orient from a subdirectory differs from orient at the root:
$(diff -u "$TMP/from-root" "$OUT" | head -20)"
}

# The identity test alone would pass if orient reported everything absent from both places.
# These name the three sections that were wrong, so the test cannot pass by being uniformly
# useless.
test_orient_from_a_subdirectory_finds_the_filed_record() {
  orient_populated_repo
  ( cd "$REPO/sub/deeper" && bash "$(ORIENT)" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
  assert_status 0
  assert_out "A thing"
  assert_not_contains "nothing filed here yet" "$OUT"
  assert_not_contains "was not set up by the installer" "$OUT"
  assert_not_contains "nobody has written down what matters here" "$OUT"
}

# An explicit path is the caller's, like any other shell tool's argument. The default is the
# root's. Absolutising both would have reintroduced the defect under a new name.
test_orient_resolves_an_explicit_path_against_the_caller() {
  orient_populated_repo
  ( cd "$REPO/sub/deeper" && bash "$(ORIENT)" ../../docs/blc/briefs ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
  assert_status 0
  assert_out "A thing"
}

test_orient_takes_an_absolute_path_from_a_subdirectory() {
  orient_populated_repo
  ( cd "$REPO/sub/deeper" && bash "$(ORIENT)" "$REPO/docs/blc/briefs" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
  assert_status 0
  assert_out "A thing"
}

# The Contract orient.sh reads must exist, and must be the one marked current.
#
# orient.sh names the Contract by path, in `CONTRACT=` and again in the line it prints. A
# version bump that misses either leaves orient reading a file that is not there, or quietly
# reporting a superseded version as the one that binds. #0033 cut v1.4 and listed the cost of
# a bump; the list was incomplete. #0034b then pointed `CONTRACT=` at a nonexistent v1.9 and
# all 684 tests stayed green, which is how this gap was measured rather than assumed.
#
# Both ends are read, so neither can drift alone: the path out of orient.sh, and the `current`
# row of the versions table. A test pinning one literal would need editing on every bump,
# which is the same hand-maintenance that caused the drift.
test_orient_reads_the_contract_version_that_is_current() {
  local named current
  named="$(sed -n 's|^CONTRACT="\$BLC_ROOT/contracts/\(v[0-9.]*\.md\)"$|\1|p' \
    "$REPO_ROOT/tools/orient.sh")"
  [ -n "$named" ] || { fail "could not read a contract path out of tools/orient.sh"; return 1; }

  assert_file "$REPO_ROOT/docs/blc/contracts/$named"

  # The table row whose status is exactly `current`, not one that merely mentions the word.
  # `#` as the delimiter, not `|`: every row of a markdown table is full of pipes.
  current="$(sed -n 's#^| \[v[0-9.]*\](\(v[0-9.]*\.md\)) |.*| current |$#\1#p' \
    "$REPO_ROOT/docs/blc/contracts/README.md")"
  [ -n "$current" ] \
    || { fail "no version is marked current in docs/blc/contracts/README.md"; return 1; }
  [ "$named" = "$current" ] \
    || fail "orient.sh reads $named, but $current is the version marked current"
}

# The line orient prints has to name the same version it reads. They are two literals in one
# file and a bump can move one.
test_orient_prints_the_contract_version_it_reads() {
  local named printed
  named="$(sed -n 's|^CONTRACT="\$BLC_ROOT/contracts/v\([0-9.]*\)\.md"$|\1|p' \
    "$REPO_ROOT/tools/orient.sh")"
  printed="$(sed -n 's|^.*echo "Contract v\([0-9.]*\) binds the briefs directory\..*$|\1|p' \
    "$REPO_ROOT/tools/orient.sh")"
  [ -n "$named" ] || { fail "could not read CONTRACT= out of tools/orient.sh"; return 1; }
  [ -n "$printed" ] || { fail "orient.sh no longer prints a Contract version"; return 1; }
  [ "$named" = "$printed" ] \
    || fail "orient.sh reads v$named and tells the reader v$printed"
}
