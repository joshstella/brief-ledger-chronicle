# Project checks — brief-checks/*.sh run by tools/validate-briefs.sh (#0011).

# Names are prefixed — test_briefs.sh defines run_validator too, and
# every test_*.sh is sourced into one shell by run.sh.
make_brief_checks_repo() {
  BC_REPO="$TMP/repo"
  BC_BRIEFS="$BC_REPO/docs/briefs"
  BC_CHECKS="$BC_REPO/brief-checks"
  mkdir -p "$BC_BRIEFS/_drafts"
  echo "# Briefs" > "$BC_BRIEFS/README.md"
  echo "# Drafts" > "$BC_BRIEFS/_drafts/README.md"
  mkdir -p "$BC_BRIEFS/0001-first"
  {
    echo "# first"
    echo ""
    echo "**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** a@b.com · **Depends on:** —"
  } > "$BC_BRIEFS/0001-first/brief.md"
}

run_brief_checks_validator() {
  bash "$REPO_ROOT/tools/validate-briefs.sh" "$BC_BRIEFS" >"$OUT" 2>&1
  LAST_STATUS=$?
}

test_brief_checks_absent_directory_behaves_as_today() {
  make_brief_checks_repo
  run_brief_checks_validator
  assert_status 0
  assert_out "1 brief(s), 8 clauses decided, 0 defect(s), 0 judgment(s)"
  assert_not_contains "project check failure" "$OUT"
}

test_brief_checks_empty_directory_behaves_as_today() {
  make_brief_checks_repo
  mkdir -p "$BC_CHECKS"
  run_brief_checks_validator
  assert_status 0
  assert_out "1 brief(s), 8 clauses decided, 0 defect(s), 0 judgment(s)"
}

test_brief_checks_passing_script() {
  make_brief_checks_repo
  mkdir -p "$BC_CHECKS"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$BC_CHECKS/ok.sh"
  run_brief_checks_validator
  assert_status 0
  assert_out "1 brief(s), 8 clauses decided, 0 defect(s), 0 judgment(s)"
}

test_brief_checks_failing_script_echoes_its_output() {
  make_brief_checks_repo
  mkdir -p "$BC_CHECKS"
  {
    echo '#!/usr/bin/env bash'
    echo 'echo "house rule violated"'
    echo 'exit 1'
  } > "$BC_CHECKS/no-drafts.sh"
  run_brief_checks_validator
  assert_status 1
  assert_out "no-drafts.sh:"
  assert_out "house rule violated"
  assert_out "1 project check failure(s)"
}

test_brief_checks_crashing_script_fails_the_run() {
  make_brief_checks_repo
  mkdir -p "$BC_CHECKS"
  printf '%s\n' '#!/usr/bin/env bash' 'syntax error here (' > "$BC_CHECKS/broken.sh"
  run_brief_checks_validator
  assert_status 1
  assert_out "broken.sh:"
  assert_out "1 project check failure(s)"
}

test_brief_checks_two_scripts_run_in_sorted_order() {
  make_brief_checks_repo
  mkdir -p "$BC_CHECKS"
  ORDER="$TMP/order.txt"
  : > "$ORDER"
  {
    echo '#!/usr/bin/env bash'
    echo "echo z >> \"$ORDER\""
  } > "$BC_CHECKS/20-second.sh"
  {
    echo '#!/usr/bin/env bash'
    echo "echo a >> \"$ORDER\""
  } > "$BC_CHECKS/10-first.sh"
  run_brief_checks_validator
  assert_status 0
  assert_contains "$(printf 'a\nz\n')" "$ORDER"
}

test_brief_checks_cannot_clear_a_toolkit_defect() {
  make_brief_checks_repo
  mkdir -p "$BC_CHECKS"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$BC_CHECKS/would-pass.sh"
  echo "not a brief folder" > "$BC_BRIEFS/9999-wrong"
  run_brief_checks_validator
  assert_status 1
  assert_out "[defect]"
  assert_not_contains "would-pass.sh:" "$OUT"
  assert_not_contains "project check failure" "$OUT"
}

test_brief_checks_install_leaves_the_directory_unmodified() {
  mkdir -p "$TARGET/brief-checks"
  printf '%s\n' '#!/usr/bin/env bash' 'echo PROJECT-OWNED' 'exit 0' > "$TARGET/brief-checks/my-rule.sh"
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_contains "PROJECT-OWNED" "$TARGET/brief-checks/my-rule.sh"
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_contains "PROJECT-OWNED" "$TARGET/brief-checks/my-rule.sh"
  assert_no_dir "$TARGET/brief-checks/blc-anything"
}
