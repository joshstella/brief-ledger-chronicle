# Phase d — the shipped rules say what survives an install (#0012).

test_socialization_process_rules_name_the_two_customization_paths() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  local rules="$TARGET/.cursor/rules/brief-ledger-chronicle.mdc"
  assert_contains "do not survive" "$rules"
  assert_contains "AGENTS.md" "$rules"
  assert_contains "brief-checks/" "$rules"
}

test_socialization_process_rules_ship_on_claude_too() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  local rules="$TARGET/.claude/rules/brief-ledger-chronicle.md"
  assert_contains "do not survive" "$rules"
  assert_contains "AGENTS.md" "$rules"
  assert_contains "brief-checks/" "$rules"
}
