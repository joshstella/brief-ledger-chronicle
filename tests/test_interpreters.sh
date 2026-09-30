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

# The second field of the discovery line for exactly $2 — `not-found`, or a path.
#
# Written because the assertions here used to glob the whole report: `*"mawk"*"not-found"*`
# matches a line saying mawk was found followed by a *different* candidate's not-found line,
# and `*"awk"*` matches `gawk`. Review found that the test guarding the candidate list stayed
# green when `awk` was deleted from it, for exactly that reason. A name is anchored on the
# newline before it and the tab after it, so no other candidate can satisfy it.
in_field() {
  local out="$1" name="$2" rest
  rest="$(printf '\n%s' "$out")"
  case "$rest" in
    *$'\n'"$name"$'\t'*) rest="${rest#*$'\n'"$name"$'\t'}" ;;
    *) return 1 ;;
  esac
  printf '%s' "${rest%%$'\t'*}"
}

in_discover() { PATH="$1" "$IN_BASH" "$REPO_ROOT/tests/run.sh" --interpreters 2>&1; }
in_plan()     { PATH="$1" "$IN_BASH" "$REPO_ROOT/tests/run.sh" --matrix-plan 2>&1; }

test_interpreters_every_candidate_is_reported_either_way() {
  local yard out count
  yard="$(in_yard empty)"
  out="$(in_discover "$yard")"

  # Silence is the failure this whole phase is about. Every candidate gets a line.
  local name
  for name in $IN_CANDIDATES; do
    in_field "$out" "$name" >/dev/null \
      || fail "discovery has no line for '$name' — every candidate is reported either way, and
silence is the failure this whole phase is about:
$out"
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
  [ "$(in_field "$out" mawk)" = "not-found" ] \
    || fail "an empty PATH did not report mawk as not-found:
$out"
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
  [ "$(in_field "$out" gawk)" = "not-found" ] \
    || fail "gawk was not reported not-found on a PATH that has only mawk:
$out"
}

# The candidate list is the scope of the claim. Promotion criterion 1 in
# docs/contracts/README.md says the supported set may not be narrowed to whatever already
# passes, and quietly deleting a name from this list is exactly that move, with no other
# symptom.
test_interpreters_the_candidate_list_has_not_been_narrowed() {
  local out name
  out="$(in_discover "$(in_yard empty)")"
  for name in awk gawk mawk original-awk busybox; do
    in_field "$out" "$name" >/dev/null \
      || fail "'$name' has been dropped from the candidate list — the matrix now claims less
than it did, with nothing else to show for it:
$out"
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

# A driver test is about what the driver does with a plan, so the plan has to be the one the
# test built. PATH can shadow a name but cannot hide one, so *every* candidate gets a stub —
# including busybox, which gets one that fails the awk-applet probe and is therefore reported
# not-found. Leaving a name unstubbed would let a machine that has it add a run.
#
# An earlier version skipped both driver tests when the machine had original-awk or busybox.
# That trade pointed the wrong way: phase `b` installs exactly those interpreters on CI, so the
# two tests written to guard the driver would have gone silent on the one machine with the
# widest matrix.
#
# $2 is the version each of awk, gawk, mawk and original-awk reports. Names sharing a version
# are one implementation, and the driver must collapse them.
in_driver_yard() {
  local yard="$TMP/interp/driver-$1"
  local real="$2" v_awk="$3" v_gawk="$4" v_mawk="$5" v_oawk="$6"
  rm -rf "$yard"; mkdir -p "$yard"
  in_stub "$yard/awk"          "$v_awk"  "$real"
  in_stub "$yard/gawk"         "$v_gawk" "$real"
  in_stub "$yard/mawk"         "$v_mawk" "$real"
  in_stub "$yard/original-awk" "$v_oawk" "$real"
  # busybox is probed by running its awk applet, not by --version. A busybox that cannot is
  # not an awk this found, so this stub takes the name out of the plan.
  printf '#!/bin/sh\nexit 1\n' > "$yard/busybox"; chmod +x "$yard/busybox"
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

# gawk is made an alias of awk on purpose, rather than of something later. It puts an alias
# *before* a run entry, so the display list and the run list stop agreeing index for index:
# display is [awk, gawk (alias), mawk, original-awk] while the runs are [awk, mawk,
# original-awk]. Indexing the announcement off the wrong list then prints `run 2/3: gawk
# (alias)`, which is the #0014 desync. With the alias last, both lists agree at every index a
# run uses and the mutation is invisible.
in_driver_three() {
  in_driver_yard "$1" "$2" "STUB alpha 1.0" "STUB alpha 1.0" "STUB beta 2.0" "STUB gamma 3.0"
}

test_interpreters_the_driver_runs_the_interpreter_it_names() {
  local yard out real
  real="$(command -v awk)" || { skip "no awk to point a stub at"; return; }
  yard="$(in_driver_three names "$real")"

  out="$(in_driver_run "$yard" "$IN_SHIM_CHECK")"

  case "$out" in
    *"the shim gave the inner run"*) fail "an inner run got an awk the driver did not name:
$out" ;;
  esac
  case "$out" in
    *"3 interpreter(s) passed"*) ;;
    *) fail "expected three implementations behind four names and a busybox without an applet:
$out" ;;
  esac
}

# The announcement itself. The shim check above compares *versions*, and the desync this guards
# leaves the version correct while the name lies — `run 2/3: gawk (alias) — mawk 1.3.4`. Review
# reproduced that with a one-word change to the driver and got 11 passed, 0 failed.
test_interpreters_each_announcement_names_a_run_and_never_an_alias() {
  local yard out real line n=0
  real="$(command -v awk)" || { skip "no awk to point a stub at"; return; }
  yard="$(in_driver_three announce "$real")"

  out="$(in_driver_run "$yard" "$IN_SHIM_CHECK")"

  # The run entries, in order, for the plan in_driver_three builds.
  local want_1="run 1/3: awk" want_2="run 2/3: mawk" want_3="run 3/3: original-awk"
  while IFS= read -r line; do
    case "$line" in
      *"run "[0-9]*"/"*) ;;
      *) continue ;;
    esac
    n=$((n + 1))
    case "$line" in
      *"(alias)"*) fail "an announcement names an alias, so the label is being read off the
display list rather than the run list — this is the #0014 desync:
$line" ;;
    esac
    local want; eval "want=\${want_$n:-}"
    [ -n "$want" ] || fail "announcement $n has no expected value — the fixture grew a run and
this list did not, so a position stopped being checked without anything failing:
$line"
    case "$line" in
      *"$want"*) ;;
      *) fail "announcement $n does not say '$want':
$line" ;;
    esac
  done <<EOF
$out
EOF

  [ "$n" -eq 3 ] || fail "expected three announcements, saw $n:
$out"
}

test_interpreters_a_failing_interpreter_fails_the_matrix() {
  local yard out rc=0 real
  real="$(command -v awk)" || { skip "no awk to point a stub at"; return; }
  yard="$(in_driver_yard failing "$real" "STUB good 1.0" "STUB good 1.0" \
                        "STUB bad 2.0" "STUB good 1.0")"
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

  # The same fallback discovery applies. Without it an awk that prints nothing for --version is
  # announced as `(version unknown)`, compared against an empty string, and fails the whole
  # matrix with a message blaming the shim — which was correct. Reproduced by review.
  local actual
  actual="$(awk --version </dev/null 2>&1 | head -1)"
  [ -n "$actual" ] || actual="(version unknown)"
  [ "$actual" = "$BLC_AWK_VERSION" ] \
    || fail "the shim gave the inner run a different awk than the driver announced.
announced: $BLC_AWK_VERSION
actual:    $actual"
}

# ── busybox ──────────────────────────────────────────────────────────────────
#
# busybox is the one candidate discovered by a different question. The others answer
# `--version`; busybox is one binary holding many applets, so the question is whether it has an
# awk applet at all, and the answer comes from running it. An earlier review round recorded this
# branch as covered. It was not: `busybox` appeared in the test file only inside candidate lists.

# A busybox stub. $2 decides whether the awk applet exists.
in_busybox() {
  local file="$1" with_awk="$2" real="${3:-}"
  if [ "$with_awk" = yes ]; then
    # Refuses every applet but awk, which is what makes it a fixture for the applet field: a
    # shim that forgets the word `awk` invokes this binary with a program as its first argument
    # and gets nothing.
    printf '#!/bin/sh\ncase "$1" in awk) shift;; *) exit 1;; esac\ncase "$1" in --version) echo "BusyBox v1.36.1 (stub) multi-call binary"; exit 0;; esac\n%s\n' \
      "${real:+exec $real \"\$@\"}" > "$file"
  else
    printf '#!/bin/sh\nexit 1\n' > "$file"
  fi
  chmod +x "$file"
}

test_interpreters_a_busybox_with_an_awk_applet_is_an_awk() {
  local yard out
  yard="$(in_yard busybox-yes)"
  in_busybox "$yard/busybox" yes
  out="$(in_discover "$yard")"

  [ "$(in_field "$out" busybox)" = "$yard/busybox" ] \
    || fail "a busybox carrying an awk applet was not discovered:
$out"
  case "$out" in
    *"BusyBox v1.36.1 (stub)"*) ;;
    *) fail "busybox was found but not with the version its applet reports:
$out" ;;
  esac
}

# The refusal half. A busybox built without awk is a binary that exists and is not an awk, and
# reporting it would put a run in the matrix that cannot execute a single test.
test_interpreters_a_busybox_without_an_awk_applet_is_not_an_awk() {
  local yard out
  yard="$(in_yard busybox-no)"
  in_busybox "$yard/busybox" no
  out="$(in_discover "$yard")"

  [ "$(in_field "$out" busybox)" = "not-found" ] \
    || fail "a busybox with no awk applet was reported as an awk:
$out"
}

# An awk that does not know --version reads a program from stdin instead, and discovery waits
# for it. The suite then hangs with no output and no failure — the worst shape a defect can
# take here, because a hung run is not a red run and CI reports a timeout rather than a cause.
#
# stdin is a FIFO opened read-write, so it never reaches EOF and no writer process has to be
# cleaned up afterwards. Without the redirect in blc_awk_version, this times out.
test_interpreters_an_awk_that_reads_stdin_cannot_hang_discovery() {
  command -v timeout >/dev/null 2>&1 || { skip "no timeout(1)"; return; }
  command -v mkfifo  >/dev/null 2>&1 || { skip "no mkfifo(1)"; return; }

  local yard fifo out rc=0
  yard="$(in_yard reads-stdin)"
  # `read` and not `cat`: PATH here is the yard and nothing else, so an external command would
  # exit 127 at once and the test could never hang, whatever the code under it did.
  printf '#!/bin/sh\nread line\nexit 0\n' > "$yard/mawk"; chmod +x "$yard/mawk"
  fifo="$yard/.stdin"; mkfifo "$fifo"

  exec 9<>"$fifo"
  out="$(timeout 10 env PATH="$yard" "$IN_BASH" "$REPO_ROOT/tests/run.sh" --interpreters 0<&9 2>&1)" || rc=$?
  exec 9>&-

  [ "$rc" -ne 124 ] || fail "discovery blocked on stdin and had to be killed. An awk that does
not recognise --version reads a program instead, so the probe must close stdin."
  [ "$rc" -eq 0 ] || fail "discovery exited $rc against an awk that reads stdin:
$out"
}

# The fallback for an awk that prints nothing for --version. Discovery announces `(version
# unknown)`; without the matching fallback in the inner check, the announcement is compared
# against an empty string, can never match, and the matrix fails with a message blaming a shim
# that did its job. The fix shipped in the previous commit with no test that could fail for it.
test_interpreters_an_awk_with_no_version_still_runs() {
  local yard out rc=0 real
  real="$(command -v awk)" || { skip "no awk to point a stub at"; return; }
  # mawk's stub answers --version with a blank line, which is how a real awk that does not know
  # the option and writes nothing behaves.
  yard="$(in_driver_yard silent "$real" "STUB alpha 1.0" "STUB alpha 1.0" "" "STUB gamma 3.0")"

  out="$(in_driver_run "$yard" "$IN_SHIM_CHECK")" || rc=$?

  [ "$rc" -eq 0 ] || fail "an awk that reports no version failed the matrix, exit $rc:
$out"
  case "$out" in
    *"(version unknown)"*) ;;
    *) fail "an awk with no version was not announced as unknown:
$out" ;;
  esac
}

# The applet field. busybox is invoked as two words, and the field exists so the path can be
# quoted separately from the applet. A shim that drops the applet runs the multi-call binary
# with a program where an applet name belongs. Nothing else in the suite executes that path.
test_interpreters_a_busybox_run_is_shimmed_with_its_applet() {
  local yard out rc=0 real
  real="$(command -v awk)" || { skip "no awk to point a stub at"; return; }
  # One version for all four named awks, so they collapse to a single run and busybox is the
  # second. Two runs, and the busybox one only works if the shim carries the applet.
  yard="$(in_driver_yard applet "$real" "STUB one 1.0" "STUB one 1.0" "STUB one 1.0" "STUB one 1.0")"
  in_busybox "$yard/busybox" yes "$real"

  out="$(in_driver_run "$yard" "$IN_SHIM_CHECK")" || rc=$?

  [ "$rc" -eq 0 ] || fail "the busybox run failed, exit $rc — a shim that drops the applet
invokes the multi-call binary with a program in the applet's place:
$out"
  case "$out" in
    *"2 interpreter(s) passed"*) ;;
    *) fail "expected one run for the four named awks and one for busybox:
$out" ;;
  esac
}

# Two awks that both say nothing about their version are two awks. The dedupe keys on the
# version string, so without the exemption at tests/run.sh:112 they share the empty key and
# collapse — one run, and a matrix reporting two interpreters it did not both use. That is the
# failure this brief exists to prevent, reached through the one input that makes the key
# meaningless rather than wrong.
test_interpreters_two_silent_awks_are_not_one_awk() {
  local yard out real
  real="$(command -v awk)" || { skip "no awk to point a stub at"; return; }
  yard="$(in_driver_yard silent-pair "$real" "STUB alpha 1.0" "" "" "STUB gamma 3.0")"

  out="$(in_plan "$yard:$PATH")"

  case "$out" in
    *"(alias)"*) fail "two awks that report no version were collapsed into one run — an unknown
version is not evidence that two binaries are the same binary:
$out" ;;
  esac
  case "$out" in
    *"run 4/4:"*) ;;
    *) fail "expected four runs from four named awks, two of them silent:
$out" ;;
  esac
}

# ── The stated claim (#0015 phase b) ─────────────────────────────────────────
#
# Contract promotion criterion 1 needs the supported-interpreter set stated. Phase b states it
# by pointing at the runner rather than by copying the list into prose, so these two tests
# guard the pointer instead of the copy: one fails if a document stops citing the runner, the
# other fails if a document starts answering the question itself.

# The documents that carry the claim. A contributor meets the first, a promoter the second.
IN_CLAIM_DOCS="tests/README.md docs/contracts/README.md"

# The command both documents send a reader to. Written once here, so renaming the mode breaks
# this test rather than leaving two documents pointing at a flag that no longer exists.
IN_CLAIM_CMD="bash tests/run.sh --matrix-plan"

test_interpreters_the_claim_documents_point_at_the_runner() {
  local doc body
  for doc in $IN_CLAIM_DOCS; do
    body="$(cat "$REPO_ROOT/$doc")"
    case "$body" in
      *"$IN_CLAIM_CMD"*) ;;
      *) fail "$doc no longer tells a reader how to read the supported-interpreter set.
The set is not written in prose anywhere, so a document that drops '$IN_CLAIM_CMD' leaves the
claim unstated, and Contract criterion 1 asks for it to be stated." ;;
    esac
  done
}

# The counterpart. A pointer is only better than a copy while there is no copy: the moment a
# document enumerates the set as well, there are two answers, and the prose one is the one that
# goes stale. Four names on one line is a list; two is a comparison, which these files do make.
test_interpreters_no_claim_document_enumerates_the_set() {
  local doc line words tok name hits
  for doc in $IN_CLAIM_DOCS; do
    while IFS= read -r line; do
      words="${line//[^[:alnum:]-]/ }"
      hits=0
      for name in $IN_CANDIDATES; do
        for tok in $words; do
          [ "$tok" = "$name" ] && { hits=$((hits + 1)); break; }
        done
      done
      [ "$hits" -lt 4 ] || fail "$doc names $hits interpreters on one line, which is a second
copy of a list that already has one authority — the candidate list in tests/run.sh. Delete the
enumeration and point at '$IN_CLAIM_CMD':
$line"
    done < "$REPO_ROOT/$doc"
  done
}
