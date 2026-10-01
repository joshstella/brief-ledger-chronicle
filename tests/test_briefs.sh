# Contract clauses BRIEFS-1 to BRIEFS-8 — tools/validate-briefs.sh.
#
# Every clause gets a fixture that violates it. A validator exercised only against
# a compliant tree passes identically when each check is replaced by `return 0`,
# so a green suite would say nothing about whether the clauses are enforced. The
# negative fixtures are the test; the self-check at the bottom is the claim that
# this repo complies.
#
# Clause text is in docs/blc/contracts/v1.2.md (BRIEFS-1..8 unchanged from v1) and is not restated
# here.

VALIDATOR() { printf '%s' "$REPO_ROOT/tools/validate-briefs.sh"; }

run_validator() {
  bash "$(VALIDATOR)" "$@" >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# A briefs directory with the non-numbered entries BRIEFS-1 permits.
make_briefs() {
  BRIEFS="$TMP/briefs"
  mkdir -p "$BRIEFS/_drafts"
  echo "# Briefs" > "$BRIEFS/README.md"
  echo "# Drafts" > "$BRIEFS/_drafts/README.md"
}

# usage: add_brief <folder> [depends-on]
add_brief() {
  local folder="$1" deps="${2:---}" serial="${1%%-*}"
  mkdir -p "$BRIEFS/$folder"
  {
    echo "# ${folder#*-}"
    echo ""
    echo "**Serial:** #$serial · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** $deps"
  } > "$BRIEFS/$folder/brief.md"
}

# usage: add_brief_with_identity <folder> <identity-line>
add_brief_with_identity() {
  local folder="$1" identity="$2"
  mkdir -p "$BRIEFS/$folder"
  {
    echo "# ${folder#*-}"
    echo ""
    echo "$identity"
  } > "$BRIEFS/$folder/brief.md"
}

# ── The clean case ───────────────────────────────────────────────────────────

test_briefs_a_compliant_tree_passes() {
  make_briefs
  add_brief 0001-first
  add_brief 0002-second "#0001"
  run_validator "$BRIEFS"
  assert_status 0
  assert_out "2 brief(s), 10 clauses decided, 0 defect(s), 0 judgment(s)"
}

# Zero defects and exit 0 is also what an empty directory produces. Any test that
# reads a clean run as proof of compliance has to distinguish the two, or it
# passes on a tree containing nothing.
test_briefs_an_empty_tree_reports_no_briefs() {
  make_briefs
  run_validator "$BRIEFS"
  assert_status 0
  assert_out "0 brief(s)"
}

test_briefs_a_missing_directory_is_a_usage_error_not_a_pass() {
  run_validator "$TMP/nope"
  assert_status 2
  assert_err "not a directory"
}

# ── BRIEFS-1 — entries are briefs or known non-numbered files ────────────────

test_briefs_1_rejects_an_unexpected_entry() {
  make_briefs
  add_brief 0001-first
  echo "scratch" > "$BRIEFS/notes.txt"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-1 [defect] notes.txt"
}

test_briefs_1_rejects_a_serial_prefixed_file() {
  make_briefs
  add_brief 0001-first
  echo "loose" > "$BRIEFS/0002-loose.md"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-1 [defect] 0002-loose.md: has a serial prefix but is not a folder"
}

test_briefs_1_permits_drafts_and_readme() {
  make_briefs
  add_brief 0001-first
  run_validator "$BRIEFS"
  assert_status 0
  assert_not_contains "BRIEFS-1" "$OUT"
}

# ── BRIEFS-2 — slug and serial shape ────────────────────────────────────────

test_briefs_2_rejects_an_uppercase_slug() {
  make_briefs
  add_brief 0001-first
  mkdir -p "$BRIEFS/0002-Bad_Slug"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-2 [defect] 0002-Bad_Slug"
}

test_briefs_2_rejects_a_five_digit_serial() {
  make_briefs
  add_brief 0001-first
  mkdir -p "$BRIEFS/00002-toolong"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-2 [defect] 00002-toolong"
}

# A malformed name is one finding, not a cascade. If BRIEFS-2 let it through to
# the clauses that parse a serial out of it, one typo would report as four
# unrelated violations and the report would stop being readable.
test_briefs_2_a_malformed_name_does_not_cascade() {
  make_briefs
  add_brief 0001-first
  mkdir -p "$BRIEFS/0002-Bad_Slug"
  run_validator "$BRIEFS"
  assert_status 1
  assert_not_contains "BRIEFS-4" "$OUT"
  assert_not_contains "BRIEFS-5" "$OUT"
  assert_out "1 defect(s)"
}

# ── BRIEFS-3 — serials are unique ───────────────────────────────────────────

test_briefs_3_rejects_a_duplicate_serial() {
  make_briefs
  add_brief 0001-first
  add_brief 0001-also-first
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-3 [defect] 0001: used by more than one folder"
}

# ── BRIEFS-4 — every brief folder holds a brief ─────────────────────────────

test_briefs_4_rejects_a_folder_with_no_brief() {
  make_briefs
  add_brief 0001-first
  mkdir -p "$BRIEFS/0002-empty"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-4 [defect] 0002-empty: contains no brief.md"
}

# ── BRIEFS-5 — the identity line is well formed ─────────────────────────────

test_briefs_5_rejects_a_missing_identity_line() {
  make_briefs
  mkdir -p "$BRIEFS/0001-first"
  echo "# first" > "$BRIEFS/0001-first/brief.md"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: no identity line"
}

test_briefs_5_rejects_a_serial_that_disagrees_with_its_folder() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0009 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: identity line says #0009, folder says 0001"
}

# The digits agree with the folder; the `#` is missing. Comparing the bare field value would
# let this pass, and no other fixture here would notice.
test_briefs_5_rejects_a_serial_without_its_hash() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** 0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: identity line says"
}

# The shared reader trims spaces only. Trimming tabs too would let both of these pass.
test_briefs_5_rejects_a_tab_after_the_serial_label() {
  make_briefs
  add_brief_with_identity 0001-first \
    "$(printf '**Serial:**\t#0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —')"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: identity line says"
}

test_briefs_5_rejects_a_tab_after_the_created_label() {
  make_briefs
  add_brief_with_identity 0001-first \
    "$(printf '**Serial:** #0001 · **Created:**\t2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —')"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: Created is missing or not ISO-8601 UTC"
}

test_briefs_5_rejects_an_author_that_does_not_start_with_the_address() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** Name <a@b.com> · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: Author is missing or not email-shaped"
}

test_briefs_5_compares_the_serial_on_its_leading_digits() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0001x · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 0
  assert_out "0 defect(s)"
}

# The first occurrence of a label wins, and a field ends at the next `·`. A check that matched
# its label anywhere on the line would pass each of these.
test_briefs_5_reads_the_first_created_field() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0001 · **Created:** bad · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: Created is missing or not ISO-8601 UTC"
}

test_briefs_5_reads_the_first_author_field() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** bad · **Author:** a@b.com · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: Author is missing or not email-shaped"
}

test_briefs_5_an_author_ends_at_the_separator() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b·x.y · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: Author is missing or not email-shaped"
}

test_briefs_5_an_author_with_a_separator_before_the_at_sign_fails() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a·b@c.d · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: Author is missing or not email-shaped"
}

test_briefs_5_rejects_a_created_date_that_is_not_iso_utc() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0001 · **Created:** Aug 21 2026 · **Author:** a@b.com · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: Created is missing or not ISO-8601 UTC"
}

test_briefs_5_rejects_an_author_that_is_not_email_shaped() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** Josha · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: Author is missing or not email-shaped"
}

test_briefs_5_rejects_a_missing_depends_on() {
  make_briefs
  add_brief_with_identity 0001-first \
    "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-5 [defect] 0001-first: identity line has no Depends on"
}

# ── BRIEFS-6 — no dangling dependencies ─────────────────────────────────────

test_briefs_6_rejects_a_dangling_dependency() {
  make_briefs
  add_brief 0001-first
  add_brief 0002-second "#0009"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-6 [defect] 0002-second: depends on #0009, which does not exist"
}

test_briefs_6_accepts_multiple_real_dependencies() {
  make_briefs
  add_brief 0001-first
  add_brief 0002-second
  add_brief 0003-third "#0001, #0002"
  run_validator "$BRIEFS"
  assert_status 0
  assert_not_contains "BRIEFS-6" "$OUT"
}

# ── BRIEFS-7 — drafts are unnumbered ────────────────────────────────────────

test_briefs_7_rejects_a_numbered_draft() {
  make_briefs
  add_brief 0001-first
  echo "draft" > "$BRIEFS/_drafts/0002-premature.md"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "BRIEFS-7 [defect] _drafts/0002-premature.md"
}

test_briefs_7_permits_an_unnumbered_draft() {
  make_briefs
  add_brief 0001-first
  echo "draft" > "$BRIEFS/_drafts/some-idea.md"
  run_validator "$BRIEFS"
  assert_status 0
  assert_not_contains "BRIEFS-7" "$OUT"
}

# ── BRIEFS-8 — serials are contiguous, and never block ──────────────────────

test_briefs_8_surfaces_a_gap() {
  make_briefs
  add_brief 0001-first
  add_brief 0003-third
  run_validator "$BRIEFS"
  assert_out "BRIEFS-8 [judgment] serials jump from 0001 to 0003"
}

test_briefs_8_surfaces_a_run_that_does_not_start_at_one() {
  make_briefs
  add_brief 0002-second
  run_validator "$BRIEFS"
  assert_out "BRIEFS-8 [judgment] serials start at 0002, not 0001"
}

# The whole point of the tag. Making a judgment clause fail the build would
# silently promote it to a defect, and the Contract says it never blocks.
test_briefs_8_a_gap_does_not_fail_the_run() {
  make_briefs
  add_brief 0001-first
  add_brief 0003-third
  run_validator "$BRIEFS"
  assert_status 0
  assert_out "0 defect(s), 1 judgment(s)"
}

# ── This repository complies with its own Contract ──────────────────────────

test_briefs_this_repo_satisfies_contract_v1() {
  run_validator "$REPO_ROOT/docs/blc/briefs"
  assert_status 0
  assert_out "0 defect(s)"
  # Without this the test passes on an empty docs/blc/briefs, which is compliance by
  # vacancy rather than compliance.
  assert_matches "— [1-9][0-9]* brief(s)" "$OUT"
}

# The brief asks that a check be named by path so the sentence goes stale if the
# link breaks. A named path nothing resolves is a claim of coverage backed by a
# string, so the naming only means something if something reads it. Phase 3 owns
# the wider report on which clauses have checks; this is only the link itself.
test_briefs_every_named_check_path_resolves() {
  local contract path found=0
  for contract in "$REPO_ROOT/docs/blc/contracts/v1.md" "$REPO_ROOT/docs/blc/contracts/v1.1.md" \
                  "$REPO_ROOT/docs/blc/contracts/v1.2.md"; do
    for path in $(grep -oE 'checked: `[^`]+`' "$contract" | sed 's/checked: `\(.*\)`/\1/' | sort -u); do
      found=$((found + 1))
      [ -f "$REPO_ROOT/$path" ] || fail "${contract##*/} names a check that does not exist: $path"
    done
  done
  [ "$found" -gt 0 ] || fail "Contract names no checks at all — expected at least one"
}

# ── The optional identity fields, and what the validator does not say ────────
#
# #0007 phase `a`. `docs/blc/briefs/README.md` states that `validate-briefs.sh` says nothing
# about `Jira:` or `Owner:`, and that a malformed value costs you a report and not a brief.
# That is a claim about a program that ships today, so the phase's documentation-only
# exemption does not reach it. Without a fixture the sentence is true by accident, and a
# later clause could make it false in silence.

test_briefs_the_optional_tracker_fields_decide_nothing() {
  make_briefs
  add_brief_with_identity 0001-owned \
    "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Owner:** not-an-email · **Jira:** !!! · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 0
  assert_out "1 brief(s), 10 clauses decided, 0 defect(s), 0 judgment(s)"
  # Both values are deliberately malformed. A well-formed fixture would pass under a
  # validator that had learned to check them, which is the change this test exists to catch.
  grep -q 'not-an-email' "$BRIEFS/0001-owned/brief.md" \
    || fail "fixture lost its Owner value — the assertion above proves nothing"
  grep -q 'Jira:\*\* !!!' "$BRIEFS/0001-owned/brief.md" \
    || fail "fixture lost its Jira value — the assertion above proves nothing"
}

# `Depends on` ends at the next `·`. A parse that read to the end of the line would make a
# `#NNNN` in any later field a dependency: a blocking defect if the serial did not exist, and an
# undeclared edge reported by nothing if it did.
#
# The two that assert an absence carry a control. A validator that had stopped reading
# dependencies at all would pass every "is not a dependency" assertion here, so each also
# proves a serial written *inside* the field is still read.
test_briefs_a_hash_after_depends_on_is_not_a_dependency() {
  make_briefs
  add_brief 0002-real
  add_brief 0003-real
  add_brief_with_identity 0001-trailing \
    "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** #0003, #0002 · **Jira:** ticket #9999"
  run_validator "$BRIEFS"
  assert_status 0
  assert_not_contains "#9999" "$OUT"
  # Control: every serial before the `·` is still a dependency, not only the first.
  rm -rf "$BRIEFS/0002-real"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "depends on #0002"
  assert_not_contains "#9999" "$OUT"
}

test_briefs_the_same_value_before_depends_on_is_inert() {
  make_briefs
  add_brief_with_identity 0001-ordered \
    "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Jira:** ticket #9999 · **Depends on:** —"
  run_validator "$BRIEFS"
  assert_status 0
  assert_out "0 defect(s), 0 judgment(s)"
}

# An existing serial after `Depends on` would be an edge nobody declared, reported by nothing.
# A clean run cannot show it is not read, because a clean run is also what the swallowed edge
# produces. Removing the brief it names does: if the field were read past the `·`, this would
# now dangle.
test_briefs_an_existing_serial_after_depends_on_is_not_swallowed() {
  make_briefs
  add_brief 0001-real
  add_brief 0003-real
  add_brief_with_identity 0002-trailing \
    "**Serial:** #0002 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** #0003 · **Jira:** ticket #0001"
  run_validator "$BRIEFS"
  assert_status 0
  # Removing 0001 draws a BRIEFS-8 judgment (serials start at 0002). No defect may follow.
  rm -rf "$BRIEFS/0001-real"
  run_validator "$BRIEFS"
  assert_status 0
  assert_out "0 defect(s)"
  assert_not_contains "depends on #0001" "$OUT"
  # Control: the serial inside the field is still a dependency.
  rm -rf "$BRIEFS/0003-real"
  run_validator "$BRIEFS"
  assert_status 1
  assert_out "depends on #0003"
}
