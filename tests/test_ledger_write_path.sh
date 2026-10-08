# Where the ledger gets written — the rule #0013 found stated in two places and silently
# contradicted by a third.
#
# The rule: the ledger reaches `main` directly only at initiation, committed and pushed before
# any branch is cut. After that it evolves on the phase branch and returns by merge. The last
# phase has no successor, so `brief/<serial>-closeout` carries the close.
#
# Nothing here can check that a person followed the rule — the same ceiling every skill guard
# has, and docs/blc/briefs/README.md says so under Known limitations. These assert the instruction
# is present and says the right thing, which is the part that is checkable. The instruction was
# wrong for six weeks precisely because nothing looked at it.

WP_START() { printf '%s' "$REPO_ROOT/skills/blc-start-brief/SKILL.md"; }
WP_NEXT()  { printf '%s' "$REPO_ROOT/skills/blc-next-brief-phase/SKILL.md"; }
WP_README(){ printf '%s' "$REPO_ROOT/docs/blc/briefs/README.md"; }

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

WP_CLOSE() { printf '%s' "$REPO_ROOT/skills/blc-close-brief/SKILL.md"; }

# The close rides the reserved branch, not a phase branch. A closeout written onto the last
# phase's branch goes nowhere: that branch is already merged and is no longer a path to main.
test_ledger_write_path_close_brief_uses_the_reserved_branch() {
  assert_contains 'brief/<serial>-closeout' "$(WP_CLOSE)"
  assert_contains "no successor" "$(WP_CLOSE)"
}

# The contract between the skill and the clause, asserted from both ends.
#
# BRIEFS-11 reads a `**Closed:**` line; this skill is what writes one. Neither half is wrong
# on its own if the field name moves — the clause would stop finding it and the skill would
# go on writing it, and the gate would report every closed brief while every closed brief
# looked correct. The failure would be a clause that fires on nothing but its own fixtures.
test_ledger_write_path_close_brief_writes_what_briefs11_reads() {
  assert_contains '**Closed:**' "$(WP_CLOSE)"
  assert_contains "BRIEFS-11" "$(WP_CLOSE)"
  # The far end: the scan that BRIEFS-11 reads still looks for this field.
  grep -q 'is_closed(l).*Closed:' "$REPO_ROOT/tools/lib/status-line.sh" \
    || fail "the shared scan no longer looks for a **Closed:** line; this contract moved"
}

# The date is written by a person, not derived. A date taken from a merge commit is when a
# branch landed, which is not when anyone closed the brief — the record would assert
# something nobody said, and nothing downstream could tell the two apart.
test_ledger_write_path_close_brief_refuses_a_derived_date() {
  assert_contains "Do not derive it from a merge commit" "$(WP_CLOSE)"
}

# A brief with an unfinished phase is not closed, it is abandoned. The skill has to send
# that case to blc-next-brief-phase rather than stamp a date on it.
test_ledger_write_path_close_brief_refuses_an_unfinished_brief() {
  assert_contains "blc-next-brief-phase" "$(WP_CLOSE)"
  grep -q 'pending.*in-progress.*stop and name it\|stop and name it' "$(WP_CLOSE)" \
    || fail "blc-close-brief does not refuse a brief with an unfinished phase"
}
