#!/usr/bin/env bash
# BRIEFS-9 and BRIEFS-10 — #0014 phase c.
#
# Both clauses are [judgment]. The assertion that matters most in this file is not that
# they fire; it is that firing them leaves the exit status at zero. A judgment promoted to
# a defect by accident breaks the build of every repository that installs this toolkit, on
# the day they upgrade, for a ledger that was legal when they wrote it.
#
# Helpers are prefixed `CL_` / `cl_`. run.sh sources every test file into one shell, and an
# unprefixed helper is one collision away from being replaced by whichever file is read
# last — which is how tests/test_brief_checks.sh silently ran against the wrong fixtures.

cl_repo() {
  CL_DIR="$TMP/clauses/$1"
  rm -rf "$CL_DIR"
  mkdir -p "$CL_DIR"
}

# usage: cl_brief <serial> <slug> -- <ledger lines...>
# Writes a brief.md that satisfies BRIEFS-1..7, so anything reported is ours.
cl_brief() {
  local serial="$1" slug="$2"; shift 3
  local d="$CL_DIR/$serial-$slug"
  mkdir -p "$d"
  printf '# Brief %s\n\n**Serial:** #%s · **Created:** 2026-01-01T00:00:00Z · **Author:** t@e.com · **Depends on:** —\n' \
    "$slug" "$serial" > "$d/brief.md"
  [ "$#" -eq 0 ] || printf '%s\n' "$@" > "$d/ledger.md"
}

cl_run() {
  CL_OUT="$(bash "$REPO_ROOT/tools/validate-briefs.sh" "$CL_DIR" 2>&1)"
  CL_RC=$?
}

cl_assert_clean_gate() {
  [ "$CL_RC" -eq 0 ] \
    || fail "$1: a [judgment] blocked the build (exit $CL_RC) — it must only complain
$CL_OUT"
}

# ── The property the whole phase turns on ────────────────────────────────────

test_clauses_judgments_never_block() {
  cl_repo neverblock
  cl_brief 0001 broken -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 in-progress a:done z:pending`' \
    '' '| a | thing | done |'
  cl_run

  case "$CL_OUT" in
    *"BRIEFS-9"*) ;;
    *) fail "BRIEFS-9 did not fire on a phase id with no row" ;;
  esac
  cl_assert_clean_gate "BRIEFS-9"
}

test_clauses_a_malformed_ledger_does_not_block_either() {
  cl_repo mal
  cl_brief 0001 fm -- '---' 'title: x' '' '# Ledger' '`blc/2 #0001 done a:done`' '' '| a | t | done |'
  cl_brief 0002 fence -- '# Ledger' '`blc/2 #0002 done a:done`' '' '| a | t | done |' '' '```' 'unclosed'
  cl_run

  case "$CL_OUT" in
    *"BRIEFS-10"*"frontmatter"*) ;;
    *) fail "BRIEFS-10 did not report unterminated frontmatter" ;;
  esac
  case "$CL_OUT" in
    *"BRIEFS-10"*"code fence"*) ;;
    *) fail "BRIEFS-10 did not report an unclosed fence" ;;
  esac
  cl_assert_clean_gate "BRIEFS-10"
}

# ── BRIEFS-9 ─────────────────────────────────────────────────────────────────

test_clauses_briefs9_passes_every_ledger_in_this_repository() {
  # The brief promises it. Asserted against the real tree rather than a fixture, because
  # the promise is about this tree.
  local out
  out="$(bash "$REPO_ROOT/tools/validate-briefs.sh" "$REPO_ROOT/docs/briefs" 2>&1)"
  case "$out" in
    *"BRIEFS-9"*) fail "BRIEFS-9 complains about a ledger already in this repository:
$out" ;;
    *"BRIEFS-10"*) fail "BRIEFS-10 complains about a ledger already in this repository:
$out" ;;
  esac
}

# Both index alphabets. Six ledgers here still number their phases, and a clause that only
# understood letters would report every one of them as unfindable.
test_clauses_briefs9_reads_numbered_phases() {
  cl_repo numbered
  cl_brief 0001 old -- \
    '# Ledger — #0001' \
    '`blc/1 #0001 done(PR#9) 1:done(PR#9) 2:done(PR#10)`' \
    '' '| phase 1 — the thing | done |' '| phase 2 — the other | done |'
  cl_run
  case "$CL_OUT" in
    *"BRIEFS-9"*) fail "a numbered ledger was reported unfindable:
$CL_OUT" ;;
  esac
}

# #0001's brief status is `done(commit 92a7168)` — a token containing a space. Splitting
# the status line on whitespace alone yields `done(commit` and `92a7168)`, and a parser that
# treated those as phase ids would report two phantom phases on the oldest ledger here.
test_clauses_briefs9_ignores_a_brief_status_containing_a_space() {
  cl_repo spacey
  cl_brief 0001 spacey -- \
    '# Ledger — #0001' \
    '`blc/1 #0001 done(commit 92a7168)`' \
    '' 'No phase table at all.'
  cl_run
  case "$CL_OUT" in
    *"BRIEFS-9"*) fail "a brief status containing a space was parsed as a phase id:
$CL_OUT" ;;
  esac
}

# The gap #0013 left open, and the reason this clause exists. These three row shapes match
# no pattern, so before BRIEFS-9 a ledger using them reported clean while its phases were
# invisible to every reader.
test_clauses_briefs9_catches_the_three_shapes_0013_left_silent() {
  cl_repo shapes
  cl_brief 0001 shapes -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 done a:done b:done c:done`' \
    '' '| `a` | one | done |' '| ~~b~~ | two | done |' '| ~~`c`~~ | three | done |'
  cl_run
  local id
  for id in a b c; do
    case "$CL_OUT" in
      *"declares phase '$id'"*) ;;
      *) fail "BRIEFS-9 stayed silent on the '$id' row shape — the #0013 gap is still open:
$CL_OUT" ;;
    esac
  done
  cl_assert_clean_gate "the three shapes"
}

test_clauses_briefs9_skips_a_brief_that_has_not_been_started() {
  # #0007 is filed with no ledger. These are the first clauses to read ledger.md, so the
  # absent case is theirs to skip rather than report.
  cl_repo unstarted
  cl_brief 0001 filed --
  cl_run
  case "$CL_OUT" in
    *"BRIEFS-9"*|*"BRIEFS-10"*) fail "a brief with no ledger was reported:
$CL_OUT" ;;
  esac
  cl_assert_clean_gate "no ledger"
}

# ── The agreement test ───────────────────────────────────────────────────────
#
# The third reader joins two that already exist, and this is the fourth attempt at an
# agreement test in this brief. The first three could not fail: an ERE that matched nothing
# (phase a), a comparison that discarded one side, and a pair of private expectations that
# never compared anything (phase b, twice).
#
# What was learned, applied here from the start:
#   - assert positively; an absence check passes on silence, on a crash, and on an empty file
#   - plant a decoy, so a divergent reader returns something specific and wrong rather than
#     nothing, and every reader has a way to be caught disagreeing
#   - check exit status, because a tool that dies emits no bad substring
#
# The decoy is a `#9999 done` status line inside a fence, above the real one. A reader that
# skips fences finds `#0001 in-progress` with phase `a`; a reader that does not finds `#9999`
# with phase `z`. Each of the three tools says so in its own vocabulary.
test_clauses_all_three_readers_agree_on_one_ledger() {
  # A real repository layout, because two of the three readers want git and all three want
  # docs/briefs to be where it actually is.
  local root="$TMP/clauses/agree"
  rm -rf "$root"
  CL_DIR="$root/docs/briefs"
  mkdir -p "$CL_DIR"
  cl_brief 0001 shape -- \
    '# Ledger — #0001 A title' \
    '' '```' '`blc/2 #9999 done z:done`' '```' '' \
    '`blc/2 #0001 in-progress a:in-progress(feature/x)`' \
    '' '| a | the thing | in-progress |'

  git -C "$root" init -q -b main
  git -C "$root" config user.email t@example.com
  git -C "$root" config user.name Test
  fixture_install_tool "$root" open-briefs.sh
  fixture_install_tool "$root" list-briefs.sh
  fixture_install_tool "$root" validate-briefs.sh
  git -C "$root" add -A
  git -C "$root" commit -qm fixture >/dev/null 2>&1

  local open_out list_out val_out open_rc list_rc val_rc
  open_out="$(cd "$root" && bash tools/open-briefs.sh docs/briefs 2>&1)"; open_rc=$?
  list_out="$(cd "$root" && bash tools/list-briefs.sh docs/briefs 2>&1)"; list_rc=$?
  val_out="$(cd "$root" && bash tools/validate-briefs.sh docs/briefs 2>&1)"; val_rc=$?

  [ "$open_rc" -eq 0 ] || fail "open-briefs exited $open_rc"
  [ "$list_rc" -eq 0 ] || fail "list-briefs exited $list_rc"
  [ "$val_rc" -eq 0 ] || fail "validate-briefs exited $val_rc on a ledger with no defect"

  # The reporter: names the brief as open, on phase a.
  case "$open_out" in
    *"[no-line]"*)    fail "open-briefs found no status line" ;;
    *"Nothing open"*) fail "open-briefs took the decoy — it thinks #0001 is done" ;;
    *0001-shape*)     ;;
    *)                fail "open-briefs did not report #0001" ;;
  esac

  # The timeline: in-progress, not done.
  case "$list_out" in
    *"| #0001 "*"in-progress"*) ;;
    *"| #0001 "*"done"*) fail "list-briefs took the decoy — it says done" ;;
    *) fail "list-briefs did not read #0001 as in-progress" ;;
  esac

  # The gate: silent, because phase `a` is findable. Had it taken the decoy it would be
  # looking for phase `z`, find no row, and complain.
  case "$val_out" in
    *"BRIEFS-9"*) fail "validate-briefs took the decoy — it is looking for the wrong phase:
$val_out" ;;
  esac

  # No reader may surface the decoy's serial.
  case "$open_out$list_out$val_out" in
    *9999*) fail "a reader surfaced the decoy serial #9999" ;;
  esac
}

# ── The validator is a reader, not a re-deriver ──────────────────────────────

test_clauses_validate_briefs_loads_both_libraries() {
  assert_loads_library validate-briefs.sh phase-row
  assert_loads_library validate-briefs.sh status-line
}

test_clauses_validate_briefs_runs_through_a_symlink() {
  local linkdir="$TMP/vbin"
  mkdir -p "$linkdir"
  ln -s "$REPO_ROOT/tools/validate-briefs.sh" "$linkdir/validate-briefs.sh"
  local out
  out="$(cd "$REPO_ROOT" && bash "$linkdir/validate-briefs.sh" docs/briefs 2>&1)"
  [ $? -ne 2 ] || fail "validate-briefs could not find its library through a symlink"
  case "$out" in
    *"cannot read"*) fail "validate-briefs looked for lib/ beside the link" ;;
    *"clauses decided"*) ;;
    *) fail "validate-briefs printed no summary through a symlink" ;;
  esac
}

# A missing library must stop the run, not produce a clean report. An exit-0 "0 defects"
# from a validator that could not load its checks is the worst output it could give.
test_clauses_a_missing_library_refuses_to_report_a_clean_tree() {
  local sandbox="$TMP/vnolib"
  rm -rf "$sandbox"
  mkdir -p "$sandbox/tools/lib"
  cp "$REPO_ROOT/tools/validate-briefs.sh" "$sandbox/tools/"
  cp "$REPO_ROOT/tools/lib/phase-row.sh" "$sandbox/tools/lib/"
  # status-line.sh deliberately absent.
  cp -r "$REPO_ROOT/docs" "$sandbox/docs"

  local out rc
  out="$(cd "$sandbox" && bash tools/validate-briefs.sh docs/briefs 2>&1)"; rc=$?
  [ "$rc" -eq 2 ] || fail "a missing library exited $rc, not 2"
  case "$out" in
    *"cannot read"*) ;;
    *) fail "a missing library produced no explanation: $out" ;;
  esac
  case "$out" in
    *"0 defect"*) fail "a validator that could not load its checks reported a clean tree" ;;
  esac
}
