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

HAVE_GH=0
command -v gh >/dev/null 2>&1 && HAVE_GH=1

# A phase entry in the status line looks like  3:in-progress(feature/x,PR#14)
# The pointer is optional; the state is not.
entry_state()   { printf '%s' "${1#*:}" | sed 's/(.*//'; }
entry_pointer() { printf '%s' "$1" | sed -n 's/.*(\(.*\))$/\1/p'; }
entry_index()   { printf '%s' "${1%%:*}"; }

# The status line sits directly under the title. A ledger whose first line is `---` opens
# with YAML frontmatter, so its title cannot start until that block closes, and the line
# lands further down through no fault of its author. That placement is legal: a docs
# pipeline pins the frontmatter, and `list-briefs` and `orient` already read the line there,
# so refusing it made this the one reader that could not see a line the others could.
#
# The read stays positional because that is what the line is for: a scan costs a line instead
# of a table. Skip a leading block, skip the blank lines after it, take the title, and the
# status line is the next line down. This is a cost rule and not a boundary — `list-briefs`
# searches the whole file on purpose, which is why it read this placement correctly for as
# long as this reader could not.
status_line() {
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---"   { in_fm = 0; next }
    in_fm                  { next }
    !titled && $0 ~ /^[[:space:]]*$/ { next }
    !titled                { titled = 1; next }
    { print; exit }
  ' "$1" | tr -d '`'
}

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

  line="$(status_line "$ledger")"
  case "$line" in
    blc/*) ;;
    *) line="" ;;
  esac

  if [ -z "$line" ]; then
    printf '%s\n' "$name"
    finding "[no-line]" "no blc/N status line on the line below the title, after any leading --- block"
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

    # Does the phase table agree? Found by collecting every row that could be this
    # phase's row and asking whether any of them carries the state word. Deliberately
    # not a full table parse: three schemas are in use across the existing ledgers, and
    # a scan for the token survives all three where a column index does not.
    #
    # One matcher serves both index alphabets, because the shapes overlap. A phase row
    # writes its id one of three ways:
    #
    #   | a | the row scan | done |         the id alone in the first cell
    #   | `a — the row scan` | done |       id and label em-dashed into one cell
    #   | `brief/0001-x` | phase 1 of it |  the id in prose, numeric schema only
    #
    # The first two are anchored to the first cell and are what `blc-start-brief` writes.
    # The third cannot be anchored: #0009 left the numeric scan loose for install targets
    # that put the id elsewhere, and a test pins that latitude. It is *added* to the
    # numeric pattern, never substituted for the anchored form — the two-column shape and
    # the prose shape both occur, and matching only one of them is how this broke.
    #
    # Every match is considered, and drift is reported only when *none* of them agrees.
    # Taking the first match meant a row from a second table — a cost or timing table
    # whose cells mention `phase 2` — could shadow the real phase row and report a record
    # that was correct as self-contradictory. The price of the rule is the opposite error:
    # a stale row goes unreported when some other matching row happens to carry the word.
    # That trade is deliberate. This tool never gates, so a false positive spends trust in
    # every finding it will ever emit, while a false negative costs one missed drift that
    # the next reader of the ledger still sees. A reporter nobody believes reports nothing.
    row_pattern="^\|[[:space:]]*~*\`?${idx}[[:space:]]*(\||—)"
    case "$idx" in
      [0-9]*) row_pattern="${row_pattern}|^\|.*phase ${idx} " ;;
    esac
    rows="$(grep -nE "$row_pattern" "$ledger")"
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
