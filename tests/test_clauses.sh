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

# Glob expansion happens in the *validator's* working directory, not the harness's. A test
# about globbing that runs from the repository root asks the question somewhere the decoys
# do not exist, and passes whatever the code does.
cl_run_from() {
  CL_OUT="$(cd "$1" && bash "$REPO_ROOT/tools/validate-briefs.sh" "$CL_DIR" 2>&1)"
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
  out="$(bash "$REPO_ROOT/tools/validate-briefs.sh" "$REPO_ROOT/docs/blc/briefs" 2>&1)"
  case "$out" in
    *"BRIEFS-9"*) fail "BRIEFS-9 complains about a ledger already in this repository:
$out" ;;
    *"BRIEFS-10"*) fail "BRIEFS-10 complains about a ledger already in this repository:
$out" ;;
  esac
}

# The test the report asked for. A ledger whose phase table backticks its ids is a ledger a
# person reads without trouble, and BRIEFS-9 used to call every phase in it missing from its
# own table. Two contributors rewrote correct ledgers into a different correct shape because
# the gate said so (#0031).
test_clauses_briefs9_reads_a_backticked_phase_table() {
  cl_repo backtick
  cl_brief 0001 ticked -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 in-progress a:done b:pending`' \
    '' \
    '| id | label | status |' \
    '|---|---|---|' \
    '| `a` | the first | done |' \
    '| ~~`b`~~ | the dropped one | pending |'
  cl_run

  case "$CL_OUT" in
    *"BRIEFS-9"*) fail "BRIEFS-9 called a backticked phase table unfindable:
$CL_OUT" ;;
  esac
  cl_assert_clean_gate "BRIEFS-9"
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

# A timestamp is digits followed by colons, which is the shape of a phase token. The first
# version of the parser accepted any token with a colon somewhere after a digit and turned
# `2026-01-01T00:00:00Z` into the phase id `2026-01-01T00`. Unreachable with today's status
# line, and pinned anyway: the clause is published, and a published clause is expensive to
# correct.
test_clauses_briefs9_rejects_a_timestamp_shaped_token() {
  cl_repo stamped
  cl_brief 0001 stamped -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 done 2026-01-01T00:00:00Z a:done`' \
    '' '| a | thing | done |'
  cl_run
  case "$CL_OUT" in
    *"2026"*) fail "a timestamp was parsed as a phase id:
$CL_OUT" ;;
  esac
  cl_assert_clean_gate "timestamp token"
}

# The three shapes #0013 left unmatched. BRIEFS-9 used to report them, and that was correct
# while they were unmatched: a row no reader could find is a row that may as well not be there,
# and reporting it was better than passing it in silence.
#
# #0031 made the readers find them, which removes the thing worth reporting. The clause now has
# to stay quiet, or it accuses a ledger of hiding a phase that every reader can see — which is
# how a real project came to rewrite two legible ledgers into a different legible shape.
#
# This test is the inverse of the one it replaces. Both pin the same three rows; what changed
# is whether the toolkit can read them.
test_clauses_briefs9_is_silent_on_the_three_shapes_0013_left_unmatched() {
  cl_repo shapes
  cl_brief 0001 shapes -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 done a:done b:done c:done`' \
    '' '| `a` | one | done |' '| ~~b~~ | two | done |' '| ~~`c`~~ | three | done |'
  cl_run
  local id
  for id in a b c; do
    case "$CL_OUT" in
      *"declares phase '$id'"*) fail "BRIEFS-9 still calls the '$id' row shape unfindable:
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
  # docs/blc/briefs to be where it actually is.
  local root="$TMP/clauses/agree"
  rm -rf "$root"
  CL_DIR="$root/docs/blc/briefs"
  mkdir -p "$CL_DIR"
  # Two phases: `a` has a row, `q` deliberately does not. `q` is what makes the gate's
  # assertion positive — a validator that reads this line MUST complain about `q`, so a
  # validator that reads nothing at all fails here instead of passing quietly.
  cl_brief 0001 shape -- \
    '# Ledger — #0001 A title' \
    '' '```' '`blc/2 #9999 done z:done`' '```' '' \
    '`blc/2 #0001 in-progress a:in-progress(feature/x) q:pending`' \
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
  open_out="$(cd "$root" && bash tools/open-briefs.sh docs/blc/briefs 2>&1)"; open_rc=$?
  list_out="$(cd "$root" && bash tools/list-briefs.sh docs/blc/briefs 2>&1)"; list_rc=$?
  val_out="$(cd "$root" && bash tools/validate-briefs.sh docs/blc/briefs 2>&1)"; val_rc=$?

  [ "$open_rc" -eq 0 ] || fail "open-briefs exited $open_rc"
  [ "$list_rc" -eq 0 ] || fail "list-briefs exited $list_rc"
  # 0, not merely "not 1": BRIEFS-9 fires on `q` here, and a [judgment] must never block.
  [ "$val_rc" -eq 0 ] || fail "validate-briefs exited $val_rc — a judgment blocked the run"

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

  # The gate, asserted positively and in both directions.
  #
  # The first version of this checked only that `BRIEFS-9` was absent, which is the absence
  # check the comment above this test forbids — and review proved the cost: giving the
  # validator a rebuilt positional locator that returns nothing left all 327 tests green
  # while BRIEFS-9 was dead on every ledger in existence. The fourth un-failable guard in
  # this brief, in the test written to prevent the third.
  #
  # So the gate must name `q`, which exists only in the real line. A validator reading the
  # decoy looks for `z`; a validator reading nothing looks for nothing. Both fail here.
  case "$val_out" in
    *"declares phase 'q'"*) ;;
    *) fail "validate-briefs did not report the unfindable phase q — it is not reading the real status line:
$val_out" ;;
  esac
  case "$val_out" in
    *"declares phase 'a'"*) fail "validate-briefs cannot find the row for phase a, which exists:
$val_out" ;;
    *"'z'"*) fail "validate-briefs took the decoy — it is looking for phase z:
$val_out" ;;
  esac

  # No reader may surface the decoy's serial.
  case "$open_out$list_out$val_out" in
    *9999*) fail "a reader surfaced the decoy serial #9999" ;;
  esac
}

# ── The tokenizer is shared, and these are the shapes that prove it ──────────
#
# Single-letter ids cannot prove it. The gate's private filter and the reporter's `*:*`
# test give the same answer on `a`, `b`, `z` — which is the phase `b` lesson verbatim: a
# corpus both readers already agree on can never show they differ. `bc` is the shape that
# separated them, and `2026-…` is the one that separated them in the other direction.
cl_three_tool_repo() {
  CL_ROOT="$TMP/clauses/$1"
  rm -rf "$CL_ROOT"
  CL_DIR="$CL_ROOT/docs/blc/briefs"
  mkdir -p "$CL_DIR"
  shift
  cl_brief 0001 tok -- "$@"
  git -C "$CL_ROOT" init -q -b main
  git -C "$CL_ROOT" config user.email t@example.com
  git -C "$CL_ROOT" config user.name Test
  fixture_install_tool "$CL_ROOT" open-briefs.sh
  fixture_install_tool "$CL_ROOT" validate-briefs.sh
  git -C "$CL_ROOT" add -A
  git -C "$CL_ROOT" commit -qm fixture >/dev/null 2>&1
}

# A multi-letter id is not a phase index — `docs/blc/briefs/README.md` says a phase has one id
# and the index is a letter. Before the tokenizer was shared, open-briefs.sh followed `bc`
# as a live phase while the gate did not see it at all.
test_clauses_the_gate_and_the_reporter_agree_on_a_multi_letter_id() {
  cl_three_tool_repo multiletter \
    '# Ledger — #0001' \
    '`blc/2 #0001 in-progress bc:in-progress(feature/x)`' \
    '' '| a | thing | done |'

  local open_out val_out
  open_out="$(cd "$CL_ROOT" && bash tools/open-briefs.sh docs/blc/briefs 2>&1)"
  val_out="$(cd "$CL_ROOT" && bash tools/validate-briefs.sh docs/blc/briefs 2>&1)"

  # Neither may treat `bc` as a phase to follow.
  case "$open_out" in
    *"phase bc"*) fail "open-briefs followed 'bc' as a phase; the gate does not:
$open_out" ;;
  esac
  # And it must not vanish from the record entirely — the gate says so out loud.
  case "$val_out" in
    *"bc:in-progress(feature/x)"*) ;;
    *) fail "nothing reported 'bc' at all — a phase in the record that no reader looks for:
$val_out" ;;
  esac
  cl_assert_gate_clean_rc "$CL_ROOT"
}

test_clauses_the_gate_and_the_reporter_agree_on_a_timestamp() {
  cl_three_tool_repo stamp \
    '# Ledger — #0001' \
    '`blc/2 #0001 in-progress 2026-01-01T00:00:00Z a:in-progress(feature/x)`' \
    '' '| a | thing | in-progress |'

  local open_out val_out
  open_out="$(cd "$CL_ROOT" && bash tools/open-briefs.sh docs/blc/briefs 2>&1)"
  val_out="$(cd "$CL_ROOT" && bash tools/validate-briefs.sh docs/blc/briefs 2>&1)"
  case "$open_out" in
    *"phase 2026"*) fail "open-briefs parsed a timestamp as a phase:
$open_out" ;;
  esac
  case "$val_out" in
    *"declares phase '2026"*) fail "the gate parsed a timestamp as a phase:
$val_out" ;;
  esac
}

cl_assert_gate_clean_rc() {
  local rc
  ( cd "$1" && bash tools/validate-briefs.sh docs/blc/briefs >/dev/null 2>&1 ); rc=$?
  [ "$rc" -eq 0 ] || fail "a [judgment] blocked the run (exit $rc)"
}

# A status line is data from a file this toolkit did not write, and `for token in $1` globs.
# With files named `q:done` and `z:pending` in the working directory, a bare `*` in a status
# line made the gate report two phases the ledger never mentions.
test_clauses_a_status_line_does_not_glob_the_working_directory() {
  cl_repo globby
  cl_brief 0001 globby -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 in-progress a:done *`' \
    '' '| a | thing | done |'
  local yard="$TMP/clauses/globby-cwd"
  rm -rf "$yard"; mkdir -p "$yard"
  # Two shapes of decoy, because two functions read the same expanded tokens and each
  # discards what the other reports. `q:`/`z:` are valid indices, so only the phase-entry
  # path can name them; `bc:` is a multi-letter id, so only the unparsed-entry path can.
  # A yard holding indices alone leaves the second function's `set -f` untestable.
  ( cd "$yard" && : > 'q:done' && : > 'z:pending' && : > 'bc:done' ) 2>/dev/null \
    || { skip "cannot create colon-named files"; return; }
  # The decoys must be findable by the pattern, or the test proves nothing.
  [ -e "$yard/q:done" ] || fail "the decoy file was not created — the test cannot detect globbing"
  [ -e "$yard/bc:done" ] || fail "the multi-letter decoy was not created — the test covers one function only"

  cl_run_from "$yard"
  case "$CL_OUT" in
    *"phase 'q'"*|*"phase 'z'"*) fail "a filename in the working directory became a phase id:
$CL_OUT" ;;
  esac
  case "$CL_OUT" in
    *"'bc:done'"*) fail "a filename in the working directory became an unparsed phase entry:
$CL_OUT" ;;
  esac
  # Positive control: the run must have reached the clause at all.
  case "$CL_OUT" in
    *"11 clauses decided"*) ;;
    *) fail "validate-briefs did not complete — the glob check never ran:
$CL_OUT" ;;
  esac
}

# ── BRIEFS-10 and the two structures that read each other ────────────────────

# Review raised the converse of the test below — a `---` inside a fence closing the
# frontmatter — as a defect. It is not one, and this test pins the decision rather than the
# behaviour drifting back.
#
# Frontmatter runs from the opening `---` to the next `---`, which is what every markdown
# tool does. Its interior is YAML, so the fence in this fixture never opened, and the `---`
# that follows is simply the closing delimiter. Reporting this file as having unterminated
# frontmatter would mean inventing a document shape no parser agrees with us about — and
# `BRIEFS-10` is a clause other repositories will be measured by.
#
# The genuinely unterminated case, `---` on line 1 and no other, is covered above and does
# complain.
test_clauses_briefs10_frontmatter_ends_at_the_first_closing_marker() {
  cl_repo fmfence
  # Frontmatter closes on line 3. The `---` further down is inside a closed fence and must
  # not re-enter or re-open anything; the fence itself is balanced. Nothing to complain of.
  cl_brief 0001 fmfence -- \
    '---' 'title: x' '---' '' '# Ledger' '`blc/2 #0001 done a:done`' '' \
    '```' '---' '```' '' '| a | t | done |'
  cl_run
  case "$CL_OUT" in
    *"BRIEFS-10"*) fail "a well-formed ledger drew a BRIEFS-10 complaint:
$CL_OUT" ;;
  esac
}

# The mirror: a fence delimiter inside a YAML block scalar is not a fence. Treating it as
# one drew a false complaint about a legal ledger, and made the locator fall back.
test_clauses_briefs10_a_fence_inside_frontmatter_is_not_a_fence() {
  cl_repo fencefm
  cl_brief 0001 fencefm -- \
    '---' 'example: |' '  ```' '  code' '---' '' '# Ledger' \
    '`blc/2 #0001 done a:done`' '' '| a | t | done |'
  cl_run
  case "$CL_OUT" in
    *"BRIEFS-10"*) fail "a fence delimiter inside frontmatter was read as an open fence:
$CL_OUT" ;;
  esac
}

# ── The validator is a reader, not a re-deriver ──────────────────────────────

# The three copies of the symlink walk must stay identical.
#
# The duplication is deliberate — it is the code that finds the shared code, so it cannot be
# shared — but complication 10 records that the copies drifted in the very commit that
# created the second one, and that nobody noticed. The third arrived in this phase with the
# same exposure and nothing holding it: `assert_loads_library` checks the load list below
# the walk, and says nothing about the walk itself.
#
# Only the walk is compared. The exit status differs per tool by documented intent, and the
# library list differs because the tools need different libraries.
cl_extract_walk() {
  sed -n '/^BLC_SELF=/,/^BLC_LIB_DIR=/p' "$REPO_ROOT/tools/$1" | grep -v '^ *exit '
}

test_clauses_the_bootstrap_walks_are_identical() {
  local ob lb vb jc
  ob="$(cl_extract_walk open-briefs.sh)"
  lb="$(cl_extract_walk list-briefs.sh)"
  vb="$(cl_extract_walk validate-briefs.sh)"
  jc="$(cl_extract_walk jira-csv.sh)"

  [ -n "$ob" ] || fail "could not extract the symlink walk from open-briefs.sh"
  # A comparison of two empty strings succeeds. Prove the extraction found something.
  case "$ob" in
    *readlink*) ;;
    *) fail "the extracted walk does not contain readlink — the extractor is broken" ;;
  esac

  [ "$ob" = "$lb" ] || fail "open-briefs.sh and list-briefs.sh symlink walks have drifted:
$(diff <(printf '%s\n' "$ob") <(printf '%s\n' "$lb") || true)"
  [ "$ob" = "$vb" ] || fail "open-briefs.sh and validate-briefs.sh symlink walks have drifted:
$(diff <(printf '%s\n' "$ob") <(printf '%s\n' "$vb") || true)"
  [ "$ob" = "$jc" ] || fail "open-briefs.sh and jira-csv.sh symlink walks have drifted:
$(diff <(printf '%s\n' "$ob") <(printf '%s\n' "$jc") || true)"
}

# The unknown-field guard exists so a typo cannot silently answer "no", which would read as
# a clean ledger. Without a test the guard is itself the untested thing.
# v1.2 states the boundary of BRIEFS-9 positively: an id mixing letters and digits, an
# uppercase id, and a timestamp are silent, and `bc:`-shaped ids are reported. A Contract
# that claims a silence nobody tests is the drift #0014 exists to close, so the claim is
# pinned here in the same shape the clause states it.
test_clauses_briefs9_reports_exactly_the_shapes_the_contract_names() {
  cl_repo boundary
  cl_brief 0001 boundary -- \
    '# Ledger — #0001 boundary' \
    '`blc/2 #0001 in-progress a:done 2026-01-01T00:00:00Z A1:done a1:done bc:done`' \
    '' '| a | thing | done |'
  cl_run

  # Reported: the one shape the clause names as unparsable.
  case "$CL_OUT" in
    *"'bc:done'"*) ;;
    *) fail "BRIEFS-9 did not report 'bc:done', which v1.2 names as reported:
$CL_OUT" ;;
  esac

  # Silent: the three shapes v1.2 names as not phase entries at all.
  local shape
  for shape in '2026-01-01T00' 'A1' 'a1'; do
    case "$CL_OUT" in
      *"'$shape"*) fail "BRIEFS-9 reported '$shape', which v1.2 states is silent:
$CL_OUT" ;;
    esac
  done
}

# docs/blc/contracts/README.md, promotion criterion 3, states that criterion 3 is unmet for every
# [judgment] in this repository. That is a claim about the present, and the present moves. If
# a ledger here ever produces a judgment, the claim goes false and the sentence needs
# rewriting — which is the failure mode this whole brief exists to stop.
#
# A judgment appearing is legitimate and must not fail the build. This test does not fail the
# build either; it fails the *suite*, which is the right place to say "a written sentence no
# longer matches the tree".
#
# It holds one half of the sentence. A standing judgment is detected. The other half is not
# mechanical: if a judgment fires on a real ledger, someone examines it, judges it correct and
# repairs the ledger, criterion 3 is met and the count returns to zero with this test green.
# Recording which half, because this brief has six guards named for properties they did not
# check, and an unstated half is how the seventh got written.
test_clauses_the_promotion_criteria_still_describe_this_repository() {
  local out
  out="$(cd "$REPO_ROOT" && bash tools/validate-briefs.sh docs/blc/briefs 2>&1)"

  # Positive control: the run must have reached the clauses at all.
  case "$out" in
    *"clauses decided"*) ;;
    *) fail "validate-briefs did not complete, or the summary changed shape — this test proves nothing:
$out" ;;
  esac

  # This asserted `, 0 judgment(s)` until BRIEFS-11, which reports sixteen ledgers here and
  # made criterion 3 met for exactly one clause. The guard did its job then — it caught the
  # prose going stale in the same run that made it stale — and the question it asks has to
  # change with the answer rather than be deleted.
  #
  # It now reads which clauses fire rather than how many findings they produce. A count
  # would have to be edited by whoever closes the next brief, for a reason that has nothing
  # to do with them. A clause id appearing here means the README's list of what criterion 3
  # is unmet for is wrong, which is the thing worth catching.
  local firing
  firing="$(printf '%s\n' "$out" | sed -n 's/^\(BRIEFS-[0-9]*\) \[judgment\].*/\1/p' | sort -u | paste -sd' ')"
  [ "$firing" = "BRIEFS-11" ] \
    || fail "the clauses producing judgments in this repository are now '$firing', not
'BRIEFS-11'. Promotion criterion 3 in docs/blc/contracts/README.md names which clauses it is
unmet for. Update that list, then update this test:
$out"
}

test_clauses_an_unknown_scan_field_is_refused() {
  local rc=0
  ( . "$REPO_ROOT/tools/lib/status-line.sh" && blc_scan_field bogus </dev/null ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] || fail "blc_scan_field accepted an unknown field name (exit $rc, wanted 2)"

  # Positive control: a real field must still be accepted, or the guard is refusing everything.
  rc=0
  ( . "$REPO_ROOT/tools/lib/status-line.sh" && blc_scan_field status </dev/null ) >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 0 ] || fail "blc_scan_field refused a known field name (exit $rc)"
}

test_clauses_validate_briefs_loads_both_libraries() {
  assert_loads_library validate-briefs.sh phase-row
  assert_loads_library validate-briefs.sh status-line
}

test_clauses_validate_briefs_runs_through_a_symlink() {
  local linkdir="$TMP/vbin"
  mkdir -p "$linkdir"
  ln -s "$REPO_ROOT/tools/validate-briefs.sh" "$linkdir/validate-briefs.sh"
  local out
  out="$(cd "$REPO_ROOT" && bash "$linkdir/validate-briefs.sh" docs/blc/briefs 2>&1)"
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
  out="$(cd "$sandbox" && bash tools/validate-briefs.sh docs/blc/briefs 2>&1)"; rc=$?
  [ "$rc" -eq 2 ] || fail "a missing library exited $rc, not 2"
  case "$out" in
    *"cannot read"*) ;;
    *) fail "a missing library produced no explanation: $out" ;;
  esac
  case "$out" in
    *"0 defect"*) fail "a validator that could not load its checks reported a clean tree" ;;
  esac
}

# ── BRIEFS-11 — a closed brief records when it closed ────────────────────────
#
# The clause reads the status line, not the `**Status:**` field. Both say whether a brief
# is closed and the ledgers carry both, so one had to be chosen: the status line is the
# machine-readable statement every tool here already parses, and all 32 closed ledgers
# carry one. Reading the prose field instead would have made the gate the only tool in
# the repository that answers "is this closed?" from a different place.

test_clauses_briefs11_reports_a_closed_brief_with_no_date() {
  cl_repo nodate
  cl_brief 0001 finished -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 done a:done(PR#1)`' \
    '' \
    '| id | label | status |' \
    '|---|---|---|' \
    '| a | the only phase | done |'
  cl_run

  case "$CL_OUT" in
    *"BRIEFS-11"*) ;;
    *) fail "BRIEFS-11 did not report a closed brief with no Closed: date
$CL_OUT" ;;
  esac
  cl_assert_clean_gate "BRIEFS-11"
}

test_clauses_briefs11_is_silent_when_the_date_is_there() {
  cl_repo dated
  cl_brief 0001 finished -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 done a:done(PR#1)`' \
    '' \
    '**Closed:** 2026-01-02' \
    '' \
    '| id | label | status |' \
    '|---|---|---|' \
    '| a | the only phase | done |'
  cl_run

  case "$CL_OUT" in
    *"BRIEFS-11"*) fail "BRIEFS-11 complained about a ledger that records its close:
$CL_OUT" ;;
  esac
}

# The clause asks only closed briefs. An open one has no date to carry yet, and asking for
# one would report every brief in flight — which is how a judgment stops being read.
test_clauses_briefs11_does_not_ask_an_open_brief_for_a_date() {
  cl_repo stillopen
  cl_brief 0001 running -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 in-progress a:in-progress(brief/0001-a-x)`' \
    '' \
    '| id | label | status |' \
    '|---|---|---|' \
    '| a | the only phase | in-progress |'
  cl_run

  case "$CL_OUT" in
    *"BRIEFS-11"*) fail "BRIEFS-11 asked an unfinished brief for a Closed: date
$CL_OUT" ;;
  esac
}

# `done(commit 92a7168)` is a real status in this repository — #0001 — and the pointer
# holds a space. A reader taking the third whitespace-separated field gets `done(commit`
# and matches nothing, so the oldest closed briefs would go unreported by a clause written
# to find exactly them.
test_clauses_briefs11_reads_a_state_whose_pointer_holds_a_space() {
  cl_repo spacey
  cl_brief 0001 ancient -- \
    '# Ledger — #0001' \
    '`blc/1 #0001 done(commit 92a7168)`'
  cl_run

  case "$CL_OUT" in
    *"BRIEFS-11"*) ;;
    *) fail "BRIEFS-11 did not read a state whose pointer contains a space
$CL_OUT" ;;
  esac
}

# A ledger that shows the field in a fenced example is documenting the format, not recording
# its own close. The clause reads the shared scan, which skips fences once for every clause
# that reads a ledger, rather than grepping the raw file. The first version did grep, and
# this fixture passed it silently — found in review, before any ledger here did it, which is
# how the same fault was caught on the status line.
test_clauses_briefs11_does_not_read_a_fenced_example_as_a_close() {
  cl_repo fenced
  cl_brief 0001 documented -- \
    '# Ledger — #0001' \
    '`blc/2 #0001 done a:done(PR#1)`' \
    '' \
    'A closed ledger shows the field like this:' \
    '' \
    '```' \
    '**Closed:** 2026-01-02' \
    '```'
  cl_run

  case "$CL_OUT" in
    *"BRIEFS-11"*) ;;
    *) fail "a fenced example of the field was read as the ledger's own close
$CL_OUT" ;;
  esac
}

# The same question for the other region the scan skips. Frontmatter is YAML, so a key that
# looks like the field is a string in a config block, not a statement about this brief.
test_clauses_briefs11_does_not_read_frontmatter_as_a_close() {
  cl_repo fmclose
  cl_brief 0001 fronted -- \
    '---' \
    '**Closed:** 2026-01-02' \
    '---' \
    '# Ledger — #0001' \
    '`blc/2 #0001 done a:done(PR#1)`'
  cl_run

  case "$CL_OUT" in
    *"BRIEFS-11"*) ;;
    *) fail "a frontmatter key was read as the ledger's own close
$CL_OUT" ;;
  esac
}
