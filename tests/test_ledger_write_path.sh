# Where the ledger gets written — the rule #0013 found stated in two places and silently
# contradicted by a third.
#
# The rule: the ledger reaches `main` directly only at initiation, committed and pushed before
# any branch is cut. After that it evolves on the phase branch and returns by merge. The last
# phase has no successor, so `brief/<serial>-closeout` carries the close.
#
# Nothing here can check that a person followed the rule — the same ceiling every skill guard
# has, and docs/briefs/README.md says so under Known limitations. These assert the instruction
# is present and says the right thing, which is the part that is checkable. The instruction was
# wrong for six weeks precisely because nothing looked at it.

WP_START() { printf '%s' "$REPO_ROOT/skills/blc-start-brief/SKILL.md"; }
WP_NEXT()  { printf '%s' "$REPO_ROOT/skills/blc-next-brief-phase/SKILL.md"; }
WP_README(){ printf '%s' "$REPO_ROOT/docs/briefs/README.md"; }

# A commit that never leaves the machine does not put the ledger on another machine. The
# instruction named that purpose while asking for an action that cannot achieve it.
test_ledger_write_path_start_brief_says_push_not_only_commit() {
  assert_contains "Commit **and push** this file to \`main\`" "$(WP_START)"
}

test_ledger_write_path_start_brief_names_itself_the_only_direct_write() {
  assert_contains "only ledger write that goes straight to \`main\`" "$(WP_START)"
}

# Writing to the branch is correct. Read alone, with no reason given, it reads as a
# contradiction of blc-start-brief — which is how it got reported as a defect.
test_ledger_write_path_next_phase_gives_the_reason_for_the_branch() {
  assert_contains "returns to \`main\` by merge" "$(WP_NEXT)"
}

test_ledger_write_path_next_phase_names_the_closeout_carrier() {
  assert_contains "brief/<serial>-closeout\` carries the brief's close" "$(WP_NEXT)"
}

# The README is where a reader goes for the convention, so it carries the whole rule and not
# only the half that applies at initiation.
test_ledger_write_path_readme_states_push_and_the_merge_path() {
  assert_contains "commits **and pushes** that file to \`main\`" "$(WP_README)"
  assert_contains "only ledger write that goes straight to \`main\`" "$(WP_README)"
}

test_ledger_write_path_readme_says_what_the_closeout_branch_is_for() {
  assert_contains "It carries the brief's close" "$(WP_README)"
}
