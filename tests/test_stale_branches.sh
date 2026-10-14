# tools/stale-branches.sh — the prover, from #0025a.
#
# The prefix is `test_stale_` and not `test_prune_`, because tests/test_prune.sh already
# covers pruning stale skills from the install log (#0012c) and the runner filters on the
# function-name prefix.
#
# Every test here is about one sentence the program must not say: "merged", for a branch no
# test proved. The brief exists because a weaker rule — a branch-name match against a merged
# pull request — passed three branches it had not proved, and the deletion came before anybody
# looked.

STALE() { printf '%s' "$REPO_ROOT/tools/stale-branches.sh"; }

# usage: run_stale [args...] — runs in $REPO, with the merged-PR list from $REPO/prs.tsv when
# that file exists, so no test reaches a forge.
run_stale() {
  local prs=""
  [ -f "$REPO/prs.tsv" ] && prs="$REPO/prs.tsv"
  ( cd "$REPO" && BLC_MERGED_PRS="$prs" bash "$(STALE)" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# A repository with a trunk and nothing else. No remote, so the local trunk is the only one.
stale_repo() {
  REPO="$TMP/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
  echo base > "$REPO/f"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm base
  : > "$REPO/prs.tsv"
}

# usage: stale_branch <name> <file> <content> — a branch with one commit the trunk lacks.
stale_branch() {
  git -C "$REPO" checkout -q -b "$1" main
  printf '%s\n' "$3" > "$REPO/$2"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "$1"
  git -C "$REPO" checkout -q main
}

tip_of() { git -C "$REPO" rev-parse "$1"; }

# usage: stale_squash_into_trunk <branch> — the merge this toolkit performs. The trunk gets
# the branch's content as one new commit, so the branch tip is not an ancestor of the trunk
# and never becomes one.
stale_squash_into_trunk() {
  git -C "$REPO" merge -q --squash "$1" >/dev/null 2>&1
  git -C "$REPO" commit -qm "squash $1"
}

# usage: stale_record_pr <sha> <base> — one line of what the forge would have returned.
stale_record_pr() { printf '%s\t%s\n' "$1" "$2" >> "$REPO/prs.tsv"; }

# ── The three tests the program runs ─────────────────────────────────────────

test_stale_proves_an_ancestor_branch() {
  stale_repo
  git -C "$REPO" branch behind main
  run_stale --tsv
  assert_status 0
  assert_out "stale	behind	ancestor"
}

# A squash merge is the whole reason the `pr` test exists: the content is in the trunk and the
# tip is not an ancestor of anything.
test_stale_proves_a_squash_merge_by_its_pull_request() {
  stale_repo
  stale_branch feature g one
  local tip; tip="$(tip_of feature)"
  stale_squash_into_trunk feature
  stale_record_pr "$tip" main
  run_stale --tsv
  assert_status 0
  assert_out "stale	feature	pr"
}

test_stale_proves_nothing_by_a_pull_request_the_tip_does_not_match() {
  stale_repo
  stale_branch feature g one
  local tip; tip="$(tip_of feature)"
  stale_squash_into_trunk feature
  stale_record_pr "$tip" main
  # One commit pushed after the pull request merged. The trunk does not have it, and the
  # recorded head no longer equals the tip. This is the 2026-10-05 case a branch-name match
  # passed.
  git -C "$REPO" checkout -q feature
  echo later > "$REPO/afterwards"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "after the merge"
  git -C "$REPO" checkout -q main
  run_stale --tsv
  assert_status 0
  assert_out "unproven	feature"
}

# A merged state proves a merge happened somewhere. The base has to be the trunk.
test_stale_rejects_a_pull_request_merged_into_another_base() {
  stale_repo
  stale_branch feature g one
  local tip; tip="$(tip_of feature)"
  stale_record_pr "$tip" release-1.x
  run_stale --tsv
  assert_status 0
  assert_out "unproven	feature"
  assert_not_contains "stale	feature" "$OUT"
}

# Content already in the trunk by some other route: no ancestry, no pull request, and merging
# it changes nothing.
test_stale_proves_a_branch_whose_merge_changes_no_tree() {
  stale_repo
  stale_branch feature g one
  stale_squash_into_trunk feature
  run_stale --tsv
  assert_status 0
  assert_out "stale	feature	tree"
}

test_stale_leaves_real_work_unproven() {
  stale_repo
  stale_branch wip w "work nobody has merged"
  run_stale --tsv
  assert_status 0
  # The tip is asserted, not just the status and the name. It was empty for every unproven
  # branch until the tab-collapse defect was found, and a shorter assertion passed throughout.
  assert_out "unproven	wip	-	$(tip_of wip)"
}

# ── What it says, and does not say ───────────────────────────────────────────

test_stale_never_calls_an_unproven_branch_merged() {
  stale_repo
  stale_branch wip w "work nobody has merged"
  run_stale
  assert_status 0
  assert_out "Not proven (1)"
  assert_not_contains "merged" "$OUT"
}

# The branch name alone would pass whatever the commit list did, since the name is printed
# either way. The commit subject is the thing only the listing can produce.
test_stale_lists_the_commits_an_unproven_branch_carries() {
  stale_repo
  git -C "$REPO" checkout -q -b wip main
  echo work > "$REPO/w"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "a subject no branch name carries"
  git -C "$REPO" checkout -q main
  run_stale
  assert_status 0
  assert_out "a subject no branch name carries"
}

test_stale_writes_no_ref_and_deletes_nothing() {
  stale_repo
  stale_branch feature g one
  stale_squash_into_trunk feature
  local before; before="$(git -C "$REPO" for-each-ref --format='%(refname) %(objectname)')"
  run_stale
  assert_status 0
  local after; after="$(git -C "$REPO" for-each-ref --format='%(refname) %(objectname)')"
  [ "$before" = "$after" ] || fail "the prover changed a ref"
}

# A classification resting on two tests while claiming three is the quiet partial answer #0024
# was about. The absence is printed.
test_stale_says_when_the_pull_request_test_did_not_run() {
  stale_repo
  stale_branch wip w "work"
  rm -f "$REPO/prs.tsv"
  ( cd "$REPO" && bash "$(STALE)" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
  assert_status 0
  assert_out "The \`pr\` test did not run"
}

# ── Which trunk ──────────────────────────────────────────────────────────────
#
# Neither trunk is right alone. On 2026-10-06 an unpushed commit on local `main` made the
# first run of this program report a branch as carrying work the trunk already had.

# usage: stale_with_remote — a clone, so the repository has both trunks.
stale_with_remote() {
  stale_repo
  git -C "$REPO" checkout -q main
  CLONE="$TMP/clone"
  git clone -q "$REPO" "$CLONE"
  git -C "$CLONE" config user.email t@example.com
  git -C "$CLONE" config user.name Test
  REPO="$CLONE"
  : > "$REPO/prs.tsv"
}

test_stale_prefers_a_local_trunk_that_is_ahead_of_the_remote() {
  stale_with_remote
  echo more > "$REPO/unpushed"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "not pushed"
  git -C "$REPO" branch sidetrack main
  run_stale
  assert_status 0
  assert_out "trunk \`main\`"
  assert_out "not yet pushed"
}

# Equal trunks are each other's ancestor, so the local name is used and nothing is said about
# pushing. Either name would be correct; the local one is what the person has.
test_stale_says_nothing_about_pushing_when_the_trunks_agree() {
  stale_with_remote
  git -C "$REPO" branch sidetrack main
  run_stale
  assert_status 0
  assert_out "trunk \`main\`"
  assert_not_contains "not yet pushed" "$OUT"
}

# A local trunk behind the remote proves fewer branches than it should. The remote wins.
test_stale_uses_the_remote_trunk_when_the_local_one_is_behind() {
  stale_with_remote
  echo ahead > "$REPO/pushed"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "on the remote only"
  git -C "$REPO" update-ref refs/remotes/origin/main HEAD
  git -C "$REPO" update-ref refs/remotes/origin/HEAD refs/remotes/origin/main
  git -C "$REPO" reset -q --hard HEAD~1
  run_stale
  assert_status 0
  assert_out "trunk \`origin/main\`"
}

test_stale_keeps_the_remote_trunk_when_the_local_one_diverged() {
  stale_with_remote
  git -C "$REPO" reset -q --hard HEAD~0
  echo diverge > "$REPO/d"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm diverged
  # Rewrite the local trunk so it is neither ahead of nor behind the remote.
  git -C "$REPO" commit -q --amend -m "diverged, rewritten"
  git -C "$REPO" update-ref refs/remotes/origin/main "$(git -C "$REPO" rev-parse HEAD~1)"
  git -C "$REPO" update-ref refs/remotes/origin/HEAD refs/remotes/origin/main
  run_stale
  assert_status 0
  assert_out "trunk \`main\`"
}

# ── Deletion (#0025b) ────────────────────────────────────────────────────────
#
# The deletion is the only irreversible thing this toolkit does. It lives in a script rather
# than in a skill so that these assertions can exist at all: an instruction to an agent is a
# rule nothing checks, and that is the whole argument of decision 1.

saved_tip() { git -C "$REPO" rev-parse --verify --quiet "refs/blc/pruned/$1"; }

test_stale_deletes_a_proven_branch_and_keeps_its_tip() {
  stale_repo
  git -C "$REPO" branch behind main
  local tip; tip="$(tip_of behind)"
  run_stale --delete behind
  assert_status 0
  assert_out "deleted behind (ancestor)"
  git -C "$REPO" rev-parse --verify --quiet refs/heads/behind >/dev/null \
    && fail "the branch survived the deletion"
  [ "$(saved_tip behind)" = "$tip" ] || fail "the tip was not kept at refs/blc/pruned/behind"
}

test_stale_refuses_to_delete_an_unproven_branch() {
  stale_repo
  stale_branch wip w "work nobody has merged"
  run_stale --delete wip
  [ "$LAST_STATUS" -eq 0 ] && fail "refusing a branch must not exit 0"
  assert_err "refused wip: no test proves"
  git -C "$REPO" rev-parse --verify --quiet refs/heads/wip >/dev/null \
    || fail "a refused branch was deleted anyway"
  saved_tip wip >/dev/null && fail "a refused branch left a saved tip"
}

test_stale_refuses_to_delete_the_trunk() {
  stale_repo
  run_stale --delete main
  [ "$LAST_STATUS" -eq 0 ] && fail "deleting the trunk must not exit 0"
  assert_err "refused main: it is the trunk"
  git -C "$REPO" rev-parse --verify --quiet refs/heads/main >/dev/null || fail "the trunk went"
}

test_stale_refuses_to_delete_the_checked_out_branch() {
  stale_repo
  git -C "$REPO" checkout -q -b here main
  run_stale --delete here
  [ "$LAST_STATUS" -eq 0 ] && fail "deleting the checked-out branch must not exit 0"
  assert_err "refused here: it is checked out"
}

test_stale_refuses_a_branch_that_does_not_exist() {
  stale_repo
  run_stale --delete ghost
  [ "$LAST_STATUS" -eq 0 ] && fail "naming a missing branch must not exit 0"
  assert_err "refused ghost: no such branch"
}

# A bare --delete would make the dangerous reading the shortest one to type, and would act on a
# classification nobody had read.
test_stale_delete_needs_a_name() {
  stale_repo
  git -C "$REPO" branch behind main
  run_stale --delete
  [ "$LAST_STATUS" -eq 2 ] || fail "expected exit 2 for --delete with no names, got $LAST_STATUS"
  git -C "$REPO" rev-parse --verify --quiet refs/heads/behind >/dev/null \
    || fail "a bare --delete deleted a branch"
}

# Refusing one name must not stop the others. Each branch is its own decision.
test_stale_deletes_what_it_can_and_refuses_the_rest() {
  stale_repo
  git -C "$REPO" branch behind main
  stale_branch wip w "work nobody has merged"
  run_stale --delete behind wip
  [ "$LAST_STATUS" -eq 0 ] && fail "a run with a refusal must not exit 0"
  assert_out "deleted behind"
  git -C "$REPO" rev-parse --verify --quiet refs/heads/wip >/dev/null \
    || fail "the unproven branch was deleted"
}

# The report and the deletion are two commands with a person between them. A branch can gain a
# commit in that gap, which is the 2026-10-05 case: a tip that no longer matches its merged
# pull request.
test_stale_reproves_a_branch_at_deletion_rather_than_trusting_the_report() {
  stale_repo
  stale_branch feature g one
  local tip; tip="$(tip_of feature)"
  stale_squash_into_trunk feature
  stale_record_pr "$tip" main
  run_stale --tsv
  assert_out "stale	feature	pr"
  git -C "$REPO" checkout -q feature
  echo later > "$REPO/afterwards"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "after the person read the report"
  git -C "$REPO" checkout -q main
  run_stale --delete feature
  [ "$LAST_STATUS" -eq 0 ] && fail "a branch that moved since the report was deleted"
  assert_err "refused feature: no test proves"
}

# A branch name can be pruned twice with a different tip each time. Overwriting would discard
# the only copy of the earlier one.
test_stale_keeps_both_tips_when_a_name_is_pruned_twice() {
  stale_repo
  git -C "$REPO" branch behind main
  local first; first="$(tip_of behind)"
  run_stale --delete behind
  assert_status 0
  echo second > "$REPO/s"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "a second base"
  git -C "$REPO" branch behind main
  local second; second="$(tip_of behind)"
  run_stale --delete behind
  assert_status 0
  [ "$(saved_tip behind)" = "$first" ] || fail "the first saved tip was overwritten"
  [ "$(saved_tip behind-2)" = "$second" ] || fail "the second tip was not kept beside it"
}

# ── When the two writes fail (#0036a) ────────────────────────────────────────
#
# The loop used to run `git update-ref` and `git branch -D` and then print a line asserting
# both had worked, without reading either exit status. These drive the failures rather than
# describing them, each with plain git and no shim, because a shim would prove the program
# handles a fake git rather than the one it runs under.

# usage: stale_block_git_dir — makes `branch -D` fail while `update-ref` still succeeds.
# `update-ref` locks under .git/refs/blc/pruned/, a subdirectory that stays writable;
# `branch -D` needs .git/packed-refs.lock in the top directory. A no-op for root.
stale_block_git_dir() {
  [ "$(id -u)" -eq 0 ] && return 1
  chmod a-w "$REPO/.git"
}
stale_unblock_git_dir() { chmod u+w "$REPO/.git"; }

# A tip that was never written must not be reported as kept, and the branch it belongs to must
# still be here. Produced by a directory/file ref conflict, which is a case the toolkit meets:
# a repository that pruned `feature` and later prunes `feature/x`.
test_stale_refuses_to_delete_when_the_tip_cannot_be_saved() {
  stale_repo
  git -C "$REPO" branch feature main
  run_stale --delete feature
  assert_status 0
  git -C "$REPO" branch feature/x main
  run_stale --delete feature/x
  [ "$LAST_STATUS" -eq 0 ] && fail "a tip that could not be saved must not exit 0"
  assert_err "refused feature/x: the tip could not be saved"
  git -C "$REPO" rev-parse --verify --quiet refs/heads/feature/x >/dev/null \
    || fail "the branch was deleted after its tip failed to save"
}

test_stale_does_not_claim_a_deletion_the_branch_survived() {
  stale_repo
  git -C "$REPO" branch behind main
  stale_block_git_dir || { skip "running as root, so a read-only .git is not read-only"; return; }
  run_stale --delete behind
  stale_unblock_git_dir
  [ "$LAST_STATUS" -eq 0 ] && fail "a deletion that did not happen must not exit 0"
  assert_err "failed behind: the branch is still here"
  git -C "$REPO" rev-parse --verify --quiet refs/heads/behind >/dev/null \
    || fail "the branch went after branch -D reported failure"
  grep -q "deleted behind" "$OUT" && fail "the run said it deleted a branch that is still here"
}

# git removes branch.<name>.* on a successful deletion. A value in a file reached through
# `[include] path = …` is not in a file this repository owns, so it stays — and the line that
# says the deletion was clean is then wrong.
test_stale_reports_configuration_that_outlived_the_deletion() {
  stale_repo
  printf '[branch "behind"]\n\tdescription = from an included file\n' > "$REPO/.git/extra"
  git -C "$REPO" config include.path extra
  git -C "$REPO" branch behind main
  run_stale --delete behind
  [ "$LAST_STATUS" -eq 0 ] && fail "surviving configuration must not exit 0"
  assert_out "deleted behind (ancestor)"
  assert_out "1 \`branch.behind.*\` setting(s) outlived it"
  git -C "$REPO" rev-parse --verify --quiet refs/heads/behind >/dev/null \
    && fail "the branch survived a deletion the run reported"
}

# A `[branch "x"]` section in ~/.gitconfig belongs to the person, not to the branch that was
# deleted, and git was never going to remove it. Counting it would make a clean prune fail for
# anyone who keeps per-branch defaults there.
test_stale_ignores_a_global_setting_of_the_same_name() {
  stale_repo
  printf '[branch "behind"]\n\tremote = origin\n' > "$TMP/global-gitconfig"
  git -C "$REPO" branch behind main
  GIT_CONFIG_GLOBAL="$TMP/global-gitconfig" run_stale --delete behind
  assert_status 0
  grep -q "outlived it" "$OUT" && fail "a global setting was counted as surviving the deletion"
}

# The report must stay quiet when nothing survived, or every clean run carries a warning and
# the warning stops meaning anything.
test_stale_says_nothing_about_configuration_when_none_survived() {
  stale_repo
  git -C "$REPO" branch behind main
  git -C "$REPO" config branch.behind.description "removed with the branch"
  run_stale --delete behind
  assert_status 0
  grep -q "outlived it" "$OUT" && fail "a clean deletion reported surviving configuration"
}

test_stale_rejects_an_unknown_argument() {
  stale_repo
  run_stale --wipe
  [ "$LAST_STATUS" -eq 2 ] || fail "expected exit 2 for an unknown argument, got $LAST_STATUS"
}

# ── Asking the forge (#0036b) ────────────────────────────────────────────────
#
# Every test above hands the program a file through BLC_MERGED_PRS, which is read before the
# forge branch and short-circuits it. So the command that asks the forge, and the filter that
# shapes its answer, have never run under test. These reach them.

# usage: stale_with_forge — a repository whose remote has a host, and a PATH where `gh`
# answers and `glab` does not.
#
# Its own directory rather than the suite's shared $STUB_BIN. That one holds a `gh` that exits
# 0 for every invocation, which would satisfy `detect-forge.sh`, answer the query with nothing,
# and leave the program reporting a `pr` test that ran. A test built on it would assert a green
# forge path and prove none of it.
stale_with_forge() {
  stale_repo
  # BLC_MERGED_PRS is read first, so the fixture cannot leave a file for it.
  rm -f "$REPO/prs.tsv"
  # A URL with a host. The clone-based fixtures use a local path, which has no host, so
  # detect-forge.sh declines and the forge branch is never reached.
  git -C "$REPO" remote add origin https://forge.example.test/o/r.git
  FORGE_BIN="$TMP/forge-bin"
  FORGE_LOG="$TMP/gh-argv"
  FORGE_PRS="$TMP/gh-prs"
  mkdir -p "$FORGE_BIN"
  : > "$FORGE_LOG"
  : > "$FORGE_PRS"
  cat > "$FORGE_BIN/gh" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$FORGE_LOG"
case "\$1" in
  auth) exit 0 ;;
  pr)   cat "$FORGE_PRS" ;;
  *)    exit 1 ;;
esac
EOF
  # detect-forge.sh probes both CLIs on every call. Without a local `glab`, a machine that has
  # the real one makes a live round trip to a host that does not exist, on every run.
  printf '#!/bin/sh\nexit 1\n' > "$FORGE_BIN/glab"
  chmod +x "$FORGE_BIN/gh" "$FORGE_BIN/glab"
}

# usage: stale_forge_pr <tip-sha> <base> — one merged pull request the fake `gh` reports, in
# the two columns `--jq` builds from headRefOid and baseRefName.
stale_forge_pr() { printf '%s\t%s\n' "$1" "$2" >> "$FORGE_PRS"; }

# usage: run_stale_forge [args...] — BLC_MERGED_PRS unset, so the forge branch is reached.
run_stale_forge() {
  # $TMP is new for each test, so $FORGE_BIN left over from an earlier one names a directory
  # that is gone. Without this, a test that forgot the fixture would find the real `gh` and
  # make a live call to a forge from the suite.
  [ -x "${FORGE_BIN:-}/gh" ] || fail "run_stale_forge needs stale_with_forge first"
  ( cd "$REPO" && PATH="$FORGE_BIN:$PATH" bash "$(STALE)" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# The query is one bulk call, not one per branch, and it asks for the two fields the filter
# reads. A later phase adds the GitLab form of the same question; this pins the GitHub one.
test_stale_asks_the_forge_for_merged_pull_requests() {
  stale_with_forge
  run_stale_forge --tsv
  assert_status 0
  assert_contains "pr list --state merged --limit 500" "$FORGE_LOG"
  assert_contains "headRefOid,baseRefName" "$FORGE_LOG"
}

# The whole point of the `pr` test, now through the command that fetches it: a squash merge
# leaves the tip outside the trunk's ancestry, and only the forge knows it landed.
test_stale_proves_a_squash_merge_the_forge_reported() {
  stale_with_forge
  stale_branch feature g one
  local tip; tip="$(tip_of feature)"
  stale_squash_into_trunk feature
  stale_forge_pr "$tip" main
  run_stale_forge --tsv
  assert_status 0
  assert_out "stale	feature	pr"
}

# The second column has to be read as a column. A run that treated each line as one blob would
# pass the test above and fail here, because the tip still matches.
test_stale_reads_the_base_column_of_what_the_forge_returned() {
  stale_with_forge
  stale_branch feature g one
  local tip; tip="$(tip_of feature)"
  stale_forge_pr "$tip" release-1.x
  run_stale_forge --tsv
  assert_status 0
  assert_out "unproven	feature"
  assert_not_contains "stale	feature" "$OUT"
}

# A forge that is there and will not answer is not the same as no forge, and the program says
# which. Until now nothing reached the line that says it.
test_stale_says_when_the_forge_could_not_answer() {
  stale_with_forge
  printf '#!/bin/sh\ncase "$1" in auth) exit 0 ;; *) exit 1 ;; esac\n' > "$FORGE_BIN/gh"
  chmod +x "$FORGE_BIN/gh"
  stale_branch wip w work
  run_stale_forge
  assert_status 0
  assert_out "the forge is github and \`gh\` could not answer"
}

# ── The skill (#0025c) ───────────────────────────────────────────────────────
#
# These assert prose, which is the weakest thing in this file. They cannot show that an agent
# follows the skill — nothing can, which is the reason the classification and the deletion are
# both in the script. What they stop is the wiring rotting: a skill that stops naming its tool,
# or stops carrying the one instruction a reader cannot derive.

SKILL_MD="skills/blc-prune-stale-branches/SKILL.md"

test_stale_skill_names_the_script_it_drives() {
  assert_contains "tools/stale-branches.sh" "$REPO_ROOT/$SKILL_MD"
  assert_contains "stale-branches.sh --delete" "$REPO_ROOT/$SKILL_MD"
}

# The script makes no network call, so a trunk that is behind proves fewer branches than it
# should. Nothing in the script can tell the reader this; only the skill runs before it.
test_stale_skill_says_to_fetch_first() {
  assert_contains "git fetch" "$REPO_ROOT/$SKILL_MD"
}

# A refusal exits non-zero even when other branches were deleted, so the exit status cannot
# tell "nothing happened" from "three deleted, one refused". An agent that checks `$?` and
# stops would report the deletions as a failure.
test_stale_skill_warns_that_the_exit_code_is_not_the_result() {
  assert_contains "not the exit code" "$REPO_ROOT/$SKILL_MD"
}

# A deletion can now stop half-finished, and the three lines that say so are the only place a
# reader learns what each one costs them. The script cannot explain itself at that length.
test_stale_skill_says_what_a_half_finished_deletion_looks_like() {
  assert_contains "the tip could not be saved" "$REPO_ROOT/$SKILL_MD"
  assert_contains "the branch is still here" "$REPO_ROOT/$SKILL_MD"
  assert_contains "outlived it" "$REPO_ROOT/$SKILL_MD"
}

# Nothing removes the saved tips. A person should learn that from the run that creates them.
test_stale_skill_says_where_the_saved_tips_go() {
  assert_contains "refs/blc/pruned" "$REPO_ROOT/$SKILL_MD"
}

test_stale_skill_ships_to_a_cursor_target() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/.cursor/skills/blc-prune-stale-branches/SKILL.md"
  assert_file "$TARGET/tools/stale-branches.sh"
}

test_stale_skill_ships_to_a_claude_target() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/.claude/skills/blc-prune-stale-branches/SKILL.md"
  assert_file "$TARGET/tools/stale-branches.sh"
}
