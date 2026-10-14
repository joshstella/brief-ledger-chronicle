#!/usr/bin/env bash
# tools/read-record.sh — the published read surface (#0039 phase b).
#
# The surface was a frozen instrument during the #0039 bake-off: no tests, nothing
# installed it, and it did not reach main. Phase b publishes it. Every test here names the
# instrument behaviour it replaces, because the point of the phase is not that the tool
# works — it did — but that four recorded faults and one inherited defect are now held
# shut by something that fails when they come back.
#
# Helpers are prefixed `RR_` / `rr_`. run.sh sources every test file into one shell, and an
# unprefixed helper is one collision away from being replaced by whichever file is read
# last. See "Helper names are shared across every test file" in tests/README.md.

RR_TOOL="tools/read-record.sh"

# A fixture repository: a real git repo, because the surface reads git for `touched`,
# `events` and the identity. Briefs are passed in as ledger lines so each test states the
# record it is asking about.
rr_repo() {
  RR_DIR="$TMP/readrec/$1"
  rm -rf "$RR_DIR"
  mkdir -p "$RR_DIR/docs/blc/briefs" "$RR_DIR/docs/blc/state"
  git -C "$RR_DIR" init -q
  git -C "$RR_DIR" config user.email "t@e.com"
  git -C "$RR_DIR" config user.name "T E"
}

# usage: rr_brief <serial> <slug> [-- <ledger lines...>]
# Writes a brief.md satisfying BRIEFS-1..7 so nothing reported is incidental.
rr_brief() {
  local serial="$1" slug="$2"; shift 2
  [ "${1:-}" = "--" ] && shift
  local d="$RR_DIR/docs/blc/briefs/$serial-$slug"
  mkdir -p "$d"
  printf '# Brief %s\n\n**Serial:** #%s · **Created:** 2026-01-01T00:00:00Z · **Author:** t@e.com · **Depends on:** —\n' \
    "$slug" "$serial" > "$d/brief.md"
  [ "$#" -eq 0 ] || printf '%s\n' "$@" > "$d/ledger.md"
}

rr_commit() {
  git -C "$RR_DIR" add -A
  git -C "$RR_DIR" commit -q -m "${1:-fixture}" --no-verify 2>/dev/null \
    || git -C "$RR_DIR" commit -q -m "${1:-fixture}"
}

# Run the tool against the fixture. The tool is the repository's own, not a copy: the
# fixture supplies records, never code.
#
# RR_OUT and RR_ERR are PATHS, not strings. assert_contains greps a file, and the suite's
# own $OUT/$ERR are files for the same reason — passing a string lands it in grep's
# filename slot, where every assertion fails with the text it was looking for printed in
# the message. That is how this file was first written.
rr_run() {
  RR_OUT="$TMP/rr.out"; RR_ERR="$TMP/rr.err"
  ( cd "$RR_DIR" && BLC_READ_ROOT="$RR_DIR" bash "$REPO_ROOT/$RR_TOOL" "$@" ) \
    >"$RR_OUT" 2>"$RR_ERR"
  RR_RC=$?
}

# Pull one brief's object out of the `briefs` array. Splitting on `},{"serial"` keeps each
# object whole, which a line-based grep over one long line cannot do.
rr_brief_obj() {
  sed 's/},{"serial"/}\n{"serial"/g' "$RR_OUT" | grep "\"serial\":\"$1\""
}

# Count JSON keys in the output, one per line after splitting on commas.
rr_count_key() {
  tr ',' '\n' < "$RR_OUT" | grep -c "\"$1\"" || true
}

rr_assert_field() {
  local obj field want
  obj="$(rr_brief_obj "$1")"; field="$2"; want="$3"
  case "$obj" in
    *"\"$field\":$want"*) ;;
    *) fail "brief $1: expected $field to be $want, got: ${obj:0:400}" ;;
  esac
}

# ── One reader, not a sixth ──────────────────────────────────────────────────
# The surface exists so every console reads one answer. A copy of the tokenizer pasted in
# here would pass every behavioural test below and reintroduce the defect #0013 was filed
# about, so the tree is asserted before the behaviour — the same move test_phase_row.sh
# makes for the same reason.

test_read_record_sources_the_shared_readers() {
  grep -q 'lib/status-line\.sh' "$REPO_ROOT/$RR_TOOL" \
    || fail "$RR_TOOL does not source the shared status-line reader"
  grep -q 'lib/phase-row\.sh' "$REPO_ROOT/$RR_TOOL" \
    || fail "$RR_TOOL does not source the shared phase-row reader"
}

test_read_record_does_not_redefine_the_shared_readers() {
  # Defining either name locally would shadow the sourced one and the tool would read the
  # record its own way while still appearing to share.
  local f
  for f in blc_status_line blc_status_state blc_status_phase_entries; do
    grep -qE "^[[:space:]]*$f\(\)" "$REPO_ROOT/$RR_TOOL" \
      && fail "$RR_TOOL defines its own $f, so it is a second reader"
  done
  return 0
}

# ── Fault 1: a revision the tool accepted and dropped ────────────────────────
# The instrument shifted and then read `$2`, so `snapshot REV` discarded REV and answered
# a different question with exit 0. `snapshot --since REV` worked only because the
# discarded token happened to land where the read looked.

test_read_record_snapshot_honours_a_revision() {
  rr_repo rev
  rr_brief 0001 one -- 'blc/2 #0001 in-progress a:in-progress(br)'
  rr_commit "first"
  rr_brief 0002 two -- 'blc/2 #0002 in-progress a:in-progress(br)'
  rr_commit "second"
  rr_brief 0003 three -- 'blc/2 #0003 in-progress a:in-progress(br)'
  rr_commit "third"

  rr_run snapshot HEAD~1
  local scoped; scoped="$(rr_count_key sha)"
  rr_run snapshot
  local all; all="$(rr_count_key sha)"
  [ "$scoped" -lt "$all" ] \
    || fail "snapshot HEAD~1 returned $scoped events and the default returned $all; the revision was dropped"
}

test_read_record_snapshot_since_is_the_same_as_a_bare_revision() {
  rr_repo since
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit "first"
  rr_brief 0002 two -- 'blc/2 #0002 done(PR#2)'
  rr_commit "second"

  rr_run events HEAD~1
  local bare; bare="$(rr_count_key sha)"
  rr_run events --since HEAD~1
  local flagged; flagged="$(rr_count_key sha)"
  [ "$bare" = "$flagged" ] \
    || fail "events HEAD~1 gave $bare and events --since HEAD~1 gave $flagged"
}

# ── The guard has to actually fail ───────────────────────────────────────────
# This was written first as `cmd_snapshot "$(rev_arg ...)"`. An `exit` inside a command
# substitution ends the subshell: the message reached stderr, the script carried on, and
# the exit status was 0. The repository hit the same shape in #0038. Asserting the message
# alone would have passed against that bug, so the status is what is asserted.

test_read_record_rejects_a_second_revision_with_a_nonzero_status() {
  rr_repo guard
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit
  rr_run snapshot HEAD HEAD~1
  [ "$RR_RC" -ne 0 ] \
    || fail "snapshot took two revisions and exited 0; the guard died in a subshell"
  assert_contains "takes at most one revision" "$RR_ERR"
}

test_read_record_rejects_arguments_to_a_subcommand_that_takes_none() {
  rr_repo noargs
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit
  rr_run briefs extra
  [ "$RR_RC" -ne 0 ] || fail "briefs accepted an argument and exited 0"
}

test_read_record_rejects_an_unknown_command() {
  rr_repo unknown
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit
  rr_run bogus
  [ "$RR_RC" -eq 2 ] || fail "unknown command exited $RR_RC, expected 2"
}

# ── Fault 2: one shape for a state, at both levels ───────────────────────────
# The instrument split phase states into state and pointer and left the brief-level state
# whole, so `done(PR#11)` arrived as a state at one level and as two fields at the other.

test_read_record_splits_the_brief_state_from_its_pointer() {
  rr_repo split
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#11) a:done(PR#9)'
  rr_commit
  rr_run briefs
  rr_assert_field 0001 state '"done"'
  rr_assert_field 0001 pointer '"PR#11"'
}

test_read_record_keeps_a_pointer_that_holds_a_space() {
  # `done(commit 92a7168)` is a real state in this repository — #0001 and four others
  # carry it. Cutting at the first `)` or splitting on whitespace loses the sha.
  rr_repo space
  rr_brief 0001 one -- 'blc/2 #0001 done(commit 92a7168)'
  rr_commit
  rr_run briefs
  rr_assert_field 0001 state '"done"'
  rr_assert_field 0001 pointer '"commit 92a7168"'
}

test_read_record_keeps_the_raw_status_line() {
  # The split must not lose anything. A consumer that wants the line as written still has
  # it, which is what makes the split safe to do at all.
  rr_repo raw
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#11) a:done(PR#9)'
  rr_commit
  rr_run briefs
  rr_assert_field 0001 status_line '"blc/2 #0001 done(PR#11) a:done(PR#9)"'
}

# ── The inherited defect: invented states ────────────────────────────────────
# `tools/list-briefs.sh` prints `planned` for a brief with no ledger and `no-line` for a
# ledger with no status line. Neither is in the five-state vocabulary at
# docs/blc/briefs/README.md. The brief for #0039 names that disagreement as one of the
# four findings it was filed about, and the instrument copied both words.

test_read_record_invents_no_state_for_a_brief_with_no_ledger() {
  rr_repo noledger
  rr_brief 0001 one
  rr_commit
  rr_run briefs
  rr_assert_field 0001 state '""'
  rr_assert_field 0001 has_ledger 'false'
  case "$(rr_brief_obj 0001)" in
    *planned*) fail "the surface invented the state 'planned', which is not in the vocabulary" ;;
  esac
}

test_read_record_invents_no_state_for_a_ledger_with_no_status_line() {
  rr_repo noline
  rr_brief 0001 one -- '# Ledger' '' 'No status line here.'
  rr_commit
  rr_run briefs
  rr_assert_field 0001 state '""'
  rr_assert_field 0001 has_ledger 'true'
  rr_assert_field 0001 has_status_line 'false'
  case "$(rr_brief_obj 0001)" in
    *no-line*) fail "the surface invented the state 'no-line', which is not in the vocabulary" ;;
  esac
}

test_read_record_reports_only_vocabulary_states() {
  # The whole fixture, checked at once: every non-empty state the surface emits has to be
  # one of the five. A sixth word is the defect this phase closes, whatever it is.
  rr_repo vocab
  rr_brief 0001 a -- 'blc/2 #0001 done(PR#1) a:done(PR#1) b:skipped'
  rr_brief 0002 b -- 'blc/2 #0002 in-progress a:in-progress(br) b:pending'
  rr_brief 0003 c -- 'blc/2 #0003 deferred a:deferred(br)'
  rr_brief 0004 d
  rr_commit
  rr_run briefs
  local bad
  bad="$(tr ',' '\n' < "$RR_OUT" | sed -n 's/.*"state":"\([^"]*\)".*/\1/p' \
    | grep -v '^$' | grep -vxE 'pending|in-progress|deferred|done|skipped' || true)"
  [ -z "$bad" ] || fail "states outside the five-state vocabulary: $(printf '%s' "$bad" | tr '\n' ' ')"
}

# ── The derivation, moved out of the console ─────────────────────────────────
# Prototype 2 built this in Go and asked for it to move here, because three consoles each
# deriving an answer are three readers free to disagree. The derivation is thin, and these
# tests pin which shapes it claims rather than asserting it is clever.

test_read_record_next_sends_an_undated_close_to_blc_close_brief() {
  rr_repo nextclose
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit
  rr_run next
  assert_contains '"action":"blc-close-brief"' "$RR_OUT"
  assert_contains 'records no Closed date' "$RR_OUT"
}

test_read_record_next_skips_a_brief_that_is_properly_closed() {
  # A closed brief needs nothing. Reporting one buries the briefs that do.
  rr_repo nextclosed
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)' '' '**Closed:** 2026-01-02'
  rr_commit
  rr_run next
  assert_not_contains '"0001"' "$RR_OUT"
}

test_read_record_next_sends_a_filed_serial_with_no_ledger_to_start_brief() {
  rr_repo nextstart
  rr_brief 0001 one
  rr_commit
  rr_run next
  assert_contains '"action":"blc-start-brief"' "$RR_OUT"
}

test_read_record_next_sends_a_phase_in_progress_to_review() {
  rr_repo nextreview
  rr_brief 0001 one -- 'blc/2 #0001 in-progress a:in-progress(brief/0001-a-x)'
  rr_commit
  rr_run next
  assert_contains 'blc-review-pr' "$RR_OUT"
  # The basis names the branch, because the pointer is the part that made it actionable.
  assert_contains 'brief/0001-a-x' "$RR_OUT"
}

test_read_record_next_sends_a_pending_phase_to_next_brief_phase() {
  rr_repo nextphase
  rr_brief 0001 one -- 'blc/2 #0001 in-progress a:done(PR#1) b:pending'
  rr_commit
  rr_run next
  assert_contains '"action":"blc-next-brief-phase"' "$RR_OUT"
}

test_read_record_next_names_the_state_when_no_rule_matches() {
  # The honest answer. A wrong next action is worse than none, because the claim of #0039
  # is that a person trusts what this says without checking.
  rr_repo nextnone
  rr_brief 0001 one -- 'blc/2 #0001 skipped'
  rr_commit
  rr_run next
  assert_contains '"action":"none"' "$RR_OUT"
  assert_contains 'skipped' "$RR_OUT"
}

# ── Shape ────────────────────────────────────────────────────────────────────

test_read_record_emits_one_phase_object_per_status_line_entry() {
  rr_repo phases
  rr_brief 0001 one -- 'blc/2 #0001 in-progress a:done(PR#1) b:in-progress(br) c:pending'
  rr_commit
  rr_run briefs
  local n; n="$(rr_count_key id)"
  [ "$n" -eq 3 ] || fail "expected 3 phase objects, got $n"
}

test_read_record_me_reports_the_configured_identity() {
  rr_repo me
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit
  rr_run me
  assert_contains '"email":"t@e.com"' "$RR_OUT"
}

test_read_record_runs_from_a_directory_that_is_not_the_repository_root() {
  # The tool finds its libraries beside itself. Resolving them against the working
  # directory is the defect #0024 was filed about, and it is what made the instrument
  # impossible to point at a fixture.
  rr_repo cwd
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit
  mkdir -p "$RR_DIR/sub/deeper"
  RR_OUT="$TMP/rr.out"
  ( cd "$RR_DIR/sub/deeper" && BLC_READ_ROOT="$RR_DIR" \
    bash "$REPO_ROOT/$RR_TOOL" briefs ) >"$RR_OUT" 2>&1 \
    || fail "the tool failed when run from a subdirectory"
  assert_contains '"serial":"0001"' "$RR_OUT"
}

# ── The contract: the field set is pinned ────────────────────────────────────
# Phase b planned "a schema". A JSON Schema file was not written, and the reason is this
# repository's own rule rather than time: a schema beside a hand-rolled emitter is a
# declared second copy of the same fact, and nothing here could check the two agree. `jq`
# is absent on the machine that published this, and adding a JSON toolchain to validate
# the surface would hand the surface the dependency it exists to avoid.
#
# So the contract is pinned as the exact key set of each object, enforced. A field added,
# removed or renamed fails here and somebody decides on purpose. That is the property a
# schema was wanted for, and this one cannot drift from the thing it describes.

# Keys of one JSON object, in order, comma-joined. The fixtures below hold no value that
# contains `":`, so matching key tokens is exact for them.
rr_keys_of() {
  printf '%s' "$1" | grep -o '"[a-z_]*":' | tr -d '":' | paste -sd,
}

test_read_record_brief_object_fields_are_pinned() {
  rr_repo keysbrief
  rr_brief 0001 one -- 'blc/2 #0001 in-progress a:in-progress(br)'
  rr_commit
  rr_run briefs
  local obj got want
  obj="$(sed 's/,"phases".*//' "$RR_OUT")"
  got="$(rr_keys_of "$obj")"
  want="serial,slug,dir,title,state,pointer,status_line,owner,author,assignee,mine,created,closed,touched,has_ledger,has_status_line"
  [ "$got" = "$want" ] || fail "the brief object's fields changed.
pinned: $want
found:  $got"
}

test_read_record_phase_object_fields_are_pinned() {
  rr_repo keysphase
  rr_brief 0001 one -- 'blc/2 #0001 in-progress a:in-progress(br)'
  rr_commit
  rr_run briefs
  local obj got want
  obj="$(sed 's/.*"phases":\[//; s/\].*//' "$RR_OUT")"
  got="$(rr_keys_of "$obj")"
  want="id,label,state,pointer"
  [ "$got" = "$want" ] || fail "the phase object's fields changed.
pinned: $want
found:  $got"
}

test_read_record_next_object_fields_are_pinned() {
  rr_repo keysnext
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit
  rr_run next
  local got want
  got="$(rr_keys_of "$(cat "$RR_OUT")")"
  want="serial,slug,action,basis"
  [ "$got" = "$want" ] || fail "the next object's fields changed.
pinned: $want
found:  $got"
}

test_read_record_event_object_fields_are_pinned() {
  rr_repo keysevent
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit "a fixture commit"
  rr_run events
  local obj got want
  obj="$(sed 's/^\[//; s/},{.*/}/' "$RR_OUT")"
  got="$(rr_keys_of "$obj")"
  want="sha,when,who,mine,kind,serial,phase,subject"
  [ "$got" = "$want" ] || fail "the event object's fields changed.
pinned: $want
found:  $got"
}

test_read_record_snapshot_top_level_fields_are_pinned() {
  rr_repo keyssnap
  rr_brief 0001 one -- 'blc/2 #0001 done(PR#1)'
  rr_commit
  rr_run snapshot
  # Top level only: cut each section's array off at its opening bracket.
  local got want
  got="$(sed 's/{"email".*"head"/"head"/; s/"briefs":\[.*/"briefs":/' "$RR_OUT" \
        | grep -o '"[a-z_]*":' | tr -d '":' | paste -sd,)"
  want="generated,repo,me,head,branch,briefs"
  [ "$got" = "$want" ] || fail "the snapshot's top-level fields changed.
pinned: $want
found:  $got"
}

# ── The derivation must not contradict a decision already recorded ───────────
# The first version of `next` reported "every phase is finished and the brief is still
# open" whenever no phase matched a rule, so a deferred brief — parked on purpose, with a
# reason in its ledger — was told to close. The basis was also untrue. A wrong next action
# stated confidently is the failure this surface exists to avoid.

test_read_record_next_does_not_tell_a_deferred_brief_to_close() {
  rr_repo nextdeferred
  rr_brief 0001 one -- 'blc/2 #0001 deferred a:deferred(br)'
  rr_commit
  rr_run next
  assert_not_contains 'blc-close-brief' "$RR_OUT"
  assert_contains '"action":"none"' "$RR_OUT"
}

test_read_record_next_does_not_tell_a_brief_with_a_deferred_phase_to_close() {
  rr_repo nextdeferredphase
  rr_brief 0001 one -- 'blc/2 #0001 in-progress a:done(PR#1) b:deferred(br)'
  rr_commit
  rr_run next
  assert_not_contains 'blc-close-brief' "$RR_OUT"
  assert_contains 'phase b is deferred' "$RR_OUT"
}

test_read_record_next_closes_a_brief_whose_phases_are_all_done_or_skipped() {
  # The rule that was over-firing is still needed, so this pins when it may fire.
  rr_repo nextallfinished
  rr_brief 0001 one -- 'blc/2 #0001 in-progress a:done(PR#1) b:skipped'
  rr_commit
  rr_run next
  assert_contains '"action":"blc-close-brief"' "$RR_OUT"
  assert_contains 'done or skipped' "$RR_OUT"
}

test_read_record_next_does_not_guess_at_a_state_outside_the_vocabulary() {
  # list-briefs.sh invents `planned`. If a word like that ever reaches a phase slot, the
  # surface must not treat it as finished and send somebody to close the brief.
  rr_repo nextunknown
  rr_brief 0001 one -- 'blc/2 #0001 in-progress a:done(PR#1) b:planned'
  rr_commit
  rr_run next
  assert_not_contains 'blc-close-brief' "$RR_OUT"
}
