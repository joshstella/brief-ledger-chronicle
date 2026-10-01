#!/usr/bin/env bash
# Answer "which briefs are open?" and say what it is costing to leave them open.
#
# Usage: open-briefs.sh [briefs-dir]     (default: docs/briefs)
#
# No finding exits non-zero. This reports; it does not gate. A long deferral is often
# the right call, so failing a build on one would forbid the thing this is meant to
# surface — see docs/briefs/README.md, "the ledger is an archive, and a bad inbox".
# A broken environment is not a finding: a missing briefs directory or a target outside
# a repository exits 2, because those mean the question could not be asked at all.
#
# The vocabulary it reads is defined once in docs/briefs/README.md, "Ledger status".
# This script does not restate it. One state is not in that vocabulary because no
# ledger asserts it: a brief with no ledger.md has not been started. That is derived
# from absence rather than read, and it is a resting state, not a finding — filing
# and starting are separate acts, and a brief is meant to wait between them.
#
# Deliberately does not decide what counts as "too stale". That threshold is an
# open decision on brief #0004. Reporting the commit distance and letting a human
# judge is honest; inventing a number here would smuggle a decision into a tool.
#
# git is required. The forge is not: PR and MR state is looked up through `gh` or `glab`
# when detect-forge.sh recognises the remote, and reported as not checked when it does not,
# because this project treats external tools as optional artifacts to piggyback on, never
# as load-bearing.
#
# Distances are measured against local refs and are only as fresh as your last fetch.
# This tool does not fetch: a reporting command that mutates the repository would be
# a surprise, and one that reaches the network cannot run offline. Fetch first if the
# numbers need to be current.

BRIEFS_DIR="${1:-docs/briefs}"

# The phase-row matcher is shared with validate-briefs.sh, so it lives in lib/ rather
# than here. A missing library is a broken install, not a finding: it exits 2 with the
# other environment failures below, because a scan that cannot run must not report a
# clean tree it never looked at.
#
# Symlinks are resolved first. `dirname "${BASH_SOURCE[0]}"` alone reports the directory
# the script was *reached* through, so a link on a PATH directory would send this looking
# for lib/ next to the link. Before the matcher moved out of this file the script had no
# external dependency and ran from wherever it was reached, and that property is kept
# here rather than surrendered to the refactor. Walked by hand instead of `readlink -f`,
# which is GNU-only and absent on macOS.
#
# The walk is bounded. A cycle cannot reach this loop by the ordinary route — the kernel
# resolves the path before bash executes anything, so a circular link fails at exec with
# ELOOP and this script never starts. That is an argument from the caller's behaviour,
# not from this loop's, and it stops holding the moment someone sources this file with a
# path they built themselves. The bound costs one comparison and removes the need to
# trust the argument.
BLC_SELF="${BASH_SOURCE[0]}"
BLC_HOPS=0
while [ -L "$BLC_SELF" ]; do
  BLC_HOPS=$((BLC_HOPS + 1))
  if [ "$BLC_HOPS" -gt 40 ]; then
    printf 'error: too many symbolic links resolving %s\n' "${BASH_SOURCE[0]}" >&2
    exit 2
  fi
  BLC_SELF_DIR="$(cd -P "$(dirname "$BLC_SELF")" && pwd)"
  BLC_SELF="$(readlink "$BLC_SELF")"
  # A relative link target is relative to the directory holding the link, not to $PWD.
  case "$BLC_SELF" in
    /*) ;;
    *) BLC_SELF="$BLC_SELF_DIR/$BLC_SELF" ;;
  esac
done
BLC_LIB_DIR="$(cd -P "$(dirname "$BLC_SELF")" && pwd)/lib"
for BLC_LIB in phase-row status-line; do
  if [ ! -r "$BLC_LIB_DIR/$BLC_LIB.sh" ]; then
    printf 'error: cannot read %s\n' "$BLC_LIB_DIR/$BLC_LIB.sh" >&2
    exit 2
  fi
  . "$BLC_LIB_DIR/$BLC_LIB.sh"
done
# Run with bash rather than executed, so a copy that lost its execute bit still answers.
BLC_DETECT_FORGE="${BLC_LIB_DIR%/lib}/detect-forge.sh"
if [ ! -r "$BLC_DETECT_FORGE" ]; then
  printf 'error: cannot read %s\n' "$BLC_DETECT_FORGE" >&2
  exit 2
fi

OPEN=0
DRIFT=0
UNTRACKED=0
NOT_STARTED=0

finding() { printf '  %-11s %s\n' "$1" "$2"; }

if [ ! -d "$BRIEFS_DIR" ]; then
  printf 'error: not a directory: %s\n' "$BRIEFS_DIR" >&2
  exit 2
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  printf 'error: not inside a git repository\n' >&2
  exit 2
fi

# The trunk is whatever the repo calls it. Guessing "main" would make the tool
# wrong-but-quiet in any repo that never renamed from master.
TRUNK=""
for candidate in main master trunk; do
  if git rev-parse --verify --quiet "refs/heads/$candidate" >/dev/null 2>&1; then
    TRUNK="$candidate"
    break
  fi
done
[ -n "$TRUNK" ] || TRUNK="HEAD"

# Asked at most once, and only when a PR or MR needs a state: each probe is a round trip to
# the server. Called as a statement, never inside $( ), so the answer outlives the call.
FORGE=""
FORGE_ASKED=0
detect_forge() {
  [ "$FORGE_ASKED" -eq 0 ] || return 0
  FORGE_ASKED=1
  FORGE="$(bash "$BLC_DETECT_FORGE" 2>/dev/null)" || FORGE=""
}

# One vocabulary for both forges: `gh` says OPEN, `glab` says opened.
state_word() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    open|opened) printf 'open' ;;
    merged) printf 'merged' ;;
    closed) printf 'closed' ;;
    "") printf 'unknown' ;;
    *) printf '%s' "$1" | tr '[:upper:]' '[:lower:]' ;;
  esac
}

# A phase entry in the status line looks like  3:in-progress(feature/x,PR#14)
# The pointer is optional; the state is not.
entry_state()   { printf '%s' "${1#*:}" | sed 's/(.*//'; }
entry_pointer() { printf '%s' "$1" | sed -n 's/.*(\(.*\))$/\1/p'; }
entry_index()   { printf '%s' "${1%%:*}"; }

# Where the status line lives is `blc_status_line`'s business, shared with `list-briefs.sh`
# so the two cannot drift apart. The positional read that used to sit here reported
# `[no-line]` for placements the other reader handled; #0014 phase `b` has the history.

branch_ref() {
  local b="$1"
  if git rev-parse --verify --quiet "refs/heads/$b" >/dev/null 2>&1; then
    printf 'refs/heads/%s' "$b"; return 0
  fi
  if git rev-parse --verify --quiet "refs/remotes/origin/$b" >/dev/null 2>&1; then
    printf 'refs/remotes/origin/%s' "$b"; return 0
  fi
  return 1
}

# Classify every field of a pointer, one `kind value` line each. The vocabulary is in
# docs/briefs/README.md, "Ledger status": a branch, `PR#14`, and `!123` for a GitLab merge
# request, separated by commas. `commit <sha>` is not handled because it cannot arrive: the
# status line is split on spaces, so it only survives on a closed phase, which is never read.
#
# Branches have no fixed shape, so a field that is none of the fixed tokens is a branch only
# if a branch by that name exists. Otherwise it is `unknown`, and the caller reports it in
# words that do not pick a cause: a deleted branch and a tracker key look identical here, and
# a deleted branch is the stale pointer this tool exists to catch. Every field is read, so an
# unknown one neither hides a real branch after it nor vanishes behind one before it.
#
# `set -f` for the reason given at `blc_status_phase_entries`: the pointer is data from a file,
# and an unquoted split globs, so `(*)` would report the working directory's file names.
pointer_fields() {
  local field had_f=0
  local IFS=,
  case "$-" in *f*) had_f=1 ;; esac
  set -f
  for field in $1; do
    field="${field#"${field%%[! ]*}"}"
    field="${field%"${field##*[! ]}"}"
    case "$field" in
      "") ;;
      # Digits only: anything else would reach `gh` as a PR number, or as an option.
      PR#*)
        case "${field#PR#}" in
          ""|*[!0-9]*) printf 'unknown %s\n' "$field" ;;
          *) printf 'pr %s\n' "${field#PR#}" ;;
        esac ;;
      '!'*)
        case "${field#!}" in
          ""|*[!0-9]*) printf 'unknown %s\n' "$field" ;;
          *) printf 'mr %s\n' "${field#!}" ;;
        esac ;;
      *)
        if branch_ref "$field" >/dev/null; then
          printf 'branch %s\n' "$field"
        else
          printf 'unknown %s\n' "$field"
        fi ;;
    esac
  done
  [ "$had_f" -eq 1 ] || set +f
}

# ── Walk the briefs ──────────────────────────────────────────────────────────

BRIEF_COUNT=0

for dir in "$BRIEFS_DIR"/[0-9][0-9][0-9][0-9]*/; do
  [ -d "$dir" ] || continue
  ledger="$dir/ledger.md"
  ledger="${ledger//\/\//\/}"
  name="${dir%/}"; name="${name##*/}"
  BRIEF_COUNT=$((BRIEF_COUNT + 1))

  # A brief with no ledger has not been started. That is a resting state, not a
  # defect: filing and starting are separate acts, and the gap between them is
  # where a brief waits to be picked up. Reported so the wait is visible, but not
  # counted as open, because counting it would report work in flight when none is.
  if [ ! -f "$ledger" ]; then
    printf '%s\n' "$name"
    finding "[not-started]" "filed; no ledger yet, so execution has not begun"
    # Untracked still matters here. A brief git has never seen is invisible to
    # everyone else, so it is not waiting to be picked up — nobody can see it.
    if ! git ls-files --error-unmatch "$dir/brief.md" >/dev/null 2>&1; then
      finding "[untracked]" "not in git; no one else can see this brief was filed"
      UNTRACKED=$((UNTRACKED + 1))
    fi
    NOT_STARTED=$((NOT_STARTED + 1))
    continue
  fi

  # A brief git has never seen has no branch, no PR and no commits, so every
  # staleness measure below reads clean precisely because it is least protected.
  # Reported as its own finding rather than as an absence of one.
  tracked=1
  git ls-files --error-unmatch "$ledger" >/dev/null 2>&1 || tracked=0

  line="$(blc_status_line "$ledger")"
  case "$line" in
    blc/*) ;;
    *) line="" ;;
  esac

  if [ -z "$line" ]; then
    printf '%s\n' "$name"
    finding "[no-line]" "no line in the file begins with a blc/N status token, outside code fences"
    [ "$tracked" -eq 0 ] && finding "[untracked]" "not in git; invisible to every branch measure"
    DRIFT=$((DRIFT + 1))
    continue
  fi

  # shellcheck disable=SC2086
  set -- $line
  shift                      # blc/N
  serial="$1"; shift         # #NNNN
  brief_state="$1"; shift    # brief-level state, possibly with a pointer

  header_printed=0
  print_header() {
    [ "$header_printed" -eq 1 ] && return
    printf '%s  %s %s\n' "$name" "$serial" "$(printf '%s' "$brief_state" | sed 's/(.*//')"
    header_printed=1
  }

  if [ "$tracked" -eq 0 ]; then
    print_header
    finding "[untracked]" "not in git; no branch, no PR, no commits, so nothing below can measure it"
    UNTRACKED=$((UNTRACKED + 1))
  fi

  # What counts as a phase entry is blc_status_phase_entries' business, shared with
  # validate-briefs.sh. This loop used to filter on `*:*` alone while the gate applied a
  # shape rule of its own, and the two disagreed about `bc:in-progress(feature/x)` — the
  # reporter followed a phase the gate could not see. One tokenizer, for the same reason
  # there is one matcher.
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue

    idx="$(entry_index "$entry")"
    state="$(entry_state "$entry")"
    ptr="$(entry_pointer "$entry")"

    # Does the phase table agree? Found by collecting every row that could be this
    # phase's row and asking whether any of them carries the state word. What counts as
    # a candidate row is `blc_phase_row_find`'s business, and the shapes it knows are
    # documented there rather than restated here.
    #
    # Every match is considered, and drift is reported only when *none* of them agrees.
    # Taking the first match meant a row from a second table — a cost or timing table
    # whose cells mention `phase 2` — could shadow the real phase row and report a record
    # that was correct as self-contradictory. The price of the rule is the opposite error:
    # a stale row goes unreported when some other matching row happens to carry the word.
    # That trade is deliberate. This tool never gates, so a false positive spends trust in
    # every finding it will ever emit, while a false negative costs one missed drift that
    # the next reader of the ledger still sees. A reporter nobody believes reports nothing.
    rows="$(blc_phase_row_find "$idx" "$ledger")"
    if [ -n "$rows" ] && ! printf '%s\n' "$rows" | grep -qF "$state"; then
      print_header
      finding "[drift]" "phase $idx: status line says '$state'; no phase table row agrees"
      DRIFT=$((DRIFT + 1))
    fi

    case "$state" in
      in-progress|deferred) ;;
      *) continue ;;
    esac

    print_header
    OPEN=$((OPEN + 1))

    # The status line is split on spaces, so `(feature/x, PR#14)` arrives as `(feature/x,`
    # and the rest is lost. Reading the fragment would measure part of what was written and
    # report the remainder as absent.
    case "$entry" in
      *"("*")") ;;
      *"("*)
        finding "[$state]" "phase $idx: pointer is cut at a space; separate its fields with commas only"
        continue ;;
    esac

    branches=""; unknowns=""; pr=""; mr=""
    while IFS=' ' read -r kind value; do
      case "$kind" in
        branch)  branches="$branches$value"$'\n' ;;
        unknown) unknowns="$unknowns$value"$'\n' ;;
        pr)      [ -n "$pr" ] || pr="$value" ;;
        mr)      [ -n "$mr" ] || mr="$value" ;;
      esac
    done <<FIELDS
$(pointer_fields "$ptr")
FIELDS

    while IFS= read -r field; do
      [ -n "$field" ] || continue
      finding "[$state]" "phase $idx: '$field' is not a PR or MR, and no branch by that name exists"
    done <<UNKNOWN
$unknowns
UNKNOWN

    if [ -z "$branches" ]; then
      # An unknown field may be the branch, deleted. Saying "no branch recorded" beside it
      # would assert the cause the line above declines to pick.
      [ -n "$unknowns" ] \
        || finding "[$state]" "phase $idx: no branch recorded, so nothing can resolve what it parked"
      continue
    fi

    forge=""
    if [ -n "$pr" ]; then
      detect_forge
      case "$FORGE" in
        github)
          st="$(gh pr view "$pr" --json state -q .state </dev/null 2>/dev/null)"
          forge="$forge, PR #$pr $(state_word "$st")" ;;
        gitlab) forge="$forge, PR #$pr (state not checked: the remote is on GitLab)" ;;
        *) forge="$forge, PR #$pr (state not checked: no forge detected)" ;;
      esac
    fi
    if [ -n "$mr" ]; then
      detect_forge
      case "$FORGE" in
        gitlab)
          st="$(glab mr view "$mr" -F json --jq .state </dev/null 2>/dev/null)"
          forge="$forge, MR !$mr $(state_word "$st")" ;;
        github) forge="$forge, MR !$mr (state not checked: the remote is on GitHub)" ;;
        *) forge="$forge, MR !$mr (state not checked: no forge detected)" ;;
      esac
    fi
    [ -n "$forge" ] || forge=", no PR"

    while IFS= read -r branch; do
      [ -n "$branch" ] || continue
      ref="$(branch_ref "$branch")"
      behind="$(git rev-list --count "$ref..$TRUNK" 2>/dev/null || printf '?')"
      ahead="$(git rev-list --count "$TRUNK..$ref" 2>/dev/null || printf '?')"
      finding "[$state]" "phase $idx: $branch — $behind commit(s) of $TRUNK landed since, $ahead unmerged$forge"
    done <<BRANCHES
$branches
BRANCHES
    # A here-doc rather than a pipe: the loop body increments OPEN, DRIFT and the other
    # counters, and a pipe would run it in a subshell where every one of those increments
    # is discarded at the closing `done`.
  done <<EOF
$(blc_status_phase_entries "$line")
EOF
done

printf '\nopen-briefs: %s — %d brief(s), %d open phase(s), %d not started, %d drift, %d untracked\n' \
  "$BRIEFS_DIR" "$BRIEF_COUNT" "$OPEN" "$NOT_STARTED" "$DRIFT" "$UNTRACKED"

if [ "$OPEN" -eq 0 ] && [ "$DRIFT" -eq 0 ] && [ "$UNTRACKED" -eq 0 ]; then
  if [ "$NOT_STARTED" -gt 0 ]; then
    # The briefs listed above are not a contradiction of "nothing open". They are
    # filed and waiting, which is the state a brief is supposed to rest in.
    printf 'Nothing open. %d brief(s) filed and waiting to be started.\n' "$NOT_STARTED"
  else
    printf 'Nothing open. Silence here is the intended output, not a failure to run.\n'
  fi
fi

exit 0
