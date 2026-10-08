# tools/next-serial.sh — serial allocation that looks past the local directory, from #0034a.
#
# The brief exists because two contributors filed two briefs as #0018 on the same day. The
# first filed at 02:46 and could only push to a branch; the second filed at 04:06 reading a
# local directory that ended at 0017. Both were right about what they could see.
#
# So the test that matters is the one where the local directory is wrong: a serial exists on
# the remote and nowhere else. Every other test here guards the ways this program could go
# quiet instead of saying so.

NEXT() { printf '%s' "$REPO_ROOT/tools/next-serial.sh"; }

# usage: run_next [args...] — runs in $REPO.
run_next() {
  ( cd "$REPO" && bash "$(NEXT)" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# The answer, with the trailing newline removed so tests can compare it to a literal.
next_said() { tr -d '\n' < "$OUT"; }

# usage: ns_brief <repo-path> <serial-slug> — a brief folder with the one file that makes it
# real. The scan reads folder names, but a folder with no brief.md is not a filed brief and
# a fixture that omitted it would be testing something easier than the real tree.
ns_brief() {
  mkdir -p "$1/docs/blc/briefs/$2"
  printf '# %s\n' "$2" > "$1/docs/blc/briefs/$2/brief.md"
}

# A repo with a real `origin` on disk. A file-path remote fetches for real and needs no
# network, so the fetch this program performs is exercised rather than stubbed out.
ns_repo() {
  REPO="$TMP/repo"
  ORIGIN="$TMP/origin.git"
  git init -q --bare "$ORIGIN"
  mkdir -p "$REPO"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
  ns_brief "$REPO" 0001-first
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm base
  git -C "$REPO" remote add origin "$ORIGIN"
  git -C "$REPO" push -q origin main
}

# usage: ns_serial_only_on_a_branch <serial-slug> — files a brief on a branch, pushes it, and
# removes every local trace. Afterwards the serial exists on the remote and the working tree
# has never seen it. This is the state the incident was in.
ns_serial_only_on_a_branch() {
  git -C "$REPO" checkout -q -b "brief/${1%%-*}-a-x" main
  ns_brief "$REPO" "$1"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm "file $1"
  git -C "$REPO" push -q origin "brief/${1%%-*}-a-x"
  git -C "$REPO" checkout -q main
  git -C "$REPO" branch -qD "brief/${1%%-*}-a-x"
  git -C "$REPO" update-ref -d "refs/remotes/origin/brief/${1%%-*}-a-x" 2>/dev/null || true
}

# ── The failure the brief was filed about ────────────────────────────────────

test_next_serial_sees_a_serial_that_exists_only_on_a_remote_branch() {
  setup
  ns_repo
  ns_serial_only_on_a_branch 0002-filed-elsewhere
  # Proves the fixture, not the program: if the working tree could see 0002, the real
  # assertion below would pass for the wrong reason.
  [ ! -d "$REPO/docs/blc/briefs/0002-filed-elsewhere" ] \
    || { fail "fixture leaked 0002 into the working tree"; teardown; return 1; }
  run_next
  assert_status 0
  [ "$(next_said)" = "0003" ] \
    || fail "next serial is $(next_said), expected 0003 — 0002 is taken on a branch"
  teardown
}

test_next_serial_local_only_answer_would_have_been_wrong() {
  setup
  ns_repo
  ns_serial_only_on_a_branch 0002-filed-elsewhere
  # The number the old rule produced. Stated as its own test so that a regression to local-only
  # scanning fails with the incident's own number rather than an off-by-one.
  run_next
  # Checked first, because "not 0002" is also true of no answer at all. Without this the test
  # passed while tools/next-serial.sh did not yet exist.
  [ -n "$(next_said)" ] || { fail "no answer at all"; teardown; return 1; }
  [ "$(next_said)" != "0002" ] \
    || fail "answered 0002, which is the serial the #0018 collision took twice"
  teardown
}

# ── Degrading without going quiet ────────────────────────────────────────────

test_next_serial_answers_locally_when_there_is_no_remote() {
  setup
  REPO="$TMP/repo"
  mkdir -p "$REPO"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name Test
  ns_brief "$REPO" 0001-first
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm base
  run_next
  assert_status 0
  [ "$(next_said)" = "0002" ] || fail "next serial is $(next_said), expected 0002"
  teardown
}

test_next_serial_says_on_stderr_what_it_could_not_read() {
  setup
  ns_repo
  # A remote that is configured and gone. The program cannot know whether a serial is hiding
  # behind it, and an answer printed with no warning claims knowledge it does not have.
  git -C "$REPO" remote set-url origin "$TMP/this-path-does-not-exist.git"
  run_next
  assert_status 0
  [ "$(next_said)" = "0002" ] || fail "expected the local answer 0002, got $(next_said)"
  # The summary line, which every partial read prints, and then the specific source. Asserting
  # only the summary would pass for a program that warned without saying what it missed.
  assert_err "without reading everything"
  assert_err "fetch"
  teardown
}

test_next_serial_warns_nothing_when_the_remote_was_read() {
  setup
  ns_repo
  run_next
  # A program that warns on every run trains its reader to ignore the warning, and the warning
  # is the only thing standing between a partial read and a silent wrong answer.
  [ ! -s "$ERR" ] || fail "warned on a clean run: $(cat "$ERR")"
  teardown
}

# ── The edges of the count ───────────────────────────────────────────────────

test_next_serial_starts_at_0001_in_an_empty_registry() {
  setup
  ns_repo
  rm -rf "$REPO/docs/blc/briefs/0001-first"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm empty
  # Pushed, or the registry is empty here and not on `origin`, and the right answer becomes
  # 0002. The first version of this test failed for that reason and the program was correct.
  git -C "$REPO" push -q origin main
  run_next
  assert_status 0
  [ "$(next_said)" = "0001" ] || fail "expected 0001 in an empty registry, got $(next_said)"
  teardown
}

test_next_serial_ignores_entries_without_a_four_digit_prefix() {
  setup
  ns_repo
  mkdir -p "$REPO/docs/blc/briefs/_drafts"
  printf '# a draft\n' > "$REPO/docs/blc/briefs/_drafts/idea.md"
  printf '# readme\n' > "$REPO/docs/blc/briefs/README.md"
  run_next
  [ "$(next_said)" = "0002" ] || fail "_drafts or README moved the count: got $(next_said)"
  teardown
}

test_next_serial_refuses_a_briefs_directory_that_is_not_there() {
  setup
  ns_repo
  # The pre-#0017 layout, or a caller in the wrong directory. Both look exactly like a repo
  # with no briefs, and both would be answered 0001 — a serial the registry already used.
  # This is the one input the program refuses rather than reports on.
  run_next docs/briefs
  [ "$LAST_STATUS" -ne 0 ] \
    || fail "answered $(next_said) for a directory that does not exist, instead of refusing"
  assert_err "not a directory"
  [ -z "$(next_said)" ] || fail "printed a serial on stdout while refusing: $(next_said)"
  teardown
}

test_next_serial_does_not_count_a_four_digit_file_as_a_brief() {
  setup
  ns_repo
  # A brief is a folder (BRIEFS-4). A file beside them with the same prefix shape is not one,
  # and counting it would raise the maximum and skip a serial nothing had used.
  printf '# notes\n' > "$REPO/docs/blc/briefs/0033-notes.md"
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm notes
  git -C "$REPO" push -q origin main
  run_next
  [ "$(next_said)" = "0002" ] \
    || fail "a stray 0033-notes.md moved the answer to $(next_said)"
  teardown
}

test_next_serial_takes_the_highest_not_the_count() {
  setup
  ns_repo
  # Contiguity is BRIEFS-8's business. This program answers from the maximum, so a gap must
  # not hand back a serial that something already used.
  ns_brief "$REPO" 0009-ninth
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm gap
  run_next
  [ "$(next_said)" = "0010" ] || fail "expected 0010 past a gap, got $(next_said)"
  teardown
}
