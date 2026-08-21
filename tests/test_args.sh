# Argument parsing, mode guards, and the confirmation prompt.

test_args_help_exits_zero() {
  run_install "" --help
  assert_status 0
  assert_out "Usage: bash install.sh"
}

test_args_unknown_flag_is_rejected() {
  run_install "" --bogus
  assert_status 1
  assert_err "Unknown argument: --bogus"
}

test_args_machine_and_target_are_mutually_exclusive() {
  run_install "" --machine --target "$TARGET"
  assert_status 1
  assert_err "mutually exclusive"
}

# The repo is the source of the process, never a target for it. Installing into
# itself would overwrite the canonical commands with copies of themselves.
#
# Run against a throwaway copy rather than the real checkout: the guard is what is
# under test, so a regression would write into whatever it is aimed at.
test_args_refuses_to_install_into_the_source_repo() {
  local src
  src="$(clone_installer_to_tmp)"
  run_install_from "$src" y --target "$src"
  assert_status 1
  assert_err "cannot install into brief-ledger-chronicle itself"
  # Proves the guard fired before any write, not merely that it printed something.
  assert_no_dir "$src/docs"
  assert_no_dir "$src/.claude"
}

test_args_declining_the_prompt_writes_nothing() {
  run_install n --target "$TARGET"
  assert_status 0
  assert_out "Aborted."
  assert_no_dir "$TARGET/.claude"
  assert_no_dir "$TARGET/docs"
}

# Anything other than y/Y is a decline, including an empty line.
test_args_empty_answer_declines() {
  run_install "" --target "$TARGET"
  assert_status 0
  assert_out "Aborted."
  assert_no_dir "$TARGET/docs"
}
