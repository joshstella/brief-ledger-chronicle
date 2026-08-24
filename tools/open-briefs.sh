#!/usr/bin/env bash
# Answer "which briefs are open?" and say what it is costing to leave them open.
#
# Usage: open-briefs.sh [briefs-dir]     (default: docs/briefs)
#
# Always exits 0. This reports; it does not gate. A long deferral is often the
# right call, so failing a build on one would forbid the thing this is meant to
# surface — see docs/briefs/README.md, "the ledger is an archive, and a bad inbox".
#
# The vocabulary it reads is defined once in docs/briefs/README.md, "Ledger status".
# This script does not restate it.
#
# Deliberately does not decide what counts as "too stale". That threshold is an
# open decision on brief #0004. Reporting the commit distance and letting a human
# judge is honest; inventing a number here would smuggle a decision into a tool.
#
# git is required. The forge is not: PR state is looked up through `gh` when it is
# present and skipped silently when it is not, because this project treats external
# tools as optional artifacts to piggyback on, never as load-bearing.
#
# Distances are measured against local refs and are only as fresh as your last fetch.
# This tool does not fetch: a reporting command that mutates the repository would be
# a surprise, and one that reaches the network cannot run offline. Fetch first if the
# numbers need to be current.

BRIEFS_DIR="${1:-docs/briefs}"

OPEN=0
DRIFT=0
UNTRACKED=0

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

HAVE_GH=0
command -v gh >/dev/null 2>&1 && HAVE_GH=1

# A phase entry in the status line looks like  3:in-progress(feature/x,PR#14)
# The pointer is optional; the state is not.
entry_state()   { printf '%s' "${1#*:}" | sed 's/(.*//'; }
entry_pointer() { printf '%s' "$1" | sed -n 's/.*(\(.*\))$/\1/p'; }
entry_index()   { printf '%s' "${1%%:*}"; }

# Pull the branch out of a pointer, which may hold a branch, a PR, a commit, or
# a comma-separated pair. Anything that is not a PR or a bare commit is a branch.
pointer_branch() {
  local p field
  p="$1"
  local IFS=,
  for field in $p; do
    field="${field# }"
    case "$field" in
      PR#*|"PR "*|commit\ *) continue ;;
      "") continue ;;
      *) printf '%s' "$field"; return 0 ;;
    esac
  done
  return 1
}

pointer_pr() {
  local p field
  p="$1"
  local IFS=,
  for field in $p; do
    field="${field# }"
    case "$field" in
      PR#*) printf '%s' "${field#PR#}"; return 0 ;;
    esac
  done
  return 1
}

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

# ── Walk the briefs ──────────────────────────────────────────────────────────

BRIEF_COUNT=0

for dir in "$BRIEFS_DIR"/[0-9][0-9][0-9][0-9]*/; do
  [ -d "$dir" ] || continue
  ledger="$dir/ledger.md"
  ledger="${ledger//\/\//\/}"
  name="${dir%/}"; name="${name##*/}"
  BRIEF_COUNT=$((BRIEF_COUNT + 1))

  if [ ! -f "$ledger" ]; then
    printf '%s\n' "$name"
    finding "[no-ledger]" "no ledger.md; nothing can say whether this is open"
    OPEN=$((OPEN + 1))
    continue
  fi

  # A brief git has never seen has no branch, no PR and no commits, so every
  # staleness measure below reads clean precisely because it is least protected.
  # Reported as its own finding rather than as an absence of one.
  tracked=1
  git ls-files --error-unmatch "$ledger" >/dev/null 2>&1 || tracked=0

  line="$(sed -n '2p' "$ledger" | tr -d '`')"
  case "$line" in
    blc/*) ;;
    *) line="" ;;
  esac

  if [ -z "$line" ]; then
    printf '%s\n' "$name"
    finding "[no-line]" "no blc/N status line under the title; cannot be scanned cheaply"
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

  for entry in "$@"; do
    case "$entry" in
      *:*) ;;
      *) continue ;;
    esac

    idx="$(entry_index "$entry")"
    state="$(entry_state "$entry")"
    ptr="$(entry_pointer "$entry")"

    # Does the phase table agree? Found by locating the row for this phase and
    # asking whether the state word appears in it. Deliberately not a full table
    # parse: three schemas are in use across the existing ledgers, and a scan for
    # the token survives all three where a column index does not.
    row="$(grep -n "^|.*phase $idx " "$ledger" | head -1)"
    if [ -n "$row" ] && ! printf '%s' "$row" | grep -q "$state"; then
      print_header
      finding "[drift]" "phase $idx: status line says '$state'; the phase table row does not"
      DRIFT=$((DRIFT + 1))
    fi

    case "$state" in
      in-progress|deferred) ;;
      *) continue ;;
    esac

    print_header
    OPEN=$((OPEN + 1))

    branch="$(pointer_branch "$ptr")" || branch=""
    pr="$(pointer_pr "$ptr")" || pr=""

    if [ -z "$branch" ]; then
      finding "[$state]" "phase $idx: no branch recorded, so nothing can resolve what it parked"
      continue
    fi

    if ! ref="$(branch_ref "$branch")"; then
      finding "[$state]" "phase $idx: branch '$branch' does not exist; the ledger points at nothing"
      continue
    fi

    behind="$(git rev-list --count "$ref..$TRUNK" 2>/dev/null || printf '?')"
    ahead="$(git rev-list --count "$TRUNK..$ref" 2>/dev/null || printf '?')"

    detail="phase $idx: $branch — $behind commit(s) of $TRUNK landed since, $ahead unmerged"

    if [ -n "$pr" ]; then
      if [ "$HAVE_GH" -eq 1 ]; then
        pr_state="$(gh pr view "$pr" --json state -q .state 2>/dev/null)"
        [ -n "$pr_state" ] || pr_state="unknown"
        detail="$detail, PR #$pr $pr_state"
      else
        detail="$detail, PR #$pr (state not checked: no gh)"
      fi
    else
      detail="$detail, no PR"
    fi

    finding "[$state]" "$detail"
  done
done

printf '\nopen-briefs: %s — %d brief(s), %d open phase(s), %d drift, %d untracked\n' \
  "$BRIEFS_DIR" "$BRIEF_COUNT" "$OPEN" "$DRIFT" "$UNTRACKED"

if [ "$OPEN" -eq 0 ] && [ "$DRIFT" -eq 0 ] && [ "$UNTRACKED" -eq 0 ]; then
  printf 'Nothing open. Silence here is the intended output, not a failure to run.\n'
fi

exit 0
