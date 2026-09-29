# The awk matrix (#0015 phase a).
#
# These tests are about the runner rather than about a tool, which makes them the one place in
# the suite that could test itself into a circle. They do not run the matrix: they run only
# `tests/run.sh --interpreters`, which discovers and exits. Discovery is written with shell
# builtins and the candidate binaries alone, so a test can hand it a PATH it built and get an
# answer about that PATH rather than about the machine it happens to run on.
#
# That property is what makes "not found" testable at all. A test that asserted "busybox is
# reported missing" would be asserting a fact about this laptop, and would turn into a false
# failure on a machine that has busybox.

IN_CANDIDATES="awk gawk mawk original-awk busybox"

# A directory holding fake awks, named as given. Each reports a version that identifies it, so
# a test can tell which binary discovery actually reached.
in_yard() {
  local yard="$TMP/interp/$1"; shift
  rm -rf "$yard"; mkdir -p "$yard"
  local name
  for name in "$@"; do
    printf '#!/bin/sh\ncase "$1" in --version) echo "STUB %s 9.9";; esac\nexit 0\n' "$name" \
      > "$yard/$name"
    chmod +x "$yard/$name"
  done
  printf '%s' "$yard"
}

# bash is invoked by absolute path so PATH can hold nothing but the yard. If bash came from
# PATH the test could not remove the machine's real awks, and every assertion below would be
# about this laptop instead of about the directory the test built.
IN_BASH="$(command -v bash)"

in_discover() { PATH="$1" "$IN_BASH" "$REPO_ROOT/tests/run.sh" --interpreters 2>&1; }
in_plan()     { PATH="$1" "$IN_BASH" "$REPO_ROOT/tests/run.sh" --matrix-plan 2>&1; }

test_interpreters_every_candidate_is_reported_either_way() {
  local yard out count
  yard="$(in_yard empty)"
  out="$(in_discover "$yard")"

  # Silence is the failure this whole phase is about. Every candidate gets a line.
  local name
  for name in $IN_CANDIDATES; do
    case "$out" in
      *"$name"*) ;;
      *) fail "discovery said nothing at all about '$name':
$out" ;;
    esac
  done

  # Derived, not a literal: a sixth candidate should need one edit, not two with a red suite
  # in between.
  local want=0
  for name in $IN_CANDIDATES; do want=$((want + 1)); done
  count="$(printf '%s\n' "$out" | grep -c .)"
  [ "$count" -eq "$want" ] || fail "expected one line per candidate ($want), got $count:
$out"
}

test_interpreters_an_absent_awk_is_named_not_a_silence() {
  local yard out
  yard="$(in_yard empty)"
  out="$(in_discover "$yard")"
  case "$out" in
    *"mawk"*"not-found"*) ;;
    *) fail "an empty PATH did not report mawk as not-found:
$out" ;;
  esac
}

test_interpreters_a_present_awk_is_found_with_its_version() {
  local yard out
  yard="$(in_yard has-mawk mawk)"
  out="$(in_discover "$yard")"

  case "$out" in
    *"STUB mawk 9.9"*) ;;
    *) fail "a mawk on PATH was not discovered with its version:
$out" ;;
  esac
  # The rest must still be absent, or the test is passing on a machine fact.
  case "$out" in
    *"gawk"*"not-found"*) ;;
    *) fail "gawk was not reported not-found on a PATH that has only mawk:
$out" ;;
  esac
}

# The candidate list is the scope of the claim. Promotion criterion 1 in
# docs/contracts/README.md says the supported set may not be narrowed to whatever already
# passes, and quietly deleting a name from this list is exactly that move, with no other
# symptom.
test_interpreters_the_candidate_list_has_not_been_narrowed() {
  local out name
  out="$(in_discover "$(in_yard empty)")"
  for name in awk gawk mawk original-awk busybox; do
    case "$out" in
      *"$name"*) ;;
      *) fail "'$name' has been dropped from the candidate list — the matrix now claims less
than it did, with nothing else to show for it:
$out" ;;
    esac
  done
}

# A run with no awk must refuse rather than report success over an empty matrix. This is the
# "no check exists is not the check passed" rule applied to the runner itself.
test_interpreters_no_awk_at_all_refuses_to_report_success() {
  local yard out rc=0
  yard="$(in_yard empty)"
  out="$(in_plan "$yard")" || rc=$?

  [ "$rc" -eq 2 ] || fail "a PATH with no awk exited $rc, wanted 2:
$out"
  case "$out" in
    *"no awk found"*) ;;
    *) fail "the refusal did not say why:
$out" ;;
  esac
}

# Two names for one implementation must not be counted twice. Without this, `awk` and `gawk`
# on a normal machine make the matrix report two interpreters while running one program.
test_interpreters_two_names_for_one_awk_count_once() {
  local yard out
  # Both stubs report the same version string, which is what marks them as one implementation.
  yard="$TMP/interp/aliased"
  rm -rf "$yard"; mkdir -p "$yard"
  local name
  for name in awk gawk; do
    printf '#!/bin/sh\ncase "$1" in --version) echo "STUB same 1.0";; esac\nexit 0\n' > "$yard/$name"
    chmod +x "$yard/$name"
  done

  out="$(in_plan "$yard")"

  case "$out" in
    *"(alias)"*) ;;
    *) fail "two names reporting one version were not collapsed to one run plus an alias:
$out" ;;
  esac
  case "$out" in
    *"run 1/1: awk"*) ;;
    *) fail "the plan did not collapse two names to a single run:
$out" ;;
  esac
}

# The label on a run must name the interpreter that ran. This held once and then stopped
# holding, silently, when alias markers shared an array with the run list — run 2 printed
# `gawk` while executing mawk. A passing suite under a misnamed interpreter is worse than a
# failing one, because the report is evidence of something that did not happen.
test_interpreters_each_run_is_labelled_with_the_awk_it_used() {
  local yard out
  yard="$TMP/interp/labelled"
  rm -rf "$yard"; mkdir -p "$yard"
  # `awk` and `gawk` are one implementation; `mawk` is a second. So the run list is
  # [awk, mawk] while the display list is [awk, gawk (alias), mawk]. If the two are indexed
  # together, run 2 takes its name from the alias entry and reads "gawk".
  local name
  for name in awk gawk; do
    printf '#!/bin/sh\ncase "$1" in --version) echo "STUB one 1.0";; esac\nexit 0\n' > "$yard/$name"
    chmod +x "$yard/$name"
  done
  printf '#!/bin/sh\ncase "$1" in --version) echo "STUB two 2.0";; esac\nexit 0\n' > "$yard/mawk"
  chmod +x "$yard/mawk"

  out="$(in_plan "$yard")"

  case "$out" in
    *"run 2/2: mawk"*) ;;
    *) fail "run 2 was not labelled mawk — the run list and the display list have desynced:
$out" ;;
  esac
  case "$out" in
    *"run 2/2: gawk"*) fail "run 2 is labelled 'gawk', which is the alias, not the interpreter:
$out" ;;
  esac
}

# ── The driver ───────────────────────────────────────────────────────────────
#
# The tests above cover planning. These cover the part that runs, which review found had no
# coverage at all: three separate one-line mutations to the driver left a fully green matrix,
# one of them running gawk twice while printing `run 2/2: mawk`.
#
# They put a yard of stub awks first on PATH so discovery is controlled, while coreutils stay
# reachable behind it, and they pass a filter so each inner run executes one test rather than
# the whole suite.

# Writes a stub awk reporting $2 as its version, then exec'ing $3 — or failing, if $3 is empty.
in_stub() {
  local file="$1" ver="$2" real="${3:-}"
  if [ -n "$real" ]; then
    printf '#!/bin/sh\ncase "$1" in --version) echo "%s"; exit 0;; esac\nexec %s "$@"\n' \
      "$ver" "$real" > "$file"
  else
    printf '#!/bin/sh\ncase "$1" in --version) echo "%s"; exit 0;; esac\nexit 1\n' "$ver" > "$file"
  fi
  chmod +x "$file"
}

# A driver test is about what the driver does with a plan, so it needs the plan to be the one it
# built. PATH can shadow a name but cannot hide one, so a machine carrying original-awk or
# busybox would produce extra runs and the arithmetic below would be about that machine.
in_driver_yard() {
  local yard="$TMP/interp/driver-$1"
  if command -v original-awk >/dev/null 2>&1 || command -v busybox >/dev/null 2>&1; then
    return 1
  fi
  rm -rf "$yard"; mkdir -p "$yard"
  printf '%s' "$yard"
}

# The one test each inner run executes. It has to be the shim check: any other filter leaves
# the inner run with no opinion about which awk it got, and the driver can then announce one
# interpreter while running another with the matrix still green.
IN_SHIM_CHECK=interpreters_the_shim_gave_the_inner_run_the_announced_awk

# Runs the driver with the re-entry flag cleared. Without the unset, a developer running the
# suite inside a matrix pass — or by hand with BLC_AWK_INNER set — gets a child that skips the
# matrix, and every test here fails for a reason that has nothing to do with the driver.
in_driver_run() {
  local yard="$1" filter="$2"
  ( unset BLC_AWK_INNER BLC_AWK_VERSION
    PATH="$yard:$PATH" exec "$IN_BASH" "$REPO_ROOT/tests/run.sh" "$filter" ) 2>&1
}

test_interpreters_the_driver_runs_the_interpreter_it_names() {
  local yard out real
  real="$(command -v gawk)" || { skip "no gawk to point a stub at"; return; }
  yard="$(in_driver_yard names)" || { skip "this machine has a candidate PATH cannot hide"; return; }
  in_stub "$yard/awk"  "STUB alpha 1.0" "$real"
  in_stub "$yard/gawk" "STUB beta 2.0"  "$real"
  in_stub "$yard/mawk" "STUB beta 2.0"  "$real"

  out="$(in_driver_run "$yard" "$IN_SHIM_CHECK")"

  # gawk and mawk report the same version, so they are one implementation and one is an alias.
  # Two runs. Each inner run checks for itself that the shim gave it the announced awk.
  case "$out" in
    *"the shim gave the inner run"*) fail "an inner run got an awk the driver did not name:
$out" ;;
  esac
  case "$out" in
    *"2 interpreter(s) passed"*) ;;
    *) fail "expected two implementations behind three names:
$out" ;;
  esac
}

test_interpreters_a_failing_interpreter_fails_the_matrix() {
  local yard out rc=0 real
  real="$(command -v gawk)" || { skip "no gawk to point a stub at"; return; }
  yard="$(in_driver_yard failing)" || { skip "this machine has a candidate PATH cannot hide"; return; }
  in_stub "$yard/awk"  "STUB good 1.0" "$real"
  in_stub "$yard/gawk" "STUB good 1.0" "$real"
  in_stub "$yard/mawk" "STUB bad 2.0"            # no real binary behind it: every call fails

  out="$(in_driver_run "$yard" "$IN_SHIM_CHECK")" || rc=$?

  [ "$rc" -eq 1 ] || fail "a matrix with a failing interpreter exited $rc, wanted 1:
$out"
  case "$out" in
    *"FAILED under"*mawk*) ;;
    *) fail "the failing interpreter was not named:
$out" ;;
  esac
}

# The same refusal as the plan-path test, against the path a human invokes. Review found that
# deleting the driver's call to blc_awk_require_one left every test green: one guard, two call
# sites, and promotion criterion 2 asks for a mutation per code path a guard claims.
test_interpreters_the_driver_refuses_when_no_awk_exists() {
  local yard out rc=0
  yard="$(in_yard empty)"
  out="$( unset BLC_AWK_INNER BLC_AWK_VERSION
          PATH="$yard" exec "$IN_BASH" "$REPO_ROOT/tests/run.sh" nothing_matches_this 2>&1 )" || rc=$?

  [ "$rc" -eq 2 ] || fail "the driver on an awk-less PATH exited $rc, wanted 2:
$out"
  case "$out" in
    *"no awk found"*) ;;
    *) fail "the driver's refusal did not say why:
$out" ;;
  esac
}

# Runs inside every matrix pass: the driver announces an interpreter and a version, and this
# checks the awk the shim installed is that one. Without it the driver can execute one awk while
# reporting another and every test still passes — a green report for a run that did not happen.
test_interpreters_the_shim_gave_the_inner_run_the_announced_awk() {
  [ -n "${BLC_AWK_INNER:-}" ] || { skip "not an inner matrix run"; return; }
  [ -n "${BLC_AWK_VERSION:-}" ] \
    || fail "BLC_AWK_INNER is set but BLC_AWK_VERSION is not — the driver stopped saying which
interpreter it handed over, and this check cannot run"

  local actual
  actual="$(awk --version 2>&1 | head -1)"
  [ "$actual" = "$BLC_AWK_VERSION" ] \
    || fail "the shim gave the inner run a different awk than the driver announced.
announced: $BLC_AWK_VERSION
actual:    $actual"
}
