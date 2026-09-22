#!/usr/bin/env bash
# Check a briefs directory against the briefs Contract, clauses BRIEFS-1 to BRIEFS-10.
#
# Usage: validate-briefs.sh [briefs-dir]     (default: docs/briefs)
#
# Exit 0 if no [defect] clause is violated, 1 otherwise. [judgment] findings are
# printed and never affect the exit status — the Contract says a judgment clause
# is surfaced for a human, so making it fail the build would silently promote it
# to a defect. BRIEFS-8, BRIEFS-9 and BRIEFS-10 are all [judgment].
#
# The clause text lives in docs/contracts/v1.2.md. This script cites clause ids and
# does not restate them: a paraphrase here would be a fourth copy of the rules,
# which is the drift this Contract was extracted to end.
#
# Depends on a POSIX shell, grep, awk, and the shared readers in tools/lib/. The
# first two were the whole list until #0014 phase c; v1.1 said so, and v1.2 corrects
# it. The dependency is deliberate and is the point of the phase: BRIEFS-9 asks
# where a phase row is and BRIEFS-10 asks how a ledger is formed, and two other
# tools already answer both. A validator with its own private copies would be a
# third reader free to disagree, which is the defect #0014 exists to close.
#
# CI is a thin trigger, so the check still travels to environments that are not
# GitHub — it now travels with tools/lib/ beside it rather than alone.

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

BRIEFS_DIR="${1:-docs/briefs}"

# Entries permitted to sit beside the numbered folders (BRIEFS-1).
KNOWN_NON_NUMBERED="_drafts README.md"

DEFECTS=0
JUDGMENTS=0
PROJECT_CHECK_FAILURES=0

defect()   { printf '%s [defect] %s\n' "$1" "$2"; DEFECTS=$((DEFECTS + 1)); }
judgment() { printf '%s [judgment] %s\n' "$1" "$2"; JUDGMENTS=$((JUDGMENTS + 1)); }

if [ ! -d "$BRIEFS_DIR" ]; then
  printf 'error: not a directory: %s\n' "$BRIEFS_DIR" >&2
  exit 2
fi

# An entry is a brief candidate if it begins with four digits — the same test
# blc-create-brief uses to find the maximum serial. Classifying on the prefix rather
# than on the full pattern keeps a malformed name in exactly one clause: it is a
# brief that is named wrong (BRIEFS-2), not an unexpected entry (BRIEFS-1).
is_brief_candidate() {
  case "$1" in
    [0-9][0-9][0-9][0-9]*) return 0 ;;
    *) return 1 ;;
  esac
}

is_known_non_numbered() {
  local entry="$1" known
  for known in $KNOWN_NON_NUMBERED; do
    [ "$entry" = "$known" ] && return 0
  done
  return 1
}

# ── Collect ──────────────────────────────────────────────────────────────────

CANDIDATES=""
for path in "$BRIEFS_DIR"/*; do
  [ -e "$path" ] || continue
  entry="${path##*/}"

  if is_brief_candidate "$entry"; then
    # BRIEFS-1 — a brief is a folder. A file with a serial prefix is not one.
    if [ ! -d "$path" ]; then
      defect "BRIEFS-1" "$entry: has a serial prefix but is not a folder"
      continue
    fi
    CANDIDATES="$CANDIDATES$entry"$'\n'
  elif ! is_known_non_numbered "$entry"; then
    defect "BRIEFS-1" "$entry: neither a NNNN-slug/ folder nor a known non-numbered entry"
  fi
done

# ── BRIEFS-2 — slug and serial shape ─────────────────────────────────────────

WELL_FORMED=""
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  if printf '%s' "$entry" | grep -qE '^[0-9]{4}-[a-z0-9-]+$'; then
    WELL_FORMED="$WELL_FORMED$entry"$'\n'
  else
    defect "BRIEFS-2" "$entry: does not match NNNN-slug with a lowercase slug"
  fi
done <<EOF
$CANDIDATES
EOF

# Only well-formed names have a serial that can be trusted, so every clause below
# reads from WELL_FORMED. A malformed name is reported once by BRIEFS-2 rather
# than cascading into the clauses that would parse it wrong.

# ── BRIEFS-3 — serials are unique ────────────────────────────────────────────

SERIALS=$(printf '%s' "$WELL_FORMED" | sed 's/^\([0-9][0-9][0-9][0-9]\)-.*/\1/' | sort)
DUPES=$(printf '%s\n' "$SERIALS" | grep -v '^$' | uniq -d)
if [ -n "$DUPES" ]; then
  while IFS= read -r serial; do
    [ -n "$serial" ] || continue
    defect "BRIEFS-3" "$serial: used by more than one folder"
  done <<EOF
$DUPES
EOF
fi

# ── BRIEFS-4, BRIEFS-5 — the brief exists and its identity line is well formed ─

DECLARED_SERIALS=""
DEPENDENCIES=""

while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  serial="${entry%%-*}"
  brief="$BRIEFS_DIR/$entry/brief.md"

  if [ ! -f "$brief" ]; then
    defect "BRIEFS-4" "$entry: contains no brief.md"
    continue
  fi

  DECLARED_SERIALS="$DECLARED_SERIALS$serial"$'\n'

  identity=$(grep -m1 '^\*\*Serial:\*\*' "$brief")
  if [ -z "$identity" ]; then
    defect "BRIEFS-5" "$entry: no identity line"
    continue
  fi

  found_serial=$(printf '%s' "$identity" | sed 's/^\*\*Serial:\*\* *#\([0-9]*\).*/\1/')
  [ "$found_serial" = "$serial" ] \
    || defect "BRIEFS-5" "$entry: identity line says #$found_serial, folder says $serial"

  printf '%s' "$identity" | grep -qE '\*\*Created:\*\* *[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' \
    || defect "BRIEFS-5" "$entry: Created is missing or not ISO-8601 UTC"

  printf '%s' "$identity" | grep -qE '\*\*Author:\*\* *[^ @]+@[^ @]+\.[^ @]+' \
    || defect "BRIEFS-5" "$entry: Author is missing or not email-shaped"

  if printf '%s' "$identity" | grep -q '\*\*Depends on:\*\*'; then
    deps=$(printf '%s' "$identity" | sed 's/.*\*\*Depends on:\*\*//')
    for dep in $(printf '%s' "$deps" | grep -oE '#[0-9]{4}' | tr -d '#'); do
      DEPENDENCIES="$DEPENDENCIES$entry $dep"$'\n'
    done
  else
    defect "BRIEFS-5" "$entry: identity line has no Depends on"
  fi
done <<EOF
$WELL_FORMED
EOF

# ── BRIEFS-6 — no dangling dependencies ──────────────────────────────────────

while IFS=' ' read -r entry dep; do
  [ -n "$dep" ] || continue
  printf '%s' "$DECLARED_SERIALS" | grep -qx "$dep" \
    || defect "BRIEFS-6" "$entry: depends on #$dep, which does not exist"
done <<EOF
$DEPENDENCIES
EOF

# ── BRIEFS-7 — drafts are unnumbered ─────────────────────────────────────────

if [ -d "$BRIEFS_DIR/_drafts" ]; then
  for path in "$BRIEFS_DIR"/_drafts/*; do
    [ -e "$path" ] || continue
    entry="${path##*/}"
    is_brief_candidate "$entry" \
      && defect "BRIEFS-7" "_drafts/$entry: a draft carries a four-digit prefix"
  done
fi

# ── BRIEFS-8 — serials are contiguous ────────────────────────────────────────
#
# [judgment], not [defect]: a removed brief legitimately retires its number, so a
# gap is a question for a human rather than a build failure.

UNIQUE_SERIALS=$(printf '%s' "$DECLARED_SERIALS" | grep -v '^$' | sort -u)
if [ -n "$UNIQUE_SERIALS" ]; then
  expected=1
  while IFS= read -r serial; do
    [ -n "$serial" ] || continue
    # Strip leading zeros before comparing; 0010 is not octal here.
    actual=$(printf '%s' "$serial" | sed 's/^0*//')
    [ -n "$actual" ] || actual=0
    if [ "$actual" -ne "$expected" ]; then
      if [ "$expected" -eq 1 ]; then
        judgment "BRIEFS-8" "serials start at $serial, not 0001"
      else
        judgment "BRIEFS-8" "serials jump from $(printf '%04d' $((expected - 1))) to $serial"
      fi
      expected="$actual"
    fi
    expected=$((expected + 1))
  done <<EOF
$UNIQUE_SERIALS
EOF
fi

# ── BRIEFS-9 — every phase id in a status line is findable in the phase table ─
#
# [judgment], not [defect]. See #0014 open decision 2: the failure mode is
# asymmetric. A judgment that should have gated costs a warning nobody acted on; a
# defect that should have reported breaks someone else's build on the day they
# upgrade, for a ledger that was legal when they wrote it. This toolkit installs
# into repositories whose ledgers it did not write.
#
# ── BRIEFS-10 — a ledger's frontmatter and fences are closed ─────────────────
#
# Also [judgment], and the clause that keeps phase b's recovery behaviour honest.
# blc_status_line deliberately succeeds on a malformed ledger — it reads through
# unterminated frontmatter and falls back past an unclosed fence — so nothing else
# would ever mention the malformation. The complaint comes from the structure the
# scan passed through, never from its result.
#
# Both read the same shared functions open-briefs.sh and list-briefs.sh read.
# Re-deriving either here is what tests/test_phase_row.sh and
# tests/test_status_line.sh scan tools/ to forbid.

# The phase ids a status line declares, whitespace-separated.
#
# A phase token is one containing a colon, which is a filter and not a formality:
# #0001's brief status is `done(commit 92a7168)` and contains a space, so splitting
# the line on whitespace alone yields `done(commit` and `92a7168)` as tokens. Both
# index alphabets are accepted — blc/1 numbered its phases, blc/2 letters them, and
# six ledgers here still use the older form.
# The id is checked for shape, not merely for a colon somewhere after a digit. The looser
# form matched `2026-01-01T00:00:00Z` and yielded the phase id `2026-01-01T00`, because a
# timestamp is digits followed by colons. No status line carries a timestamp today, so this
# was unreachable — and it is fixed anyway, because BRIEFS-9 is about to be written into a
# Contract clause and a parser is easier to correct than a published version of one.
status_line_phase_ids() {
  local token id ids=""
  for token in $1; do
    case "$token" in
      *:*) id="${token%%:*}" ;;
      *) continue ;;
    esac
    # A phase index is one lowercase letter (blc/2) or digits (blc/1). Nothing else is one.
    case "$id" in
      [a-z]) ids="$ids $id" ;;
      *[!0-9]*) ;;
      [0-9]*) ids="$ids $id" ;;
    esac
  done
  printf '%s' "${ids# }"
}

for entry in $WELL_FORMED; do
  ledger="$BRIEFS_DIR/$entry/ledger.md"
  # A brief that has not been started has no ledger, and that is not a defect —
  # #0007 is filed and waiting. BRIEFS-1 to BRIEFS-7 govern brief.md; these two are
  # the first clauses to read ledger.md at all, so the absent case is theirs to skip.
  [ -f "$ledger" ] || continue

  case "$(blc_ledger_structure "$ledger" frontmatter)" in
    open) judgment "BRIEFS-10" "$entry: ledger.md opens a --- frontmatter block that never closes" ;;
  esac
  case "$(blc_ledger_structure "$ledger" fence)" in
    open) judgment "BRIEFS-10" "$entry: ledger.md ends inside an unclosed code fence" ;;
  esac

  status_line="$(blc_status_line "$ledger")"
  # No status line is already reported by open-briefs.sh as drift, and BRIEFS-9 has
  # nothing to say about a line that does not exist.
  [ -n "$status_line" ] || continue

  for phase_id in $(status_line_phase_ids "$status_line"); do
    blc_phase_row_find "$phase_id" "$ledger" >/dev/null 2>&1 \
      || judgment "BRIEFS-9" "$entry: status line declares phase '$phase_id', which matches no row in the phase table"
  done
done

# ── Project checks (brief-checks/) ───────────────────────────────────────────
#
# After toolkit clauses pass, run each script in brief-checks/*.sh in sorted
# order. The directory lives at the repository root; the installer never creates
# or writes it. Exit 0 passes; anything else fails and the script's output is
# echoed under its filename.

run_project_checks() {
  local repo_root checks_dir script output status

  repo_root="$(cd "$BRIEFS_DIR/../.." && pwd)"
  checks_dir="$repo_root/brief-checks"
  [ -d "$checks_dir" ] || return 0

  for script in $(find "$checks_dir" -maxdepth 1 -type f -name '*.sh' | sort); do
    output="$(bash "$script" "$BRIEFS_DIR" 2>&1)" || status=$?
    status="${status:-0}"
    if [ "$status" -ne 0 ]; then
      printf '%s:\n%s\n' "$(basename "$script")" "$output"
      PROJECT_CHECK_FAILURES=$((PROJECT_CHECK_FAILURES + 1))
    fi
    status=0
  done
}

if [ "$DEFECTS" -eq 0 ]; then
  run_project_checks
fi

# ── Report ───────────────────────────────────────────────────────────────────
#
# The count is of clauses this script decides, not of clauses in the Contract.
# Saying "8 clauses checked" when the Contract grows a ninth would overstate
# coverage, which is the failure this artifact exists to prevent.
#
# The brief count is reported for the same reason. Without it, a caller cannot
# tell compliance from an empty directory: both are zero defects and exit 0, and
# a test asserting only the exit code would pass on a tree containing nothing.

BRIEF_COUNT=$(printf '%s' "$WELL_FORMED" | grep -c '[^[:space:]]')

if [ "$PROJECT_CHECK_FAILURES" -gt 0 ]; then
  printf '\nvalidate-briefs: %s — %d brief(s), 10 clauses decided, %d defect(s), %d judgment(s), %d project check failure(s)\n' \
    "$BRIEFS_DIR" "$BRIEF_COUNT" "$DEFECTS" "$JUDGMENTS" "$PROJECT_CHECK_FAILURES"
else
  printf '\nvalidate-briefs: %s — %d brief(s), 10 clauses decided, %d defect(s), %d judgment(s)\n' \
    "$BRIEFS_DIR" "$BRIEF_COUNT" "$DEFECTS" "$JUDGMENTS"
fi

[ "$DEFECTS" -eq 0 ] && [ "$PROJECT_CHECK_FAILURES" -eq 0 ] || exit 1
exit 0
