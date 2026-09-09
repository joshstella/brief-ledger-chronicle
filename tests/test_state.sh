# The declaration convention — docs/state/, from #0008b.
#
# Phase b ships a convention, not a program, and a convention has almost nothing a
# test can hold onto. What follows is deliberately limited to the two things that
# are actually mechanical: that the directory and its README reach a target, and
# that the filename rule produces the path the README claims it does.
#
# The rule is asserted here against a local implementation of it, not against
# shipped code, because nothing implements it yet — phase c's orient is the first
# reader. That is a real gap and it is recorded in the ledger: until c lands, the
# normalization rule is prose, and prose drifts. These tests pin the expected
# answers now so that c has something to be wrong against.

# The rule, in one line: lowercase the address, use it verbatim.
state_path_for() { printf 'docs/state/%s.md' "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"; }

# ── The rule ─────────────────────────────────────────────────────────────────

test_state_filename_is_the_lowercased_address() {
  local got
  got="$(state_path_for 'Josh.Stella@Example.COM')"
  [ "$got" = "docs/state/josh.stella@example.com.md" ] \
    || fail "expected docs/state/josh.stella@example.com.md, got $got"
}

# @ and . survive. A slug rule would have eaten both, and the README promises they
# do not, because the mapping has to run backwards as well as forwards.
test_state_filename_keeps_the_at_sign_and_the_dots() {
  local got
  got="$(state_path_for 'a.b@c.d')"
  case "$got" in
    *"a.b@c.d"*) ;;
    *) fail "expected the address verbatim, got $got" ;;
  esac
}

# Two addresses that a dash-slug would collapse into one path must not collapse
# here. This is the collision the verbatim rule was chosen to avoid.
test_state_filename_does_not_collide_two_addresses() {
  local a b
  a="$(state_path_for 'josh.stella@example.com')"
  b="$(state_path_for 'josh-stella@example.com')"
  [ "$a" != "$b" ] || fail "two distinct addresses produced the same path: $a"
}

# The concurrency story in one assertion: two contributors declaring at the same
# moment write different files, so there is nothing to merge.
test_state_two_contributors_never_share_a_path() {
  local a b
  a="$(state_path_for 'one@example.com')"
  b="$(state_path_for 'two@example.com')"
  [ "$a" != "$b" ] || fail "two contributors mapped to the same path: $a"
}

# A path is only useful if it can be written. @ and . are legal everywhere this
# runs, and this proves it rather than assuming it.
test_state_the_derived_path_is_actually_writable() {
  local p="$TMP/$(state_path_for 'Josh.Stella@Example.com')"
  mkdir -p "$(dirname "$p")"
  printf '# josh.stella@example.com\n' > "$p" 2>/dev/null \
    || fail "could not write the derived path: $p"
  assert_file "$p"
}

# ── It has to travel ─────────────────────────────────────────────────────────

test_state_directory_is_scaffolded_into_a_target() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_dir "$TARGET/docs/state"
}

test_state_readme_ships_to_a_target() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/docs/state/README.md"
  assert_contains "One file per contributor" "$TARGET/docs/state/README.md"
}

test_state_ships_on_both_hosts() {
  run_install y --host claude --target "$TARGET"
  assert_status 0
  assert_file "$TARGET/docs/state/README.md"
}

test_state_is_named_in_the_install_summary() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  assert_out "docs/state/"
}

# Declarations are committed inputs, not generated output. If a future change ever
# ignores this directory the way docs/chronicles/ is partly ignored, the whole
# single-writer design stops working — a peer cannot read what was never pushed.
test_state_is_not_gitignored_in_a_target() {
  run_install y --host cursor --target "$TARGET"
  assert_status 0
  if [ -f "$TARGET/.gitignore" ]; then
    assert_not_contains "docs/state" "$TARGET/.gitignore"
  fi
  return 0
}
