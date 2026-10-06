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

test_stale_rejects_an_unknown_argument() {
  stale_repo
  run_stale --wipe
  [ "$LAST_STATUS" -eq 2 ] || fail "expected exit 2 for an unknown argument, got $LAST_STATUS"
}
